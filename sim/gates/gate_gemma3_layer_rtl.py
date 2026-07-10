"""gate_gemma3_layer_rtl — ADR-0062 S4+S5 (F1.6): the FULL Gemma-3 decoder layer bit-exact
on the NPU RTL.

Runs the entire int8 chain on the NPU, feeding each step's ACTUAL RTL output into the next
(mat_engine GEMMs for every projection/QK^T/AV; sequencer-core ops for RMSNorm/RoPE/softmax/
gelu/mul/residual). Asserts every checkpoint byte-identical to the Tier-C golden
(gemma_quant_layer). S4 milestone = x_mid (attention residual); S5 = x_out (full layer).
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
import gemma_quant_s3 as s3  # noqa: E402
import gemma_quant_layer as gl  # noqa: E402
import gemma_runtime as gr  # noqa: E402

RTL = [ROOT / f"design/npu/rtl/{m}.v" for m in
       ("npu_top", "npu_axil_regs", "npu_dma", "npu_tcm", "axil_decerr", "mat_engine", "npu_ml_ctrl", "npu_strip_buf")]
RTL += CPU_M1_RTL
TB = [ROOT / "design/npu/dv/tb/axi_full_rwmem.v", ROOT / "design/npu/dv/tb/tb_npu_tflm_model.v"]
CASE = ROOT / "sim/work/tflm_model"
FIRMWARE = ROOT / "design/npu/sw/cq_sequencer/firmware.hex"
_C = (s1.RSQRT_C, s1.EPS_Q, s1.INV_SQRT2_Q16)


@pytest.mark.skipif(not shutil.which("verilator"), reason="no verilator — not-run")
def test_full_decoder_layer_bit_exact_on_rtl(tmp_path):
    assert FIRMWARE.exists(), "firmware.hex missing — run make in design/npu/sw/cq_sequencer"
    cfg = ref.CFG
    W = ref.make_weights(cfg)
    x = np.random.default_rng(23).normal(0, 1.0, (cfg["seq"], cfg["hidden"])).astype(np.float32)
    ck = gl.layer_int8(x, W, cfg)
    seq, nh, nkv, hd = cfg["seq"], cfg["n_heads"], cfg["n_kv_heads"], cfg["head_dim"]
    hid, inter = cfg["hidden"], cfg["intermediate"]
    scale = 1.0 / np.sqrt(cfg["query_pre_attn_scalar"])

    mdir = tmp_path / "obj"
    b = subprocess.run(["verilator", "--binary", "--timing", "-Wno-fatal",
                        "--top-module", "tb_npu_tflm_model", "-Mdir", str(mdir),
                        *CPU_M1_ARGS, *[str(p) for p in RTL + TB]],
                       capture_output=True, text=True)
    binary = mdir / "Vtb_npu_tflm_model"
    assert binary.exists(), f"build failed:\n{b.stdout}\n{b.stderr}"

    def run():
        out = subprocess.run([str(binary)], cwd=ROOT, capture_output=True,
                             text=True, timeout=300).stdout
        assert "NPU_TFLM_MODEL_PASS" in out and "0 errors" in out, out

    def gemm(w_fp_or_pad, sw, s_in, s_out, k, n, rows, perchan=None):
        w = w_fp_or_pad if perchan is None else perchan
        ng, nt = rt.emit_layer_v2(CASE, gr.gemm_layer(w, sw, s_in, s_out, k, n),
                                  rows, ring_entries=256)
        run()
        return rt.unpack_result_v2(CASE / "result.dump", ng, nt, len(rows), n)

    def proj(w_fp, s_in, s_out, rows):
        w_q, sw = gq.q_perchannel(w_fp.T)
        return gemm(None, sw, s_in, s_out, w_q.shape[1], w_q.shape[0], rows, perchan=w_q)

    def rmsnorm(rows, nrm, s_out, H):
        gr.emit_rmsnorm_rows(CASE, rows, nrm, *_C, len(rows), H)
        run()
        return gr.unpack_contiguous(CASE / "result.dump", len(rows), H)

    def rope(x3, rmeta, n):
        gr.emit_rope(CASE, x3, ck["cos_q"], ck["sin_q"], rmeta, seq, n, hd)
        run()
        return gr.unpack_contiguous(CASE / "result.dump", seq * n, hd)

    def residual(r_rows, a_rows, res, H):
        gr.emit_add_requant(CASE, r_rows, a_rows, {"res": res}, seq, H)
        run()
        return gr.unpack_contiguous(CASE / "result.dump", seq, H)

    x_q = ck["x_q"].tolist()

    # ===== attention sub-block =====
    hin = rmsnorm(x_q, ck["nrm_in"], ck["s_hin"], hid)
    assert hin == ck["hin_q"].tolist(), "RMSNorm_in"

    q_lin = proj(W["q_proj"], ck["s_hin"], ck["s_q"], hin)
    k_lin = proj(W["k_proj"], ck["s_hin"], ck["s_k"], hin)
    v_lin = proj(W["v_proj"], ck["s_hin"], ck["s_v"], hin)
    assert v_lin == ck["v_lin"].tolist(), "v_proj"

    qn = rmsnorm([q_lin[s][h * hd:(h + 1) * hd] for s in range(seq) for h in range(nh)],
                 ck["q_nrm"], ck["s_qn"], hd)
    kn = rmsnorm([k_lin[s][0:hd] for s in range(seq)], ck["k_nrm"], ck["s_kn"], hd)

    qr = rope([[qn[p * nh + h] for h in range(nh)] for p in range(seq)], ck["q_rmeta"], nh)
    kr = rope([[kn[p] for _ in range(nkv)] for p in range(seq)], ck["k_rmeta"], nkv)
    assert qr == ck["qr_q"].reshape(seq * nh, hd).tolist(), "RoPE(q)"

    qr3 = [[qr[p * nh + h] for h in range(nh)] for p in range(seq)]
    rows_q = [qr3[p][h] for h in range(nh) for p in range(seq)]
    k_h = [kr[p] for p in range(seq)]
    k_pad = [list(r) for r in k_h] + [[0] * hd for _ in range(8 - seq)]
    scores = gemm(None, [ck["s_kr"]] * 8, ck["s_qr"], ck["g3"]["s_score"] / scale, hd, 8,
                  rows_q, perchan=k_pad)
    scores = [row[:seq] for row in scores]
    assert scores == ck["g3"]["scores"].tolist(), "QK^T"

    valids = [(r % seq) + 1 for r in range(nh * seq)]
    gr.emit_softmax(CASE, scores, ck["g3"]["lut"].tolist(), seq, nh * seq, valids, s3.PROB_SCALE)
    run()
    prob = gr.unpack_contiguous(CASE / "result.dump", nh * seq, seq)
    assert prob == ck["g3"]["prob"].tolist(), "softmax"

    v_t = [[v_lin[p][d] for p in range(seq)] + [0] * (8 - seq) for d in range(hd)]
    prob_pad = [list(r) + [0] * (8 - seq) for r in prob]
    av = gemm(None, [ck["s_v"]] * hd, ck["g3"]["s_prob"], ck["g3"]["s_av"], 8, hd, prob_pad,
              perchan=v_t)
    attn = [[0] * (nh * hd) for _ in range(seq)]
    for h in range(nh):
        for p in range(seq):
            attn[p][h * hd:(h + 1) * hd] = av[h * seq + p]
    assert attn == ck["attn_q"].tolist(), "AV/attn"

    ao = proj(W["o_proj"], ck["s_attn"], ck["s_ao"], attn)
    assert ao == ck["ao_q"].tolist(), "o_proj"
    an = rmsnorm(ao, ck["nrm_pa"], ck["s_an"], hid)
    xmid = residual(x_q, an, ck["res1"], hid)
    assert xmid == ck["xmid_q"].tolist(), "S4 attention residual (x_mid)"

    # ===== MLP sub-block =====
    hff = rmsnorm(xmid, ck["nrm_pf"], ck["s_hff"], hid)
    gate_lin = proj(W["gate_proj"], ck["s_hff"], ck["s_gate"], hff)
    up_lin = proj(W["up_proj"], ck["s_hff"], ck["s_up"], hff)

    gr.emit_act_lut(CASE, gate_lin, ck["lut"].tolist(), seq, inter)
    run()
    gelu = gr.unpack_contiguous(CASE / "result.dump", seq, inter)
    assert gelu == ck["gelu_q"].tolist(), "gelu LUT"

    m_qmul, m_shift = ck["m_ewise"]
    gr.emit_ewise_mul(CASE, gelu, up_lin, m_qmul, 31 - m_shift, seq, inter)
    run()
    prod = gr.unpack_contiguous(CASE / "result.dump", seq, inter)
    assert prod == ck["prod_q"].tolist(), "ewise mul"

    m_lin = proj(W["down_proj"], ck["s_prod"], ck["s_m"], prod)
    mn = rmsnorm(m_lin, ck["nrm_pff"], ck["s_mn"], hid)
    xout = residual(xmid, mn, ck["res2"], hid)
    assert xout == ck["xout_q"].tolist(), "S5 full decoder layer (x_out)"
