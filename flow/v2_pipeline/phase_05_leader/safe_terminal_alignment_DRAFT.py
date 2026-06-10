# DRAFT — Grok-safe terminal alignment (to REPLACE the fragile dut[:_i+2] truncation
# at run_riscvdv_lockstep.py ~line 482, once J19 frees the harness). Apply after J19.
#
# WHY (Grok adversarial review J2, DISAGREE/material-risk): `dut = dut[:_i+2]` assumes
# write_tohost is exactly auipc+sw AND can HIDE a real divergence that routes the DUT
# into write_tohost early (the surgically-shortened prefix looks matching). The "no
# masking" claim was false once the trace is surgically shortened.
#
# SAFE version: trim EACH side at its OWN architectural exit (first commit whose pc is
# the write_tohost symbol), then let compare_commits run. This does NOT mask:
#  - a per-commit divergence before exit is caught normally;
#  - a divergence that drives the DUT into write_tohost early gives de < se -> the
#    commit at the divergence point mismatches (DUT pc==write_tohost vs Spike normal),
#    so compare_commits flags it;
#  - a remaining exit-index difference shows up as a count mismatch (not hidden).

_wt = elf_symbol(work, "write_tohost")  # raises if missing; guard with try if optional

def _exit_idx(commits):
    for i, c in enumerate(commits):
        if c["pc"] == _wt:
            return i
    return None

_de, _se = _exit_idx(dut), _exit_idx(spike)
# trim each at ITS OWN exit (include the tohost-store commit). Symmetric; not surgical.
if _de is not None:
    dut = dut[:_de + 1]
if _se is not None:
    spike = spike[:_se + 1]
# Optional hardening (Grok): if both reached exit but |_de - _se| is large, emit a
# warning artifact and do NOT count this seed toward the zero-divergence total.
