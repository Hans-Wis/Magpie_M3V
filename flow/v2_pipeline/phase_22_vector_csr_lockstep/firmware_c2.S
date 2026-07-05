/* ADR-0056 Phase-C C2 directed: integer multiply-accumulate.
   vmacc(vd+=vs1*vs2) vnmsac(vd-=vs1*vs2) vmadd(vd=vs1*vd+vs2) vnmsub(vd=vs2-vs1*vd).
   OPMVV(.vv)/OPMVX(.vx), SEW low bits. vd is the accumulator: reloaded before each
   MAC so the sum is deterministic. vd-overlap with vs1/vs2 is spec-LEGAL and must not
   trap (exercised explicitly). Observe vse+lw. m2 group via vmv.v.x splat. Terminator:
   masked vmacc writing v0 = illegal. Spike --isa=rv32imf_zve32x_zvl128b golden
   (vd=10,vs1=3,vs2=5 -> macc 25 / nmsac -5 / madd 35 / nmsub -25). */
.section .init
.global _start
_start:
    li   t0, 0x200
    csrs mstatus, t0
    lla  x18, ps1
    lla  x19, ps2
    lla  x20, pd
    lla  x22, dst

    /* ================= e32, m1, vl=4 ================= */
    li   a0, 4
    vsetvli t1, a0, e32, m1, ta, ma
    vle32.v v6, (x18)              /* vs1 */
    vle32.v v2, (x19)              /* vs2 */
    vle32.v v5, (x20); vmacc.vv  v5, v6, v2
    vse32.v v5,(x22); lw t3,0(x22); lw t4,4(x22); lw t5,8(x22); lw t6,12(x22)
    vle32.v v5, (x20); vnmsac.vv v5, v6, v2
    vse32.v v5,(x22); lw t3,0(x22); lw t4,4(x22); lw t5,8(x22); lw t6,12(x22)
    vle32.v v5, (x20); vmadd.vv  v5, v6, v2
    vse32.v v5,(x22); lw t3,0(x22); lw t4,4(x22); lw t5,8(x22); lw t6,12(x22)
    vle32.v v5, (x20); vnmsub.vv v5, v6, v2
    vse32.v v5,(x22); lw t3,0(x22); lw t4,4(x22); lw t5,8(x22); lw t6,12(x22)
    /* --- .vx forms (rs1 = -3 multiplicand) --- */
    li   a1, -3
    vle32.v v5, (x20); vmacc.vx  v5, a1, v2
    vse32.v v5,(x22); lw t3,0(x22); lw t4,4(x22)
    vle32.v v5, (x20); vnmsac.vx v5, a1, v2
    vse32.v v5,(x22); lw t3,0(x22); lw t4,4(x22)
    vle32.v v5, (x20); vmadd.vx  v5, a1, v2
    vse32.v v5,(x22); lw t3,0(x22); lw t4,4(x22)
    vle32.v v5, (x20); vnmsub.vx v5, a1, v2
    vse32.v v5,(x22); lw t3,0(x22); lw t4,4(x22)
    /* --- vd-overlap (spec-legal, must not trap) --- */
    vle32.v v2, (x19); vmacc.vv v2, v6, v2      /* vd==vs2 */
    vse32.v v2,(x22); lw t3,0(x22); lw t4,4(x22)
    vle32.v v6, (x18); vmadd.vv v6, v6, v2      /* vd==vs1 */
    vse32.v v6,(x22); lw t5,0(x22); lw t6,4(x22)

    /* ================= e16, m1, vl=8 ================= */
    lla  x18, ps1_16
    lla  x19, ps2_16
    li   a0, 8
    vsetvli t1, a0, e16, m1, ta, ma
    vle16.v v6, (x18)
    vle16.v v2, (x19)
    vle16.v v5, (x20); vmacc.vv  v5, v6, v2
    vse16.v v5,(x22); lw t3,0(x22); lw t4,4(x22); lw t5,8(x22); lw t6,12(x22)
    vle16.v v5, (x20); vnmsac.vv v5, v6, v2
    vse16.v v5,(x22); lw t3,0(x22); lw t4,4(x22); lw t5,8(x22); lw t6,12(x22)
    vle16.v v5, (x20); vmadd.vv  v5, v6, v2
    vse16.v v5,(x22); lw t3,0(x22); lw t4,4(x22); lw t5,8(x22); lw t6,12(x22)
    vle16.v v5, (x20); vnmsub.vv v5, v6, v2
    vse16.v v5,(x22); lw t3,0(x22); lw t4,4(x22); lw t5,8(x22); lw t6,12(x22)

    /* ================= e8, m1, vl=16 ================= */
    lla  x18, ps1_8
    lla  x19, ps2_8
    li   a0, 16
    vsetvli t1, a0, e8, m1, ta, ma
    vle8.v v6, (x18)
    vle8.v v2, (x19)
    vle8.v v5, (x20); vmacc.vv  v5, v6, v2
    vse8.v v5,(x22); lw t3,0(x22); lw t4,4(x22); lw t5,8(x22); lw t6,12(x22)
    vle8.v v5, (x20); vnmsac.vv v5, v6, v2
    vse8.v v5,(x22); lw t3,0(x22); lw t4,4(x22); lw t5,8(x22); lw t6,12(x22)
    vle8.v v5, (x20); vmadd.vv  v5, v6, v2
    vse8.v v5,(x22); lw t3,0(x22); lw t4,4(x22); lw t5,8(x22); lw t6,12(x22)
    vle8.v v5, (x20); vnmsub.vv v5, v6, v2
    vse8.v v5,(x22); lw t3,0(x22); lw t4,4(x22); lw t5,8(x22); lw t6,12(x22)

    /* ============ e32, m2, vl=8 group smoke (beats_op) ============ */
    li   a0, 8
    vsetvli t1, a0, e32, m2, ta, ma
    li   a1, 0x00000003
    vmv.v.x v6, a1
    li   a1, 0x00000005
    vmv.v.x v2, a1
    li   a1, 0x0000000A
    vmv.v.x v8, a1
    vmacc.vv v8, v6, v2                          /* group v8v9 = 10 + 3*5 = 25 */
    vse32.v v8,(x22); lw t3,0(x22); lw t4,16(x22)
    li   a1, 0x0000000A
    vmv.v.x v8, a1
    vnmsub.vv v8, v6, v2                          /* 5 - 3*10 = -25 */
    vse32.v v8,(x22); lw t3,0(x22); lw t4,16(x22)

    /* ============ terminator: masked vmacc writing v0 = illegal ============ */
    li   a0, 4
    vsetvli t1, a0, e32, m1, ta, ma
    vmacc.vv v0, v6, v2, v0.t
    ebreak

.section .data
.align 6
ps1:  .word 3, 0xFFFFFFFF, 0x00010000, 0x0000007F
ps2:  .word 5, 7, 0x00000100, 0xFFFFFFFF
pd:   .word 10, 0x80000000, 1, 100
.align 6
ps1_16: .short 3, 0xFFFF, 0x0100, 0x007F, 0x8000, 0x0002, 0xABCD, 0x0010
ps2_16: .short 5, 7, 0x0010, 0xFFFF, 0x0002, 0x7FFF, 0x0003, 0x00FF
.align 6
ps1_8:  .byte 3,0xFF,0x10,0x7F,0x02,0x80,0x11,0x08, 0x04,0xC3,0x0F,0xF0,0x01,0x7F,0x80,0xFF
ps2_8:  .byte 5,7,0x03,0xFF,0x7F,0x80,0x10,0xF0, 0xAB,0x3D,0xF1,0x0F,0xFE,0x81,0x80,0x02
.align 6
dst:  .space 64
