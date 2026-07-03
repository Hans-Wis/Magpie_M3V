"""gate_20_axi_fabric — Phase 1 AXI4-Lite fabric brick.

Verifies the first net-new bus slice of the two-core M3V SoC:
  host AXI4-Lite master  ->  axil_1to2 router  ->  { NPU CSR slave @0x3xxx , passthrough mem }

Sim engine = **Verilator** (`--binary --timing`); VCS is the signoff track (OUTSIDE-SANDBOX).
Verilator lint (errors fatal) + Verilator sim asserting AXIL_FABRIC_PASS. Skips if verilator absent.
"""

import shutil
import subprocess
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
RTL = [ROOT / "IP/npu/rtl/axil_1to2.v", ROOT / "IP/npu/rtl/npu_axil_regs.v"]
TB = [ROOT / "IP/npu/dv/tb/axil_mem16.v", ROOT / "IP/npu/dv/tb/tb_axil_fabric.v"]
TOP = "tb_axil_fabric"
LINT_WAIVERS = ["-Wno-DECLFILENAME", "-Wno-MULTITOP", "-Wno-UNUSEDSIGNAL"]

# Since ADR-0034 (Phase 2 Step 4) npu_top instantiates the cpu_m1 sequencer, so every
# gate that elaborates npu_top needs the cpu_m1 sources + its include dir.
CPU_M1_DIR = ROOT / "IP/cpu_m1/rtl"
CPU_M1_RTL = [CPU_M1_DIR / f"{m}.v" for m in (
    "rfu", "alu", "bmu", "idu", "ifu", "lsu", "csr", "trigger", "pmp",
    "mul", "div", "forward", "hazard", "bp", "ras", "cdec", "core", "cpu_m1_top")]
CPU_M1_ARGS = [f"-I{CPU_M1_DIR}", "-Wno-TIMESCALEMOD"]


def verilator_lint(rtl, extra_args=()):
    r = subprocess.run(["verilator", "--lint-only", "-Wall", *LINT_WAIVERS, *extra_args,
                        *[str(p) for p in rtl]],
                       capture_output=True, text=True)
    assert "%Error" not in r.stderr, f"verilator lint errors:\n{r.stderr}"
    assert r.returncode == 0, f"verilator exited {r.returncode}:\n{r.stderr}"


def verilator_sim(tmp_path, top, files, pass_token, require_zero_errors=True, extra_args=()):
    mdir = tmp_path / "obj"
    b = subprocess.run(["verilator", "--binary", "--timing", "-Wno-fatal", "--top-module", top,
                        "-Mdir", str(mdir), *extra_args, *[str(p) for p in files]],
                       capture_output=True, text=True)
    assert (mdir / f"V{top}").exists(), f"verilator build failed:\n{b.stdout}\n{b.stderr}"
    out = subprocess.run([str(mdir / f"V{top}")], capture_output=True, text=True, timeout=180).stdout
    assert pass_token in out, f"sim did not pass ({pass_token} absent):\n{out}"
    if require_zero_errors:
        assert "0 errors" in out, f"scoreboard reported mismatches:\n{out}"


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_fabric_rtl_lints_clean_of_errors():
    verilator_lint(RTL)


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_fabric_scoreboard_passes(tmp_path):
    verilator_sim(tmp_path, TOP, RTL + TB, "AXIL_FABRIC_PASS")
