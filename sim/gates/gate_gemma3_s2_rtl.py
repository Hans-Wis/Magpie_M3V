"""gate_gemma3_s2_rtl — ADR-0062 S2 (F1.6): Gemma Q/K/V projection + QK-norm + RoPE
bit-exact on the NPU RTL.

  q = h @ Wq -> reshape[seq,nh,hd] -> RMSNorm(q_norm) -> RoPE     (nh=4)
  k = h @ Wk -> reshape[seq,nkv,hd] -> RMSNorm(k_norm) -> RoPE    (nkv=1)
  v = h @ Wv                                                       (projection only)

Projections run on the proven mat_engine; QK-norm reuses MAT_RMSNORM (H=head_dim); RoPE runs
on the sequencer core via the new MAT_ROPE op (Q15 cos/sin tables + rotate-half + gemmlowp
requant). Every checkpoint is chained through the ACTUAL RTL output of the previous step and
asserted byte-identical to the Tier-C golden (gemma_quant_s2).
"""
import shutil
import subprocess
import sys
from pathlib import Path

import numpy as np
import pytest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "sim/models"))
sys.path.insert(0, str(ROOT / "design/npu/sw/gemma"))
from gate_20_axi_fabric import CPU_M1_ARGS, CPU_M1_RTL  # noqa: E402
import tflm_runtime as rt  # noqa: E402
import gemma_ref as ref  # noqa: E402
import gemma_quant as gq  # noqa: E402
import gemma_quant_s1 as s1  # noqa: E402
import gemma_quant_s2 as s2  # noqa: E402
import gemma_runtime as gr  # noqa: E402

RTL = [ROOT / f"design/npu/rtl/{m}.v" for m in
       ("npu_top", "npu_axil_regs", "npu_dma", "npu_tcm", "axil_decerr", "mat_engine", "npu_ml_ctrl")]
RTL += CPU_M1_RTL
TB = [ROOT / "design/npu/dv/tb/axi_full_rwmem.v", ROOT / "design/npu/dv/tb/tb_npu_tflm_model.v"]
CASE = ROOT / "sim/work/tflm_model"
FIRMWARE = ROOT / "design/npu/sw/cq_sequencer/firmware.hex"


def _golden(seed=11):
    cfg = ref.CFG
    W = ref.make_weights(cfg)
    h = np.random.default_rng(seed).normal(0, 1.0, (cfg["seq"], cfg["hidden"])).astype(np.float32)
    return cfg, W, s2.s2_golden(h, W, cfg)


def _run(binary):
    out = subprocess.run([str(binary)], cwd=ROOT, capture_output=True,
                         text=True, timeout=300).stdout
    assert "NPU_TFLM_MODEL_PASS" in out and "0 errors" in out, out


def _reshape_heads(flat, seq, n, hd):
    """[seq][n*hd] -> [seq*n][hd] row-major."""
    return [flat[s][h * hd:(h + 1) * hd] for s in range(seq) for h in range(n)]


def test_s2_ssot():
    import cq_codec as c
    assert "MAT_ROPE" in c.OPCODES
    # RoPE requant multiplier lands in the gemmlowp engine shift range (honest scope)
    cfg, W, g = _golden()
    assert 0 <= g["q_rmeta"]["shift"] <= 62 and 0 <= g["k_rmeta"]["shift"] <= 62


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_s2_qkv_qknorm_rope_bit_exact_on_rtl(tmp_path):
    assert FIRMWARE.exists(), "firmware.hex missing — run make in design/npu/sw/cq_sequencer"
    cfg, W, g = _golden()
    seq, nh, nkv, hd = cfg["seq"], cfg["n_heads"], cfg["n_kv_heads"], cfg["head_dim"]
    hid = cfg["hidden"]
    h_q = g["h_q"].tolist()

    mdir = tmp_path / "obj"
    b = subprocess.run(["verilator", "--binary", "--timing", "-Wno-fatal",
                        "--top-module", "tb_npu_tflm_model", "-Mdir", str(mdir),
                        *CPU_M1_ARGS, *[str(p) for p in RTL + TB]],
                       capture_output=True, text=True)
    binary = mdir / "Vtb_npu_tflm_model"
    assert binary.exists(), f"build failed:\n{b.stdout}\n{b.stderr}"

    def gemm(w_fp, s_in, s_out, n, x_q):
        w_q, sw = gq.q_perchannel(w_fp.T)
        ng, nt = rt.emit_layer_v2(CASE, gr.gemm_layer(w_q, sw, s_in, s_out, hid, n),
                                  x_q, ring_entries=128)
        _run(binary)
        return rt.unpack_result_v2(CASE / "result.dump", ng, nt, seq, n)

    def qknorm(lin_rtl, nrm, n, s_out):
        rows = _reshape_heads(lin_rtl, seq, n, hd)
        gr.emit_rmsnorm_rows(CASE, rows, nrm, s1.RSQRT_C, s1.EPS_Q, s1.INV_SQRT2_Q16,
                             seq * n, hd)
        _run(binary)
        return gr.unpack_contiguous(CASE / "result.dump", seq * n, hd)

    def rope(norm_rtl, rmeta, n):
        x = [[norm_rtl[p * n + h] for h in range(n)] for p in range(seq)]
        gr.emit_rope(CASE, x, g["cos_q"], g["sin_q"], rmeta, seq, n, hd)
        _run(binary)
        return gr.unpack_contiguous(CASE / "result.dump", seq * n, hd)

    # --- Q path: proj -> QK-norm -> RoPE ---
    q_lin = gemm(W["q_proj"], g["s_h"], g["s_q"], nh * hd, h_q)
    assert q_lin == g["q_lin"].tolist(), "q_proj GEMM RTL != golden"
    q_n = qknorm(q_lin, g["q_nrm"], nh, g["s_qn"])
    assert q_n == g["q_n"].reshape(seq * nh, hd).tolist(), "QK-norm(q) RTL != golden"
    q_r = rope(q_n, g["q_rmeta"], nh)
    assert q_r == g["q_r"].reshape(seq * nh, hd).tolist(), "RoPE(q) RTL != golden"

    # --- K path: proj -> QK-norm -> RoPE ---
    k_lin = gemm(W["k_proj"], g["s_h"], g["s_k"], nkv * hd, h_q)
    assert k_lin == g["k_lin"].tolist(), "k_proj GEMM RTL != golden"
    k_n = qknorm(k_lin, g["k_nrm"], nkv, g["s_kn"])
    assert k_n == g["k_n"].reshape(seq * nkv, hd).tolist(), "QK-norm(k) RTL != golden"
    k_r = rope(k_n, g["k_rmeta"], nkv)
    assert k_r == g["k_r"].reshape(seq * nkv, hd).tolist(), "RoPE(k) RTL != golden"

    # --- V path: projection only ---
    v_lin = gemm(W["v_proj"], g["s_h"], g["s_v"], nkv * hd, h_q)
    assert v_lin == g["v_lin"].tolist(), "v_proj GEMM RTL != golden (full S2)"
