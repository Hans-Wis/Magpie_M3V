/* ADR-0055 Phase-B B4 directed: whole-register move vmv<nr>r.v (nr=1,2,4,8).
   Copies nr WHOLE registers vd+p <- vs2+p, independent of vtype (LMUL/SEW/vl).
   Observation: vse32 + lw per copied register (scalar commit is what lockstep
   compares). Coverage: each nr copies the right registers; an over-copy guard
   (sentinel in v24 must survive vmv8r); vtype-independence (vmvr executes under
   an m8 vtype — Spike-probed legal, DUT must not trap). Terminator: a misaligned
   vmv2r (vd odd -> not nr-aligned) both DUT and Spike trap on.
   Spike --isa=rv32imf_zve32x_zvl128b is authority. */
.section .init
.global _start
_start:
    li   t0, 0x200
    csrs mstatus, t0
    lla  x20, tbl
    lla  x22, dst

    /* ===== vmv1r.v ===== */
    li   a0, 4
    vsetvli t1, a0, e32, m1, ta, ma
    vle32.v v2, (x20)              /* v2 = entry0 (patA) */
    vmv1r.v v5, v2
    vse32.v v5, (x22)
    lw t3, 0(x22); lw t4, 4(x22); lw t5, 8(x22); lw t6, 12(x22)

    /* ===== vmv2r.v : v4,v5 <- entry0,entry1 ; copy to v8,v9 ===== */
    vle32.v v4, (x20)
    addi x21, x20, 16
    vle32.v v5, (x21)
    vmv2r.v v8, v4
    vse32.v v8, (x22); lw t3, 0(x22); lw t4, 12(x22)
    vse32.v v9, (x22); lw t5, 0(x22); lw t6, 12(x22)

    /* ===== vmv4r.v : v4..v7 <- entry0..3 ; copy to v8..v11 ===== */
    addi x21, x20, 32
    vle32.v v6, (x21)
    addi x21, x20, 48
    vle32.v v7, (x21)
    vmv4r.v v8, v4
    vse32.v v8,  (x22); lw t3, 0(x22)
    vse32.v v9,  (x22); lw t4, 0(x22)
    vse32.v v10, (x22); lw t5, 0(x22)
    vse32.v v11, (x22); lw t6, 0(x22)

    /* ===== vmv8r.v : v8..v15 <- entry0..7 ; copy to v16..v23 ===== */
    addi x21, x20, 0;   vle32.v v8,  (x21)
    addi x21, x20, 16;  vle32.v v9,  (x21)
    addi x21, x20, 32;  vle32.v v10, (x21)
    addi x21, x20, 48;  vle32.v v11, (x21)
    addi x21, x20, 64;  vle32.v v12, (x21)
    addi x21, x20, 80;  vle32.v v13, (x21)
    addi x21, x20, 96;  vle32.v v14, (x21)
    addi x21, x20, 112; vle32.v v15, (x21)
    lla  x23, sentinel
    vle32.v v24, (x23)            /* v24 = sentinel: must survive vmv8r (no over-copy) */
    vmv8r.v v16, v8
    vse32.v v16, (x22); lw t3, 0(x22)   /* entry0 */
    vse32.v v17, (x22); lw t4, 0(x22)   /* entry1 */
    vse32.v v22, (x22); lw t5, 0(x22)   /* entry6 */
    vse32.v v23, (x22); lw t6, 0(x22)   /* entry7 */
    vse32.v v24, (x22); lw t3, 0(x22); lw t4, 12(x22)  /* still sentinel */

    /* ===== vtype-independence: vmvr under an m8 vtype (Spike: legal) ===== */
    li   a0, 32
    vsetvli t1, a0, e32, m8, ta, ma
    vmv1r.v v20, v2               /* v2 = entry0; copy must execute despite m8 */
    li   a0, 4
    vsetvli t1, a0, e32, m1, ta, ma
    vse32.v v20, (x22)
    lw t3, 0(x22); lw t4, 12(x22)

    /* ===== terminator: misaligned vmv2r (vd=9 odd) = illegal, both trap ===== */
    vmv2r.v v9, v4
    ebreak

.section .data
.align 6
tbl:
    .word 0xA0000001, 0xA0000002, 0xA0000003, 0xA0000004   /* entry0 */
    .word 0xB1000001, 0xB1000002, 0xB1000003, 0xB1000004   /* entry1 */
    .word 0xC2000001, 0xC2000002, 0xC2000003, 0xC2000004   /* entry2 */
    .word 0xD3000001, 0xD3000002, 0xD3000003, 0xD3000004   /* entry3 */
    .word 0xE4000001, 0xE4000002, 0xE4000003, 0xE4000004   /* entry4 */
    .word 0xF5000001, 0xF5000002, 0xF5000003, 0xF5000004   /* entry5 */
    .word 0x16000001, 0x16000002, 0x16000003, 0x16000004   /* entry6 */
    .word 0x27000001, 0x27000002, 0x27000003, 0x27000004   /* entry7 */
.align 6
sentinel:
    .word 0x5E571E10, 0x5E571E11, 0x5E571E12, 0x5E571E13
.align 6
dst:
    .space 16
