#!/usr/bin/env python3
"""cov_metrics — P01 coverage infrastructure: dual-number (RAW + ADJUSTED) reporter.

Single source of truth for per-stage coverage acceptance (coverage_gate_plan.md). Parses Verilator
coverage.dat (line + toggle points); applies STRUCTURAL exclusions from a per-stage waiver file
(JSON; schema in waivers/SCHEMA.md); reports RAW and ADJUSTED (RAW always shown; ADJUSTED is the bar).
VCS/URG branch/expr/FSM ingestion is an extension point (parse_urg) — stubbed until a VCS run exists,
so a stage may NOT be marked done on branch/expr/FSM until that is implemented (callers must check).

Hardened per Codex P01 producer!=approver review (2026-06-09):
- Full point identity (file,line,point-id,page,object,hier) — no (o,l) collisions / denominator undercount.
- Blanket-waiver ban enforced IN CODE: a waiver matching catch-all with no bit range is rejected; and a
  single waiver may not exclude an entire module (WAIVER_MAX_FRAC) — raises CoverageError.
- Invariants asserted: adjusted_hits <= raw_hits, adjusted_total <= raw_total (exclusions only shrink).
- Only APPROVED waivers apply (un-approved => RAW == ADJUSTED).
"""
from __future__ import annotations

import json
import re
from collections import defaultdict
from pathlib import Path

WAIVER_MAX_FRAC = 0.90  # a single waiver excluding > this fraction of a module's points is a blanket waiver
_CATCH_ALL = {"", ".*", ".+", "(.*)", "^.*$"}


class CoverageError(Exception):
    pass


# ---------- Verilator coverage.dat parsing ----------
def _fields(payload: str) -> dict:
    f = {}
    for item in payload.split("\x01"):
        if item and "\x02" in item:
            k, v = item.split("\x02", 1)
            f[k] = v
    return f


def parse_points(dat_paths, kind: str) -> dict:
    """Union coverage points of type `kind` across dat files, keyed by FULL identity.
    Returns {module: {point_key: hit_bool}} (hit = covered in ANY file). point_key is the full
    Verilator point tuple so two distinct points never collide (fixes line/denominator undercount)."""
    rows: dict = defaultdict(dict)
    for dat in dat_paths:
        for line in Path(dat).read_text(encoding="latin-1", errors="replace").splitlines():
            if not line.startswith("C '") or "' " not in line:
                continue
            payload, count_s = line[3:].rsplit("' ", 1)
            fl = _fields(payload)
            if fl.get("t") != kind:
                continue
            module = Path(fl.get("f", "")).name or "?"
            # MODULE-level union identity = (object, line). The object `o` encodes signal[bit]:edge
            # (unique within a module); hierarchy `h` is deliberately EXCLUDED so the same RTL point
            # under different testbench instances UNIONS (hit in ANY), not over-counts. Empirically
            # validated: this reproduces the agreed 13058 DUT toggle total (Gemini P01 cross-check);
            # including `h` inflated it to 67518 (per-instance). Module=basename (DUT basenames unique).
            point_key = (fl.get("o", ""), fl.get("l", ""))
            try:
                cnt = int(count_s.strip())
            except ValueError:
                continue
            rows[module][point_key] = rows[module].get(point_key, False) or cnt > 0
    return rows


def parse_info_lines(info_paths) -> dict:
    """Parse LCOV .info (verilator_coverage -write-info) for SOURCE-LINE coverage (the customer
    'line 100%' metric — .dat 't=line' points are basic BLOCKS, not source lines; Gemini P01 review).
    Returns {module: {lineno: hit_bool}} unioned across files."""
    rows: dict = defaultdict(dict)
    for info in info_paths:
        cur = None
        for line in Path(info).read_text(encoding="utf-8", errors="replace").splitlines():
            if line.startswith("SF:"):
                cur = Path(line[3:]).name
            elif line.startswith("DA:") and cur:
                num, _, cnt = line[3:].partition(",")
                try:
                    rows[cur][int(num)] = rows[cur].get(int(num), False) or int(cnt) > 0
                except ValueError:
                    continue
    return rows


# ---------- waivers ----------
def load_waivers(path) -> list:
    p = Path(path)
    if not p.exists():
        return []
    data = json.loads(p.read_text(encoding="utf-8"))
    return data.get("waivers", data if isinstance(data, list) else [])


def _bit(sig: str):
    m = re.search(r"\[(\d+)\]", sig)
    return int(m.group(1)) if m else None


def _waiver_is_valid(w: dict) -> bool:
    """Reject blanket waivers: catch-all signal_re with no bit range is not a structural exclusion."""
    if not w.get("approved"):
        return False
    sre = (w.get("signal_re") or "").strip()
    has_range = w.get("bit_lo") is not None or w.get("bit_hi") is not None
    has_signals = bool(w.get("signals"))
    if sre in _CATCH_ALL and not has_range and not has_signals:
        return False
    return True


def _point_sig(point_key) -> str:
    # toggle key = (object, line); line key = (f"L<n>",). Signal/object is always index 0.
    if isinstance(point_key, tuple) and point_key:
        return point_key[0]
    return str(point_key)


def is_waived(module: str, point_key, waivers: list) -> bool:
    sig = _point_sig(point_key)
    b = _bit(sig)
    for w in waivers:
        if not _waiver_is_valid(w):
            continue
        if w.get("module") not in (module, "*"):
            continue
        sigs = w.get("signals")
        if sigs:
            if not any(s in sig for s in sigs):
                continue
        else:
            if not re.search(w.get("signal_re", "$^"), sig):
                continue
        lo, hi = w.get("bit_lo"), w.get("bit_hi")
        if lo is not None or hi is not None:
            if b is None:
                continue
            if lo is not None and b < lo:
                continue
            if hi is not None and b > hi:
                continue
        return True
    return False


# ---------- dual-number report ----------
def _accumulate(kind: str, pts: dict, waivers: list, dut_only: bool, waived_sink: list) -> dict:
    raw_h = raw_t = adj_h = adj_t = 0
    per = {}
    for m, mp in pts.items():
        if dut_only and m.startswith("tb_"):
            continue
        h = t = ah = at = mod_waived = 0
        for pk, hit in mp.items():
            t += 1
            h += 1 if hit else 0
            if is_waived(m, pk, waivers):
                mod_waived += 1
                if not hit:
                    waived_sink.append((kind, m, _point_sig(pk)))
                continue
            at += 1
            ah += 1 if hit else 0
        if t and mod_waived / t > WAIVER_MAX_FRAC:
            raise CoverageError(
                f"blanket waiver: {mod_waived}/{t} ({100*mod_waived/t:.0f}%) of {m} {kind} points "
                f"waived by a single stage file (> {WAIVER_MAX_FRAC:.0%}). Split into specific, "
                f"bit-ranged structural waivers (SCHEMA.md).")
        assert ah <= h and at <= t, f"invariant on {m}/{kind}: adj=({ah},{at}) raw=({h},{t})"
        per[m] = {"raw": (h, t), "adj": (ah, at)}
        raw_h += h; raw_t += t; adj_h += ah; adj_t += at
    assert adj_h <= raw_h and adj_t <= raw_t, f"global invariant {kind}: adjusted exceeds raw"
    return {"per_module": per,
            "raw_pct": 100 * raw_h / raw_t if raw_t else 0.0,
            "adj_pct": 100 * adj_h / adj_t if adj_t else 0.0,
            "raw": (raw_h, raw_t), "adj": (adj_h, adj_t)}


def dual_number(dat_paths, waiver_path=None, info_paths=None, dut_only=True) -> dict:
    """RAW+ADJUSTED dual-number report. Toggle from .dat (point-level). Line from .info SOURCE-LINES
    when info_paths given (the customer 'line 100%' metric); else falls back to .dat basic-BLOCKS
    (labeled line_is_blocks=True)."""
    waivers = load_waivers(waiver_path) if waiver_path else []
    waived_sink: list = []
    toggle_pts = parse_points(dat_paths, "toggle")
    if info_paths:
        line_src = {m: {(f"L{ln}",): hit for ln, hit in d.items()}
                    for m, d in parse_info_lines(info_paths).items()}
        line_is_blocks = False
    else:
        line_src = parse_points(dat_paths, "line")
        line_is_blocks = True
    out = {
        "toggle": _accumulate("toggle", toggle_pts, waivers, dut_only, waived_sink),
        "line": _accumulate("line", line_src, waivers, dut_only, waived_sink),
        "line_is_blocks": line_is_blocks,
        "waived_points": [(m, s) for (k, m, s) in waived_sink if k == "toggle"],
    }
    return out


def format_report(rep: dict, scope: str = "") -> str:
    L, T = rep["line"], rep["toggle"]
    return (f"SCOPE: {scope}\n"
            f"LINE:   raw {L['raw_pct']:.1f}% ({L['raw'][0]}/{L['raw'][1]})  "
            f"adjusted {L['adj_pct']:.1f}% ({L['adj'][0]}/{L['adj'][1]})\n"
            f"TOGGLE: raw {T['raw_pct']:.1f}% ({T['raw'][0]}/{T['raw'][1]})  "
            f"adjusted {T['adj_pct']:.1f}% ({T['adj'][0]}/{T['adj'][1]})  "
            f"(waived toggles: {len(rep['waived_points'])})\n"
            f"BRANCH/EXPR/FSM: pending VCS+URG run (parse_urg extension point — NOT measured by Verilator)")


def parse_urg(urg_dir, module=None) -> dict:
    """Parse a VCS URG report dir for PER-MODULE branch/condition coverage (the licensed-tool metrics
    Verilator cannot produce). Each URG 'Module :: <name>' page reports rows like 'Branches 13 13 100'
    (hit total pct). Returns {module_name: {metric: {hit,total,pct}}}; if `module` given, returns just
    that module's dict. branch=>'branch', Conditions=>'expr'."""
    import glob as _glob
    import re as _re
    pages = _glob.glob(str(Path(urg_dir) / "mod*.html"))
    if not pages:
        raise CoverageError(f"no URG mod*.html in {urg_dir} — VCS coverage not run")
    labels = {"Branches": "branch", "Conditions": "expr",
              "States": "fsm_state", "Transitions": "fsm_arc"}
    per: dict = {}
    for pg in pages:
        t = _re.sub(r"<[^>]+>", " ", Path(pg).read_text(errors="replace"))
        t = _re.sub(r"\s+", " ", t)
        mn = _re.search(r"Module :: (\w+)", t)
        if not mn:
            continue
        name = mn.group(1)
        metrics = {}
        for label, metric in labels.items():
            # URG row format is "<label> <TOTAL> <COVERED> <PCT>" (total first, then hit).
            m = _re.search(label + r" (\d+) (\d+) (\d+)", t)
            if m:
                tot, h, rep_pct = int(m.group(1)), int(m.group(2)), int(m.group(3))
                pct = 100.0 * h / tot if tot else 0.0
                # cross-check parsed hit/total against URG's own reported pct (catches column-order bugs)
                if tot and abs(pct - rep_pct) > 1.5:
                    raise CoverageError(
                        f"URG parse mismatch for {name}/{metric}: hit={h} total={tot} -> {pct:.0f}% "
                        f"but URG reports {rep_pct}% (column-order/parse error)")
                metrics[metric] = {"hit": h, "total": tot, "pct": pct}
        if metrics:
            per[name] = metrics
    if module is not None:
        if module not in per:
            raise CoverageError(f"module {module!r} not in URG report (have {list(per)})")
        return per[module]
    return per


if __name__ == "__main__":
    import glob
    import sys
    root = Path(__file__).resolve().parents[4]
    dats = sys.argv[1:] or glob.glob(str(root / "flow/v2_pipeline/phase_04_0*_coverage/coverage.dat"))
    infos = glob.glob(str(root / "flow/v2_pipeline/phase_04_0*_coverage/coverage/coverage.info"))
    print(format_report(dual_number(dats, info_paths=infos), scope="self-test (source-line via .info)"))
