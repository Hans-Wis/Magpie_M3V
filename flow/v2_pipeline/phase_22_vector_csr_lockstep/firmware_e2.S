/* ADR-0058 Phase-E E2 (stub) directed: segment load/store vlseg<nf>/vsseg<nf>.
   nf=2..4, EEW=SEW, LMUL=1, unmasked, vstart=0, unit-stride. element-major/field-minor
   interleave: mem[i*nf+f] -> field(vd+f)[i]. Verify deinterleave (loads) + interleave
   (stores) via vse+lw. SEW 8/16/32. Golden-probed vlseg2 -> v4=a[], v5=b[]. Out of stub
   scope (LMUL>1/EEW!=SEW/masked) is intentionally illegal (DUT stricter than Spike, not
   tested). Spike --isa=rv32imf_zve32x_zvl128b is authority. */
.section .init
.global _start
_start:
    li   t0, 0x200
    csrs mstatus, t0
    lla  x22, dst

    /* ===== nf=2, e8, vl=4 ===== */
    lla  x20, s2_8
    li   a0, 4
    vsetvli t1, a0, e8, m1, ta, ma
    vlseg2e8.v v4, (x20)                 /* v4=[10,11,12,13] v5=[20,21,22,23] */
    vse8.v v4,(x22); lw t3,0(x22)
    vse8.v v5,(x22); lw t4,0(x22)
    /* store back interleaved */
    lla  x21, dst2
    vsseg2e8.v v4, (x21)
    lw t5,0(x21); lw t6,4(x21)

    /* ===== nf=3, e8, vl=4 ===== */
    lla  x20, s3_8
    vlseg3e8.v v8, (x20)                 /* v8,v9,v10 = 3 deinterleaved fields */
    vse8.v v8, (x22); lw t3,0(x22)
    vse8.v v9, (x22); lw t4,0(x22)
    vse8.v v10,(x22); lw t5,0(x22)

    /* ===== nf=4, e8, vl=4 ===== */
    lla  x20, s4_8
    vlseg4e8.v v8, (x20)
    vse8.v v8, (x22); lw t3,0(x22)
    vse8.v v9, (x22); lw t4,0(x22)
    vse8.v v10,(x22); lw t5,0(x22)
    vse8.v v11,(x22); lw t6,0(x22)

    /* ===== nf=2, e16, vl=4 ===== */
    lla  x20, s2_16
    vsetvli t1, a0, e16, m1, ta, ma
    vlseg2e16.v v4, (x20)
    vse16.v v4,(x22); lw t3,0(x22); lw t4,4(x22)
    vse16.v v5,(x22); lw t5,0(x22); lw t6,4(x22)
    lla  x21, dst2
    vsseg2e16.v v4, (x21)
    lw t3,0(x21); lw t4,4(x21); lw t5,8(x21); lw t6,12(x21)

    /* ===== nf=2, e32, vl=4 ===== */
    lla  x20, s2_32
    vsetvli t1, a0, e32, m1, ta, ma
    vlseg2e32.v v4, (x20)
    vse32.v v4,(x22); lw t3,0(x22); lw t4,4(x22); lw t5,8(x22); lw t6,12(x22)
    vse32.v v5,(x22); lw t3,0(x22); lw t4,4(x22); lw t5,8(x22); lw t6,12(x22)

    /* ===== partial-vl tail-undisturbed (Codex finding): vl=2 < VLMAX=8 @ e16 ===== */
    lla  x20, s2_16
    li   a1, 0x7F
    vsetvli t1, a0, e16, m1, ta, ma      /* a0 still 4 -> set to VLMAX view via 8 below */
    li   a2, 8
    vsetvli t1, a2, e16, m1, ta, ma      /* VLMAX=8 */
    vmv.v.x v4, a1                        /* pre-color v4 tail = 0x007F */
    vmv.v.x v5, a1
    li   a2, 2
    vsetvli t1, a2, e16, m1, ta, ma      /* vl=2 */
    vlseg2e16.v v4, (x20)                 /* only elems 0,1 loaded; 2..7 must stay 0x7F */
    li   a2, 8
    vsetvli t1, a2, e16, m1, ta, ma      /* store all 8 to observe the tail */
    vse16.v v4,(x22); lw t3,0(x22); lw t4,4(x22); lw t5,8(x22); lw t6,12(x22)
    vse16.v v5,(x22); lw t3,0(x22); lw t4,12(x22)

    ebreak

.section .data
.align 6
/* nf=2 e8: a=[10..13] b=[20..23] interleaved */
s2_8:  .byte 10,20, 11,21, 12,22, 13,23
.align 6
s3_8:  .byte 1,2,3, 4,5,6, 7,8,9, 10,11,12
.align 6
s4_8:  .byte 0x10,0x20,0x30,0x40, 0x11,0x21,0x31,0x41, 0x12,0x22,0x32,0x42, 0x13,0x23,0x33,0x43
.align 6
s2_16: .short 0x0100,0x0200, 0x0101,0x0201, 0x0102,0x0202, 0x0103,0x0203
.align 6
s2_32: .word 0x11110000,0x22220000, 0x11110001,0x22220001, 0x11110002,0x22220002, 0x11110003,0x22220003
.align 6
dst:   .space 32
.align 6
dst2:  .space 32
