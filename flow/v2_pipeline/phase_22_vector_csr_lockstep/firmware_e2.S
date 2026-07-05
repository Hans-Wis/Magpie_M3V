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

    /* ===== nf=2, e8, m2 (VLMAX=32, EMUL=4) — the compiler's actual vlseg2e8@m2 ===== */
    lla  x20, sm2
    li   a0, 32
    vsetvli t1, a0, e8, m2, ta, ma
    vlseg2e8.v v8, (x20)                  /* field0={v8,v9}, field1={v10,v11} */
    li   a0, 16
    vsetvli t1, a0, e8, m1, ta, ma        /* observe each register under m1 */
    vse8.v v8, (x22); lw t3,0(x22); lw t4,12(x22)
    vse8.v v9, (x22); lw t5,0(x22); lw t6,12(x22)
    vse8.v v10,(x22); lw t3,0(x22); lw t4,12(x22)
    vse8.v v11,(x22); lw t5,0(x22); lw t6,12(x22)
    /* store back @ m2 and read the interleaved memory */
    lla  x21, dm2
    li   a0, 32
    vsetvli t1, a0, e8, m2, ta, ma
    vsseg2e8.v v8, (x21)
    lw t3,0(x21); lw t4,32(x21); lw t5,60(x21)

    /* ===== partial-vl @ m2: vl=20 (element 20 in v9, tests per-register tail blend) ===== */
    li   a0, 32
    vsetvli t1, a0, e8, m2, ta, ma
    li   a1, 0x7E
    vmv.v.x v8, a1                        /* pre-color the whole m2 group... */
    vmv.v.x v10, a1
    li   a0, 20
    vsetvli t1, a0, e8, m2, ta, ma        /* vl=20 */
    vlseg2e8.v v8, (x20)                  /* elems 0..19 loaded; 20..31 stay 0x7E */
    li   a0, 16
    vsetvli t1, a0, e8, m1, ta, ma
    vse8.v v9, (x22); lw t3,0(x22); lw t4,12(x22)   /* v9 = elems 16..31: 16..19 real, 20..31=0x7E */

    /* ===== nf=2, e8, m4 (VLMAX=64, EMUL=8) ===== */
    lla  x20, sm4
    li   a0, 64
    vsetvli t1, a0, e8, m4, ta, ma
    vlseg2e8.v v8, (x20)                  /* field0={v8..v11}, field1={v12..v15} */
    li   a0, 16
    vsetvli t1, a0, e8, m1, ta, ma
    vse8.v v8, (x22); lw t3,0(x22)
    vse8.v v11,(x22); lw t4,0(x22)        /* field0 last register (elems 48..63) */
    vse8.v v12,(x22); lw t5,0(x22)        /* field1 first register */

    /* ===== terminator: vlseg2e8@m2 with vd=v1 (unaligned to L=2) = illegal (Codex) ===== */
    lla  x20, sm2
    li   a0, 32
    vsetvli t1, a0, e8, m2, ta, ma
    vlseg2e8.v v1, (x20)
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
.align 6
/* m2: 32 elements x 2 fields interleaved: mem[2i]=i, mem[2i+1]=0x80|i */
sm2:
.set i, 0
.rept 32
    .byte i, (0x80 + i)
    .set i, i + 1
.endr
.align 6
dm2:   .space 64
.align 6
/* m4: 64 elements x 2 fields interleaved */
sm4:
.set j, 0
.rept 64
    .byte (j & 0x3F), (0xC0 | (j & 0x3F))
    .set j, j + 1
.endr
