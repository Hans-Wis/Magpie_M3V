/* ADR-0059 Phase-F directed: LMUL=m8 (8-register group) for same-width beats_op.
   vlmax e8=128 / e16=64 / e32=32 (Spike-probed). Group = vd..vd+7, vd/vs aligned
   mod-8. Widening/reductions/mask-scan/gather/slides stay m8-illegal (cfg_illegal).
   Strategy: pre-load group source registers under m1 (distinct per-register splats)
   so each m8 logical vector has a known 16-elem-per-register step pattern, then run
   the m8 op and observe individual registers back under m1 via vse+lw. Compares emit
   a single mask register (v1). Spike --isa=rv32imf_zve32x_zvl128b is authority. */
.section .init
.global _start
_start:
    li   t0, 0x200
    csrs mstatus, t0
    lla  x22, dst

    /* ===== pre-load group A = v8..v15 (e8): reg k := value (k+1) ===== */
    li   a0, 16
    vsetvli t1, a0, e8, m1, ta, ma
    li t2,1;  vmv.v.x v8, t2
    li t2,2;  vmv.v.x v9, t2
    li t2,3;  vmv.v.x v10, t2
    li t2,4;  vmv.v.x v11, t2
    li t2,5;  vmv.v.x v12, t2
    li t2,6;  vmv.v.x v13, t2
    li t2,7;  vmv.v.x v14, t2
    li t2,8;  vmv.v.x v15, t2
    /* group B = v16..v23 all := 0x10 (splat under m8 in one shot) */
    li   a0, 128
    vsetvli t1, a0, e8, m8, ta, ma
    li   t2, 0x10
    vmv.v.x v16, t2

    /* ===== m8 vadd.vv v24, v8, v16 : elem = A_elem + 0x10 ===== */
    vadd.vv v24, v8, v16
    li   a0, 16
    vsetvli t1, a0, e8, m1, ta, ma
    vse8.v v24,(x22); lw t3,0(x22)          /* 0x11111111 */
    vse8.v v27,(x22); lw t4,0(x22)          /* reg 3 -> value 4+0x10=0x14 */
    vse8.v v31,(x22); lw t5,0(x22)          /* reg 7 -> value 8+0x10=0x18 */

    /* ===== m8 vadd.vx v24, v8, t2(=5) ===== */
    li   a0, 128
    vsetvli t1, a0, e8, m8, ta, ma
    li   t2, 5
    vadd.vx v24, v8, t2
    li   a0, 16
    vsetvli t1, a0, e8, m1, ta, ma
    vse8.v v24,(x22); lw t3,0(x22)          /* 1+5=0x06 */
    vse8.v v31,(x22); lw t4,0(x22)          /* 8+5=0x0d */

    /* ===== m8 e16 (vlmax=64): re-splat A=step 0x100.., B=0x1000 ===== */
    li   a0, 8
    vsetvli t1, a0, e16, m1, ta, ma
    li t2,0x100; vmv.v.x v8, t2
    li t2,0x200; vmv.v.x v9, t2
    li t2,0x300; vmv.v.x v10, t2
    li t2,0x400; vmv.v.x v11, t2
    li t2,0x500; vmv.v.x v12, t2
    li t2,0x600; vmv.v.x v13, t2
    li t2,0x700; vmv.v.x v14, t2
    li t2,0x800; vmv.v.x v15, t2
    li   a0, 64
    vsetvli t1, a0, e16, m8, ta, ma
    li t2,0x1000; vmv.v.x v16, t2
    vadd.vv v24, v8, v16
    li   a0, 8
    vsetvli t1, a0, e16, m1, ta, ma
    vse16.v v24,(x22); lw t3,0(x22)         /* 0x1100 x2 -> 0x11001100 */
    vse16.v v31,(x22); lw t4,0(x22)         /* 0x1800 x2 */

    /* ===== m8 compare -> mask dest v1 : vmsltu.vx v1, v8(e8 step), 5 ===== */
    /* re-load A under e8 first (was clobbered by e16 splats) */
    li   a0, 16
    vsetvli t1, a0, e8, m1, ta, ma
    li t2,1;  vmv.v.x v8, t2
    li t2,2;  vmv.v.x v9, t2
    li t2,3;  vmv.v.x v10, t2
    li t2,4;  vmv.v.x v11, t2
    li t2,5;  vmv.v.x v12, t2
    li t2,6;  vmv.v.x v13, t2
    li t2,7;  vmv.v.x v14, t2
    li t2,8;  vmv.v.x v15, t2
    li   a0, 128
    vsetvli t1, a0, e8, m8, ta, ma
    li   t2, 5
    vmsltu.vx v1, v8, t2                     /* elems<5 (reg 0..3 => elem 0..63) true */
    li   a0, 16
    vsetvli t1, a0, e8, m1, ta, ma
    vse8.v v1,(x22); lw t3,0(x22); lw t4,4(x22); lw t5,8(x22); lw t6,12(x22)
    /* expect t3=t4=0xFFFFFFFF (elem 0..63), t5=t6=0 (elem 64..127) */

    /* all-equal compare -> all ones */
    li   a0, 128
    vsetvli t1, a0, e8, m8, ta, ma
    vmseq.vv v1, v8, v8
    li   a0, 16
    vsetvli t1, a0, e8, m1, ta, ma
    vse8.v v1,(x22); lw t3,0(x22); lw t6,12(x22)

    /* ===== vl=0 : no write (pre-color v24 group, expect undisturbed) ===== */
    li   a0, 128
    vsetvli t1, a0, e8, m8, ta, ma
    li   t2, 0x77
    vmv.v.x v24, t2                          /* color whole group */
    li   a0, 0
    vsetvli t1, a0, e8, m8, ta, ma           /* vl=0 */
    vadd.vv v24, v8, v16
    li   a0, 16
    vsetvli t1, a0, e8, m1, ta, ma
    vse8.v v24,(x22); lw t3,0(x22)           /* stays 0x77777777 */
    vse8.v v31,(x22); lw t4,0(x22)           /* stays 0x77777777 */

    /* ===== vl=1 : only element 0 written ===== */
    li   a0, 128
    vsetvli t1, a0, e8, m8, ta, ma
    li   t2, 0x55
    vmv.v.x v24, t2
    li   a0, 1
    vsetvli t1, a0, e8, m8, ta, ma           /* vl=1, tail-agnostic */
    li   t2, 3
    vadd.vx v24, v8, t2                       /* elem0 = 1+3=4 ; rest tail */
    li   a0, 16
    vsetvli t1, a0, e8, m1, ta, ma
    vse8.v v24,(x22); lw t3,0(x22)           /* byte0=0x04, tail=agnostic (Spike golden) */

    /* ===== masked m8 (mu): v0 = elems<5 ; masked-off keep old ===== */
    li   a0, 128
    vsetvli t1, a0, e8, m8, ta, ma
    li   t2, 5
    vmsltu.vx v0, v8, t2                       /* mask in v0 : elem 0..63 active */
    li   t2, 0x99
    vmv.v.x v24, t2                            /* pre-color v24 group */
    vsetvli t1, a0, e8, m8, ta, mu             /* mask-undisturbed */
    vadd.vv v24, v8, v16, v0.t                 /* active: A+0x10 ; inactive: 0x99 */
    li   a0, 16
    vsetvli t1, a0, e8, m1, ta, ma
    vse8.v v24,(x22); lw t3,0(x22)            /* reg0 active -> 0x11 */
    vse8.v v27,(x22); lw t4,0(x22)            /* reg3 (elem48..63) active -> 0x14 */
    vse8.v v28,(x22); lw t5,0(x22)            /* reg4 (elem64..79) inactive -> 0x99 */

    /* ===== terminator: unaligned vd @ m8 = illegal (both DUT & Spike trap) ===== */
    li   a0, 128
    vsetvli t1, a0, e8, m8, ta, ma
    vadd.vv v9, v8, v16
    ebreak

.section .data
.align 6
dst:   .space 64
