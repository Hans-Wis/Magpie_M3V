"""gate_gemma3_s3_rtl — ADR-0062 S3 (F1.6): Gemma QK^T + causal mask + softmax + AV
bit-exact on the NPU RTL, batched over heads (GQA nkv=1).

  scores = QK^T (mat_engine, per-tensor requant, *1/sqrt(qpre) folded, key-dim padded to 8)
  prob   = softmax(scores, causal valid=p+1)   (MAT_SOFTMAX on the sequencer core)
  av     = prob @ v (mat_engine, key-dim padded to 8)
  attn[p, h*hd+d] = av[h*seq+p, d]

The two matmuls reuse the proven per-channel GEMM (== gemm_pc); softmax is the new op.
Every checkpoint is chained through the ACTUAL RTL output and asserted byte-identical to the
Tier-C golden (gemma_quant_s3).
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
import gemma_quant_s2 as s2  # noqa: E402
import gemma_quant_s3 as s3  # noqa: E402
import gemma_runtime as gr  # noqa: E402

RTL = [ROOT / f"design/npu/rtl/{m}.v" for m in
       ("npu_top", "npu_axil_regs", "npu_dma", "npu_tcm", "axil_decerr", "mat_engine")]
RTL += CPU_M1_RTL
TB = [ROOT / "design/npu/dv/tb/axi_full_rwmem.v", ROOT / "design/npu/dv/tb/tb_npu_tflm_model.v"]
CASE = ROOT / "sim/work/tflm_model"
FIRMWARE = ROOT / "design/npu/sw/cq_sequencer/firmware.hex"


def _golden(seed=11):
    cfg = ref.CFG
    W = ref.make_weights(cfg)
    h = np.random.default_rng(seed).normal(0, 1.0, (cfg["seq"], cfg["hidden"])).astype(np.float32)
    g2 = s2.s2_golden(h, W, cfg)
    v_q = g2["v_lin"].reshape(cfg["seq"], cfg["n_kv_heads"], cfg["head_dim"])
    v_fp = (h @ W["v_proj"]).reshape(cfg["seq"], cfg["n_kv_heads"], cfg["head_dim"])
    g3 = s3.s3_golden(g2["q_r"], g2["s_qr"], g2["k_r"], g2["s_kr"], v_q, g2["s_v"], cfg,
                      g2["q_rope_fp"], g2["k_rope_fp"], v_fp)
    return cfg, g2, g3


def _run(binary):
    out = subprocess.run([str(binary)], cwd=ROOT, capture_output=True,
                         text=True, timeout=300).stdout
    assert "NPU_TFLM_MODEL_PASS" in out and "0 errors" in out, out


def _pad_rows(mat, ncols):
    return [list(r) + [0] * (ncols - len(r)) for r in mat]


def test_s3_ssot():
    import cq_codec as c
    assert "MAT_SOFTMAX" in c.OPCODES
    cfg, g2, g3 = _golden()
    # prob rows sum to ~PROB_SCALE over the causal-valid span
    for p in range(cfg["seq"]):
        assert abs(int(g3["prob"][p].sum()) - s3.PROB_SCALE) <= 2


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_s3_attention_bit_exact_on_rtl(tmp_path):
    assert FIRMWARE.exists(), "firmware.hex missing — run make in design/npu/sw/cq_sequencer"
    cfg, g2, g3 = _golden()
    seq, nh, hd = cfg["seq"], cfg["n_heads"], cfg["head_dim"]
    scale = 1.0 / np.sqrt(cfg["query_pre_attn_scalar"])
    nrows = nh * seq

    mdir = tmp_path / "obj"
    b = subprocess.run(["verilator", "--binary", "--timing", "-Wno-fatal",
                        "--top-module", "tb_npu_tflm_model", "-Mdir", str(mdir),
                        *CPU_M1_ARGS, *[str(p) for p in RTL + TB]],
                       capture_output=True, text=True)
    binary = mdir / "Vtb_npu_tflm_model"
    assert binary.exists(), f"build failed:\n{b.stdout}\n{b.stderr}"

    def gemm(w_pad, sw, s_in, s_out, k, n, rows):
        ng, nt = rt.emit_layer_v2(CASE, gr.gemm_layer(w_pad, sw, s_in, s_out, k, n),
                                  rows, ring_entries=128)
        _run(binary)
        return ng, nt

    # --- step 1: QK^T scores (mat_engine, key positions padded to 8) ---
    k_pad = _pad_rows(g3["k_h"].tolist(), hd) + [[0] * hd for _ in range(8 - seq)]
    ng, nt = gemm(k_pad, [g2["s_kr"]] * 8, g2["s_qr"], g3["s_score"] / scale, hd, 8,
                  g3["rows_q"].tolist())
    scores_rtl = rt.unpack_result_v2(CASE / "result.dump", ng, nt, nrows, 8)
    scores_rtl = [row[:seq] for row in scores_rtl]
    assert scores_rtl == g3["scores"].tolist(), "QK^T RTL != golden"

    # --- step 2: softmax (sequencer core), chained from RTL scores ---
    valids = [(r % seq) + 1 for r in range(nrows)]
    gr.emit_softmax(CASE, scores_rtl, g3["lut"].tolist(), seq, nrows, valids, s3.PROB_SCALE)
    _run(binary)
    prob_rtl = gr.unpack_contiguous(CASE / "result.dump", nrows, seq)
    assert prob_rtl == g3["prob"].tolist(), "softmax RTL != golden"

    # --- step 3: AV (mat_engine, key-dim padded to 8), chained from RTL prob ---
    vt_pad = [list(g3["v_t"][d]) + [0] * (8 - seq) for d in range(hd)]
    prob_pad = _pad_rows(prob_rtl, 8)
    ng, nt = gemm(vt_pad, [g2["s_v"]] * hd, g3["s_prob"], g3["s_av"], 8, hd, prob_pad)
    av_rtl = rt.unpack_result_v2(CASE / "result.dump", ng, nt, nrows, hd)
    assert av_rtl == g3["av"].tolist(), "AV RTL != golden"

    attn = [[0] * (nh * hd) for _ in range(seq)]
    for h in range(nh):
        for p in range(seq):
            attn[p][h * hd:(h + 1) * hd] = av_rtl[h * seq + p]
    assert attn == g3["attn"].tolist(), "assembled attention RTL != golden (full S3)"
