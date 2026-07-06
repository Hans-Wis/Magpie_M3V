"""gate_a2_zb_zicond - ADR-0026 Phase A2: Zba+Zbb+Zbs+Zicond (BMU) + decode tightening.

A2 scope: bmu.v (separate single-cycle bit-manip unit; heavy ops kept out of the base ALU
case mux), idu decode for all 26 ops + RESERVED-slot tightening in the OP/OP-IMM-shift space
(the M1 baseline silently wrong-decoded reserved funct7 encodings as base ops), misa.B
(Spike --priv=m parity = 0x40001106), farm/lib harness on the A2 ISA string.

Asserts:
  1. toolchain acceptance (probe + DESIGN_MAP committed — was verified BEFORE RTL per ADR)
  2. directed full lockstep PASS (all ops, sign/edge operands, misa.B read, cross-unit
     forwarding BMU<->ALU<->MUL<->load; >=55 commits)
  3. illegal negative test: 4 reserved encodings trap mcause=2 (evidence log + trace)
  4. CoreMark KPI: >=2.9 CoreMark/MHz with Zb codegen (honest matrix documented: O2/zb 2.74,
     O3/zb 3.23 — flags contribute most; Zb ISA ~+3%; the ADR's -15% instr budget was
     optimistic and is corrected in the A2 record)
  5. RTL really has the BMU + tightened decode + misa.B
"""

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
A2 = ROOT / "flow/v2_pipeline/phase_a2_zb_zicond"
BENCH = ROOT / "flow/v2_pipeline/phase_b0_benchmarks"


def test_a2_toolchain_acceptance_artifacts():
    assert (A2 / "toolchain_probe.S").exists()
    assert "VERIFIED" in (A2 / "DESIGN_MAP.md").read_text()


def test_a2_directed_full_lockstep_pass():
    log = (A2 / "a2_zb.log").read_text()
    assert log.lstrip().startswith("PASS"), f"a2 directed not PASS: {log!r}"
    m = re.search(r"matched (\d+) commits", log)
    assert m and int(m.group(1)) >= 55


def test_a2_illegal_reserved_encodings_trap():
    assert "PASS" in (A2 / "illegal_test.log").read_text()
    trace = (A2 / "illegal_dut_commit.trace").read_text()
    # the counter (x27) must reach 4 = all four reserved encodings trapped with mcause=2
    assert re.search(r",27,00000004$", trace, re.M), "illegal-trap count never reached 4"


def test_a2_coremark_kpi():
    log = (BENCH / "coremark_run.log").read_text()
    m = re.search(r"M1_BENCH: cycles=(\d+) instret=(\d+)", log)
    assert m, "no M1_BENCH line"
    cm_per_mhz = 10 * 1_000_000 / int(m.group(1))   # ITERATIONS=10
    assert cm_per_mhz >= 2.9, f"CoreMark/MHz {cm_per_mhz:.2f} < 2.9 KPI"


def test_a2_rtl_has_bmu_and_tightened_decode():
    assert (ROOT / "design/cpu_m1/rtl/bmu.v").exists()
    idu = (ROOT / "design/cpu_m1/rtl/idu.v").read_text()
    assert "bmu_slot_illegal" in idu and "BMU_CZEQZ" in idu
    csr = (ROOT / "design/cpu_m1/rtl/csr.v").read_text()
    assert "(26'h1 << 1)" in csr, "misa.B not set"
    core = (ROOT / "design/cpu_m1/rtl/core.v").read_text()
    assert "id_is_bmu ? bmu_result : alu_result" in core
