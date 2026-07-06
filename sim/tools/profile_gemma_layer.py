#!/usr/bin/env python3
"""profile_gemma_layer — ADR-0062 cycle-profile of the full Gemma-3 decoder layer on the NPU
RTL. Runs the same host-chained chain as gate_gemma3_layer_rtl, but captures the TB's
NPU_PROFILE line (total / mat-engine-busy / dma-busy / sequencer-retire cycles) per step and
prints a per-step + by-class breakdown. Measurement, not a pass/fail gate.

Usage:  python sim/tools/profile_gemma_layer.py
"""
import re
import shutil
import subprocess
import sys
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "sim/models"))
sys.path.insert(0, str(ROOT / "sim/gates"))
sys.path.insert(0, str(ROOT / "design/npu/sw/gemma"))
import tflm_runtime as rt          # noqa: E402
import gemma_ref as ref            # noqa: E402
import gemma_quant as gq           # noqa: E402
import gemma_quant_s1 as s1        # noqa: E402
import gemma_quant_s3 as s3        # noqa: E402
import gemma_quant_layer as gl     # noqa: E402
import gemma_runtime as gr         # noqa: E402
from gate_20_axi_fabric import CPU_M1_ARGS, CPU_M1_RTL  # noqa: E402

RTL = [ROOT / f"design/npu/rtl/{m}.v" for m in
       ("npu_top", "npu_axil_regs", "npu_dma", "npu_tcm", "axil_decerr", "mat_engine")] + CPU_M1_RTL
TB = [ROOT / "design/npu/dv/tb/axi_full_rwmem.v", ROOT / "design/npu/dv/tb/tb_npu_tflm_model.v"]
CASE = ROOT / "sim/work/tflm_model"
_C = (s1.RSQRT_C, s1.EPS_Q, s1.INV_SQRT2_Q16)
_PAT = re.compile(r"NPU_PROFILE total=(\d+) mat=(\d+) dma=(\d+) ret=(\d+) run=(\d+) rsc=(\d+)")

records = []   # (label, kind, total, mat, dma, ret, run, rsc)


def build(mdir):
    b = subprocess.run(["verilator", "--binary", "--timing", "-Wno-fatal",
                        "--top-module", "tb_npu_tflm_model", "-Mdir", str(mdir),
                        *CPU_M1_ARGS, *[str(p) for p in RTL + TB]],
                       capture_output=True, text=True)
    binary = mdir / "Vtb_npu_tflm_model"
    assert binary.exists(), f"build failed:\n{b.stdout[-3000:]}\n{b.stderr[-3000:]}"
    return binary


def run(binary, label, kind):
    out = subprocess.run([str(binary)], cwd=ROOT, capture_output=True, text=True, timeout=300).stdout
    assert "NPU_TFLM_MODEL_PASS" in out, out
    m = _PAT.search(out)
    tot, mat, dma, ret, run, rsc = (int(x) for x in m.groups())
    records.append((label, kind, tot, mat, dma, ret, run, rsc))
    return CASE / "result.dump"


def main():
    cfg = ref.CFG
    W = ref.make_weights(cfg)
    x = np.random.default_rng(23).normal(0, 1.0, (cfg["seq"], cfg["hidden"])).astype(np.float32)
    ck = gl.layer_int8(x, W, cfg)
    seq, nh, nkv, hd = cfg["seq"], cfg["n_heads"], cfg["n_kv_heads"], cfg["head_dim"]
    hid, inter = cfg["hidden"], cfg["intermediate"]
    scale = 1.0 / np.sqrt(cfg["query_pre_attn_scalar"])

    mdir = ROOT / "sim/work/prof_obj"
    if not shutil.which("verilator"):
        print("no verilator — not-run")
        return
    print("building Verilator (npu_top + cpu_m1) ...")
    binary = build(mdir)

    def gemm(label, w, sw, s_in, s_out, k, n, rows):
        ng, nt = rt.emit_layer_v2(CASE, gr.gemm_layer(w, sw, s_in, s_out, k, n), rows, ring_entries=256)
        run(binary, label, "GEMM")
        return rt.unpack_result_v2(CASE / "result.dump", ng, nt, len(rows), n)

    def proj(label, w_fp, s_in, s_out, rows):
        w_q, sw = gq.q_perchannel(w_fp.T)
        return gemm(label, w_q, sw, s_in, s_out, w_q.shape[1], w_q.shape[0], rows)

    def rmsnorm(label, rows, nrm, s_out, H):
        gr.emit_rmsnorm_rows(CASE, rows, nrm, *_C, len(rows), H)
        run(binary, label, "nonlin")
        return gr.unpack_contiguous(CASE / "result.dump", len(rows), H)

    def rope(label, x3, rmeta, n):
        gr.emit_rope(CASE, x3, ck["cos_q"], ck["sin_q"], rmeta, seq, n, hd)
        run(binary, label, "nonlin")
        return gr.unpack_contiguous(CASE / "result.dump", seq * n, hd)

    def residual(label, r_rows, a_rows, res, H):
        gr.emit_add_requant(CASE, r_rows, a_rows, {"res": res}, seq, H)
        run(binary, label, "nonlin")
        return gr.unpack_contiguous(CASE / "result.dump", seq, H)

    x_q = ck["x_q"].tolist()
    # ---- attention sub-block ----
    hin = rmsnorm("RMSNorm_in", x_q, ck["nrm_in"], ck["s_hin"], hid)
    q_lin = proj("q_proj", W["q_proj"], ck["s_hin"], ck["s_q"], hin)
    k_lin = proj("k_proj", W["k_proj"], ck["s_hin"], ck["s_k"], hin)
    v_lin = proj("v_proj", W["v_proj"], ck["s_hin"], ck["s_v"], hin)
    qn = rmsnorm("QK-norm_q", [q_lin[s][h * hd:(h + 1) * hd] for s in range(seq) for h in range(nh)],
                 ck["q_nrm"], ck["s_qn"], hd)
    kn = rmsnorm("QK-norm_k", [k_lin[s][0:hd] for s in range(seq)], ck["k_nrm"], ck["s_kn"], hd)
    qr = rope("RoPE_q", [[qn[p * nh + h] for h in range(nh)] for p in range(seq)], ck["q_rmeta"], nh)
    kr = rope("RoPE_k", [[kn[p] for _ in range(nkv)] for p in range(seq)], ck["k_rmeta"], nkv)

    qr3 = [[qr[p * nh + h] for h in range(nh)] for p in range(seq)]
    rows_q = [qr3[p][h] for h in range(nh) for p in range(seq)]
    k_pad = [list(kr[p]) for p in range(seq)] + [[0] * hd for _ in range(8 - seq)]
    scores = gemm("QK^T", k_pad, [ck["s_kr"]] * 8, ck["s_qr"], ck["g3"]["s_score"] / scale, hd, 8, rows_q)
    scores = [row[:seq] for row in scores]
    valids = [(r % seq) + 1 for r in range(nh * seq)]
    gr.emit_softmax(CASE, scores, ck["g3"]["lut"].tolist(), seq, nh * seq, valids, s3.PROB_SCALE)
    run(binary, "softmax", "nonlin")
    prob = gr.unpack_contiguous(CASE / "result.dump", nh * seq, seq)

    v_t = [[v_lin[p][d] for p in range(seq)] + [0] * (8 - seq) for d in range(hd)]
    prob_pad = [list(r) + [0] * (8 - seq) for r in prob]
    av = gemm("AV", v_t, [ck["s_v"]] * hd, ck["g3"]["s_prob"], ck["g3"]["s_av"], 8, hd, prob_pad)
    attn = [[0] * (nh * hd) for _ in range(seq)]
    for h in range(nh):
        for p in range(seq):
            attn[p][h * hd:(h + 1) * hd] = av[h * seq + p]
    ao = proj("o_proj", W["o_proj"], ck["s_attn"], ck["s_ao"], attn)
    an = rmsnorm("RMSNorm_postattn", ao, ck["nrm_pa"], ck["s_an"], hid)
    xmid = residual("residual_1", x_q, an, ck["res1"], hid)

    # ---- MLP sub-block ----
    hff = rmsnorm("RMSNorm_preffn", xmid, ck["nrm_pf"], ck["s_hff"], hid)
    gate_lin = proj("gate_proj", W["gate_proj"], ck["s_hff"], ck["s_gate"], hff)
    up_lin = proj("up_proj", W["up_proj"], ck["s_hff"], ck["s_up"], hff)
    gr.emit_act_lut(CASE, gate_lin, ck["lut"].tolist(), seq, inter)
    run(binary, "gelu_LUT", "nonlin")
    gelu = gr.unpack_contiguous(CASE / "result.dump", seq, inter)
    m_qmul, m_shift = ck["m_ewise"]
    gr.emit_ewise_mul(CASE, gelu, up_lin, m_qmul, 31 - m_shift, seq, inter)
    run(binary, "ewise_mul", "nonlin")
    prod = gr.unpack_contiguous(CASE / "result.dump", seq, inter)
    m_lin = proj("down_proj", W["down_proj"], ck["s_prod"], ck["s_m"], prod)
    mn = rmsnorm("RMSNorm_postffn", m_lin, ck["nrm_pff"], ck["s_mn"], hid)
    residual("residual_2", xmid, mn, ck["res2"], hid)

    # ---- useful MACs (analytic, from dims) ----
    useful = (seq * (nh * hd) * hid + 2 * seq * (nkv * hd) * hid          # q,k,v proj
              + nh * seq * seq * hd + nh * seq * hd * seq                  # QK^T, AV
              + seq * hid * (nh * hd)                                      # o_proj
              + 2 * seq * inter * hid + seq * hid * inter)                 # gate,up,down

    # ---- report ----
    w = max(len(r[0]) for r in records)
    print(f"\n{'step':<{w}}  {'kind':<7} {'total':>7} {'mat':>7} {'run':>6} {'rsc':>6} "
          f"{'dma':>7} {'core*':>7}")
    print("-" * (w + 48))
    for lab, kind, tot, mat, dma, ret, rn, rc in records:
        core = tot - mat - dma
        print(f"{lab:<{w}}  {kind:<7} {tot:>7} {mat:>7} {rn:>6} {rc:>6} {dma:>7} {core:>7}")
    tot_all = sum(r[2] for r in records)
    mat_all = sum(r[2] for r in records if r[1] == "GEMM")
    non_all = sum(r[2] for r in records if r[1] == "nonlin")
    dma_all = sum(r[4] for r in records)
    matbusy = sum(r[3] for r in records)
    run_all = sum(r[6] for r in records)
    rsc_all = sum(r[7] for r in records)
    print("-" * (w + 48))
    print(f"TOTAL wall-clock: {tot_all} cycles")
    print(f"  GEMM steps {mat_all} ({100*mat_all/tot_all:.1f}%) | nonlinear {non_all} "
          f"({100*non_all/tot_all:.1f}%) | DMA busy {dma_all} ({100*dma_all/tot_all:.1f}%)")
    print(f"  mat-engine busy {matbusy} ({100*matbusy/tot_all:.1f}% wall): "
          f"S_RUN(MAC) {run_all}, S_RSC(requant) {rsc_all}, other {matbusy-run_all-rsc_all}")
    print(f"  useful MACs (analytic) {useful}; MAC-slots in S_RUN {run_all*256}; "
          f"spatial packing {100*useful/(run_all*256):.1f}%")
    print(f"  => MAC array does {useful} useful MACs in {run_all} S_RUN cycles out of "
          f"{tot_all} wall-clock ({100*run_all/tot_all:.2f}% of wall-clock)")


if __name__ == "__main__":
    main()
