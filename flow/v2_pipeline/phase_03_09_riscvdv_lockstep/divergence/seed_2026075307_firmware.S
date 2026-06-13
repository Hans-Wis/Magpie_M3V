.include "user_define.h"
.globl _start
.section .text
_start:           
                  .include "user_init.s"
                  csrr x5, 0xf14
                  li x6, 0
                  beq x5, x6, 0f

0: la x30, h0_start
jalr x0, x30, 0
h0_start:
                  li x13, 0x40001104
                  nop  # adapt: misa write dropped (DUT misa is WARL read-only; Spike misa writable)
kernel_sp:        
                  la x29, kernel_stack_end

trap_vec_init:    
                  la x13, mtvec_handler
                  ori x13, x13, 0
                  csrw 0x305, x13 # MTVEC

mepc_setup:       
                  la x13, init
                  csrw 0x341, x13

init_machine_mode:
                  li x13, 0x1e00
                  csrw 0x300, x13 # MSTATUS
                  li x13, 0x0
                  csrw 0x304, x13 # MIE
                  mret
init:             
                  li x0, 0x80000000
                  li x1, 0x80000000
                  li x2, 0x80000000
                  li x3, 0xf2a5a8e7
                  li x4, 0xce3d83ff
                  li x5, 0xfa48be67
                  li x6, 0xb
                  li x7, 0xf192c137
                  li x8, 0x1
                  li x9, 0x80000000
                  li x10, 0xfe42924b
                  li x11, 0xc
                  li x12, 0x80000000
                  li x13, 0x4
                  li x14, 0x80000000
                  li x15, 0x5
                  li x16, 0x0
                  li x17, 0x80000000
                  li x18, 0x2ed4ebf7
                  li x19, 0x5a9dd02a
                  li x20, 0x0
                  li x21, 0x419bc80
                  li x22, 0x0
                  li x23, 0xc
                  li x24, 0x80000000
                  li x25, 0x6
                  li x26, 0x0
                  li x27, 0x80000000
                  li x28, 0x994b9caa
                  li x30, 0xfb8db7ed
                  la x31, user_stack_end
main:             c.sub       a3, a3
                  # M1 J18 synchronous-trap smoke stream
                  ecall
                  ebreak
                  .word 0x00000000
                  la x5, j18_misalign_data
                  lw x6, 1(x5)
                  sw x6, 2(x5)
                  # M1 J14 supported-CSR lockstep sweep
                  csrr x5, 0x300
                  csrrw x6, 0x340, x5
                  csrr x5, 0x340
                  csrrs x6, 0x300, x0
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  orn   x31, x30, x31
                  csrw mscratch, x8
                  la   x8, zbcov_scratch
                  sw   x9, 0(x8)
                  sw   sp, 4(x8)
                  addi sp, x8, 8
                  c.swsp x31, 0(sp)
                  c.lwsp x30, 0(sp)
                  sw   x31, 8(x8)
                  c.lw  x9, 8(x8)
                  c.sw  x9, 8(x8)
                  lw   sp, 4(x8)
                  lw   x9, 0(x8)
                  csrr x8, mscratch
                  csrrc x6, 0x304, x0
                  csrr x6, 0x305
                  csrr x6, 0x341
                  csrr x6, 0x342
                  csrr x6, 0x343
                  csrr x6, 0x344
                  csrr x6, 0xc00
                  csrr x6, 0xc80
                  csrr x6, 0xc02
                  csrr x6, 0xc82
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  xnor  x31, x30, x31
                  csrrw x6, 0x340, x0
                  xori        a3, s0, -1064
                  bgeu        a3, s10, 4f
                  slli        a6, sp, 2
4:                c.li        sp, 8
                  addi        tp, s3, 681
                  c.mv        s6, s7
                  sra         tp, s4, a7
                  rem         zero, t1, s8
                  sltiu       zero, s7, -1657
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  clz   x31, x30
                  xori        t3, s2, 1177
                  c.or        s0, a3
                  mulh        t1, t0, t5
                  or          ra, t1, s11
                  c.beqz      a5, 20f
                  c.srai      a3, 5
                  mulhsu      t0, s10, ra
                  c.sub       a3, s0
                  bge         a2, s3, 33f
                  addi        zero, s10, -1340
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  ctz   x31, x30
                  .word 0xb52063   # reserved -> trap, rotate arms
20:               srl         s9, t2, s5
                  add         t2, s0, s0
                  srl         sp, zero, a4
                  c.srli      a3, 7
                  c.addi16sp  sp, 224
                  add         s5, s5, a0
                  bgeu        t2, a7, 30f
                  or          zero, a2, s11
                  c.sub       a3, a3
                  c.srli      a3, 23
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  cpop  x31, x30
30:               slli        s9, t5, 22
                  c.add       s8, a2
                  c.slli      s10, 15
33:               c.addi4spn  a3, sp, 128
                  c.or        a3, a3
                  slli        s1, s4, 13
                  and         t0, s2, a5
                  sltiu       t1, s1, 1735
                  c.lui       a4, 19
                  srl         t2, t5, s5
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  min   x31, x30, x31
                  csrw mscratch, ra
                  c.jal 8191f
8191:            jal  ra, 8192f
8192:            jal  ra, 8193f
8193:            la   ra, 8194f
                  jalr x0, 0(ra)
8194:            csrr ra, mscratch
                  mulhu       s0, s5, gp
                  and         a6, s4, a0
                  div         s7, s11, a7
                  srl         gp, a4, t4
                  blt         s2, s0, 49f
                  auipc       zero, 643020
                  c.sub       a3, a3
                  c.bnez      s1, 58f
                  c.nop
49:               c.lui       s7, 17
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  minu  x31, x30, x31
                  and         zero, s3, a1
                  srai        gp, a1, 2
                  xor         a0, gp, t4
                  c.and       a3, a3
                  addi        s10, t6, -139
                  c.slli      s4, 13
                  c.addi      t1, -1
                  srai        t1, a3, 8
58:               c.or        a4, a3
                  sub         s7, t4, s2
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  max   x31, x30, x31
                  .hword 0x2000  # C-illegal leg -> trap
                  .hword 0x0001
                  slli        s4, a6, 28
                  add         s2, a0, a6
                  div         s6, s1, s9
                  c.addi      ra, -1
                  mul         s9, a3, s7
                  slt         s9, tp, a5
                  bne         t3, s3, 76f
                  c.sub       a3, a3
                  c.lui       t1, 18
                  slt         s4, s10, t3
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  maxu  x31, x30, x31
                  slt         s3, a3, a7
                  bltu        a5, tp, 73f
                  slt         a2, s0, a5
73:               auipc       zero, 96196
                  c.andi      a3, 10
                  slli        t3, tp, 31
76:               mulhu       ra, s6, s7
                  slt         a7, s1, s10
                  nop
                  or          s0, t0, s6
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  sext.b x31, x30
                  csrw mscratch, ra
                  jal  ra, 82131f
                  jalr x0, 0(ra)     # wrong-path ret: IF pre-decode pop
82131:          csrr ra, mscratch
                  add         s5, t3, a5
                  rem         s4, t4, s4
                  c.srai      a3, 21
                  srli        zero, a3, 17
                  or          a7, tp, t6
                  bge         ra, t2, 87f
                  srl         zero, s8, a5
87:               slti        ra, sp, -1614
                  c.addi16sp  sp, -16
                  bge         a2, gp, 94f
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  sext.h x31, x30
                  li   x30, 0x80000000
                  li   x31, -1
                  div  x31, x30, x31
                  rem  x31, x30, x30
                  li   x31, 0
                  divu x31, x30, x31
                  li   x31, 0
                  rem  x31, x30, x31
                  bltu        s11, sp, 100f
                  slt         a2, gp, ra
                  slli        a7, s8, 23
                  or          s0, a3, zero
94:               c.addi      ra, -1
                  sra         a4, a5, s1
                  sltu        t2, s2, s5
                  srai        s2, s2, 11
                  lui         a6, 357615
                  bge         gp, t3, 118f
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  zext.h x31, x30
                  .word 0xfeb50533   # reserved -> trap, rotate arms
100:              mulhu       ra, gp, t0
                  sll         t2, a0, s0
                  c.and       a3, a3
                  srai        a0, t3, 18
                  c.srai      a3, 2
                  mulhu       t1, a6, gp
                  xor         s5, s9, ra
                  xor         s11, gp, s9
                  c.addi16sp  sp, 112
                  sll         ra, t3, s10
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  rol   x31, x30, x31
                  sll         s8, t6, zero
                  c.andi      s0, 25
                  c.and       a3, a3
                  add         s5, s8, s1
                  c.addi16sp  sp, 32
                  lui         a7, 720132
                  beq         s1, t5, 127f
                  sub         s3, sp, s6
118:              xori        zero, t3, 754
                  srli        s0, a3, 18
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  ror   x31, x30, x31
                  bge         a7, s2, 128f
                  c.lui       s9, 22
                  xori        t2, s1, 209
                  slli        gp, s4, 31
                  auipc       s5, 839790
                  add         ra, t2, a0
                  sll         s11, t1, t4
127:              add         s8, a0, s1
128:              bgeu        zero, s7, 145f
                  rem         a0, t4, t4
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  rori  x31, x30, 7
                  c.bnez      a3, 141f
                  c.srai      a3, 19
                  c.beqz      a3, 139f
                  c.lui       t1, 23
                  nop
                  c.and       a3, a3
                  mulhsu      zero, a4, a6
                  sll         a7, zero, zero
                  c.li        sp, -1
139:              or          ra, zero, sp
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  orc.b x31, x30
                  csrw mscratch, x30
                  csrrs x31, mscratch, x0
                  csrrc x31, mscratch, x0
                  sll         t1, t4, s2
141:              c.and       a3, a3
                  slli        zero, t3, 16
                  sltiu       gp, a1, 1187
                  bne         a2, t2, 145f
145:              xori        s2, t6, 1058
                  nop
                  addi        t0, s1, -1936
                  c.mv        s11, a3
                  lui         zero, 276073
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  rev8  x31, x30
                  or          zero, t1, t2
                  auipc       s11, 800215
                  c.beqz      s0, 153f
153:              c.mv        s5, a3
                  andi        tp, tp, 1903
                  c.srli      a3, 16
                  c.xor       a3, a4
                  c.slli      a0, 4
                  c.srai      a3, 31
                  divu        s0, s8, s7
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  bclr  x31, x30, x31
                  bgeu        t1, a4, 179f
                  andi        s5, s0, 1765
                  sll         a6, sp, s8
                  c.addi4spn  a3, sp, 384
                  sra         a7, s8, t4
                  blt         t0, a7, 177f
                  srl         s9, s5, a0
                  c.andi      a3, 0
                  sll         a4, s4, t0
                  slti        a7, s4, -189
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  bext  x31, x30, x31
                  add         s8, sp, s5
                  c.bnez      a4, 185f
                  c.srai      a3, 8
                  mulhsu      s3, s5, t2
                  or          t3, a6, s1
                  mul         s1, zero, a5
                  mulh        t2, s2, s11
177:              or          a1, t2, t6
                  slti        a5, t4, 1885
179:              divu        s1, sp, s7
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  binv  x31, x30, x31
                  .word 0x1eb55513   # reserved -> trap, rotate arms
                  bgeu        tp, s9, 186f
                  c.or        s0, a3
                  sltu        a3, gp, s7
                  sra         a7, t3, a7
                  blt         s2, a2, 197f
185:              xori        ra, s11, 1348
186:              c.mv        s2, a6
                  mul         s3, t1, sp
                  c.xor       a3, a3
                  lui         s1, 515047
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  bset  x31, x30, x31
                  csrw mscratch, x8
                  la   x8, zbcov_scratch
                  sw   x9, 0(x8)
                  sw   sp, 4(x8)
                  addi sp, x8, 8
                  c.swsp x31, 0(sp)
                  c.lwsp x30, 0(sp)
                  sw   x31, 8(x8)
                  c.lw  x9, 8(x8)
                  c.sw  x9, 8(x8)
                  lw   sp, 4(x8)
                  lw   x9, 0(x8)
                  csrr x8, mscratch
                  c.srai      a3, 17
                  and         s3, t0, t2
                  mul         a5, s5, s2
                  c.li        s7, 31
                  div         s4, gp, a1
                  sll         ra, s9, t1
                  sra         gp, a0, a4
197:              div         s1, s3, s4
                  mul         s9, s9, t0
                  slli        zero, tp, 7
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  bclri x31, x30, 31
                  lui         a0, 562868
                  slti        s9, s5, -1321
                  or          a6, t0, a3
                  sll         s9, t3, t2
                  blt         s2, ra, 222f
                  xori        a5, t1, -196
                  c.bnez      a3, 212f
                  c.bnez      s0, 212f
                  c.add       gp, a0
                  c.add       ra, t4
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  bexti x31, x30, 15
                  slti        zero, a1, -761
                  slli        s9, a5, 22
212:              c.addi4spn  a3, sp, 384
                  srai        zero, a0, 26
                  c.slli      a7, 14
                  addi        a6, t3, -421
                  mulhsu      ra, s4, a7
                  auipc       t1, 529393
                  and         a5, t5, t5
                  c.and       a3, a3
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  binvi x31, x30, 0
                  xor         zero, s5, a1
                  mul         a1, s5, tp
222:              and         ra, ra, a5
                  slli        zero, s3, 11
                  sra         a2, t3, t2
                  c.slli      tp, 22
                  beq         a7, tp, 245f
                  bgeu        s0, tp, 231f
                  ori         ra, s8, 876
                  bge         sp, a1, 244f
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  bseti x31, x30, 31
                  srli        a3, s11, 2
231:              div         a2, a0, s6
                  blt         zero, a3, 247f
                  c.andi      a3, -1
                  div         s3, ra, s10
                  c.andi      a3, 17
                  slt         zero, a2, s11
                  ori         s0, t6, 1740
                  auipc       zero, 494085
                  c.andi      a3, -1
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  czero.eqz x31, x30, x31
                  csrw mscratch, ra
                  jal  ra, 82291f
                  jalr x0, 0(ra)     # wrong-path ret: IF pre-decode pop
82291:          csrr ra, mscratch
                  csrw mscratch, ra
                  c.jal 81291f
81291:            jal  ra, 81292f
81292:            jal  ra, 81293f
81293:            la   ra, 81294f
                  jalr x0, 0(ra)
81294:            csrr ra, mscratch
                  srl         tp, t6, a5
                  c.srli      a3, 18
                  c.or        a3, a3
                  slti        zero, t2, -299
244:              c.sub       a3, a3
245:              bne         a4, a3, 247f
                  c.lui       t3, 28
247:              mulh        s2, t2, s2
                  c.srli      a3, 11
                  c.beqz      a3, 259f
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  czero.nez x31, x30, x31
                  beq         s0, a3, 263f
                  c.li        a5, -1
                  c.bnez      a3, 271f
                  c.nop
                  sub         t2, s4, s11
                  c.addi4spn  a3, sp, 448
                  c.mv        ra, s9
                  c.add       a5, t5
                  c.addi      a1, 1
259:              blt         t2, t1, 265f
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  sh1add x31, x30, x31
                  .word 0x20b512b3   # reserved -> trap, rotate arms
                  c.nop
                  c.nop
                  bgeu        s1, s4, 279f
263:              mulh        s11, s3, s1
                  and         s10, gp, t6
265:              sll         ra, s2, gp
                  mul         a4, zero, t6
                  c.srai      a3, 13
                  mulhsu      s5, a7, s5
                  c.addi      ra, 21
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  sh2add x31, x30, x31
                  c.lui       ra, 9
271:              c.andi      s1, -1
                  c.slli      a6, 7
                  divu        zero, t3, t0
                  c.srli      a3, 6
                  c.bnez      a3, 282f
                  addi        a1, t3, 1440
                  and         s0, zero, t0
                  addi        s8, s11, 1722
279:              c.srai      a3, 3
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  sh3add x31, x30, x31
                  ori         gp, t1, 897
                  srli        t0, a7, 21
282:              c.li        a6, 12
                  lui         gp, 713061
                  c.slli      s1, 9
                  or          a1, a0, t0
                  c.li        s4, 25
                  c.andi      a3, -1
                  xor         s6, tp, a4
                  blt         s7, s0, 301f
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  andn  x31, x30, x31
                  li   x30, 0x80000000
                  li   x31, -1
                  div  x31, x30, x31
                  rem  x31, x30, x30
                  li   x31, 0
                  divu x31, x30, x31
                  li   x31, 0
                  rem  x31, x30, x31
                  sra         t3, s2, s7
                  c.xor       a3, a3
                  lui         s8, 462397
                  c.addi4spn  a0, sp, 192
                  auipc       s1, 42422
                  sltu        s4, s4, a1
                  addi        s1, a7, 80
                  srl         s6, s5, a1
                  blt         a5, s8, 306f
                  xor         s11, s3, s0
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  orn   x31, x30, x31
                  .hword 0xa000  # C-illegal leg -> trap
                  .hword 0x0001
                  sll         a5, t6, s5
301:              c.addi      s0, 16
                  auipc       gp, 17583
                  sltiu       a2, a1, 672
                  bgeu        s10, a0, 309f
                  c.mv        t0, t5
306:              rem         s4, s10, t0
                  mulhsu      s5, s5, sp
                  srl         a7, t5, t1
309:              lui         s6, 195534
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  xnor  x31, x30, x31
                  mulh        t1, t1, s7
                  rem         ra, t6, t5
                  bne         t3, a1, 317f
                  rem         a5, a6, s7
                  c.lui       s4, 11
                  sltiu       s2, s3, -962
                  auipc       s0, 553862
317:              c.xor       a3, a3
                  sub         s3, t3, ra
                  or          s1, s5, s7
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  clz   x31, x30
                  andi        s5, zero, 1046
                  mulhsu      a6, s10, s7
                  sltiu       s4, s0, -391
                  c.srli      a1, 10
                  c.add       s3, ra
                  c.beqz      a3, 327f
                  c.and       a3, a3
327:              c.or        a3, a3
                  or          a2, t4, zero
                  auipc       zero, 930734
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  ctz   x31, x30
                  sll         zero, zero, t0
                  addi        s1, t3, 1850
                  c.nop
                  div         a7, gp, s9
                  c.andi      a3, -1
                  mul         t1, a1, t0
                  divu        zero, a0, s4
                  auipc       zero, 433301
                  blt         s8, a0, 356f
                  lui         a3, 21139
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  cpop  x31, x30
                  .word 0x40b53533   # reserved -> trap, rotate arms
                  csrw mscratch, x30
                  csrrs x31, mscratch, x0
                  csrrc x31, mscratch, x0
                  mul         s4, t4, s6
                  sra         s11, s11, t6
                  sra         s9, s11, a3
                  nop
                  c.mv        sp, s6
                  blt         t2, t4, 351f
                  blt         tp, s9, 357f
                  xor         s4, t0, s7
                  c.and       a3, a3
                  blt         a6, ra, 359f
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  min   x31, x30, x31
                  srl         s6, t4, t6
351:              ori         sp, t6, -1480
                  c.addi4spn  a3, sp, 192
                  slti        s0, t6, -1133
                  c.beqz      a3, 358f
                  srli        s3, t2, 24
356:              mulhsu      s8, s1, a6
357:              mul         t0, s0, a4
358:              c.and       a5, a3
359:              c.lui       s5, 18
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  minu  x31, x30, x31
                  sra         zero, s2, a3
                  c.addi16sp  sp, 128
                  sltiu       t0, s4, 421
                  nop
                  slli        a5, t5, 9
                  nop
                  andi        s3, gp, -1915
                  xor         t2, tp, tp
                  sltu        s9, s5, a2
                  c.and       s0, a3
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  max   x31, x30, x31
                  slt         zero, s1, s11
                  xor         zero, s6, t4
                  c.li        a3, -1
                  c.xor       a3, a0
                  mul         a0, s6, gp
                  c.slli      a7, 31
                  addi        s6, t2, -821
                  div         s1, a5, t4
                  addi        a5, t2, -1654
                  xori        gp, sp, 476
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  maxu  x31, x30, x31
                  slti        t0, s10, 1520
                  c.and       a3, a3
                  divu        a3, s10, s10
                  sltu        tp, s11, s0
                  sub         gp, a7, s9
                  c.beqz      a3, 399f
                  c.and       a2, a3
                  mulh        s5, t0, t4
                  c.sub       a3, a3
                  c.beqz      a3, 408f
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  sext.b x31, x30
                  csrw mscratch, x8
                  la   x8, zbcov_scratch
                  sw   x9, 0(x8)
                  sw   sp, 4(x8)
                  addi sp, x8, 8
                  c.swsp x31, 0(sp)
                  c.lwsp x30, 0(sp)
                  sw   x31, 8(x8)
                  c.lw  x9, 8(x8)
                  c.sw  x9, 8(x8)
                  lw   sp, 4(x8)
                  lw   x9, 0(x8)
                  csrr x8, mscratch
                  c.addi      sp, 3
                  andi        a0, t3, 1713
                  mulh        a1, t6, s0
                  slli        ra, gp, 13
                  ori         t2, s4, 1757
                  c.nop
                  srl         t2, s7, s0
                  c.sub       a2, a3
                  c.lui       t1, 12
399:              c.srli      a3, 20
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  sext.h x31, x30
                  csrw mscratch, ra
                  jal  ra, 82451f
                  jalr x0, 0(ra)     # wrong-path ret: IF pre-decode pop
82451:          csrr ra, mscratch
                  c.slli      s3, 21
                  add         zero, zero, t1
                  c.addi4spn  a3, sp, 384
                  srai        zero, s1, 27
                  c.beqz      s0, 415f
                  beq         a6, s8, 409f
                  div         t1, t4, s8
                  slti        t0, a1, -1395
408:              c.addi16sp  sp, 304
409:              bltu        s3, s5, 424f
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  zext.h x31, x30
                  bltu        s5, t2, 416f
                  srl         ra, t5, s3
                  mulhsu      zero, a3, s5
                  c.addi16sp  sp, 128
                  sltiu       sp, a3, -1391
415:              c.or        a3, a3
416:              c.beqz      a3, 435f
                  auipc       a0, 93817
                  andi        zero, t1, 953
                  add         sp, t0, s5
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  rol   x31, x30, x31
                  .word 0xab50533   # reserved -> trap, rotate arms
                  and         s10, t0, t3
                  c.andi      a3, 17
                  bltu        s7, s4, 424f
                  srli        s4, t1, 5
424:              mulhu       sp, s7, a1
                  nop
                  add         t2, s8, gp
                  c.sub       a3, a3
                  bge         s10, s2, 433f
                  c.slli      a5, 5
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  ror   x31, x30, x31
                  bltu        a4, s5, 441f
                  c.andi      a3, 1
                  and         a7, s8, s7
433:              c.and       a3, a3
                  xori        a4, tp, -1238
435:              mulhsu      s6, a2, s2
                  nop
                  c.and       a3, a3
                  sltu        zero, s1, t3
                  addi        sp, ra, -1119
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  rori  x31, x30, 7
                  csrw mscratch, ra
                  c.jal 81491f
81491:            jal  ra, 81492f
81492:            jal  ra, 81493f
81493:            la   ra, 81494f
                  jalr x0, 0(ra)
81494:            csrr ra, mscratch
                  xor         t0, ra, s4
441:              slt         a0, s10, s11
                  mulhsu      t1, a7, t0
                  slti        a2, tp, 814
                  bne         ra, a0, 445f
445:              bgeu        zero, s1, 446f
446:              srli        zero, a3, 14
                  c.addi4spn  a3, sp, 896
                  xori        s8, s11, -1006
                  sltu        a1, s3, s7
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  orc.b x31, x30
                  mulhsu      t2, a0, t6
                  rem         a0, a3, s9
                  slti        gp, s7, -1588
                  c.or        a3, a3
                  sltiu       s0, s0, 252
                  div         a2, sp, s6
                  c.addi4spn  a3, sp, 784
                  c.addi4spn  a3, sp, 640
                  srai        s3, s9, 5
                  xor         s8, t0, s11
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  rev8  x31, x30
                  c.lui       a0, 21
                  mulh        s1, s8, s5
                  c.addi16sp  sp, 128
                  mulhsu      s0, s2, a3
                  c.li        ra, 23
                  beq         s2, t0, 484f
                  addi        zero, s10, 722
                  slt         zero, s11, a6
                  blt         a0, t3, 473f
                  xori        s7, s2, 1137
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  bclr  x31, x30, x31
                  c.nop
                  slt         a5, s9, s9
                  c.and       s0, a1
473:              bge         s11, gp, 483f
                  slli        s1, a5, 26
                  c.srai      a3, 16
                  c.mv        sp, ra
                  bgeu        s0, zero, 482f
                  c.sub       a3, a3
                  sltu        a5, a3, s11
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  bext  x31, x30, x31
                  xori        s3, a1, 1605
                  xor         s1, a1, t5
482:              mulhsu      t0, a4, a0
483:              c.li        a0, -1
484:              sra         s4, s9, sp
                  c.and       a3, a3
                  sra         zero, s1, gp
                  sra         s10, t1, s3
                  c.li        t0, -1
                  c.slli      ra, 22
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  binv  x31, x30, x31
                  li   x30, 0x80000000
                  li   x31, -1
                  div  x31, x30, x31
                  rem  x31, x30, x30
                  li   x31, 0
                  divu x31, x30, x31
                  li   x31, 0
                  rem  x31, x30, x31
                  srai        a5, s7, 13
                  c.and       s1, a3
                  mulh        s4, t3, s10
                  andi        zero, a7, -20
                  c.or        a3, a3
                  srli        s7, a0, 16
                  bge         t5, a7, 503f
                  c.and       s0, a1
                  sltiu       t0, a5, -1782
                  srai        s3, s6, 8
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  bset  x31, x30, x31
                  .word 0x60b52533   # reserved -> trap, rotate arms
                  sltiu       t0, t4, -319
                  c.and       a4, a3
                  div         a6, s1, t4
503:              mul         s0, a5, sp
                  c.beqz      a3, 508f
                  ori         a3, s1, -842
                  sub         zero, a6, s10
                  c.addi16sp  sp, -16
508:              bne         s2, a2, 527f
                  sltiu       gp, s7, 1919
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  bclri x31, x30, 31
                  c.slli      s4, 24
                  c.addi16sp  sp, 480
                  c.sub       a3, a3
                  c.beqz      a3, 519f
                  slli        zero, s10, 18
                  add         zero, sp, s9
                  c.xor       a3, a3
                  sra         t2, s10, t0
                  sltiu       t3, t2, -1766
519:              slt         s3, gp, s3
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  bexti x31, x30, 15
                  c.xor       a3, a3
                  bge         t1, s8, 522f
522:              mulhsu      ra, s0, t0
                  c.bnez      a3, 524f
524:              mulhu       zero, s8, a0
                  c.and       a3, a3
                  c.and       s1, a2
527:              c.slli      a4, 11
                  xor         s8, s4, ra
                  c.beqz      a3, 541f
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  binvi x31, x30, 0
                  bge         s11, a5, 532f
                  andi        t1, sp, 1350
532:              c.srai      a3, 22
                  slti        zero, s4, 301
                  addi        tp, sp, 935
                  bltu        a3, s8, 541f
                  slt         gp, s5, s3
                  c.mv        sp, a4
                  srl         a0, t2, gp
                  blt         s4, gp, 544f
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  bseti x31, x30, 31
                  .hword 0x7002  # C-illegal leg -> trap
                  .hword 0x0001
                  csrw mscratch, x30
                  csrrs x31, mscratch, x0
                  csrrc x31, mscratch, x0
                  beq         t1, a4, 559f
541:              bgeu        t5, s8, 559f
                  nop
                  slti        s0, tp, -872
544:              slt         a4, s3, sp
                  and         zero, gp, t3
                  andi        a3, t5, 1047
                  slti        s6, t6, 170
                  and         t0, gp, t3
                  sub         s11, t2, s0
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  czero.eqz x31, x30, x31
                  auipc       s5, 833035
                  addi        t0, t3, -424
                  c.addi      t2, 27
                  bge         s6, gp, 559f
                  mulhu       s9, sp, s5
                  auipc       a1, 15960
                  c.li        a5, 30
                  c.addi16sp  sp, -16
                  c.and       a3, a3
559:              bne         ra, ra, 576f
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  czero.nez x31, x30, x31
                  csrw mscratch, ra
                  jal  ra, 82611f
                  jalr x0, 0(ra)     # wrong-path ret: IF pre-decode pop
82611:          csrr ra, mscratch
                  lui         s11, 183491
                  andi        t3, s9, -1510
                  beq         t1, t3, 575f
                  c.slli      a2, 1
                  srai        tp, a4, 26
                  sltu        a6, zero, s1
                  nop
                  c.nop
                  c.addi4spn  a1, sp, 384
                  auipc       a5, 981465
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  sh1add x31, x30, x31
                  c.add       s10, t6
                  add         gp, t1, s6
                  c.srai      a1, 16
                  mulhu       zero, a5, a6
                  c.srai      a3, 28
575:              c.nop
576:              slti        t1, t5, -958
                  or          a0, a0, s5
                  ori         tp, t1, -1665
                  c.and       a3, s1
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  sh2add x31, x30, x31
                  .word 0x48b52533   # reserved -> trap, rotate arms
                  c.nop
                  c.andi      a3, 11
                  srl         s3, a0, s10
                  c.xor       a3, a3
                  mulh        zero, s3, a0
                  sub         a5, t1, a0
                  bne         a0, a5, 597f
                  beq         s9, s4, 602f
                  c.sub       a3, a1
                  add         s0, sp, tp
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  sh3add x31, x30, x31
                  csrw mscratch, x8
                  la   x8, zbcov_scratch
                  sw   x9, 0(x8)
                  sw   sp, 4(x8)
                  addi sp, x8, 8
                  c.swsp x31, 0(sp)
                  c.lwsp x30, 0(sp)
                  sw   x31, 8(x8)
                  c.lw  x9, 8(x8)
                  c.sw  x9, 8(x8)
                  lw   sp, 4(x8)
                  lw   x9, 0(x8)
                  csrr x8, mscratch
                  sll         a3, t0, sp
                  mulhu       s8, tp, a3
                  bgeu        a1, ra, 606f
                  slli        a4, t4, 7
                  mulh        s1, gp, s2
                  slli        s2, ra, 18
                  c.beqz      a3, 607f
597:              mulhsu      a7, t4, s2
                  srl         s8, t3, s6
                  c.srli      a3, 8
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  andn  x31, x30, x31
                  mul         a4, a4, t4
                  c.addi16sp  sp, -16
602:              c.beqz      a3, 606f
                  xori        a0, t0, 1914
                  and         a0, s2, t2
                  c.lui       s2, 9
606:              beq         gp, s2, 617f
607:              sltu        t2, a3, t3
                  or          t2, s6, a1
                  beq         t5, s5, 617f
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  orn   x31, x30, x31
                  srai        s3, s1, 22
                  auipc       s10, 738269
                  bge         a0, s5, 622f
                  div         s4, s5, s2
                  sll         zero, t5, t4
                  c.addi16sp  sp, 128
                  lui         t1, 406666
617:              auipc       a6, 38168
                  div         s1, s4, s6
                  bltu        a0, a6, 621f
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  xnor  x31, x30, x31
                  c.beqz      a3, 622f
621:              c.andi      a3, -1
622:              auipc       a2, 959941
                  c.sub       a3, a3
                  div         zero, gp, s3
                  sltu        s8, t2, t2
                  c.slli      s8, 7
                  mulhsu      t1, a5, a4
                  c.addi16sp  sp, -16
                  ori         ra, sp, -1949
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  clz   x31, x30
                  mulhsu      zero, a0, s11
                  auipc       tp, 243275
                  c.add       sp, a0
                  c.or        a5, s0
                  mulhsu      s3, s0, a7
                  beq         s6, a1, 650f
                  c.lui       a5, 25
                  beq         t0, sp, 643f
                  c.add       ra, s0
                  c.and       a3, a5
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  ctz   x31, x30
                  csrw mscratch, ra
                  c.jal 81691f
81691:            jal  ra, 81692f
81692:            jal  ra, 81693f
81693:            la   ra, 81694f
                  jalr x0, 0(ra)
81694:            csrr ra, mscratch
                  add         a7, a0, tp
                  srl         a3, s0, ra
                  sub         s2, s0, a6
643:              c.sub       a3, a3
                  or          s11, s1, a1
                  c.lui       ra, 18
                  or          gp, a5, a3
                  c.addi16sp  sp, 96
                  c.mv        sp, a7
                  srl         s6, t4, a5
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  cpop  x31, x30
650:              c.or        a3, a3
                  c.beqz      a2, 666f
                  sltu        s3, a3, t4
                  sll         zero, t0, t1
                  slti        t3, s3, 1928
                  ori         a7, s6, -31
                  slt         s9, t3, s1
                  sltiu       zero, s10, 1174
                  c.lui       a3, 16
                  srl         a0, zero, ra
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  min   x31, x30, x31
                  .word 0x68b52533   # reserved -> trap, rotate arms
                  sltiu       a6, t0, 1038
                  sll         zero, a1, s11
                  mulhsu      t0, s0, s1
                  bgeu        s8, t6, 677f
                  c.and       a0, a3
                  mulh        s3, a2, tp
666:              mulh        zero, s3, s3
                  mulhu       a1, s10, a4
                  mulh        s6, a0, a0
                  mul         s6, zero, s11
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  minu  x31, x30, x31
                  bge         tp, a3, 681f
                  and         s8, s3, t0
                  srli        s7, ra, 22
                  lui         s4, 102920
                  c.addi4spn  a3, sp, 832
                  xor         s6, s3, t4
                  srli        a5, s6, 1
677:              rem         t0, ra, s10
                  mulh        s0, t0, ra
                  ori         t3, s9, 1009
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  max   x31, x30, x31
                  srai        a7, s8, 6
681:              add         s4, s6, s2
                  mul         s5, ra, s3
                  slli        s10, t0, 26
                  divu        t0, s7, t5
                  and         a7, a4, a0
                  c.mv        t2, a7
                  lui         s11, 794086
                  mulh        a6, t6, ra
                  c.addi      ra, 10
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  maxu  x31, x30, x31
                  li   x30, 0x80000000
                  li   x31, -1
                  div  x31, x30, x31
                  rem  x31, x30, x30
                  li   x31, 0
                  divu x31, x30, x31
                  li   x31, 0
                  rem  x31, x30, x31
                  c.or        a3, a3
                  c.xor       a4, a3
                  sltu        s5, a3, t6
                  slt         s4, s6, a1
                  mulhsu      zero, s5, s9
                  bltu        a4, ra, 697f
                  c.sub       a5, a3
697:              c.sub       a3, a0
                  add         t1, s9, t0
                  c.nop
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  sext.b x31, x30
                  c.sub       a3, a1
                  mulhu       s5, s0, a1
                  add         t2, a4, a5
                  bgeu        s0, s9, 711f
                  div         s2, t3, s4
                  c.srli      a3, 2
                  add         t3, t0, sp
                  bge         t1, t4, 714f
                  c.beqz      a3, 710f
                  bne         a3, t0, 727f
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  sext.h x31, x30
710:              bge         ra, s1, 723f
711:              c.andi      a3, 27
                  bge         tp, a0, 718f
                  c.or        a3, a3
714:              sra         s2, a6, a5
                  c.addi4spn  a3, sp, 96
                  auipc       ra, 256684
                  srli        s1, sp, 30
718:              xor         t3, t6, s4
                  c.srli      a3, 17
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  zext.h x31, x30
                  csrw mscratch, ra
                  jal  ra, 82771f
                  jalr x0, 0(ra)     # wrong-path ret: IF pre-decode pop
82771:          csrr ra, mscratch
                  ori         s5, a4, -246
                  c.sub       a0, a3
                  srli        zero, t5, 18
723:              c.mv        s3, t6
                  bltu        a7, t5, 728f
                  bltu        s1, a6, 727f
                  add         a7, a7, tp
727:              c.addi      t3, -1
728:              mul         zero, sp, s6
                  c.slli      a7, 19
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  rol   x31, x30, x31
                  beq         a5, s9, 731f
731:              slti        a3, s8, 285
                  mul         a4, s10, s11
                  beq         a6, t0, 739f
                  c.addi4spn  a4, sp, 128
                  andi        a6, s11, 1930
                  c.and       a3, a3
                  mulhsu      s4, a3, gp
                  c.addi      ra, 2
739:              bne         a7, a5, 758f
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  ror   x31, x30, x31
                  .word 0x28b52533   # reserved -> trap, rotate arms
                  csrw mscratch, x30
                  csrrs x31, mscratch, x0
                  csrrc x31, mscratch, x0
                  c.beqz      a3, 751f
                  c.bnez      a3, 760f
                  nop
                  ori         s0, zero, 1010
                  c.addi      s5, 18
                  andi        a7, t1, 961
                  mulhu       s2, tp, s5
                  bltu        t0, s9, 752f
                  blt         a1, s8, 758f
                  and         sp, s8, s6
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  rori  x31, x30, 7
                  rem         zero, t1, t1
751:              slli        t2, a0, 6
752:              c.beqz      a3, 769f
                  sra         a6, s9, a1
                  srai        s7, a0, 26
                  c.add       s10, a0
                  c.andi      a3, -1
                  slli        t2, s6, 14
758:              sra         s6, ra, sp
                  bge         s10, a4, 764f
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  orc.b x31, x30
760:              mulh        s3, t0, a2
                  slt         zero, s1, t0
                  bne         s7, t5, 777f
                  and         t1, t3, s6
764:              bge         s4, t2, 775f
                  divu        a3, s10, s3
                  lui         a5, 957131
                  ori         s2, t3, -1529
                  c.or        a3, a5
769:              c.lui       s0, 2
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  rev8  x31, x30
                  c.slli      ra, 9
                  or          a0, ra, s6
                  c.add       a2, s4
                  slt         s1, a5, s9
                  bgeu        a4, s1, 786f
775:              c.li        ra, 25
                  mulhsu      sp, s7, t3
777:              c.sub       a3, a3
                  c.srai      a3, 14
                  blt         zero, tp, 798f
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  bclr  x31, x30, x31
                  .hword 0x9c01  # C-illegal leg -> trap
                  .hword 0x0001
                  lui         zero, 529
                  mulh        s10, s1, sp
                  c.addi4spn  a3, sp, 448
                  c.srli      a1, 18
                  sub         a6, s8, sp
                  and         s3, s1, s8
786:              c.and       a3, a1
                  c.and       s1, a3
                  c.addi16sp  sp, 96
                  bgeu        s6, s10, 799f
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  bext  x31, x30, x31
                  csrw mscratch, x8
                  la   x8, zbcov_scratch
                  sw   x9, 0(x8)
                  sw   sp, 4(x8)
                  addi sp, x8, 8
                  c.swsp x31, 0(sp)
                  c.lwsp x30, 0(sp)
                  sw   x31, 8(x8)
                  c.lw  x9, 8(x8)
                  c.sw  x9, 8(x8)
                  lw   sp, 4(x8)
                  lw   x9, 0(x8)
                  csrr x8, mscratch
                  c.srai      a3, 12
                  c.bnez      a3, 795f
                  andi        t3, s0, 1478
                  add         s1, s4, s6
                  mulh        a0, s10, gp
795:              addi        s10, a0, 158
                  or          sp, a5, s5
                  c.lui       a2, 31
798:              rem         sp, a6, a6
799:              c.addi16sp  sp, 208
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  binv  x31, x30, x31
                  beq         a5, sp, 801f
801:              mulh        a1, s9, s8
                  c.addi16sp  sp, -16
                  slt         s8, t6, s9
                  slti        a2, ra, 1064
                  rem         a4, s4, ra
                  add         a6, a2, zero
                  c.srai      a4, 26
                  sra         a7, a3, tp
                  mul         a4, a7, s1
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  bset  x31, x30, x31
                  mul         a6, s2, tp
                  sltu        a5, t6, s11
                  c.add       a5, s11
                  bne         sp, a5, 818f
                  sra         s11, t6, ra
                  addi        t0, gp, -913
                  srai        a4, s5, 3
                  sll         t2, s2, s7
818:              div         s4, s9, a6
                  c.addi      sp, 14
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  bclri x31, x30, 31
                  .word 0x8b52533   # reserved -> trap, rotate arms
                  c.addi4spn  a1, sp, 896
                  srli        s2, t1, 2
                  blt         ra, s10, 832f
                  c.srli      a3, 21
                  sra         s1, a3, gp
                  addi        s10, t0, 2000
                  c.slli      t0, 28
                  sra         zero, a0, sp
                  andi        s9, t5, 1657
                  xor         s11, s1, a1
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  bexti x31, x30, 15
                  bne         t1, s3, 847f
                  c.mv        s4, s11
832:              c.srai      a5, 19
                  addi        zero, gp, -726
                  lui         s1, 613841
                  bltu        ra, t4, 841f
                  and         sp, s1, t4
                  addi        s2, s10, 921
                  div         a2, s8, a0
                  nop
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  binvi x31, x30, 0
                  csrw mscratch, ra
                  c.jal 81891f
81891:            jal  ra, 81892f
81892:            jal  ra, 81893f
81893:            la   ra, 81894f
                  jalr x0, 0(ra)
81894:            csrr ra, mscratch
                  c.addi16sp  sp, -16
841:              xori        s9, t1, -435
                  beq         a2, s2, 843f
843:              c.lui       a3, 21
                  bne         s7, ra, 848f
                  sltu        s3, t0, a5
                  and         t1, t4, tp
847:              slli        t2, t4, 5
848:              and         gp, a0, s5
                  nop
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  bseti x31, x30, 31
                  addi        s0, tp, -191
                  c.addi      s1, 31
                  xori        s1, a4, -1926
                  slt         s2, s10, a0
                  beq         t5, a2, 859f
                  xor         zero, a1, t1
                  bgeu        s8, s5, 869f
                  sltiu       t3, s10, -2041
                  div         s7, a2, s8
859:              srl         a4, s10, t3
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  czero.eqz x31, x30, x31
                  ori         zero, tp, 1263
                  bgeu        t4, a2, 866f
                  slli        zero, a7, 7
                  c.andi      a3, 11
                  nop
                  sra         a2, sp, s7
866:              div         a1, s5, a0
                  c.or        a3, a3
                  c.and       a3, s0
869:              andi        gp, s5, -1036
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  czero.nez x31, x30, x31
                  xor         s1, a2, a4
                  blt         s9, t0, 881f
                  mulhu       zero, s5, a3
                  sll         t0, s7, a5
                  ori         s7, a4, -1216
                  c.addi16sp  sp, 32
                  c.li        s3, 12
                  c.nop
                  lui         s9, 61580
                  sll         s7, zero, a5
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  sh1add x31, x30, x31
                  csrw mscratch, ra
                  jal  ra, 82931f
                  jalr x0, 0(ra)     # wrong-path ret: IF pre-decode pop
82931:          csrr ra, mscratch
                  blt         t3, s7, 891f
881:              c.beqz      a4, 895f
                  auipc       s0, 1032930
                  nop
                  andi        s1, a3, -1883
                  slli        zero, a3, 12
                  bne         a2, t0, 888f
                  mul         a1, a3, a2
888:              c.and       s1, a3
                  c.beqz      a3, 895f
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  sh2add x31, x30, x31
                  li   x30, 0x80000000
                  li   x31, -1
                  div  x31, x30, x31
                  rem  x31, x30, x30
                  li   x31, 0
                  divu x31, x30, x31
                  li   x31, 0
                  rem  x31, x30, x31
                  c.andi      a3, 16
891:              sll         s0, s9, ra
                  lui         a2, 133195
                  andi        s2, gp, -96
                  slt         zero, t6, s8
895:              or          s6, gp, ra
                  xori        zero, s4, 1871
                  c.li        tp, -1
                  c.nop
                  sll         a5, s7, s0
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  sh3add x31, x30, x31
                  .word 0xeb55533   # reserved -> trap, rotate arms
                  sub         s1, t2, s6
                  c.nop
                  mulhsu      zero, gp, sp
                  blt         zero, t5, 911f
                  mulh        s8, t0, a7
                  srl         s4, a1, zero
                  addi        s6, t2, 890
                  c.nop
                  bltu        ra, a7, 923f
                  srli        t2, s5, 18
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  andn  x31, x30, x31
                  andi        s10, s3, -188
911:              xori        s2, t6, -736
                  c.and       a3, a3
                  sra         a2, zero, zero
                  c.addi      gp, 26
                  mul         s0, s10, a5
                  c.sub       a3, a5
                  c.li        a2, 14
                  c.addi16sp  sp, -16
                  divu        s1, gp, a1
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  orn   x31, x30, x31
                  or          s5, a1, gp
                  add         ra, s6, s4
                  sra         s5, a7, s11
923:              c.sub       a2, a3
                  divu        gp, s10, zero
                  add         s3, t4, t2
                  lui         t2, 980705
                  c.and       a3, a3
                  div         a7, t0, a1
                  c.addi4spn  a3, sp, 864
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  xnor  x31, x30, x31
                  slt         ra, s3, s11
                  divu        t2, s9, s3
                  c.addi      a4, 25
                  bltu        gp, tp, 944f
                  sltu        zero, t5, ra
                  srai        s0, s9, 14
                  addi        t2, a4, 716
                  sub         zero, gp, ra
                  c.slli      ra, 29
                  sltu        t2, s9, s9
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  clz   x31, x30
                  csrw mscratch, x30
                  csrrs x31, mscratch, x0
                  csrrc x31, mscratch, x0
                  or          a2, t3, t3
                  c.xor       a5, a3
                  sub         t0, a7, s3
                  andi        s1, tp, 2000
944:              ori         a7, s8, 1081
                  sltiu       ra, t4, -930
                  add         sp, t1, a7
                  sltu        a2, a1, tp
                  c.lui       s11, 1
                  beq         t0, s7, 968f
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  ctz   x31, x30
                  c.mv        s9, s7
                  sll         a6, s3, s9
                  c.add       tp, ra
                  xor         ra, s7, a2
                  c.mv        a4, t6
                  bltu        s8, a1, 956f
956:              c.and       a3, a3
                  div         t2, tp, a1
                  c.nop
                  sltiu       zero, t6, 1064
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  cpop  x31, x30
                  srai        s2, s9, 15
                  c.nop
                  bltu        t3, a4, 980f
                  slt         a7, t4, a4
                  and         a7, s5, ra
                  bne         a6, a5, 984f
                  slti        s11, tp, 1761
                  lui         a2, 371685
968:              rem         a4, a6, a0
                  c.xor       a3, a3
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  min   x31, x30, x31
                  c.addi      s0, 1
                  slt         s8, t2, s6
                  lui         zero, 44296
                  lui         a4, 311348
                  bne         t1, a1, 993f
                  c.beqz      a3, 981f
                  mulhsu      a5, s1, a1
                  mulhsu      a2, s8, s1
                  lui         s11, 822194
                  sltiu       s7, a4, 1288
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  minu  x31, x30, x31
                  .word 0xeb51533   # reserved -> trap, rotate arms
980:              bge         a7, sp, 982f
981:              mulhu       tp, t3, a4
982:              divu        t3, s9, s4
                  divu        s3, t1, s11
984:              c.srai      a3, 4
                  c.srli      a3, 17
                  andi        s1, s3, -1462
                  c.lui       s0, 25
                  sltiu       zero, s8, -1553
                  nop
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  max   x31, x30, x31
                  csrw mscratch, x8
                  la   x8, zbcov_scratch
                  sw   x9, 0(x8)
                  sw   sp, 4(x8)
                  addi sp, x8, 8
                  c.swsp x31, 0(sp)
                  c.lwsp x30, 0(sp)
                  sw   x31, 8(x8)
                  c.lw  x9, 8(x8)
                  c.sw  x9, 8(x8)
                  lw   sp, 4(x8)
                  lw   x9, 0(x8)
                  csrr x8, mscratch
                  c.or        a3, a3
                  c.mv        a4, s2
                  sra         sp, a6, tp
993:              div         a2, tp, s3
                  rem         zero, s2, sp
                  srai        s8, a1, 31
                  bltu        a3, a1, 1001f
                  beq         a2, a7, 999f
                  sll         zero, t6, t3
999:              c.addi16sp  sp, -16
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  maxu  x31, x30, x31
                  andi        a4, a1, -1870
1001:             divu        tp, t0, s1
                  ori         tp, t0, 861
                  bltu        gp, zero, 1010f
                  bne         t1, a0, 1016f
                  c.addi      s2, -1
                  blt         ra, s9, 1017f
                  rem         a1, s8, a1
                  or          t2, s3, s7
                  srai        s11, a3, 0
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  sext.b x31, x30
1010:             bltu        s9, a1, 1014f
                  c.bnez      a3, 1026f
                  sltu        t3, a5, a0
                  or          a0, t4, a2
1014:             divu        s10, zero, a1
                  beq         a7, a2, 1026f
1016:             c.nop
1017:             srl         t0, ra, s10
                  sub         s0, s11, t5
                  sra         s5, t4, t1
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  sext.h x31, x30
                  bltu        s0, a0, 1025f
                  lui         s8, 612442
                  c.beqz      a3, 1024f
                  andi        a6, t6, 203
1024:             srl         s11, a0, ra
1025:             mulhsu      s8, s4, a7
1026:             c.mv        s1, t6
                  srl         s5, s9, t5
                  mulhsu      a3, s8, s0
                  addi        zero, t0, -919
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  zext.h x31, x30
                  sra         zero, s1, t6
                  lui         s8, 803339
                  divu        a6, s2, tp
                  divu        t1, a0, a1
                  andi        s9, a5, -785
                  xori        s3, s6, -2043
                  mul         a5, s8, sp
                  sll         s6, s11, a6
                  srai        a5, a3, 3
                  c.andi      a3, -1
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  rol   x31, x30, x31
                  csrw mscratch, ra
                  jal  ra, 821091f
                  jalr x0, 0(ra)     # wrong-path ret: IF pre-decode pop
821091:          csrr ra, mscratch
                  csrw mscratch, ra
                  c.jal 811091f
811091:            jal  ra, 811092f
811092:            jal  ra, 811093f
811093:            la   ra, 811094f
                  jalr x0, 0(ra)
811094:            csrr ra, mscratch
                  sltu        tp, t6, sp
                  div         s1, s5, t6
                  sll         s4, s2, s2
                  c.addi4spn  s1, sp, 640
                  bne         a6, t6, 1048f
                  c.add       a6, s8
                  c.lui       s4, 14
                  c.bnez      a3, 1061f
1048:             bne         a2, a7, 1067f
                  sll         a7, s8, t5
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  ror   x31, x30, x31
                  or          s9, a5, a2
                  c.addi4spn  a3, sp, 96
                  c.srli      a3, 6
                  mulhsu      s5, a6, zero
                  c.beqz      a3, 1059f
                  slli        zero, ra, 7
                  nop
                  srl         gp, a6, t5
                  c.mv        a6, s11
1059:             c.or        a3, a3
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  rori  x31, x30, 7
                  .word 0x60b51513   # reserved -> trap, rotate arms
                  mulhsu      sp, tp, a5
1061:             c.or        a3, a3
                  bne         t5, tp, 1066f
                  srai        s2, ra, 0
                  c.slli      ra, 26
                  bge         s8, a4, 1067f
1066:             c.li        t1, -1
1067:             or          gp, a0, gp
                  slt         t0, s9, s4
                  rem         sp, a2, a2
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  orc.b x31, x30
                  rem         s6, s7, t5
                  c.sub       a3, a3
                  mulh        a5, s8, zero
                  sra         s8, s11, t1
                  blt         ra, s2, 1079f
                  nop
                  and         s5, t5, a3
                  sltiu       a1, s6, 335
                  and         t3, t3, a0
1079:             c.srai      s0, 19
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  rev8  x31, x30
                  srli        tp, s8, 19
                  c.beqz      a3, 1087f
                  or          s0, t6, a1
                  srl         t3, s1, t1
                  beq         s7, t5, 1103f
                  slt         t2, tp, s6
                  c.bnez      a3, 1087f
1087:             c.nop
                  c.or        a3, a3
                  bgeu        a6, a2, 1106f
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  bclr  x31, x30, x31
                  li   x30, 0x80000000
                  li   x31, -1
                  div  x31, x30, x31
                  rem  x31, x30, x30
                  li   x31, 0
                  divu x31, x30, x31
                  li   x31, 0
                  rem  x31, x30, x31
                  c.mv        s3, t3
                  ori         s5, t5, -184
                  bltu        t3, s3, 1094f
                  ori         a3, t5, -1522
1094:             slti        zero, a3, 1757
                  addi        a7, s4, -472
                  auipc       ra, 324812
                  slti        s7, s11, -362
                  blt         s4, t3, 1116f
                  c.addi16sp  sp, 400
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  bext  x31, x30, x31
                  bltu        s9, s3, 1115f
                  c.mv        ra, s11
                  bltu        a7, s4, 1109f
1103:             mulh        s5, s10, s2
                  bne         t4, s5, 1114f
                  srai        s6, a0, 27
1106:             beq         ra, s11, 1117f
                  mulhu       zero, a5, a3
                  c.srai      s0, 12
1109:             c.xor       a3, a3
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  binv  x31, x30, x31
                  nop
                  mul         s4, s2, a6
                  nop
                  beq         t6, s3, 1132f
1114:             c.li        t3, -1
1115:             c.andi      a3, 29
1116:             srli        t3, ra, 22
1117:             c.srai      a3, 14
                  blt         tp, t4, 1130f
                  srl         a2, gp, a7
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  bset  x31, x30, x31
                  xor         a3, t5, a7
                  sub         a7, a5, t5
                  c.addi16sp  sp, 224
                  and         s0, a3, a2
                  addi        tp, s8, 1758
                  c.add       ra, s2
                  mulhsu      s8, s7, a2
                  mulh        gp, sp, s6
                  slt         gp, s4, s1
                  c.srli      a3, 5
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  bclri x31, x30, 31
1130:             and         s3, gp, s7
                  srai        zero, s3, 9
1132:             srai        a0, t1, 30
                  c.and       a3, a3
                  andi        s4, a2, 541
                  c.and       s1, a0
                  or          zero, s11, s8
                  divu        s0, t5, a5
                  c.lui       s7, 16
                  c.beqz      a3, 1149f
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  bexti x31, x30, 15
                  csrw mscratch, x30
                  csrrs x31, mscratch, x0
                  csrrc x31, mscratch, x0
                  c.li        t2, -1
                  xor         t1, a2, s6
                  sub         zero, sp, s2
                  sra         s0, s9, a2
                  mulhu       a0, s1, t5
                  c.srli      a3, 27
                  andi        a0, s11, -2040
                  c.andi      a3, 2
                  nop
1149:             nop
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  binvi x31, x30, 0
                  c.addi4spn  a3, sp, 32
                  bne         t3, t3, 1152f
1152:             srli        s6, s5, 22
                  xor         t2, a2, s3
                  rem         s6, a1, t6
                  beq         a2, t1, 1168f
                  c.andi      a3, -1
                  beq         tp, gp, 1163f
                  c.beqz      a3, 1169f
                  c.li        a5, 2
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  bseti x31, x30, 31
                  c.slli      ra, 12
                  bge         t4, s7, 1167f
                  c.addi4spn  a3, sp, 896
1163:             mulh        a2, sp, s0
                  andi        a2, a7, 1534
                  bgeu        zero, a0, 1173f
                  andi        zero, s0, 1356
1167:             mulhu       t3, t0, t2
1168:             mulh        s10, s0, s2
1169:             mulhu       s6, s2, s6
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  czero.eqz x31, x30, x31
                  srai        gp, s5, 29
                  sltu        t3, s8, tp
                  c.or        a1, a4
1173:             lui         a3, 316174
                  mulhsu      a5, a5, a0
                  add         zero, s3, t6
                  c.addi4spn  a3, sp, 976
                  bge         s2, a5, 1192f
                  c.li        t2, 19
                  c.andi      a0, -1
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  czero.nez x31, x30, x31
                  bltu        t1, a6, 1181f
1181:             beq         a3, s8, 1200f
                  lui         s3, 10206
                  slli        s3, t0, 30
                  sub         ra, t0, s11
                  c.slli      s5, 13
                  and         t2, s9, s11
                  xori        s9, s1, -1724
                  add         a0, t3, a6
                  and         zero, zero, a4
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  sh1add x31, x30, x31
                  csrw mscratch, x8
                  la   x8, zbcov_scratch
                  sw   x9, 0(x8)
                  sw   sp, 4(x8)
                  addi sp, x8, 8
                  c.swsp x31, 0(sp)
                  c.lwsp x30, 0(sp)
                  sw   x31, 8(x8)
                  c.lw  x9, 8(x8)
                  c.sw  x9, 8(x8)
                  lw   sp, 4(x8)
                  lw   x9, 0(x8)
                  csrr x8, mscratch
                  mul         a6, s6, s8
                  xor         a2, gp, a2
1192:             c.srli      a3, 16
                  or          a3, a2, t4
                  sll         s6, sp, t0
                  lui         s2, 668501
                  c.andi      a3, -1
                  andi        s4, s1, -59
                  add         s6, t1, s5
                  c.or        a4, a3
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  sh2add x31, x30, x31
                  csrw mscratch, ra
                  jal  ra, 821251f
                  jalr x0, 0(ra)     # wrong-path ret: IF pre-decode pop
821251:          csrr ra, mscratch
1200:             mulh        s3, s0, t2
                  c.beqz      a3, 1207f
                  c.addi4spn  a3, sp, 320
                  c.slli      a2, 9
                  sltiu       s3, s2, 12
                  beq         a5, a5, 1216f
                  add         s5, a6, t3
1207:             c.xor       a3, a3
                  add         s4, s10, s2
                  sub         a0, s2, s5
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  sh3add x31, x30, x31
                  auipc       tp, 994823
                  c.or        a3, a3
                  c.slli      ra, 22
                  div         a0, s6, s6
                  c.sub       s1, s1
                  sltiu       s10, t1, 301
1216:             mulh        s11, t1, s0
                  c.addi4spn  a3, sp, 640
                  ori         a5, s6, 737
                  c.sub       a3, a3
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  andn  x31, x30, x31
                  slli        a1, s9, 11
                  slli        s4, t3, 31
                  mulhsu      a6, s4, a7
                  srai        a1, s11, 14
                  auipc       zero, 970311
                  c.addi      t2, -1
                  rem         a4, t5, s7
                  c.bnez      a3, 1237f
                  bge         tp, t5, 1243f
                  c.beqz      a5, 1234f
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  orn   x31, x30, x31
                  c.addi4spn  s1, sp, 64
                  c.mv        t2, ra
                  c.andi      a3, 21
                  blt         s4, t1, 1245f
1234:             or          s6, s8, t2
                  divu        zero, s11, ra
                  sltu        s11, t1, t4
1237:             slli        s9, t2, 10
                  xori        tp, s2, -42
                  c.bnez      a3, 1244f
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  xnor  x31, x30, x31
                  csrw mscratch, ra
                  c.jal 811291f
811291:            jal  ra, 811292f
811292:            jal  ra, 811293f
811293:            la   ra, 811294f
                  jalr x0, 0(ra)
811294:            csrr ra, mscratch
                  c.nop
                  slli        tp, s10, 23
                  mul         a5, s3, s8
1243:             slti        s6, t4, -1328
1244:             mul         zero, zero, s2
1245:             or          s9, t5, s0
                  andi        a0, a7, -108
                  mulhsu      s9, a3, t1
                  div         zero, t3, a0
                  sll         s11, a2, a6
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  clz   x31, x30
                  c.srai      a3, 18
                  srli        t1, gp, 29
                  sltu        a6, a1, s5
                  c.andi      a3, 20
                  c.addi      sp, 14
                  c.slli      a4, 31
                  c.li        s3, -1
                  c.mv        ra, a6
                  bgeu        t3, s9, 1264f
                  srai        s4, t2, 8
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  ctz   x31, x30
                  slt         s10, t1, a4
                  c.srai      a3, 16
                  srai        tp, a3, 11
                  or          tp, s1, a7
1264:             c.addi16sp  sp, 400
                  sll         t2, a0, s4
                  divu        t2, t1, gp
                  mulh        t0, t5, gp
                  div         s11, a4, t3
                  bltu        s7, s3, 1273f
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  cpop  x31, x30
                  c.add       s1, t0
                  c.srli      a3, 2
                  sra         a4, s2, t3
1273:             srl         s10, s6, t0
                  add         a7, a4, a6
                  sltu        s0, sp, a7
                  auipc       sp, 888972
                  c.bnez      a3, 1285f
                  sll         t0, tp, a0
                  sra         a2, gp, t3
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  min   x31, x30, x31
                  bgeu        a2, t2, 1299f
                  nop
                  c.srli      a1, 10
                  c.andi      a3, 14
                  c.slli      a2, 24
1285:             c.li        s5, 27
                  beq         a4, s10, 1291f
                  addi        t3, s8, -1926
                  c.srli      a0, 17
                  mul         s5, a5, s7
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  minu  x31, x30, x31
                  li   x30, 0x80000000
                  li   x31, -1
                  div  x31, x30, x31
                  rem  x31, x30, x30
                  li   x31, 0
                  divu x31, x30, x31
                  li   x31, 0
                  rem  x31, x30, x31
                  mul         a0, a0, a7
1291:             div         t3, s1, t3
                  c.nop
                  andi        s3, t0, -1833
                  c.or        a2, s0
                  sub         gp, s1, s7
                  c.nop
                  beq         a2, zero, 1299f
                  srai        a0, sp, 12
1299:             auipc       a6, 856539
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  max   x31, x30, x31
                  slli        s5, s4, 28
                  sra         s2, a4, t4
                  c.addi16sp  sp, 432
                  divu        a5, s4, t1
                  c.xor       s0, a1
                  c.srli      a3, 12
                  auipc       t1, 416428
                  c.srai      a5, 12
                  c.xor       a3, a5
                  c.addi4spn  a3, sp, 192
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  maxu  x31, x30, x31
                  ori         s7, s7, -104
                  add         s2, gp, t6
                  auipc       s11, 556052
                  srl         s3, t4, t6
                  mulhsu      sp, s9, s0
                  bne         s0, a2, 1325f
                  mulhsu      s3, a6, t3
                  andi        s7, s5, -245
                  bgeu        s5, sp, 1319f
1319:             c.beqz      a3, 1338f
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  sext.b x31, x30
                  c.nop
                  divu        s4, a5, a4
                  mulhsu      s0, s11, s10
                  c.or        a3, a3
                  rem         zero, a3, t2
1325:             lui         t3, 263
                  lui         a4, 289761
                  bltu        a5, s9, 1333f
                  mulhsu      s5, tp, s10
                  auipc       a4, 716159
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  sext.h x31, x30
                  c.srai      a3, 16
                  lui         a2, 909061
                  nop
1333:             beq         t2, sp, 1348f
                  c.srli      a2, 24
                  divu        zero, a4, s1
                  addi        s5, s5, -852
                  mul         a4, s7, a6
1338:             c.beqz      a3, 1349f
                  rem         a2, t6, s0
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  zext.h x31, x30
                  csrw mscratch, x30
                  csrrs x31, mscratch, x0
                  csrrc x31, mscratch, x0
                  c.srai      a3, 13
                  divu        zero, a7, t0
                  nop
                  and         s9, t4, a1
                  c.and       a3, a3
                  c.srai      a1, 17
                  add         s5, s8, zero
                  mulhu       zero, zero, tp
1348:             and         zero, zero, s1
1349:             xori        t0, t4, 565
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  rol   x31, x30, x31
                  c.nop
                  and         sp, s7, a2
                  c.addi16sp  sp, 400
                  lui         s6, 769536
                  srl         s8, a2, s1
                  blt         s7, s11, 1373f
                  c.bnez      a3, 1358f
                  sll         gp, t0, a6
1358:             c.lui       s6, 29
                  divu        a3, a6, a7
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  ror   x31, x30, x31
                  csrw mscratch, ra
                  jal  ra, 821411f
                  jalr x0, 0(ra)     # wrong-path ret: IF pre-decode pop
821411:          csrr ra, mscratch
                  srai        a6, a3, 13
                  lui         a3, 551401
                  lui         s9, 1021783
                  bge         s8, s3, 1377f
                  xori        t1, ra, 1060
                  srli        s5, t1, 6
                  c.srai      a3, 12
                  bltu        s6, s9, 1380f
                  srai        s2, sp, 26
                  ori         a1, s4, -1068
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  rori  x31, x30, 7
                  c.sub       a3, a3
                  c.and       a4, a3
                  bge         s4, t1, 1376f
1373:             c.addi16sp  sp, -16
                  bltu        sp, s9, 1376f
                  and         sp, a0, s3
1376:             c.lui       ra, 7
1377:             c.and       a3, a2
                  bltu        t1, s10, 1395f
                  nop
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  orc.b x31, x30
1380:             c.addi      sp, 22
                  mulh        a3, ra, a7
                  mulh        ra, ra, a1
                  blt         tp, gp, 1390f
                  srai        t0, a1, 6
                  c.srli      a3, 9
                  srli        t2, a1, 9
                  ori         s8, zero, -1673
                  xor         a6, a0, s6
                  c.mv        s3, t0
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  rev8  x31, x30
                  csrw mscratch, x8
                  la   x8, zbcov_scratch
                  sw   x9, 0(x8)
                  sw   sp, 4(x8)
                  addi sp, x8, 8
                  c.swsp x31, 0(sp)
                  c.lwsp x30, 0(sp)
                  sw   x31, 8(x8)
                  c.lw  x9, 8(x8)
                  c.sw  x9, 8(x8)
                  lw   sp, 4(x8)
                  lw   x9, 0(x8)
                  csrr x8, mscratch
1390:             srai        s10, t2, 15
                  lui         s11, 605308
                  xori        tp, t2, 1362
                  mulhsu      s3, t3, a7
                  c.bnez      a3, 1405f
1395:             or          s7, s7, s10
                  srli        s2, t2, 29
                  mulhsu      s7, a4, ra
                  mulhsu      gp, a1, a6
                  sltiu       t0, t6, 1254
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  bclr  x31, x30, x31
                  c.li        s6, 20
                  c.srai      a3, 31
                  bge         s5, a7, 1408f
                  srl         s3, a6, a5
                  mulh        s4, a7, s1
1405:             slli        s4, a4, 24
                  or          s5, s11, s7
                  c.mv        ra, t5
1408:             divu        s1, a5, s10
                  mulhu       s1, a6, t5
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  bext  x31, x30, x31
                  c.or        a0, a3
                  slt         s2, a0, s11
                  c.addi      s1, 26
                  ori         t0, a0, 1655
                  sub         a0, s5, a0
                  c.nop
                  srli        tp, s2, 27
                  c.mv        s0, sp
                  c.srai      a0, 28
                  srai        s4, ra, 27
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  binv  x31, x30, x31
                  bge         a0, a6, 1430f
                  bltu        t3, a1, 1423f
                  c.nop
1423:             lui         gp, 755014
                  c.addi16sp  sp, -16
                  or          s5, s3, s9
                  c.srli      a3, 29
                  c.lui       s3, 9
                  slti        tp, s4, 1795
                  sltu        s0, s11, a2
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  bset  x31, x30, x31
1430:             beq         t0, zero, 1432f
                  c.addi      ra, -1
1432:             c.beqz      a3, 1437f
                  addi        a6, a4, 168
                  nop
                  c.xor       a3, a3
                  c.lui       t2, 7
1437:             mulh        s7, t6, s5
                  c.addi      s7, -1
                  c.addi      t1, -1
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  bclri x31, x30, 31
                  csrw mscratch, ra
                  c.jal 811491f
811491:            jal  ra, 811492f
811492:            jal  ra, 811493f
811493:            la   ra, 811494f
                  jalr x0, 0(ra)
811494:            csrr ra, mscratch
                  c.and       a3, s0
                  bne         t1, a1, 1460f
                  c.slli      ra, 6
                  c.xor       a3, a3
                  sltu        s10, s0, t6
                  c.bnez      a3, 1459f
                  xori        zero, a1, -1723
                  auipc       s11, 592020
                  srl         gp, t0, s5
                  c.addi      s11, -1
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  bexti x31, x30, 15
                  nop
                  and         s9, tp, s9
                  andi        s4, a5, 1271
                  c.and       a2, s1
                  c.add       ra, t1
                  nop
                  rem         sp, t2, s9
                  bge         zero, t3, 1464f
                  c.beqz      a3, 1468f
1459:             divu        zero, s1, s8
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  binvi x31, x30, 0
1460:             srl         a2, a6, s10
                  rem         a3, t4, s0
                  c.or        a3, a0
                  c.srli      a1, 16
1464:             c.srli      a3, 16
                  c.mv        s9, s3
                  c.srli      a3, 21
                  xor         zero, a7, a3
1468:             c.slli      s1, 1
                  slti        s5, sp, 1687
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  bseti x31, x30, 31
                  mul         s6, s7, s7
                  c.bnez      a5, 1490f
                  c.add       s0, t1
                  sub         s2, ra, t6
                  sll         s10, t1, a6
                  sltu        sp, s1, s11
                  sra         sp, a7, a6
                  c.andi      a2, -1
                  slt         sp, gp, t5
                  c.add       tp, t5
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  czero.eqz x31, x30, x31
                  slti        t0, t2, 972
                  c.andi      a3, 29
                  slt         zero, t4, a2
                  bne         s6, a4, 1491f
                  ori         t1, s3, 602
                  nop
                  sltiu       t2, t2, -43
                  slti        ra, zero, -1462
                  or          s0, a4, s8
                  c.and       a3, a3
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  czero.nez x31, x30, x31
                  li   x30, 0x80000000
                  li   x31, -1
                  div  x31, x30, x31
                  rem  x31, x30, x30
                  li   x31, 0
                  divu x31, x30, x31
                  li   x31, 0
                  rem  x31, x30, x31
1490:             mulhsu      ra, a5, t5
1491:             mul         t3, s5, tp
                  bltu        a3, gp, 1498f
                  add         a4, s3, a2
                  c.li        s8, 30
                  or          a2, a7, a5
                  mul         a0, t5, a1
                  addi        a4, s0, 1724
1498:             sub         a5, s11, a7
                  addi        a6, t1, 618
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  sh1add x31, x30, x31
                  nop
                  mulhu       zero, t0, a2
                  sltu        a4, a5, t5
                  c.addi16sp  sp, 256
                  c.sub       a1, a3
                  c.nop
                  slli        tp, a2, 20
                  c.or        a3, a3
                  and         a6, s10, s5
                  c.mv        s10, s1
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  sh2add x31, x30, x31
                  c.li        s5, -1
                  c.beqz      a2, 1522f
                  srl         a4, t1, ra
                  c.slli      s7, 24
                  slli        a1, s11, 19
                  c.andi      a3, -1
                  lui         zero, 114371
                  c.nop
                  c.or        a3, s0
                  xor         zero, tp, s10
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  sh3add x31, x30, x31
                  csrw mscratch, ra
                  jal  ra, 821571f
                  jalr x0, 0(ra)     # wrong-path ret: IF pre-decode pop
821571:          csrr ra, mscratch
                  sll         s6, t6, t6
                  mulhsu      s0, a3, s6
1522:             srli        t0, t1, 27
                  c.addi4spn  a3, sp, 384
                  slli        t2, tp, 8
                  c.addi16sp  sp, 176
                  c.and       a3, a3
                  div         tp, t2, s2
                  addi        a6, s3, 1445
                  addi        a5, t4, -736
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  andn  x31, x30, x31
                  xori        a4, zero, -94
                  bltu        t6, s9, 1535f
                  c.andi      a3, -1
                  srli        s11, t1, 6
                  c.bnez      a3, 1545f
1535:             sub         s3, a1, t1
                  srl         a2, gp, a0
                  c.bnez      a3, 1543f
                  blt         s6, s10, 1539f
1539:             c.addi      ra, 26
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  orn   x31, x30, x31
                  csrw mscratch, x30
                  csrrs x31, mscratch, x0
                  csrrc x31, mscratch, x0
                  c.and       a3, s0
                  xori        s5, t0, 1877
                  c.and       a0, a3
1543:             c.and       a3, a3
                  c.srli      a3, 18
1545:             sll         a5, t6, zero
                  sub         a0, a3, s5
                  sltu        s8, s8, t1
                  bne         ra, a6, 1560f
                  andi        zero, ra, -759
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  xnor  x31, x30, x31
                  c.lui       s9, 1
                  c.or        a3, a3
                  div         s9, s11, s8
                  c.and       a3, s1
                  or          s3, a0, s7
                  divu        t0, s6, s11
                  srl         s0, a0, a7
                  c.xor       a3, a3
                  c.andi      a5, 26
                  auipc       a7, 215961
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  clz   x31, x30
1560:             or          zero, s11, t6
                  bne         s8, a1, 1563f
                  bge         s2, s3, 1575f
1563:             mulhsu      a1, tp, a6
                  blt         t4, s9, 1568f
                  c.srli      a3, 30
                  andi        zero, s6, 837
                  xor         s1, gp, s4
1568:             auipc       s5, 552410
                  sub         s0, s6, a5
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  ctz   x31, x30
                  nop
                  sra         a3, s7, t6
                  sra         zero, a2, a5
                  c.srli      a3, 19
                  bltu        t5, t5, 1589f
1575:             mulh        s4, t0, a4
                  sll         a4, s2, a3
                  c.slli      s10, 18
                  slli        s5, ra, 15
                  c.andi      a3, -1
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  cpop  x31, x30
                  c.or        a0, s0
                  xori        s3, zero, 1693
                  lui         t0, 669774
                  ori         t3, a2, -645
                  c.lui       ra, 21
                  srl         t2, zero, s2
                  add         a6, s5, s3
                  sra         ra, gp, a0
                  rem         s7, s0, s3
1589:             bne         s3, s0, 1594f
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  min   x31, x30, x31
                  csrw mscratch, x8
                  la   x8, zbcov_scratch
                  sw   x9, 0(x8)
                  sw   sp, 4(x8)
                  addi sp, x8, 8
                  c.swsp x31, 0(sp)
                  c.lwsp x30, 0(sp)
                  sw   x31, 8(x8)
                  c.lw  x9, 8(x8)
                  c.sw  x9, 8(x8)
                  lw   sp, 4(x8)
                  lw   x9, 0(x8)
                  csrr x8, mscratch
                  c.nop
                  slti        sp, a2, 542
                  auipc       a7, 721292
                  sltiu       a6, a4, -498
1594:             c.sub       a3, a3
                  mulhsu      a1, sp, t6
                  and         zero, a2, s6
                  divu        sp, s9, t3
                  lui         gp, 1028902
                  sltu        ra, sp, t1
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  minu  x31, x30, x31
                  c.nop
                  mul         s8, s0, zero
                  bltu        t0, t4, 1603f
1603:             c.xor       a3, a3
                  c.srai      a2, 6
                  bgeu        a0, a3, 1616f
                  c.addi16sp  sp, -16
                  mul         s10, a5, s6
                  c.srli      s1, 8
                  div         zero, zero, s0
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  max   x31, x30, x31
                  c.addi      s9, 16
                  c.srai      a3, 3
                  xori        a1, a6, 1826
                  and         a1, a4, s6
                  c.addi16sp  sp, 336
                  c.bnez      a3, 1634f
1616:             div         a1, zero, s2
                  bgeu        ra, t4, 1632f
                  slli        a5, a7, 19
                  srl         a4, t2, t0
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  maxu  x31, x30, x31
                  and         zero, s4, a4
                  auipc       s2, 268706
                  bltu        t3, s7, 1639f
                  lui         s7, 264908
                  and         a2, a4, a2
                  sltiu       sp, a2, 1180
                  blt         sp, t4, 1644f
                  sltu        t2, s3, s9
                  div         s3, ra, s8
                  c.addi      t3, -1
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  sext.b x31, x30
                  c.mv        ra, s8
                  sltiu       zero, s3, 1598
1632:             c.add       a5, s6
                  or          zero, tp, a4
1634:             sra         a5, zero, t1
                  rem         s1, a5, t6
                  mul         t0, t2, t6
                  slt         s4, a3, a6
                  sltu        t0, a3, a5
1639:             c.addi4spn  a3, sp, 784
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  sext.h x31, x30
                  csrw mscratch, ra
                  c.jal 811691f
811691:            jal  ra, 811692f
811692:            jal  ra, 811693f
811693:            la   ra, 811694f
                  jalr x0, 0(ra)
811694:            csrr ra, mscratch
                  c.beqz      a0, 1645f
                  auipc       t1, 129653
                  c.srai      a3, 19
                  c.addi16sp  sp, 128
1644:             srli        s4, s5, 11
1645:             nop
                  c.or        a3, a3
                  sll         t0, s9, a7
                  c.slli      ra, 24
                  bne         t1, t5, 1653f
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  zext.h x31, x30
                  or          t2, zero, ra
                  c.nop
                  xori        s10, s3, 1526
1653:             sll         a1, t1, gp
                  mulhsu      s10, sp, sp
                  c.bnez      a3, 1666f
                  bgeu        t6, t0, 1664f
                  srai        a0, s6, 9
                  nop
                  mulhu       a0, ra, s2
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  rol   x31, x30, x31
                  c.li        a7, 24
                  c.mv        s11, t3
                  ori         s11, s1, 327
                  bge         t3, s2, 1673f
1664:             blt         a0, a3, 1677f
                  bge         s8, s2, 1684f
1666:             xori        zero, a2, -1006
                  bne         t1, s8, 1682f
                  addi        a7, a7, 283
                  slti        a6, t2, -614
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  ror   x31, x30, x31
                  nop
                  c.li        s4, 20
                  xori        s2, s0, 282
1673:             slti        s4, zero, 1866
                  andi        s1, tp, 979
                  and         zero, sp, t4
                  beq         t1, s3, 1690f
1677:             c.and       a3, a3
                  lui         a7, 521804
                  sra         a3, s1, tp
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  rori  x31, x30, 7
                  csrw mscratch, ra
                  jal  ra, 821731f
                  jalr x0, 0(ra)     # wrong-path ret: IF pre-decode pop
821731:          csrr ra, mscratch
                  sltu        a0, t1, s8
                  divu        a0, a5, a1
1682:             c.xor       a3, a3
                  c.li        s11, -1
1684:             bgeu        t0, t6, 1703f
                  sll         ra, t2, a2
                  srai        s0, t4, 31
                  beq         t5, s10, 1705f
                  c.lui       s3, 16
                  c.or        a3, s1
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  orc.b x31, x30
                  li   x30, 0x80000000
                  li   x31, -1
                  div  x31, x30, x31
                  rem  x31, x30, x30
                  li   x31, 0
                  divu x31, x30, x31
                  li   x31, 0
                  rem  x31, x30, x31
1690:             beq         s7, t5, 1696f
                  sll         a4, a3, a7
                  xor         a2, a3, s6
                  or          s10, tp, s7
                  andi        sp, t1, 862
                  lui         s5, 497989
1696:             sub         s5, s3, s11
                  srl         a3, zero, t0
                  sltu        zero, t5, s8
                  divu        a4, t5, t0
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  rev8  x31, x30
                  c.slli      a0, 7
                  c.addi4spn  a5, sp, 704
                  sub         a6, zero, a3
1703:             or          zero, a7, s3
                  sra         tp, a1, s6
1705:             srl         s1, t4, t2
                  lui         t2, 819033
                  beq         a5, s10, 1718f
                  c.xor       a3, a3
                  mul         s4, s3, a2
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  bclr  x31, x30, x31
                  bne         t0, s4, 1716f
                  c.sub       a3, a3
                  and         s6, zero, a2
                  c.sub       a1, a1
                  c.slli      a3, 22
                  c.mv        s10, gp
1716:             c.nop
                  sltiu       zero, a6, -1210
1718:             c.beqz      a0, 1730f
                  c.addi4spn  a3, sp, 640
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  bext  x31, x30, x31
                  slti        s9, s11, -374
                  sra         s4, t1, s0
                  c.nop
                  c.and       a3, a3
                  mul         t0, s3, tp
                  auipc       zero, 912366
                  c.srai      a3, 24
                  slli        s3, t0, 9
                  mulh        s9, zero, a0
                  sll         s2, sp, s2
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  binv  x31, x30, x31
1730:             blt         t0, ra, 1745f
                  srl         t2, t6, t1
                  mulhu       s7, t0, s3
                  slt         t2, s5, s0
                  nop
                  c.li        sp, 12
                  or          zero, s1, t6
                  auipc       a2, 277875
                  bltu        t2, t5, 1743f
                  c.addi4spn  a3, sp, 896
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  bset  x31, x30, x31
                  csrw mscratch, x30
                  csrrs x31, mscratch, x0
                  csrrc x31, mscratch, x0
                  mulhsu      a3, s1, s4
                  or          s11, a6, t3
                  slt         s10, a1, sp
1743:             c.srli      a3, 5
                  srl         zero, a3, t6
1745:             ori         zero, a5, 356
                  mul         a3, s10, zero
                  sltiu       a0, gp, -224
                  add         zero, s8, a5
                  beq         s1, t4, 1751f
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  bclri x31, x30, 31
                  srai        t3, s9, 21
1751:             sltiu       sp, s11, 1135
                  blt         a2, s8, 1758f
                  mul         t3, t4, s8
                  andi        t1, sp, 880
                  c.add       s10, s6
                  auipc       gp, 963435
                  c.sub       a3, a3
1758:             and         t3, s5, tp
                  srli        s8, s9, 4
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  bexti x31, x30, 15
                  c.slli      a6, 9
                  bgeu        t1, s8, 1780f
                  sltiu       s2, s8, -702
                  c.slli      a5, 16
                  c.or        a3, s1
                  c.srli      a5, 27
                  srai        s3, s4, 6
                  c.sub       a3, a3
                  c.lui       s9, 18
                  mulh        s4, s10, s2
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  binvi x31, x30, 0
                  auipc       a7, 851507
                  c.addi16sp  sp, 336
                  mul         tp, sp, s8
                  c.bnez      a3, 1775f
                  c.addi16sp  sp, -16
1775:             beq         s5, tp, 1779f
                  bgeu        s1, s9, 1778f
                  slli        s2, s9, 23
1778:             bgeu        ra, t5, 1785f
1779:             c.addi4spn  a3, sp, 448
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  bseti x31, x30, 31
1780:             mulhsu      s6, t0, zero
                  srl         a0, s11, a5
                  bltu        s8, s6, 1793f
                  bne         s8, s3, 1784f
1784:             c.lui       t2, 12
1785:             mulh        a3, s9, t3
                  auipc       t3, 57918
                  c.lui       s10, 9
                  sub         s5, s4, t0
                  c.li        s6, 13
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  czero.eqz x31, x30, x31
                  csrw mscratch, x8
                  la   x8, zbcov_scratch
                  sw   x9, 0(x8)
                  sw   sp, 4(x8)
                  addi sp, x8, 8
                  c.swsp x31, 0(sp)
                  c.lwsp x30, 0(sp)
                  sw   x31, 8(x8)
                  c.lw  x9, 8(x8)
                  c.sw  x9, 8(x8)
                  lw   sp, 4(x8)
                  lw   x9, 0(x8)
                  csrr x8, mscratch
                  ori         a5, s9, 1910
                  c.addi      t3, 24
                  c.add       s4, sp
1793:             bne         s0, a2, 1810f
                  or          zero, a7, t5
                  bne         sp, ra, 1805f
                  c.srli      a3, 24
                  lui         t1, 259050
                  c.addi16sp  sp, 112
                  srl         s0, s11, t5
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  czero.nez x31, x30, x31
                  auipc       s5, 41283
                  sub         a3, ra, s4
                  sub         a3, t4, s10
                  slti        s2, s5, 1234
                  bgeu        t2, s6, 1809f
1805:             srai        a5, s5, 7
                  c.bnez      a5, 1811f
                  slli        s3, t4, 28
                  c.mv        s7, a4
1809:             and         t2, s6, a4
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  sh1add x31, x30, x31
1810:             c.lui       ra, 4
1811:             c.and       a3, a3
                  blt         s0, s6, 1813f
1813:             c.beqz      a2, 1831f
                  slti        zero, a5, -351
                  beq         a7, s1, 1830f
                  c.mv        ra, s1
                  divu        s4, s1, a6
                  srai        gp, s11, 2
                  sltiu       a5, s0, 162
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  sh2add x31, x30, x31
                  c.slli      ra, 21
                  and         s5, a0, t4
                  and         s7, s9, t0
                  auipc       s6, 115573
                  c.addi16sp  sp, -16
                  addi        t1, zero, 1270
                  lui         s5, 638629
                  slli        s7, t4, 3
                  mulh        zero, sp, t1
                  mulhsu      s6, t3, t6
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  sh3add x31, x30, x31
1830:             auipc       s11, 552498
1831:             c.beqz      a1, 1845f
                  srl         s8, s10, s1
                  c.addi4spn  a0, sp, 64
                  c.lui       a4, 26
                  c.beqz      a3, 1836f
1836:             c.li        s3, -1
                  mulhu       a5, a3, a3
                  sltu        tp, s7, a5
                  c.lui       s2, 16
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  andn  x31, x30, x31
                  csrw mscratch, ra
                  jal  ra, 821891f
                  jalr x0, 0(ra)     # wrong-path ret: IF pre-decode pop
821891:          csrr ra, mscratch
                  csrw mscratch, ra
                  c.jal 811891f
811891:            jal  ra, 811892f
811892:            jal  ra, 811893f
811893:            la   ra, 811894f
                  jalr x0, 0(ra)
811894:            csrr ra, mscratch
                  c.addi      a1, 8
                  srai        a6, s3, 1
                  slt         s6, s5, a6
                  sub         sp, sp, s3
                  bgeu        ra, t5, 1850f
1845:             sub         t0, s10, a1
                  c.andi      a5, -1
                  c.nop
                  auipc       s0, 401041
                  c.or        a3, s0
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  orn   x31, x30, x31
1850:             c.sub       a3, a2
                  slli        t2, sp, 27
                  slt         s2, t5, a0
                  mulh        s6, tp, s9
                  rem         t3, a5, t3
                  slt         s2, a5, t6
                  srai        a2, t0, 11
                  ori         a3, s1, 701
                  srai        zero, ra, 3
                  mul         a0, a0, t5
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  xnor  x31, x30, x31
                  and         zero, sp, t0
                  divu        s10, a3, s5
                  beq         t5, t4, 1863f
1863:             sll         a6, s10, s10
                  nop
                  auipc       gp, 520864
                  c.andi      a4, -1
                  sra         zero, a7, t0
                  nop
                  slti        s6, t3, 395
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  clz   x31, x30
                  nop
                  c.sub       a3, s0
                  addi        s2, s3, -1496
                  c.beqz      a3, 1877f
                  auipc       a2, 83771
                  mulhu       s11, t1, a2
                  nop
1877:             c.mv        a5, s0
                  sll         t2, a2, a7
                  rem         t1, s11, a3
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  ctz   x31, x30
                  srl         t3, t4, s6
                  mulhu       t0, tp, tp
                  c.xor       a3, a3
                  c.addi16sp  sp, 96
                  sra         a0, sp, s8
                  mulhsu      zero, s3, s0
                  c.nop
                  sub         s2, a6, s10
                  bgeu        s1, a0, 1890f
                  bltu        a7, s4, 1897f
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  cpop  x31, x30
                  li   x30, 0x80000000
                  li   x31, -1
                  div  x31, x30, x31
                  rem  x31, x30, x30
                  li   x31, 0
                  divu x31, x30, x31
                  li   x31, 0
                  rem  x31, x30, x31
1890:             c.addi4spn  a3, sp, 960
                  slt         s9, t0, a5
                  bgeu        s10, a4, 1911f
                  c.slli      ra, 24
                  c.lui       t1, 6
                  c.srai      a3, 2
                  xori        a1, s7, -262
1897:             div         ra, t2, a6
                  srai        sp, s3, 1
                  auipc       t1, 329844
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  min   x31, x30, x31
                  xori        s11, a6, -76
                  c.slli      ra, 12
                  c.bnez      a3, 1904f
                  c.or        a3, a3
1904:             c.sub       a3, a3
                  c.addi      s8, -1
                  c.srai      s0, 5
                  sltu        zero, ra, a1
                  sra         zero, zero, s1
                  xor         a5, s10, tp
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  minu  x31, x30, x31
                  bne         zero, a3, 1920f
1911:             c.lui       ra, 11
                  c.or        a3, a3
                  c.andi      a3, -1
                  ori         a6, t2, -1605
                  mulh        a7, t1, t3
                  mulhu       s10, s11, a2
                  c.srai      a3, 4
                  c.and       a3, a3
                  c.andi      a3, 11
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  max   x31, x30, x31
1920:             c.add       s3, t0
                  auipc       a0, 942588
                  c.nop
                  c.or        a3, s1
                  c.or        a3, a2
                  addi        s7, t5, 1419
                  srl         t3, t1, s11
                  beq         s5, s2, 1934f
                  c.andi      a3, -1
                  c.sub       a2, a3
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  maxu  x31, x30, x31
                  andi        s7, s10, -458
                  c.lui       ra, 17
                  c.xor       a0, a3
                  or          s5, a0, gp
1934:             div         s7, zero, s8
                  c.lui       s0, 19
                  srai        s0, s1, 16
                  c.addi4spn  a3, sp, 832
                  mulhu       t1, ra, a4
                  xor         s1, a6, s1
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  sext.b x31, x30
                  csrw mscratch, x30
                  csrrs x31, mscratch, x0
                  csrrc x31, mscratch, x0
                  bgeu        a3, s9, 1945f
                  addi        a2, s4, 873
                  c.mv        a7, s1
                  c.addi4spn  a3, sp, 832
                  sltu        t0, zero, sp
1945:             slli        t3, t0, 0
                  c.srai      a3, 22
                  xor         s0, t1, a0
                  rem         a3, s3, s4
                  auipc       sp, 405605
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  sext.h x31, x30
                  andi        s10, s3, -1433
                  c.srli      a3, 5
                  slli        t2, tp, 29
                  lui         zero, 935931
                  c.beqz      a3, 1959f
                  ori         gp, tp, 1042
                  div         a3, s1, s1
                  c.addi16sp  sp, -16
                  sub         s10, zero, a5
1959:             c.srli      a3, 1
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  zext.h x31, x30
                  sltiu       a3, sp, 621
                  slli        a5, s9, 24
                  srl         s3, s2, t2
                  slli        s6, t3, 7
                  slt         a5, a2, s8
                  mulhu       a3, gp, t3
                  rem         s4, s5, t2
                  sltiu       a2, s1, 1718
                  c.bnez      a3, 1970f
                  xori        s9, s7, 1906
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  rol   x31, x30, x31
1970:             rem         t2, t0, t2
                  c.sub       a3, s0
                  c.addi16sp  sp, 96
                  bne         a0, ra, 1985f
                  c.mv        a4, s2
                  andi        s3, s8, -1144
                  bltu        s7, s4, 1991f
                  c.sub       a3, a3
                  c.srai      a3, 13
                  srli        a7, a5, 11
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  ror   x31, x30, x31
                  bgeu        ra, t3, 1997f
                  c.andi      a4, 4
                  c.mv        a0, s11
                  c.and       a2, a3
                  slti        s5, a0, -528
1985:             c.addi16sp  sp, -16
                  sltiu       s11, ra, 1644
                  sra         a4, t6, gp
                  mulhu       s7, t2, s1
                  bne         t1, s1, 1993f
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  rori  x31, x30, 7
                  csrw mscratch, x8
                  la   x8, zbcov_scratch
                  sw   x9, 0(x8)
                  sw   sp, 4(x8)
                  addi sp, x8, 8
                  c.swsp x31, 0(sp)
                  c.lwsp x30, 0(sp)
                  sw   x31, 8(x8)
                  c.lw  x9, 8(x8)
                  c.sw  x9, 8(x8)
                  lw   sp, 4(x8)
                  lw   x9, 0(x8)
                  csrr x8, mscratch
                  bltu        a1, zero, 2009f
1991:             and         s0, s1, s2
                  c.mv        s1, t1
1993:             srli        s0, s5, 11
                  c.xor       a3, a3
                  c.mv        s8, t0
                  c.bnez      a2, 2009f
1997:             srl         s8, a0, t2
                  srli        zero, t2, 0
                  bge         tp, t3, 2005f
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  orc.b x31, x30
                  csrw mscratch, ra
                  jal  ra, 822051f
                  jalr x0, 0(ra)     # wrong-path ret: IF pre-decode pop
822051:          csrr ra, mscratch
                  nop
                  c.xor       a3, a3
                  c.addi      ra, -1
                  c.bnez      a1, 2013f
                  slt         zero, s2, t1
2005:             bgeu        gp, t0, 2011f
                  rem         zero, s11, a6
                  c.slli      t1, 21
                  c.sub       a3, s0
2009:             mulhu       zero, s6, ra
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  rev8  x31, x30
                  c.beqz      a3, 2021f
2011:             auipc       sp, 567612
                  sub         s3, t1, a3
2013:             c.bnez      a1, 2018f
                  mulhsu      s0, a7, a3
                  xori        a5, a3, -1973
                  c.srli      a3, 31
                  sra         t3, a3, gp
2018:             or          a4, a3, t3
                  srli        t0, zero, 9
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  bclr  x31, x30, x31
                  rem         a5, s9, zero
2021:             addi        a7, t3, 587
                  mulhu       t0, s6, ra
                  blt         tp, s3, 2034f
                  c.andi      a3, 19
                  srl         a6, s7, t1
                  xori        s0, a6, 564
                  sll         s3, s3, s0
                  c.srli      a3, 2
                  bge         t3, t4, 2048f
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  bext  x31, x30, x31
                  c.addi      s2, 7
                  srai        t0, ra, 17
                  div         s2, s7, s9
                  mulhu       s5, a1, t1
2034:             beq         s6, a6, 2045f
                  nop
                  c.nop
                  ori         s8, t3, -1887
                  bge         tp, t0, 2049f
                  c.andi      a3, -1
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  binv  x31, x30, x31
                  csrw mscratch, ra
                  c.jal 812091f
812091:            jal  ra, 812092f
812092:            jal  ra, 812093f
812093:            la   ra, 812094f
                  jalr x0, 0(ra)
812094:            csrr ra, mscratch
                  mulhu       zero, zero, a0
                  c.srai      a3, 8
                  c.addi4spn  s0, sp, 896
                  bge         s3, s9, 2048f
                  c.addi16sp  sp, -16
2045:             sra         s4, t2, t0
                  sub         s3, s8, t6
                  sll         s4, gp, t0
2048:             div         s1, s4, sp
2049:             sub         tp, t0, zero
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  bset  x31, x30, x31
                  sra         a5, t1, a4
                  xor         s2, s6, a7
                  div         gp, a1, a2
                  lui         t1, 618080
                  c.mv        t2, tp
                  sll         s1, gp, t2
                  sll         t1, t4, a3
                  bge         t1, s3, 2059f
                  andi        a0, s0, -1405
2059:             c.mv        a3, gp
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  bclri x31, x30, 31
                  mulhu       a6, s9, s5
                  c.slli      s6, 16
                  bltu        t5, s3, 2081f
                  c.slli      t3, 12
                  c.andi      a3, 9
                  c.andi      a3, 18
                  c.li        tp, -1
                  bne         s9, s9, 2082f
                  c.nop
                  c.or        a3, s1
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  bexti x31, x30, 15
                  c.addi16sp  sp, -16
                  c.slli      s3, 21
                  c.add       t1, s9
                  mulh        a3, a3, a7
                  divu        a5, s5, s0
                  xor         s6, s1, t2
                  c.srli      a3, 27
                  c.add       ra, a6
                  divu        s6, s9, s5
                  c.or        a3, a3
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  binvi x31, x30, 0
                  bge         a1, a0, 2090f
2081:             c.addi      ra, 15
2082:             blt         s5, s9, 2097f
                  mulh        tp, t1, t1
                  or          s9, s7, s6
                  mulhu       a0, s7, gp
                  lui         s10, 823897
                  bge         a3, a6, 2099f
                  c.beqz      a5, 2099f
                  c.addi4spn  a3, sp, 16
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  bseti x31, x30, 31
                  li   x30, 0x80000000
                  li   x31, -1
                  div  x31, x30, x31
                  rem  x31, x30, x30
                  li   x31, 0
                  divu x31, x30, x31
                  li   x31, 0
                  rem  x31, x30, x31
2090:             slt         a6, zero, a5
                  c.andi      a3, -1
                  c.add       s5, t3
                  c.slli      s4, 13
                  slti        a7, s8, -1970
                  c.andi      a3, -1
                  and         gp, s3, a0
2097:             c.and       a3, a3
                  c.sub       s0, s1
2099:             srli        a3, tp, 11
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  czero.eqz x31, x30, x31
                  bgeu        a6, t4, 2105f
                  c.mv        a7, tp
                  c.or        a3, a3
                  c.or        a3, a1
                  srai        zero, s8, 28
2105:             auipc       s11, 670842
                  xori        a7, t6, 1938
                  c.lui       ra, 27
                  mulhsu      sp, t4, s9
                  add         a6, a7, s7
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  czero.nez x31, x30, x31
                  srai        s6, s0, 5
                  xor         ra, ra, a5
                  div         t0, a5, s4
                  c.add       t0, s10
                  lui         s6, 328383
                  bne         t6, t5, 2119f
                  bgeu        s0, s6, 2122f
                  sltu        a5, a0, s5
                  c.srai      a3, 27
2119:             mul         s11, a0, t5
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  sh1add x31, x30, x31
                  mulhu       a4, s6, s11
                  mulhsu      s6, a2, t6
2122:             c.xor       a4, a3
                  c.bnez      a3, 2125f
                  c.addi16sp  sp, -16
2125:             c.add       a5, s9
                  c.addi16sp  sp, -16
                  c.slli      t1, 14
                  slti        t2, s2, 521
                  c.add       s8, t3
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  sh2add x31, x30, x31
                  andi        zero, a2, 1617
                  c.or        a3, s0
                  c.sub       a3, a3
                  c.sub       a3, a3
                  sltu        gp, a6, s8
                  sltiu       a1, gp, -1027
                  addi        a5, t1, 980
                  sltu        t1, tp, a7
                  sub         zero, s5, s1
                  srl         s0, s6, zero
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  sh3add x31, x30, x31
                  csrw mscratch, x30
                  csrrs x31, mscratch, x0
                  csrrc x31, mscratch, x0
                  add         sp, s9, sp
                  addi        zero, zero, 810
                  sra         s7, tp, s2
                  c.li        s7, -1
                  rem         s5, tp, a4
                  c.srai      a3, 5
                  bltu        s8, a1, 2151f
                  c.mv        s11, s4
                  sra         zero, a3, s6
                  c.sub       a3, a5
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  andn  x31, x30, x31
                  c.xor       a3, a2
2151:             bge         s5, s9, 2165f
                  c.sub       a3, a3
                  c.srai      a3, 18
                  sra         sp, t1, s1
                  bge         t6, a1, 2168f
                  mulhsu      t0, a6, s8
                  bgeu        a6, s3, 2176f
                  beq         a0, s4, 2168f
                  andi        t0, tp, -797
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  orn   x31, x30, x31
                  csrw mscratch, ra
                  jal  ra, 822211f
                  jalr x0, 0(ra)     # wrong-path ret: IF pre-decode pop
822211:          csrr ra, mscratch
                  c.bnez      a3, 2162f
                  sll         a7, t6, s5
2162:             beq         t4, t2, 2173f
                  and         zero, s11, t4
                  addi        s1, a0, -1952
2165:             srli        t2, s9, 7
                  beq         s7, s6, 2184f
                  c.bnez      a3, 2173f
2168:             sra         s3, s8, gp
                  mulhu       a2, t0, t5
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  xnor  x31, x30, x31
                  srli        a4, s1, 21
                  add         t0, a6, a1
                  bltu        s1, zero, 2176f
2173:             auipc       t1, 122820
                  or          gp, s2, s10
                  c.beqz      a0, 2176f
2176:             c.nop
                  sub         a5, t5, a4
                  srai        ra, s10, 23
                  c.addi      s3, -1
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  clz   x31, x30
                  and         s6, sp, s0
                  c.nop
                  auipc       zero, 181983
                  c.addi4spn  a3, sp, 128
2184:             c.addi      ra, -1
                  c.addi      t1, -1
                  sltiu       a7, s9, -1648
                  rem         a3, t5, a0
                  sll         t2, s9, s2
                  c.li        s2, -1
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  ctz   x31, x30
                  csrw mscratch, x8
                  la   x8, zbcov_scratch
                  sw   x9, 0(x8)
                  sw   sp, 4(x8)
                  addi sp, x8, 8
                  c.swsp x31, 0(sp)
                  c.lwsp x30, 0(sp)
                  sw   x31, 8(x8)
                  c.lw  x9, 8(x8)
                  c.sw  x9, 8(x8)
                  lw   sp, 4(x8)
                  lw   x9, 0(x8)
                  csrr x8, mscratch
                  c.addi16sp  sp, 400
                  blt         a2, a5, 2210f
                  bge         s11, s3, 2198f
                  bge         ra, t5, 2201f
                  c.srai      s1, 8
                  c.xor       a3, a3
                  andi        t2, t4, -40
                  slt         t3, s1, a2
2198:             c.addi16sp  sp, 352
                  c.nop
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  cpop  x31, x30
                  sra         a0, a4, s8
2201:             c.and       s1, a3
                  c.nop
                  blt         t4, s10, 2210f
                  c.mv        a3, gp
                  srl         s1, a3, ra
                  sltu        zero, zero, s7
                  bne         t1, t1, 2208f
2208:             c.or        a1, a3
                  sltiu       zero, t3, -496
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  min   x31, x30, x31
2210:             bne         ra, t2, 2227f
                  ori         a2, a7, -194
                  addi        a2, a4, 723
                  c.srai      a3, 4
                  slli        a3, s10, 7
                  srl         a4, s6, a0
                  slt         a6, s6, s5
                  and         s5, s9, tp
                  c.addi16sp  sp, -16
                  c.addi4spn  a3, sp, 288
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  minu  x31, x30, x31
                  c.lui       s7, 12
                  auipc       t2, 591701
                  addi        a7, s10, -1637
                  c.or        a3, a3
                  bltu        s1, s1, 2238f
                  divu        ra, ra, ra
                  sltiu       a0, s11, 666
2227:             sltu        a4, gp, a2
                  sltu        s0, t4, t1
                  sll         a7, s8, a4
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  max   x31, x30, x31
                  bgeu        s1, t6, 2249f
                  sltu        s0, a3, t6
                  c.mv        s9, t3
                  c.add       s5, a3
                  xori        s8, s11, -1089
                  c.srli      a3, 22
                  xor         zero, s3, s2
                  bge         a0, a4, 2252f
2238:             srl         s4, s10, sp
                  c.mv        t3, s3
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  maxu  x31, x30, x31
                  csrw mscratch, ra
                  c.jal 812291f
812291:            jal  ra, 812292f
812292:            jal  ra, 812293f
812293:            la   ra, 812294f
                  jalr x0, 0(ra)
812294:            csrr ra, mscratch
                  sra         zero, s6, tp
                  srli        a3, a4, 26
                  c.mv        s11, ra
                  sll         s4, t2, sp
                  add         a4, t4, s4
                  divu        s6, s10, t1
                  c.lui       a6, 26
                  c.and       a3, a3
                  srai        s4, zero, 6
2249:             srl         t1, t0, a1
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  sext.b x31, x30
                  c.addi      a0, -1
                  c.beqz      s0, 2256f
2252:             addi        s7, s0, -1598
                  nop
                  c.slli      sp, 24
                  xori        sp, s1, -237
2256:             andi        a4, ra, -708
                  c.or        a3, a3
                  bltu        s5, a7, 2269f
                  slti        s3, s2, -1821
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  sext.h x31, x30
                  c.nop
                  bltu        s8, s5, 2268f
                  bltu        s1, sp, 2279f
                  xori        s9, s11, -1977
                  srai        a5, s5, 10
                  srli        a1, a5, 5
                  c.mv        s5, s6
                  c.mv        s1, a0
2268:             c.li        a3, -1
2269:             c.li        ra, -1
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  zext.h x31, x30
                  nop
                  auipc       zero, 231402
                  andi        s3, zero, 1575
                  mulhsu      s6, s10, s3
                  c.addi      s7, 12
                  bne         s7, a7, 2280f
                  blt         gp, t4, 2286f
                  c.bnez      a3, 2296f
                  c.lui       a7, 4
2279:             andi        s10, s0, -915
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  rol   x31, x30, x31
2280:             c.addi16sp  sp, 48
                  c.slli      s6, 1
                  bltu        s10, s0, 2300f
                  mulh        s5, ra, s6
                  c.or        a3, a3
                  c.or        a3, a3
2286:             c.slli      a4, 7
                  sll         t2, t3, t4
                  or          s6, a6, s2
                  divu        s8, s2, s7
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  ror   x31, x30, x31
                  li   x30, 0x80000000
                  li   x31, -1
                  div  x31, x30, x31
                  rem  x31, x30, x30
                  li   x31, 0
                  divu x31, x30, x31
                  li   x31, 0
                  rem  x31, x30, x31
                  c.addi16sp  sp, -16
                  divu        zero, a7, s6
                  beq         s5, a5, 2300f
                  c.addi16sp  sp, 320
                  sll         s0, t5, a1
                  c.addi4spn  a3, sp, 576
2296:             c.add       t1, ra
                  slli        t1, a0, 13
                  srli        s4, a5, 10
                  c.slli      s7, 20
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  rori  x31, x30, 7
2300:             div         a6, t6, a0
                  blt         s11, s9, 2311f
                  sra         a6, a7, s2
                  c.nop
                  addi        ra, s1, -1641
                  srli        s0, a6, 2
                  c.bnez      a3, 2319f
                  rem         s10, sp, s10
                  slti        a5, t5, -73
                  c.andi      s0, -1
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  orc.b x31, x30
                  mul         s3, sp, s1
2311:             c.slli      s0, 26
                  rem         t3, a4, s8
                  sll         s7, a6, s8
                  c.beqz      a5, 2326f
                  c.srli      a3, 12
                  c.li        s3, 15
                  c.srai      a1, 20
                  ori         s3, zero, 1067
2319:             rem         t1, t0, s6
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  rev8  x31, x30
                  csrw mscratch, ra
                  jal  ra, 822371f
                  jalr x0, 0(ra)     # wrong-path ret: IF pre-decode pop
822371:          csrr ra, mscratch
                  c.add       s6, t1
                  rem         ra, sp, a7
                  mulhsu      a1, t2, t6
                  bge         s10, s8, 2327f
                  rem         zero, a7, a4
                  c.srli      a4, 29
2326:             or          a3, t5, s3
2327:             add         s9, a3, s1
                  sub         a6, t6, t0
                  and         zero, s9, a2
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  bclr  x31, x30, x31
                  bne         t2, sp, 2331f
2331:             mulhsu      s9, zero, s11
                  c.slli      s0, 24
                  bgeu        t5, t5, 2335f
                  ori         s1, t6, 222
2335:             c.or        a3, a3
                  addi        t3, a2, -1263
                  sltu        tp, s11, s6
                  c.bnez      a3, 2357f
                  c.nop
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  bext  x31, x30, x31
                  csrw mscratch, x30
                  csrrs x31, mscratch, x0
                  csrrc x31, mscratch, x0
                  c.li        s1, -1
                  sra         s10, t1, s11
                  mulh        s2, s10, a6
                  lui         s11, 785903
                  xor         t3, s2, s4
                  bne         a7, a5, 2356f
                  div         s9, s6, s10
                  c.lui       s8, 19
                  sll         t2, tp, gp
                  c.lui       ra, 1
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  binv  x31, x30, x31
                  c.addi16sp  sp, -16
                  mulhsu      s8, a7, a0
                  c.addi16sp  sp, -16
                  srl         t3, s2, a7
                  ori         s0, a1, 357
                  slt         zero, s11, sp
2356:             c.or        a3, a3
2357:             c.addi      ra, 4
                  c.add       s0, t0
                  mulhsu      zero, a3, sp
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  bset  x31, x30, x31
                  c.nop
                  ori         s3, t3, 987
                  bltu        zero, s5, 2364f
                  lui         s1, 614719
2364:             xori        a1, a5, 770
                  bge         a7, s10, 2369f
                  c.add       gp, s3
                  c.srli      a3, 13
                  c.li        s6, -1
2369:             and         s8, zero, s10
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  bclri x31, x30, 31
                  srai        a4, s10, 7
                  bne         s11, a2, 2377f
                  bge         s3, t4, 2377f
                  c.or        a3, a3
                  nop
                  c.sub       a3, a3
                  c.xor       a3, a3
2377:             div         gp, ra, t1
                  sltiu       gp, t6, -470
                  blt         t3, s7, 2385f
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  bexti x31, x30, 15
                  mulhsu      s2, t4, s7
                  sltiu       zero, s0, 927
                  ori         a7, t1, 233
                  div         a2, t6, t3
                  c.srli      a3, 9
2385:             c.addi16sp  sp, -16
                  add         t2, s6, a3
                  mul         zero, a6, s8
                  sub         a7, t1, ra
                  srl         t0, s2, gp
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  binvi x31, x30, 0
                  csrw mscratch, x8
                  la   x8, zbcov_scratch
                  sw   x9, 0(x8)
                  sw   sp, 4(x8)
                  addi sp, x8, 8
                  c.swsp x31, 0(sp)
                  c.lwsp x30, 0(sp)
                  sw   x31, 8(x8)
                  c.lw  x9, 8(x8)
                  c.sw  x9, 8(x8)
                  lw   sp, 4(x8)
                  lw   x9, 0(x8)
                  csrr x8, mscratch
                  c.addi4spn  a3, sp, 384
                  add         a6, s8, a0
                  c.or        a3, a4
                  bge         a3, s6, 2394f
2394:             slli        s7, t2, 5
                  slli        t0, s0, 25
                  andi        s11, s3, -595
                  mulhu       tp, s1, zero
                  mulhsu      t3, t0, a0
                  sltu        ra, s6, t3
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  bseti x31, x30, 31
                  or          zero, s8, t6
                  c.mv        a3, s2
                  c.addi16sp  sp, 16
                  sltiu       a7, s9, 688
                  sra         s5, a2, a3
                  c.sub       a5, a3
                  c.and       a3, a3
                  c.li        s4, 28
                  mulh        s7, a6, ra
                  bgeu        s3, s1, 2424f
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  czero.eqz x31, x30, x31
                  c.sub       s1, a3
                  slt         zero, s0, t3
                  c.slli      s6, 8
                  c.mv        s1, s7
                  beq         sp, s10, 2416f
                  c.lui       gp, 26
2416:             c.mv        sp, s11
                  xori        t2, t2, -1626
                  c.sub       a3, a3
                  slti        t2, t3, 596
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  czero.nez x31, x30, x31
                  xori        a6, s1, 198
                  mulh        s0, s0, s11
                  sll         s10, a2, tp
                  c.slli      ra, 24
2424:             srl         a7, s3, s11
                  xori        s6, t1, 314
                  beq         sp, sp, 2432f
                  andi        a0, zero, 1646
                  c.mv        a4, t4
                  mul         s0, s11, a2
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  sh1add x31, x30, x31
                  xori        tp, a5, -1166
                  xor         a4, t3, tp
2432:             mul         a5, s1, s5
                  mulh        ra, t5, t3
                  c.srli      a3, 13
                  c.slli      s4, 8
                  slli        s3, s10, 2
                  addi        zero, t4, 179
                  c.addi16sp  sp, -16
                  rem         s11, zero, t4
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  sh2add x31, x30, x31
                  csrw mscratch, ra
                  c.jal 812491f
812491:            jal  ra, 812492f
812492:            jal  ra, 812493f
812493:            la   ra, 812494f
                  jalr x0, 0(ra)
812494:            csrr ra, mscratch
                  slli        a0, a6, 25
                  srl         a3, a4, a2
                  c.add       s7, s2
                  divu        s0, s2, s0
                  divu        ra, s10, a5
                  bge         s11, sp, 2456f
                  mul         s9, a2, a5
                  slt         s11, a4, t6
                  sub         t2, t2, a4
                  bgeu        a5, s6, 2451f
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  sh3add x31, x30, x31
                  mul         a6, s10, a0
2451:             srli        a3, ra, 3
                  ori         s9, s9, 1188
                  and         a4, a7, t2
                  c.andi      a3, -1
                  div         s7, t4, t1
2456:             andi        s6, a5, 209
                  sub         s4, s10, s1
                  rem         t0, a7, t4
                  c.xor       a3, a3
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  andn  x31, x30, x31
                  and         tp, t0, s5
                  div         a1, s10, a5
                  mulhsu      s2, t2, t6
                  addi        gp, s0, 622
                  rem         zero, s1, a6
                  bge         s3, tp, 2472f
                  c.beqz      a3, 2485f
                  mulhu       zero, s2, s10
                  c.li        a1, 13
                  xori        s10, s0, 918
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  orn   x31, x30, x31
                  sltiu       s5, t3, -974
                  xori        zero, a3, 484
2472:             bge         zero, a1, 2484f
                  c.srai      s0, 23
                  bgeu        s11, a3, 2475f
2475:             bltu        sp, sp, 2483f
                  c.bnez      a2, 2482f
                  xori        s0, zero, -533
                  c.li        a5, 18
                  mulh        zero, a2, a3
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  xnor  x31, x30, x31
                  csrw mscratch, ra
                  jal  ra, 822531f
                  jalr x0, 0(ra)     # wrong-path ret: IF pre-decode pop
822531:          csrr ra, mscratch
                  c.addi16sp  sp, -16
                  c.and       a3, a3
2482:             bgeu        sp, s0, 2484f
2483:             c.bnez      a3, 2488f
2484:             c.sub       a3, a3
2485:             bltu        a4, t0, 2500f
                  c.srli      a3, 31
                  sra         t2, t4, zero
2488:             mulh        s8, s7, s1
                  bne         a7, zero, 2499f
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  clz   x31, x30
                  li   x30, 0x80000000
                  li   x31, -1
                  div  x31, x30, x31
                  rem  x31, x30, x30
                  li   x31, 0
                  divu x31, x30, x31
                  li   x31, 0
                  rem  x31, x30, x31
                  c.add       s4, a6
                  sltiu       a6, s7, -1577
                  auipc       s0, 344515
                  and         s4, a6, t3
                  add         s11, a1, s6
                  auipc       s0, 777739
                  andi        a6, a7, 1449
                  c.mv        ra, t0
                  sltu        s8, a7, t4
2499:             c.srai      a3, 4
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  ctz   x31, x30
2500:             sub         t1, a1, a0
                  sra         s3, t1, a0
                  c.and       a3, a0
                  c.xor       a3, a3
                  srai        t2, a5, 9
                  slti        s2, zero, -1467
                  blt         a5, s8, 2512f
                  bne         s5, tp, 2509f
                  c.li        gp, -1
2509:             c.mv        s1, ra
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  cpop  x31, x30
                  srai        s11, a4, 6
                  c.sub       a3, a3
2512:             srl         s11, s8, tp
                  blt         t4, s0, 2517f
                  sra         s3, a6, s11
                  lui         s2, 168524
                  c.lui       s2, 21
2517:             mulhsu      zero, s8, s5
                  xor         s10, gp, s9
                  c.sub       a3, a2
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  min   x31, x30, x31
                  slti        a6, a5, 63
                  nop
                  div         s11, a1, a3
                  xori        zero, tp, 383
                  c.andi      a2, -1
                  c.addi4spn  s1, sp, 640
                  bgeu        s3, s3, 2537f
                  or          a4, s9, a7
                  srai        s11, s1, 30
                  sll         a7, t6, t0
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  minu  x31, x30, x31
                  c.bnez      a3, 2535f
                  c.srai      a3, 20
                  sltiu       ra, sp, -1161
                  mulhu       a3, a6, s9
                  srl         sp, t5, t6
2535:             slti        zero, s7, -1965
                  rem         s7, s6, s0
2537:             sll         s8, s6, s11
                  c.or        a3, a3
                  mulh        s6, tp, a2
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  max   x31, x30, x31
                  csrw mscratch, x30
                  csrrs x31, mscratch, x0
                  csrrc x31, mscratch, x0
                  c.li        s10, -1
                  bne         t1, s11, 2542f
2542:             xori        a0, zero, -67
                  c.srai      a3, 11
                  sltu        a0, t0, ra
                  mul         zero, t6, t2
                  div         a0, t5, a6
                  andi        a0, s8, 1076
                  c.lui       a2, 27
                  rem         t1, t0, s2
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  maxu  x31, x30, x31
                  slli        zero, a0, 12
                  mulhsu      t2, s11, t1
                  srai        a2, a5, 4
                  c.nop
                  ori         s4, s10, 1636
                  sltu        a6, a3, s10
                  mulhsu      a2, a6, s2
                  or          tp, t4, sp
                  c.nop
                  c.srli      a3, 7
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  sext.b x31, x30
                  c.mv        a4, gp
                  bltu        t4, s8, 2572f
                  andi        zero, t3, -128
                  c.mv        s3, t3
                  and         s0, s6, zero
                  mul         s9, s5, t4
                  mulhu       t0, s10, s9
                  c.slli      ra, 18
                  c.add       s4, a2
                  c.sub       a3, a3
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  sext.h x31, x30
                  or          a7, ra, t3
                  c.srli      a3, 17
2572:             xori        s2, gp, 1031
                  nop
                  mul         a1, s7, a2
                  div         t3, s0, t6
                  div         s5, t1, zero
                  xori        s1, a5, -1032
                  andi        gp, s5, 397
                  or          tp, t0, s1
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  zext.h x31, x30
                  ori         gp, t0, 14
                  c.bnez      a3, 2595f
                  c.or        a5, a3
                  addi        t2, tp, 880
                  mul         gp, s8, t2
                  addi        a6, t1, 1756
                  c.and       a3, a3
                  c.li        ra, -1
                  c.beqz      s1, 2603f
                  c.lui       s9, 2
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  rol   x31, x30, x31
                  csrw mscratch, x8
                  la   x8, zbcov_scratch
                  sw   x9, 0(x8)
                  sw   sp, 4(x8)
                  addi sp, x8, 8
                  c.swsp x31, 0(sp)
                  c.lwsp x30, 0(sp)
                  sw   x31, 8(x8)
                  c.lw  x9, 8(x8)
                  c.sw  x9, 8(x8)
                  lw   sp, 4(x8)
                  lw   x9, 0(x8)
                  csrr x8, mscratch
                  c.srai      a3, 24
                  c.mv        sp, t6
                  bne         s2, s2, 2605f
                  add         t0, zero, zero
                  sra         tp, zero, a0
2595:             c.xor       a1, a3
                  add         s5, gp, s10
                  bge         t0, zero, 2603f
                  addi        a4, t4, 1687
                  c.li        t1, -1
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  ror   x31, x30, x31
                  c.andi      a3, -1
                  ori         t3, sp, -1874
                  andi        sp, t4, -751
2603:             c.mv        s11, s6
                  blt         t2, t4, 2622f
2605:             and         s6, t0, a4
                  ori         t1, a4, 468
                  addi        t3, s8, -1531
                  c.addi4spn  a3, sp, 320
                  c.or        a1, a3
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  rori  x31, x30, 7
                  sll         a4, tp, tp
                  mul         s9, t0, a6
                  c.or        a2, a1
                  bgeu        s11, t4, 2618f
                  nop
                  xor         s5, ra, ra
                  sltu        ra, t5, s2
                  c.beqz      a3, 2627f
2618:             div         s10, s11, t5
                  c.addi16sp  sp, -16
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  orc.b x31, x30
                  lui         s6, 211714
                  c.xor       a3, a3
2622:             div         a6, s4, s5
                  c.srai      a3, 30
                  div         s2, a0, s11
                  c.add       s6, ra
                  ori         a6, t2, 1365
2627:             c.addi16sp  sp, 112
                  c.li        tp, 0
                  c.andi      a3, 13
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  rev8  x31, x30
                  auipc       t3, 952690
                  slt         zero, s11, a6
                  auipc       t1, 657277
                  c.or        a3, a3
                  lui         a2, 457216
                  c.beqz      a1, 2639f
                  c.lui       s10, 1
                  srai        s1, t5, 29
                  c.lui       a1, 7
2639:             bgeu        a1, t6, 2656f
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  bclr  x31, x30, x31
                  csrw mscratch, ra
                  jal  ra, 822691f
                  jalr x0, 0(ra)     # wrong-path ret: IF pre-decode pop
822691:          csrr ra, mscratch
                  csrw mscratch, ra
                  c.jal 812691f
812691:            jal  ra, 812692f
812692:            jal  ra, 812693f
812693:            la   ra, 812694f
                  jalr x0, 0(ra)
812694:            csrr ra, mscratch
                  rem         sp, s9, t0
                  c.andi      a3, 7
                  blt         s1, a2, 2661f
                  blt         t4, s5, 2662f
                  slli        s11, tp, 23
                  add         s5, t1, t2
                  c.add       s2, a2
                  andi        t1, t2, 1518
                  c.slli      a0, 1
                  sra         a0, s7, s5
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  bext  x31, x30, x31
                  c.beqz      a3, 2661f
                  c.srai      a3, 8
                  bgeu        gp, t2, 2663f
                  and         t2, s0, a7
                  c.sub       a3, a3
                  bgeu        s7, s2, 2660f
2656:             bltu        gp, s6, 2661f
                  bgeu        a4, a6, 2670f
                  rem         a6, ra, t3
                  rem         t0, s9, s8
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  binv  x31, x30, x31
2660:             c.srai      s1, 27
2661:             c.bnez      a3, 2668f
2662:             srl         sp, t3, a6
2663:             c.mv        a4, a2
                  srl         gp, sp, t2
                  andi        zero, t3, 882
                  div         s0, gp, s10
                  c.xor       a3, a3
2668:             beq         s5, s4, 2680f
                  c.bnez      a3, 2671f
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  bset  x31, x30, x31
2670:             auipc       s3, 999277
2671:             c.bnez      a3, 2686f
                  andi        s0, zero, -1577
                  sltiu       a3, t1, -844
                  slt         s7, a3, s0
                  bgeu        a3, a4, 2677f
                  bne         s11, s11, 2682f
2677:             bne         ra, ra, 2694f
                  c.or        a3, s0
                  xor         s5, s8, t3
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  bclri x31, x30, 31
2680:             beq         t1, t5, 2686f
                  blt         t5, a6, 2686f
2682:             c.xor       a3, a3
                  rem         s7, s7, t2
                  xori        a1, s3, 1471
                  c.addi16sp  sp, -16
2686:             sub         a0, t3, s7
                  beq         tp, t2, 2688f
2688:             div         a7, s6, s4
                  or          zero, s7, sp
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  bexti x31, x30, 15
                  li   x30, 0x80000000
                  li   x31, -1
                  div  x31, x30, x31
                  rem  x31, x30, x30
                  li   x31, 0
                  divu x31, x30, x31
                  li   x31, 0
                  rem  x31, x30, x31
                  add         s2, a0, a6
                  c.li        s11, -1
                  bge         a2, s0, 2693f
2693:             or          s3, a0, zero
2694:             blt         s0, ra, 2704f
                  sub         zero, a5, tp
                  srl         t0, s10, s8
                  rem         s3, s3, a3
                  sub         t0, s4, a0
                  and         s9, s11, gp
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  binvi x31, x30, 0
                  bne         a3, sp, 2710f
                  c.mv        ra, s8
                  c.nop
                  c.mv        ra, s3
2704:             sll         zero, s3, s6
                  and         zero, sp, a6
                  xor         s11, t4, t3
                  c.bnez      a0, 2721f
                  sltiu       s11, a7, 1941
                  sltu        s10, t1, s6
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  bseti x31, x30, 31
2710:             slt         s2, a0, t6
                  divu        a4, t2, s1
                  slli        s2, a7, 5
                  bne         s1, a2, 2717f
                  divu        s9, a4, s8
                  sltiu       s11, t0, 1374
                  c.beqz      a3, 2731f
2717:             sra         s5, a0, s7
                  c.and       a3, a3
                  c.xor       a3, a3
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  czero.eqz x31, x30, x31
                  mulhsu      s2, t2, t1
2721:             mulhu       t3, s9, s5
                  sltu        s5, a0, s6
                  add         s5, a7, s1
                  bge         s6, zero, 2732f
                  c.and       a3, a3
                  srli        a7, t0, 10
                  and         s9, a4, t0
                  auipc       s8, 1037367
                  c.xor       a3, a3
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  czero.nez x31, x30, x31
                  sra         s3, s0, s11
2731:             srli        a0, a0, 14
2732:             c.srli      a2, 7
                  c.or        s0, a3
                  c.beqz      a3, 2753f
                  sltiu       t2, a6, -629
                  slli        s7, a6, 14
                  addi        a7, s10, -1717
                  slti        s3, s8, -2029
                  c.nop
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  sh1add x31, x30, x31
                  csrw mscratch, x30
                  csrrs x31, mscratch, x0
                  csrrc x31, mscratch, x0
                  xori        a1, t2, -1120
                  slli        zero, sp, 16
                  mulhsu      t3, s9, a0
                  c.srli      a3, 28
                  c.or        a3, a3
                  c.mv        ra, a7
                  c.andi      a3, -1
                  rem         s6, s1, s5
                  c.xor       a0, a0
                  ori         s3, t3, 1665
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  sh2add x31, x30, x31
                  div         t2, ra, zero
                  lui         s5, 255718
                  srl         a1, s8, a5
2753:             blt         t3, a4, 2772f
                  andi        t0, s8, 512
                  bge         a4, t6, 2761f
                  c.slli      t3, 1
                  and         s11, a3, t0
                  c.srai      a3, 16
                  mul         s3, t4, s3
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  sh3add x31, x30, x31
                  srli        s11, t2, 0
2761:             srli        a1, s2, 6
                  bltu        s10, zero, 2766f
                  sltiu       a5, s11, 985
                  c.beqz      a3, 2775f
                  c.slli      a5, 27
2766:             mulhsu      t2, a1, a4
                  add         a1, a7, s8
                  bgeu        a5, gp, 2786f
                  c.addi16sp  sp, 480
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  andn  x31, x30, x31
                  xor         a0, a2, s11
                  mul         a5, s5, s9
2772:             or          s0, s1, t5
                  c.li        a7, -1
                  mulh        s3, t1, s4
2775:             slt         a4, a2, a7
                  bltu        sp, t4, 2787f
                  beq         t2, a7, 2779f
                  bne         a6, t0, 2797f
2779:             bltu        gp, t4, 2796f
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  orn   x31, x30, x31
                  c.lui       ra, 14
                  xor         zero, t1, s6
                  slli        s0, a7, 16
                  c.addi4spn  a0, sp, 352
                  bne         sp, a4, 2790f
                  c.add       t3, s6
2786:             srai        a1, sp, 30
2787:             sltu        zero, sp, s10
                  blt         gp, t3, 2793f
                  bge         a4, s0, 2795f
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  xnor  x31, x30, x31
                  csrw mscratch, x8
                  la   x8, zbcov_scratch
                  sw   x9, 0(x8)
                  sw   sp, 4(x8)
                  addi sp, x8, 8
                  c.swsp x31, 0(sp)
                  c.lwsp x30, 0(sp)
                  sw   x31, 8(x8)
                  c.lw  x9, 8(x8)
                  c.sw  x9, 8(x8)
                  lw   sp, 4(x8)
                  lw   x9, 0(x8)
                  csrr x8, mscratch
2790:             auipc       zero, 230607
                  c.slli      t0, 24
                  bltu        s7, t0, 2794f
2793:             srl         s4, zero, s11
2794:             bltu        gp, a7, 2806f
2795:             sltu        s1, a5, s6
2796:             slti        a4, t5, 863
2797:             c.sub       a3, a3
                  bltu        t5, t2, 2812f
                  blt         zero, s7, 2810f
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  clz   x31, x30
                  csrw mscratch, ra
                  jal  ra, 822851f
                  jalr x0, 0(ra)     # wrong-path ret: IF pre-decode pop
822851:          csrr ra, mscratch
                  add         sp, a0, s4
                  c.li        ra, 5
                  add         s4, a0, s1
                  sub         zero, sp, a2
                  c.addi4spn  s0, sp, 832
                  sra         s0, s4, s1
2806:             bne         s8, ra, 2813f
                  c.li        ra, -1
                  c.xor       a3, a3
                  c.and       a3, a2
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  ctz   x31, x30
2810:             bne         s9, a4, 2829f
                  mulhsu      gp, a3, t3
2812:             auipc       s1, 118640
2813:             sra         zero, s7, t4
                  ori         s2, s4, 683
                  slli        t2, s5, 5
                  slli        s3, t6, 8
                  c.nop
                  c.beqz      a3, 2820f
                  mul         tp, t1, s5
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  cpop  x31, x30
2820:             bgeu        t2, s4, 2825f
                  divu        zero, t0, s6
                  bltu        s6, s1, 2823f
2823:             mulhsu      s2, s3, s0
                  div         zero, t4, t5
2825:             auipc       s0, 576808
                  c.addi      tp, -1
                  c.addi      ra, -1
                  blt         s7, a2, 2832f
2829:             xor         s3, ra, t6
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  min   x31, x30, x31
                  slt         a4, t2, t3
                  ori         s9, a5, -1153
2832:             or          t3, t3, s9
                  c.bnez      a3, 2848f
                  c.or        a3, a3
                  slt         sp, tp, t3
                  beq         s2, s7, 2847f
                  c.srai      a3, 11
                  bge         gp, a0, 2846f
                  andi        a7, s11, -749
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  minu  x31, x30, x31
                  csrw mscratch, ra
                  c.jal 812891f
812891:            jal  ra, 812892f
812892:            jal  ra, 812893f
812893:            la   ra, 812894f
                  jalr x0, 0(ra)
812894:            csrr ra, mscratch
                  c.mv        s0, gp
                  beq         s2, t5, 2842f
2842:             ori         zero, s7, -1012
                  c.bnez      a3, 2853f
                  c.or        a3, a3
                  nop
2846:             nop
2847:             lui         a2, 30852
2848:             add         s10, a4, s3
                  rem         sp, t6, t4
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  max   x31, x30, x31
                  mulh        s6, a4, a4
                  xor         zero, t5, t2
                  c.addi16sp  sp, 80
2853:             c.sub       a3, a3
                  ori         s3, a3, 996
                  c.or        a3, a3
                  ori         t1, a0, -373
                  c.mv        s5, t2
                  sltiu       s6, a2, -1969
                  slt         a0, s4, tp
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  maxu  x31, x30, x31
                  c.bnez      a3, 2875f
                  mulh        s0, s4, tp
                  c.beqz      s1, 2881f
                  mulhsu      s1, s6, a3
                  c.addi4spn  a3, sp, 896
                  bne         t1, s10, 2875f
                  srai        zero, s1, 26
                  lui         a3, 30015
                  mulhsu      zero, s7, a2
                  c.srai      a3, 21
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  sext.b x31, x30
                  c.li        a0, -1
                  c.and       a3, a3
                  c.andi      s0, 11
                  bgeu        s2, s11, 2875f
                  c.addi16sp  sp, -16
2875:             srli        s11, a2, 21
                  bgeu        s6, s5, 2894f
                  nop
                  c.addi16sp  sp, -16
                  c.slli      ra, 31
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  sext.h x31, x30
                  c.addi16sp  sp, 416
2881:             xori        s3, zero, 1408
                  xori        s8, s4, -1731
                  bne         zero, t6, 2889f
                  addi        s8, s3, 1301
                  bge         s11, s3, 2889f
                  rem         t0, t0, t2
                  c.or        a3, a3
                  c.lui       a5, 23
2889:             andi        a6, a0, 870
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  zext.h x31, x30
                  li   x30, 0x80000000
                  li   x31, -1
                  div  x31, x30, x31
                  rem  x31, x30, x30
                  li   x31, 0
                  divu x31, x30, x31
                  li   x31, 0
                  rem  x31, x30, x31
                  mulhsu      tp, a5, a4
                  c.li        a1, -1
                  c.slli      s1, 9
                  sra         s3, t6, t0
2894:             srli        a5, t5, 20
                  c.nop
                  c.bnez      a0, 2909f
                  beq         sp, zero, 2916f
                  c.add       s2, t5
                  nop
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  rol   x31, x30, x31
                  slli        a7, gp, 3
                  sltu        t3, s11, a4
                  and         s0, s5, a5
                  div         t3, ra, a6
                  c.slli      a0, 21
                  c.xor       a3, a3
                  and         tp, a2, s3
                  nop
                  sltiu       gp, tp, 135
2909:             div         t2, a3, s3
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  ror   x31, x30, x31
                  and         sp, a7, a6
                  slli        gp, s9, 5
                  c.and       a4, a3
                  mulhsu      s3, s3, tp
                  c.and       a1, s0
                  sltiu       a0, a2, 1071
2916:             blt         s4, sp, 2927f
                  slt         a7, a4, t1
                  srl         a4, t1, s7
                  c.beqz      a3, 2924f
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  rori  x31, x30, 7
                  and         s9, a1, sp
                  ori         zero, s4, -317
                  c.andi      a1, -1
                  mulhu       s1, s11, ra
2924:             c.xor       a3, a3
                  beq         a1, s3, 2937f
                  sltu        s3, t0, s2
2927:             c.lui       ra, 5
                  bne         a3, s3, 2938f
                  bgeu        s3, t0, 2939f
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  orc.b x31, x30
                  or          a0, s9, s11
                  slti        s7, s3, -1564
                  xori        s3, s0, 392
                  xori        s9, gp, 1595
                  mul         t1, a3, tp
                  mul         a7, zero, zero
                  bge         tp, s2, 2938f
2937:             mulh        s0, a1, t4
2938:             c.nop
2939:             bgeu        s10, gp, 2958f
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  rev8  x31, x30
                  csrw mscratch, x30
                  csrrs x31, mscratch, x0
                  csrrc x31, mscratch, x0
                  c.addi      a7, -1
                  c.andi      a3, -1
                  lui         s8, 478416
                  sll         s8, s4, t5
                  slt         t2, s7, ra
                  mulhsu      a7, s6, a5
                  c.addi      sp, 5
                  addi        zero, sp, -677
                  beq         s1, t5, 2956f
                  c.beqz      a3, 2954f
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  bclr  x31, x30, x31
                  add         s10, sp, t5
                  c.srli      a3, 1
                  divu        s4, gp, s5
                  c.mv        a6, s6
2954:             c.add       s10, s10
                  c.beqz      a3, 2956f
2956:             c.mv        t3, a6
                  c.srli      a3, 2
2958:             c.li        s9, -1
                  mulhsu      t1, a6, t4
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  bext  x31, x30, x31
                  csrw mscratch, ra
                  jal  ra, 823011f
                  jalr x0, 0(ra)     # wrong-path ret: IF pre-decode pop
823011:          csrr ra, mscratch
                  c.andi      a3, -1
                  sltu        s9, s4, a2
                  c.addi      t0, -1
                  c.or        s1, a3
                  xor         t3, gp, s9
                  mul         s0, a7, s0
                  divu        s0, s6, t0
                  and         a3, a6, t0
                  c.and       a3, a3
                  auipc       a0, 249766
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  binv  x31, x30, x31
                  xor         s4, s6, t1
                  c.beqz      a3, 2982f
                  bgeu        s0, s4, 2979f
                  mul         s3, s3, t3
                  xor         a1, t4, a2
                  sltu        a3, a4, a4
                  c.slli      s7, 24
                  c.nop
                  c.addi4spn  a3, sp, 384
2979:             c.srli      a3, 3
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  bset  x31, x30, x31
                  addi        a4, s6, -693
                  c.slli      s1, 4
2982:             sltiu       ra, a1, 205
                  div         zero, s10, a2
                  sltiu       tp, s11, 1069
                  c.addi16sp  sp, 224
                  div         tp, a6, a5
                  c.mv        ra, t5
                  sll         s6, s7, a0
                  srai        s8, s11, 26
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  bclri x31, x30, 31
                  csrw mscratch, x8
                  la   x8, zbcov_scratch
                  sw   x9, 0(x8)
                  sw   sp, 4(x8)
                  addi sp, x8, 8
                  c.swsp x31, 0(sp)
                  c.lwsp x30, 0(sp)
                  sw   x31, 8(x8)
                  c.lw  x9, 8(x8)
                  c.sw  x9, 8(x8)
                  lw   sp, 4(x8)
                  lw   x9, 0(x8)
                  csrr x8, mscratch
                  sltiu       a5, s11, -1868
                  c.add       s6, ra
                  c.bnez      a1, 2993f
2993:             div         zero, s5, a0
                  c.li        s2, 4
                  slti        zero, s9, -1884
                  c.and       a3, a0
                  bne         s11, s0, 3016f
                  xori        a1, s2, 1060
                  slti        s7, sp, 259
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  bexti x31, x30, 15
                  bltu        t0, a5, 3013f
                  ori         a7, s8, -1740
                  srli        s4, s5, 11
                  mulh        s9, tp, ra
                  xor         t3, t0, a4
                  div         zero, a2, a1
                  c.xor       a3, a3
                  sltiu       s11, a3, 1900
                  c.mv        ra, t2
                  c.srai      a3, 12
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  binvi x31, x30, 0
                  c.li        ra, -1
                  or          gp, t4, a3
                  c.and       a3, s1
3013:             srl         zero, tp, s2
                  c.mv        ra, gp
                  c.xor       a3, a3
3016:             add         a1, s8, sp
                  c.srli      a3, 1
                  addi        s6, s6, -1702
                  sll         s9, a1, a0
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  bseti x31, x30, 31
                  c.addi4spn  a3, sp, 384
                  bge         a1, s10, 3039f
                  c.addi      gp, -1
                  blt         s10, s1, 3029f
                  c.sub       a3, a3
                  nop
                  bgeu        s7, s1, 3031f
                  addi        s3, t5, 1063
                  bne         t2, t0, 3033f
3029:             c.srli      a3, 12
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  czero.eqz x31, x30, x31
                  c.srai      a3, 11
3031:             nop
                  slli        tp, ra, 26
3033:             c.nop
                  ori         a6, a4, 1032
                  sub         s3, s10, a6
                  c.lui       ra, 9
                  srai        s6, a5, 1
                  c.nop
3039:             c.nop
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  czero.nez x31, x30, x31
                  csrw mscratch, ra
                  c.jal 813091f
813091:            jal  ra, 813092f
813092:            jal  ra, 813093f
813093:            la   ra, 813094f
                  jalr x0, 0(ra)
813094:            csrr ra, mscratch
                  srli        t3, a7, 9
                  c.beqz      s0, 3043f
                  bne         a6, a4, 3048f
3043:             nop
                  slti        s8, s9, -1801
                  c.andi      a3, 19
                  slti        t1, s10, 1671
                  c.slli      t0, 14
3048:             add         sp, ra, zero
                  sltu        a4, zero, ra
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  sh1add x31, x30, x31
                  c.nop
                  sra         s5, t0, s9
                  c.or        a3, a3
                  c.or        a0, a3
                  beq         t1, gp, 3068f
                  mulh        gp, s0, s0
                  c.beqz      a3, 3058f
                  or          zero, t2, zero
3058:             lui         s9, 650900
                  xori        a5, s10, -1211
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  sh2add x31, x30, x31
                  srl         zero, t6, s3
                  auipc       gp, 562370
                  c.addi4spn  a3, sp, 640
                  auipc       t3, 258847
                  mul         s10, s5, t2
                  sll         zero, t4, a0
                  beq         t2, zero, 3077f
                  c.li        a0, -1
3068:             c.sub       a3, a2
                  slt         t2, gp, t1
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  sh3add x31, x30, x31
                  blt         gp, t5, 3081f
                  sltu        s5, zero, s4
                  c.and       a3, a3
                  c.beqz      a4, 3090f
                  c.addi      s5, 9
                  c.or        a3, a3
                  xor         s6, tp, a3
3077:             c.lui       s0, 11
                  mulhsu      s0, t3, t5
                  andi        a6, s8, -1056
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  andn  x31, x30, x31
                  c.bnez      a2, 3086f
3081:             sltu        gp, s1, a2
                  div         t0, a3, s1
                  c.lui       s2, 3
                  c.add       a1, s11
                  c.nop
3086:             nop
                  addi        sp, s6, 1020
                  c.nop
                  auipc       s10, 566089
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  orn   x31, x30, x31
                  li   x30, 0x80000000
                  li   x31, -1
                  div  x31, x30, x31
                  rem  x31, x30, x30
                  li   x31, 0
                  divu x31, x30, x31
                  li   x31, 0
                  rem  x31, x30, x31
3090:             c.lui       s8, 13
                  sltiu       s0, t3, 907
                  sltu        s10, gp, a1
                  srli        t1, t4, 5
                  andi        s8, t2, -1071
                  ori         a1, s4, 434
                  bne         s2, sp, 3111f
                  c.andi      a3, 1
                  sltiu       zero, tp, -661
                  c.xor       a1, a3
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  xnor  x31, x30, x31
                  c.and       a3, a3
                  lui         s1, 566603
                  bne         a3, a2, 3117f
                  c.and       a3, a3
                  bltu        s5, gp, 3108f
                  slli        t1, zero, 9
                  sra         s5, a3, a3
                  div         t2, s1, a5
3108:             c.addi16sp  sp, -16
                  c.xor       a3, a5
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  clz   x31, x30
                  c.slli      ra, 29
3111:             auipc       a0, 139523
                  srli        a5, zero, 26
                  sll         s7, a1, t6
                  mulh        t2, s4, s1
                  c.andi      a3, 11
                  mulhsu      a7, a0, t2
3117:             beq         s3, s5, 3136f
                  c.add       ra, t3
                  xori        a4, tp, 1455
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  ctz   x31, x30
                  csrw mscratch, ra
                  jal  ra, 823171f
                  jalr x0, 0(ra)     # wrong-path ret: IF pre-decode pop
823171:          csrr ra, mscratch
                  c.or        a3, a3
                  blt         s2, a0, 3125f
                  mulhsu      gp, s5, gp
                  divu        s9, t6, t1
                  slt         s5, a3, s9
3125:             c.mv        a5, t0
                  srl         zero, gp, a5
                  bne         a5, s6, 3129f
                  mulh        s8, s6, t2
3129:             rem         s2, s7, s2
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  cpop  x31, x30
                  srai        s7, t0, 12
                  bgeu        t2, s11, 3137f
                  c.addi16sp  sp, -16
                  bgeu        a1, s6, 3134f
3134:             c.addi      t1, 20
                  div         a6, zero, a2
3136:             sub         s7, s10, s3
3137:             c.andi      a3, 30
                  or          a6, t4, s0
                  c.srli      a1, 11
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  min   x31, x30, x31
                  csrw mscratch, x30
                  csrrs x31, mscratch, x0
                  csrrc x31, mscratch, x0
                  xori        tp, a0, -805
                  c.beqz      a3, 3153f
                  c.sub       a3, a4
                  sub         a4, a2, t1
                  c.xor       a4, a3
                  c.addi4spn  a3, sp, 320
                  sltiu       gp, s5, 525
                  mulhsu      a7, zero, a4
                  mul         ra, sp, a5
                  c.mv        ra, s6
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  minu  x31, x30, x31
                  auipc       s5, 420322
                  c.addi4spn  s1, sp, 352
                  bgeu        s4, s10, 3158f
3153:             lui         a6, 161022
                  rem         s4, t6, s10
                  sltu        a2, sp, t0
                  c.slli      s2, 3
                  bne         a3, s0, 3161f
3158:             beq         s2, s9, 3169f
                  c.sub       a3, a3
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  max   x31, x30, x31
                  c.nop
3161:             nop
                  c.add       ra, gp
                  mulh        zero, s0, a1
                  addi        a0, s1, 1184
                  c.srai      a3, 21
                  slti        s2, s11, 997
                  addi        s1, s7, 1435
                  and         zero, t0, s4
3169:             c.lui       a1, 13
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  maxu  x31, x30, x31
                  mul         s11, t6, t6
                  div         zero, a1, zero
                  divu        a4, s9, s2
                  addi        s8, t1, -1145
                  c.addi      ra, 29
                  lui         t0, 880797
                  sra         zero, s5, s8
                  nop
                  bgeu        zero, a7, 3184f
                  c.andi      a3, 14
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  sext.b x31, x30
                  bne         a4, s4, 3188f
                  blt         a0, t1, 3196f
                  bne         tp, s9, 3201f
                  divu        t2, a6, s8
3184:             xori        t2, zero, 999
                  sltu        zero, ra, s5
                  auipc       a4, 252548
                  rem         s5, s4, s9
3188:             c.srli      a3, 6
                  c.beqz      a3, 3202f
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  sext.h x31, x30
                  csrw mscratch, x8
                  la   x8, zbcov_scratch
                  sw   x9, 0(x8)
                  sw   sp, 4(x8)
                  addi sp, x8, 8
                  c.swsp x31, 0(sp)
                  c.lwsp x30, 0(sp)
                  sw   x31, 8(x8)
                  c.lw  x9, 8(x8)
                  c.sw  x9, 8(x8)
                  lw   sp, 4(x8)
                  lw   x9, 0(x8)
                  csrr x8, mscratch
                  mulhsu      s5, s9, t6
                  c.or        a3, a3
                  c.srli      s0, 24
                  xor         tp, t2, ra
                  c.lui       t1, 22
                  mulh        s1, t1, s8
3196:             c.sub       a0, a3
                  srli        s1, gp, 19
                  sub         ra, s5, s2
                  nop
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  zext.h x31, x30
                  bne         t1, t1, 3219f
3201:             rem         a1, s1, a6
3202:             c.srli      a3, 23
                  or          t0, t0, a5
                  xor         s5, a0, zero
                  c.or        a3, s1
                  sra         zero, s8, s1
                  sltiu       gp, t5, 356
                  auipc       t2, 76803
                  c.li        ra, 20
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  rol   x31, x30, x31
                  c.li        s10, -1
                  andi        a6, t4, 1057
                  c.addi      ra, -1
                  sltiu       s9, a4, -633
                  auipc       sp, 381095
                  sll         t2, a1, t1
                  c.srli      a4, 22
                  srli        zero, s7, 13
                  c.add       t1, t2
3219:             div         zero, a6, t4
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  ror   x31, x30, x31
                  c.sub       a3, a3
                  addi        t2, t3, 1579
                  divu        t3, s4, s1
                  srl         s1, a7, s5
                  auipc       s11, 727656
                  c.xor       a3, a4
                  nop
                  c.addi4spn  a3, sp, 528
                  c.and       a3, a3
                  c.lui       s3, 31
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  rori  x31, x30, 7
                  sltu        sp, s8, s4
                  div         a0, s4, s7
                  c.srai      a3, 26
                  xori        a0, t2, -1853
                  bne         s7, a1, 3244f
                  mul         s2, a6, a7
                  c.bnez      a3, 3243f
                  mulh        gp, a2, a5
                  add         a7, a6, s3
                  c.xor       a3, a3
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  orc.b x31, x30
                  csrw mscratch, ra
                  c.jal 813291f
813291:            jal  ra, 813292f
813292:            jal  ra, 813293f
813293:            la   ra, 813294f
                  jalr x0, 0(ra)
813294:            csrr ra, mscratch
                  divu        t0, a4, a0
                  c.nop
                  blt         s9, s3, 3253f
3243:             c.lui       s0, 20
3244:             c.xor       a3, s0
                  c.sub       a3, a0
                  beq         a0, sp, 3248f
                  beq         a4, sp, 3265f
3248:             c.beqz      a3, 3252f
                  xor         gp, a2, t2
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  rev8  x31, x30
                  andi        s8, s6, -1763
                  c.andi      a3, 4
3252:             c.srai      a3, 18
3253:             c.or        a2, a3
                  c.addi4spn  a3, sp, 128
                  slli        zero, s7, 21
                  bge         t2, t3, 3267f
                  c.addi      s6, 23
                  auipc       s7, 914189
                  bltu        a5, s7, 3264f
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  bclr  x31, x30, x31
                  nop
                  c.add       ra, a2
                  blt         gp, s8, 3279f
                  srl         s1, s4, tp
3264:             c.li        s4, 27
3265:             xori        sp, t1, 1975
                  c.beqz      a3, 3267f
3267:             c.slli      s6, 15
                  sub         t1, s2, s2
                  and         gp, a7, a4
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  bext  x31, x30, x31
                  sll         a6, a6, s8
                  srli        s1, s1, 27
                  beq         a7, a0, 3286f
                  bne         zero, s6, 3278f
                  lui         zero, 454283
                  c.lui       t1, 30
                  xori        sp, s11, 23
                  bgeu        t0, a5, 3282f
3278:             mul         s1, t1, s11
3279:             or          zero, t3, s6
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  binv  x31, x30, x31
                  csrw mscratch, ra
                  jal  ra, 823331f
                  jalr x0, 0(ra)     # wrong-path ret: IF pre-decode pop
823331:          csrr ra, mscratch
                  add         t2, a5, s6
                  auipc       s1, 854155
3282:             c.andi      a3, -1
                  c.srai      a3, 7
                  beq         s11, a1, 3303f
                  ori         a1, s9, -137
3286:             addi        tp, a0, -1822
                  mulh        t2, ra, s1
                  sub         a4, t1, a2
                  rem         a1, a3, s0
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  bset  x31, x30, x31
                  li   x30, 0x80000000
                  li   x31, -1
                  div  x31, x30, x31
                  rem  x31, x30, x30
                  li   x31, 0
                  divu x31, x30, x31
                  li   x31, 0
                  rem  x31, x30, x31
                  div         t2, sp, ra
                  c.bnez      a3, 3301f
                  bne         tp, s8, 3307f
                  rem         t2, ra, zero
                  xor         t1, a0, s4
                  or          s10, tp, s0
                  c.or        s0, a3
                  beq         t3, t2, 3299f
                  sll         s7, gp, t2
3299:             slti        s5, a0, -961
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  bclri x31, x30, 31
                  c.nop
3301:             div         a1, tp, t5
                  sltiu       s2, s4, 1684
3303:             slli        s7, t4, 26
                  c.srai      a3, 23
                  blt         s10, a0, 3324f
                  c.and       a3, a3
3307:             mulh        zero, gp, s0
                  srai        s0, s7, 20
                  srai        a0, s1, 27
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  bexti x31, x30, 15
                  c.add       a5, s3
                  bltu        a3, tp, 3326f
                  c.srai      a3, 19
                  slli        t0, a3, 17
                  sll         s8, a6, tp
                  or          s11, zero, t4
                  mul         t3, s4, s4
                  c.add       ra, s9
                  slt         s1, gp, s8
                  c.srai      a3, 28
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  binvi x31, x30, 0
                  sub         s2, s10, a7
                  slti        a2, tp, -1140
                  bgeu        gp, t5, 3332f
                  srli        t3, a6, 31
3324:             blt         s10, a5, 3343f
                  blt         t4, t0, 3329f
3326:             c.andi      a3, 2
                  srl         a7, a5, ra
                  c.mv        s6, a4
3329:             nop
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  bseti x31, x30, 31
                  mulhsu      zero, a2, s10
                  c.andi      a3, -1
3332:             lui         a6, 244935
                  slt         s6, s6, gp
                  blt         s4, t3, 3353f
                  c.bnez      a3, 3340f
                  sltu        t1, t2, t6
                  c.beqz      s0, 3342f
                  c.xor       a3, a3
                  sra         a2, s1, a0
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  czero.eqz x31, x30, x31
                  csrw mscratch, x30
                  csrrs x31, mscratch, x0
                  csrrc x31, mscratch, x0
3340:             mulh        t3, s6, s7
                  div         a2, s0, a3
3342:             beq         t6, a4, 3357f
3343:             c.srai      s0, 26
                  c.addi4spn  s1, sp, 896
                  bge         s11, t4, 3356f
                  rem         t0, s0, t2
                  c.and       a3, a1
                  lui         a6, 357556
                  mulhsu      zero, t6, a6
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  czero.nez x31, x30, x31
                  c.and       a3, a3
                  sra         t0, gp, s2
                  c.and       a3, a3
3353:             bne         a5, s10, 3354f
3354:             c.andi      a4, 2
                  c.lui       a3, 19
3356:             andi        zero, a5, -897
3357:             bge         a7, gp, 3362f
                  bne         s6, s7, 3360f
                  or          s5, s1, a2
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  sh1add x31, x30, x31
3360:             c.sub       a3, a3
                  sltu        t2, a5, a0
3362:             sltiu       s5, a7, 1483
                  and         a7, s10, ra
                  c.andi      a3, -1
                  c.add       s8, s1
                  c.bnez      a1, 3377f
                  c.addi      t3, -1
                  bne         t0, s11, 3380f
                  sll         s2, t1, s10
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  sh2add x31, x30, x31
                  xor         gp, a6, t1
                  blt         gp, t2, 3382f
                  auipc       a7, 518172
                  mulhu       zero, s7, a4
                  c.or        a4, a3
                  c.lui       a3, 4
                  nop
3377:             divu        s8, s5, t0
                  xori        t1, a5, -545
                  c.andi      a1, 7
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  sh3add x31, x30, x31
3380:             bgeu        s11, s6, 3397f
                  srli        a7, s1, 13
3382:             bge         zero, a6, 3388f
                  or          a6, s3, zero
                  c.bnez      a3, 3402f
                  slt         s10, a2, s10
                  srli        t2, gp, 10
                  mulh        ra, zero, s0
3388:             beq         s7, gp, 3390f
                  c.srai      a0, 19
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  andn  x31, x30, x31
                  csrw mscratch, x8
                  la   x8, zbcov_scratch
                  sw   x9, 0(x8)
                  sw   sp, 4(x8)
                  addi sp, x8, 8
                  c.swsp x31, 0(sp)
                  c.lwsp x30, 0(sp)
                  sw   x31, 8(x8)
                  c.lw  x9, 8(x8)
                  c.sw  x9, 8(x8)
                  lw   sp, 4(x8)
                  lw   x9, 0(x8)
                  csrr x8, mscratch
3390:             mulhsu      zero, s0, t4
                  c.addi16sp  sp, -16
                  c.beqz      a3, 3398f
                  mulhsu      gp, a4, s9
                  blt         s11, t2, 3398f
                  slt         s3, t3, a6
                  divu        s11, t2, s6
3397:             mulhu       a4, sp, s7
3398:             c.srai      a3, 14
                  srli        t2, s2, 13
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  orn   x31, x30, x31
                  mulh        zero, s2, a7
                  rem         zero, t1, s9
3402:             bne         t0, s10, 3404f
                  mulhu       a1, a6, s11
3404:             c.srai      a4, 7
                  c.li        ra, -1
                  bgeu        s1, a3, 3419f
                  sll         gp, s9, s0
                  xori        a2, s3, -2038
                  mul         zero, t5, s9
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  xnor  x31, x30, x31
                  c.srli      s0, 29
                  bne         t6, s5, 3421f
                  lui         tp, 527704
                  divu        zero, t5, t6
                  beq         t3, zero, 3428f
                  c.li        t3, -1
                  srli        zero, a6, 19
                  bgeu        a0, s3, 3418f
3418:             divu        a0, t1, s11
3419:             xori        gp, a7, -293
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  clz   x31, x30
                  sll         t0, zero, t1
3421:             bge         a0, s1, 3428f
                  bge         ra, s6, 3428f
                  c.slli      a2, 19
                  srl         t1, s6, t4
                  c.li        ra, -1
                  mulhu       s10, s1, a7
                  c.srai      a1, 20
3428:             sra         a3, ra, a0
                  srli        t1, t6, 5
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  ctz   x31, x30
                  divu        zero, s0, s9
                  addi        s7, s9, 1327
                  sub         s7, t1, sp
                  lui         s10, 298947
                  blt         gp, t4, 3442f
                  ori         zero, s6, -925
                  srli        s7, s9, 23
                  c.beqz      a0, 3441f
                  sltiu       s3, s0, -1612
                  blt         s9, a4, 3458f
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  cpop  x31, x30
                  csrw mscratch, ra
                  jal  ra, 823491f
                  jalr x0, 0(ra)     # wrong-path ret: IF pre-decode pop
823491:          csrr ra, mscratch
                  csrw mscratch, ra
                  c.jal 813491f
813491:            jal  ra, 813492f
813492:            jal  ra, 813493f
813493:            la   ra, 813494f
                  jalr x0, 0(ra)
813494:            csrr ra, mscratch
                  bltu        t3, s3, 3445f
3441:             sll         zero, t6, s2
3442:             mulh        a2, t2, s0
                  c.or        a3, a3
                  and         s11, s7, a0
3445:             c.slli      t0, 21
                  beq         t6, a3, 3458f
                  lui         t1, 630528
                  c.and       a3, a3
                  bge         t5, s4, 3455f
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  min   x31, x30, x31
                  divu        s5, ra, t0
                  auipc       t2, 889681
                  c.addi16sp  sp, 192
                  srli        s11, s3, 31
                  c.li        ra, 7
3455:             srai        zero, t2, 4
                  xor         s7, gp, t6
                  blt         t3, a0, 3468f
3458:             mul         s11, zero, t1
                  bge         t5, a5, 3470f
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  minu  x31, x30, x31
                  nop
                  add         a1, gp, s2
                  sltu        s7, s9, a0
                  nop
                  c.mv        s0, a2
                  or          s0, t3, t6
                  lui         s1, 671520
                  c.and       s1, a3
3468:             auipc       t0, 853069
                  mulhu       t0, t3, s11
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  max   x31, x30, x31
3470:             bltu        t5, a3, 3475f
                  c.andi      a3, -1
                  ori         a3, t0, 253
                  div         t0, s0, gp
                  xori        ra, t2, -1645
3475:             sltu        s4, s11, a5
                  and         s3, s5, tp
                  andi        s2, s3, -36
                  beq         gp, a1, 3497f
                  ori         tp, t4, -1016
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  maxu  x31, x30, x31
                  c.beqz      a3, 3482f
                  c.xor       a3, a3
3482:             c.srli      a3, 9
                  or          s1, t4, t4
                  bge         s5, s9, 3503f
                  add         s11, sp, s9
                  div         t2, t6, a4
                  auipc       a4, 247904
                  mulhsu      s3, s4, t5
                  slt         s0, tp, ra
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  sext.b x31, x30
                  li   x30, 0x80000000
                  li   x31, -1
                  div  x31, x30, x31
                  rem  x31, x30, x30
                  li   x31, 0
                  divu x31, x30, x31
                  li   x31, 0
                  rem  x31, x30, x31
                  slt         s7, t6, s10
                  bne         a2, s6, 3509f
                  divu        sp, s5, s3
                  c.slli      s1, 12
                  c.addi      a1, -1
                  srl         s1, t2, s3
                  and         s4, s0, s8
3497:             slli        a6, s5, 10
                  auipc       t0, 808705
                  rem         t1, ra, s8
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  sext.h x31, x30
                  c.slli      ra, 9
                  slti        gp, a1, -1955
                  c.andi      a3, 5
3503:             rem         a6, a6, s0
                  srli        s7, s7, 23
                  mulhu       a6, s8, t3
                  auipc       s9, 191220
                  slli        s11, s0, 11
                  c.addi16sp  sp, -16
3509:             mulh        tp, t1, a2
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  zext.h x31, x30
                  divu        s10, ra, s7
                  srl         a0, a4, a7
                  or          a1, s2, s5
                  c.lui       a6, 25
                  lui         s1, 372017
                  bge         s3, a3, 3520f
                  auipc       ra, 490163
                  c.mv        s8, s3
                  divu        t3, s5, t3
                  sltiu       tp, s9, -1857
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  rol   x31, x30, x31
3520:             c.andi      a3, 6
                  sub         sp, t2, gp
                  beq         s11, s0, 3532f
                  c.andi      a3, 23
                  and         t3, s4, s6
                  lui         tp, 1029563
                  and         gp, a7, ra
                  xor         ra, s6, t5
                  mulhsu      s0, s8, s11
                  rem         ra, s1, ra
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  ror   x31, x30, x31
                  xori        s0, s5, 925
                  c.addi4spn  a3, sp, 960
3532:             srl         tp, a5, a2
                  beq         a6, a5, 3539f
                  c.slli      s11, 3
                  div         gp, ra, a3
                  c.addi16sp  sp, -16
                  c.addi16sp  sp, -16
                  c.addi16sp  sp, -16
3539:             mul         t0, s3, a2
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  rori  x31, x30, 7
                  csrw mscratch, x30
                  csrrs x31, mscratch, x0
                  csrrc x31, mscratch, x0
                  bltu        t1, a7, 3541f
3541:             c.andi      a3, 9
                  slli        s2, s9, 18
                  and         ra, sp, s0
                  nop
                  c.li        s2, -1
                  add         s6, s0, zero
                  c.mv        a0, a2
                  bltu        a6, tp, 3555f
                  c.and       a3, a1
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  orc.b x31, x30
                  c.xor       a3, a3
                  sltu        tp, sp, tp
                  c.beqz      s0, 3554f
                  sltu        s7, a0, s0
3554:             c.xor       a3, a3
3555:             sltiu       ra, ra, -1176
                  c.sub       a4, s1
                  sub         s0, a3, t5
                  c.slli      s10, 6
                  xori        ra, s1, 409
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  rev8  x31, x30
                  mulhsu      s9, s3, s10
                  sll         t1, a1, t3
                  c.lui       s9, 28
                  c.mv        t3, s1
                  beq         a3, t2, 3566f
                  addi        s3, s11, 1936
3566:             sra         zero, a3, s5
                  bgeu        s1, s0, 3577f
                  c.addi      s5, 14
                  bltu        s0, t4, 3580f
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  bclr  x31, x30, x31
                  srl         s4, zero, t1
                  c.mv        s8, s4
                  mul         a2, a5, s8
                  c.srli      a3, 30
                  c.nop
                  nop
                  sltu        a4, t4, t5
3577:             c.or        a3, a3
                  c.srli      a3, 22
                  srl         ra, a2, s0
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  bext  x31, x30, x31
3580:             ori         zero, s4, -954
                  nop
                  srl         zero, s4, t6
                  mulhu       a5, t3, s6
                  c.or        a3, s0
                  or          s4, gp, zero
                  c.nop
                  bgeu        s0, s6, 3604f
                  bltu        s7, t1, 3594f
                  c.sub       a3, a3
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  binv  x31, x30, x31
                  csrw mscratch, x8
                  la   x8, zbcov_scratch
                  sw   x9, 0(x8)
                  sw   sp, 4(x8)
                  addi sp, x8, 8
                  c.swsp x31, 0(sp)
                  c.lwsp x30, 0(sp)
                  sw   x31, 8(x8)
                  c.lw  x9, 8(x8)
                  c.sw  x9, 8(x8)
                  lw   sp, 4(x8)
                  lw   x9, 0(x8)
                  csrr x8, mscratch
                  srl         a0, s11, s11
                  ori         tp, s1, 542
                  sltiu       s5, t4, 658
                  c.xor       s0, s1
3594:             bne         t2, s2, 3595f
3595:             c.bnez      a3, 3609f
                  c.and       a3, a3
                  c.beqz      a3, 3612f
                  xori        sp, s3, 1617
                  nop
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  bset  x31, x30, x31
                  csrw mscratch, ra
                  jal  ra, 823651f
                  jalr x0, 0(ra)     # wrong-path ret: IF pre-decode pop
823651:          csrr ra, mscratch
                  bltu        tp, t3, 3608f
                  sltiu       s10, t1, 836
                  slti        tp, t5, -556
                  mul         zero, s8, t5
3604:             mulhsu      a1, a0, s5
                  c.mv        a4, s4
                  bge         s0, s4, 3619f
                  c.addi      gp, -1
3608:             rem         s2, t1, gp
3609:             beq         s7, s2, 3624f
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  bclri x31, x30, 31
                  divu        ra, s1, a1
                  c.add       s3, t5
3612:             bge         s3, s1, 3616f
                  mulhu       a4, s5, s5
                  slli        a0, a0, 31
                  c.and       a3, a3
3616:             add         tp, tp, ra
                  c.li        s9, 14
                  c.beqz      a3, 3624f
3619:             slt         s4, s5, s9
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  bexti x31, x30, 15
                  c.andi      a3, -1
                  c.nop
                  slt         s6, a3, t1
                  beq         a3, a5, 3636f
3624:             c.andi      a3, 29
                  rem         t1, t1, t6
                  div         a2, t2, a3
                  c.addi      s5, -1
                  slli        a1, t2, 11
                  srai        s1, a2, 7
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  binvi x31, x30, 0
                  addi        a1, a2, 1671
                  sub         zero, s2, s11
                  or          zero, s6, a5
                  or          s9, zero, a1
                  srl         zero, s9, s0
                  bne         a4, t3, 3649f
3636:             slli        s7, t4, 29
                  bgeu        gp, tp, 3638f
3638:             addi        s1, s11, -1780
                  c.addi16sp  sp, -16
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  bseti x31, x30, 31
                  csrw mscratch, ra
                  c.jal 813691f
813691:            jal  ra, 813692f
813692:            jal  ra, 813693f
813693:            la   ra, 813694f
                  jalr x0, 0(ra)
813694:            csrr ra, mscratch
                  auipc       a0, 475491
                  c.addi4spn  a3, sp, 320
                  bgeu        s1, s1, 3653f
                  sll         s5, t3, t6
                  sra         t2, s2, s11
                  sltu        s2, t2, s9
                  c.li        s0, 22
                  sltu        s2, s8, s5
                  c.add       a5, ra
3649:             or          zero, tp, t3
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  czero.eqz x31, x30, x31
                  add         t2, a2, s6
                  xor         s2, a4, a6
                  divu        ra, s11, s3
3653:             mulh        tp, a3, s3
                  c.lui       tp, 26
                  and         s5, a2, a5
                  mulhsu      gp, a1, s6
                  c.beqz      a4, 3664f
                  c.li        t1, 3
                  mulhsu      t0, sp, s11
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  czero.nez x31, x30, x31
                  c.xor       a3, s0
                  srai        s6, a3, 7
                  nop
                  bgeu        sp, gp, 3682f
3664:             sub         zero, t2, a7
                  c.srai      a3, 16
                  c.bnez      a3, 3671f
                  srl         gp, s10, t5
                  c.slli      s11, 7
                  srai        zero, a5, 24
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  sh1add x31, x30, x31
                  mulh        s6, a6, gp
3671:             blt         s9, s1, 3681f
                  c.beqz      a3, 3682f
                  mulhsu      zero, tp, a2
                  mulhu       zero, sp, t3
                  c.beqz      a3, 3680f
                  sltiu       s2, s6, -107
                  c.nop
                  c.addi      s7, 4
                  c.add       ra, s4
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  sh2add x31, x30, x31
3680:             lui         a4, 620111
3681:             xor         s6, t3, s4
3682:             mulhsu      zero, s9, t1
                  sra         s6, s11, s3
                  and         t0, s2, s2
                  lui         t2, 569882
                  sltu        t0, t2, s9
                  c.li        t3, -1
                  c.addi16sp  sp, 96
                  blt         a6, t2, 3700f
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  sh3add x31, x30, x31
                  li   x30, 0x80000000
                  li   x31, -1
                  div  x31, x30, x31
                  rem  x31, x30, x30
                  li   x31, 0
                  divu x31, x30, x31
                  li   x31, 0
                  rem  x31, x30, x31
                  c.sub       a3, a3
                  auipc       a2, 532712
                  c.beqz      a3, 3700f
                  c.srai      a3, 11
                  xori        t1, s11, -1964
                  or          gp, gp, t2
                  c.lui       s11, 1
                  c.srai      a3, 17
                  bgeu        s0, t2, 3709f
                  lui         a0, 53399
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  andn  x31, x30, x31
3700:             lui         a5, 240954
                  c.nop
                  c.sub       s0, a3
                  c.andi      a3, -1
                  sra         a6, s5, s1
                  sltiu       s6, s5, -774
                  blt         s4, t5, 3721f
                  c.srli      a2, 23
                  sub         s10, a1, a3
3709:             and         sp, s1, s0
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  orn   x31, x30, x31
                  c.li        ra, -1
                  sltu        s10, s5, a2
                  mulh        t2, a4, sp
                  slli        s10, s3, 4
                  or          s0, s6, ra
                  addi        a6, t6, -1414
                  and         a6, a6, s11
                  mul         s4, a5, s11
                  c.bnez      a3, 3722f
                  srl         s0, t4, s2
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  xnor  x31, x30, x31
                  ori         a5, sp, 1243
3721:             c.mv        ra, a1
3722:             bgeu        a5, a1, 3728f
                  sll         a7, tp, t6
                  srli        a6, t5, 14
                  slli        a2, s5, 1
                  nop
                  srl         s7, t1, t6
3728:             andi        gp, s11, -1797
                  bne         t6, t5, 3747f
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  clz   x31, x30
                  rem         s4, a5, a3
                  sub         a3, s4, tp
                  ori         s2, t2, 580
                  blt         s7, a4, 3739f
                  c.and       a3, a3
                  c.sub       a3, a3
                  andi        s4, s7, -1692
                  srl         s2, s8, t1
                  mulh        ra, s11, t6
3739:             beq         s11, tp, 3741f
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  ctz   x31, x30
                  csrw mscratch, x30
                  csrrs x31, mscratch, x0
                  csrrc x31, mscratch, x0
                  mulh        s0, a6, t0
3741:             c.addi16sp  sp, -16
                  bgeu        s5, a4, 3754f
                  bge         a6, s7, 3745f
                  c.bnez      a3, 3761f
3745:             slti        s0, sp, 1906
                  auipc       s5, 377387
3747:             sll         s4, sp, zero
                  sub         s5, s7, t1
                  xori        tp, t5, 1909
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  cpop  x31, x30
                  c.srli      a3, 29
                  slli        s3, a5, 0
                  sub         t0, s11, gp
                  xor         zero, a6, s0
3754:             add         a7, sp, sp
                  bgeu        t2, a1, 3757f
                  c.slli      ra, 23
3757:             c.or        a3, a3
                  auipc       s8, 454515
                  xori        s11, a6, 1864
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  min   x31, x30, x31
                  csrw mscratch, ra
                  jal  ra, 823811f
                  jalr x0, 0(ra)     # wrong-path ret: IF pre-decode pop
823811:          csrr ra, mscratch
                  slli        a6, s7, 15
3761:             sub         t3, a4, sp
                  sra         s7, gp, s0
                  and         s9, s2, t3
                  bltu        ra, t3, 3768f
                  c.and       a3, a3
                  c.lui       a1, 14
                  sub         t1, s11, s8
3768:             mulhu       a6, a3, t4
                  c.addi4spn  a4, sp, 736
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  minu  x31, x30, x31
                  sub         s6, a6, sp
                  sra         t1, s9, s8
                  addi        s8, s4, 93
                  bgeu        t6, ra, 3788f
                  add         gp, s10, s2
                  c.addi16sp  sp, -16
                  divu        a3, a4, a4
                  xori        t2, s7, 437
                  bltu        a5, gp, 3797f
                  slli        a5, sp, 10
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  max   x31, x30, x31
                  mulhu       t2, s8, s9
                  div         s6, a1, t3
                  srl         s0, s7, t6
                  bltu        tp, s1, 3784f
3784:             slti        t3, a4, -941
                  c.addi4spn  a1, sp, 832
                  c.add       ra, t4
                  bltu        s5, s11, 3792f
3788:             c.addi4spn  s1, sp, 320
                  slti        zero, s7, 1263
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  maxu  x31, x30, x31
                  csrw mscratch, x8
                  la   x8, zbcov_scratch
                  sw   x9, 0(x8)
                  sw   sp, 4(x8)
                  addi sp, x8, 8
                  c.swsp x31, 0(sp)
                  c.lwsp x30, 0(sp)
                  sw   x31, 8(x8)
                  c.lw  x9, 8(x8)
                  c.sw  x9, 8(x8)
                  lw   sp, 4(x8)
                  lw   x9, 0(x8)
                  csrr x8, mscratch
                  auipc       a3, 919085
                  divu        s6, s0, t5
3792:             blt         t1, s7, 3811f
                  sra         t2, s7, t6
                  c.beqz      a5, 3800f
                  bltu        s2, t1, 3808f
                  andi        s0, s9, 1831
3797:             mulh        zero, a6, s0
                  srli        a2, sp, 19
                  c.and       s1, a3
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  sext.b x31, x30
3800:             c.slli      a7, 1
                  slti        s3, a4, 1620
                  or          s6, ra, a0
                  mulhu       s0, s8, ra
                  andi        tp, a2, -830
                  divu        a1, gp, s6
                  c.addi4spn  a3, sp, 432
                  sra         s2, a0, t2
3808:             ori         s6, t1, -1586
                  sra         zero, t6, s4
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  sext.h x31, x30
                  andi        a2, a3, 1373
3811:             rem         a6, s6, a5
                  and         s11, s4, s3
                  c.addi4spn  s0, sp, 128
                  div         t3, s0, a0
                  divu        a4, a7, s9
                  div         a7, s5, s3
                  add         s4, t1, s6
                  sub         ra, t1, s1
                  mulhsu      s7, a6, t3
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  zext.h x31, x30
                  rem         s3, t2, s11
                  andi        zero, t0, -2025
                  slti        s9, s2, -998
                  c.beqz      a4, 3824f
3824:             lui         a3, 660776
                  c.li        ra, -1
                  srl         a0, t3, s8
                  divu        s1, a7, s6
                  mulh        zero, t0, gp
                  c.andi      a3, 25
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  rol   x31, x30, x31
                  sll         a6, t3, s11
                  xor         s3, zero, a5
                  sltu        t3, a7, a1
                  xori        sp, t5, -1828
                  sub         tp, a7, t1
                  sra         s1, a3, zero
                  and         tp, s3, t2
                  divu        a6, t3, ra
                  blt         s5, ra, 3843f
                  addi        s6, ra, -462
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  ror   x31, x30, x31
                  csrw mscratch, ra
                  c.jal 813891f
813891:            jal  ra, 813892f
813892:            jal  ra, 813893f
813893:            la   ra, 813894f
                  jalr x0, 0(ra)
813894:            csrr ra, mscratch
                  c.srli      a3, 16
                  nop
                  xor         a0, a1, t4
3843:             c.bnez      a3, 3860f
                  c.bnez      a3, 3854f
                  c.and       a2, a3
                  mulhsu      t1, s8, t6
                  c.and       s1, a3
                  bne         a2, tp, 3859f
                  andi        a3, t0, -1873
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  rori  x31, x30, 7
                  c.nop
                  add         t3, ra, a6
                  c.slli      s6, 22
                  c.lui       ra, 1
3854:             sra         zero, ra, a6
                  divu        s10, s7, a1
                  c.nop
                  c.bnez      a3, 3861f
                  bgeu        a4, s7, 3866f
3859:             sub         tp, tp, s5
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  orc.b x31, x30
3860:             sltiu       s11, a0, 337
3861:             and         s4, a7, t4
                  c.xor       a2, a3
                  srli        gp, ra, 19
                  slti        tp, sp, -791
                  c.beqz      a3, 3880f
3866:             c.addi4spn  a3, sp, 960
                  mulhu       sp, a3, a4
                  andi        t1, a7, 286
                  sra         a4, s4, a0
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  rev8  x31, x30
                  mulhsu      s11, a5, a0
                  divu        s10, a6, s10
                  mulhsu      t3, zero, s10
                  ori         s5, t0, 1641
                  c.srli      a5, 24
                  xori        ra, a5, 389
                  mulhsu      a1, s11, t2
                  bgeu        t4, t5, 3889f
                  nop
                  mul         t1, a5, a3
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  bclr  x31, x30, x31
3880:             or          s2, s0, s8
                  c.sub       a3, a3
                  mulh        s0, t0, s10
                  c.srai      s1, 27
                  c.bnez      a3, 3889f
                  c.sub       a3, a3
                  xori        zero, t0, -941
                  or          s6, t2, s11
                  ori         a7, tp, -647
3889:             c.li        s2, 8
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  bext  x31, x30, x31
                  li   x30, 0x80000000
                  li   x31, -1
                  div  x31, x30, x31
                  rem  x31, x30, x30
                  li   x31, 0
                  divu x31, x30, x31
                  li   x31, 0
                  rem  x31, x30, x31
                  c.mv        tp, s8
                  srl         ra, s11, a4
                  srai        a0, s11, 17
                  srli        a2, ra, 28
                  sub         zero, s9, t0
                  c.srai      a3, 7
                  c.addi4spn  a3, sp, 320
                  c.beqz      a3, 3899f
                  c.addi4spn  s1, sp, 384
3899:             mulh        a6, a0, s6
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  binv  x31, x30, x31
                  bltu        a2, t0, 3905f
                  or          s6, t3, zero
                  mulh        zero, s10, gp
                  srl         s5, t5, zero
                  andi        a3, s2, 492
3905:             beq         t6, s0, 3911f
                  c.nop
                  mulhsu      t1, a5, s7
                  c.xor       a3, s0
                  or          zero, t1, s9
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  bset  x31, x30, x31
                  mulh        t2, s7, t6
3911:             srai        s3, a4, 4
                  c.addi4spn  s0, sp, 832
                  add         a6, t6, zero
                  sltiu       s0, t2, -492
                  srai        zero, t3, 26
                  mulhsu      t2, a3, t0
                  xor         t1, s6, s10
                  c.xor       a3, s1
                  c.srai      a3, 11
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  bclri x31, x30, 31
                  csrw mscratch, ra
                  jal  ra, 823971f
                  jalr x0, 0(ra)     # wrong-path ret: IF pre-decode pop
823971:          csrr ra, mscratch
                  divu        t1, a5, ra
                  addi        t2, zero, 1410
                  sra         s1, s8, s7
                  c.mv        a6, s4
                  c.or        a3, a3
                  mul         zero, s6, ra
                  sltu        s2, t5, s4
                  slli        a4, sp, 1
                  sra         a2, t4, t4
                  divu        s10, a2, s0
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  bexti x31, x30, 15
                  c.sub       a3, s1
                  c.bnez      a3, 3933f
                  c.srli      a3, 23
3933:             c.and       a3, a0
                  sltu        a0, ra, s6
                  c.sub       a3, a0
                  bltu        zero, s1, 3947f
                  c.nop
                  c.beqz      a3, 3940f
                  bgeu        t1, s9, 3943f
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  binvi x31, x30, 0
                  csrw mscratch, x30
                  csrrs x31, mscratch, x0
                  csrrc x31, mscratch, x0
3940:             blt         sp, s3, 3950f
                  mulh        zero, a7, s3
                  mulh        zero, t2, s8
3943:             bge         a6, a5, 3958f
                  c.mv        a6, t3
                  addi        zero, s1, -1726
                  slti        a3, a3, 579
3947:             and         s5, s10, s8
                  sub         s11, a6, s10
                  bge         s1, s4, 3960f
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  bseti x31, x30, 31
3950:             sub         s0, t0, a1
                  mulh        a0, t3, s1
                  slti        a6, s4, -851
                  c.beqz      a3, 3972f
                  srl         s3, tp, s4
                  c.li        ra, -1
                  addi        s7, t1, -1181
                  c.addi4spn  a3, sp, 496
3958:             add         a3, t5, t0
                  andi        s6, a0, -649
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  czero.eqz x31, x30, x31
3960:             beq         gp, tp, 3978f
                  c.bnez      a3, 3968f
                  c.xor       a3, a2
                  sltiu       ra, s7, 1303
                  bge         s9, s3, 3970f
                  andi        a1, a6, 584
                  c.addi16sp  sp, 192
                  or          a5, a4, s8
3968:             c.li        s4, 0
                  c.addi      a6, -1
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  czero.nez x31, x30, x31
3970:             sltiu       a4, gp, -1192
                  c.add       ra, sp
3972:             mul         a3, gp, s5
                  add         a6, s1, ra
                  addi        ra, t2, -1637
                  sub         sp, s8, a0
                  sra         t2, s8, s10
                  srli        s4, gp, 9
3978:             sub         sp, s9, t6
                  lui         a7, 826602
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  sh1add x31, x30, x31
                  c.sub       a3, a3
                  slli        zero, s7, 9
                  srli        s3, s5, 6
                  c.beqz      a3, 3984f
3984:             srai        a5, a5, 31
                  c.beqz      a4, 4004f
                  c.li        ra, -1
                  c.sub       a3, a3
                  xor         a4, t4, s10
                  c.addi16sp  sp, -16
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  sh2add x31, x30, x31
                  csrw mscratch, x8
                  la   x8, zbcov_scratch
                  sw   x9, 0(x8)
                  sw   sp, 4(x8)
                  addi sp, x8, 8
                  c.swsp x31, 0(sp)
                  c.lwsp x30, 0(sp)
                  sw   x31, 8(x8)
                  c.lw  x9, 8(x8)
                  c.sw  x9, 8(x8)
                  lw   sp, 4(x8)
                  lw   x9, 0(x8)
                  csrr x8, mscratch
                  srli        s3, s7, 17
                  sltiu       tp, s4, -819
                  mulhsu      s11, s1, a4
                  mulhu       gp, a3, s11
                  mul         s9, s10, a0
                  mul         gp, zero, tp
                  c.lui       tp, 31
                  c.addi      s6, 5
                  auipc       s7, 84739
                  c.li        t0, -1
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  sh3add x31, x30, x31
                  andi        sp, s2, 654
                  c.nop
                  c.srli      a2, 7
                  c.sub       a3, a3
4004:             sltiu       s4, s8, -1878
                  c.li        a0, -1
                  c.srli      a3, 11
                  c.srli      a3, 16
                  c.addi16sp  sp, 400
                  slt         zero, ra, t4
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  andn  x31, x30, x31
                  slti        s4, zero, -1217
                  c.add       t2, s10
                  slti        s8, s2, 729
                  slt         a6, s9, s9
                  bltu        s3, a5, 4033f
                  andi        a1, s11, -1756
                  c.mv        s2, s0
                  bge         a5, a5, 4031f
                  c.andi      a3, -1
                  c.nop
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  orn   x31, x30, x31
                  slti        t0, s0, -177
                  slli        s6, a4, 28
                  bne         t0, s6, 4033f
                  sltiu       s8, s8, 1912
                  xori        t0, t4, 1682
                  srai        a6, t6, 16
                  srl         a7, a1, a3
                  bltu        s10, s11, 4033f
                  lui         s7, 6726
                  auipc       sp, 39030
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  xnor  x31, x30, x31
                  bne         t3, s9, 4032f
4031:             c.andi      a2, 4
4032:             c.mv        a7, t6
4033:             c.beqz      a3, 4044f
                  c.mv        a0, s10
                  sll         zero, gp, s0
                  c.xor       a3, a3
                  divu        a0, a1, t3
                  c.li        t2, -1
                  c.and       a3, a2
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  clz   x31, x30
                  csrw mscratch, ra
                  c.jal 814091f
814091:            jal  ra, 814092f
814092:            jal  ra, 814093f
814093:            la   ra, 814094f
                  jalr x0, 0(ra)
814094:            csrr ra, mscratch
                  sra         a2, s3, t5
                  c.mv        s3, s7
                  c.add       a5, tp
                  slli        gp, ra, 19
4044:             xor         gp, a1, s1
                  bltu        t6, tp, 4057f
                  nop
                  beq         s4, a0, 4054f
                  sra         a2, a1, a6
                  c.srli      a3, 5
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  ctz   x31, x30
                  and         zero, s5, s7
                  div         a3, t0, s8
                  blt         s0, s10, 4062f
                  c.srai      s0, 17
4054:             srl         s3, s5, s6
                  c.andi      a3, 25
                  xor         sp, t4, zero
4057:             c.slli      s5, 8
                  c.add       s7, ra
                  bltu        s4, sp, 4072f
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  cpop  x31, x30
                  c.addi16sp  sp, 496
                  or          s4, s10, s2
4062:             c.srli      a3, 20
                  c.beqz      a3, 4082f
                  slti        a0, t0, 1175
                  c.nop
                  or          a5, t1, gp
                  c.add       tp, gp
                  bltu        s4, s9, 4085f
                  ori         zero, s4, 959
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  min   x31, x30, x31
                  mul         s10, a0, s2
                  slt         s3, s2, s0
4072:             slli        sp, s5, 9
                  slt         s5, s6, t0
                  c.andi      a3, 27
                  bltu        a6, zero, 4090f
                  bgeu        a5, s1, 4081f
                  sra         a0, t2, t3
                  bgeu        a4, s0, 4079f
4079:             c.slli      a1, 20
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  minu  x31, x30, x31
                  csrw mscratch, ra
                  jal  ra, 824131f
                  jalr x0, 0(ra)     # wrong-path ret: IF pre-decode pop
824131:          csrr ra, mscratch
                  xor         t0, t0, t0
4081:             c.and       a3, a3
4082:             xori        s10, t3, -1721
                  c.bnez      a3, 4088f
                  slli        a3, s6, 12
4085:             xor         t1, tp, t4
                  c.mv        a5, s11
                  lui         sp, 226006
4088:             sub         s5, sp, t5
                  bltu        s11, t1, 4097f
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  max   x31, x30, x31
                  li   x30, 0x80000000
                  li   x31, -1
                  div  x31, x30, x31
                  rem  x31, x30, x30
                  li   x31, 0
                  divu x31, x30, x31
                  li   x31, 0
                  rem  x31, x30, x31
4090:             lui         s8, 186585
                  sll         t1, zero, gp
                  sra         t1, gp, s1
                  c.li        a6, 20
                  c.slli      s11, 6
                  c.andi      a3, 14
                  srli        zero, t3, 24
4097:             mulhsu      zero, s4, s11
                  ori         s2, s3, -1434
                  c.or        a2, a3
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  maxu  x31, x30, x31
                  mulhsu      s8, sp, t0
                  c.beqz      a3, 4119f
                  slli        t1, s0, 31
                  andi        a2, a6, 1620
                  divu        gp, t6, t1
                  xori        s8, s11, -628
                  srl         s3, s7, a4
                  c.slli      ra, 14
                  slli        t0, s3, 24
                  and         tp, s4, t4
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  sext.b x31, x30
                  c.add       ra, s0
                  c.or        a3, a3
                  slt         a3, s6, s6
                  xori        s1, s11, -447
                  or          ra, s9, s8
                  rem         s8, tp, t4
                  xor         a2, s11, t0
                  c.and       a3, a3
                  mulh        a3, ra, s2
4119:             srai        a5, t3, 18
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  sext.h x31, x30
                  c.bnez      a3, 4122f
                  bltu        sp, zero, 4136f
4122:             c.addi16sp  sp, 192
                  mulhu       s0, s6, t1
                  auipc       a1, 212376
                  bltu        s1, s6, 4136f
                  c.lui       s7, 14
                  c.li        s0, 18
                  c.bnez      a3, 4129f
4129:             mulhu       a6, s7, sp
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  zext.h x31, x30
                  srl         s6, t4, s9
                  c.li        ra, 25
                  xor         a6, s0, a2
                  slt         t3, t5, zero
                  bge         t3, t1, 4139f
                  slt         t2, s5, s9
4136:             c.addi16sp  sp, 144
                  ori         s6, gp, -220
                  bgeu        ra, t4, 4140f
4139:             c.srli      a3, 8
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  rol   x31, x30, x31
                  csrw mscratch, x30
                  csrrs x31, mscratch, x0
                  csrrc x31, mscratch, x0
4140:             bltu        s4, s6, 4150f
                  mulhu       s11, tp, zero
                  bne         s2, zero, 4146f
                  c.add       s4, t1
                  mulh        s9, sp, a5
                  c.xor       a3, a3
4146:             sll         s7, a3, a5
                  sll         s2, ra, t0
                  nop
                  srl         a6, a2, s11
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  ror   x31, x30, x31
4150:             nop
                  c.beqz      a5, 4157f
                  sll         t3, s7, a2
                  xor         s4, t2, t1
                  sltu        s8, s1, s11
                  slti        s6, s8, -1866
                  bgeu        tp, t2, 4160f
4157:             rem         s5, s9, a3
                  sltu        t3, t2, s5
                  c.srli      a3, 10
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  rori  x31, x30, 7
4160:             sltiu       zero, s6, 465
                  mulhsu      s9, tp, s0
                  mulhsu      tp, s1, s1
                  mulhu       s6, a7, zero
                  sub         zero, s9, tp
                  and         s11, s4, a7
                  mulh        s1, s6, s0
                  c.slli      tp, 31
                  slli        gp, sp, 2
                  slti        t3, a7, 1243
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  orc.b x31, x30
                  slt         a3, s1, a6
                  c.addi      gp, -1
                  div         s5, s0, s6
                  beq         s2, a2, 4187f
                  c.mv        a6, t6
                  c.addi      tp, -1
                  xor         a2, a2, t0
                  sll         a3, s2, t0
                  xor         t0, t3, t4
                  nop
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  rev8  x31, x30
                  sll         s10, s10, t6
                  c.sub       a3, a3
                  c.add       s7, t5
                  addi        s7, s2, -870
                  xori        s3, a2, 162
                  sltiu       s8, s0, -1229
                  add         t2, s3, a2
4187:             addi        a2, s8, -2039
                  mulhu       a7, a1, s9
                  srai        s3, s3, 28
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  bclr  x31, x30, x31
                  csrw mscratch, x8
                  la   x8, zbcov_scratch
                  sw   x9, 0(x8)
                  sw   sp, 4(x8)
                  addi sp, x8, 8
                  c.swsp x31, 0(sp)
                  c.lwsp x30, 0(sp)
                  sw   x31, 8(x8)
                  c.lw  x9, 8(x8)
                  c.sw  x9, 8(x8)
                  lw   sp, 4(x8)
                  lw   x9, 0(x8)
                  csrr x8, mscratch
                  and         ra, t4, s2
                  ori         a3, t5, -445
                  sub         a4, s10, a7
                  c.addi      a0, -1
                  addi        s6, t2, 466
                  c.beqz      a3, 4201f
                  c.beqz      a3, 4215f
                  c.sub       a4, a3
                  c.bnez      a3, 4217f
                  sra         s5, ra, s10
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  bext  x31, x30, x31
                  slt         s5, t0, s5
4201:             andi        t1, t1, 1798
                  sltiu       a2, s2, -1595
                  srli        t0, a3, 24
                  c.addi      s9, -1
                  nop
                  ori         a2, t0, 124
                  mulhsu      s4, gp, s1
                  xori        a6, s6, 211
                  c.sub       a3, a3
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  binv  x31, x30, x31
                  xor         a4, s10, a7
                  beq         ra, a0, 4217f
                  c.lui       s11, 12
                  beq         s8, sp, 4224f
                  c.srli      a3, 24
4215:             c.addi4spn  a3, sp, 832
                  slt         s5, t5, t2
4217:             auipc       a0, 760561
                  blt         a3, a6, 4236f
                  c.beqz      a3, 4229f
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  bset  x31, x30, x31
                  c.or        a3, a5
                  bltu        s2, s8, 4240f
                  c.xor       s0, a3
                  bne         t5, t2, 4228f
4224:             sub         t3, s7, t4
                  c.or        a3, a3
                  nop
                  sub         s3, s4, ra
4228:             blt         a0, s0, 4232f
4229:             bgeu        s8, s4, 4234f
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  bclri x31, x30, 31
                  c.li        s2, -1
                  div         s9, t4, a7
4232:             mulhu       t1, t0, t1
                  c.addi4spn  a3, sp, 320
4234:             c.mv        a2, s1
                  c.bnez      a3, 4243f
4236:             sltiu       t3, t3, 1266
                  bgeu        s8, a5, 4242f
                  sltiu       s3, a2, -1686
                  mulhsu      s10, a2, gp
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  bexti x31, x30, 15
                  csrw mscratch, ra
                  jal  ra, 824291f
                  jalr x0, 0(ra)     # wrong-path ret: IF pre-decode pop
824291:          csrr ra, mscratch
                  csrw mscratch, ra
                  c.jal 814291f
814291:            jal  ra, 814292f
814292:            jal  ra, 814293f
814293:            la   ra, 814294f
                  jalr x0, 0(ra)
814294:            csrr ra, mscratch
4240:             bltu        s4, a6, 4242f
                  c.mv        s6, tp
4242:             bgeu        t6, a7, 4259f
4243:             c.nop
                  slli        t0, t1, 24
                  div         a3, a2, a1
                  c.srai      s0, 27
                  bge         tp, t6, 4257f
                  c.srai      a5, 28
                  bne         t5, tp, 4250f
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  binvi x31, x30, 0
4250:             srli        s3, a0, 21
                  c.and       a3, a1
                  c.addi4spn  a5, sp, 320
                  c.xor       a1, a3
                  mulhu       s6, a6, s5
                  nop
                  c.beqz      a3, 4269f
4257:             nop
                  ori         t3, gp, -1484
4259:             c.andi      a3, 0
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  bseti x31, x30, 31
                  nop
                  bgeu        s5, s5, 4262f
4262:             xori        a7, ra, 532
                  c.xor       a3, a2
                  sub         t1, tp, s2
                  ori         a5, s4, 525
                  c.xor       a3, a3
                  mul         s8, t0, zero
                  bge         s0, a4, 4274f
4269:             sra         gp, t4, a2
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  czero.eqz x31, x30, x31
                  mul         tp, s6, s5
                  c.add       a7, s10
                  c.srai      a3, 16
                  auipc       a7, 526172
4274:             beq         s2, s0, 4281f
                  divu        zero, s10, sp
                  sltiu       zero, a2, -142
                  srai        tp, t1, 11
                  c.addi      s0, 19
                  srl         s7, s10, s2
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  czero.nez x31, x30, x31
                  andi        s11, s6, -366
4281:             c.sub       a3, a1
                  c.or        a3, a5
                  bgeu        sp, s0, 4285f
                  c.addi4spn  a3, sp, 832
4285:             slti        s6, gp, 294
                  c.addi16sp  sp, -16
                  mulh        a2, a6, s3
                  srai        gp, gp, 3
                  mulhu       t2, s4, t0
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  sh1add x31, x30, x31
                  li   x30, 0x80000000
                  li   x31, -1
                  div  x31, x30, x31
                  rem  x31, x30, x30
                  li   x31, 0
                  divu x31, x30, x31
                  li   x31, 0
                  rem  x31, x30, x31
                  bgeu        a3, s6, 4305f
                  srl         a6, a3, t3
                  and         a6, s5, a7
                  c.xor       s1, a3
                  div         gp, a5, t1
                  slti        s4, ra, 1987
                  sub         ra, s7, a7
                  c.srli      a3, 6
                  xor         a6, s3, sp
                  andi        a0, a3, 1890
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  sh2add x31, x30, x31
                  slli        t2, a1, 28
                  mulhu       zero, a2, tp
                  sltiu       gp, a7, 1182
                  bgeu        s10, s1, 4315f
                  sltiu       s10, a7, -1604
4305:             srl         s1, a5, s4
                  beq         s0, sp, 4320f
                  add         ra, a2, s6
                  rem         t0, a4, gp
                  rem         zero, a6, a6
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  sh3add x31, x30, x31
                  xori        t0, gp, -1082
                  auipc       sp, 186587
                  c.lui       ra, 20
                  srai        s9, ra, 8
                  c.beqz      a3, 4333f
4315:             div         a6, s8, s7
                  auipc       t1, 511695
                  sltu        s5, t4, t2
                  c.sub       a4, a3
                  andi        a6, t1, -1776
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  andn  x31, x30, x31
4320:             addi        zero, a6, 1033
                  blt         t4, gp, 4332f
                  mulhsu      sp, s1, a6
                  sll         s8, a5, zero
                  andi        zero, s7, 973
                  c.slli      sp, 4
                  mulh        a0, t0, s1
                  sltiu       a4, t5, -229
                  xori        s4, a6, -1769
                  ori         a0, s2, -502
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  orn   x31, x30, x31
                  bltu        t0, t6, 4349f
                  mulhsu      ra, a3, sp
4332:             c.mv        a7, ra
4333:             c.lui       ra, 18
                  c.addi16sp  sp, 336
                  bltu        t6, s7, 4337f
                  mulh        t3, t0, t0
4337:             c.or        a3, a3
                  nop
                  bge         t6, a2, 4345f
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  xnor  x31, x30, x31
                  csrw mscratch, x30
                  csrrs x31, mscratch, x0
                  csrrc x31, mscratch, x0
                  sltiu       s5, a5, -225
                  ori         s0, s11, -168
                  bgeu        a2, a6, 4357f
                  c.srai      a3, 16
                  c.and       a3, a3
4345:             c.li        a5, 28
                  c.slli      a1, 14
                  srli        zero, tp, 17
                  bge         s7, t0, 4358f
4349:             c.addi16sp  sp, 224
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  clz   x31, x30
                  slt         s8, s5, ra
                  mulhsu      zero, a5, s2
                  sltu        s8, a4, a6
                  mulhsu      a5, t1, s7
                  sra         sp, a6, a7
                  ori         t3, a1, 1590
                  c.lui       t3, 19
4357:             divu        zero, t1, a0
4358:             c.add       ra, t4
                  la x30, test_done
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  ctz   x31, x30
                  jalr x0, x30, 0
test_done:        
                  li gp, 1
                  j write_tohost
write_tohost:     
                  sw gp, tohost, t5

_exit:            
                  j write_tohost

instr_end:        
                  nop

.section .data
.align 2
j18_misalign_data:
.word 0x11223344
.align 6; .global tohost; tohost: .dword 0;
.align 6; .global fromhost; fromhost: .dword 0;
.section .region_0,"aw",@progbits;
region_0:
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.word 0x40414243, 0x44454647, 0x48494a4b, 0x4c4d4e4f, 0x50515253, 0x54555657, 0x58595a5b, 0x5c5d5e5f
.word 0x60616263, 0x64656667, 0x68696a6b, 0x6c6d6e6f, 0x70717273, 0x74757677, 0x78797a7b, 0x7c7d7e7f
.word 0x80818283, 0x84858687, 0x88898a8b, 0x8c8d8e8f, 0x90919293, 0x94959697, 0x98999a9b, 0x9c9d9e9f
.word 0xa0a1a2a3, 0xa4a5a6a7, 0xa8a9aaab, 0xacadaeaf, 0xb0b1b2b3, 0xb4b5b6b7, 0xb8b9babb, 0xbcbdbebf
.word 0xc0c1c2c3, 0xc4c5c6c7, 0xc8c9cacb, 0xcccdcecf, 0xd0d1d2d3, 0xd4d5d6d7, 0xd8d9dadb, 0xdcdddedf
.word 0xe0e1e2e3, 0xe4e5e6e7, 0xe8e9eaeb, 0xecedeeef, 0xf0f1f2f3, 0xf4f5f6f7, 0xf8f9fafb, 0xfcfdfeff
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.word 0x40414243, 0x44454647, 0x48494a4b, 0x4c4d4e4f, 0x50515253, 0x54555657, 0x58595a5b, 0x5c5d5e5f
.word 0x60616263, 0x64656667, 0x68696a6b, 0x6c6d6e6f, 0x70717273, 0x74757677, 0x78797a7b, 0x7c7d7e7f
.word 0x80818283, 0x84858687, 0x88898a8b, 0x8c8d8e8f, 0x90919293, 0x94959697, 0x98999a9b, 0x9c9d9e9f
.word 0xa0a1a2a3, 0xa4a5a6a7, 0xa8a9aaab, 0xacadaeaf, 0xb0b1b2b3, 0xb4b5b6b7, 0xb8b9babb, 0xbcbdbebf
.word 0xc0c1c2c3, 0xc4c5c6c7, 0xc8c9cacb, 0xcccdcecf, 0xd0d1d2d3, 0xd4d5d6d7, 0xd8d9dadb, 0xdcdddedf
.word 0xe0e1e2e3, 0xe4e5e6e7, 0xe8e9eaeb, 0xecedeeef, 0xf0f1f2f3, 0xf4f5f6f7, 0xf8f9fafb, 0xfcfdfeff
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.word 0x40414243, 0x44454647, 0x48494a4b, 0x4c4d4e4f, 0x50515253, 0x54555657, 0x58595a5b, 0x5c5d5e5f
.word 0x60616263, 0x64656667, 0x68696a6b, 0x6c6d6e6f, 0x70717273, 0x74757677, 0x78797a7b, 0x7c7d7e7f
.word 0x80818283, 0x84858687, 0x88898a8b, 0x8c8d8e8f, 0x90919293, 0x94959697, 0x98999a9b, 0x9c9d9e9f
.word 0xa0a1a2a3, 0xa4a5a6a7, 0xa8a9aaab, 0xacadaeaf, 0xb0b1b2b3, 0xb4b5b6b7, 0xb8b9babb, 0xbcbdbebf
.word 0xc0c1c2c3, 0xc4c5c6c7, 0xc8c9cacb, 0xcccdcecf, 0xd0d1d2d3, 0xd4d5d6d7, 0xd8d9dadb, 0xdcdddedf
.word 0xe0e1e2e3, 0xe4e5e6e7, 0xe8e9eaeb, 0xecedeeef, 0xf0f1f2f3, 0xf4f5f6f7, 0xf8f9fafb, 0xfcfdfeff
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.word 0x40414243, 0x44454647, 0x48494a4b, 0x4c4d4e4f, 0x50515253, 0x54555657, 0x58595a5b, 0x5c5d5e5f
.word 0x60616263, 0x64656667, 0x68696a6b, 0x6c6d6e6f, 0x70717273, 0x74757677, 0x78797a7b, 0x7c7d7e7f
.word 0x80818283, 0x84858687, 0x88898a8b, 0x8c8d8e8f, 0x90919293, 0x94959697, 0x98999a9b, 0x9c9d9e9f
.word 0xa0a1a2a3, 0xa4a5a6a7, 0xa8a9aaab, 0xacadaeaf, 0xb0b1b2b3, 0xb4b5b6b7, 0xb8b9babb, 0xbcbdbebf
.word 0xc0c1c2c3, 0xc4c5c6c7, 0xc8c9cacb, 0xcccdcecf, 0xd0d1d2d3, 0xd4d5d6d7, 0xd8d9dadb, 0xdcdddedf
.word 0xe0e1e2e3, 0xe4e5e6e7, 0xe8e9eaeb, 0xecedeeef, 0xf0f1f2f3, 0xf4f5f6f7, 0xf8f9fafb, 0xfcfdfeff
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.word 0x40414243, 0x44454647, 0x48494a4b, 0x4c4d4e4f, 0x50515253, 0x54555657, 0x58595a5b, 0x5c5d5e5f
.word 0x60616263, 0x64656667, 0x68696a6b, 0x6c6d6e6f, 0x70717273, 0x74757677, 0x78797a7b, 0x7c7d7e7f
.word 0x80818283, 0x84858687, 0x88898a8b, 0x8c8d8e8f, 0x90919293, 0x94959697, 0x98999a9b, 0x9c9d9e9f
.word 0xa0a1a2a3, 0xa4a5a6a7, 0xa8a9aaab, 0xacadaeaf, 0xb0b1b2b3, 0xb4b5b6b7, 0xb8b9babb, 0xbcbdbebf
.word 0xc0c1c2c3, 0xc4c5c6c7, 0xc8c9cacb, 0xcccdcecf, 0xd0d1d2d3, 0xd4d5d6d7, 0xd8d9dadb, 0xdcdddedf
.word 0xe0e1e2e3, 0xe4e5e6e7, 0xe8e9eaeb, 0xecedeeef, 0xf0f1f2f3, 0xf4f5f6f7, 0xf8f9fafb, 0xfcfdfeff
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.word 0x40414243, 0x44454647, 0x48494a4b, 0x4c4d4e4f, 0x50515253, 0x54555657, 0x58595a5b, 0x5c5d5e5f
.word 0x60616263, 0x64656667, 0x68696a6b, 0x6c6d6e6f, 0x70717273, 0x74757677, 0x78797a7b, 0x7c7d7e7f
.word 0x80818283, 0x84858687, 0x88898a8b, 0x8c8d8e8f, 0x90919293, 0x94959697, 0x98999a9b, 0x9c9d9e9f
.word 0xa0a1a2a3, 0xa4a5a6a7, 0xa8a9aaab, 0xacadaeaf, 0xb0b1b2b3, 0xb4b5b6b7, 0xb8b9babb, 0xbcbdbebf
.word 0xc0c1c2c3, 0xc4c5c6c7, 0xc8c9cacb, 0xcccdcecf, 0xd0d1d2d3, 0xd4d5d6d7, 0xd8d9dadb, 0xdcdddedf
.word 0xe0e1e2e3, 0xe4e5e6e7, 0xe8e9eaeb, 0xecedeeef, 0xf0f1f2f3, 0xf4f5f6f7, 0xf8f9fafb, 0xfcfdfeff
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.word 0x40414243, 0x44454647, 0x48494a4b, 0x4c4d4e4f, 0x50515253, 0x54555657, 0x58595a5b, 0x5c5d5e5f
.word 0x60616263, 0x64656667, 0x68696a6b, 0x6c6d6e6f, 0x70717273, 0x74757677, 0x78797a7b, 0x7c7d7e7f
.word 0x80818283, 0x84858687, 0x88898a8b, 0x8c8d8e8f, 0x90919293, 0x94959697, 0x98999a9b, 0x9c9d9e9f
.word 0xa0a1a2a3, 0xa4a5a6a7, 0xa8a9aaab, 0xacadaeaf, 0xb0b1b2b3, 0xb4b5b6b7, 0xb8b9babb, 0xbcbdbebf
.word 0xc0c1c2c3, 0xc4c5c6c7, 0xc8c9cacb, 0xcccdcecf, 0xd0d1d2d3, 0xd4d5d6d7, 0xd8d9dadb, 0xdcdddedf
.word 0xe0e1e2e3, 0xe4e5e6e7, 0xe8e9eaeb, 0xecedeeef, 0xf0f1f2f3, 0xf4f5f6f7, 0xf8f9fafb, 0xfcfdfeff
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.word 0x40414243, 0x44454647, 0x48494a4b, 0x4c4d4e4f, 0x50515253, 0x54555657, 0x58595a5b, 0x5c5d5e5f
.word 0x60616263, 0x64656667, 0x68696a6b, 0x6c6d6e6f, 0x70717273, 0x74757677, 0x78797a7b, 0x7c7d7e7f
.word 0x80818283, 0x84858687, 0x88898a8b, 0x8c8d8e8f, 0x90919293, 0x94959697, 0x98999a9b, 0x9c9d9e9f
.word 0xa0a1a2a3, 0xa4a5a6a7, 0xa8a9aaab, 0xacadaeaf, 0xb0b1b2b3, 0xb4b5b6b7, 0xb8b9babb, 0xbcbdbebf
.word 0xc0c1c2c3, 0xc4c5c6c7, 0xc8c9cacb, 0xcccdcecf, 0xd0d1d2d3, 0xd4d5d6d7, 0xd8d9dadb, 0xdcdddedf
.word 0xe0e1e2e3, 0xe4e5e6e7, 0xe8e9eaeb, 0xecedeeef, 0xf0f1f2f3, 0xf4f5f6f7, 0xf8f9fafb, 0xfcfdfeff
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.word 0x40414243, 0x44454647, 0x48494a4b, 0x4c4d4e4f, 0x50515253, 0x54555657, 0x58595a5b, 0x5c5d5e5f
.word 0x60616263, 0x64656667, 0x68696a6b, 0x6c6d6e6f, 0x70717273, 0x74757677, 0x78797a7b, 0x7c7d7e7f
.word 0x80818283, 0x84858687, 0x88898a8b, 0x8c8d8e8f, 0x90919293, 0x94959697, 0x98999a9b, 0x9c9d9e9f
.word 0xa0a1a2a3, 0xa4a5a6a7, 0xa8a9aaab, 0xacadaeaf, 0xb0b1b2b3, 0xb4b5b6b7, 0xb8b9babb, 0xbcbdbebf
.word 0xc0c1c2c3, 0xc4c5c6c7, 0xc8c9cacb, 0xcccdcecf, 0xd0d1d2d3, 0xd4d5d6d7, 0xd8d9dadb, 0xdcdddedf
.word 0xe0e1e2e3, 0xe4e5e6e7, 0xe8e9eaeb, 0xecedeeef, 0xf0f1f2f3, 0xf4f5f6f7, 0xf8f9fafb, 0xfcfdfeff
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.word 0x40414243, 0x44454647, 0x48494a4b, 0x4c4d4e4f, 0x50515253, 0x54555657, 0x58595a5b, 0x5c5d5e5f
.word 0x60616263, 0x64656667, 0x68696a6b, 0x6c6d6e6f, 0x70717273, 0x74757677, 0x78797a7b, 0x7c7d7e7f
.word 0x80818283, 0x84858687, 0x88898a8b, 0x8c8d8e8f, 0x90919293, 0x94959697, 0x98999a9b, 0x9c9d9e9f
.word 0xa0a1a2a3, 0xa4a5a6a7, 0xa8a9aaab, 0xacadaeaf, 0xb0b1b2b3, 0xb4b5b6b7, 0xb8b9babb, 0xbcbdbebf
.word 0xc0c1c2c3, 0xc4c5c6c7, 0xc8c9cacb, 0xcccdcecf, 0xd0d1d2d3, 0xd4d5d6d7, 0xd8d9dadb, 0xdcdddedf
.word 0xe0e1e2e3, 0xe4e5e6e7, 0xe8e9eaeb, 0xecedeeef, 0xf0f1f2f3, 0xf4f5f6f7, 0xf8f9fafb, 0xfcfdfeff
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.word 0x40414243, 0x44454647, 0x48494a4b, 0x4c4d4e4f, 0x50515253, 0x54555657, 0x58595a5b, 0x5c5d5e5f
.word 0x60616263, 0x64656667, 0x68696a6b, 0x6c6d6e6f, 0x70717273, 0x74757677, 0x78797a7b, 0x7c7d7e7f
.word 0x80818283, 0x84858687, 0x88898a8b, 0x8c8d8e8f, 0x90919293, 0x94959697, 0x98999a9b, 0x9c9d9e9f
.word 0xa0a1a2a3, 0xa4a5a6a7, 0xa8a9aaab, 0xacadaeaf, 0xb0b1b2b3, 0xb4b5b6b7, 0xb8b9babb, 0xbcbdbebf
.word 0xc0c1c2c3, 0xc4c5c6c7, 0xc8c9cacb, 0xcccdcecf, 0xd0d1d2d3, 0xd4d5d6d7, 0xd8d9dadb, 0xdcdddedf
.word 0xe0e1e2e3, 0xe4e5e6e7, 0xe8e9eaeb, 0xecedeeef, 0xf0f1f2f3, 0xf4f5f6f7, 0xf8f9fafb, 0xfcfdfeff
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.word 0x40414243, 0x44454647, 0x48494a4b, 0x4c4d4e4f, 0x50515253, 0x54555657, 0x58595a5b, 0x5c5d5e5f
.word 0x60616263, 0x64656667, 0x68696a6b, 0x6c6d6e6f, 0x70717273, 0x74757677, 0x78797a7b, 0x7c7d7e7f
.word 0x80818283, 0x84858687, 0x88898a8b, 0x8c8d8e8f, 0x90919293, 0x94959697, 0x98999a9b, 0x9c9d9e9f
.word 0xa0a1a2a3, 0xa4a5a6a7, 0xa8a9aaab, 0xacadaeaf, 0xb0b1b2b3, 0xb4b5b6b7, 0xb8b9babb, 0xbcbdbebf
.word 0xc0c1c2c3, 0xc4c5c6c7, 0xc8c9cacb, 0xcccdcecf, 0xd0d1d2d3, 0xd4d5d6d7, 0xd8d9dadb, 0xdcdddedf
.word 0xe0e1e2e3, 0xe4e5e6e7, 0xe8e9eaeb, 0xecedeeef, 0xf0f1f2f3, 0xf4f5f6f7, 0xf8f9fafb, 0xfcfdfeff
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.word 0x40414243, 0x44454647, 0x48494a4b, 0x4c4d4e4f, 0x50515253, 0x54555657, 0x58595a5b, 0x5c5d5e5f
.word 0x60616263, 0x64656667, 0x68696a6b, 0x6c6d6e6f, 0x70717273, 0x74757677, 0x78797a7b, 0x7c7d7e7f
.word 0x80818283, 0x84858687, 0x88898a8b, 0x8c8d8e8f, 0x90919293, 0x94959697, 0x98999a9b, 0x9c9d9e9f
.word 0xa0a1a2a3, 0xa4a5a6a7, 0xa8a9aaab, 0xacadaeaf, 0xb0b1b2b3, 0xb4b5b6b7, 0xb8b9babb, 0xbcbdbebf
.word 0xc0c1c2c3, 0xc4c5c6c7, 0xc8c9cacb, 0xcccdcecf, 0xd0d1d2d3, 0xd4d5d6d7, 0xd8d9dadb, 0xdcdddedf
.word 0xe0e1e2e3, 0xe4e5e6e7, 0xe8e9eaeb, 0xecedeeef, 0xf0f1f2f3, 0xf4f5f6f7, 0xf8f9fafb, 0xfcfdfeff
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.word 0x40414243, 0x44454647, 0x48494a4b, 0x4c4d4e4f, 0x50515253, 0x54555657, 0x58595a5b, 0x5c5d5e5f
.word 0x60616263, 0x64656667, 0x68696a6b, 0x6c6d6e6f, 0x70717273, 0x74757677, 0x78797a7b, 0x7c7d7e7f
.word 0x80818283, 0x84858687, 0x88898a8b, 0x8c8d8e8f, 0x90919293, 0x94959697, 0x98999a9b, 0x9c9d9e9f
.word 0xa0a1a2a3, 0xa4a5a6a7, 0xa8a9aaab, 0xacadaeaf, 0xb0b1b2b3, 0xb4b5b6b7, 0xb8b9babb, 0xbcbdbebf
.word 0xc0c1c2c3, 0xc4c5c6c7, 0xc8c9cacb, 0xcccdcecf, 0xd0d1d2d3, 0xd4d5d6d7, 0xd8d9dadb, 0xdcdddedf
.word 0xe0e1e2e3, 0xe4e5e6e7, 0xe8e9eaeb, 0xecedeeef, 0xf0f1f2f3, 0xf4f5f6f7, 0xf8f9fafb, 0xfcfdfeff
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.word 0x40414243, 0x44454647, 0x48494a4b, 0x4c4d4e4f, 0x50515253, 0x54555657, 0x58595a5b, 0x5c5d5e5f
.word 0x60616263, 0x64656667, 0x68696a6b, 0x6c6d6e6f, 0x70717273, 0x74757677, 0x78797a7b, 0x7c7d7e7f
.word 0x80818283, 0x84858687, 0x88898a8b, 0x8c8d8e8f, 0x90919293, 0x94959697, 0x98999a9b, 0x9c9d9e9f
.word 0xa0a1a2a3, 0xa4a5a6a7, 0xa8a9aaab, 0xacadaeaf, 0xb0b1b2b3, 0xb4b5b6b7, 0xb8b9babb, 0xbcbdbebf
.word 0xc0c1c2c3, 0xc4c5c6c7, 0xc8c9cacb, 0xcccdcecf, 0xd0d1d2d3, 0xd4d5d6d7, 0xd8d9dadb, 0xdcdddedf
.word 0xe0e1e2e3, 0xe4e5e6e7, 0xe8e9eaeb, 0xecedeeef, 0xf0f1f2f3, 0xf4f5f6f7, 0xf8f9fafb, 0xfcfdfeff
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.word 0x40414243, 0x44454647, 0x48494a4b, 0x4c4d4e4f, 0x50515253, 0x54555657, 0x58595a5b, 0x5c5d5e5f
.word 0x60616263, 0x64656667, 0x68696a6b, 0x6c6d6e6f, 0x70717273, 0x74757677, 0x78797a7b, 0x7c7d7e7f
.word 0x80818283, 0x84858687, 0x88898a8b, 0x8c8d8e8f, 0x90919293, 0x94959697, 0x98999a9b, 0x9c9d9e9f
.word 0xa0a1a2a3, 0xa4a5a6a7, 0xa8a9aaab, 0xacadaeaf, 0xb0b1b2b3, 0xb4b5b6b7, 0xb8b9babb, 0xbcbdbebf
.word 0xc0c1c2c3, 0xc4c5c6c7, 0xc8c9cacb, 0xcccdcecf, 0xd0d1d2d3, 0xd4d5d6d7, 0xd8d9dadb, 0xdcdddedf
.word 0xe0e1e2e3, 0xe4e5e6e7, 0xe8e9eaeb, 0xecedeeef, 0xf0f1f2f3, 0xf4f5f6f7, 0xf8f9fafb, 0xfcfdfeff
.section .region_1,"aw",@progbits;
region_1:
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.word 0x40414243, 0x44454647, 0x48494a4b, 0x4c4d4e4f, 0x50515253, 0x54555657, 0x58595a5b, 0x5c5d5e5f
.word 0x60616263, 0x64656667, 0x68696a6b, 0x6c6d6e6f, 0x70717273, 0x74757677, 0x78797a7b, 0x7c7d7e7f
.word 0x80818283, 0x84858687, 0x88898a8b, 0x8c8d8e8f, 0x90919293, 0x94959697, 0x98999a9b, 0x9c9d9e9f
.word 0xa0a1a2a3, 0xa4a5a6a7, 0xa8a9aaab, 0xacadaeaf, 0xb0b1b2b3, 0xb4b5b6b7, 0xb8b9babb, 0xbcbdbebf
.word 0xc0c1c2c3, 0xc4c5c6c7, 0xc8c9cacb, 0xcccdcecf, 0xd0d1d2d3, 0xd4d5d6d7, 0xd8d9dadb, 0xdcdddedf
.word 0xe0e1e2e3, 0xe4e5e6e7, 0xe8e9eaeb, 0xecedeeef, 0xf0f1f2f3, 0xf4f5f6f7, 0xf8f9fafb, 0xfcfdfeff
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.word 0x40414243, 0x44454647, 0x48494a4b, 0x4c4d4e4f, 0x50515253, 0x54555657, 0x58595a5b, 0x5c5d5e5f
.word 0x60616263, 0x64656667, 0x68696a6b, 0x6c6d6e6f, 0x70717273, 0x74757677, 0x78797a7b, 0x7c7d7e7f
.word 0x80818283, 0x84858687, 0x88898a8b, 0x8c8d8e8f, 0x90919293, 0x94959697, 0x98999a9b, 0x9c9d9e9f
.word 0xa0a1a2a3, 0xa4a5a6a7, 0xa8a9aaab, 0xacadaeaf, 0xb0b1b2b3, 0xb4b5b6b7, 0xb8b9babb, 0xbcbdbebf
.word 0xc0c1c2c3, 0xc4c5c6c7, 0xc8c9cacb, 0xcccdcecf, 0xd0d1d2d3, 0xd4d5d6d7, 0xd8d9dadb, 0xdcdddedf
.word 0xe0e1e2e3, 0xe4e5e6e7, 0xe8e9eaeb, 0xecedeeef, 0xf0f1f2f3, 0xf4f5f6f7, 0xf8f9fafb, 0xfcfdfeff
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.word 0x40414243, 0x44454647, 0x48494a4b, 0x4c4d4e4f, 0x50515253, 0x54555657, 0x58595a5b, 0x5c5d5e5f
.word 0x60616263, 0x64656667, 0x68696a6b, 0x6c6d6e6f, 0x70717273, 0x74757677, 0x78797a7b, 0x7c7d7e7f
.word 0x80818283, 0x84858687, 0x88898a8b, 0x8c8d8e8f, 0x90919293, 0x94959697, 0x98999a9b, 0x9c9d9e9f
.word 0xa0a1a2a3, 0xa4a5a6a7, 0xa8a9aaab, 0xacadaeaf, 0xb0b1b2b3, 0xb4b5b6b7, 0xb8b9babb, 0xbcbdbebf
.word 0xc0c1c2c3, 0xc4c5c6c7, 0xc8c9cacb, 0xcccdcecf, 0xd0d1d2d3, 0xd4d5d6d7, 0xd8d9dadb, 0xdcdddedf
.word 0xe0e1e2e3, 0xe4e5e6e7, 0xe8e9eaeb, 0xecedeeef, 0xf0f1f2f3, 0xf4f5f6f7, 0xf8f9fafb, 0xfcfdfeff
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.word 0x40414243, 0x44454647, 0x48494a4b, 0x4c4d4e4f, 0x50515253, 0x54555657, 0x58595a5b, 0x5c5d5e5f
.word 0x60616263, 0x64656667, 0x68696a6b, 0x6c6d6e6f, 0x70717273, 0x74757677, 0x78797a7b, 0x7c7d7e7f
.word 0x80818283, 0x84858687, 0x88898a8b, 0x8c8d8e8f, 0x90919293, 0x94959697, 0x98999a9b, 0x9c9d9e9f
.word 0xa0a1a2a3, 0xa4a5a6a7, 0xa8a9aaab, 0xacadaeaf, 0xb0b1b2b3, 0xb4b5b6b7, 0xb8b9babb, 0xbcbdbebf
.word 0xc0c1c2c3, 0xc4c5c6c7, 0xc8c9cacb, 0xcccdcecf, 0xd0d1d2d3, 0xd4d5d6d7, 0xd8d9dadb, 0xdcdddedf
.word 0xe0e1e2e3, 0xe4e5e6e7, 0xe8e9eaeb, 0xecedeeef, 0xf0f1f2f3, 0xf4f5f6f7, 0xf8f9fafb, 0xfcfdfeff
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.word 0x40414243, 0x44454647, 0x48494a4b, 0x4c4d4e4f, 0x50515253, 0x54555657, 0x58595a5b, 0x5c5d5e5f
.word 0x60616263, 0x64656667, 0x68696a6b, 0x6c6d6e6f, 0x70717273, 0x74757677, 0x78797a7b, 0x7c7d7e7f
.word 0x80818283, 0x84858687, 0x88898a8b, 0x8c8d8e8f, 0x90919293, 0x94959697, 0x98999a9b, 0x9c9d9e9f
.word 0xa0a1a2a3, 0xa4a5a6a7, 0xa8a9aaab, 0xacadaeaf, 0xb0b1b2b3, 0xb4b5b6b7, 0xb8b9babb, 0xbcbdbebf
.word 0xc0c1c2c3, 0xc4c5c6c7, 0xc8c9cacb, 0xcccdcecf, 0xd0d1d2d3, 0xd4d5d6d7, 0xd8d9dadb, 0xdcdddedf
.word 0xe0e1e2e3, 0xe4e5e6e7, 0xe8e9eaeb, 0xecedeeef, 0xf0f1f2f3, 0xf4f5f6f7, 0xf8f9fafb, 0xfcfdfeff
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.word 0x40414243, 0x44454647, 0x48494a4b, 0x4c4d4e4f, 0x50515253, 0x54555657, 0x58595a5b, 0x5c5d5e5f
.word 0x60616263, 0x64656667, 0x68696a6b, 0x6c6d6e6f, 0x70717273, 0x74757677, 0x78797a7b, 0x7c7d7e7f
.word 0x80818283, 0x84858687, 0x88898a8b, 0x8c8d8e8f, 0x90919293, 0x94959697, 0x98999a9b, 0x9c9d9e9f
.word 0xa0a1a2a3, 0xa4a5a6a7, 0xa8a9aaab, 0xacadaeaf, 0xb0b1b2b3, 0xb4b5b6b7, 0xb8b9babb, 0xbcbdbebf
.word 0xc0c1c2c3, 0xc4c5c6c7, 0xc8c9cacb, 0xcccdcecf, 0xd0d1d2d3, 0xd4d5d6d7, 0xd8d9dadb, 0xdcdddedf
.word 0xe0e1e2e3, 0xe4e5e6e7, 0xe8e9eaeb, 0xecedeeef, 0xf0f1f2f3, 0xf4f5f6f7, 0xf8f9fafb, 0xfcfdfeff
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.word 0x40414243, 0x44454647, 0x48494a4b, 0x4c4d4e4f, 0x50515253, 0x54555657, 0x58595a5b, 0x5c5d5e5f
.word 0x60616263, 0x64656667, 0x68696a6b, 0x6c6d6e6f, 0x70717273, 0x74757677, 0x78797a7b, 0x7c7d7e7f
.word 0x80818283, 0x84858687, 0x88898a8b, 0x8c8d8e8f, 0x90919293, 0x94959697, 0x98999a9b, 0x9c9d9e9f
.word 0xa0a1a2a3, 0xa4a5a6a7, 0xa8a9aaab, 0xacadaeaf, 0xb0b1b2b3, 0xb4b5b6b7, 0xb8b9babb, 0xbcbdbebf
.word 0xc0c1c2c3, 0xc4c5c6c7, 0xc8c9cacb, 0xcccdcecf, 0xd0d1d2d3, 0xd4d5d6d7, 0xd8d9dadb, 0xdcdddedf
.word 0xe0e1e2e3, 0xe4e5e6e7, 0xe8e9eaeb, 0xecedeeef, 0xf0f1f2f3, 0xf4f5f6f7, 0xf8f9fafb, 0xfcfdfeff
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.word 0x40414243, 0x44454647, 0x48494a4b, 0x4c4d4e4f, 0x50515253, 0x54555657, 0x58595a5b, 0x5c5d5e5f
.word 0x60616263, 0x64656667, 0x68696a6b, 0x6c6d6e6f, 0x70717273, 0x74757677, 0x78797a7b, 0x7c7d7e7f
.word 0x80818283, 0x84858687, 0x88898a8b, 0x8c8d8e8f, 0x90919293, 0x94959697, 0x98999a9b, 0x9c9d9e9f
.word 0xa0a1a2a3, 0xa4a5a6a7, 0xa8a9aaab, 0xacadaeaf, 0xb0b1b2b3, 0xb4b5b6b7, 0xb8b9babb, 0xbcbdbebf
.word 0xc0c1c2c3, 0xc4c5c6c7, 0xc8c9cacb, 0xcccdcecf, 0xd0d1d2d3, 0xd4d5d6d7, 0xd8d9dadb, 0xdcdddedf
.word 0xe0e1e2e3, 0xe4e5e6e7, 0xe8e9eaeb, 0xecedeeef, 0xf0f1f2f3, 0xf4f5f6f7, 0xf8f9fafb, 0xfcfdfeff
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.word 0x40414243, 0x44454647, 0x48494a4b, 0x4c4d4e4f, 0x50515253, 0x54555657, 0x58595a5b, 0x5c5d5e5f
.word 0x60616263, 0x64656667, 0x68696a6b, 0x6c6d6e6f, 0x70717273, 0x74757677, 0x78797a7b, 0x7c7d7e7f
.word 0x80818283, 0x84858687, 0x88898a8b, 0x8c8d8e8f, 0x90919293, 0x94959697, 0x98999a9b, 0x9c9d9e9f
.word 0xa0a1a2a3, 0xa4a5a6a7, 0xa8a9aaab, 0xacadaeaf, 0xb0b1b2b3, 0xb4b5b6b7, 0xb8b9babb, 0xbcbdbebf
.word 0xc0c1c2c3, 0xc4c5c6c7, 0xc8c9cacb, 0xcccdcecf, 0xd0d1d2d3, 0xd4d5d6d7, 0xd8d9dadb, 0xdcdddedf
.word 0xe0e1e2e3, 0xe4e5e6e7, 0xe8e9eaeb, 0xecedeeef, 0xf0f1f2f3, 0xf4f5f6f7, 0xf8f9fafb, 0xfcfdfeff
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.word 0x40414243, 0x44454647, 0x48494a4b, 0x4c4d4e4f, 0x50515253, 0x54555657, 0x58595a5b, 0x5c5d5e5f
.word 0x60616263, 0x64656667, 0x68696a6b, 0x6c6d6e6f, 0x70717273, 0x74757677, 0x78797a7b, 0x7c7d7e7f
.word 0x80818283, 0x84858687, 0x88898a8b, 0x8c8d8e8f, 0x90919293, 0x94959697, 0x98999a9b, 0x9c9d9e9f
.word 0xa0a1a2a3, 0xa4a5a6a7, 0xa8a9aaab, 0xacadaeaf, 0xb0b1b2b3, 0xb4b5b6b7, 0xb8b9babb, 0xbcbdbebf
.word 0xc0c1c2c3, 0xc4c5c6c7, 0xc8c9cacb, 0xcccdcecf, 0xd0d1d2d3, 0xd4d5d6d7, 0xd8d9dadb, 0xdcdddedf
.word 0xe0e1e2e3, 0xe4e5e6e7, 0xe8e9eaeb, 0xecedeeef, 0xf0f1f2f3, 0xf4f5f6f7, 0xf8f9fafb, 0xfcfdfeff
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.word 0x40414243, 0x44454647, 0x48494a4b, 0x4c4d4e4f, 0x50515253, 0x54555657, 0x58595a5b, 0x5c5d5e5f
.word 0x60616263, 0x64656667, 0x68696a6b, 0x6c6d6e6f, 0x70717273, 0x74757677, 0x78797a7b, 0x7c7d7e7f
.word 0x80818283, 0x84858687, 0x88898a8b, 0x8c8d8e8f, 0x90919293, 0x94959697, 0x98999a9b, 0x9c9d9e9f
.word 0xa0a1a2a3, 0xa4a5a6a7, 0xa8a9aaab, 0xacadaeaf, 0xb0b1b2b3, 0xb4b5b6b7, 0xb8b9babb, 0xbcbdbebf
.word 0xc0c1c2c3, 0xc4c5c6c7, 0xc8c9cacb, 0xcccdcecf, 0xd0d1d2d3, 0xd4d5d6d7, 0xd8d9dadb, 0xdcdddedf
.word 0xe0e1e2e3, 0xe4e5e6e7, 0xe8e9eaeb, 0xecedeeef, 0xf0f1f2f3, 0xf4f5f6f7, 0xf8f9fafb, 0xfcfdfeff
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.word 0x40414243, 0x44454647, 0x48494a4b, 0x4c4d4e4f, 0x50515253, 0x54555657, 0x58595a5b, 0x5c5d5e5f
.word 0x60616263, 0x64656667, 0x68696a6b, 0x6c6d6e6f, 0x70717273, 0x74757677, 0x78797a7b, 0x7c7d7e7f
.word 0x80818283, 0x84858687, 0x88898a8b, 0x8c8d8e8f, 0x90919293, 0x94959697, 0x98999a9b, 0x9c9d9e9f
.word 0xa0a1a2a3, 0xa4a5a6a7, 0xa8a9aaab, 0xacadaeaf, 0xb0b1b2b3, 0xb4b5b6b7, 0xb8b9babb, 0xbcbdbebf
.word 0xc0c1c2c3, 0xc4c5c6c7, 0xc8c9cacb, 0xcccdcecf, 0xd0d1d2d3, 0xd4d5d6d7, 0xd8d9dadb, 0xdcdddedf
.word 0xe0e1e2e3, 0xe4e5e6e7, 0xe8e9eaeb, 0xecedeeef, 0xf0f1f2f3, 0xf4f5f6f7, 0xf8f9fafb, 0xfcfdfeff
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.word 0x40414243, 0x44454647, 0x48494a4b, 0x4c4d4e4f, 0x50515253, 0x54555657, 0x58595a5b, 0x5c5d5e5f
.word 0x60616263, 0x64656667, 0x68696a6b, 0x6c6d6e6f, 0x70717273, 0x74757677, 0x78797a7b, 0x7c7d7e7f
.word 0x80818283, 0x84858687, 0x88898a8b, 0x8c8d8e8f, 0x90919293, 0x94959697, 0x98999a9b, 0x9c9d9e9f
.word 0xa0a1a2a3, 0xa4a5a6a7, 0xa8a9aaab, 0xacadaeaf, 0xb0b1b2b3, 0xb4b5b6b7, 0xb8b9babb, 0xbcbdbebf
.word 0xc0c1c2c3, 0xc4c5c6c7, 0xc8c9cacb, 0xcccdcecf, 0xd0d1d2d3, 0xd4d5d6d7, 0xd8d9dadb, 0xdcdddedf
.word 0xe0e1e2e3, 0xe4e5e6e7, 0xe8e9eaeb, 0xecedeeef, 0xf0f1f2f3, 0xf4f5f6f7, 0xf8f9fafb, 0xfcfdfeff
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.word 0x40414243, 0x44454647, 0x48494a4b, 0x4c4d4e4f, 0x50515253, 0x54555657, 0x58595a5b, 0x5c5d5e5f
.word 0x60616263, 0x64656667, 0x68696a6b, 0x6c6d6e6f, 0x70717273, 0x74757677, 0x78797a7b, 0x7c7d7e7f
.word 0x80818283, 0x84858687, 0x88898a8b, 0x8c8d8e8f, 0x90919293, 0x94959697, 0x98999a9b, 0x9c9d9e9f
.word 0xa0a1a2a3, 0xa4a5a6a7, 0xa8a9aaab, 0xacadaeaf, 0xb0b1b2b3, 0xb4b5b6b7, 0xb8b9babb, 0xbcbdbebf
.word 0xc0c1c2c3, 0xc4c5c6c7, 0xc8c9cacb, 0xcccdcecf, 0xd0d1d2d3, 0xd4d5d6d7, 0xd8d9dadb, 0xdcdddedf
.word 0xe0e1e2e3, 0xe4e5e6e7, 0xe8e9eaeb, 0xecedeeef, 0xf0f1f2f3, 0xf4f5f6f7, 0xf8f9fafb, 0xfcfdfeff
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.word 0x40414243, 0x44454647, 0x48494a4b, 0x4c4d4e4f, 0x50515253, 0x54555657, 0x58595a5b, 0x5c5d5e5f
.word 0x60616263, 0x64656667, 0x68696a6b, 0x6c6d6e6f, 0x70717273, 0x74757677, 0x78797a7b, 0x7c7d7e7f
.word 0x80818283, 0x84858687, 0x88898a8b, 0x8c8d8e8f, 0x90919293, 0x94959697, 0x98999a9b, 0x9c9d9e9f
.word 0xa0a1a2a3, 0xa4a5a6a7, 0xa8a9aaab, 0xacadaeaf, 0xb0b1b2b3, 0xb4b5b6b7, 0xb8b9babb, 0xbcbdbebf
.word 0xc0c1c2c3, 0xc4c5c6c7, 0xc8c9cacb, 0xcccdcecf, 0xd0d1d2d3, 0xd4d5d6d7, 0xd8d9dadb, 0xdcdddedf
.word 0xe0e1e2e3, 0xe4e5e6e7, 0xe8e9eaeb, 0xecedeeef, 0xf0f1f2f3, 0xf4f5f6f7, 0xf8f9fafb, 0xfcfdfeff
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.word 0x40414243, 0x44454647, 0x48494a4b, 0x4c4d4e4f, 0x50515253, 0x54555657, 0x58595a5b, 0x5c5d5e5f
.word 0x60616263, 0x64656667, 0x68696a6b, 0x6c6d6e6f, 0x70717273, 0x74757677, 0x78797a7b, 0x7c7d7e7f
.word 0x80818283, 0x84858687, 0x88898a8b, 0x8c8d8e8f, 0x90919293, 0x94959697, 0x98999a9b, 0x9c9d9e9f
.word 0xa0a1a2a3, 0xa4a5a6a7, 0xa8a9aaab, 0xacadaeaf, 0xb0b1b2b3, 0xb4b5b6b7, 0xb8b9babb, 0xbcbdbebf
.word 0xc0c1c2c3, 0xc4c5c6c7, 0xc8c9cacb, 0xcccdcecf, 0xd0d1d2d3, 0xd4d5d6d7, 0xd8d9dadb, 0xdcdddedf
.word 0xe0e1e2e3, 0xe4e5e6e7, 0xe8e9eaeb, 0xecedeeef, 0xf0f1f2f3, 0xf4f5f6f7, 0xf8f9fafb, 0xfcfdfeff
.section .user_stack,"aw",@progbits;
.align 2
user_stack_start:
.rept 4999
.4byte 0x0
.endr
user_stack_end:
.4byte 0x0
.align 2
kernel_instr_start:
.text
.align 2
mtvec_handler:    
                  j j18_resume_trap_handler
illegal_instr_handler:
j18_resume_trap_handler:
                  csrr  x6, 0x341
                  lhu   x15, 0(x6)
                  andi  x15, x15, 3
                  li    x31, 3
                  bne   x15, x31, 1f
                  addi  x6, x6, 4
                  j     2f
1:                addi  x6, x6, 2
2:                csrw  0x341, x6
                  mret

.align 2
mmode_intr_handler:
                  csrr  x13, 0x300 # MSTATUS;
                  csrr  x13, 0x304 # MIE;
                  csrr  x13, 0x344 # MIP;
                  csrrc x13, 0x344, x13 # MIP;
                  lw x1, 4(x31)
                  lw x2, 8(x31)
                  lw x3, 12(x31)
                  lw x4, 16(x31)
                  lw x5, 20(x31)
                  lw x6, 24(x31)
                  lw x7, 28(x31)
                  lw x8, 32(x31)
                  lw x9, 36(x31)
                  lw x10, 40(x31)
                  lw x11, 44(x31)
                  lw x12, 48(x31)
                  lw x13, 52(x31)
                  lw x14, 56(x31)
                  lw x15, 60(x31)
                  lw x16, 64(x31)
                  lw x17, 68(x31)
                  lw x18, 72(x31)
                  lw x19, 76(x31)
                  lw x20, 80(x31)
                  lw x21, 84(x31)
                  lw x22, 88(x31)
                  lw x23, 92(x31)
                  lw x24, 96(x31)
                  lw x25, 100(x31)
                  lw x26, 104(x31)
                  lw x27, 108(x31)
                  lw x28, 112(x31)
                  lw x29, 116(x31)
                  lw x30, 120(x31)
                  lw x31, 124(x31)
                  addi x31, x31, 124
                  add x29, x31, zero
                  csrrw x31, 0x340, x31
                  mret;

kernel_instr_end: nop
.align 2
kernel_data_start:
.section .s_region_0,"aw",@progbits;
s_region_0:
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.word 0x40414243, 0x44454647, 0x48494a4b, 0x4c4d4e4f, 0x50515253, 0x54555657, 0x58595a5b, 0x5c5d5e5f
.word 0x60616263, 0x64656667, 0x68696a6b, 0x6c6d6e6f, 0x70717273, 0x74757677, 0x78797a7b, 0x7c7d7e7f
.word 0x80818283, 0x84858687, 0x88898a8b, 0x8c8d8e8f, 0x90919293, 0x94959697, 0x98999a9b, 0x9c9d9e9f
.word 0xa0a1a2a3, 0xa4a5a6a7, 0xa8a9aaab, 0xacadaeaf, 0xb0b1b2b3, 0xb4b5b6b7, 0xb8b9babb, 0xbcbdbebf
.word 0xc0c1c2c3, 0xc4c5c6c7, 0xc8c9cacb, 0xcccdcecf, 0xd0d1d2d3, 0xd4d5d6d7, 0xd8d9dadb, 0xdcdddedf
.word 0xe0e1e2e3, 0xe4e5e6e7, 0xe8e9eaeb, 0xecedeeef, 0xf0f1f2f3, 0xf4f5f6f7, 0xf8f9fafb, 0xfcfdfeff
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.word 0x40414243, 0x44454647, 0x48494a4b, 0x4c4d4e4f, 0x50515253, 0x54555657, 0x58595a5b, 0x5c5d5e5f
.word 0x60616263, 0x64656667, 0x68696a6b, 0x6c6d6e6f, 0x70717273, 0x74757677, 0x78797a7b, 0x7c7d7e7f
.word 0x80818283, 0x84858687, 0x88898a8b, 0x8c8d8e8f, 0x90919293, 0x94959697, 0x98999a9b, 0x9c9d9e9f
.word 0xa0a1a2a3, 0xa4a5a6a7, 0xa8a9aaab, 0xacadaeaf, 0xb0b1b2b3, 0xb4b5b6b7, 0xb8b9babb, 0xbcbdbebf
.word 0xc0c1c2c3, 0xc4c5c6c7, 0xc8c9cacb, 0xcccdcecf, 0xd0d1d2d3, 0xd4d5d6d7, 0xd8d9dadb, 0xdcdddedf
.word 0xe0e1e2e3, 0xe4e5e6e7, 0xe8e9eaeb, 0xecedeeef, 0xf0f1f2f3, 0xf4f5f6f7, 0xf8f9fafb, 0xfcfdfeff
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.word 0x40414243, 0x44454647, 0x48494a4b, 0x4c4d4e4f, 0x50515253, 0x54555657, 0x58595a5b, 0x5c5d5e5f
.word 0x60616263, 0x64656667, 0x68696a6b, 0x6c6d6e6f, 0x70717273, 0x74757677, 0x78797a7b, 0x7c7d7e7f
.word 0x80818283, 0x84858687, 0x88898a8b, 0x8c8d8e8f, 0x90919293, 0x94959697, 0x98999a9b, 0x9c9d9e9f
.word 0xa0a1a2a3, 0xa4a5a6a7, 0xa8a9aaab, 0xacadaeaf, 0xb0b1b2b3, 0xb4b5b6b7, 0xb8b9babb, 0xbcbdbebf
.word 0xc0c1c2c3, 0xc4c5c6c7, 0xc8c9cacb, 0xcccdcecf, 0xd0d1d2d3, 0xd4d5d6d7, 0xd8d9dadb, 0xdcdddedf
.word 0xe0e1e2e3, 0xe4e5e6e7, 0xe8e9eaeb, 0xecedeeef, 0xf0f1f2f3, 0xf4f5f6f7, 0xf8f9fafb, 0xfcfdfeff
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.word 0x40414243, 0x44454647, 0x48494a4b, 0x4c4d4e4f, 0x50515253, 0x54555657, 0x58595a5b, 0x5c5d5e5f
.word 0x60616263, 0x64656667, 0x68696a6b, 0x6c6d6e6f, 0x70717273, 0x74757677, 0x78797a7b, 0x7c7d7e7f
.word 0x80818283, 0x84858687, 0x88898a8b, 0x8c8d8e8f, 0x90919293, 0x94959697, 0x98999a9b, 0x9c9d9e9f
.word 0xa0a1a2a3, 0xa4a5a6a7, 0xa8a9aaab, 0xacadaeaf, 0xb0b1b2b3, 0xb4b5b6b7, 0xb8b9babb, 0xbcbdbebf
.word 0xc0c1c2c3, 0xc4c5c6c7, 0xc8c9cacb, 0xcccdcecf, 0xd0d1d2d3, 0xd4d5d6d7, 0xd8d9dadb, 0xdcdddedf
.word 0xe0e1e2e3, 0xe4e5e6e7, 0xe8e9eaeb, 0xecedeeef, 0xf0f1f2f3, 0xf4f5f6f7, 0xf8f9fafb, 0xfcfdfeff
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.word 0x40414243, 0x44454647, 0x48494a4b, 0x4c4d4e4f, 0x50515253, 0x54555657, 0x58595a5b, 0x5c5d5e5f
.word 0x60616263, 0x64656667, 0x68696a6b, 0x6c6d6e6f, 0x70717273, 0x74757677, 0x78797a7b, 0x7c7d7e7f
.word 0x80818283, 0x84858687, 0x88898a8b, 0x8c8d8e8f, 0x90919293, 0x94959697, 0x98999a9b, 0x9c9d9e9f
.word 0xa0a1a2a3, 0xa4a5a6a7, 0xa8a9aaab, 0xacadaeaf, 0xb0b1b2b3, 0xb4b5b6b7, 0xb8b9babb, 0xbcbdbebf
.word 0xc0c1c2c3, 0xc4c5c6c7, 0xc8c9cacb, 0xcccdcecf, 0xd0d1d2d3, 0xd4d5d6d7, 0xd8d9dadb, 0xdcdddedf
.word 0xe0e1e2e3, 0xe4e5e6e7, 0xe8e9eaeb, 0xecedeeef, 0xf0f1f2f3, 0xf4f5f6f7, 0xf8f9fafb, 0xfcfdfeff
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.word 0x40414243, 0x44454647, 0x48494a4b, 0x4c4d4e4f, 0x50515253, 0x54555657, 0x58595a5b, 0x5c5d5e5f
.word 0x60616263, 0x64656667, 0x68696a6b, 0x6c6d6e6f, 0x70717273, 0x74757677, 0x78797a7b, 0x7c7d7e7f
.word 0x80818283, 0x84858687, 0x88898a8b, 0x8c8d8e8f, 0x90919293, 0x94959697, 0x98999a9b, 0x9c9d9e9f
.word 0xa0a1a2a3, 0xa4a5a6a7, 0xa8a9aaab, 0xacadaeaf, 0xb0b1b2b3, 0xb4b5b6b7, 0xb8b9babb, 0xbcbdbebf
.word 0xc0c1c2c3, 0xc4c5c6c7, 0xc8c9cacb, 0xcccdcecf, 0xd0d1d2d3, 0xd4d5d6d7, 0xd8d9dadb, 0xdcdddedf
.word 0xe0e1e2e3, 0xe4e5e6e7, 0xe8e9eaeb, 0xecedeeef, 0xf0f1f2f3, 0xf4f5f6f7, 0xf8f9fafb, 0xfcfdfeff
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.word 0x40414243, 0x44454647, 0x48494a4b, 0x4c4d4e4f, 0x50515253, 0x54555657, 0x58595a5b, 0x5c5d5e5f
.word 0x60616263, 0x64656667, 0x68696a6b, 0x6c6d6e6f, 0x70717273, 0x74757677, 0x78797a7b, 0x7c7d7e7f
.word 0x80818283, 0x84858687, 0x88898a8b, 0x8c8d8e8f, 0x90919293, 0x94959697, 0x98999a9b, 0x9c9d9e9f
.word 0xa0a1a2a3, 0xa4a5a6a7, 0xa8a9aaab, 0xacadaeaf, 0xb0b1b2b3, 0xb4b5b6b7, 0xb8b9babb, 0xbcbdbebf
.word 0xc0c1c2c3, 0xc4c5c6c7, 0xc8c9cacb, 0xcccdcecf, 0xd0d1d2d3, 0xd4d5d6d7, 0xd8d9dadb, 0xdcdddedf
.word 0xe0e1e2e3, 0xe4e5e6e7, 0xe8e9eaeb, 0xecedeeef, 0xf0f1f2f3, 0xf4f5f6f7, 0xf8f9fafb, 0xfcfdfeff
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.word 0x40414243, 0x44454647, 0x48494a4b, 0x4c4d4e4f, 0x50515253, 0x54555657, 0x58595a5b, 0x5c5d5e5f
.word 0x60616263, 0x64656667, 0x68696a6b, 0x6c6d6e6f, 0x70717273, 0x74757677, 0x78797a7b, 0x7c7d7e7f
.word 0x80818283, 0x84858687, 0x88898a8b, 0x8c8d8e8f, 0x90919293, 0x94959697, 0x98999a9b, 0x9c9d9e9f
.word 0xa0a1a2a3, 0xa4a5a6a7, 0xa8a9aaab, 0xacadaeaf, 0xb0b1b2b3, 0xb4b5b6b7, 0xb8b9babb, 0xbcbdbebf
.word 0xc0c1c2c3, 0xc4c5c6c7, 0xc8c9cacb, 0xcccdcecf, 0xd0d1d2d3, 0xd4d5d6d7, 0xd8d9dadb, 0xdcdddedf
.word 0xe0e1e2e3, 0xe4e5e6e7, 0xe8e9eaeb, 0xecedeeef, 0xf0f1f2f3, 0xf4f5f6f7, 0xf8f9fafb, 0xfcfdfeff
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.word 0x40414243, 0x44454647, 0x48494a4b, 0x4c4d4e4f, 0x50515253, 0x54555657, 0x58595a5b, 0x5c5d5e5f
.word 0x60616263, 0x64656667, 0x68696a6b, 0x6c6d6e6f, 0x70717273, 0x74757677, 0x78797a7b, 0x7c7d7e7f
.word 0x80818283, 0x84858687, 0x88898a8b, 0x8c8d8e8f, 0x90919293, 0x94959697, 0x98999a9b, 0x9c9d9e9f
.word 0xa0a1a2a3, 0xa4a5a6a7, 0xa8a9aaab, 0xacadaeaf, 0xb0b1b2b3, 0xb4b5b6b7, 0xb8b9babb, 0xbcbdbebf
.word 0xc0c1c2c3, 0xc4c5c6c7, 0xc8c9cacb, 0xcccdcecf, 0xd0d1d2d3, 0xd4d5d6d7, 0xd8d9dadb, 0xdcdddedf
.word 0xe0e1e2e3, 0xe4e5e6e7, 0xe8e9eaeb, 0xecedeeef, 0xf0f1f2f3, 0xf4f5f6f7, 0xf8f9fafb, 0xfcfdfeff
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.word 0x40414243, 0x44454647, 0x48494a4b, 0x4c4d4e4f, 0x50515253, 0x54555657, 0x58595a5b, 0x5c5d5e5f
.word 0x60616263, 0x64656667, 0x68696a6b, 0x6c6d6e6f, 0x70717273, 0x74757677, 0x78797a7b, 0x7c7d7e7f
.word 0x80818283, 0x84858687, 0x88898a8b, 0x8c8d8e8f, 0x90919293, 0x94959697, 0x98999a9b, 0x9c9d9e9f
.word 0xa0a1a2a3, 0xa4a5a6a7, 0xa8a9aaab, 0xacadaeaf, 0xb0b1b2b3, 0xb4b5b6b7, 0xb8b9babb, 0xbcbdbebf
.word 0xc0c1c2c3, 0xc4c5c6c7, 0xc8c9cacb, 0xcccdcecf, 0xd0d1d2d3, 0xd4d5d6d7, 0xd8d9dadb, 0xdcdddedf
.word 0xe0e1e2e3, 0xe4e5e6e7, 0xe8e9eaeb, 0xecedeeef, 0xf0f1f2f3, 0xf4f5f6f7, 0xf8f9fafb, 0xfcfdfeff
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.word 0x40414243, 0x44454647, 0x48494a4b, 0x4c4d4e4f, 0x50515253, 0x54555657, 0x58595a5b, 0x5c5d5e5f
.word 0x60616263, 0x64656667, 0x68696a6b, 0x6c6d6e6f, 0x70717273, 0x74757677, 0x78797a7b, 0x7c7d7e7f
.word 0x80818283, 0x84858687, 0x88898a8b, 0x8c8d8e8f, 0x90919293, 0x94959697, 0x98999a9b, 0x9c9d9e9f
.word 0xa0a1a2a3, 0xa4a5a6a7, 0xa8a9aaab, 0xacadaeaf, 0xb0b1b2b3, 0xb4b5b6b7, 0xb8b9babb, 0xbcbdbebf
.word 0xc0c1c2c3, 0xc4c5c6c7, 0xc8c9cacb, 0xcccdcecf, 0xd0d1d2d3, 0xd4d5d6d7, 0xd8d9dadb, 0xdcdddedf
.word 0xe0e1e2e3, 0xe4e5e6e7, 0xe8e9eaeb, 0xecedeeef, 0xf0f1f2f3, 0xf4f5f6f7, 0xf8f9fafb, 0xfcfdfeff
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.word 0x40414243, 0x44454647, 0x48494a4b, 0x4c4d4e4f, 0x50515253, 0x54555657, 0x58595a5b, 0x5c5d5e5f
.word 0x60616263, 0x64656667, 0x68696a6b, 0x6c6d6e6f, 0x70717273, 0x74757677, 0x78797a7b, 0x7c7d7e7f
.word 0x80818283, 0x84858687, 0x88898a8b, 0x8c8d8e8f, 0x90919293, 0x94959697, 0x98999a9b, 0x9c9d9e9f
.word 0xa0a1a2a3, 0xa4a5a6a7, 0xa8a9aaab, 0xacadaeaf, 0xb0b1b2b3, 0xb4b5b6b7, 0xb8b9babb, 0xbcbdbebf
.word 0xc0c1c2c3, 0xc4c5c6c7, 0xc8c9cacb, 0xcccdcecf, 0xd0d1d2d3, 0xd4d5d6d7, 0xd8d9dadb, 0xdcdddedf
.word 0xe0e1e2e3, 0xe4e5e6e7, 0xe8e9eaeb, 0xecedeeef, 0xf0f1f2f3, 0xf4f5f6f7, 0xf8f9fafb, 0xfcfdfeff
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.word 0x40414243, 0x44454647, 0x48494a4b, 0x4c4d4e4f, 0x50515253, 0x54555657, 0x58595a5b, 0x5c5d5e5f
.word 0x60616263, 0x64656667, 0x68696a6b, 0x6c6d6e6f, 0x70717273, 0x74757677, 0x78797a7b, 0x7c7d7e7f
.word 0x80818283, 0x84858687, 0x88898a8b, 0x8c8d8e8f, 0x90919293, 0x94959697, 0x98999a9b, 0x9c9d9e9f
.word 0xa0a1a2a3, 0xa4a5a6a7, 0xa8a9aaab, 0xacadaeaf, 0xb0b1b2b3, 0xb4b5b6b7, 0xb8b9babb, 0xbcbdbebf
.word 0xc0c1c2c3, 0xc4c5c6c7, 0xc8c9cacb, 0xcccdcecf, 0xd0d1d2d3, 0xd4d5d6d7, 0xd8d9dadb, 0xdcdddedf
.word 0xe0e1e2e3, 0xe4e5e6e7, 0xe8e9eaeb, 0xecedeeef, 0xf0f1f2f3, 0xf4f5f6f7, 0xf8f9fafb, 0xfcfdfeff
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.word 0x40414243, 0x44454647, 0x48494a4b, 0x4c4d4e4f, 0x50515253, 0x54555657, 0x58595a5b, 0x5c5d5e5f
.word 0x60616263, 0x64656667, 0x68696a6b, 0x6c6d6e6f, 0x70717273, 0x74757677, 0x78797a7b, 0x7c7d7e7f
.word 0x80818283, 0x84858687, 0x88898a8b, 0x8c8d8e8f, 0x90919293, 0x94959697, 0x98999a9b, 0x9c9d9e9f
.word 0xa0a1a2a3, 0xa4a5a6a7, 0xa8a9aaab, 0xacadaeaf, 0xb0b1b2b3, 0xb4b5b6b7, 0xb8b9babb, 0xbcbdbebf
.word 0xc0c1c2c3, 0xc4c5c6c7, 0xc8c9cacb, 0xcccdcecf, 0xd0d1d2d3, 0xd4d5d6d7, 0xd8d9dadb, 0xdcdddedf
.word 0xe0e1e2e3, 0xe4e5e6e7, 0xe8e9eaeb, 0xecedeeef, 0xf0f1f2f3, 0xf4f5f6f7, 0xf8f9fafb, 0xfcfdfeff
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.word 0x40414243, 0x44454647, 0x48494a4b, 0x4c4d4e4f, 0x50515253, 0x54555657, 0x58595a5b, 0x5c5d5e5f
.word 0x60616263, 0x64656667, 0x68696a6b, 0x6c6d6e6f, 0x70717273, 0x74757677, 0x78797a7b, 0x7c7d7e7f
.word 0x80818283, 0x84858687, 0x88898a8b, 0x8c8d8e8f, 0x90919293, 0x94959697, 0x98999a9b, 0x9c9d9e9f
.word 0xa0a1a2a3, 0xa4a5a6a7, 0xa8a9aaab, 0xacadaeaf, 0xb0b1b2b3, 0xb4b5b6b7, 0xb8b9babb, 0xbcbdbebf
.word 0xc0c1c2c3, 0xc4c5c6c7, 0xc8c9cacb, 0xcccdcecf, 0xd0d1d2d3, 0xd4d5d6d7, 0xd8d9dadb, 0xdcdddedf
.word 0xe0e1e2e3, 0xe4e5e6e7, 0xe8e9eaeb, 0xecedeeef, 0xf0f1f2f3, 0xf4f5f6f7, 0xf8f9fafb, 0xfcfdfeff
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.word 0x40414243, 0x44454647, 0x48494a4b, 0x4c4d4e4f, 0x50515253, 0x54555657, 0x58595a5b, 0x5c5d5e5f
.word 0x60616263, 0x64656667, 0x68696a6b, 0x6c6d6e6f, 0x70717273, 0x74757677, 0x78797a7b, 0x7c7d7e7f
.word 0x80818283, 0x84858687, 0x88898a8b, 0x8c8d8e8f, 0x90919293, 0x94959697, 0x98999a9b, 0x9c9d9e9f
.word 0xa0a1a2a3, 0xa4a5a6a7, 0xa8a9aaab, 0xacadaeaf, 0xb0b1b2b3, 0xb4b5b6b7, 0xb8b9babb, 0xbcbdbebf
.word 0xc0c1c2c3, 0xc4c5c6c7, 0xc8c9cacb, 0xcccdcecf, 0xd0d1d2d3, 0xd4d5d6d7, 0xd8d9dadb, 0xdcdddedf
.word 0xe0e1e2e3, 0xe4e5e6e7, 0xe8e9eaeb, 0xecedeeef, 0xf0f1f2f3, 0xf4f5f6f7, 0xf8f9fafb, 0xfcfdfeff
.section .s_region_1,"aw",@progbits;
s_region_1:
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.word 0x40414243, 0x44454647, 0x48494a4b, 0x4c4d4e4f, 0x50515253, 0x54555657, 0x58595a5b, 0x5c5d5e5f
.word 0x60616263, 0x64656667, 0x68696a6b, 0x6c6d6e6f, 0x70717273, 0x74757677, 0x78797a7b, 0x7c7d7e7f
.word 0x80818283, 0x84858687, 0x88898a8b, 0x8c8d8e8f, 0x90919293, 0x94959697, 0x98999a9b, 0x9c9d9e9f
.word 0xa0a1a2a3, 0xa4a5a6a7, 0xa8a9aaab, 0xacadaeaf, 0xb0b1b2b3, 0xb4b5b6b7, 0xb8b9babb, 0xbcbdbebf
.word 0xc0c1c2c3, 0xc4c5c6c7, 0xc8c9cacb, 0xcccdcecf, 0xd0d1d2d3, 0xd4d5d6d7, 0xd8d9dadb, 0xdcdddedf
.word 0xe0e1e2e3, 0xe4e5e6e7, 0xe8e9eaeb, 0xecedeeef, 0xf0f1f2f3, 0xf4f5f6f7, 0xf8f9fafb, 0xfcfdfeff
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.word 0x40414243, 0x44454647, 0x48494a4b, 0x4c4d4e4f, 0x50515253, 0x54555657, 0x58595a5b, 0x5c5d5e5f
.word 0x60616263, 0x64656667, 0x68696a6b, 0x6c6d6e6f, 0x70717273, 0x74757677, 0x78797a7b, 0x7c7d7e7f
.word 0x80818283, 0x84858687, 0x88898a8b, 0x8c8d8e8f, 0x90919293, 0x94959697, 0x98999a9b, 0x9c9d9e9f
.word 0xa0a1a2a3, 0xa4a5a6a7, 0xa8a9aaab, 0xacadaeaf, 0xb0b1b2b3, 0xb4b5b6b7, 0xb8b9babb, 0xbcbdbebf
.word 0xc0c1c2c3, 0xc4c5c6c7, 0xc8c9cacb, 0xcccdcecf, 0xd0d1d2d3, 0xd4d5d6d7, 0xd8d9dadb, 0xdcdddedf
.word 0xe0e1e2e3, 0xe4e5e6e7, 0xe8e9eaeb, 0xecedeeef, 0xf0f1f2f3, 0xf4f5f6f7, 0xf8f9fafb, 0xfcfdfeff
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.word 0x40414243, 0x44454647, 0x48494a4b, 0x4c4d4e4f, 0x50515253, 0x54555657, 0x58595a5b, 0x5c5d5e5f
.word 0x60616263, 0x64656667, 0x68696a6b, 0x6c6d6e6f, 0x70717273, 0x74757677, 0x78797a7b, 0x7c7d7e7f
.word 0x80818283, 0x84858687, 0x88898a8b, 0x8c8d8e8f, 0x90919293, 0x94959697, 0x98999a9b, 0x9c9d9e9f
.word 0xa0a1a2a3, 0xa4a5a6a7, 0xa8a9aaab, 0xacadaeaf, 0xb0b1b2b3, 0xb4b5b6b7, 0xb8b9babb, 0xbcbdbebf
.word 0xc0c1c2c3, 0xc4c5c6c7, 0xc8c9cacb, 0xcccdcecf, 0xd0d1d2d3, 0xd4d5d6d7, 0xd8d9dadb, 0xdcdddedf
.word 0xe0e1e2e3, 0xe4e5e6e7, 0xe8e9eaeb, 0xecedeeef, 0xf0f1f2f3, 0xf4f5f6f7, 0xf8f9fafb, 0xfcfdfeff
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.word 0x40414243, 0x44454647, 0x48494a4b, 0x4c4d4e4f, 0x50515253, 0x54555657, 0x58595a5b, 0x5c5d5e5f
.word 0x60616263, 0x64656667, 0x68696a6b, 0x6c6d6e6f, 0x70717273, 0x74757677, 0x78797a7b, 0x7c7d7e7f
.word 0x80818283, 0x84858687, 0x88898a8b, 0x8c8d8e8f, 0x90919293, 0x94959697, 0x98999a9b, 0x9c9d9e9f
.word 0xa0a1a2a3, 0xa4a5a6a7, 0xa8a9aaab, 0xacadaeaf, 0xb0b1b2b3, 0xb4b5b6b7, 0xb8b9babb, 0xbcbdbebf
.word 0xc0c1c2c3, 0xc4c5c6c7, 0xc8c9cacb, 0xcccdcecf, 0xd0d1d2d3, 0xd4d5d6d7, 0xd8d9dadb, 0xdcdddedf
.word 0xe0e1e2e3, 0xe4e5e6e7, 0xe8e9eaeb, 0xecedeeef, 0xf0f1f2f3, 0xf4f5f6f7, 0xf8f9fafb, 0xfcfdfeff
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.word 0x40414243, 0x44454647, 0x48494a4b, 0x4c4d4e4f, 0x50515253, 0x54555657, 0x58595a5b, 0x5c5d5e5f
.word 0x60616263, 0x64656667, 0x68696a6b, 0x6c6d6e6f, 0x70717273, 0x74757677, 0x78797a7b, 0x7c7d7e7f
.word 0x80818283, 0x84858687, 0x88898a8b, 0x8c8d8e8f, 0x90919293, 0x94959697, 0x98999a9b, 0x9c9d9e9f
.word 0xa0a1a2a3, 0xa4a5a6a7, 0xa8a9aaab, 0xacadaeaf, 0xb0b1b2b3, 0xb4b5b6b7, 0xb8b9babb, 0xbcbdbebf
.word 0xc0c1c2c3, 0xc4c5c6c7, 0xc8c9cacb, 0xcccdcecf, 0xd0d1d2d3, 0xd4d5d6d7, 0xd8d9dadb, 0xdcdddedf
.word 0xe0e1e2e3, 0xe4e5e6e7, 0xe8e9eaeb, 0xecedeeef, 0xf0f1f2f3, 0xf4f5f6f7, 0xf8f9fafb, 0xfcfdfeff
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.word 0x40414243, 0x44454647, 0x48494a4b, 0x4c4d4e4f, 0x50515253, 0x54555657, 0x58595a5b, 0x5c5d5e5f
.word 0x60616263, 0x64656667, 0x68696a6b, 0x6c6d6e6f, 0x70717273, 0x74757677, 0x78797a7b, 0x7c7d7e7f
.word 0x80818283, 0x84858687, 0x88898a8b, 0x8c8d8e8f, 0x90919293, 0x94959697, 0x98999a9b, 0x9c9d9e9f
.word 0xa0a1a2a3, 0xa4a5a6a7, 0xa8a9aaab, 0xacadaeaf, 0xb0b1b2b3, 0xb4b5b6b7, 0xb8b9babb, 0xbcbdbebf
.word 0xc0c1c2c3, 0xc4c5c6c7, 0xc8c9cacb, 0xcccdcecf, 0xd0d1d2d3, 0xd4d5d6d7, 0xd8d9dadb, 0xdcdddedf
.word 0xe0e1e2e3, 0xe4e5e6e7, 0xe8e9eaeb, 0xecedeeef, 0xf0f1f2f3, 0xf4f5f6f7, 0xf8f9fafb, 0xfcfdfeff
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.word 0x40414243, 0x44454647, 0x48494a4b, 0x4c4d4e4f, 0x50515253, 0x54555657, 0x58595a5b, 0x5c5d5e5f
.word 0x60616263, 0x64656667, 0x68696a6b, 0x6c6d6e6f, 0x70717273, 0x74757677, 0x78797a7b, 0x7c7d7e7f
.word 0x80818283, 0x84858687, 0x88898a8b, 0x8c8d8e8f, 0x90919293, 0x94959697, 0x98999a9b, 0x9c9d9e9f
.word 0xa0a1a2a3, 0xa4a5a6a7, 0xa8a9aaab, 0xacadaeaf, 0xb0b1b2b3, 0xb4b5b6b7, 0xb8b9babb, 0xbcbdbebf
.word 0xc0c1c2c3, 0xc4c5c6c7, 0xc8c9cacb, 0xcccdcecf, 0xd0d1d2d3, 0xd4d5d6d7, 0xd8d9dadb, 0xdcdddedf
.word 0xe0e1e2e3, 0xe4e5e6e7, 0xe8e9eaeb, 0xecedeeef, 0xf0f1f2f3, 0xf4f5f6f7, 0xf8f9fafb, 0xfcfdfeff
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.word 0x40414243, 0x44454647, 0x48494a4b, 0x4c4d4e4f, 0x50515253, 0x54555657, 0x58595a5b, 0x5c5d5e5f
.word 0x60616263, 0x64656667, 0x68696a6b, 0x6c6d6e6f, 0x70717273, 0x74757677, 0x78797a7b, 0x7c7d7e7f
.word 0x80818283, 0x84858687, 0x88898a8b, 0x8c8d8e8f, 0x90919293, 0x94959697, 0x98999a9b, 0x9c9d9e9f
.word 0xa0a1a2a3, 0xa4a5a6a7, 0xa8a9aaab, 0xacadaeaf, 0xb0b1b2b3, 0xb4b5b6b7, 0xb8b9babb, 0xbcbdbebf
.word 0xc0c1c2c3, 0xc4c5c6c7, 0xc8c9cacb, 0xcccdcecf, 0xd0d1d2d3, 0xd4d5d6d7, 0xd8d9dadb, 0xdcdddedf
.word 0xe0e1e2e3, 0xe4e5e6e7, 0xe8e9eaeb, 0xecedeeef, 0xf0f1f2f3, 0xf4f5f6f7, 0xf8f9fafb, 0xfcfdfeff
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.word 0x40414243, 0x44454647, 0x48494a4b, 0x4c4d4e4f, 0x50515253, 0x54555657, 0x58595a5b, 0x5c5d5e5f
.word 0x60616263, 0x64656667, 0x68696a6b, 0x6c6d6e6f, 0x70717273, 0x74757677, 0x78797a7b, 0x7c7d7e7f
.word 0x80818283, 0x84858687, 0x88898a8b, 0x8c8d8e8f, 0x90919293, 0x94959697, 0x98999a9b, 0x9c9d9e9f
.word 0xa0a1a2a3, 0xa4a5a6a7, 0xa8a9aaab, 0xacadaeaf, 0xb0b1b2b3, 0xb4b5b6b7, 0xb8b9babb, 0xbcbdbebf
.word 0xc0c1c2c3, 0xc4c5c6c7, 0xc8c9cacb, 0xcccdcecf, 0xd0d1d2d3, 0xd4d5d6d7, 0xd8d9dadb, 0xdcdddedf
.word 0xe0e1e2e3, 0xe4e5e6e7, 0xe8e9eaeb, 0xecedeeef, 0xf0f1f2f3, 0xf4f5f6f7, 0xf8f9fafb, 0xfcfdfeff
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.word 0x40414243, 0x44454647, 0x48494a4b, 0x4c4d4e4f, 0x50515253, 0x54555657, 0x58595a5b, 0x5c5d5e5f
.word 0x60616263, 0x64656667, 0x68696a6b, 0x6c6d6e6f, 0x70717273, 0x74757677, 0x78797a7b, 0x7c7d7e7f
.word 0x80818283, 0x84858687, 0x88898a8b, 0x8c8d8e8f, 0x90919293, 0x94959697, 0x98999a9b, 0x9c9d9e9f
.word 0xa0a1a2a3, 0xa4a5a6a7, 0xa8a9aaab, 0xacadaeaf, 0xb0b1b2b3, 0xb4b5b6b7, 0xb8b9babb, 0xbcbdbebf
.word 0xc0c1c2c3, 0xc4c5c6c7, 0xc8c9cacb, 0xcccdcecf, 0xd0d1d2d3, 0xd4d5d6d7, 0xd8d9dadb, 0xdcdddedf
.word 0xe0e1e2e3, 0xe4e5e6e7, 0xe8e9eaeb, 0xecedeeef, 0xf0f1f2f3, 0xf4f5f6f7, 0xf8f9fafb, 0xfcfdfeff
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.word 0x40414243, 0x44454647, 0x48494a4b, 0x4c4d4e4f, 0x50515253, 0x54555657, 0x58595a5b, 0x5c5d5e5f
.word 0x60616263, 0x64656667, 0x68696a6b, 0x6c6d6e6f, 0x70717273, 0x74757677, 0x78797a7b, 0x7c7d7e7f
.word 0x80818283, 0x84858687, 0x88898a8b, 0x8c8d8e8f, 0x90919293, 0x94959697, 0x98999a9b, 0x9c9d9e9f
.word 0xa0a1a2a3, 0xa4a5a6a7, 0xa8a9aaab, 0xacadaeaf, 0xb0b1b2b3, 0xb4b5b6b7, 0xb8b9babb, 0xbcbdbebf
.word 0xc0c1c2c3, 0xc4c5c6c7, 0xc8c9cacb, 0xcccdcecf, 0xd0d1d2d3, 0xd4d5d6d7, 0xd8d9dadb, 0xdcdddedf
.word 0xe0e1e2e3, 0xe4e5e6e7, 0xe8e9eaeb, 0xecedeeef, 0xf0f1f2f3, 0xf4f5f6f7, 0xf8f9fafb, 0xfcfdfeff
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.word 0x40414243, 0x44454647, 0x48494a4b, 0x4c4d4e4f, 0x50515253, 0x54555657, 0x58595a5b, 0x5c5d5e5f
.word 0x60616263, 0x64656667, 0x68696a6b, 0x6c6d6e6f, 0x70717273, 0x74757677, 0x78797a7b, 0x7c7d7e7f
.word 0x80818283, 0x84858687, 0x88898a8b, 0x8c8d8e8f, 0x90919293, 0x94959697, 0x98999a9b, 0x9c9d9e9f
.word 0xa0a1a2a3, 0xa4a5a6a7, 0xa8a9aaab, 0xacadaeaf, 0xb0b1b2b3, 0xb4b5b6b7, 0xb8b9babb, 0xbcbdbebf
.word 0xc0c1c2c3, 0xc4c5c6c7, 0xc8c9cacb, 0xcccdcecf, 0xd0d1d2d3, 0xd4d5d6d7, 0xd8d9dadb, 0xdcdddedf
.word 0xe0e1e2e3, 0xe4e5e6e7, 0xe8e9eaeb, 0xecedeeef, 0xf0f1f2f3, 0xf4f5f6f7, 0xf8f9fafb, 0xfcfdfeff
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.word 0x40414243, 0x44454647, 0x48494a4b, 0x4c4d4e4f, 0x50515253, 0x54555657, 0x58595a5b, 0x5c5d5e5f
.word 0x60616263, 0x64656667, 0x68696a6b, 0x6c6d6e6f, 0x70717273, 0x74757677, 0x78797a7b, 0x7c7d7e7f
.word 0x80818283, 0x84858687, 0x88898a8b, 0x8c8d8e8f, 0x90919293, 0x94959697, 0x98999a9b, 0x9c9d9e9f
.word 0xa0a1a2a3, 0xa4a5a6a7, 0xa8a9aaab, 0xacadaeaf, 0xb0b1b2b3, 0xb4b5b6b7, 0xb8b9babb, 0xbcbdbebf
.word 0xc0c1c2c3, 0xc4c5c6c7, 0xc8c9cacb, 0xcccdcecf, 0xd0d1d2d3, 0xd4d5d6d7, 0xd8d9dadb, 0xdcdddedf
.word 0xe0e1e2e3, 0xe4e5e6e7, 0xe8e9eaeb, 0xecedeeef, 0xf0f1f2f3, 0xf4f5f6f7, 0xf8f9fafb, 0xfcfdfeff
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.word 0x40414243, 0x44454647, 0x48494a4b, 0x4c4d4e4f, 0x50515253, 0x54555657, 0x58595a5b, 0x5c5d5e5f
.word 0x60616263, 0x64656667, 0x68696a6b, 0x6c6d6e6f, 0x70717273, 0x74757677, 0x78797a7b, 0x7c7d7e7f
.word 0x80818283, 0x84858687, 0x88898a8b, 0x8c8d8e8f, 0x90919293, 0x94959697, 0x98999a9b, 0x9c9d9e9f
.word 0xa0a1a2a3, 0xa4a5a6a7, 0xa8a9aaab, 0xacadaeaf, 0xb0b1b2b3, 0xb4b5b6b7, 0xb8b9babb, 0xbcbdbebf
.word 0xc0c1c2c3, 0xc4c5c6c7, 0xc8c9cacb, 0xcccdcecf, 0xd0d1d2d3, 0xd4d5d6d7, 0xd8d9dadb, 0xdcdddedf
.word 0xe0e1e2e3, 0xe4e5e6e7, 0xe8e9eaeb, 0xecedeeef, 0xf0f1f2f3, 0xf4f5f6f7, 0xf8f9fafb, 0xfcfdfeff
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.word 0x40414243, 0x44454647, 0x48494a4b, 0x4c4d4e4f, 0x50515253, 0x54555657, 0x58595a5b, 0x5c5d5e5f
.word 0x60616263, 0x64656667, 0x68696a6b, 0x6c6d6e6f, 0x70717273, 0x74757677, 0x78797a7b, 0x7c7d7e7f
.word 0x80818283, 0x84858687, 0x88898a8b, 0x8c8d8e8f, 0x90919293, 0x94959697, 0x98999a9b, 0x9c9d9e9f
.word 0xa0a1a2a3, 0xa4a5a6a7, 0xa8a9aaab, 0xacadaeaf, 0xb0b1b2b3, 0xb4b5b6b7, 0xb8b9babb, 0xbcbdbebf
.word 0xc0c1c2c3, 0xc4c5c6c7, 0xc8c9cacb, 0xcccdcecf, 0xd0d1d2d3, 0xd4d5d6d7, 0xd8d9dadb, 0xdcdddedf
.word 0xe0e1e2e3, 0xe4e5e6e7, 0xe8e9eaeb, 0xecedeeef, 0xf0f1f2f3, 0xf4f5f6f7, 0xf8f9fafb, 0xfcfdfeff
.word 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f, 0x10111213, 0x14151617, 0x18191a1b, 0x1c1d1e1f
.word 0x20212223, 0x24252627, 0x28292a2b, 0x2c2d2e2f, 0x30313233, 0x34353637, 0x38393a3b, 0x3c3d3e3f
.word 0x40414243, 0x44454647, 0x48494a4b, 0x4c4d4e4f, 0x50515253, 0x54555657, 0x58595a5b, 0x5c5d5e5f
.word 0x60616263, 0x64656667, 0x68696a6b, 0x6c6d6e6f, 0x70717273, 0x74757677, 0x78797a7b, 0x7c7d7e7f
.word 0x80818283, 0x84858687, 0x88898a8b, 0x8c8d8e8f, 0x90919293, 0x94959697, 0x98999a9b, 0x9c9d9e9f
.word 0xa0a1a2a3, 0xa4a5a6a7, 0xa8a9aaab, 0xacadaeaf, 0xb0b1b2b3, 0xb4b5b6b7, 0xb8b9babb, 0xbcbdbebf
.word 0xc0c1c2c3, 0xc4c5c6c7, 0xc8c9cacb, 0xcccdcecf, 0xd0d1d2d3, 0xd4d5d6d7, 0xd8d9dadb, 0xdcdddedf
.word 0xe0e1e2e3, 0xe4e5e6e7, 0xe8e9eaeb, 0xecedeeef, 0xf0f1f2f3, 0xf4f5f6f7, 0xf8f9fafb, 0xfcfdfeff
.section .kernel_stack,"aw",@progbits;
.align 2
kernel_stack_start:
.rept 4999
.4byte 0x0
.endr
kernel_stack_end:
.4byte 0x0

.section .data
.balign 8
zbcov_scratch:
.word 0, 0, 0, 0   # inject_zb aligned scratch (sp-independent)
