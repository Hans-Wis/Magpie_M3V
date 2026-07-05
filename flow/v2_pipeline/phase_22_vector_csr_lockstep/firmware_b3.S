/* ADR-0055 Phase-B B3 directed: carry/borrow vadc/vsbc/vmadc/vmsbc.
   - vadc/vsbc: vector vd = vs2 +/- vs1(/rs1/imm) +/- carry(v0[i]); v0 is the
     carry OPERAND (not a predicate) -> body force-active, vm=1 illegal.
   - vmadc/vmsbc: MASK vd = unsigned carry/borrow-OUT bit. vm=0 -> carry-in from
     v0[i] (.v*m forms); vm=1 -> no carry-in (.vv/.vx/.vi), vd==v0 then legal.
   Observation: vse<sew> then lw (scalar commit is what the lockstep compares).
   Mask dest is pre-zeroed so its tail (>vl) is deterministic across DUT/Spike.
   Data picks carry/borrow boundaries: a+b+cin == 2^SEW (carry), a<b+bin (borrow).
   Terminator: vadc.vvm with vd==v0 (vd==0) = ILLEGAL (dest overlaps carry v0);
   both DUT and Spike trap. Spike --isa=rv32imf_zve32x_zvl128b is authority. */
.section .init
.global _start
_start:
    li   t0, 0x200
    csrs mstatus, t0            /* mstatus.VS = Initial */
    lla  x20, pA8
    lla  x21, pB8
    lla  x22, pC
    lla  x23, dst

    /* ================= e8, m1, vl=16 ================= */
    li   a0, 16
    vsetvli t1, a0, e8, m1, ta, ma
    vle8.v v2, (x20)           /* a */
    vle8.v v3, (x21)           /* b */
    vle8.v v4, (x22)           /* carry seed bytes (0/1) */
    vmsne.vi v0, v4, 0         /* v0[i] = carry bit */
    vmv.v.i v6, 0              /* pre-zero mask dest (deterministic tail) */

    /* --- vadc arithmetic (vvm / vxm / vim) --- */
    vadc.vvm v5, v2, v3, v0
    vse8.v v5, (x23)
    lw t3, 0(x23); lw t4, 4(x23); lw t5, 8(x23); lw t6, 12(x23)
    li   a1, 0x7F
    vadc.vxm v5, v2, a1, v0
    vse8.v v5, (x23)
    lw t3, 0(x23); lw t4, 4(x23); lw t5, 8(x23); lw t6, 12(x23)
    vadc.vim v5, v2, 5, v0
    vse8.v v5, (x23)
    lw t3, 0(x23); lw t4, 4(x23); lw t5, 8(x23); lw t6, 12(x23)

    /* --- vsbc arithmetic (vvm / vxm) --- */
    vsbc.vvm v5, v2, v3, v0
    vse8.v v5, (x23)
    lw t3, 0(x23); lw t4, 4(x23); lw t5, 8(x23); lw t6, 12(x23)
    vsbc.vxm v5, v2, a1, v0
    vse8.v v5, (x23)
    lw t3, 0(x23); lw t4, 4(x23); lw t5, 8(x23); lw t6, 12(x23)

    /* --- vmadc / vmsbc mask (carry-in form, vm=0, vd!=0) --- */
    vmadc.vvm v6, v2, v3, v0
    vse8.v v6, (x23); lw t3, 0(x23); lw t4, 4(x23)
    vmsbc.vvm v6, v2, v3, v0
    vse8.v v6, (x23); lw t3, 0(x23); lw t4, 4(x23)
    vmadc.vxm v6, v2, a1, v0
    vse8.v v6, (x23); lw t3, 0(x23); lw t4, 4(x23)
    vmsbc.vxm v6, v2, a1, v0
    vse8.v v6, (x23); lw t3, 0(x23); lw t4, 4(x23)
    vmadc.vim v6, v2, 5, v0
    vse8.v v6, (x23); lw t3, 0(x23); lw t4, 4(x23)

    /* --- vmadc / vmsbc mask (NO carry-in, vm=1, vd==v0 legal) --- */
    vmadc.vv v0, v2, v3
    vse8.v v0, (x23); lw t3, 0(x23); lw t4, 4(x23)
    vmseq.vi v0, v4, 1         /* rebuild a carry mask for later use */
    vmsbc.vv v6, v2, v3
    vse8.v v6, (x23); lw t3, 0(x23); lw t4, 4(x23)
    vmadc.vx v6, v2, a1
    vse8.v v6, (x23); lw t3, 0(x23); lw t4, 4(x23)
    vmsbc.vx v6, v2, a1
    vse8.v v6, (x23); lw t3, 0(x23); lw t4, 4(x23)
    vmadc.vi v6, v2, 5
    vse8.v v6, (x23); lw t3, 0(x23); lw t4, 4(x23)

    /* ================= e16, m1, vl=8 ================= */
    lla  x18, pA16
    lla  x19, pB16
    li   a0, 8
    vsetvli t1, a0, e16, m1, ta, ma
    vle16.v v2, (x18)
    vle16.v v3, (x19)
    vmsne.vi v0, v4, 0         /* reuse v4 carry seed (low 8 bytes) */
    vadc.vvm v5, v2, v3, v0
    vse16.v v5, (x23)
    lw t3, 0(x23); lw t4, 4(x23); lw t5, 8(x23); lw t6, 12(x23)
    vsbc.vvm v5, v2, v3, v0
    vse16.v v5, (x23)
    lw t3, 0(x23); lw t4, 4(x23); lw t5, 8(x23); lw t6, 12(x23)
    li   a1, 0x1234
    vadc.vxm v5, v2, a1, v0
    vse16.v v5, (x23)
    lw t3, 0(x23); lw t4, 4(x23); lw t5, 8(x23); lw t6, 12(x23)
    vmadc.vvm v6, v2, v3, v0
    vse16.v v6, (x23); lw t3, 0(x23)
    vmsbc.vvm v6, v2, v3, v0
    vse16.v v6, (x23); lw t3, 0(x23)
    vmadc.vv v6, v2, v3
    vse16.v v6, (x23); lw t3, 0(x23)
    vmsbc.vx v6, v2, a1
    vse16.v v6, (x23); lw t3, 0(x23)

    /* ================= e32, m1, vl=4 ================= */
    lla  x18, pA32
    lla  x19, pB32
    li   a0, 4
    vsetvli t1, a0, e32, m1, ta, ma
    vle32.v v2, (x18)
    vle32.v v3, (x19)
    vmsne.vi v0, v4, 0
    vadc.vvm v5, v2, v3, v0
    vse32.v v5, (x23)
    lw t3, 0(x23); lw t4, 4(x23); lw t5, 8(x23); lw t6, 12(x23)
    vsbc.vvm v5, v2, v3, v0
    vse32.v v5, (x23)
    lw t3, 0(x23); lw t4, 4(x23); lw t5, 8(x23); lw t6, 12(x23)
    li   a1, 0x40000000
    vadc.vxm v5, v2, a1, v0
    vse32.v v5, (x23)
    lw t3, 0(x23); lw t4, 4(x23); lw t5, 8(x23); lw t6, 12(x23)
    vmadc.vvm v6, v2, v3, v0
    vse32.v v6, (x23); lw t3, 0(x23)
    vmsbc.vvm v6, v2, v3, v0
    vse32.v v6, (x23); lw t3, 0(x23)
    vmadc.vv v6, v2, v3
    vse32.v v6, (x23); lw t3, 0(x23)
    vmsbc.vv v6, v2, v3
    vse32.v v6, (x23); lw t3, 0(x23)

    /* ================= e8, m2, vl=32 group smoke (beats_op path) =================
       Group-EMUL memory loads are out of scope, so build sources by splat and a
       carry mask by self-compare (all-ones). Exercises the m2 group iteration for
       vadc/vsbc (arith, staged) and vmadc/vmsbc (mask accumulation). */
    li   a0, 32
    vsetvli t1, a0, e8, m2, ta, ma
    li   a1, 0x9C
    vmv.v.x v2, a1             /* a splat (group v2,v3) */
    li   a1, 0x7A
    vmv.v.x v4, a1             /* b splat (group v4,v5) */
    vmseq.vv v0, v2, v2        /* carry mask = all-ones over 32 elems */
    vadc.vvm v8, v2, v4, v0    /* 0x9C+0x7A+1 = 0x117 -> 0x17 carry */
    vse8.v v8, (x23)
    lw t3, 0(x23); lw t4, 16(x23)
    vsbc.vvm v8, v2, v4, v0    /* 0x9C-0x7A-1 = 0x21 */
    vse8.v v8, (x23)
    lw t3, 0(x23); lw t4, 16(x23)
    vmadc.vvm v10, v2, v4, v0  /* carry-out bit = 1 for all */
    vse8.v v10, (x23); lw t3, 0(x23)
    vmadc.vv v10, v2, v4       /* no carry: 0x9C+0x7A=0x116 -> carry 1 */
    vse8.v v10, (x23); lw t3, 0(x23)
    vmsbc.vv v10, v2, v4       /* 0x9C < 0x7A ? no -> 0 */
    vse8.v v10, (x23); lw t3, 0(x23)

    /* ============ terminator: vd==v0 illegal (dest overlaps carry v0) ============ */
    li   a0, 16
    vsetvli t1, a0, e8, m1, ta, ma
    vadc.vvm v0, v2, v4, v0
    ebreak

.section .data
.align 6
pA8:
    .byte 0xFF, 0x80, 0x7F, 0x01, 0x00, 0xFE, 0xAB, 0x10
    .byte 0x55, 0xC3, 0x0F, 0xF0, 0x01, 0x7F, 0x80, 0xFF
pB8:
    .byte 0x01, 0x80, 0x01, 0xFF, 0x00, 0x01, 0x55, 0xF0
    .byte 0xAB, 0x3D, 0xF1, 0x0F, 0xFE, 0x81, 0x80, 0x00
pC:
    .byte 1, 0, 1, 1, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0
.align 6
pA16:
    .short 0xFFFF, 0x8000, 0x1234, 0x0001, 0x7FFF, 0xFFFE, 0xABCD, 0x0080
pB16:
    .short 0x0001, 0x8000, 0xEDCC, 0xFFFF, 0x0001, 0x0003, 0x5432, 0xFF80
.align 6
pA32:
    .word 0xFFFFFFFF, 0x80000000, 0x12345678, 0x00000001
pB32:
    .word 0x00000001, 0x80000000, 0xEDCBA988, 0xFFFFFFFF
.align 6
dst:
    .space 64
