/* ADR-0058 Phase-E E3 directed: vrgather.vv/.vx/.vi.
   vd[i] = (index >= vlmax) ? 0 : vs2[index]; index = vs1[i] (.vv) / rs1 (.vx) / uimm
   (.vi). m1, combinational crossbar. Covers SEW 8/16/32, out-of-range indices (->0),
   .vx/.vi broadcast, masked. Terminator: vrgather.vv vd==vs2 (require_noover) illegal.
   Golden src[10..17] idx[3,0,7,2,9,1,5,4] -> [13,10,17,12,0,11,15,14]. Spike
   --isa=rv32imf_zve32x_zvl128b is authority. */
.section .init
.global _start
_start:
    li   t0, 0x200
    csrs mstatus, t0
    lla  x20, src8
    lla  x21, idx8
    lla  x22, dst

    /* ===== SEW8, m1, vl=8 ===== */
    li   a0, 8
    vsetvli t1, a0, e8, m1, ta, ma
    vle8.v v2, (x20)
    vle8.v v1, (x21)
    vrgather.vv v5, v2, v1
    vse8.v v5,(x22); lw t3,0(x22); lw t4,4(x22)
    li   a1, 2
    vrgather.vx v5, v2, a1          /* broadcast vs2[2] */
    vse8.v v5,(x22); lw t5,0(x22)
    vrgather.vi v5, v2, 5           /* broadcast vs2[5] */
    vse8.v v5,(x22); lw t6,0(x22)
    li   a1, 20
    vrgather.vx v5, v2, a1          /* OOR index -> all 0 */
    vse8.v v5,(x22); lw t3,0(x22)
    /* masked gather */
    lla  x23, msk
    vle8.v v4, (x23)
    vmsne.vi v0, v4, 0
    li   a1, 0x77
    vmv.v.x v5, a1                  /* pre-color inactive */
    vrgather.vv v5, v2, v1, v0.t
    vse8.v v5,(x22); lw t4,0(x22); lw t5,4(x22)

    /* ===== SEW16, m1, vl=8 ===== */
    lla  x20, src16
    lla  x21, idx16
    vsetvli t1, a0, e16, m1, ta, ma
    vle16.v v2, (x20)
    vle16.v v1, (x21)
    vrgather.vv v5, v2, v1
    vse16.v v5,(x22); lw t3,0(x22); lw t4,4(x22); lw t5,8(x22); lw t6,12(x22)
    li   a1, 3
    vrgather.vx v5, v2, a1
    vse16.v v5,(x22); lw t3,0(x22)

    /* ===== SEW32, m1, vl=4 ===== */
    lla  x20, src32
    lla  x21, idx32
    li   a0, 4
    vsetvli t1, a0, e32, m1, ta, ma
    vle32.v v2, (x20)
    vle32.v v1, (x21)
    vrgather.vv v5, v2, v1
    vse32.v v5,(x22); lw t3,0(x22); lw t4,4(x22); lw t5,8(x22); lw t6,12(x22)
    vrgather.vi v5, v2, 1
    vse32.v v5,(x22); lw t3,0(x22)

    /* ===== terminator: vrgather.vv vd==vs2 (overlap) = illegal ===== */
    li   a0, 8
    vsetvli t1, a0, e8, m1, ta, ma
    vrgather.vv v2, v2, v1
    ebreak

.section .data
.align 6
src8:  .byte 10,11,12,13,14,15,16,17
.align 6
idx8:  .byte 3,0,7,2,9,1,5,4          /* 9 is out of range (vlmax=8) */
.align 6
msk:   .byte 0,1,1,0,1,0,1,1
.align 6
src16: .short 0x0100,0x0201,0x0302,0x0403,0x0504,0x0605,0x0706,0x0807
idx16: .short 7,0,3,9,1,6,2,4
.align 6
src32: .word 0x11111111,0x22222222,0x33333333,0x44444444
idx32: .word 2,5,0,3
.align 6
dst:   .space 32
