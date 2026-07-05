"""gate_51_offload_closure — ADR-0043: the offload row closes.

(a) 2D/strided DMA through the CQ (tb_npu_cq_strided): LOAD_W W2=row-stride
    gathers a strided shared block into the TCM (verified word-for-word via a
    contiguous STORE readback); STORE W3[31:16]=dst stride scatters rows into
    a larger tensor with the gaps holding their sentinels; misaligned / short
    strides halt with MAT_PARAM (sanitizer ladder).
(b) Host ring-producer ABI (cq_host.CqProducer): RING_OVERRUN prevented by
    producer discipline — free-space math across wrap, all-or-nothing push
    (CqFull), and the fence hook ordered STRICTLY before the TAIL doorbell
    (cache-flush-before-doorbell contract; SoC integration = Phase 7).
(c) Firmware footprint guard: text+bss must stay below the 0x700 weight
    region — LOAD_W overwriting live statics was a real near-miss this phase.
"""

import shutil
import subprocess
import sys
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "IP/npu/sw/host"))
from gate_20_axi_fabric import CPU_M1_ARGS, CPU_M1_RTL, verilator_sim  # noqa: E402
from cq_host import CqFull, CqProducer  # noqa: E402

RTL = [ROOT / f"IP/npu/rtl/{m}.v" for m in
       ("npu_top", "npu_axil_regs", "npu_dma", "npu_tcm", "axil_decerr", "mat_engine")]
RTL += CPU_M1_RTL
TB = [ROOT / "IP/npu/dv/tb/axi_full_rwmem.v", ROOT / "IP/npu/dv/tb/tb_npu_cq_strided.v"]


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_strided_gather_scatter_and_sanitizers(tmp_path):
    verilator_sim(tmp_path, "tb_npu_cq_strided", RTL + TB, "NPU_CQ_STRIDED_PASS",
                  extra_args=CPU_M1_ARGS)


def _producer(size=8, head=0):
    state = dict(head=head, tail=None, slots={})
    p = CqProducer(size,
                   read_head=lambda: state["head"],
                   write_tail=lambda t: state.__setitem__("tail", t),
                   write_slot=lambda s, d: state["slots"].__setitem__(s, list(d)))
    return p, state


def test_producer_refuses_overrun():
    p, _ = _producer(size=8, head=0)
    p.push([[1, 0, 0, 0]] * 7)               # exactly the 7 free slots
    with pytest.raises(CqFull):
        p.push([[1, 0, 0, 0]])               # slot 8 would land on HEAD
    p.commit()


def test_producer_free_space_wraps():
    p, state = _producer(size=8, head=0)
    p.push([[1, 0, 0, 0]] * 6)
    p.commit()
    state["head"] = 6                        # consumer caught up
    assert p.free_entries() == 7
    p.push([[2, 0, 0, 0]] * 7)               # wraps physically
    p.commit()
    assert state["tail"] == (6 + 7) % 8
    assert set(state["slots"]) == set(range(8))


def test_fence_strictly_before_doorbell():
    p, _ = _producer()
    p.push([[1, 0, 0, 0]])
    p.commit()
    kinds = [e[0] for e in p._log]
    assert kinds.index("fence") < kinds.index("doorbell"), \
        "flush-before-doorbell contract violated"


def test_codec_encodes_scatter():
    sys.path.insert(0, str(ROOT / "IP/npu/sw"))
    import cq_codec
    d = cq_codec.decode(cq_codec.encode(
        "MAT_STORE", dst_addr=0x80001900, src_tcm_byte=0x680,
        dst_stride_words=6, rows=3, cols=4, last=1))
    assert d["dst_stride_words"] == 6 and d["src_tcm_byte"] == 0x680
    assert d["rows"] == 3 and d["cols"] == 4
    g = cq_codec.decode(cq_codec.encode(
        "MAT_LOAD_W", src_addr=0x80002000, src_row_stride_bytes=32,
        rows=3, cols=4))
    assert g["stride"] == 32


def test_firmware_stays_below_weight_region():
    size = ROOT / "IP/npu/sw/cq_sequencer/firmware.elf"
    r = subprocess.run(["riscv64-unknown-elf-size", str(size)],
                       capture_output=True, text=True,
                       env={"PATH": "/home/edauser/miniforge3/pkgs/"
                            "riscv-tools-1.0.6-0_h1234567_g56c29e0/riscv-tools/bin"})
    if r.returncode != 0:
        pytest.skip("riscv size tool unavailable — not-run")
    text, data, bss = [int(x) for x in r.stdout.splitlines()[1].split()[:3]]
    assert text + data + bss <= 0x700, \
        f"firmware {text + data + bss}B collides with the 0x700 weight region"
