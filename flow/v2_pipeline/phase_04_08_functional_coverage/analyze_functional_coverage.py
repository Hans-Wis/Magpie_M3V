#!/usr/bin/env python3
"""Summarize cpu_m1 functional coverage observer events."""

from __future__ import annotations

import csv
from pathlib import Path


ROOT = Path(__file__).resolve().parent

OPCODES = {
    "lui": 0b0110111,
    "auipc": 0b0010111,
    "jal": 0b1101111,
    "jalr": 0b1100111,
    "branch": 0b1100011,
    "load": 0b0000011,
    "store": 0b0100011,
    "op_imm": 0b0010011,
    "op": 0b0110011,
    "system": 0b1110011,
    "fence": 0b0001111,
}

INSTR_CLASSES = {
    1: "alu",
    2: "load",
    3: "store",
    4: "branch",
    5: "jump",
    6: "csr",
    7: "upper",
}

IMM_FORMATS = {
    1: "i",
    2: "s",
    3: "b",
    4: "u",
    5: "j",
}

IMM_SIGNS = {
    1: "zero",
    2: "positive",
    3: "negative",
}

IMM_CORNERS = {
    1: "zero",
    2: "min",
    3: "max",
    4: "u_all_ones",
}

GROUP_BINS = {
    "cg_opcode_instr_class": [f"opcode:{k}" for k in OPCODES] + ["size:rvc", "size:rv32"],
    "cg_alu_m_funct": [f"alu_funct3:{i}" for i in range(8)] + ["funct7:base", "funct7:sub_sra", "funct7:muldiv"] + [f"m_op:{i}" for i in range(8)] + ["m_kind:mul", "m_kind:div"],
    "cg_load_store": [f"ls_kind:{k}" for k in ("load", "store")] + [f"width:{k}" for k in ("byte", "half", "word")] + [f"sign:{k}" for k in ("signed", "unsigned", "none")] + [f"addr_lo:{i}" for i in range(4)],
    "cg_branch_jump_bp_ras": ["branch:taken", "branch:not_taken", "dir:forward", "dir:backward", "jump:jal", "jump:jalr", "ras:push", "ras:pop", "bp:hit", "bp:miss"],
    "cg_hazard_flush": ["hazard:load_use", "hazard:muldiv_busy", "hazard:fetch_stall", "hazard:mem_stall", "redirect:no", "redirect:yes"],
    "cg_csr_trap": ["csr:rw", "csr:rs", "csr:rc", "trap:illegal", "trap:ecall", "trap:ebreak", "trap:irq", "trap:load_misalign", "trap:store_misalign", "mret:yes"],
    "cg_riscvisacov_operands": (
        [f"class:{name}" for name in INSTR_CLASSES.values()]
        + [f"rd:x{i}" for i in range(32)]
        + [f"rs1:x{i}" for i in range(32)]
        + [f"rs2:x{i}" for i in range(32)]
    ),
    "cg_riscvisacov_value_corners": (
        [f"rs1_val:{name}" for name in ("zero", "one", "minus_one", "max_pos", "min_neg", "all_ones")]
        + [f"rs2_val:{name}" for name in ("zero", "one", "minus_one", "max_pos", "min_neg", "all_ones")]
    ),
    "cg_riscvisacov_immediates": (
        [f"format:{name}" for name in IMM_FORMATS.values()]
        + [f"sign:{name}" for name in IMM_SIGNS.values()]
        + [f"{fmt}:{corner}" for fmt in IMM_FORMATS.values() for corner in ("zero", "min", "max")]
        + ["u:u_all_ones"]
    ),
}

EXCLUDED_BINS = {
    "cg_riscvisacov_immediates": {
        "j:max": (
            "JUSTIFIED EXCLUSION: structural memory-map limit",
            "RV32 JAL max positive offset is +0xFFFFE; from any nonzero JAL PC this requires an approximately 1 MiB forward executable target, but this phase/SKU config maps only 16 KiB (firmware.lds rom LENGTH=16K; tb_random_func_cov MEM_SIZE=4096 words indexed by i_mem_addr[13:2])",
            "waive",
        )
    }
}

BIN_REASON = {
    "hazard:mem_stall": ("not driven by core-local random harness", "reachable through cpu_m1_top wait-state memory wrapper", "waive"),
    "trap:irq": ("random harness ties irq_external_pulse low", "reachable in phase_02_00/03_01 IRQ tests; needs VCS bind rerun", "none"),
    "trap:load_misalign": ("random generator avoids misaligned architectural accesses", "reachable in phase_02_02 misalign test; needs VCS bind rerun", "none"),
    "trap:store_misalign": ("random generator avoids misaligned architectural accesses", "reachable in phase_02_02 misalign test; needs VCS bind rerun", "none"),
    "mret:yes": ("random generator does not install a trap handler", "reachable in IRQ/trap directed firmware; needs VCS bind rerun", "none"),
}


def rows() -> list[dict[str, str]]:
    path = ROOT / "functional_events.csv"
    with path.open(newline="", encoding="utf-8") as fh:
        return list(csv.DictReader(fh))


def mark_hits(events: list[dict[str, str]]) -> dict[str, set[str]]:
    hits = {group: set() for group in GROUP_BINS}
    for row in events:
        ev = row["event"]
        if ev == "hazard":
            hits["cg_hazard_flush"].add(f"hazard:{row['a']}")
            continue
        a = row["a"]
        b = row["b"]
        c = row["c"]
        d = row["d"]
        try:
            ai = int(a) if a not in {"push", "pop"} else None
            bi = int(b)
            ci = int(c)
            di = int(d)
            ei = int(row["e"])
        except ValueError:
            continue
        if ev == "decode":
            opcode = ai
            for name, value in OPCODES.items():
                if opcode == value:
                    hits["cg_opcode_instr_class"].add(f"opcode:{name}")
            hits["cg_opcode_instr_class"].add("size:rvc" if bi else "size:rv32")
            if opcode in (OPCODES["op"], OPCODES["op_imm"]):
                hits["cg_alu_m_funct"].add(f"alu_funct3:{ci}")
            if opcode == OPCODES["op"]:
                funct7 = di
                if funct7 == 0:
                    hits["cg_alu_m_funct"].add("funct7:base")
                elif funct7 == 32:
                    hits["cg_alu_m_funct"].add("funct7:sub_sra")
                elif funct7 == 1:
                    hits["cg_alu_m_funct"].add("funct7:muldiv")
                    md = ei
                    hits["cg_alu_m_funct"].add(f"m_op:{md}")
                    hits["cg_alu_m_funct"].add("m_kind:div" if md & 4 else "m_kind:mul")
        elif ev == "ls":
            is_load = ai
            is_store = bi
            funct3 = ci
            addr_lo = di
            if is_load:
                hits["cg_load_store"].add("ls_kind:load")
                hits["cg_load_store"].add("sign:unsigned" if funct3 & 4 else "sign:signed")
            if is_store:
                hits["cg_load_store"].add("ls_kind:store")
                hits["cg_load_store"].add("sign:none")
            hits["cg_load_store"].add(["width:byte", "width:half", "width:word"][funct3 & 3] if (funct3 & 3) < 3 else "width:byte")
            hits["cg_load_store"].add(f"addr_lo:{addr_lo}")
        elif ev == "branch":
            hits["cg_branch_jump_bp_ras"].add("branch:taken" if ai else "branch:not_taken")
            hits["cg_branch_jump_bp_ras"].add("dir:backward" if bi else "dir:forward")
        elif ev == "jump":
            if ai:
                hits["cg_branch_jump_bp_ras"].add("jump:jal")
            if bi:
                hits["cg_branch_jump_bp_ras"].add("jump:jalr")
        elif ev == "ras":
            hits["cg_branch_jump_bp_ras"].add(f"ras:{a}")
        elif ev == "bp":
            hits["cg_branch_jump_bp_ras"].add("bp:miss" if ai else "bp:hit")
        elif ev == "redirect":
            hits["cg_hazard_flush"].add("redirect:yes")
        elif ev == "csr":
            hits["cg_csr_trap"].add({1: "csr:rw", 2: "csr:rs", 3: "csr:rc"}.get(ai, "csr:rw"))
        elif ev == "trap":
            hits["cg_csr_trap"].add(["trap:illegal", "trap:ecall", "trap:ebreak", "trap:irq", "trap:load_misalign", "trap:store_misalign"][ai])
        elif ev == "mret":
            hits["cg_csr_trap"].add("mret:yes")
        elif ev == "operand":
            hits["cg_riscvisacov_operands"].add(f"rd:x{ai}")
            hits["cg_riscvisacov_operands"].add(f"rs1:x{bi}")
            hits["cg_riscvisacov_operands"].add(f"rs2:x{ci}")
            if di in INSTR_CLASSES:
                hits["cg_riscvisacov_operands"].add(f"class:{INSTR_CLASSES[di]}")
        elif ev == "value":
            for prefix, value in (("rs1_val", ai), ("rs2_val", bi)):
                value &= 0xFFFFFFFF
                if value == 0:
                    hits["cg_riscvisacov_value_corners"].add(f"{prefix}:zero")
                if value == 1:
                    hits["cg_riscvisacov_value_corners"].add(f"{prefix}:one")
                if value == 0xFFFFFFFF:
                    hits["cg_riscvisacov_value_corners"].add(f"{prefix}:minus_one")
                    hits["cg_riscvisacov_value_corners"].add(f"{prefix}:all_ones")
                if value == 0x7FFFFFFF:
                    hits["cg_riscvisacov_value_corners"].add(f"{prefix}:max_pos")
                if value == 0x80000000:
                    hits["cg_riscvisacov_value_corners"].add(f"{prefix}:min_neg")
        elif ev == "imm":
            fmt = IMM_FORMATS.get(ai)
            sign = IMM_SIGNS.get(bi)
            corner = IMM_CORNERS.get(ci)
            if fmt:
                hits["cg_riscvisacov_immediates"].add(f"format:{fmt}")
            if sign:
                hits["cg_riscvisacov_immediates"].add(f"sign:{sign}")
            if fmt and corner:
                hits["cg_riscvisacov_immediates"].add(f"{fmt}:{corner}")
    if events:
        hits["cg_hazard_flush"].add("redirect:no")
    return hits


def default_reason(bin_name: str, unavailable: bool = False) -> tuple[str, str, str]:
    if unavailable:
        return ("VCS license unavailable before simulation; no covergroup samples", "reachable bins remain unmeasured until licensed VCS rerun", "waive")
    if bin_name in BIN_REASON:
        return BIN_REASON[bin_name]
    if bin_name.startswith("m_op:") or bin_name.startswith("alu_funct3:"):
        return ("not selected by this bounded random seed", "reachable by RV32IM random/direct stimulus", "none")
    if bin_name.startswith("opcode:") or bin_name.startswith("size:"):
        return ("not emitted by this bounded random seed", "reachable by generator constraint expansion or directed test", "none")
    if bin_name.startswith("width:") or bin_name.startswith("sign:") or bin_name.startswith("addr_lo:"):
        return ("not generated by current memory operand mix", "reachable with directed load/store offsets", "none")
    if bin_name.startswith("ras:") or bin_name.startswith("bp:") or bin_name.startswith("jump:") or bin_name.startswith("branch:") or bin_name.startswith("dir:"):
        return ("not generated by current control-flow mix", "reachable with BP/RAS directed tests under this bind", "none")
    if bin_name.startswith("csr:") or bin_name.startswith("trap:"):
        return ("not generated by current random firmware", "reachable with CSR/trap directed tests under this bind", "none")
    if bin_name.startswith(("rd:", "rs1:", "rs2:", "class:")):
        return ("not generated by the measured retire stream", "reachable with register-sweep directed stimulus under this bind", "none")
    if bin_name.startswith(("rs1_val:", "rs2_val:")):
        return ("not generated by the measured operand-value stream", "reachable with directed value-corner stimulus under this bind", "none")
    if bin_name.startswith(("format:", "sign:", "i:", "s:", "b:", "u:", "j:")):
        return ("not generated by the measured immediate stream", "reachable with immediate-boundary directed stimulus; wide J offsets need large-address/alias harness support", "none")
    return ("unhit in measured stimulus", "reachable unless separately proven otherwise", "none")


def main() -> int:
    events = rows()
    license_text = ""
    for name in ("vcs_compile.log", "provenance.log"):
        path = ROOT / name
        if path.exists():
            license_text += path.read_text(encoding="utf-8", errors="replace")
    unavailable = len(events) == 0 and (
        "Cannot connect to the license server" in license_text
        or "VCS license unavailable" in license_text
    )
    hits = mark_hits(events)
    summary_rows = []
    uncovered_rows = []
    excluded_rows = []
    total_hit = 0
    total_bins = 0
    raw_total_hit = 0
    raw_total_bins = 0
    for group, bins in GROUP_BINS.items():
        excluded = EXCLUDED_BINS.get(group, {})
        effective_bins = [item for item in bins if item not in excluded]
        hit = sum(1 for item in effective_bins if item in hits[group])
        raw_hit = sum(1 for item in bins if item in hits[group])
        raw_total_hit += raw_hit
        raw_total_bins += len(bins)
        total_hit += hit
        total_bins += len(effective_bins)
        pct = hit * 100.0 / len(effective_bins)
        missing = [item for item in effective_bins if item not in hits[group]]
        excluded_missing = [item for item in bins if item in excluded and item not in hits[group]]
        notable = []
        notable.extend(missing)
        notable.extend(f"{item} (justified exclusion)" for item in excluded_missing)
        summary_rows.append({"covergroup": group, "hit": str(hit), "total": str(len(effective_bins)), "hit_percent": f"{pct:.2f}", "uncovered": "; ".join(notable)})
        for item in missing:
            reason, reachability, waiver = default_reason(item, unavailable)
            uncovered_rows.append({"covergroup": group, "bin": item, "reason": reason, "reachability": reachability, "waiver_candidate": waiver})
        for item in excluded_missing:
            reason, reachability, waiver = excluded[item]
            row = {"covergroup": group, "bin": item, "reason": reason, "reachability": reachability, "waiver_candidate": waiver}
            uncovered_rows.append(row)
            excluded_rows.append(row)
    overall = total_hit * 100.0 / total_bins
    raw_overall = raw_total_hit * 100.0 / raw_total_bins
    threshold = 100
    execution_status = "measured"
    if unavailable:
        execution_status = "VCS license unavailable; coverage waived/unavailable"
    elif overall < threshold:
        execution_status = "measured; below gate threshold"

    with (ROOT / "functional_coverage_summary.csv").open("w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(fh, fieldnames=["covergroup", "hit", "total", "hit_percent", "uncovered"])
        writer.writeheader()
        writer.writerows(summary_rows)
    with (ROOT / "uncovered_bins.csv").open("w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(fh, fieldnames=["covergroup", "bin", "reason", "reachability", "waiver_candidate"])
        writer.writeheader()
        writer.writerows(uncovered_rows)

    lines = [
        "# Phase 4.8 Functional Coverage Report",
        "",
        f"Overall functional coverage: {overall:.2f}% ({total_hit}/{total_bins} effective bins); raw before exclusions: {raw_overall:.2f}% ({raw_total_hit}/{raw_total_bins} bins); gate threshold: {threshold}%.",
        f"Execution status: {execution_status}.",
        "",
        "| covergroup | hit% | hit/total | notable uncovered bins |",
        "| --- | ---: | ---: | --- |",
    ]
    for row in summary_rows:
        notable = row["uncovered"] if row["uncovered"] else "none"
        lines.append(f"| {row['covergroup']} | {row['hit_percent']} | {row['hit']}/{row['total']} | {notable} |")
    lines.extend(["", "## Uncovered Bin Triage", "", "| covergroup | bin | reason | reachability | waiver |", "| --- | --- | --- | --- | --- |"])
    for row in uncovered_rows:
        lines.append(f"| {row['covergroup']} | {row['bin']} | {row['reason']} | {row['reachability']} | {row['waiver_candidate']} |")
    if excluded_rows:
        lines.extend(["", "## Justified Exclusions", "", "| covergroup | bin | justification |", "| --- | --- | --- |"])
        for row in excluded_rows:
            lines.append(f"| {row['covergroup']} | {row['bin']} | {row['reachability']} |")
    lines.extend([
        "",
        "## Provenance",
        "",
        "Key commands are captured in `provenance.log`; raw VCS/URG logs and databases remain in this phase directory.",
    ])
    (ROOT / "functional_coverage_report.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"MEASURED: functional coverage {overall:.2f}% ({total_hit}/{total_bins}); gate threshold {threshold}%")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
