.section .init
.global _start
_start:
    li   t0, 0x200
    csrs mstatus, t0
    la   x31, data_area
    /* MAX_POOL_2D 2x2 s2 (TFLM: max over window, no requant) */
    li   a0, 8
    vsetvli t1, a0, e8, m1, ta, ma
    addi a1, x31, 0
    vle8.v v1, (a1)
    addi a1, x31, 8
    vle8.v v2, (a1)
    addi a1, x31, 32
    vle8.v v3, (a1)
    addi a1, x31, 40
    vle8.v v4, (a1)
    vmax.vv v1, v1, v2
    vmax.vv v3, v3, v4
    vmax.vv v1, v1, v3
    addi a1, x31, 128
    vse8.v v1, (a1)
    addi a1, x31, 16
    vle8.v v1, (a1)
    addi a1, x31, 24
    vle8.v v2, (a1)
    addi a1, x31, 48
    vle8.v v3, (a1)
    addi a1, x31, 56
    vle8.v v4, (a1)
    vmax.vv v1, v1, v2
    vmax.vv v3, v3, v4
    vmax.vv v1, v1, v3
    addi a1, x31, 136
    vse8.v v1, (a1)
    addi a1, x31, 64
    vle8.v v1, (a1)
    addi a1, x31, 72
    vle8.v v2, (a1)
    addi a1, x31, 96
    vle8.v v3, (a1)
    addi a1, x31, 104
    vle8.v v4, (a1)
    vmax.vv v1, v1, v2
    vmax.vv v3, v3, v4
    vmax.vv v1, v1, v3
    addi a1, x31, 144
    vse8.v v1, (a1)
    addi a1, x31, 80
    vle8.v v1, (a1)
    addi a1, x31, 88
    vle8.v v2, (a1)
    addi a1, x31, 112
    vle8.v v3, (a1)
    addi a1, x31, 120
    vle8.v v4, (a1)
    vmax.vv v1, v1, v2
    vmax.vv v3, v3, v4
    vmax.vv v1, v1, v3
    addi a1, x31, 152
    vse8.v v1, (a1)
    /* AVERAGE_POOL_2D 2x2 s2 — exact TFLM half-away (lemma 1) */
    li   t0, 2
    csrw vxrm, t0                  /* rdn: vnclip truncates */
    li   a0, 8
    vsetvli t1, a0, e8, mf2, ta, ma
    addi a1, x31, 0
    vle8.v v1, (a1)
    addi a1, x31, 8
    vle8.v v2, (a1)
    addi a1, x31, 32
    vle8.v v3, (a1)
    addi a1, x31, 40
    vle8.v v4, (a1)
    vmv.v.i v5, 1
    vwmul.vv v6, v1, v5    /* widen: sum16 = a */
    vwadd.wv v6, v6, v2
    vwadd.wv v6, v6, v3
    vwadd.wv v6, v6, v4
    li   a0, 8
    vsetvli t1, a0, e16, m1, ta, ma
    vmslt.vx v0, v6, x0    /* negative-sum lanes */
    vadd.vi v6, v6, 2
    vadd.vi v6, v6, -1, v0.t
    li   a0, 8
    vsetvli t1, a0, e8, mf2, ta, ma
    vnclip.wi v7, v6, 2    /* >>2 truncate + narrow */
    addi a1, x31, 160
    vse8.v v7, (a1)
    li   a0, 8
    vsetvli t1, a0, e8, mf2, ta, ma
    addi a1, x31, 16
    vle8.v v1, (a1)
    addi a1, x31, 24
    vle8.v v2, (a1)
    addi a1, x31, 48
    vle8.v v3, (a1)
    addi a1, x31, 56
    vle8.v v4, (a1)
    vmv.v.i v5, 1
    vwmul.vv v6, v1, v5    /* widen: sum16 = a */
    vwadd.wv v6, v6, v2
    vwadd.wv v6, v6, v3
    vwadd.wv v6, v6, v4
    li   a0, 8
    vsetvli t1, a0, e16, m1, ta, ma
    vmslt.vx v0, v6, x0    /* negative-sum lanes */
    vadd.vi v6, v6, 2
    vadd.vi v6, v6, -1, v0.t
    li   a0, 8
    vsetvli t1, a0, e8, mf2, ta, ma
    vnclip.wi v7, v6, 2    /* >>2 truncate + narrow */
    addi a1, x31, 168
    vse8.v v7, (a1)
    li   a0, 8
    vsetvli t1, a0, e8, mf2, ta, ma
    addi a1, x31, 64
    vle8.v v1, (a1)
    addi a1, x31, 72
    vle8.v v2, (a1)
    addi a1, x31, 96
    vle8.v v3, (a1)
    addi a1, x31, 104
    vle8.v v4, (a1)
    vmv.v.i v5, 1
    vwmul.vv v6, v1, v5    /* widen: sum16 = a */
    vwadd.wv v6, v6, v2
    vwadd.wv v6, v6, v3
    vwadd.wv v6, v6, v4
    li   a0, 8
    vsetvli t1, a0, e16, m1, ta, ma
    vmslt.vx v0, v6, x0    /* negative-sum lanes */
    vadd.vi v6, v6, 2
    vadd.vi v6, v6, -1, v0.t
    li   a0, 8
    vsetvli t1, a0, e8, mf2, ta, ma
    vnclip.wi v7, v6, 2    /* >>2 truncate + narrow */
    addi a1, x31, 176
    vse8.v v7, (a1)
    li   a0, 8
    vsetvli t1, a0, e8, mf2, ta, ma
    addi a1, x31, 80
    vle8.v v1, (a1)
    addi a1, x31, 88
    vle8.v v2, (a1)
    addi a1, x31, 112
    vle8.v v3, (a1)
    addi a1, x31, 120
    vle8.v v4, (a1)
    vmv.v.i v5, 1
    vwmul.vv v6, v1, v5    /* widen: sum16 = a */
    vwadd.wv v6, v6, v2
    vwadd.wv v6, v6, v3
    vwadd.wv v6, v6, v4
    li   a0, 8
    vsetvli t1, a0, e16, m1, ta, ma
    vmslt.vx v0, v6, x0    /* negative-sum lanes */
    vadd.vi v6, v6, 2
    vadd.vi v6, v6, -1, v0.t
    li   a0, 8
    vsetvli t1, a0, e8, mf2, ta, ma
    vnclip.wi v7, v6, 2    /* >>2 truncate + narrow */
    addi a1, x31, 184
    vse8.v v7, (a1)
    /* output probes — gate_59 reads these from the trace */
    lw   t2, 128(x31)
    lw   t2, 132(x31)
    lw   t2, 136(x31)
    lw   t2, 140(x31)
    lw   t2, 144(x31)
    lw   t2, 148(x31)
    lw   t2, 152(x31)
    lw   t2, 156(x31)
    lw   t2, 160(x31)
    lw   t2, 164(x31)
    lw   t2, 168(x31)
    lw   t2, 172(x31)
    lw   t2, 176(x31)
    lw   t2, 180(x31)
    lw   t2, 184(x31)
    lw   t2, 188(x31)
    ebreak
    .balign 4
data_area:
    .word 0x61804b98
    .word 0x91b037d6
    .word 0x2207dd2c
    .word 0x2b9bc9b9
    .word 0xd1bf4da1
    .word 0xfb94ec0a
    .word 0xb1fd8e8c
    .word 0x4358061f
    .word 0x159dcb31
    .word 0x4640b2cc
    .word 0xc61237e2
    .word 0x0c2c660e
    .word 0x728c1547
    .word 0x9c825294
    .word 0xcd476f65
    .word 0x4dfa3671
    .word 0x2c4a0d7a
    .word 0x27bb69ff
    .word 0x21df6659
    .word 0x6a9e1ea8
    .word 0x06a0be2c
    .word 0xedbf8791
    .word 0xa892d7d9
    .word 0x44d73d29
    .word 0xb3b35f99
    .word 0xa2f0f1e1
    .word 0x873df3ab
    .word 0x3e0b547b
    .word 0xa4b9f481
    .word 0x95559deb
    .word 0x7a91aaa4
    .word 0x22cfa4f9
    .zero 64
