.include "user_define.h"
.globl _start
.section .text
_start:           
                  .include "user_init.s"
                  csrr x5, 0xf14
                  li x6, 0
                  beq x5, x6, 0f

0: la x8, h0_start
jalr x0, x8, 0
h0_start:
                  li x30, 0x40001104
                  nop  # adapt: misa write dropped (DUT misa is WARL read-only; Spike misa writable)
kernel_sp:        
                  la x31, kernel_stack_end

trap_vec_init:    
                  la x30, mtvec_handler
                  ori x30, x30, 0
                  csrw 0x305, x30 # MTVEC

mepc_setup:       
                  la x30, init
                  csrw 0x341, x30

init_machine_mode:
                  li x30, 0x1800
                  csrw 0x300, x30 # MSTATUS
                  li x30, 0x0
                  csrw 0x304, x30 # MIE
                  mret
init:             
                  li x0, 0x80000000
                  li x1, 0xf460f433
                  li x2, 0x80000000
                  li x3, 0xf3e7a9b8
                  li x4, 0x3
                  li x5, 0xc522588c
                  li x6, 0x0
                  li x7, 0xb
                  li x8, 0x5c394be1
                  li x9, 0xd
                  li x10, 0x80000000
                  li x11, 0x0
                  li x12, 0xe8a4a9b1
                  li x13, 0xe
                  li x14, 0xf4f8120e
                  li x15, 0x3ccfb644
                  li x16, 0x2cfa698c
                  li x17, 0xfb7591c3
                  li x18, 0xb
                  li x19, 0xf1f91741
                  li x20, 0xd0549321
                  li x21, 0x6
                  li x22, 0x29791079
                  li x23, 0x0
                  li x24, 0xf35e3ed2
                  li x25, 0x0
                  li x26, 0x80000000
                  li x27, 0xa
                  li x29, 0x80000000
                  li x30, 0xc9459044
                  la x28, user_stack_end
main:             c.slli      ra, 10
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
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  sh1add x31, x30, x31
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
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  sh2add x31, x30, x31
                  csrrw x6, 0x340, x0
                  andi        sp, s3, 1559
                  divu        s1, s4, a5
                  c.srai      a0, 21
                  c.addi4spn  a0, sp, 128
                  and         t1, sp, s8
                  lui         ra, 663836
                  sltu        a3, a5, t5
                  rem         a5, s8, s11
                  srli        a3, s4, 25
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  sh3add x31, x30, x31
                  c.bnez      a2, 13f
                  slt         a3, gp, t6
                  xor         a0, s1, t4
13:               c.addi4spn  a2, sp, 912
                  and         sp, t6, s3
                  c.srli      a2, 6
                  c.xor       a0, a3
                  c.li        a0, 24
                  slli        s1, s5, 5
                  c.beqz      a2, 30f
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  andn  x31, x30, x31
                  divu        a4, tp, a1
                  bge         s3, t0, 30f
                  xor         zero, ra, a2
                  mul         t0, s10, t0
                  sltu        t1, sp, t5
                  beq         t3, a4, 31f
                  mulh        zero, a3, ra
                  srli        zero, a5, 19
                  c.and       s1, a0
                  divu        a6, s10, ra
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
30:               ori         tp, t5, 617
31:               c.sub       a2, a1
                  ori         s11, a2, -1437
                  sll         a3, s1, a1
                  bltu        s5, t4, 40f
                  add         a5, t4, sp
                  sltu        sp, s0, s3
                  mulhu       a7, s9, s7
                  c.beqz      a3, 41f
                  beq         t2, s2, 49f
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  xnor  x31, x30, x31
40:               lui         t0, 628251
41:               sll         s10, s6, s0
                  c.beqz      a0, 54f
                  c.beqz      a2, 47f
                  and         zero, s1, s4
                  lui         a4, 376532
                  c.slli      a4, 13
47:               slti        a2, a7, 1346
                  c.lui       a1, 18
49:               addi        tp, a5, 175
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  clz   x31, x30
                  c.sub       a0, a1
                  bne         s2, s11, 61f
                  div         a4, s9, t4
                  and         a5, s10, t6
54:               slt         zero, t1, a2
                  div         s4, sp, a5
                  bltu        s5, a3, 60f
                  bge         zero, s2, 68f
                  c.xor       a1, a1
                  c.srli      a2, 16
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  ctz   x31, x30
                  .word 0xb52063   # reserved -> trap, rotate arms
60:               c.and       a2, a1
61:               mulh        s3, t4, t0
                  srl         zero, a2, t1
                  xori        a1, a5, -451
                  c.nop
                  bltu        s11, zero, 82f
                  addi        a2, s7, -38
                  c.and       a3, s1
68:               addi        s3, s5, 567
                  sltiu       zero, s5, -369
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  cpop  x31, x30
                  c.andi      a0, 14
                  sll         a3, s7, t6
                  beq         t0, t5, 89f
                  srai        t2, t4, 12
                  nop
                  slt         tp, tp, t1
                  divu        a6, zero, a3
                  div         s4, ra, t1
                  c.xor       a0, a0
                  c.lui       ra, 1
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
                  auipc       s8, 609963
                  andi        t1, t2, 944
82:               andi        s1, a4, 92
                  c.slli      a1, 29
                  c.beqz      a2, 85f
85:               sub         s7, gp, a5
                  div         s4, s4, s10
                  or          ra, s11, s10
                  c.xor       a3, a4
89:               div         t0, t5, tp
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  minu  x31, x30, x31
                  auipc       t0, 32025
                  mulh        s6, s1, a2
                  c.add       t4, t2
                  ori         s10, a0, 197
                  sra         t4, t3, t1
                  bltu        s8, s2, 109f
                  c.nop
                  c.nop
                  c.nop
                  c.srli      a2, 1
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  max   x31, x30, x31
                  .hword 0x2000  # C-illegal leg -> trap
                  .hword 0x0001
                  c.sub       a2, a0
                  bgeu        s4, t1, 116f
                  c.addi16sp  sp, -16
                  and         a1, s0, a3
                  c.andi      a2, 12
                  bne         s3, t1, 109f
                  divu        s8, s5, a7
                  mulhu       zero, s3, s10
                  srl         s7, t1, t4
109:              bgeu        a7, s7, 129f
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  maxu  x31, x30, x31
                  c.slli      s5, 8
                  sra         t5, sp, s9
                  sub         ra, s3, a0
                  mulh        t5, t0, s11
                  srai        s9, a2, 25
                  c.mv        tp, s8
116:              c.beqz      a3, 119f
                  srai        zero, t5, 27
                  mulhu       t2, t6, a2
119:              sltiu       s5, s6, 1877
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  sext.b x31, x30
                  csrw mscratch, ra
                  jal  ra, 82131f
                  jalr x0, 0(ra)     # wrong-path ret: IF pre-decode pop
82131:          csrr ra, mscratch
                  sll         a5, s11, t2
                  bne         a4, ra, 139f
                  c.srli      a0, 10
                  c.andi      a3, 22
                  c.lui       ra, 4
                  c.or        a3, a0
                  c.addi4spn  a2, sp, 272
                  bgeu        t0, t3, 130f
                  mul         t0, a3, t2
129:              c.li        s4, 16
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
130:              c.lui       a2, 7
                  sub         s11, a7, gp
                  c.lui       t1, 4
                  c.and       a2, s0
                  c.xor       a3, s1
                  nop
                  or          a1, a6, t5
                  sltiu       sp, t6, 558
                  sra         s1, s3, s2
139:              c.bnez      a3, 146f
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  zext.h x31, x30
                  .word 0xfeb50533   # reserved -> trap, rotate arms
                  c.lui       s2, 26
                  sltiu       zero, a1, -1792
                  bge         a0, a4, 162f
                  andi        tp, a2, -1660
                  c.lui       s6, 12
                  mulh        sp, a2, s0
146:              c.add       s11, a4
                  srli        s2, s10, 28
                  sra         a4, s10, t5
                  mulh        zero, t6, s11
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  rol   x31, x30, x31
                  c.bnez      a4, 165f
                  c.mv        ra, gp
                  sra         a6, zero, t3
                  slti        a4, s11, 329
                  and         a7, s6, zero
                  xor         zero, s1, a2
                  srai        a7, t0, 27
                  slti        t0, a1, -734
                  blt         t4, a5, 172f
                  blt         s10, a3, 167f
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  ror   x31, x30, x31
                  srl         a3, s5, s5
                  add         s10, t5, s6
162:              c.add       s2, a4
                  srai        t1, t3, 11
                  srli        a1, s1, 3
165:              c.add       t2, s2
                  c.add       s2, s2
167:              sltu        a4, gp, s8
                  srai        a5, a3, 16
                  or          a0, a6, t5
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  rori  x31, x30, 7
                  rem         gp, s8, s5
                  c.addi4spn  a2, sp, 160
172:              mulhu       zero, s10, s8
                  c.andi      s1, 17
                  c.add       t5, tp
                  slt         ra, a3, s4
                  slli        a0, s6, 11
                  slt         s9, t5, s8
                  c.addi4spn  a3, sp, 704
                  xori        zero, tp, 601
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  orc.b x31, x30
                  csrw mscratch, x30
                  csrrs x31, mscratch, x0
                  csrrc x31, mscratch, x0
                  c.beqz      a2, 181f
181:              c.beqz      a0, 195f
                  c.sub       a3, a0
                  xor         t4, t6, s3
                  c.andi      a2, 25
                  c.or        a0, a2
                  sub         t4, s5, ra
                  c.beqz      a1, 206f
                  srli        s11, t5, 8
                  slti        a3, t0, 563
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  rev8  x31, x30
                  c.sub       a2, s1
                  srai        s4, t1, 8
                  divu        t0, s5, t4
                  andi        a2, s2, 856
                  beq         a3, tp, 206f
195:              rem         a5, s6, zero
                  c.add       a3, s6
                  xori        a7, gp, -889
                  sra         s7, s11, a6
                  c.sub       a0, a0
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  bclr  x31, x30, x31
                  bge         t6, s7, 210f
                  c.mv        a3, s10
                  nop
                  sltiu       s3, s10, -1221
                  srl         a6, a1, a5
                  c.srai      a4, 3
206:              c.nop
                  ori         s1, t1, 523
                  srl         t2, sp, s9
                  and         a6, s3, zero
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  bext  x31, x30, x31
210:              c.sub       a3, a3
                  bgeu        t5, t3, 225f
                  c.andi      a3, -1
                  c.or        a2, s1
                  sltu        s9, t0, a4
                  xor         a3, a4, s4
                  slli        s8, s3, 10
                  bne         s8, s7, 234f
                  c.xor       a2, a1
                  rem         s6, s5, s7
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  binv  x31, x30, x31
                  .word 0x1eb55513   # reserved -> trap, rotate arms
                  c.addi      gp, 28
                  mulhu       s5, t3, t0
                  beq         zero, a0, 236f
                  c.addi      sp, -1
                  c.xor       a1, a2
225:              sra         t0, s7, a4
                  auipc       zero, 373075
                  ori         gp, t0, 722
                  xor         t1, a4, s1
                  auipc       s1, 772612
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
                  andi        s6, t3, 1533
                  slli        s7, t5, 19
                  srli        t4, tp, 20
                  srl         zero, s2, s5
234:              c.addi4spn  a2, sp, 960
                  bltu        s0, t6, 236f
236:              or          s1, s8, s11
                  sub         t0, t0, tp
                  mulhsu      s11, s7, a1
                  c.nop
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  bclri x31, x30, 31
                  divu        a6, t6, s4
                  c.add       s4, t1
                  srli        s4, s9, 20
                  sltu        s5, s1, a0
                  srai        sp, s2, 19
                  c.addi16sp  sp, 288
                  sltu        a1, gp, zero
                  c.add       a0, sp
                  mulhsu      zero, s10, tp
                  blt         t5, t5, 252f
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  bexti x31, x30, 15
                  lui         tp, 692440
                  c.nop
252:              sltiu       s4, a2, -751
                  nop
                  bge         t1, s10, 265f
                  beq         s1, t3, 270f
                  slt         s6, a2, s8
                  slli        s4, s7, 27
                  lui         s4, 1008574
                  c.add       s6, s9
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  binvi x31, x30, 0
                  slli        t0, s10, 3
                  nop
                  auipc       t2, 32540
                  blt         zero, a5, 271f
                  addi        a1, gp, 179
265:              div         a2, s9, a3
                  slti        a4, s2, -437
                  srli        s7, a5, 12
                  c.srli      a1, 10
                  mulhu       s9, a4, t5
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  bseti x31, x30, 31
270:              c.or        a0, a3
271:              c.sub       a2, a3
                  bltu        t4, t4, 275f
                  c.addi4spn  a0, sp, 400
                  nop
275:              c.addi16sp  sp, 96
                  srli        s2, tp, 11
                  c.bnez      a0, 281f
                  mulhu       s9, sp, s0
                  c.addi16sp  sp, -16
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
                  c.addi      s2, 13
281:              mulhsu      zero, s3, a4
                  c.and       a0, a3
                  beq         s1, t6, 298f
                  c.lui       s5, 20
                  ori         a3, s3, -239
                  slli        s3, s2, 19
                  and         a0, t2, s4
                  div         a6, t3, a1
                  sub         zero, s1, gp
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  czero.nez x31, x30, x31
                  add         s5, t3, s4
                  srli        a5, s9, 18
                  bltu        t3, s1, 309f
                  c.sub       a3, a0
                  c.slli      s11, 21
                  bltu        t3, s1, 304f
                  c.or        a3, a1
                  c.nop
298:              or          a2, a3, ra
                  c.srai      a2, 12
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  sh1add x31, x30, x31
                  .word 0x20b512b3   # reserved -> trap, rotate arms
                  div         sp, a2, t1
                  beq         a0, s7, 321f
                  c.slli      a0, 4
                  c.srai      a0, 3
304:              c.add       ra, ra
                  nop
                  div         sp, t1, gp
                  srai        s3, a7, 15
                  lui         sp, 104360
309:              mul         s10, s10, a2
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  sh2add x31, x30, x31
                  sll         s2, a7, a6
                  xori        zero, t0, 990
                  addi        zero, s6, 1798
                  srli        a1, s6, 9
                  srai        s9, a5, 22
                  c.srai      a2, 16
                  ori         a6, a1, 1659
                  divu        a5, s8, s7
                  c.add       a2, ra
                  c.andi      a2, -1
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  sh3add x31, x30, x31
                  sltiu       zero, s5, 1302
321:              c.mv        a4, s4
                  c.sub       a0, a1
                  c.bnez      a3, 327f
                  or          sp, a4, a0
                  sra         s3, s7, a3
                  srli        t4, s10, 18
327:              c.andi      a2, -1
                  rem         s8, s0, t3
                  xori        zero, a5, -212
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
                  slt         ra, sp, tp
                  ori         s6, t3, -1813
                  bge         a5, s0, 333f
333:              addi        zero, ra, 1131
                  div         ra, s8, s7
                  c.lui       a2, 30
                  divu        s6, t4, t6
                  c.or        a0, a1
                  c.add       ra, sp
                  bne         t0, s10, 345f
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  orn   x31, x30, x31
                  .hword 0xa000  # C-illegal leg -> trap
                  .hword 0x0001
                  c.beqz      a0, 344f
                  srai        t5, s8, 13
                  srli        a3, t2, 29
                  c.li        s5, 20
344:              bgeu        s4, a0, 364f
345:              xor         a7, s8, s7
                  mulhsu      a6, zero, s2
                  c.mv        t0, ra
                  srl         s3, s7, s1
                  c.addi      s5, 27
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  xnor  x31, x30, x31
                  c.addi16sp  sp, -16
                  sub         zero, s1, a3
                  c.li        s10, -1
                  c.sub       a0, a3
                  sll         s9, a5, a7
                  divu        s9, tp, a7
                  ori         tp, t2, -604
                  lui         s2, 233522
                  add         t1, t2, s2
                  xor         s1, s7, ra
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  clz   x31, x30
                  sub         zero, s0, s8
                  andi        t4, a4, -565
                  srai        t1, a5, 23
                  ori         s2, sp, 148
364:              mulhu       a2, t0, gp
                  slt         s10, s5, s2
                  c.addi16sp  sp, 480
                  c.add       a0, s11
                  addi        t4, s7, 544
                  divu        a0, s5, s4
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  ctz   x31, x30
                  mul         sp, gp, a4
                  mulh        zero, t5, s11
                  slt         s3, a4, tp
                  sra         s11, s3, s1
                  lui         gp, 313053
                  slti        t5, a3, -1085
                  andi        s5, gp, 1516
                  sll         s10, gp, t2
                  nop
                  sltiu       a2, s7, -2040
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  cpop  x31, x30
                  .word 0x40b53533   # reserved -> trap, rotate arms
                  csrw mscratch, x30
                  csrrs x31, mscratch, x0
                  csrrc x31, mscratch, x0
                  c.bnez      a1, 394f
                  c.lui       a6, 22
                  c.addi16sp  sp, -16
                  mulhu       a1, a2, a3
                  div         a6, s7, zero
                  c.andi      a0, 19
                  rem         s4, tp, s9
                  addi        sp, t5, 253
                  divu        zero, t3, a4
                  nop
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  min   x31, x30, x31
                  addi        a3, ra, -590
                  sra         t4, a6, s5
                  mulh        ra, tp, t3
                  c.and       a3, a3
394:              beq         t5, t1, 404f
                  sltiu       s6, t2, 193
                  c.mv        s2, sp
                  slt         s3, a2, s10
                  lui         s7, 194574
                  c.add       a2, s8
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  minu  x31, x30, x31
                  xor         a6, ra, ra
                  c.beqz      a2, 407f
                  c.addi4spn  a2, sp, 128
                  c.nop
404:              c.srli      a0, 14
                  c.xor       a2, s0
                  c.or        a2, a1
407:              slt         s3, t6, s3
                  bge         t0, t1, 415f
                  div         s7, a1, a7
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  max   x31, x30, x31
                  ori         zero, t1, -1448
                  sltiu       s3, tp, 517
                  sll         s8, gp, a5
                  c.addi16sp  sp, 256
                  divu        a4, t2, sp
415:              sltu        t2, s9, s1
                  c.lui       t4, 1
                  mulh        zero, s6, s7
                  addi        s10, s9, -54
                  and         s5, s5, a3
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  maxu  x31, x30, x31
                  mul         s5, s1, s8
                  c.sub       a0, a2
                  c.lui       a5, 20
                  bne         a6, a6, 426f
                  add         a0, sp, s10
                  slli        s5, s1, 16
426:              sltiu       s6, t5, 1506
                  xori        t2, ra, 1474
                  c.addi      t0, -1
                  mulhu       zero, t2, sp
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
                  and         s2, s8, s1
                  bgeu        ra, s9, 449f
                  c.slli      ra, 21
                  divu        a7, zero, s8
                  c.addi      s1, -1
                  sll         s5, a5, t2
                  lui         a7, 492798
                  div         t1, a0, t2
                  bltu        a6, a2, 449f
                  xor         t5, s10, s7
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  sext.h x31, x30
                  csrw mscratch, ra
                  jal  ra, 82451f
                  jalr x0, 0(ra)     # wrong-path ret: IF pre-decode pop
82451:          csrr ra, mscratch
                  sltu        a1, ra, s11
                  srai        zero, s1, 11
                  c.addi16sp  sp, 176
                  divu        a5, s6, s10
                  c.and       a1, a1
                  c.addi4spn  a2, sp, 272
                  sll         a7, s1, a1
                  sltiu       zero, s2, 584
                  c.srli      a2, 23
449:              addi        s4, s0, 1273
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  zext.h x31, x30
                  c.or        a3, s0
                  and         s3, a3, t2
                  xori        s11, s6, 1464
                  c.addi      s11, -1
                  c.add       s7, a7
                  c.andi      a2, 27
                  bne         s10, s10, 475f
                  auipc       a2, 769513
                  xor         t1, t3, s0
                  c.mv        s5, t6
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  rol   x31, x30, x31
                  .word 0xab50533   # reserved -> trap, rotate arms
                  c.xor       a0, a2
                  sltiu       s5, s7, 139
                  c.bnez      a1, 465f
                  c.srli      a0, 13
                  divu        a1, tp, t0
465:              or          zero, sp, s0
                  sra         s7, s7, t5
                  sll         s9, s1, a7
                  srl         s10, s10, a6
                  sra         a1, a6, s3
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  ror   x31, x30, x31
                  div         t0, a5, t6
                  c.xor       s1, a0
                  blt         s6, a4, 482f
                  blt         tp, t6, 477f
                  lui         s6, 538738
475:              srli        s5, s2, 19
                  c.addi4spn  a0, sp, 128
477:              and         s11, t2, a6
                  mul         tp, zero, t4
                  srli        zero, zero, 24
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
                  c.sub       a2, a1
                  c.bnez      a2, 501f
482:              xor         s8, a5, a6
                  ori         s2, zero, 481
                  srai        t2, a1, 26
                  sltu        tp, a6, a6
                  c.lui       a4, 14
                  c.xor       a0, a2
                  mul         s8, a0, s2
                  sub         t5, s7, s5
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  orc.b x31, x30
                  sltu        a5, t1, s9
                  bge         a4, s11, 505f
                  or          t0, s0, s3
                  bge         a5, s8, 510f
                  divu        gp, s6, a2
                  mulhu       t2, s9, s5
                  beq         a6, a4, 499f
                  lui         s11, 1000220
                  bgeu        s0, gp, 512f
499:              srl         ra, s6, s0
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  rev8  x31, x30
                  c.slli      s6, 23
501:              bltu        t5, s5, 502f
502:              bgeu        s0, t3, 510f
                  c.srai      a0, 29
                  slli        tp, s8, 29
505:              sltiu       s7, t0, 1854
                  slt         s5, s4, t6
                  c.addi      a2, 2
                  c.and       a2, a1
                  or          a5, a2, s9
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  bclr  x31, x30, x31
510:              c.beqz      a2, 516f
                  c.andi      a2, 17
512:              mul         zero, s6, s3
                  divu        s1, s0, t5
                  andi        t5, s0, -1669
                  bge         a4, s11, 533f
516:              slti        gp, s5, -1971
                  lui         a4, 999006
                  bne         s11, t3, 524f
                  lui         s3, 953048
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  bext  x31, x30, x31
                  nop
                  sra         a0, s5, zero
                  sub         a2, s2, t5
                  slli        gp, s1, 28
524:              beq         a2, s11, 525f
525:              sll         s3, ra, s0
                  c.add       s4, t1
                  ori         a0, s2, -1160
                  slti        a5, s7, -1439
                  bltu        a2, zero, 533f
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
                  c.sub       a3, a4
                  c.mv        sp, s1
                  c.sub       a2, a1
533:              c.addi4spn  a2, sp, 704
                  mulhu       a0, t2, a0
                  mul         a1, tp, s1
                  bne         t2, s7, 553f
                  beq         a6, a4, 548f
                  c.li        t2, 6
                  sra         s8, s8, s6
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  bset  x31, x30, x31
                  .word 0x60b52533   # reserved -> trap, rotate arms
                  div         ra, s3, a7
                  auipc       a6, 369104
                  c.and       a0, a1
                  rem         s4, a0, t1
                  sra         t1, t2, s1
                  lui         s3, 987746
                  sltu        t1, s9, t1
                  sll         s10, s4, a4
548:              mulhsu      zero, a7, s0
                  xor         a2, a1, s0
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  bclri x31, x30, 31
                  bltu        gp, s10, 553f
                  sra         a3, gp, tp
                  c.srli      a1, 22
553:              nop
                  mulhsu      tp, s11, s10
                  c.addi16sp  sp, 384
                  addi        a6, s6, -705
                  rem         tp, a7, s8
                  div         s6, s9, s6
                  c.lui       ra, 7
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  bexti x31, x30, 15
                  mul         s11, t5, t3
                  c.bnez      a2, 572f
                  c.slli      ra, 31
                  c.or        a2, a3
                  c.srli      s1, 7
                  srl         zero, t5, s9
                  srl         t0, t3, tp
                  mulhsu      zero, s10, t4
                  c.srli      a2, 27
                  c.slli      a1, 6
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  binvi x31, x30, 0
                  c.nop
                  mulhu       ra, s9, s2
572:              c.addi16sp  sp, -16
                  xori        s9, a7, -1653
                  c.add       a0, s3
                  c.bnez      a0, 587f
                  mulhu       s9, s9, a3
                  auipc       s2, 47140
                  bne         s5, sp, 597f
                  slt         zero, s11, zero
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  bseti x31, x30, 31
                  .hword 0x7002  # C-illegal leg -> trap
                  .hword 0x0001
                  csrw mscratch, x30
                  csrrs x31, mscratch, x0
                  csrrc x31, mscratch, x0
                  auipc       s4, 549203
                  c.addi16sp  sp, -16
                  sub         s6, s0, a1
                  srai        ra, a5, 13
                  divu        a7, s6, t6
                  c.add       a2, t2
                  c.slli      a3, 18
587:              slti        s8, s5, -664
                  c.xor       a0, a5
                  andi        zero, t3, 343
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  czero.eqz x31, x30, x31
                  div         t2, a3, a3
                  add         tp, s10, t3
                  c.mv        ra, s1
                  c.add       s9, t2
                  c.srli      a3, 9
                  c.nop
                  slti        t5, a7, 2034
597:              c.beqz      a2, 611f
                  and         a1, s2, a6
                  srli        a6, t3, 13
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  czero.nez x31, x30, x31
                  csrw mscratch, ra
                  jal  ra, 82611f
                  jalr x0, 0(ra)     # wrong-path ret: IF pre-decode pop
82611:          csrr ra, mscratch
                  c.beqz      a4, 620f
                  auipc       t1, 235399
                  rem         s9, s8, t1
                  blt         a1, t6, 612f
                  c.and       a1, s0
                  slli        tp, t1, 12
                  c.addi4spn  a0, sp, 208
                  lui         t2, 330232
                  sra         tp, s5, t5
                  c.srai      a4, 29
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  sh1add x31, x30, x31
                  sltiu       a4, s7, 1004
611:              slli        zero, s2, 29
612:              sub         zero, s3, s6
                  or          ra, a5, s9
                  mulhsu      s3, tp, t1
                  c.beqz      a1, 630f
                  c.add       a4, s5
                  srl         t2, a1, a1
                  mulhu       a3, a5, s11
                  c.addi      a3, -1
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  sh2add x31, x30, x31
                  .word 0x48b52533   # reserved -> trap, rotate arms
620:              c.srli      a0, 11
                  mulh        a6, s8, tp
                  bltu        sp, t1, 632f
                  c.andi      a1, -1
                  c.li        a3, 3
                  c.nop
                  rem         t4, zero, a6
                  slli        a5, a7, 31
                  beq         t2, tp, 631f
                  divu        s8, a7, s2
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
630:              c.srli      a2, 6
631:              c.bnez      a1, 635f
632:              c.andi      s1, 20
                  and         tp, s8, a3
                  sltiu       s11, s8, -1626
635:              c.add       a2, s3
                  c.add       t0, a2
                  sub         a6, s7, s8
                  auipc       a6, 793487
                  andi        s4, s8, 1175
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  andn  x31, x30, x31
                  blt         t3, a4, 647f
                  sltu        t1, s7, s6
                  c.bnez      a2, 657f
                  c.andi      a2, -1
                  divu        zero, a1, t4
                  c.addi4spn  a2, sp, 560
                  c.slli      tp, 13
647:              bltu        s1, s6, 650f
                  srai        s9, t2, 19
                  c.bnez      a0, 666f
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  orn   x31, x30, x31
650:              xori        a2, s10, -1409
                  blt         s6, tp, 659f
                  c.lui       a7, 14
                  c.add       s6, t1
                  sltu        s6, gp, a3
                  or          a0, a7, s5
                  auipc       s7, 375732
657:              blt         s8, s11, 671f
                  bge         t1, s5, 665f
659:              div         t4, s1, s2
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  xnor  x31, x30, x31
                  srli        a2, ra, 10
                  mulhsu      a0, s0, a3
                  blt         s6, a3, 674f
                  xori        t0, s0, 1289
                  mulhu       s5, t0, zero
665:              xor         s10, t1, a0
666:              c.bnez      a2, 676f
                  c.lui       s8, 29
                  mulhsu      t1, a4, s11
                  beq         s3, t1, 672f
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  clz   x31, x30
                  slt         s7, s5, t0
671:              bltu        s8, a1, 680f
672:              sll         s5, t2, a4
                  bne         a7, gp, 690f
674:              c.xor       a2, a3
                  c.nop
676:              c.beqz      a2, 680f
                  c.xor       a1, s1
                  divu        s6, s5, s3
                  blt         s10, t1, 682f
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
680:              c.add       s1, s8
                  ori         zero, s3, 217
682:              c.lui       a5, 6
                  c.srai      a4, 13
                  lui         t5, 462030
                  xor         s5, zero, a2
                  c.addi      s1, -1
                  srl         a4, a2, s11
                  addi        zero, s6, -1569
                  divu        a5, t5, t4
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  cpop  x31, x30
690:              c.andi      a1, -1
                  bge         a3, s3, 710f
                  and         s9, s0, t4
                  c.andi      a2, -1
                  c.li        ra, 14
                  add         zero, s3, s2
                  c.add       t0, t6
                  c.xor       a0, s1
                  srai        t1, a5, 31
                  c.sub       a2, a0
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  min   x31, x30, x31
                  .word 0x68b52533   # reserved -> trap, rotate arms
                  sra         s6, sp, t1
                  andi        t5, s2, 1749
                  xori        a7, s3, 408
                  divu        t2, zero, t4
                  srai        zero, a2, 21
                  beq         s10, a3, 709f
                  c.xor       s1, a1
                  bne         a2, gp, 721f
                  c.li        s8, -1
709:              c.mv        t0, tp
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  minu  x31, x30, x31
710:              c.srai      a0, 1
                  c.srli      a0, 11
                  bne         s7, a2, 718f
                  mulh        s10, a2, a5
                  nop
                  lui         s11, 509167
                  ori         a5, s5, -431
                  c.addi4spn  a2, sp, 528
718:              sll         s9, a3, s10
                  c.andi      s1, -1
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  max   x31, x30, x31
                  c.bnez      a0, 731f
721:              ori         t1, t4, 820
                  slti        s6, s9, 766
                  c.srai      a3, 17
                  c.srli      a3, 4
                  c.or        a2, a3
                  lui         s3, 910265
                  c.or        a0, a3
                  c.bnez      a0, 743f
                  sltu        s4, ra, t5
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
                  sltiu       a0, s10, 1113
731:              srai        s4, a1, 21
                  slti        zero, t3, -703
                  c.lui       s10, 7
                  c.lui       a5, 8
                  sltiu       a1, s2, 1065
                  divu        a3, s6, s0
                  srli        zero, s0, 21
                  ori         a7, a6, 131
                  slt         a0, t1, a0
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  sext.b x31, x30
                  srli        ra, s11, 4
                  or          ra, s2, a5
                  mulhsu      s8, s6, s3
743:              c.add       a7, t3
                  bne         sp, t5, 762f
                  c.xor       a2, s1
                  mulh        t4, t6, a0
                  add         t2, t3, zero
                  c.lui       s2, 10
                  srli        zero, tp, 4
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  sext.h x31, x30
                  rem         zero, ra, t3
                  bne         zero, gp, 765f
                  c.addi4spn  a2, sp, 32
                  c.srai      a3, 1
                  xor         a3, s1, a7
                  c.andi      a3, -1
                  c.or        a2, a1
                  div         s3, a7, ra
                  rem         a0, s6, t6
                  c.or        a0, a1
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  zext.h x31, x30
                  csrw mscratch, ra
                  jal  ra, 82771f
                  jalr x0, 0(ra)     # wrong-path ret: IF pre-decode pop
82771:          csrr ra, mscratch
                  c.addi16sp  sp, 32
                  or          s1, s3, ra
762:              sltu        s3, t2, s2
                  sub         s11, zero, a1
                  div         s9, t5, a7
765:              and         a2, s8, t6
                  lui         zero, 457009
                  xori        zero, a2, -1096
                  mulh        s5, s1, t3
                  mulhu       s5, s3, a7
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  rol   x31, x30, x31
                  c.add       a3, s2
                  c.or        a3, a2
                  sub         gp, s8, t3
                  sll         s6, s1, s0
                  and         s6, s4, t5
                  slt         zero, t6, t4
                  c.addi      ra, 17
                  slti        zero, s3, -1158
                  srli        s2, s2, 20
                  divu        zero, a2, s9
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  ror   x31, x30, x31
                  .word 0x28b52533   # reserved -> trap, rotate arms
                  csrw mscratch, x30
                  csrrs x31, mscratch, x0
                  csrrc x31, mscratch, x0
                  sll         a2, s4, a6
                  divu        s7, t1, s0
                  or          a0, tp, s6
                  srli        zero, s3, 31
                  xori        a2, a3, 788
                  bne         sp, t3, 786f
786:              mulhu       t5, a7, t2
                  beq         s1, a7, 791f
                  rem         s6, s4, zero
                  c.xor       a0, a1
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  rori  x31, x30, 7
                  c.li        ra, -1
791:              bne         tp, a6, 792f
792:              bne         t2, a1, 803f
                  mulhu       zero, tp, s5
                  c.or        a0, a1
                  bltu        a5, s2, 815f
                  c.addi4spn  a0, sp, 128
                  xori        tp, s0, -605
                  c.andi      a2, -1
                  c.add       ra, s5
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  orc.b x31, x30
                  mulhsu      tp, a4, s9
                  sltiu       s4, s0, 394
                  bge         a6, s2, 805f
803:              c.sub       a2, a0
                  c.addi16sp  sp, 384
805:              sll         a1, a2, t6
                  and         a6, a0, s7
                  c.sub       s1, a0
                  slt         zero, a3, tp
                  beq         s6, a0, 824f
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  rev8  x31, x30
                  mul         s1, a4, s4
                  bltu        t6, a7, 814f
                  nop
                  add         t2, t0, a7
814:              c.and       a0, a3
815:              c.srai      a2, 8
                  or          t4, tp, s8
                  sub         zero, sp, s6
                  bltu        s11, a7, 824f
                  andi        sp, t0, 704
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  bclr  x31, x30, x31
                  .hword 0x9c01  # C-illegal leg -> trap
                  .hword 0x0001
                  c.or        a1, s1
                  c.add       a7, a4
                  bgeu        a5, s9, 842f
                  addi        tp, s0, -859
824:              c.and       a0, a1
                  c.li        s8, -1
                  c.xor       a2, a3
                  c.and       a3, a0
                  c.addi4spn  a0, sp, 352
                  c.addi16sp  sp, 80
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
                  andi        s6, s1, 1668
                  slli        s11, a7, 7
                  c.beqz      a0, 842f
                  mulh        s7, s3, a6
                  and         a3, gp, a7
                  div         t2, t1, t2
                  addi        s11, s6, 1974
                  sll         gp, a3, s9
                  c.srli      a2, 21
                  mul         s1, s5, t3
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  binv  x31, x30, x31
                  srai        s8, a4, 6
                  sub         s3, a6, a3
842:              or          a1, t2, s5
                  c.nop
                  c.mv        t1, t1
                  addi        a0, s3, 1628
                  c.nop
                  mulhu       a6, t0, s11
                  c.li        s6, 22
                  mulhu       s5, s1, s7
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  bset  x31, x30, x31
                  add         t4, s8, s3
                  c.and       a5, a3
                  sub         sp, a2, tp
                  lui         s5, 971061
                  c.lui       ra, 9
                  c.addi      a0, -1
                  c.or        a2, s1
                  sll         s10, a2, zero
                  c.bnez      a0, 861f
                  xor         s5, s4, s7
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  bclri x31, x30, 31
                  .word 0x8b52533   # reserved -> trap, rotate arms
                  mul         t0, a1, tp
861:              bltu        a6, t3, 880f
                  c.addi4spn  a5, sp, 176
                  add         a6, t2, ra
                  beq         s5, a5, 868f
                  c.srli      a3, 14
                  srli        t0, s5, 17
                  bltu        s7, s8, 868f
868:              addi        t0, s10, 1263
                  xor         zero, a2, s8
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  bexti x31, x30, 15
                  lui         s9, 777823
                  sltiu       t0, s11, -761
                  slt         t5, t5, sp
                  or          t5, s6, a5
                  slli        s11, a7, 0
                  slti        ra, t5, -1828
                  sra         ra, t3, a2
                  c.slli      ra, 1
                  sub         s1, a6, tp
                  addi        a2, a1, 500
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
880:              srl         sp, t5, a6
                  bge         s7, s2, 898f
                  rem         ra, s3, gp
                  beq         a6, s7, 900f
                  ori         t5, t1, 443
                  xor         t0, s4, s9
                  auipc       t2, 1021398
                  srl         s9, s0, t0
                  sltiu       a4, t4, 159
                  xori        s9, gp, 847
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  bseti x31, x30, 31
                  c.li        s3, 5
                  bgeu        t6, ra, 911f
                  c.andi      a3, -1
                  c.beqz      a2, 907f
                  nop
                  c.srli      a2, 15
                  c.li        t5, 25
                  slt         sp, t4, zero
898:              xor         s2, a0, s0
                  or          s9, t6, a5
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  czero.eqz x31, x30, x31
900:              auipc       s1, 101284
                  sra         t2, t6, s7
                  srli        s11, ra, 8
                  c.slli      a7, 8
                  mulh        t0, s4, a3
                  beq         zero, a2, 919f
                  divu        s9, a2, a0
907:              auipc       ra, 600138
                  slli        gp, s3, 17
                  c.slli      t2, 6
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  czero.nez x31, x30, x31
                  c.lui       a1, 21
911:              rem         a0, s3, a2
                  c.and       a0, a0
                  addi        gp, s5, -593
                  addi        a3, t0, 1669
                  srli        s6, s11, 22
                  andi        s8, a1, 1942
                  lui         zero, 381795
                  c.andi      a4, -1
919:              xor         s4, t1, sp
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  sh1add x31, x30, x31
                  csrw mscratch, ra
                  jal  ra, 82931f
                  jalr x0, 0(ra)     # wrong-path ret: IF pre-decode pop
82931:          csrr ra, mscratch
                  beq         t4, zero, 931f
                  beq         t1, s3, 933f
                  slt         a2, s6, s3
                  c.or        a5, a2
                  xor         s2, s6, s5
                  mulhu       t2, s8, gp
                  auipc       a4, 283281
                  addi        tp, a2, 1508
                  c.add       s7, t2
                  c.add       ra, t2
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
                  srl         a6, s4, zero
931:              add         s9, s2, gp
                  slt         sp, t0, t3
933:              beq         a1, a1, 934f
934:              c.andi      a2, 31
                  c.xor       a0, a1
                  c.slli      a2, 23
                  andi        t5, sp, -1128
                  c.andi      s1, 31
                  c.srai      a2, 23
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  sh3add x31, x30, x31
                  .word 0xeb55533   # reserved -> trap, rotate arms
                  slti        s4, gp, 207
                  andi        s6, s1, -701
                  srl         s5, a1, s7
                  add         s6, a5, s9
                  c.srai      a2, 20
                  rem         t2, s1, a5
                  ori         s4, sp, 1586
                  c.beqz      a0, 950f
                  c.srai      a2, 21
                  auipc       a1, 225024
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  andn  x31, x30, x31
950:              nop
                  lui         zero, 225333
                  slli        s9, a6, 6
                  srli        zero, sp, 18
                  bgeu        s0, s4, 962f
                  addi        t2, s8, -1727
                  slt         tp, zero, s2
                  slti        s4, tp, 1280
                  c.slli      a6, 16
                  divu        t1, tp, zero
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  orn   x31, x30, x31
                  or          a3, s7, t5
                  bne         s8, t6, 979f
962:              add         a5, s11, s6
                  c.srai      a3, 18
                  c.mv        s6, t3
                  srai        sp, a6, 26
                  div         sp, a2, t5
                  xor         s10, s1, t0
                  sll         zero, s5, sp
                  or          t0, a7, a2
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  xnor  x31, x30, x31
                  bltu        t1, t6, 984f
                  c.addi      t1, 2
                  addi        s4, s11, -1670
                  add         t0, tp, s8
                  c.or        a3, a2
                  c.srli      a0, 21
                  ori         t4, sp, -1364
                  divu        zero, a4, a0
                  bgeu        t6, t6, 998f
979:              blt         a7, a3, 985f
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  clz   x31, x30
                  csrw mscratch, x30
                  csrrs x31, mscratch, x0
                  csrrc x31, mscratch, x0
                  bgeu        a6, t1, 995f
                  c.mv        ra, t3
                  slti        tp, s9, 174
                  lui         t1, 474268
984:              bgeu        s11, s9, 988f
985:              xor         s5, a1, a6
                  c.srai      a1, 3
                  mulhu       t5, s5, a5
988:              nop
                  c.nop
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  ctz   x31, x30
                  bne         t4, s0, 993f
                  divu        a4, ra, s2
                  c.addi4spn  a2, sp, 272
993:              andi        zero, s6, 90
                  c.andi      a2, 13
995:              divu        s11, s10, t4
                  c.sub       a2, a2
                  c.beqz      a2, 1006f
998:              c.and       a0, a2
                  c.lui       s8, 20
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  cpop  x31, x30
                  c.sub       a2, a0
                  xor         s2, s6, a4
                  c.xor       a0, a3
                  c.add       a1, a6
                  bge         zero, ra, 1015f
                  slli        gp, s2, 5
1006:             mul         a5, a3, s5
                  addi        s10, tp, 1900
                  beq         t4, ra, 1015f
                  auipc       s1, 868799
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  min   x31, x30, x31
                  ori         a3, s10, -13
                  lui         zero, 599998
                  beq         s8, tp, 1027f
                  lui         a6, 441326
                  c.sub       a2, a2
1015:             mulhsu      s6, tp, ra
                  c.and       a3, a2
                  sub         zero, t5, s2
                  mulh        s10, s1, a3
                  c.slli      ra, 10
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  minu  x31, x30, x31
                  .word 0xeb51533   # reserved -> trap, rotate arms
                  blt         t1, a0, 1024f
                  c.addi      s3, 24
                  slli        a5, s9, 3
                  c.nop
1024:             srl         s9, s1, t4
                  c.xor       a3, a0
                  slt         a7, s0, t2
1027:             mul         zero, tp, gp
                  bltu        gp, s6, 1034f
                  srl         a5, t4, a7
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
                  lui         t5, 783885
                  c.slli      s10, 27
                  sra         gp, s0, ra
                  lui         a2, 369972
1034:             blt         tp, a0, 1037f
                  auipc       t1, 588542
                  c.bnez      a2, 1046f
1037:             and         a6, a3, a1
                  xori        s9, s8, -1656
                  c.or        a2, a2
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  maxu  x31, x30, x31
                  c.addi4spn  a0, sp, 32
                  sra         s9, a3, a7
                  blt         s0, t3, 1052f
                  mulhu       s2, s7, s9
                  xori        s5, ra, 1748
                  sll         t0, a0, t5
1046:             c.nop
                  slt         s3, t1, sp
                  blt         a7, s9, 1049f
1049:             sub         a3, t5, ra
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  sext.b x31, x30
                  xor         s9, s2, tp
                  auipc       s1, 1022432
1052:             xor         zero, t4, t0
                  sra         s10, t4, zero
                  nop
                  sltiu       a0, a4, 832
                  c.addi      a4, -1
                  xori        t0, s5, 362
                  c.srai      a1, 28
                  nop
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  sext.h x31, x30
                  lui         s5, 712980
                  div         ra, s1, t5
                  mulhsu      zero, ra, tp
                  blt         s5, a7, 1071f
                  mulhsu      s8, a4, t2
                  c.sub       a0, a3
                  div         s4, a6, t4
                  sltiu       s6, t3, -322
                  nop
                  addi        s6, s8, 181
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  zext.h x31, x30
                  c.beqz      a1, 1089f
1071:             andi        gp, s11, -1773
                  c.addi4spn  a0, sp, 640
                  sub         a1, a3, s11
                  sub         ra, t2, a5
                  ori         s7, a3, 1767
                  srl         tp, s8, s6
                  slt         zero, gp, a7
                  c.andi      a0, 8
                  srai        s4, a1, 8
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
                  bge         s6, t5, 1086f
                  bltu        a5, a4, 1091f
                  slt         zero, a6, t2
                  slt         s10, sp, s1
                  c.sub       a2, s1
                  blt         t3, zero, 1095f
1086:             bne         a7, t1, 1089f
                  c.addi4spn  a3, sp, 816
                  sltu        zero, s3, a0
1089:             or          s10, s0, s7
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  ror   x31, x30, x31
                  bge         t4, a4, 1105f
1091:             add         t1, s0, s1
                  ori         tp, a4, -1175
                  c.xor       a4, a0
                  sub         s6, s6, a4
1095:             sltu        zero, a7, a7
                  andi        zero, t0, -804
                  add         s4, a3, a7
                  slli        a5, a4, 10
                  srli        zero, a1, 20
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  rori  x31, x30, 7
                  .word 0x60b51513   # reserved -> trap, rotate arms
                  c.xor       a0, a0
                  sltu        zero, s7, a6
                  c.li        t1, 27
                  xori        s4, a3, -1849
                  c.addi      t0, -1
1105:             c.and       a1, a0
                  c.beqz      a3, 1115f
                  mulhsu      s6, s10, s5
                  c.sub       a0, s1
                  sltu        zero, t2, s3
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  orc.b x31, x30
                  addi        s8, s10, -915
                  lui         t4, 419694
                  c.slli      t4, 9
                  c.sub       a3, a0
                  xori        zero, a6, 1191
1115:             mul         s4, s3, sp
                  c.mv        s9, gp
                  slt         s9, t4, s4
                  c.beqz      a0, 1130f
                  c.add       s7, t1
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  rev8  x31, x30
                  rem         zero, t1, s11
                  c.bnez      a0, 1124f
                  slt         s4, t3, t3
                  c.xor       a0, a4
1124:             ori         a2, t6, 958
                  srai        t5, a5, 30
                  c.nop
                  and         s6, s3, s11
                  c.beqz      a0, 1148f
                  rem         s2, a5, s0
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
1130:             srl         s2, s2, s9
                  c.bnez      a3, 1151f
                  bgeu        s6, t3, 1146f
                  addi        s11, s1, 693
                  sltiu       a1, s1, -1179
                  c.addi      a6, 5
                  bge         s0, a4, 1153f
                  sub         s7, ra, ra
                  lui         a0, 496322
                  slli        zero, s1, 16
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  bext  x31, x30, x31
                  c.lui       s4, 8
                  c.or        a0, a3
                  c.bnez      a0, 1145f
                  c.beqz      a0, 1150f
                  ori         gp, a4, -435
1145:             c.beqz      a2, 1156f
1146:             and         a6, zero, zero
                  add         a4, t1, s7
1148:             add         a5, a7, s2
                  slli        a7, t0, 17
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  binv  x31, x30, x31
1150:             c.addi      t2, 5
1151:             mulhsu      a0, zero, t0
                  sltiu       a0, zero, -1004
1153:             sra         gp, s8, a1
                  c.sub       a0, a0
                  c.addi16sp  sp, -16
1156:             srli        s2, s0, 4
                  div         s4, t0, t5
                  c.srli      a2, 1
                  add         zero, s7, gp
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  bset  x31, x30, x31
                  slli        s4, a6, 14
                  srl         ra, a1, gp
                  sltu        s1, ra, s9
                  divu        s10, t0, s5
                  bge         t3, zero, 1178f
                  c.lui       t2, 1
                  xori        s3, s10, -588
                  sltiu       a4, s0, 285
                  bge         a1, s1, 1182f
                  srl         s4, a0, s6
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  bclri x31, x30, 31
                  bge         a0, t4, 1181f
                  c.xor       a1, a2
                  div         zero, gp, a1
                  c.li        ra, 3
                  c.bnez      a0, 1178f
                  sll         ra, a0, a5
                  add         t5, a4, t4
                  c.lui       s4, 6
1178:             c.li        t0, 21
                  lui         s1, 400708
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  bexti x31, x30, 15
                  csrw mscratch, x30
                  csrrs x31, mscratch, x0
                  csrrc x31, mscratch, x0
                  c.li        ra, 16
1181:             c.lui       a6, 12
1182:             c.srai      a3, 19
                  andi        s9, t2, -1069
                  srai        s8, ra, 22
                  srli        s4, t5, 0
                  sltiu       s7, sp, 311
                  c.addi4spn  a2, sp, 640
                  c.beqz      a1, 1192f
                  c.add       a6, s7
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  binvi x31, x30, 0
                  or          t5, s1, a3
                  nop
1192:             slti        a6, t3, 1710
                  xori        s10, t0, 498
                  mulhu       s6, s1, gp
                  auipc       s3, 634129
                  sra         zero, s0, a2
                  and         t0, t6, a4
                  c.addi4spn  a3, sp, 336
                  andi        zero, a2, 936
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  bseti x31, x30, 31
                  c.lui       s3, 30
                  slt         t0, t0, zero
                  srl         a5, s2, s3
                  c.sub       a0, a1
                  sra         t5, a6, s11
                  and         a1, a5, gp
                  bgeu        s0, a0, 1209f
                  sub         t4, t3, s1
                  c.li        ra, 5
1209:             slt         a7, a4, s10
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  czero.eqz x31, x30, x31
                  c.addi16sp  sp, 448
                  add         s6, t6, s7
                  sra         s9, a7, s8
                  ori         zero, s7, 732
                  mul         s11, s7, t3
                  mulhu       tp, s2, t5
                  andi        zero, t4, 1344
                  slt         s8, s10, a2
                  bgeu        a6, t0, 1224f
                  c.beqz      a0, 1237f
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  czero.nez x31, x30, x31
                  mulhsu      zero, t1, ra
                  xor         s6, sp, gp
                  c.nop
                  c.bnez      a0, 1227f
1224:             or          sp, t3, t2
                  sltiu       s2, s3, -1461
                  add         t1, s8, t6
1227:             nop
                  blt         a4, s0, 1243f
                  add         zero, t1, ra
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
                  srl         zero, t3, a5
                  auipc       a2, 998582
                  c.bnez      a3, 1233f
1233:             sll         t1, ra, t5
                  bne         tp, s0, 1251f
                  bge         t5, ra, 1255f
                  c.lui       ra, 29
1237:             c.addi      s1, 23
                  div         a2, gp, s11
                  sltu        s9, a7, a5
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  sh2add x31, x30, x31
                  csrw mscratch, ra
                  jal  ra, 821251f
                  jalr x0, 0(ra)     # wrong-path ret: IF pre-decode pop
821251:          csrr ra, mscratch
                  c.addi4spn  a0, sp, 496
                  slt         s7, t1, a4
                  nop
1243:             lui         sp, 536744
                  nop
                  andi        zero, s4, 449
                  auipc       a2, 362706
                  lui         a7, 160942
                  slti        s7, a6, 943
                  slti        a0, a7, 1306
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  sh3add x31, x30, x31
                  srai        t4, a0, 22
1251:             sltiu       s6, s4, 364
                  ori         zero, a6, -1599
                  c.slli      a6, 8
                  c.addi      s8, -1
1255:             blt         gp, a5, 1259f
                  or          sp, s8, t0
                  add         zero, s9, s6
                  auipc       s5, 724485
1259:             c.addi16sp  sp, 16
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  andn  x31, x30, x31
                  bne         s2, t6, 1274f
                  srai        a3, t0, 20
                  sra         ra, t0, t1
                  c.addi4spn  a2, sp, 16
                  auipc       a4, 154870
                  srai        s4, s10, 27
                  addi        t0, s9, -1624
                  xori        s9, s4, -1538
                  addi        a4, s9, 779
                  c.slli      s7, 8
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  orn   x31, x30, x31
                  c.li        t1, 16
                  sub         s9, a0, t6
                  srli        a6, t6, 11
                  c.slli      a5, 27
1274:             c.add       t0, s10
                  c.srai      a0, 10
                  lui         a7, 317491
                  divu        t2, t4, t3
                  lui         a0, 163979
                  c.slli      a5, 1
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
                  beq         s3, s2, 1291f
                  c.addi16sp  sp, 448
                  rem         a0, t4, t3
                  srli        s2, s11, 22
                  mul         s5, s9, s4
                  c.andi      a3, -1
                  c.add       s6, sp
                  bne         s10, s2, 1298f
                  c.add       s6, s8
                  or          a0, s3, t6
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  clz   x31, x30
                  xor         gp, s8, a4
1291:             divu        zero, t2, tp
                  beq         s0, a6, 1301f
                  c.andi      a0, -1
                  c.srai      a0, 14
                  bne         s10, a5, 1307f
                  div         a2, s6, s9
                  mulhsu      a1, sp, s6
1298:             sll         a7, gp, t3
                  c.srai      a2, 25
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  ctz   x31, x30
                  and         t1, a7, ra
1301:             c.andi      a1, -1
                  mulhu       s6, s2, s7
                  c.mv        ra, s6
                  c.bnez      a4, 1318f
                  or          zero, s9, a5
                  c.bnez      a1, 1309f
1307:             c.beqz      a0, 1322f
                  sub         s11, gp, ra
1309:             c.nop
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  cpop  x31, x30
                  add         t5, s11, a3
                  srai        s9, t1, 7
                  mulhsu      t4, s11, s8
                  bge         a7, s10, 1330f
                  sll         s6, tp, s10
                  c.srai      a2, 4
                  andi        s7, t0, 1563
                  sltu        t0, sp, s10
1318:             mulhsu      a4, s3, s3
                  slli        a1, s5, 7
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  min   x31, x30, x31
                  slti        s7, s8, 784
                  c.bnez      a0, 1327f
1322:             bltu        t6, s6, 1325f
                  andi        s4, s7, -355
                  c.bnez      a0, 1334f
1325:             c.addi16sp  sp, -16
                  c.xor       a2, a3
1327:             divu        a0, t5, sp
                  c.slli      s10, 8
                  c.addi16sp  sp, -16
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
1330:             srl         sp, s5, a0
                  nop
                  mulhsu      s6, s0, t5
                  add         a1, t0, a6
1334:             bgeu        zero, s0, 1335f
1335:             c.addi16sp  sp, 176
                  mulhsu      s1, a2, s4
                  beq         t3, t5, 1347f
                  sll         s6, t4, a6
                  sub         s8, a2, t2
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  max   x31, x30, x31
                  srl         a6, t4, s4
                  c.mv        tp, a6
                  c.and       a5, a3
                  srl         s11, s2, a3
                  ori         a7, s4, 1814
                  nop
                  bne         a5, s8, 1361f
1347:             c.addi      s10, 21
                  slt         zero, s10, a7
                  blt         t0, ra, 1363f
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  maxu  x31, x30, x31
                  or          s4, a1, s9
                  addi        a2, s7, -1243
                  bgeu        a4, s11, 1359f
                  bne         s7, sp, 1373f
                  c.addi16sp  sp, -16
                  sltiu       s7, s9, -509
                  c.xor       a3, a5
                  xori        t5, sp, 1296
                  srl         s6, s6, t1
1359:             add         a4, a5, s7
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  sext.b x31, x30
                  mul         s9, s8, a7
1361:             c.srli      a2, 24
                  ori         s2, s3, -426
1363:             xori        s10, a0, 1322
                  rem         sp, a5, t3
                  c.slli      a7, 17
                  rem         tp, a6, t6
                  c.and       a1, a0
                  xori        tp, t2, 1260
                  c.srai      a0, 26
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  sext.h x31, x30
                  mulhsu      t5, a0, s5
                  rem         a0, s7, t1
                  xori        s4, t6, 680
1373:             srl         a0, s8, t2
                  or          sp, t4, s3
                  c.bnez      a3, 1378f
                  srai        t4, s1, 27
                  c.sub       a1, s1
1378:             c.add       s1, a7
                  bge         sp, s3, 1380f
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  zext.h x31, x30
                  csrw mscratch, x30
                  csrrs x31, mscratch, x0
                  csrrc x31, mscratch, x0
1380:             c.add       s10, t1
                  bltu        a3, s8, 1385f
                  sll         s7, a3, a3
                  mulhu       zero, t5, a4
                  sltiu       gp, s0, -1907
1385:             andi        s1, s1, -674
                  srli        zero, s1, 3
                  divu        a2, a5, tp
                  c.srai      a2, 26
                  sub         s3, a3, s4
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  rol   x31, x30, x31
                  sltu        t0, a3, a2
                  bgeu        t2, a2, 1408f
                  slti        t4, a0, -1247
                  c.xor       a0, a2
                  and         sp, t4, t6
                  blt         s5, s8, 1414f
                  ori         a6, s1, -1573
                  mulhsu      s11, s10, s9
                  c.add       s7, a0
                  auipc       s2, 55195
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  ror   x31, x30, x31
                  csrw mscratch, ra
                  jal  ra, 821411f
                  jalr x0, 0(ra)     # wrong-path ret: IF pre-decode pop
821411:          csrr ra, mscratch
                  c.mv        a2, a1
                  bltu        s2, s0, 1407f
                  add         a7, s0, s8
                  c.andi      a0, 18
                  c.xor       a2, a2
                  c.andi      a2, -1
                  div         s9, tp, tp
1407:             c.lui       s3, 31
1408:             ori         a6, s7, -230
                  c.bnez      a5, 1427f
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  rori  x31, x30, 7
                  mul         s9, t2, s2
                  c.addi16sp  sp, -16
                  mul         s5, a3, sp
                  or          s9, t2, s6
1414:             bltu        s7, t0, 1418f
                  sll         tp, t0, s9
                  mulhsu      t0, t2, a7
                  beq         gp, s0, 1420f
1418:             sub         s9, a5, a1
                  divu        t4, t1, a0
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  orc.b x31, x30
1420:             beq         ra, t1, 1428f
                  c.slli      t5, 26
                  mulh        s4, s0, s4
                  c.nop
                  c.addi16sp  sp, -16
                  bgeu        tp, s8, 1434f
                  xori        s11, s11, 1233
1427:             sll         s1, s4, tp
1428:             sll         s10, a4, s11
                  slli        zero, a7, 12
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
                  srai        s7, t3, 0
                  c.srai      a0, 20
                  c.srli      a0, 10
                  srli        s5, s2, 26
1434:             addi        s2, s1, 150
                  c.srli      a2, 19
                  bge         a7, a3, 1453f
                  div         zero, t1, t3
                  sltu        zero, t5, t0
                  c.and       a0, a0
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  bclr  x31, x30, x31
                  srai        t4, s3, 1
                  sltu        a6, s4, t4
                  bge         s4, s11, 1446f
                  div         s2, s10, s2
                  c.and       a1, s1
                  xor         a0, a2, s7
1446:             c.sub       a2, s1
                  sub         s5, s4, s9
                  c.sub       a2, s1
                  sra         t5, a3, s2
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  bext  x31, x30, x31
                  c.sub       a2, s0
                  bne         zero, t6, 1454f
                  sra         t4, t2, s5
1453:             c.andi      a2, -1
1454:             c.addi4spn  a4, sp, 192
                  blt         a3, sp, 1466f
                  div         s11, t5, a3
                  nop
                  bltu        a3, tp, 1472f
                  mulh        a7, t0, a7
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  binv  x31, x30, x31
                  auipc       a3, 940548
                  c.bnez      a2, 1464f
                  c.addi      a6, -1
                  rem         a6, s2, s11
1464:             sll         a5, a0, t0
                  andi        s2, t1, 1067
1466:             divu        zero, t6, s0
                  mulhsu      a5, t4, zero
                  or          s8, s4, s11
                  c.addi      s11, 14
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  bset  x31, x30, x31
                  sra         a3, s0, s1
                  xori        s5, t5, -984
1472:             c.addi16sp  sp, -16
                  lui         t5, 592835
                  c.addi16sp  sp, 480
                  addi        ra, s6, -1215
                  divu        s4, a6, t3
                  c.slli      a7, 10
                  sra         s2, t0, s1
                  lui         zero, 832585
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
                  srai        s10, s6, 20
                  and         s5, s10, s11
                  c.sub       a0, s0
                  sltiu       s4, s9, -1266
                  rem         gp, a7, gp
                  slti        s4, a6, 1582
                  c.mv        s3, a4
                  addi        t5, s2, 1902
                  c.bnez      a0, 1495f
                  c.li        ra, 30
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  bexti x31, x30, 15
                  c.addi      t0, 13
                  c.xor       a0, a2
                  slli        s7, t3, 8
                  sltiu       a5, t5, 1039
                  rem         t2, s0, a6
1495:             blt         s3, s7, 1512f
                  and         s6, t3, t2
                  slli        a1, s7, 29
                  c.li        tp, 3
                  lui         gp, 436759
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  binvi x31, x30, 0
                  sltu        t2, s8, a7
                  sra         s11, t0, t3
                  div         t5, s5, a7
                  c.and       s1, s1
                  c.srli      a2, 15
                  xori        s7, a0, 965
                  mul         zero, a1, t3
                  divu        a2, a2, s6
                  c.lui       s6, 5
                  div         gp, tp, s5
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  bseti x31, x30, 31
                  and         s6, s7, s1
                  divu        s6, s9, a4
1512:             c.add       ra, s6
                  slli        a6, s6, 27
                  and         a3, s0, t2
                  srli        zero, ra, 26
                  c.andi      a3, -1
                  c.slli      ra, 4
                  div         zero, a2, a0
                  srl         zero, a1, sp
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  czero.eqz x31, x30, x31
                  mul         a6, s8, a5
                  c.srai      a2, 7
                  srai        a3, s9, 27
                  mulhu       zero, tp, s1
                  addi        a1, a1, 203
                  c.lui       s9, 25
                  srai        a1, a1, 18
                  c.addi      s1, -1
                  mulhu       sp, s6, a4
                  c.addi      a0, -1
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
                  beq         a0, a5, 1544f
                  c.bnez      a0, 1541f
                  sra         tp, s10, t0
                  lui         s5, 326548
                  mulhsu      s3, tp, a0
                  bge         a1, a4, 1555f
                  div         t0, s8, s5
                  mulhu       a6, t0, s2
                  mulh        tp, s9, t3
                  auipc       s7, 68493
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  sh1add x31, x30, x31
                  blt         zero, a2, 1551f
1541:             c.slli      a2, 16
                  slt         sp, s1, s9
                  sll         zero, t1, sp
1544:             divu        a2, a5, t4
                  c.slli      ra, 21
                  beq         ra, s9, 1564f
                  add         t2, t4, s9
                  c.addi      a1, -1
                  beq         a2, sp, 1559f
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  sh2add x31, x30, x31
                  auipc       a4, 502845
1551:             c.slli      s9, 26
                  c.and       s1, s1
                  and         a7, s7, gp
                  rem         zero, a5, a1
1555:             c.nop
                  sub         zero, a0, s8
                  slti        a3, ra, 602
                  c.or        a2, a4
1559:             c.and       a0, a2
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  sh3add x31, x30, x31
                  csrw mscratch, ra
                  jal  ra, 821571f
                  jalr x0, 0(ra)     # wrong-path ret: IF pre-decode pop
821571:          csrr ra, mscratch
                  c.xor       a0, a0
                  bltu        s0, a5, 1562f
1562:             andi        s6, t1, 995
                  c.mv        tp, s3
1564:             bgeu        s5, zero, 1570f
                  slt         a6, tp, s11
                  andi        t2, sp, -1297
                  and         s2, gp, s6
                  bgeu        s6, gp, 1572f
                  or          s10, t0, tp
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  andn  x31, x30, x31
1570:             add         t4, s9, zero
                  auipc       a1, 142592
1572:             c.addi      s7, 29
                  addi        a7, tp, 1900
                  blt         s5, t4, 1586f
                  lui         zero, 433593
                  blt         a2, s1, 1579f
                  beq         a2, sp, 1581f
                  c.lui       t2, 16
1579:             div         s1, t5, s3
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  orn   x31, x30, x31
                  csrw mscratch, x30
                  csrrs x31, mscratch, x0
                  csrrc x31, mscratch, x0
                  c.li        tp, 2
1581:             srli        zero, s0, 21
                  c.andi      s1, 16
                  lui         zero, 825340
                  srai        a4, s3, 10
                  add         a6, s3, ra
1586:             c.and       a0, a2
                  sra         s1, t1, a5
                  c.or        a3, s0
                  c.bnez      a2, 1603f
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  xnor  x31, x30, x31
                  c.srli      a1, 26
                  ori         s10, s8, -981
                  c.and       a0, a3
                  ori         t2, t4, -290
                  c.or        a0, a0
                  mulhsu      t5, s0, s3
                  c.andi      a1, -1
                  slt         t5, ra, a1
                  addi        a4, s2, -103
                  c.mv        ra, gp
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  clz   x31, x30
                  sra         t5, s11, s1
                  div         a2, s8, a4
                  blt         a4, a0, 1608f
1603:             xori        s1, s1, 824
                  sltiu       a3, ra, 2012
                  srl         s10, s7, s4
                  xori        s6, a6, -422
                  add         a5, s5, a7
1608:             srl         t2, t1, tp
                  mulh        s8, gp, a3
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  ctz   x31, x30
                  mul         t2, s10, s11
                  c.slli      s4, 16
                  div         ra, ra, a5
                  beq         gp, s4, 1628f
                  sltu        s7, ra, a0
                  c.and       a0, a3
                  beq         s5, s4, 1619f
                  nop
                  sltu        t2, a1, tp
1619:             div         zero, t0, sp
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  cpop  x31, x30
                  mulhsu      zero, s1, s8
                  c.srai      a2, 8
                  bge         t0, a5, 1642f
                  srli        s11, t6, 7
                  c.addi4spn  a3, sp, 576
                  sub         a7, zero, s5
                  sltiu       s2, a4, 1442
                  srl         a1, s3, a4
1628:             c.or        a5, a2
                  or          a1, a3, t2
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
                  c.bnez      a0, 1649f
                  addi        s7, sp, 1231
                  c.or        a0, a2
                  c.addi16sp  sp, 368
                  c.lui       gp, 4
                  addi        a5, t5, 0
                  and         t1, a1, s10
                  bge         a7, t6, 1645f
                  c.slli      a3, 20
                  c.beqz      a0, 1654f
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  minu  x31, x30, x31
                  srli        s3, s11, 18
                  mulhu       s3, s9, s7
1642:             srai        a0, s7, 0
                  slti        t4, t2, 836
                  blt         s2, a2, 1645f
1645:             add         ra, s10, tp
                  c.srai      a2, 7
                  sltiu       zero, ra, -231
                  c.and       a4, a1
1649:             c.mv        s4, a5
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  max   x31, x30, x31
                  c.mv        ra, a5
                  c.and       a2, s0
                  c.slli      a3, 31
                  c.nop
1654:             bne         t1, s8, 1655f
1655:             lui         s10, 954791
                  c.xor       a2, a2
                  slli        t2, s2, 9
                  add         s4, t6, a3
                  div         s6, a6, s3
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  maxu  x31, x30, x31
                  or          t4, a0, s1
                  c.slli      ra, 16
                  slli        ra, tp, 10
                  slti        s6, a7, 1049
                  c.addi4spn  a2, sp, 528
                  c.mv        ra, s1
                  c.andi      a2, -1
                  c.and       a2, a0
                  nop
                  slt         s9, s2, s11
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  sext.b x31, x30
                  c.beqz      a2, 1689f
                  c.slli      s1, 22
                  c.xor       a4, a1
                  sra         s9, a5, t3
                  c.add       s2, s9
                  srl         a1, t1, a6
                  c.addi      ra, 6
                  bltu        t2, s11, 1681f
                  slli        t5, s4, 2
                  andi        s5, zero, -509
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
                  c.nop
1681:             add         a0, s8, tp
                  ori         gp, t2, 723
                  mul         gp, t0, a3
                  bge         s3, a7, 1694f
                  andi        zero, a2, -132
                  bge         t4, s2, 1700f
                  bne         s10, ra, 1688f
1688:             c.bnez      a3, 1699f
1689:             slli        s4, s4, 21
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  zext.h x31, x30
                  addi        s11, tp, 117
                  or          a7, s1, s3
                  andi        a6, t3, -1098
                  sltu        ra, s10, t6
1694:             bne         s6, s5, 1698f
                  mulhsu      ra, s10, zero
                  add         zero, a5, t3
                  addi        zero, a1, 962
1698:             bne         a6, s1, 1707f
1699:             c.bnez      a0, 1713f
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  rol   x31, x30, x31
1700:             lui         s8, 673838
                  mulhu       t2, s1, a3
                  c.mv        s8, t4
                  c.xor       a2, a0
                  xor         s3, t2, a4
                  c.xor       a1, a2
                  lui         t0, 369720
1707:             c.nop
                  sra         s5, s4, t6
                  divu        a7, a3, s3
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  ror   x31, x30, x31
                  or          t4, s3, a6
                  rem         zero, a2, s1
                  c.addi4spn  a0, sp, 880
1713:             xor         ra, s6, t2
                  blt         t4, a1, 1718f
                  blt         t4, s7, 1718f
                  c.beqz      a0, 1722f
                  sltu        a1, a4, s2
1718:             c.nop
                  slt         zero, sp, t2
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  rori  x31, x30, 7
                  csrw mscratch, ra
                  jal  ra, 821731f
                  jalr x0, 0(ra)     # wrong-path ret: IF pre-decode pop
821731:          csrr ra, mscratch
                  c.nop
                  nop
1722:             slti        a0, zero, 1076
                  c.bnez      a2, 1740f
                  bltu        s6, t1, 1735f
                  sltiu       s5, a7, -643
                  c.lui       a2, 12
                  c.addi4spn  a0, sp, 208
                  auipc       t1, 464566
                  divu        ra, t1, s1
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
                  sub         a5, s8, s5
                  andi        s1, a0, 455
                  c.sub       a2, a0
                  rem         s2, a7, s6
                  mulh        s3, a2, t5
1735:             auipc       a2, 203158
                  xor         s7, t6, t5
                  c.mv        tp, a0
                  c.sub       a3, s0
                  c.addi4spn  a0, sp, 944
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  rev8  x31, x30
1740:             c.addi4spn  a5, sp, 576
                  c.srli      a1, 28
                  c.addi16sp  sp, 416
                  srl         gp, s10, s0
                  bne         zero, sp, 1747f
                  mulh        sp, t0, gp
                  div         s3, a5, a6
1747:             slti        ra, s0, 279
                  c.andi      a0, -1
                  c.slli      s9, 19
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  bclr  x31, x30, x31
                  auipc       a0, 1043946
                  slli        s6, t5, 7
                  c.bnez      a0, 1767f
                  c.add       ra, s1
                  mulhu       s2, a4, zero
                  c.slli      t2, 8
                  c.srli      a1, 18
                  and         gp, a7, s11
                  c.srai      a0, 6
                  srai        a0, a3, 31
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  bext  x31, x30, x31
                  c.addi4spn  a0, sp, 560
                  c.nop
                  c.li        tp, 19
                  c.mv        gp, t2
                  c.xor       a0, s1
                  c.xor       a3, a3
                  sll         a0, s3, t2
1767:             sltiu       s1, t5, 715
                  c.addi4spn  a3, sp, 832
                  c.xor       a2, a2
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  binv  x31, x30, x31
                  srl         zero, t0, a2
                  andi        zero, s10, 772
                  c.sub       a1, a4
                  c.or        a2, a3
                  mulhu       t1, s6, a6
                  addi        t5, s10, -872
                  xori        a0, t3, 1851
                  bge         t6, a4, 1785f
                  slli        s1, s8, 22
                  bgeu        s3, t4, 1782f
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  bset  x31, x30, x31
                  csrw mscratch, x30
                  csrrs x31, mscratch, x0
                  csrrc x31, mscratch, x0
                  div         zero, sp, t4
                  c.li        t2, -1
1782:             c.li        s1, -1
                  c.slli      a7, 28
                  div         a3, a5, t3
1785:             sll         tp, s1, tp
                  or          ra, a3, s0
                  auipc       a6, 637085
                  c.addi      ra, -1
                  mul         s5, a5, s0
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  bclri x31, x30, 31
                  mulh        a4, a0, gp
                  bltu        sp, a4, 1801f
                  slt         t2, a0, a7
                  divu        t0, s10, t4
                  rem         ra, sp, gp
                  rem         t0, s0, a3
                  c.srai      s1, 5
                  ori         zero, a2, -1478
                  auipc       s10, 399312
                  c.or        a2, a3
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  bexti x31, x30, 15
                  c.and       a3, a1
1801:             c.lui       a2, 18
                  blt         s7, a4, 1809f
                  sub         s4, tp, t1
                  add         ra, ra, tp
                  xori        s8, sp, -791
                  mulh        s1, t5, s3
                  c.srai      a2, 9
                  c.addi      sp, 31
1809:             rem         t2, s4, a6
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  binvi x31, x30, 0
                  ori         zero, s1, 2046
                  c.mv        s10, s0
                  c.and       a1, a3
                  nop
                  div         t0, t0, s2
                  c.sub       a2, a1
                  lui         t1, 107025
                  sll         t5, a0, a0
                  c.or        a2, a3
                  blt         gp, s4, 1836f
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  bseti x31, x30, 31
                  c.addi      sp, 31
                  c.add       s7, a7
                  srai        s10, s3, 12
                  srli        a2, s1, 6
                  rem         a3, s4, s8
                  c.lui       s7, 19
                  srai        t2, t2, 24
                  c.or        a3, s0
                  andi        t1, t1, -802
                  srl         ra, s10, s4
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
                  c.or        a4, a1
                  slti        s8, s6, 1372
                  srl         zero, a0, a1
                  bne         a3, t0, 1851f
                  mul         s5, a6, a1
                  bgeu        zero, t1, 1850f
1836:             sll         s5, s3, s4
                  and         a3, a2, a0
                  bne         s0, s6, 1858f
                  srli        zero, zero, 2
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  czero.nez x31, x30, x31
                  andi        a7, s9, 1623
                  c.bnez      a4, 1847f
                  c.xor       a0, a0
                  lui         a3, 863421
                  srai        zero, a5, 10
                  nop
                  and         a6, t1, s3
1847:             c.and       a2, a3
                  c.add       s11, s2
                  sra         s10, a7, t0
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  sh1add x31, x30, x31
1850:             slli        a5, s0, 31
1851:             c.or        a0, a0
                  add         sp, t4, s7
                  c.addi      s8, -1
                  c.mv        a4, t5
                  c.nop
                  c.beqz      a0, 1859f
                  c.bnez      a0, 1871f
1858:             srai        s4, s4, 27
1859:             rem         t0, sp, t3
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  sh2add x31, x30, x31
                  beq         s1, tp, 1872f
                  c.addi4spn  a1, sp, 736
                  mul         a4, sp, tp
                  bltu        gp, s4, 1883f
                  c.srli      a0, 6
                  addi        s9, t0, -1383
                  sub         t2, s4, t1
                  c.addi      a4, -1
                  bne         s6, a0, 1886f
                  c.addi16sp  sp, -16
                  li   x30, 0xa5a5a5a5
                  li   x31, 0x00010000
                  sh3add x31, x30, x31
                  c.add       t2, s7
1871:             c.bnez      a2, 1872f
1872:             div         a7, t0, s11
                  mul         s1, sp, a5
                  c.and       a3, a0
                  c.lui       t0, 5
                  xor         a5, a5, ra
                  c.xor       a2, a3
                  c.srli      a3, 27
                  c.mv        s6, t4
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
                  div         zero, t2, s1
                  blt         a6, a3, 1888f
                  c.li        s5, -1
1883:             mulhsu      a5, a7, a1
                  c.and       a2, a1
                  slli        s4, t0, 5
1886:             c.srli      a1, 29
                  c.bnez      a0, 1899f
1888:             rem         a3, s11, s7
                  srl         zero, s4, zero
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  orn   x31, x30, x31
                  slt         s5, s4, s7
                  bgeu        gp, gp, 1899f
                  nop
                  slli        zero, s1, 14
                  bne         t1, s7, 1914f
                  add         a3, a3, s11
                  rem         t2, a3, s11
                  slti        s1, a0, 15
                  c.lui       a0, 9
1899:             c.srai      a0, 31
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  xnor  x31, x30, x31
                  c.srli      a3, 15
                  c.or        a2, a3
                  c.andi      a0, -1
                  c.bnez      a0, 1922f
                  c.srai      a5, 24
                  bne         tp, a6, 1925f
                  c.srli      a2, 4
                  c.mv        sp, s2
                  c.sub       a2, a2
                  div         a3, s3, t0
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  clz   x31, x30
                  and         s5, a5, sp
                  or          t2, t0, a1
                  sub         a2, a5, a6
                  slli        s6, ra, 20
1914:             c.sub       s1, a3
                  srl         tp, sp, a1
                  ori         a3, t0, 1629
                  c.addi16sp  sp, 16
                  slli        t5, a7, 22
                  auipc       zero, 1883
                  li   x30, 0x80000000
                  li   x31, 0xffff0001
                  ctz   x31, x30
                  bltu        gp, t5, 1931f
                  c.slli      ra, 20
1922:             c.srli      a2, 2
                  c.sub       a2, a0
                  c.andi      a0, -1
1925:             sltu        t4, s2, a1
                  c.srai      a0, 16
                  nop
                  srai        tp, s2, 30
                  srl         ra, t0, a6
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
                  c.xor       s1, a2
1931:             c.nop
                  c.srli      a0, 24
                  mulh        s6, t3, t2
                  sltu        s10, s4, t2
                  c.beqz      a3, 1936f
1936:             blt         s0, s3, 1940f
                  c.sub       a0, a0
                  slti        s8, a1, 1772
                  bge         s6, tp, 1943f
                  li   x30, 0x00000000
                  li   x31, 0x7fffffff
                  min   x31, x30, x31
1940:             andi        t4, s0, 1830
                  mulh        ra, s5, s7
                  srai        a3, s3, 6
1943:             andi        t1, t1, -44
                  c.sub       a3, s1
                  c.and       a0, a0
                  or          zero, a2, s11
                  bne         s1, s3, 1950f
                  bgeu        t4, a3, 1954f
                  sra         s8, sp, a1
                  li   x30, 0xffff0001
                  li   x31, 0x80000000
                  minu  x31, x30, x31
1950:             bgeu        a7, ra, 1959f
                  slti        a5, a7, -1168
                  mulh        s4, t6, gp
                  nop
1954:             blt         s3, sp, 1957f
                  sltiu       a7, s10, -671
                  bgeu        sp, s7, 1965f
1957:             srli        s5, s9, 7
                  addi        zero, a3, 1204
1959:             mulh        zero, s9, s5
                  li   x30, 0x00010000
                  li   x31, 0xa5a5a5a5
                  max   x31, x30, x31
                  c.or        a2, s0
                  blt         a7, s4, 1965f
                  or          s6, s5, a5
                  mulhsu      t5, t0, gp
                  c.sub       a0, a0
1965:             srl         t1, a6, a2
                  la x8, test_done
                  jalr x0, x8, 0
test_done:        
                  li gp, 1
                  j write_tohost
                  li   x30, 0x7fffffff
                  li   x31, 0x00000000
                  maxu  x31, x30, x31
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
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.section .region_1,"aw",@progbits;
region_1:
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
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
                  csrr  x30, 0x300 # MSTATUS;
                  csrr  x30, 0x304 # MIE;
                  csrr  x30, 0x344 # MIP;
                  csrrc x30, 0x344, x30 # MIP;
                  lw x1, 4(x28)
                  lw x2, 8(x28)
                  lw x3, 12(x28)
                  lw x4, 16(x28)
                  lw x5, 20(x28)
                  lw x6, 24(x28)
                  lw x7, 28(x28)
                  lw x8, 32(x28)
                  lw x9, 36(x28)
                  lw x10, 40(x28)
                  lw x11, 44(x28)
                  lw x12, 48(x28)
                  lw x13, 52(x28)
                  lw x14, 56(x28)
                  lw x15, 60(x28)
                  lw x16, 64(x28)
                  lw x17, 68(x28)
                  lw x18, 72(x28)
                  lw x19, 76(x28)
                  lw x20, 80(x28)
                  lw x21, 84(x28)
                  lw x22, 88(x28)
                  lw x23, 92(x28)
                  lw x24, 96(x28)
                  lw x25, 100(x28)
                  lw x26, 104(x28)
                  lw x27, 108(x28)
                  lw x28, 112(x28)
                  lw x29, 116(x28)
                  lw x30, 120(x28)
                  lw x31, 124(x28)
                  addi x28, x28, 124
                  add x31, x28, zero
                  csrrw x28, 0x340, x28
                  mret;

kernel_instr_end: nop
.align 2
kernel_data_start:
.section .s_region_0,"aw",@progbits;
s_region_0:
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.section .s_region_1,"aw",@progbits;
s_region_1:
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
.word 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000
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
