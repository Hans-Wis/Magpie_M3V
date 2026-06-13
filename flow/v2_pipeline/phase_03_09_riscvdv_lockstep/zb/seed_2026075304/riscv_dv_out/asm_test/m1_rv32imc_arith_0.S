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
                  li x27, 0x40001104
                  csrw 0x301, x27
kernel_sp:        
                  la x7, kernel_stack_end

trap_vec_init:    
                  la x27, mtvec_handler
                  ori x27, x27, 0
                  csrw 0x305, x27 # MTVEC

mepc_setup:       
                  la x27, init
                  csrw 0x341, x27

init_machine_mode:
                  li x27, 0x1c00
                  csrw 0x300, x27 # MSTATUS
                  li x27, 0x0
                  csrw 0x304, x27 # MIE
                  mret
init:             
                  li x0, 0x0
                  li x1, 0xfeb5598a
                  li x2, 0xe5b11fc
                  li x3, 0x80000000
                  li x4, 0x4
                  li x5, 0x0
                  li x6, 0xfbde3ecb
                  li x8, 0x38f91aa8
                  li x9, 0xb1979e6
                  li x10, 0x2
                  li x11, 0xfb31cf50
                  li x12, 0x80000000
                  li x13, 0xa4f6f9ff
                  li x14, 0x0
                  li x15, 0xb
                  li x16, 0xfbcf3121
                  li x17, 0xf0aa807e
                  li x18, 0x0
                  li x19, 0x7be6fc59
                  li x20, 0xfd31d97f
                  li x21, 0xf58248df
                  li x22, 0x0
                  li x23, 0x0
                  li x24, 0x0
                  li x25, 0xc
                  li x27, 0x80000000
                  li x28, 0xfb03d85a
                  li x29, 0x80000000
                  li x30, 0x0
                  li x31, 0x0
                  la x26, user_stack_end
main:             c.li        tp, 17
                  c.srai      a2, 5
                  c.and       a0, a0
                  mul         t0, a3, s0
                  beq         a6, a3, 23f
                  c.or        a0, a2
                  c.li        gp, 15
                  srai        t4, a7, 10
                  lui         s6, 1045715
                  sltu        s7, s7, s11
                  c.slli      t3, 6
                  sltiu       s11, s10, -1386
                  c.mv        gp, s10
                  c.sub       a1, a3
                  bgeu        t3, t3, 22f
                  c.srli      a0, 19
                  mulhsu      s8, a2, a0
                  nop
                  and         t4, s8, a3
                  bgeu        s8, sp, 39f
                  or          s9, s3, s3
                  sll         a1, s7, a7
22:               bge         t3, a1, 36f
23:               c.li        t3, 1
                  c.slli      s7, 12
                  c.beqz      a4, 45f
                  c.srli      a3, 20
                  mulhsu      s3, s1, t6
                  addi        s8, t5, -1251
                  c.or        a0, s0
                  mulhu       zero, tp, tp
                  slti        s1, s9, -136
                  slt         a1, s1, s5
                  bgeu        sp, a6, 45f
                  sltiu       gp, s2, -1848
                  sub         zero, gp, gp
36:               sll         a5, s3, s4
                  beq         a0, zero, 39f
                  bgeu        s10, a0, 46f
39:               c.addi16sp  sp, 352
                  c.nop
                  mulh        s11, s1, s4
                  lui         t3, 76149
                  div         a5, t0, s10
                  c.addi      a5, -1
45:               auipc       a6, 237237
46:               sltiu       s1, gp, -1561
                  c.lui       ra, 8
                  c.sub       a2, a0
                  sltu        zero, s8, s4
                  c.li        s2, 2
                  sltiu       s4, s0, 1350
                  slt         zero, s4, s10
                  c.slli      s1, 24
                  bne         s0, s3, 67f
                  c.sub       a5, a3
                  c.and       s1, a1
                  lui         t4, 1022733
                  ori         a6, a6, 728
                  srli        a4, a2, 20
                  beq         a1, s6, 66f
                  srli        s0, s5, 2
                  div         a1, s0, s1
                  c.mv        t0, s8
                  c.mv        s2, a7
                  xori        a2, a3, 1766
66:               mul         s4, s10, t6
67:               addi        a1, s3, 1653
                  srl         s5, a1, a4
                  c.slli      s2, 26
                  c.or        a2, s1
                  add         gp, t5, a3
                  add         t3, t1, s6
                  sll         zero, tp, a0
                  sltiu       ra, t3, -1585
                  c.or        a5, s1
                  c.addi4spn  a0, sp, 336
                  slti        a6, a3, -15
                  xor         s9, s1, sp
                  blt         s7, t0, 99f
                  c.or        a4, a2
                  addi        a1, t0, -2036
                  bge         s5, a1, 86f
                  c.sub       a0, a0
                  mul         s11, ra, a7
                  sll         t0, a7, a6
86:               beq         a3, gp, 100f
                  sra         a6, s11, s10
                  mul         zero, a5, s4
                  auipc       t6, 1043700
                  c.xor       a0, s1
                  srli        a1, t3, 15
                  andi        a2, s8, -1062
                  mul         zero, t0, a1
                  andi        s8, sp, -270
                  mulh        a6, s6, s3
                  bge         s8, s1, 113f
                  c.nop
                  c.addi16sp  sp, -16
99:               blt         a4, t4, 117f
100:              xor         s4, a0, tp
                  and         zero, s10, s7
                  bgeu        a5, s5, 108f
                  c.slli      s8, 3
                  div         ra, t6, s9
                  bltu        a3, t2, 122f
                  divu        s5, a5, a5
                  div         s6, a4, a1
108:              sub         s3, t3, s7
                  nop
                  divu        gp, s7, a6
                  c.sub       s0, s1
                  c.nop
113:              add         a7, s11, t4
                  xor         zero, s11, a7
                  divu        s2, a2, sp
                  c.and       a0, s1
117:              c.srli      a3, 1
                  c.or        a0, a0
                  xori        s8, s0, -1003
                  add         s2, s4, a0
                  blt         a7, a4, 141f
122:              mulhu       s0, s4, s11
                  lui         t0, 402207
                  divu        s7, a2, ra
                  nop
                  bge         gp, t6, 136f
                  andi        a4, ra, 917
                  c.beqz      a4, 145f
                  c.slli      s6, 7
                  or          t6, s1, t0
                  mulhu       gp, s1, t2
                  xori        a1, tp, -59
                  sltu        a4, a4, tp
                  c.add       s2, a7
                  slt         zero, s5, tp
136:              c.srli      a0, 17
                  srai        a0, s0, 21
                  sltu        a0, s6, gp
                  bgeu        t6, a6, 151f
                  or          a1, a6, t0
141:              slti        s2, sp, 1083
                  c.addi      s2, 2
                  c.lui       a0, 12
                  ori         s1, a0, 1699
145:              beq         s7, t6, 160f
                  auipc       a1, 952525
                  and         a5, s7, s8
                  mulh        a7, t6, t6
                  andi        s4, a0, 243
                  srli        a1, t2, 29
151:              sltiu       s5, s7, -140
                  srli        s6, s2, 27
                  c.nop
                  bne         t5, tp, 168f
                  ori         s3, t3, -352
                  c.slli      a1, 24
                  bge         t6, s6, 169f
                  blt         s9, s0, 177f
                  auipc       s6, 429033
160:              srli        s8, s8, 13
                  srai        s2, s1, 7
                  or          a5, s1, s10
                  c.addi4spn  a3, sp, 848
                  c.li        s4, -1
                  and         a0, a0, t1
                  sub         s7, a3, a2
                  nop
168:              divu        s9, a6, s11
169:              c.addi4spn  s0, sp, 656
                  sltiu       a2, t2, 107
                  blt         s3, a7, 173f
                  c.beqz      a2, 180f
173:              c.beqz      a0, 182f
                  srli        t1, a0, 8
                  rem         t3, a2, s11
                  and         t1, s4, a5
177:              c.sub       a0, a2
                  bltu        tp, ra, 195f
                  sltu        sp, a5, a0
180:              mul         a7, s5, s0
                  slt         gp, sp, sp
182:              sra         t4, s8, a1
                  mulhsu      s0, s0, t0
                  mulh        sp, tp, t1
                  slti        a4, t6, -65
                  slli        a3, a1, 24
                  or          a3, gp, t2
                  srl         zero, s10, s2
                  c.slli      ra, 2
                  blt         gp, ra, 209f
                  slli        a6, ra, 18
                  bge         a1, s3, 210f
                  srai        t3, a0, 13
                  mulhu       a7, s2, a5
195:              srl         s8, t2, zero
                  slti        a3, s3, 776
                  c.mv        s8, tp
                  sll         t1, a0, a1
                  srl         a3, s8, s6
                  slli        sp, a7, 18
                  bltu        t0, s3, 213f
                  c.li        ra, -1
                  beq         a3, a7, 217f
                  c.addi16sp  sp, 320
                  c.xor       a3, s0
                  c.lui       tp, 1
                  ori         a2, a2, 1866
                  mulhsu      sp, a0, a5
209:              c.add       s6, ra
210:              slt         t3, a4, sp
                  srai        a7, s11, 13
                  sltiu       a5, s3, 801
213:              sll         a1, s3, t0
                  rem         t0, a1, t0
                  c.andi      a4, 15
                  c.srli      a0, 17
217:              mulh        zero, s5, s8
                  lui         a4, 426786
                  bge         s11, s10, 231f
                  c.addi4spn  a0, sp, 592
                  c.addi16sp  sp, 192
                  blt         t5, a1, 239f
                  c.andi      a0, -1
                  bltu        t1, s0, 232f
                  mulhu       t6, s4, s8
                  rem         s2, tp, s8
                  sra         s4, s0, a0
                  andi        s7, a3, 1895
                  andi        s0, a0, 59
                  c.srai      a1, 16
231:              c.slli      ra, 6
232:              lui         gp, 471041
                  c.slli      a6, 16
                  lui         zero, 800204
                  c.addi4spn  a0, sp, 368
                  bltu        t4, s4, 256f
                  xori        a1, s0, 1352
                  srli        a3, a6, 3
239:              c.and       s1, a2
                  lui         a0, 649793
                  mulhu       gp, s4, s8
                  c.mv        a1, s11
                  slli        s2, s4, 7
                  sra         s4, gp, t4
                  c.and       a0, a2
                  xori        zero, ra, 1287
                  addi        zero, s9, 996
                  nop
                  and         s0, s5, a1
                  sltu        t1, s0, a4
                  andi        tp, a5, 727
                  c.srai      a2, 1
                  divu        s7, tp, t3
                  c.or        a0, s0
                  slti        tp, s1, 1971
256:              bge         zero, t3, 276f
                  add         s11, a2, a6
                  c.beqz      a0, 272f
                  slli        t1, s9, 12
                  c.mv        t1, s2
                  sltiu       zero, t3, 124
                  c.slli      s0, 26
                  slt         ra, a7, a0
                  auipc       zero, 157931
                  c.lui       a2, 22
                  xor         zero, s4, a3
                  divu        a0, t6, a2
                  bgeu        a7, a0, 277f
                  div         s3, a6, s11
                  slti        a0, t6, 1941
                  blt         ra, sp, 273f
272:              sll         zero, a3, a3
273:              slt         a3, gp, a2
                  c.srai      a0, 3
                  c.mv        a5, sp
276:              sra         s1, t0, s3
277:              c.slli      t4, 28
                  sll         zero, gp, sp
                  or          ra, a6, s11
                  srli        a0, s9, 27
                  bgeu        s8, a7, 300f
                  beq         t3, t5, 299f
                  srl         zero, s11, t3
                  lui         tp, 197045
                  xor         s5, s10, t2
                  c.mv        sp, ra
                  c.addi16sp  sp, 464
                  srl         a3, s11, a2
                  c.mv        s0, s3
                  addi        s4, tp, 951
                  srli        a3, t1, 21
                  xor         s6, s0, t0
                  c.nop
                  mulhsu      t0, s4, ra
                  add         tp, t5, ra
                  c.xor       a2, a1
                  bge         t4, gp, 301f
                  lui         a7, 890960
299:              srai        s11, a2, 11
300:              c.xor       a0, a2
301:              slli        s2, t3, 23
                  ori         s3, a4, 1475
                  c.addi16sp  sp, 48
                  mulhsu      a3, s5, s4
                  slti        s5, a5, -311
                  c.xor       a0, a3
                  c.or        a0, a1
                  srl         a5, s4, s4
                  mul         s9, s10, a5
                  rem         a0, a3, s1
                  srai        a2, s10, 23
                  c.sub       s1, a3
                  c.nop
                  sll         t0, zero, s10
                  c.xor       a2, s1
                  slti        s5, a0, -1029
                  slt         a7, s3, gp
                  srl         s1, a0, zero
                  c.lui       s5, 28
                  divu        s1, a2, t3
                  c.srli      a2, 29
                  sltu        t1, a5, s8
                  sra         a4, s3, a0
                  sub         sp, s0, a2
                  c.andi      a0, 7
                  and         s6, a4, t3
                  c.xor       a0, s0
                  divu        zero, sp, a2
                  bgeu        s11, a4, 346f
                  c.srai      a0, 4
                  divu        s8, a4, t5
                  bgeu        sp, s7, 342f
                  add         a7, a1, a5
                  c.addi16sp  sp, -16
                  xori        ra, s9, 922
                  or          zero, t5, s4
                  srai        s1, a3, 17
                  c.addi      s1, 27
                  srl         t3, t3, s0
                  or          gp, t5, gp
                  xori        zero, gp, 1288
342:              c.xor       s1, s1
                  mulh        zero, s9, tp
                  sub         t4, t2, a3
                  c.xor       s1, a2
346:              c.srai      a3, 6
                  c.srli      a0, 8
                  rem         zero, sp, t5
                  c.beqz      a0, 364f
                  c.xor       s0, a1
                  c.srai      a3, 29
                  div         a4, s2, s7
                  div         a1, s2, a3
                  srl         s11, a2, a0
                  divu        s6, a7, s9
                  or          s4, a1, t4
                  andi        s5, s0, -829
                  c.xor       a0, a4
                  add         a3, a0, sp
                  auipc       tp, 663512
                  mulhu       zero, a1, ra
                  sub         a2, a0, t6
                  c.sub       a2, a2
364:              auipc       a7, 777180
                  c.and       a0, a2
                  c.nop
                  c.li        t1, 12
                  divu        tp, s2, tp
                  beq         a1, s5, 377f
                  c.lui       s2, 8
                  bltu        a6, s7, 384f
                  blt         zero, s0, 384f
                  c.xor       s1, a2
                  c.addi4spn  s1, sp, 864
                  addi        zero, a3, 73
                  srli        s6, s3, 8
377:              bgeu        tp, s11, 391f
                  mulh        t0, t0, s0
                  sltiu       s4, t5, 183
                  srl         a6, s6, s9
                  c.addi4spn  a3, sp, 448
                  sltu        s4, s3, a2
                  and         s4, s6, t0
384:              slti        zero, s10, 22
                  nop
                  and         s3, a7, s2
                  bne         a5, t0, 393f
                  xor         s2, t6, a3
                  c.or        a1, a1
                  c.or        a3, a0
391:              divu        sp, a7, s11
                  sltiu       s0, a6, -1161
393:              slt         a7, s10, s7
                  sra         s8, zero, a5
                  c.mv        s8, a5
                  sll         zero, gp, ra
                  bgeu        t0, t3, 416f
                  sub         s9, s2, tp
                  blt         s4, t4, 419f
                  divu        s8, t3, ra
                  auipc       a5, 961663
                  sltiu       a0, s1, 979
                  slt         sp, t2, a3
                  mulhsu      a3, sp, s1
                  mulh        s3, s8, tp
                  c.addi      ra, -1
                  mulh        a1, s6, s2
                  bltu        t5, s9, 410f
                  c.sub       a0, a2
410:              c.srli      a0, 12
                  sltiu       zero, t2, 1035
                  sltiu       s5, s6, 18
                  c.srai      a0, 8
                  add         a0, a3, a6
                  divu        s7, s4, s3
416:              mulhsu      s3, s5, sp
                  c.srai      a0, 29
                  sra         sp, s3, s4
419:              sra         s11, gp, t4
                  c.nop
                  blt         t2, s0, 438f
                  blt         zero, a7, 441f
                  c.addi16sp  sp, 432
                  bltu        s1, t3, 444f
                  c.mv        tp, a6
                  c.addi4spn  a2, sp, 48
                  andi        t1, s5, -521
                  slli        s4, a6, 29
                  slli        t6, s11, 18
                  c.slli      s7, 28
                  c.add       sp, s10
                  c.srli      a0, 24
                  auipc       s1, 738378
                  auipc       zero, 808638
                  and         a1, s0, t6
                  srai        zero, s2, 18
                  srli        s2, s3, 1
438:              c.lui       s9, 20
                  slli        s6, a4, 31
                  sub         a1, t0, a1
441:              c.mv        tp, sp
                  addi        s8, s10, 1076
                  c.beqz      a0, 449f
444:              c.slli      ra, 30
                  c.beqz      a3, 453f
                  slli        t0, s0, 31
                  mulh        a0, zero, a1
                  mulh        a1, t1, s6
449:              rem         s1, s9, t5
                  c.mv        gp, a6
                  bgeu        sp, s9, 471f
                  c.xor       a1, s1
453:              c.addi16sp  sp, -16
                  c.addi4spn  s0, sp, 464
                  rem         s1, s5, s11
                  c.addi      a3, -1
                  bge         t2, a5, 476f
                  bltu        s3, a5, 473f
                  c.srai      s1, 3
                  mulhu       t0, t5, gp
                  sll         s4, s3, a0
                  c.sub       a4, s1
                  bgeu        t1, a4, 475f
                  bgeu        gp, s1, 470f
                  divu        t0, t2, a2
                  srl         s7, s11, a1
                  auipc       zero, 336105
                  srai        a1, a6, 14
                  srl         t1, sp, t5
470:              slt         s9, t2, t1
471:              mulhu       zero, t0, a6
                  lui         s2, 340527
473:              mulhsu      zero, a6, a5
                  mulhsu      zero, a4, t2
475:              c.li        gp, -1
476:              add         a7, t0, t3
                  c.lui       a0, 14
                  divu        t0, a7, s3
                  divu        s7, s1, a7
                  c.li        tp, -1
                  c.addi4spn  a1, sp, 80
                  sltu        s11, s9, t3
                  divu        a0, a3, t6
                  beq         a5, s10, 498f
                  srl         tp, t0, s5
                  c.and       a0, a1
                  c.addi      s1, -1
                  blt         a0, t3, 490f
                  c.addi4spn  a0, sp, 144
490:              slt         s11, s7, s1
                  srai        s0, s6, 12
                  bge         a1, t0, 509f
                  bltu        s2, sp, 510f
                  c.li        s11, -1
                  c.or        a0, a2
                  c.addi16sp  sp, -16
                  c.beqz      a2, 511f
498:              c.slli      ra, 31
                  add         a2, s5, t3
                  xori        s6, s5, -1256
                  c.addi      ra, -1
                  ori         zero, zero, 1474
                  div         t0, tp, ra
                  c.addi      t0, -1
                  div         zero, t6, s3
                  c.sub       a0, a0
                  srli        s8, s2, 29
                  c.lui       s2, 28
509:              auipc       zero, 1046297
510:              rem         zero, s4, s5
511:              mulhu       a0, a0, sp
                  auipc       s11, 379637
                  c.and       a0, a0
                  and         tp, s5, t0
                  sra         s9, a4, t2
                  c.beqz      a0, 535f
                  mulhsu      s5, t2, s6
                  mulh        zero, t6, s8
                  xori        t0, t3, -48
                  lui         a5, 410687
                  lui         a3, 130113
                  blt         s9, gp, 526f
                  slti        s9, a4, -1223
                  mulhu       s0, a7, a1
                  slt         t1, tp, t2
526:              sub         a4, t1, s10
                  add         s0, ra, t6
                  rem         s11, zero, t5
                  bltu        t2, s11, 546f
                  c.beqz      a0, 542f
                  bne         gp, sp, 551f
                  blt         s0, a5, 545f
                  ori         a4, a0, -1870
                  rem         a2, sp, t0
535:              mul         s7, s2, s5
                  sltiu       s3, t3, -886
                  c.srli      a0, 1
                  blt         t2, a7, 546f
                  c.li        s7, 12
                  sll         zero, t6, a6
                  bge         s5, a5, 549f
542:              beq         a6, a2, 560f
                  c.addi4spn  a0, sp, 320
                  sltiu       zero, s6, -1724
545:              c.mv        sp, s10
546:              rem         a3, ra, t3
                  mul         t0, s9, ra
                  xori        s2, t1, -1761
549:              c.add       t1, t4
                  c.nop
551:              c.sub       a3, s1
                  slt         a6, a7, a1
                  addi        t6, a2, 337
                  sll         gp, s4, s4
                  auipc       zero, 428469
                  div         s3, a7, a3
                  mulhu       s7, s4, tp
                  bgeu        s11, s5, 575f
                  mulhu       a1, zero, t6
560:              and         s5, a0, s3
                  sll         a3, ra, a7
                  beq         s1, a0, 576f
                  bne         s9, t1, 582f
                  c.and       a0, a1
                  c.or        s0, a0
                  bgeu        s3, s3, 578f
                  and         t1, s5, tp
                  c.sub       a3, a2
                  bgeu        a1, a3, 575f
                  divu        zero, t5, a3
                  bne         s2, s6, 579f
                  c.mv        s1, t2
                  c.add       a3, tp
                  xor         zero, t2, tp
575:              rem         s8, a4, t5
576:              rem         ra, t6, a4
                  sra         s7, a3, s6
578:              c.andi      a0, 9
579:              slli        a4, s11, 26
                  mulhsu      t3, a5, a7
                  sll         s6, s5, a6
582:              bgeu        s10, a0, 592f
                  srli        s5, a6, 15
                  bge         a0, s7, 593f
                  xor         s5, zero, s5
                  auipc       s7, 484981
                  mul         s3, s6, t2
                  addi        a3, gp, 371
                  sltu        a2, s11, a1
                  c.li        a2, 10
                  c.addi      s9, -1
592:              bltu        t5, t2, 612f
593:              slti        zero, s2, -267
                  c.xor       a2, a3
                  mul         s8, s8, s11
                  c.beqz      a0, 598f
                  lui         ra, 552874
598:              bge         t1, a3, 618f
                  sra         zero, a1, t3
                  or          t1, a0, s2
                  addi        t6, s5, -1986
                  mulhu       sp, zero, a1
                  xor         s11, s8, s4
                  c.beqz      a2, 612f
                  bge         s3, t0, 609f
                  blt         sp, s10, 623f
                  bge         s5, t3, 627f
                  xor         s2, gp, s10
609:              slti        gp, t6, 92
                  slli        a0, a7, 21
                  or          s6, t2, t6
612:              c.slli      a1, 17
                  c.srli      a3, 1
                  sll         t4, s0, s3
                  c.srli      a0, 8
                  slli        s6, s4, 30
                  c.or        a0, s1
618:              c.or        a0, a3
                  c.srli      s0, 3
                  slt         a7, a6, t2
                  c.slli      a6, 7
                  sra         s2, t6, a3
623:              c.and       a1, a3
                  bltu        s1, s5, 638f
                  add         s0, s6, sp
                  c.srai      a2, 5
627:              c.add       sp, a4
                  sltu        s4, s3, t1
                  mul         a4, a6, s2
                  c.andi      a5, -1
                  mul         s8, t1, a5
                  rem         a1, t3, a2
                  sltu        gp, s6, a4
                  add         s5, a6, a5
                  div         gp, a5, sp
                  sltiu       s7, s0, -173
                  auipc       s0, 760548
638:              mulh        s8, a3, t6
                  c.li        t6, 31
                  c.and       a0, a2
                  srli        zero, s9, 17
                  c.and       a0, a2
                  mul         t4, s0, a5
                  c.and       a2, a3
                  c.nop
                  c.mv        ra, a2
                  mulhu       a3, t3, a4
                  c.xor       a0, a3
                  mulhsu      s3, a0, zero
                  c.nop
                  and         s11, a3, tp
                  mulhu       t0, s0, sp
                  or          t4, a3, a5
                  c.addi      s9, -1
                  bne         s10, s11, 674f
                  and         zero, a7, t5
                  bltu        s2, ra, 670f
                  c.mv        t0, a3
                  srli        t1, a6, 21
                  c.and       a0, a1
                  blt         gp, gp, 669f
                  c.srli      a0, 17
                  c.mv        s2, t2
                  beq         t4, t2, 684f
                  blt         t0, t0, 679f
                  c.addi4spn  a3, sp, 432
                  ori         s4, ra, -1224
                  and         t6, t2, ra
669:              c.xor       a4, a1
670:              c.srli      a0, 13
                  c.and       a1, a2
                  c.addi      a6, -1
                  beq         a1, a0, 679f
674:              bne         s3, s7, 688f
                  c.nop
                  c.slli      a5, 18
                  ori         a6, t6, 1150
                  c.xor       a0, a3
679:              beq         ra, a1, 689f
                  c.lui       s6, 16
                  andi        gp, a1, -349
                  ori         sp, tp, 320
                  bne         a3, sp, 695f
684:              sll         s0, t2, t1
                  c.sub       a5, s1
                  rem         gp, s4, t2
                  or          a5, s6, a4
688:              sub         a7, t6, s3
689:              slli        s0, a4, 2
                  c.srai      a0, 14
                  c.li        t3, 17
                  sub         t3, s7, t1
                  sra         s11, t3, s9
                  auipc       a3, 9271
695:              addi        a2, tp, 975
                  c.addi4spn  a3, sp, 272
                  c.lui       t0, 11
                  srai        a7, a5, 23
                  sll         s0, t2, ra
                  c.addi      sp, 24
                  c.add       s5, a2
                  c.addi16sp  sp, 16
                  slli        a1, t1, 26
                  nop
                  xori        zero, ra, -1228
                  sll         sp, zero, s10
                  c.slli      s3, 30
                  c.lui       a4, 25
                  rem         s3, t2, a4
                  sra         a7, t3, s10
                  and         s8, t2, t3
                  c.lui       t4, 17
                  or          s0, a4, sp
                  bge         s10, t0, 716f
                  srl         s7, a5, s9
716:              or          zero, s7, a2
                  bge         a1, zero, 737f
                  blt         gp, a5, 730f
                  mulhu       ra, a5, t1
                  c.slli      s4, 1
                  c.add       sp, a1
                  bgeu        t4, s9, 742f
                  xor         t0, t2, s10
                  slti        s8, t1, -839
                  sra         gp, s10, s0
                  srl         zero, a4, a1
                  sltu        t6, s7, s8
                  bge         zero, a1, 745f
                  srai        t1, t4, 24
730:              mulh        a1, s1, a7
                  c.slli      a7, 1
                  c.mv        a2, a2
                  auipc       s4, 301798
                  slti        a3, s6, 1166
                  c.srli      a3, 10
                  blt         s8, t1, 744f
737:              xori        s1, t3, 229
                  mul         a1, a4, t5
                  c.mv        s5, s11
                  andi        s8, gp, -1719
                  sll         s6, sp, a3
742:              nop
                  c.mv        a2, s2
744:              c.xor       a2, a0
745:              divu        t1, s8, a3
                  lui         a5, 55631
                  mulh        s1, s4, t6
                  c.addi      ra, 3
                  addi        t6, a3, 953
                  c.addi      a2, -1
                  sub         sp, s10, s9
                  slli        ra, a4, 8
                  bltu        a0, a4, 770f
                  sltiu       s9, sp, 368
                  srai        a6, a3, 27
                  c.addi      ra, -1
                  srai        s11, a7, 1
                  sltu        t3, s9, s6
                  blt         t6, t0, 765f
                  c.addi16sp  sp, 464
                  and         a3, t6, a1
                  slti        a5, t5, -996
                  c.or        a0, s1
                  c.sub       a3, a1
765:              c.srli      a3, 9
                  mulhu       s11, t3, s10
                  rem         a3, a4, t6
                  c.li        tp, 19
                  beq         s5, a6, 788f
770:              mul         tp, s2, s3
                  add         s0, s3, a0
                  c.beqz      a0, 784f
                  sub         zero, sp, s0
                  add         s3, s0, s6
                  c.li        a5, 20
                  auipc       zero, 686704
                  c.li        a4, 27
                  c.or        a3, a3
                  c.add       ra, s3
                  sltiu       gp, s9, 679
                  srli        a0, s8, 16
                  mulh        zero, s10, a0
                  c.srai      a0, 10
784:              bltu        a4, s4, 801f
                  mul         a1, s5, s7
                  ori         a6, a3, 1773
                  c.lui       tp, 6
788:              mul         s11, a1, s9
                  div         s3, a0, a7
                  c.li        t0, -1
                  mulhsu      t6, s4, tp
                  c.andi      a0, -1
                  c.li        a6, 13
                  c.beqz      a0, 809f
                  divu        a4, s2, s11
                  bgeu        t5, t1, 814f
                  bge         s4, t0, 799f
                  c.addi16sp  sp, 464
799:              bge         s11, t4, 808f
                  div         t1, s1, a4
801:              c.addi16sp  sp, -16
                  srli        s2, a6, 0
                  blt         s10, zero, 822f
                  c.srai      a1, 22
                  blt         s2, a1, 819f
                  c.lui       a3, 15
                  and         s4, t3, a5
808:              sub         s7, a2, s2
809:              xori        t0, s0, 14
                  slt         t3, s7, a0
                  and         ra, s8, a3
                  rem         s2, t5, a0
                  c.beqz      a0, 832f
814:              blt         s9, s4, 816f
                  and         t1, s2, t1
816:              c.li        a7, 2
                  c.andi      a3, 29
                  srai        a6, s7, 26
819:              andi        s0, tp, -1404
                  c.slli      t3, 19
                  rem         s0, a4, s11
822:              c.nop
                  c.sub       a3, a2
                  lui         t3, 4333
                  c.mv        a6, t4
                  bgeu        a4, a1, 828f
                  addi        s0, s2, -1653
828:              srai        zero, t0, 28
                  c.li        ra, -1
                  addi        s7, s0, 870
                  div         zero, a0, a1
832:              mulh        s2, s11, t6
                  c.and       a3, a3
                  bltu        t4, s6, 854f
                  bltu        s11, s5, 853f
                  blt         s11, tp, 845f
                  mulhsu      zero, a7, s4
                  xori        s11, s3, 618
                  mulhsu      ra, t6, t0
                  slli        ra, t6, 14
                  sltiu       s6, sp, 981
                  c.andi      a3, 1
                  sub         a5, t5, s0
                  srl         s0, ra, sp
845:              c.lui       s2, 7
                  ori         ra, a6, -699
                  lui         s5, 135873
                  nop
                  mul         s8, s2, a2
                  c.srli      a0, 25
                  andi        s8, a5, -1617
                  c.xor       a2, a0
853:              sub         s5, t5, a1
854:              xor         s7, s1, s7
                  bge         a4, tp, 863f
                  auipc       s7, 583971
                  sltu        t1, a1, s8
                  c.li        ra, -1
                  slli        s3, tp, 24
                  lui         s9, 914437
                  rem         t0, t1, t0
                  xor         a1, tp, t4
863:              c.mv        s0, a5
                  bge         a3, a1, 881f
                  mul         zero, a0, s10
                  c.addi4spn  a0, sp, 224
                  sll         t4, s10, s11
                  lui         s0, 352534
                  or          s4, a3, s5
                  auipc       s5, 369000
                  sll         zero, ra, a1
                  c.addi16sp  sp, 64
                  xor         a3, ra, s2
                  add         s7, a4, s4
                  c.add       s4, s0
                  nop
                  beq         a7, s1, 889f
                  bltu        t4, gp, 892f
                  c.lui       t3, 15
                  addi        a7, a0, -1112
881:              sub         a7, a5, ra
                  mulhsu      t4, t5, t1
                  add         a6, a5, s4
                  c.addi      a6, -1
                  mul         s5, a2, t5
                  c.addi16sp  sp, -16
                  xor         s7, s1, t4
                  c.sub       a0, a1
889:              c.srai      a0, 24
                  rem         zero, a0, a2
                  c.srai      a1, 12
892:              slt         s11, t2, gp
                  xor         a2, a7, s4
                  beq         t0, a0, 907f
                  add         a0, t6, s0
                  xori        t1, a5, -1944
                  c.add       s6, s5
                  slli        ra, ra, 10
                  c.add       s4, ra
                  sll         s2, t4, a2
                  auipc       tp, 369797
                  c.slli      ra, 27
                  nop
                  bgeu        a0, s2, 916f
                  xori        ra, t6, -1278
                  bgeu        a0, t4, 923f
907:              c.xor       a2, a2
                  c.li        s6, -1
                  nop
                  sltiu       s3, t2, 2034
                  c.add       a1, a1
                  mulh        s9, t6, s3
                  slli        a3, t6, 7
                  auipc       a1, 75082
                  c.sub       a0, a1
916:              bltu        a6, s1, 924f
                  srl         a4, a3, s7
                  auipc       t0, 777848
                  bge         a2, t3, 938f
                  srai        a7, s3, 14
                  c.nop
                  srl         s5, s4, a5
923:              c.addi16sp  sp, -16
924:              c.li        t6, 6
                  beq         s9, a2, 942f
                  mulh        s3, a3, sp
                  sltiu       s8, a6, -598
                  addi        a6, a5, 1458
                  c.or        a0, a3
                  c.addi4spn  a0, sp, 304
                  sra         zero, s5, a2
                  slt         a1, t1, s1
                  c.andi      a3, 2
                  slli        s4, ra, 13
                  addi        s6, s9, 1475
                  sltiu       a1, zero, 1163
                  mul         t1, s4, a4
938:              c.srli      a1, 18
                  c.addi4spn  a0, sp, 1008
                  beq         t1, t5, 957f
                  c.mv        a7, a7
942:              bge         s0, a6, 948f
                  mulhu       a4, sp, s5
                  c.or        a0, a4
                  bne         t5, s10, 965f
                  c.or        a0, a3
                  srl         t0, s0, a7
948:              c.srai      a0, 12
                  c.addi      s6, -1
                  add         s9, a5, t0
                  div         a0, sp, a6
                  xor         s6, s10, a1
                  auipc       s9, 327786
                  sltu        a3, t3, t5
                  c.li        a2, 29
                  add         zero, s1, s11
957:              rem         a3, t5, tp
                  blt         t3, gp, 972f
                  bltu        a3, t6, 978f
                  srl         s7, a6, s11
                  bne         s1, a2, 971f
                  auipc       s3, 64371
                  c.li        a3, 4
                  bge         ra, s3, 970f
965:              bge         sp, a0, 985f
                  blt         s4, s6, 986f
                  bge         zero, t3, 982f
                  bne         a0, gp, 972f
                  c.srai      a0, 17
970:              slli        s6, s7, 29
971:              auipc       a7, 644876
972:              or          a6, s1, s4
                  c.and       s0, a5
                  mulh        t1, s11, a4
                  divu        t4, sp, t0
                  srai        zero, tp, 22
                  divu        s4, s9, t6
978:              c.lui       ra, 9
                  sub         a1, t4, s11
                  c.lui       s9, 7
                  bgeu        sp, gp, 989f
982:              c.andi      a0, -1
                  c.addi4spn  a0, sp, 144
                  bltu        s9, s3, 996f
985:              andi        zero, s10, -1792
986:              bgeu        s6, t1, 1000f
                  sll         a0, s5, s1
                  c.addi16sp  sp, 304
989:              c.or        s1, a2
                  c.xor       a2, a2
                  bge         t6, t3, 997f
                  c.slli      a6, 9
                  c.addi4spn  a0, sp, 480
                  and         a1, ra, s2
                  c.srai      a4, 29
996:              sra         zero, s5, a4
997:              c.nop
                  sll         t6, s2, t1
                  slti        s11, gp, -1784
1000:             nop
                  c.beqz      a0, 1013f
                  c.addi4spn  a2, sp, 352
                  c.lui       s6, 16
                  bge         s1, t6, 1023f
                  c.addi4spn  a3, sp, 176
                  bltu        t5, s2, 1015f
                  slt         zero, a3, t3
                  c.addi16sp  sp, -16
                  srl         s6, a0, t3
                  mul         zero, t0, a7
                  bne         s10, s9, 1031f
                  mul         ra, t6, s11
1013:             srl         a5, t5, s1
                  bltu        s0, s3, 1022f
1015:             divu        a6, t5, s8
                  div         t6, t6, a1
                  sll         sp, gp, ra
                  sll         s2, s10, a5
                  bltu        t4, s4, 1033f
                  srai        s2, t5, 9
                  add         s11, t4, a5
1022:             sub         s5, t0, t4
1023:             sub         t3, s5, a4
                  bge         a3, s1, 1038f
                  srai        a0, t4, 8
                  slt         zero, s7, tp
                  bgeu        ra, a0, 1044f
                  srl         t6, a4, t4
                  sltiu       t1, s6, 1882
                  sltu        s9, s1, s9
1031:             beq         s9, s0, 1037f
                  sltu        s5, sp, a6
1033:             mulh        s0, s8, sp
                  c.nop
                  andi        t6, s6, 1157
                  mul         s0, t0, ra
1037:             c.addi16sp  sp, -16
1038:             xor         a5, t6, t1
                  auipc       s9, 359386
                  c.andi      a0, -1
                  c.mv        s2, s7
                  c.andi      a0, 27
                  rem         a0, s5, a4
1044:             c.srli      a0, 11
                  slli        a0, t6, 24
                  mul         gp, s11, a2
                  c.mv        a0, a6
                  srl         s7, s0, zero
                  xor         a1, gp, a7
                  c.beqz      a3, 1069f
                  sll         zero, s5, s9
                  sltu        s8, s1, a3
                  sra         t3, a4, a7
                  c.add       t4, s7
                  c.sub       a0, a0
                  bltu        a6, t2, 1068f
                  addi        s4, s5, -893
                  c.slli      s3, 1
                  sll         s3, a7, s11
                  sra         s1, zero, s5
                  c.nop
                  divu        t1, t0, t1
                  bge         ra, s7, 1080f
                  mul         gp, s3, t6
                  sltu        sp, s6, s8
                  srli        a7, s1, 0
                  addi        s7, t3, -296
1068:             beq         s7, s1, 1088f
1069:             mul         tp, a7, sp
                  bgeu        s8, a1, 1082f
                  c.and       a0, a3
                  c.slli      s0, 7
                  sltu        sp, zero, s0
                  c.sub       a2, a2
                  auipc       a0, 483669
                  bltu        a6, s5, 1089f
                  div         zero, s5, s2
                  c.mv        a1, t3
                  nop
1080:             andi        a3, s3, -1757
                  c.srai      a2, 4
1082:             c.srli      a5, 22
                  c.xor       s0, a0
                  sltu        s5, s3, s7
                  c.andi      s1, -1
                  c.andi      a2, 4
                  c.andi      a0, -1
1088:             sltu        gp, a2, t2
1089:             c.addi      s1, -1
                  srai        s3, s0, 19
                  auipc       a7, 477848
                  rem         zero, a2, t2
                  c.sub       a3, a0
                  srli        s0, t2, 20
                  mul         a0, s2, gp
                  or          a0, s11, t3
                  c.or        a0, a3
                  c.or        a2, a2
                  c.and       a3, a2
                  c.addi      ra, 5
                  slt         t3, tp, a1
                  bltu        t0, s0, 1119f
                  andi        zero, s1, 988
                  lui         s11, 882842
                  slli        a2, t5, 19
                  beq         a1, t4, 1123f
                  srai        t4, s4, 12
                  c.addi16sp  sp, 192
                  sub         a6, t1, s4
                  or          s3, s0, t1
                  mul         zero, a0, gp
                  andi        s3, s4, -1013
                  c.mv        s3, ra
                  c.srai      a3, 1
                  c.mv        ra, ra
                  srai        a1, a0, 27
                  and         s7, tp, s2
                  rem         ra, a2, s0
1119:             bge         a3, t3, 1134f
                  c.srai      a3, 15
                  slti        a7, s11, -1815
                  c.nop
1123:             ori         zero, sp, -39
                  bgeu        a3, s9, 1126f
                  c.nop
1126:             addi        a2, s1, -1307
                  bne         gp, s11, 1137f
                  c.mv        t0, s4
                  mul         s1, t0, s4
                  xor         a2, t0, a6
                  c.lui       a7, 30
                  sra         sp, a1, a3
                  mul         ra, s9, a3
1134:             c.mv        gp, sp
                  c.lui       s3, 27
                  sltiu       t6, s8, 1684
1137:             and         a0, gp, t5
                  mulhu       a2, s6, t1
                  c.or        a3, a2
                  c.and       a0, a1
                  c.addi16sp  sp, 384
                  sll         t1, s0, t4
                  c.srli      a0, 23
                  slli        t3, a3, 20
                  sll         t6, a6, s7
                  slti        s9, s0, 1177
                  c.add       ra, s2
                  sub         a7, a2, a1
                  mul         zero, ra, s3
                  c.srli      a0, 24
                  bne         s6, s9, 1159f
                  c.mv        t4, ra
                  sub         s11, a5, s6
                  slti        t6, s2, 511
                  c.li        ra, -1
                  slti        a4, a0, 1931
                  addi        zero, a0, -812
                  srli        gp, a6, 17
1159:             sub         a5, t5, tp
                  c.mv        s2, s9
                  c.beqz      s1, 1165f
                  c.lui       s9, 1
                  add         t3, sp, t2
                  andi        a2, t1, -1280
1165:             slti        zero, s8, -356
                  bgeu        a2, a1, 1184f
                  andi        gp, a2, 1536
                  mulh        sp, a4, a0
                  c.lui       t3, 15
                  and         t4, ra, a2
                  bge         ra, tp, 1179f
                  sub         t3, a0, zero
                  c.sub       a0, a1
                  xori        s9, a6, -1495
                  c.srai      a3, 20
                  c.beqz      a0, 1178f
                  c.xor       a3, a2
1178:             beq         a6, s0, 1198f
1179:             c.beqz      a2, 1198f
                  c.mv        a6, a6
                  lui         t6, 53215
                  c.addi16sp  sp, 160
                  andi        t3, s4, -1544
1184:             mulhu       a6, t5, t5
                  add         a5, s0, t4
                  divu        a7, tp, a3
                  mulhu       s2, zero, s10
                  srai        t1, s10, 25
                  slt         zero, s4, t2
                  xor         s2, s8, s4
                  or          t6, t0, a0
                  srli        a2, zero, 20
                  c.li        a3, -1
                  sltu        t6, s7, a2
                  c.and       a3, a3
                  bgeu        s6, a0, 1216f
                  lui         s8, 199927
1198:             c.slli      a7, 20
                  and         a2, a2, s4
                  c.beqz      a0, 1217f
                  and         s1, s11, ra
                  bne         t2, tp, 1215f
                  srli        zero, s11, 12
                  c.or        a5, a2
                  c.beqz      a3, 1223f
                  sltiu       s7, s2, -1744
                  c.addi4spn  a3, sp, 896
                  c.or        a0, a3
                  c.beqz      a0, 1217f
                  rem         t1, a4, a6
                  c.xor       a2, s0
                  addi        s3, a1, -2035
                  c.li        s3, -1
                  c.slli      t6, 12
1215:             c.srai      a3, 11
1216:             c.li        s9, 20
1217:             auipc       s9, 607366
                  c.andi      a0, 27
                  c.mv        t4, gp
                  c.addi      ra, 13
                  c.add       t1, t0
                  div         tp, s4, ra
1223:             srl         a2, a3, t3
                  c.add       a0, s10
                  mul         tp, a1, s8
                  blt         s9, a4, 1241f
                  add         zero, a4, s7
                  auipc       a3, 550558
                  addi        gp, t3, 1303
                  bgeu        a3, s10, 1238f
                  div         t4, s5, sp
                  xor         t3, a7, a6
                  c.xor       a1, a0
                  sltiu       zero, zero, 680
                  srl         a2, a6, a3
                  srl         zero, s7, s10
                  auipc       zero, 91388
1238:             c.srai      a3, 7
                  auipc       t1, 775645
                  lui         s1, 1000944
1241:             c.and       a0, s0
                  xori        a0, s9, -1975
                  mulhsu      t6, s6, a1
                  c.andi      a2, 12
                  c.beqz      a0, 1257f
                  bne         t0, tp, 1265f
                  slti        a5, ra, -1709
                  bltu        ra, t2, 1262f
                  divu        t1, t4, a6
                  mul         tp, s10, s7
                  sll         ra, a3, s4
                  sltu        s0, s1, ra
                  addi        zero, a7, 1301
                  bltu        a4, a7, 1266f
                  sltiu       s2, t4, 361
                  beq         a0, s5, 1276f
1257:             sll         tp, s2, a6
                  or          tp, a6, a3
                  bge         tp, a7, 1279f
                  c.srli      s0, 1
                  c.mv        a3, s2
1262:             lui         t3, 574979
                  blt         s8, s2, 1267f
                  slti        gp, s1, -731
1265:             c.and       a0, a3
1266:             and         t6, a1, gp
1267:             srl         s7, gp, s3
                  sll         a2, a4, a1
                  c.add       a2, t4
                  srl         gp, t3, tp
                  rem         t3, t3, s4
                  bne         a1, t5, 1289f
                  sltu        s5, a7, s9
                  mulh        zero, t1, s1
                  ori         zero, t2, 1844
1276:             divu        gp, t0, s1
                  bgeu        t5, t5, 1294f
                  bge         s9, s8, 1292f
1279:             c.beqz      a0, 1299f
                  sltu        s11, s6, a3
                  nop
                  xori        s0, gp, 380
                  or          s9, tp, s6
                  srai        a1, t5, 8
                  bne         a1, a5, 1305f
                  bgeu        t1, a6, 1292f
                  srl         t6, a2, t0
                  addi        t3, a1, 1241
1289:             sub         tp, a6, s10
                  auipc       zero, 615677
                  slt         s9, s0, gp
1292:             c.beqz      a0, 1294f
                  or          t4, a2, t5
1294:             c.and       a0, a2
                  lui         a1, 227932
                  sltu        zero, t2, ra
                  bge         t4, s6, 1316f
                  c.addi      t0, -1
1299:             srai        ra, gp, 22
                  c.sub       a0, a2
                  slti        s0, a5, 1348
                  sltiu       sp, a5, 1712
                  sltiu       zero, s5, 722
                  lui         a4, 670717
1305:             rem         t1, s5, s0
                  c.add       a3, s5
                  srli        t3, s4, 13
                  c.lui       a3, 17
                  beq         s10, t2, 1323f
                  c.or        a0, a2
                  sub         s6, a5, t0
                  mul         a3, tp, s1
                  mulhsu      zero, a1, s1
                  beq         tp, ra, 1333f
                  and         a6, s3, t2
1316:             bgeu        a6, s6, 1324f
                  andi        a0, tp, 1650
                  slt         zero, t6, s11
                  c.add       t6, s9
                  sub         a5, s6, s10
                  slt         gp, t5, t5
                  srai        t0, zero, 0
1323:             c.addi      sp, 22
1324:             sra         ra, t0, t1
                  sll         ra, s4, a5
                  mul         a7, s8, tp
                  beq         t1, gp, 1333f
                  sra         zero, t3, s6
                  slli        gp, t2, 18
                  c.addi      s7, -1
                  mulhu       zero, gp, s7
                  mulhsu      a3, a1, tp
1333:             c.and       a0, s1
                  slti        s6, s6, 1605
                  c.addi16sp  sp, 272
                  ori         t4, a0, 116
                  srai        a4, a7, 28
                  c.or        a0, a3
                  bge         s0, tp, 1341f
                  and         s4, s1, s3
1341:             ori         a7, s8, 589
                  c.add       ra, s1
                  mulhu       s11, s0, s3
                  c.xor       a0, a2
                  add         zero, a4, s10
                  bltu        a2, s11, 1355f
                  add         s4, s8, a7
                  bltu        s3, s11, 1360f
                  c.slli      a0, 13
                  slti        s11, s8, -1446
                  div         ra, t1, s10
                  c.add       s2, t4
                  bltu        s11, s9, 1363f
                  c.addi16sp  sp, 448
1355:             andi        a4, s5, -110
                  sltiu       t0, s10, 616
                  add         t4, sp, a2
                  bne         s5, t6, 1375f
                  c.slli      s7, 14
1360:             c.nop
                  andi        s11, a5, 598
                  c.and       a3, s1
1363:             c.sub       a0, a0
                  ori         t3, a1, 934
                  bgeu        t4, gp, 1385f
                  sltu        s1, tp, a4
                  slli        a3, s5, 29
                  c.addi      ra, 30
                  slli        a6, t4, 5
                  mulhu       a2, s6, s7
                  bge         t0, t4, 1388f
                  c.nop
                  c.li        s4, 26
                  sub         gp, sp, s2
1375:             c.or        s1, a3
                  add         t6, s2, t6
                  auipc       a6, 75506
                  xor         s0, zero, a2
                  nop
                  sltiu       s9, t6, -1874
                  addi        s8, s4, 1533
                  sltiu       zero, gp, -40
                  sra         s4, t3, s0
                  rem         t0, s9, a2
1385:             andi        s4, tp, -1619
                  blt         a0, t1, 1406f
                  or          sp, s2, t5
1388:             srai        a0, s7, 3
                  sub         t1, s8, s2
                  xor         s5, a4, s9
                  c.srai      a0, 15
                  c.andi      a2, 29
                  c.or        a0, a4
                  xor         t0, a5, ra
                  xor         s2, ra, s10
                  nop
                  c.srli      a1, 13
                  mulhu       t6, a4, a4
                  sub         zero, a6, s4
                  mulhsu      s11, s9, t2
                  div         s2, a1, a0
                  sub         zero, s0, a4
                  c.or        a0, a0
                  c.addi4spn  a5, sp, 528
                  c.add       ra, sp
1406:             blt         s0, s8, 1419f
                  div         s8, t1, s11
                  addi        s5, a5, 177
                  c.andi      a0, 31
                  blt         t1, a0, 1424f
                  c.srli      s0, 1
                  slt         a1, s1, ra
                  bgeu        zero, a2, 1422f
                  div         a0, s5, t0
                  mul         zero, a0, sp
                  c.srli      a0, 19
                  add         a4, t0, s10
                  srli        s6, t0, 29
1419:             c.slli      s1, 19
                  c.add       s1, tp
                  c.mv        s7, s10
1422:             bge         t0, s9, 1437f
                  bgeu        t6, t2, 1425f
1424:             mul         s11, t4, a7
1425:             c.srai      a0, 11
                  c.and       a0, s1
                  bne         t5, a6, 1446f
                  c.addi      gp, 10
                  mulhsu      zero, s9, tp
                  srl         s3, s10, s4
                  slli        ra, ra, 23
                  mulhu       a1, t2, gp
                  c.lui       t4, 27
                  mul         a1, s6, s1
                  c.beqz      a0, 1454f
                  c.srai      a0, 25
1437:             sltu        sp, a6, sp
                  srai        tp, s9, 9
                  sll         s8, s3, a0
                  srl         t6, s6, t1
                  bltu        t0, s10, 1461f
                  c.slli      s9, 28
                  xor         s8, a0, s9
                  xori        a0, tp, -1140
                  mulhsu      s6, ra, s2
1446:             sll         s9, s10, s8
                  mulhu       zero, s6, s7
                  c.srai      a5, 17
                  c.or        a0, a3
                  ori         a4, t4, 2024
                  sub         a0, s1, t5
                  bgeu        s4, s1, 1456f
                  c.lui       ra, 7
1454:             sll         a7, s0, s3
                  c.addi4spn  a1, sp, 48
1456:             div         a6, tp, a1
                  srai        s5, t1, 23
                  c.slli      t4, 25
                  srli        a3, s1, 6
                  blt         t6, zero, 1462f
1461:             div         s3, t1, gp
1462:             c.slli      gp, 29
                  srli        ra, a7, 17
                  c.xor       a0, a0
                  div         s11, s3, sp
                  c.and       a0, s0
                  c.mv        gp, t4
                  xor         ra, sp, tp
                  c.or        a0, s1
                  sra         s5, s9, tp
                  ori         gp, s10, 545
                  bltu        gp, s3, 1484f
                  and         s8, t1, s9
                  c.mv        s6, t3
                  c.or        a0, a3
                  c.and       a0, a1
                  mulh        a1, s9, t4
                  blt         ra, gp, 1486f
                  c.srai      a1, 8
                  or          s5, s1, a1
                  auipc       a4, 307670
                  xori        t1, s10, -1299
                  sll         s9, s8, s3
1484:             add         a5, s4, a4
                  c.andi      a3, -1
1486:             c.addi16sp  sp, 320
                  c.addi4spn  a3, sp, 32
                  and         zero, t6, a1
                  ori         a7, s2, 1061
                  mulh        a5, s3, gp
                  rem         t4, gp, gp
                  c.mv        sp, t5
                  bltu        t4, t2, 1513f
                  addi        s6, t0, 1177
                  c.srai      a0, 29
                  c.srai      a2, 13
                  lui         tp, 193014
                  c.mv        s1, s5
                  add         s6, t5, a6
                  bge         gp, zero, 1508f
                  bge         s7, t6, 1507f
                  nop
                  c.addi      s9, -1
                  mulhsu      t6, ra, t5
                  or          s11, a4, s4
                  c.li        sp, -1
1507:             ori         s7, t4, -168
1508:             srl         zero, s7, s7
                  c.addi      tp, -1
                  mul         a4, t1, sp
                  divu        a5, a1, s2
                  mulhu       zero, t5, a2
1513:             sll         t4, s9, t6
                  c.and       a0, a0
                  addi        a1, t6, 436
                  sra         s9, s9, zero
                  sltiu       s4, a7, 566
                  and         t3, t6, s9
                  ori         zero, sp, 1802
                  srl         s9, s10, gp
                  c.xor       a1, a3
                  c.mv        s2, s6
                  sltiu       zero, a0, 886
                  or          t6, s4, sp
                  or          zero, s6, a0
                  c.slli      t0, 9
                  c.addi4spn  a0, sp, 144
                  rem         zero, s10, t0
                  sra         zero, a5, a0
                  c.lui       ra, 14
                  c.and       a0, s1
                  xori        zero, a6, -1794
                  addi        zero, s3, 774
                  sra         s4, s0, a0
                  sra         tp, s11, s1
                  c.and       a3, a3
                  bgeu        t3, a7, 1554f
                  c.srai      a2, 13
                  c.addi16sp  sp, 32
                  c.mv        a4, s5
                  c.slli      ra, 25
                  mulhsu      t3, ra, t0
                  lui         t0, 595653
                  sltu        s3, t4, s2
                  c.addi16sp  sp, 448
                  nop
                  bne         s7, a1, 1561f
                  c.addi      s9, -1
                  mul         tp, s4, t2
                  c.xor       a0, a3
                  bltu        t3, gp, 1568f
                  mulhu       s9, s3, a7
                  srl         a4, gp, s11
1554:             lui         a4, 791748
                  srai        s7, s8, 17
                  sra         t3, s2, a6
                  beq         s5, s0, 1565f
                  srl         zero, t4, gp
                  blt         a6, t6, 1569f
                  mulhu       t4, t5, s1
1561:             c.beqz      a0, 1578f
                  sltu        tp, s10, a3
                  c.mv        t0, ra
                  c.sub       s0, a5
1565:             c.beqz      a0, 1583f
                  nop
                  divu        a4, a0, t5
1568:             slt         s8, s7, t1
1569:             c.sub       a0, s0
                  andi        t0, s0, -1906
                  c.addi      ra, 29
                  c.add       ra, sp
                  c.or        a3, a3
                  c.lui       gp, 8
                  c.beqz      a4, 1587f
                  nop
                  add         sp, ra, s6
1578:             mulhu       a0, a4, a0
                  srli        t4, t1, 29
                  bltu        s3, zero, 1599f
                  mulh        s5, t6, a4
                  slti        zero, a3, -1805
1583:             c.addi4spn  s1, sp, 16
                  c.slli      s6, 24
                  blt         s2, t0, 1591f
                  mulhsu      s7, t3, a2
1587:             c.addi4spn  a3, sp, 704
                  c.nop
                  div         a7, ra, t4
                  slli        a2, a5, 0
1591:             lui         a5, 656779
                  slti        t4, a6, -1969
                  c.srai      a0, 20
                  c.andi      a2, -1
                  c.lui       s11, 17
                  srl         a2, t1, s2
                  srai        zero, a0, 31
                  sll         t1, ra, a2
1599:             c.mv        a4, s10
                  blt         s11, tp, 1612f
                  ori         zero, s2, 1886
                  mulh        gp, a3, gp
                  c.srai      a2, 19
                  beq         s0, t1, 1618f
                  c.addi16sp  sp, -16
                  add         s11, a2, a5
                  srli        s5, t0, 27
                  ori         s6, tp, 1721
                  xori        zero, t6, -1861
                  nop
                  c.addi16sp  sp, -16
1612:             slt         s5, zero, a3
                  and         a1, zero, s8
                  beq         t6, s11, 1616f
                  mulhu       s8, a4, tp
1616:             bltu        s0, t2, 1624f
                  blt         gp, zero, 1634f
1618:             sub         a4, a7, s10
                  slti        a4, s11, -830
                  c.mv        ra, s4
                  c.andi      a0, -1
                  or          t3, s7, a1
                  auipc       zero, 943529
1624:             c.addi      s1, 19
                  c.xor       a2, a2
                  lui         s6, 84518
                  sltu        s4, s5, s8
                  c.lui       s3, 14
                  sll         t3, s5, s10
                  c.sub       a0, a2
                  xori        s7, ra, 701
                  c.or        a0, s0
                  c.and       a0, a3
1634:             c.mv        s2, t2
                  addi        s1, s1, -1745
                  slli        t4, a3, 18
                  rem         s0, s6, s0
                  and         a4, s8, s1
                  c.mv        a7, a7
                  c.li        s8, -1
                  slt         a3, gp, s1
                  mul         tp, a0, a4
                  c.srli      a0, 17
                  c.addi4spn  a0, sp, 496
                  rem         s2, a1, s6
                  c.sub       a0, a2
                  lui         t4, 971526
                  rem         s2, t0, s11
                  bltu        s6, a2, 1659f
                  sra         t6, t4, t1
                  mulhsu      s0, a5, t0
                  sltiu       a4, t2, 1246
                  sltu        sp, a5, s4
                  xor         zero, s7, gp
                  c.andi      a2, 18
                  or          ra, s9, s1
                  xori        t6, a3, 1080
                  c.addi16sp  sp, -16
1659:             c.and       a2, a1
                  c.andi      a0, 24
                  slti        s8, t2, -1639
                  ori         s2, s0, -1864
                  and         s2, s11, gp
                  bgeu        t5, t6, 1668f
                  sll         gp, a1, t3
                  or          t6, s2, a2
                  srli        t0, tp, 26
1668:             xor         s6, a3, t2
                  sub         s0, a7, s11
                  bgeu        s6, a7, 1690f
                  mulhu       t6, sp, s3
                  srl         zero, a5, gp
                  nop
                  addi        s11, t6, -1293
                  mulhsu      s0, t6, zero
                  mulh        t0, s4, t4
                  or          t1, t1, a2
                  slti        zero, sp, 585
                  c.xor       a0, a1
                  slti        s2, t6, -840
                  srai        zero, s4, 6
                  sltiu       s4, a6, -318
                  xori        s7, s1, -206
                  c.li        a4, -1
                  mul         tp, s5, sp
                  auipc       s4, 8172
                  c.sub       a0, a3
                  bltu        s8, a4, 1708f
                  c.addi16sp  sp, 496
1690:             or          t0, t6, zero
                  sra         s11, a2, s0
                  sltiu       s9, ra, 1672
                  add         s0, a0, zero
                  slt         s9, t6, t6
                  c.addi16sp  sp, -16
                  c.mv        a0, t2
                  xori        zero, zero, 1466
                  c.xor       a0, a1
                  c.and       a0, s0
                  sra         zero, s6, t4
                  sll         s0, s2, s4
                  bgeu        s6, ra, 1716f
                  c.srli      a2, 29
                  c.lui       ra, 14
                  mulhu       a3, s5, t0
                  c.addi16sp  sp, -16
                  mulh        t6, s8, a0
1708:             sltu        a2, s6, gp
                  divu        t1, s3, zero
                  c.addi      ra, -1
                  c.li        a7, -1
                  mulhsu      t0, a0, gp
                  auipc       zero, 773890
                  div         s0, s8, s11
                  slli        s1, t3, 14
1716:             sra         s8, sp, a4
                  slli        a6, s5, 28
                  c.and       a1, a0
                  divu        t0, s8, t3
                  c.sub       a3, s0
                  mulh        ra, s0, s4
                  or          t0, zero, s3
                  or          s1, a6, s11
                  rem         s1, s10, s0
                  c.addi4spn  a0, sp, 32
                  srl         s5, s7, s4
                  slt         s3, s0, s11
                  c.add       t4, t5
                  xor         a4, t5, t6
                  srli        a3, t1, 26
                  c.slli      ra, 15
                  sub         s8, s9, gp
                  slt         t3, s4, t4
                  c.addi4spn  a0, sp, 272
                  c.beqz      a0, 1750f
                  bne         a6, s2, 1756f
                  div         s2, s8, s8
                  auipc       a4, 356457
                  xori        tp, a6, 1076
                  bltu        zero, s1, 1746f
                  slli        s4, s9, 17
                  srli        ra, t4, 11
                  rem         zero, sp, s3
                  c.add       t3, s0
                  c.and       a0, s0
1746:             c.sub       a1, a2
                  xor         t6, s2, s2
                  rem         s11, s4, a6
                  nop
1750:             sltu        gp, t3, a1
                  add         s11, s10, a3
                  mulh        t6, t3, s4
                  andi        ra, s7, -432
                  c.lui       ra, 12
                  addi        zero, a6, -1381
1756:             c.addi16sp  sp, 368
                  sltu        s3, a1, ra
                  c.xor       a0, a1
                  c.or        a1, a3
                  c.addi      s0, -1
                  addi        a7, t0, -1669
                  auipc       s6, 226839
                  and         zero, a6, sp
                  rem         zero, t1, s0
                  add         t1, t6, s8
                  auipc       a4, 844511
                  bge         s1, t5, 1784f
                  c.mv        s11, ra
                  c.srai      s1, 7
                  divu        s11, t0, ra
                  blt         s3, s6, 1783f
                  div         zero, s10, s9
                  c.and       a3, a2
                  sll         zero, a0, s6
                  bne         a6, sp, 1789f
                  sll         s3, s1, s4
                  addi        s5, s11, 1376
                  ori         s3, a4, 673
                  sll         s6, s7, t5
                  mul         ra, a7, a3
                  nop
                  xori        s8, s7, 1353
1783:             mulh        t6, a2, a4
1784:             slli        a0, a3, 6
                  c.beqz      s0, 1793f
                  c.beqz      a0, 1792f
                  c.li        sp, -1
                  divu        t3, s2, t2
1789:             rem         a3, t2, t0
                  bne         sp, zero, 1802f
                  c.or        a0, a3
1792:             c.mv        tp, a7
1793:             xor         tp, a4, t3
                  srai        zero, s7, 0
                  xor         s3, a6, a7
                  c.srli      a2, 15
                  nop
                  rem         a0, a2, a1
                  lui         s1, 598138
                  bne         t0, s0, 1817f
                  divu        s8, s3, t6
1802:             c.lui       s7, 14
                  c.add       gp, s11
                  c.mv        ra, tp
                  c.nop
                  c.addi      t1, -1
                  ori         s11, a6, -844
                  xor         a1, t0, s3
                  mulhu       s1, t6, s4
                  c.or        a0, a2
                  srai        s3, a7, 3
                  bgeu        a4, a3, 1821f
                  srai        ra, s0, 2
                  srli        t6, a5, 23
                  lui         sp, 99779
                  c.xor       a0, a2
1817:             bne         tp, a1, 1836f
                  c.addi4spn  a1, sp, 208
                  bge         a6, t5, 1827f
                  c.addi4spn  a0, sp, 640
1821:             sltu        s0, ra, s3
                  lui         zero, 119516
                  c.addi      s9, 12
                  sll         t1, t1, s6
                  blt         a7, t0, 1827f
                  slt         a0, s0, s8
1827:             bne         tp, t4, 1846f
                  mulhsu      s6, t0, s9
                  sltiu       a4, gp, -18
                  and         s7, a5, t6
                  c.nop
                  c.srli      a0, 28
                  or          s11, gp, a6
                  c.addi      s6, -1
                  c.xor       a3, a3
1836:             sltu        a6, a1, a6
                  sub         zero, a4, t6
                  beq         s9, s3, 1857f
                  c.addi      a3, -1
                  c.xor       a3, a3
                  sltu        t0, t3, s5
                  c.lui       t3, 19
                  nop
                  c.mv        s5, s10
                  bne         t3, sp, 1857f
1846:             divu        s6, a1, a5
                  c.addi      t6, 14
                  auipc       s4, 768141
                  mulh        zero, a6, a7
                  bgeu        t6, s11, 1863f
                  slli        a1, a4, 10
                  divu        a3, t4, ra
                  mul         zero, t2, s1
                  c.addi      sp, 13
                  c.add       sp, s3
                  c.srli      a3, 9
1857:             c.addi      sp, 19
                  c.xor       a3, a2
                  c.nop
                  ori         s0, a7, -1709
                  slti        s2, s10, 1503
                  mul         zero, s3, t4
1863:             lui         zero, 806199
                  c.mv        ra, a5
                  c.addi      tp, -1
                  c.addi4spn  s0, sp, 144
                  bge         gp, s6, 1885f
                  nop
                  sra         s2, a6, s7
                  sra         zero, s4, s7
                  slli        ra, s2, 17
                  sltu        a1, ra, ra
                  sra         a7, a6, t0
                  c.nop
                  c.or        a3, s1
                  srli        s3, t3, 7
                  c.addi16sp  sp, 64
                  c.and       a0, a1
                  mulhu       s11, gp, tp
                  c.addi      a7, -1
                  c.andi      a3, 24
                  slti        a3, s10, 2033
                  c.nop
                  c.addi4spn  a0, sp, 496
1885:             slt         gp, s0, s10
                  mulh        gp, s4, a7
                  bltu        sp, t4, 1907f
                  c.li        ra, 7
                  div         a4, a4, a4
                  auipc       a6, 806659
                  ori         a5, sp, 1249
                  sll         s3, a0, s7
                  ori         s7, t0, -246
                  or          a3, s7, sp
                  c.or        a3, a1
                  c.addi4spn  a0, sp, 160
                  div         t6, a1, s0
                  xor         s6, a5, t3
                  c.srli      a5, 24
                  blt         s5, t0, 1917f
                  c.slli      s2, 14
                  c.lui       t3, 17
                  srl         a4, a2, zero
                  bgeu        a5, t0, 1918f
                  c.nop
                  slt         zero, a3, s4
1907:             div         s8, a7, s0
                  slt         t4, ra, s5
                  auipc       s2, 148364
                  andi        tp, s0, -539
                  c.li        gp, 30
                  xor         a3, s5, tp
                  div         s5, s11, t5
                  c.nop
                  ori         t4, a7, -1036
                  slli        zero, gp, 18
1917:             xor         zero, t0, t0
1918:             beq         zero, t4, 1922f
                  slli        s8, a1, 3
                  c.andi      a0, -1
                  c.xor       a0, a2
1922:             bgeu        s0, ra, 1930f
                  and         a1, t3, a4
                  c.srai      a3, 26
                  c.srli      a3, 6
                  srai        tp, s1, 7
                  slli        ra, t5, 10
                  c.lui       ra, 3
                  c.and       a4, a3
1930:             bgeu        s10, ra, 1950f
                  slt         a7, s4, sp
                  c.srai      a0, 3
                  srl         sp, s0, a2
                  blt         tp, a2, 1942f
                  sltiu       zero, a7, -673
                  c.li        s0, 0
                  mulhu       s4, a7, s5
                  srai        a0, a2, 8
                  sra         t0, a6, a7
                  srli        s0, t0, 17
                  c.add       s2, s0
1942:             div         t4, t0, sp
                  beq         s10, s6, 1957f
                  addi        s11, s0, 594
                  c.srai      a3, 28
                  srli        a4, a7, 15
                  bgeu        t5, t6, 1964f
                  slti        a0, ra, -352
                  c.mv        a7, a6
1950:             or          t1, s1, s3
                  c.addi      t0, -1
                  c.xor       a3, a0
                  c.beqz      a2, 1973f
                  c.addi16sp  sp, -16
                  c.nop
                  nop
1957:             addi        s4, t4, 815
                  xori        s6, t6, 1650
                  nop
                  c.addi      s4, -1
                  add         a5, s4, t6
                  rem         s3, sp, s5
                  c.mv        t6, ra
1964:             c.li        a4, -1
                  xori        s4, t1, -906
                  nop
                  mulhsu      zero, t0, a5
                  srai        s7, s8, 14
                  ori         a5, t1, -679
                  or          s2, a5, s7
                  c.mv        s6, a1
                  c.xor       a0, a0
1973:             divu        zero, t3, s3
                  sll         zero, s3, t2
                  sra         a6, a6, ra
                  nop
                  c.andi      a0, -1
                  lui         s1, 143816
                  mul         a4, t4, a4
                  add         a4, t2, a5
                  addi        t3, s2, -1819
                  or          zero, zero, ra
                  c.li        sp, -1
                  mulhu       a1, zero, s5
                  slti        s1, ra, 363
                  auipc       s0, 401372
                  c.add       a4, a0
                  c.addi4spn  a3, sp, 16
                  c.addi      tp, 4
                  c.li        a3, -1
                  slti        a6, zero, 1989
                  c.li        t1, 19
                  c.or        a3, a1
                  srai        s2, s7, 19
                  xori        zero, a6, -463
                  beq         s7, s1, 2010f
                  c.addi4spn  a3, sp, 576
                  add         s2, s1, s5
                  blt         s4, t5, 2011f
                  nop
                  srli        s2, a4, 29
                  auipc       zero, 710796
                  c.and       a0, a2
                  slt         t0, a2, tp
                  auipc       s6, 38278
                  c.andi      a0, 14
                  c.mv        s9, s10
                  div         zero, s8, s9
                  rem         a7, a3, a1
2010:             c.sub       a3, a1
2011:             slli        s0, a2, 2
                  c.sub       a3, a0
                  c.andi      a3, -1
                  c.addi4spn  a2, sp, 592
                  c.lui       gp, 4
                  c.mv        s8, a1
                  sub         s3, s10, a4
                  bne         s0, t6, 2020f
                  rem         gp, s2, s2
2020:             sra         s4, t3, a7
                  sltiu       s6, gp, 929
                  mulhsu      a7, s2, zero
                  c.srai      a3, 21
                  c.mv        a0, a3
                  c.add       a7, a7
                  beq         s1, a2, 2045f
                  nop
                  sub         s7, ra, a1
                  c.beqz      a0, 2044f
                  or          a4, t6, sp
                  srai        sp, s7, 31
                  andi        tp, sp, -1396
                  c.srai      a0, 5
                  mulhu       a6, s4, s1
                  c.sub       a0, a1
                  srl         s2, t0, t2
                  c.srli      a0, 22
                  or          zero, tp, s3
                  c.sub       a1, a5
                  lui         gp, 16558
                  and         a6, t0, tp
                  bltu        a2, s3, 2054f
                  blt         s9, t0, 2063f
2044:             lui         sp, 560378
2045:             sltiu       a0, t2, -1269
                  c.or        a3, a1
                  c.addi      s8, 17
                  c.addi16sp  sp, 416
                  mulh        a1, sp, a6
                  c.mv        s3, a7
                  c.slli      a5, 17
                  c.addi4spn  a1, sp, 16
                  ori         t3, t2, 1398
2054:             or          zero, a7, s2
                  ori         s1, s1, 1148
                  ori         s2, t6, 1358
                  c.nop
                  bge         s0, s8, 2066f
                  srli        zero, s4, 1
                  c.beqz      a2, 2077f
                  c.nop
                  beq         a0, a3, 2072f
2063:             bne         zero, s5, 2077f
                  c.nop
                  bltu        t4, a3, 2074f
2066:             c.and       a3, a1
                  c.addi16sp  sp, -16
                  c.srai      a1, 9
                  c.addi      t4, -1
                  lui         s5, 52045
                  addi        t6, gp, -679
2072:             andi        a4, a5, -1236
                  c.xor       a0, s1
2074:             nop
                  sll         t1, s0, s8
                  mulh        t4, zero, ra
2077:             bgeu        t5, a1, 2083f
                  c.slli      a1, 25
                  bge         s9, t4, 2097f
                  c.srai      a0, 24
                  c.xor       a0, a3
                  nop
2083:             srli        a5, a1, 1
                  c.addi      s5, -1
                  div         s4, a1, t6
                  bgeu        s11, tp, 2105f
                  c.nop
                  auipc       zero, 241415
                  sltiu       a1, s7, 784
                  div         zero, a0, s2
                  andi        s4, s9, 1291
                  nop
                  ori         zero, t2, 1506
                  beq         ra, s7, 2106f
                  addi        a2, t3, 1170
                  add         t3, ra, s4
2097:             c.and       a3, s1
                  mulhu       s2, s5, t2
                  div         s9, s1, s1
                  divu        gp, a6, ra
                  bgeu        s10, zero, 2121f
                  c.li        a0, -1
                  slli        a0, t6, 26
                  slti        a6, a1, -1188
2105:             srl         s7, s8, tp
2106:             xor         zero, a7, t5
                  slli        a1, t0, 22
                  addi        s4, t4, 1460
                  bne         s4, s1, 2111f
                  c.sub       a2, s1
2111:             c.xor       a2, a2
                  c.mv        sp, gp
                  bne         zero, t0, 2130f
                  c.lui       a7, 18
                  c.lui       a7, 31
                  auipc       gp, 313102
                  mul         s4, a0, a7
                  addi        s7, ra, -952
                  c.addi4spn  a5, sp, 144
                  nop
2121:             sra         a4, s10, s0
                  bne         a4, s2, 2141f
                  sll         tp, s6, a6
                  sub         s2, s1, t4
                  nop
                  addi        a7, t5, 14
                  mul         s3, s7, gp
                  c.xor       a0, a2
                  div         s9, a3, a6
2130:             xor         s9, sp, t3
                  andi        zero, s1, 1094
                  c.sub       a0, a1
                  beq         a1, a2, 2146f
                  bltu        t2, s2, 2151f
                  c.xor       a0, s0
                  bgeu        a4, t0, 2142f
                  slti        zero, s11, 1254
                  mulhsu      s1, t0, s1
                  c.and       a0, a2
                  c.or        a3, s1
2141:             c.addi      gp, -1
2142:             c.srai      a4, 19
                  c.srai      a0, 18
                  add         a2, a4, tp
                  addi        a4, s11, 1797
2146:             beq         a1, t4, 2158f
                  c.xor       a0, a0
                  bne         s11, t4, 2157f
                  srl         t4, s9, a3
                  sra         s2, t5, s6
2151:             c.srli      a3, 23
                  xori        t4, ra, -1974
                  blt         a3, s6, 2170f
                  div         zero, s11, s6
                  c.andi      a0, 10
                  sltu        a6, a6, sp
2157:             sltu        a2, a1, a4
2158:             c.add       s6, a5
                  c.lui       gp, 1
                  mulhsu      zero, s1, s10
                  ori         s3, t1, -1489
                  div         a4, a6, t2
                  divu        a5, s9, s9
                  c.addi16sp  sp, 16
                  and         zero, s0, s1
                  c.xor       a2, a1
                  c.addi4spn  s1, sp, 368
                  c.or        a0, a3
                  sltu        zero, a1, t6
2170:             c.addi      s2, -1
                  bge         s3, a5, 2173f
                  xor         zero, s1, a2
2173:             c.or        a0, a2
                  c.or        a0, a1
                  c.andi      a3, 4
                  sra         s11, s7, t2
                  rem         zero, sp, s3
                  addi        zero, s9, -63
                  andi        ra, a2, 628
                  srl         zero, sp, t6
                  c.addi      a1, 14
                  andi        a3, s8, -1581
                  ori         t3, t1, -1629
                  sra         sp, a6, t6
                  addi        s0, s0, -298
                  c.xor       s1, a3
                  sll         t6, a1, s2
                  and         t3, t1, s2
                  ori         zero, s6, -1441
                  slti        t4, a2, -89
                  c.lui       s1, 30
                  c.nop
                  lui         s11, 262888
                  slli        a2, t6, 13
                  add         zero, s9, t1
                  mulhsu      t6, ra, s4
                  andi        a1, t5, -1613
                  ori         s3, a4, -866
                  bgeu        s6, zero, 2205f
                  sra         t4, s10, s8
                  blt         s0, a4, 2221f
                  bgeu        t5, t4, 2216f
                  c.nop
                  andi        a2, s7, -77
2205:             slt         a0, s3, s2
                  xori        gp, s3, 1743
                  c.li        a3, -1
                  mulh        tp, t3, a1
                  c.beqz      a2, 2211f
                  c.beqz      a0, 2218f
2211:             sra         s7, s5, s0
                  sub         t4, s5, a1
                  c.li        ra, 29
                  addi        a3, ra, -70
                  div         s11, a5, a3
2216:             rem         zero, s8, s10
                  slt         a3, gp, s4
2218:             and         s9, s8, tp
                  blt         s4, t2, 2229f
                  c.and       a0, s1
2221:             srai        t6, tp, 20
                  blt         tp, zero, 2236f
                  blt         s8, tp, 2242f
                  andi        s7, a3, 1051
                  c.nop
                  mulh        s11, s3, a1
                  c.addi      s0, 27
                  srl         s0, t0, a7
2229:             mulhsu      a0, t4, s7
                  c.srli      a2, 19
                  lui         t3, 867761
                  and         a6, tp, a1
                  auipc       s2, 656453
                  div         s4, s4, t6
                  sltiu       s3, s9, 362
2236:             addi        s11, s8, 1393
                  c.xor       a2, s1
                  or          zero, s6, a5
                  add         a1, s10, s4
                  c.or        s0, a0
                  c.li        s7, 0
2242:             c.andi      a0, -1
                  nop
                  div         s9, t4, s3
                  xor         s7, sp, a4
                  c.li        a1, 18
                  c.srli      a3, 25
                  sll         a1, s0, s8
                  mulh        tp, t1, t5
                  sll         gp, s5, a3
                  lui         a5, 83668
                  beq         s10, t1, 2269f
                  divu        t0, t0, a2
                  mul         t1, s2, a6
                  nop
                  srai        t3, gp, 27
                  c.or        a2, a0
                  xor         t6, t5, a4
                  and         s3, s8, a4
                  c.and       a3, a1
                  c.beqz      a0, 2274f
                  or          s7, s0, gp
                  nop
                  c.and       a3, s1
                  c.xor       a0, a3
                  divu        s6, sp, t6
                  xor         s6, t0, s9
                  div         a3, a2, t2
2269:             auipc       s6, 272887
                  c.mv        t1, a3
                  c.nop
                  addi        sp, s7, -1713
                  andi        s9, s5, -312
2274:             mul         t6, a0, s6
                  bge         t0, a4, 2294f
                  c.slli      a2, 26
                  bne         zero, s3, 2294f
                  divu        s9, s5, s3
                  c.beqz      a0, 2283f
                  c.xor       a2, a1
                  sltu        zero, t1, t0
                  rem         zero, a4, s9
2283:             bltu        zero, a5, 2300f
                  xor         s8, a5, a3
                  slt         a3, t5, s5
                  lui         s6, 991392
                  sra         s5, gp, tp
                  lui         a3, 506625
                  c.beqz      a3, 2295f
                  slti        zero, s8, -373
                  xori        ra, ra, -114
                  mulhu       zero, a0, s9
                  add         a6, s6, t4
2294:             c.lui       a4, 8
2295:             srai        s1, s6, 1
                  sltu        t0, s2, zero
                  beq         t0, t3, 2305f
                  xor         s8, a3, s7
                  rem         t4, a5, s6
2300:             beq         t5, s6, 2312f
                  c.sub       a0, a2
                  c.srli      a2, 17
                  addi        a6, tp, 1041
                  c.addi4spn  a0, sp, 16
2305:             nop
                  c.beqz      a0, 2326f
                  c.andi      a2, -1
                  rem         a6, s5, zero
                  c.mv        t0, a5
                  sltiu       s5, sp, -1400
                  ori         s8, tp, -153
2312:             sub         gp, t2, s5
                  div         zero, zero, a5
                  xori        s2, a3, 889
                  c.andi      a3, -1
                  sub         s9, a4, a2
                  addi        zero, gp, 505
                  add         zero, s1, s4
                  sltiu       t3, a2, -1543
                  and         a6, tp, s5
                  slti        a2, s0, 1818
                  c.addi      a4, -1
                  xori        ra, a6, 936
                  sub         s3, s0, s4
                  slti        s0, t0, -1868
2326:             sll         a0, t2, s3
                  divu        a6, tp, s0
                  slli        s5, s3, 13
                  c.or        a4, s0
                  srai        t1, gp, 6
                  bge         a4, s5, 2349f
                  srai        a6, a3, 22
                  sub         s6, t4, a4
                  c.srai      a3, 2
                  c.beqz      a0, 2350f
                  auipc       s7, 368756
                  mulhsu      a1, s7, a6
                  bge         t0, s4, 2358f
                  c.li        t3, 20
                  mulh        s1, s7, a0
                  c.addi      a3, 1
                  slli        zero, t6, 13
                  sltu        t6, zero, a1
                  c.addi16sp  sp, -16
                  beq         s0, t4, 2365f
                  slt         s11, s11, s9
                  mul         zero, t6, sp
                  c.mv        t6, a2
2349:             sub         s5, s5, ra
2350:             sltiu       zero, sp, 1883
                  bltu        a5, t2, 2370f
                  c.slli      ra, 12
                  c.addi4spn  a0, sp, 784
                  slti        a6, s5, -1100
                  andi        a2, t1, -1189
                  c.addi16sp  sp, 464
                  lui         sp, 297772
2358:             blt         a2, s6, 2370f
                  c.beqz      a3, 2367f
                  mulh        s8, t2, t3
                  blt         tp, tp, 2375f
                  mulhu       s4, gp, ra
                  lui         zero, 614490
                  bgeu        s6, s6, 2378f
2365:             c.addi16sp  sp, 288
                  c.srli      a2, 11
2367:             srai        t3, s1, 6
                  c.li        s7, 31
                  beq         a4, t6, 2381f
2370:             c.lui       s3, 17
                  c.or        a0, a2
                  mulhu       s9, a5, sp
                  c.nop
                  c.sub       a2, a0
2375:             c.lui       s1, 7
                  xor         t6, gp, a6
                  srli        a7, a2, 10
2378:             addi        t4, s1, 2026
                  addi        sp, t0, -162
                  mul         s11, s2, s2
2381:             sll         s9, tp, t5
                  srl         s6, t3, s6
                  sll         a7, a3, s8
                  mulh        a7, s9, s3
                  mul         gp, s0, t4
                  c.beqz      a2, 2396f
                  slti        zero, s5, 1666
                  divu        t0, t3, s7
                  srl         a1, s1, a0
                  div         a3, a4, t2
                  xori        t0, s9, 386
                  sub         t3, t6, a7
                  and         gp, gp, s7
                  c.or        a0, a5
                  srli        t3, ra, 15
2396:             c.addi      t3, 22
                  nop
                  c.and       s1, a2
                  and         ra, a5, s3
                  c.sub       a0, a2
                  bge         s4, t5, 2413f
                  rem         gp, s10, s5
                  divu        a6, sp, tp
                  c.beqz      a0, 2418f
                  bgeu        s10, t2, 2411f
                  and         t1, a5, tp
                  c.li        s6, -1
                  bltu        s11, a2, 2425f
                  bge         s10, s1, 2429f
                  slti        s9, s6, -176
2411:             srai        zero, a0, 18
                  bltu        s5, s4, 2421f
2413:             mulh        s4, a3, a0
                  slt         t3, sp, s7
                  sra         a1, a7, s6
                  c.slli      a1, 6
                  divu        s1, a2, sp
2418:             sll         t4, s9, t1
                  bge         t3, zero, 2438f
                  mulhsu      gp, gp, t3
2421:             c.nop
                  addi        t1, a3, -351
                  and         s4, t3, s9
                  c.mv        ra, t0
2425:             andi        s2, s5, -1962
                  c.addi4spn  a0, sp, 176
                  mulh        a7, s8, tp
                  c.andi      a3, 0
2429:             slli        a6, s2, 22
                  or          a0, a6, a7
                  sll         a1, a5, t5
                  slt         ra, a1, a7
                  c.addi16sp  sp, -16
                  bne         a7, s7, 2452f
                  lui         a1, 848255
                  bne         zero, t2, 2444f
                  c.andi      a0, -1
2438:             sltiu       ra, s3, 1251
                  srli        s4, t6, 29
                  c.andi      a3, 12
                  sll         a2, t1, a5
                  srli        a0, a3, 6
                  c.lui       a5, 16
2444:             c.addi16sp  sp, -16
                  srai        s2, tp, 16
                  c.nop
                  rem         s8, s11, tp
                  c.mv        s6, s5
                  c.nop
                  slli        s4, a3, 11
                  sltiu       a3, a3, 1192
2452:             c.addi4spn  s0, sp, 80
                  bgeu        s9, tp, 2472f
                  srl         a3, zero, gp
                  c.mv        a4, a2
                  srli        s6, t5, 4
                  andi        t6, tp, 1180
                  mulhsu      gp, ra, t2
                  mul         a6, s10, t3
                  sll         a3, s2, a0
                  c.addi16sp  sp, -16
                  slt         s9, t2, a1
                  auipc       zero, 467586
                  addi        s1, s2, 846
                  c.or        a3, s1
                  sra         s2, sp, t3
                  mulhsu      s2, a0, s6
                  mul         s4, s3, a7
                  c.lui       ra, 3
                  mul         a2, tp, s3
                  xor         s6, a5, s0
2472:             bltu        s6, zero, 2489f
                  bltu        s2, s4, 2493f
                  addi        s1, s11, 657
                  xori        ra, sp, 979
                  srli        a7, s10, 23
                  sra         a3, a5, s6
                  addi        zero, a5, -1061
                  xori        a2, a5, -956
                  c.srli      a3, 10
                  c.addi      t0, 7
                  c.addi4spn  a3, sp, 816
                  srai        t4, a5, 16
                  c.srli      a3, 28
                  c.addi      ra, 23
                  c.sub       a2, s0
                  divu        s8, a4, s4
                  c.xor       a2, a0
2489:             sub         a5, t2, a6
                  slli        s8, t5, 15
                  c.or        a0, a2
                  mul         a5, zero, ra
2493:             xori        tp, a5, -1705
                  c.sub       a3, a1
                  c.mv        tp, s10
                  c.beqz      a0, 2500f
                  sltu        zero, s0, a3
                  mulhu       a7, sp, s10
                  srl         t4, s11, s11
2500:             bltu        t3, s1, 2508f
                  c.li        s8, -1
                  divu        s11, gp, a4
                  div         zero, t1, s11
                  slli        a3, s10, 22
                  c.addi16sp  sp, 176
                  slti        gp, s0, 833
                  slti        s1, s11, 1024
2508:             c.li        s8, 11
                  c.addi      a5, 19
                  sub         tp, s2, s5
                  ori         a1, a3, 498
                  slt         t0, t6, sp
                  c.and       a2, a2
                  sra         a3, a5, a1
                  c.beqz      a0, 2535f
                  beq         s1, t3, 2529f
                  bne         s9, t2, 2536f
                  nop
                  c.xor       s1, a1
                  c.andi      s0, -1
                  srl         tp, t4, a3
                  srli        s5, gp, 10
                  ori         zero, a2, -953
                  c.add       s0, s6
                  lui         s0, 854757
                  c.srli      a3, 28
                  slti        zero, a0, -464
                  c.addi4spn  a3, sp, 656
2529:             nop
                  c.and       a3, s1
                  c.nop
                  mul         a3, t6, a3
                  sltu        a1, s5, s3
                  c.li        gp, 0
2535:             auipc       sp, 203169
2536:             c.xor       a2, a3
                  sub         sp, t6, s7
                  c.lui       s4, 17
                  bltu        s6, a6, 2556f
                  nop
                  add         zero, s6, tp
                  or          s0, s2, s10
                  mulh        a5, a5, s0
                  sltiu       tp, a1, 1674
                  bgeu        a2, a5, 2559f
                  bltu        a5, t0, 2563f
                  auipc       t4, 527326
                  c.or        a1, s1
                  mulh        a3, s5, t3
                  c.add       a7, s5
                  lui         gp, 727845
                  xor         a4, tp, s7
                  c.nop
                  bgeu        gp, a4, 2566f
                  sltu        t3, t5, zero
2556:             c.beqz      a0, 2558f
                  srli        a0, s9, 16
2558:             sltiu       a4, s10, 1910
2559:             mul         t6, s8, t5
                  c.srai      a3, 8
                  divu        tp, s0, a4
                  c.or        a3, a2
2563:             auipc       s11, 478583
                  andi        a0, a0, -1476
                  c.li        ra, 2
2566:             c.nop
                  c.srli      s0, 9
                  divu        s5, a5, s4
                  bge         t1, t2, 2584f
                  slti        s6, tp, 133
                  blt         zero, a3, 2591f
                  ori         zero, t0, -1293
                  c.mv        s8, t1
                  nop
                  c.srli      a0, 29
                  sltu        s5, s1, t5
                  xor         s9, s9, s1
                  sltiu       s9, a3, -156
                  slli        s9, a6, 12
                  add         zero, ra, sp
                  c.sub       s1, s0
                  slt         s2, t3, t4
                  and         t4, s9, t3
2584:             c.beqz      a3, 2586f
                  and         a1, a6, a3
2586:             c.sub       a3, a2
                  slli        a0, t0, 1
                  c.and       a2, a0
                  c.slli      s4, 8
                  div         s4, ra, t2
2591:             c.andi      a0, 7
                  c.mv        a3, s1
                  div         t6, a4, t1
                  c.slli      s2, 13
                  bgeu        s6, s9, 2603f
                  nop
                  mulh        s4, t5, s9
                  andi        s5, s5, 1948
                  srli        s0, s0, 20
                  bltu        sp, a3, 2606f
                  and         s7, sp, s4
                  c.and       a0, a3
2603:             sra         t1, s5, a2
                  c.nop
                  c.slli      t0, 25
2606:             c.slli      s1, 19
                  addi        s0, t5, -121
                  rem         a0, a7, sp
                  slti        s2, a2, 1075
                  c.or        a0, a0
                  sltu        zero, a6, a2
                  c.mv        a1, ra
                  bgeu        a4, s5, 2621f
                  and         s7, a3, t0
                  addi        s7, gp, -1298
                  sll         s5, s5, a6
                  bne         a7, s11, 2635f
                  c.sub       a0, a2
                  c.lui       tp, 29
                  bge         ra, gp, 2632f
2621:             c.srli      a2, 12
                  sll         zero, s8, a5
                  xori        a6, s7, 784
                  c.addi      s11, 1
                  c.addi16sp  sp, -16
                  c.srai      s1, 2
                  slti        s3, a2, -1777
                  mulh        zero, t1, tp
                  nop
                  c.nop
                  mul         a5, a6, a2
2632:             c.addi4spn  a3, sp, 288
                  sltiu       a3, t6, -708
                  add         gp, s9, s2
2635:             c.or        a1, a3
                  srl         s3, s1, s1
                  beq         s1, gp, 2649f
                  c.srai      a3, 20
                  srli        s7, a2, 29
                  ori         zero, s5, 1215
                  c.li        s0, 10
                  c.li        a5, 4
                  sltu        a5, a1, s8
                  slti        s6, s4, 839
                  mulhsu      a2, s11, s1
                  c.mv        s4, a1
                  c.srai      a0, 30
                  bge         a5, s9, 2662f
2649:             mul         sp, a1, t5
                  srl         zero, s11, zero
                  srai        t3, a0, 21
                  divu        tp, a5, sp
                  c.xor       a2, a3
                  auipc       s1, 935296
                  sub         s0, s5, t5
                  c.li        a1, 6
                  c.or        a3, a4
                  c.mv        s7, s8
                  c.add       s8, s0
                  mulhsu      t6, s6, s1
                  div         zero, tp, t6
2662:             c.add       tp, s4
                  bltu        s4, ra, 2680f
                  mul         gp, a4, s11
                  ori         zero, t6, 971
                  srli        a5, s9, 3
                  xor         a2, t3, s7
                  xor         zero, t5, a1
                  srli        t1, gp, 7
                  beq         s6, tp, 2679f
                  c.addi      ra, 24
                  c.addi      a4, -1
                  auipc       t1, 956475
                  c.xor       a0, a3
                  c.andi      a0, 10
                  srl         a1, s3, tp
                  c.srli      a0, 27
                  mul         ra, a3, gp
2679:             auipc       sp, 31725
2680:             c.or        a0, s0
                  c.mv        s11, a1
                  blt         s5, a6, 2692f
                  and         sp, a0, a6
                  c.or        a0, a1
                  c.srli      a0, 14
                  c.sub       a2, a1
                  add         s11, s10, sp
                  bgeu        a6, s7, 2708f
                  c.addi      s4, 6
                  divu        zero, t4, s5
                  sub         sp, zero, a2
2692:             c.srli      a3, 1
                  c.or        a5, a0
                  sltu        a3, t2, ra
                  blt         a6, t0, 2714f
                  div         s3, s9, s9
                  beq         a0, a0, 2705f
                  c.srai      s0, 7
                  rem         s5, s10, s5
                  slli        zero, s3, 27
                  add         a1, t2, a2
                  slli        s7, a4, 27
                  slti        gp, s6, 885
                  c.mv        s5, s11
2705:             slli        t6, a2, 21
                  bltu        a4, t1, 2723f
                  mulh        ra, a7, a0
2708:             slli        gp, s11, 27
                  bgeu        s1, s3, 2723f
                  c.sub       a0, s1
                  sub         s1, s1, s9
                  rem         s6, a6, a6
                  lui         s1, 761174
2714:             addi        s9, a3, 983
                  ori         s7, sp, -1964
                  mulh        a6, tp, s4
                  srai        a2, s11, 1
                  c.addi4spn  a0, sp, 560
                  xori        a1, t1, 659
                  bne         s0, a2, 2737f
                  or          t1, a7, s11
                  bge         s11, zero, 2739f
2723:             c.mv        s0, s3
                  or          s5, t3, s6
                  srli        t3, t0, 28
                  c.mv        t0, t2
                  sub         s4, s6, ra
                  divu        tp, s2, t3
                  c.nop
                  c.xor       a1, a1
                  sltiu       a4, tp, -1173
                  sub         zero, a7, gp
                  slt         zero, t1, s1
                  c.li        t3, 17
                  bltu        s0, zero, 2754f
                  c.srli      s0, 31
2737:             sll         s9, s0, a6
                  xor         s9, s9, t3
2739:             mulhu       s2, a1, s0
                  c.lui       t1, 13
                  add         t4, a2, a6
                  sra         a3, a0, a3
                  xor         t0, s0, sp
                  or          s11, t0, tp
                  mulh        a2, s6, s8
                  c.lui       s8, 2
                  div         a6, tp, s10
                  c.xor       a2, a0
                  c.nop
                  c.li        ra, -1
                  bne         t0, a5, 2757f
                  c.mv        s3, s6
                  c.srli      a0, 23
2754:             sll         zero, t2, s6
                  c.or        a0, s1
                  c.lui       a7, 16
2757:             c.beqz      a0, 2771f
                  mul         s8, a3, a0
                  sll         a0, gp, t0
                  srai        s7, ra, 5
                  srai        a6, sp, 19
                  slti        a2, s6, -934
                  c.addi      s8, 18
                  sltiu       s2, s9, -116
                  or          s11, t3, a4
                  c.nop
                  srai        t0, a7, 13
                  sltu        s11, ra, s2
                  slti        zero, sp, -1399
                  nop
2771:             srli        s6, a2, 25
                  bltu        s4, s11, 2785f
                  c.beqz      a3, 2781f
                  andi        s6, s11, -1375
                  c.and       a0, a2
                  addi        zero, t5, -1417
                  srai        gp, t4, 10
                  sltu        a1, a2, s8
                  c.and       a0, s1
                  or          s3, a5, a1
2781:             or          a7, zero, s0
                  andi        zero, s9, -1203
                  mulh        a1, gp, s0
                  c.srai      a3, 3
2785:             c.addi      a1, -1
                  bltu        s2, s2, 2792f
                  c.xor       a0, a1
                  bltu        s7, s6, 2790f
                  c.or        s1, a0
2790:             bgeu        t4, tp, 2810f
                  slli        s1, s5, 2
2792:             srai        zero, ra, 18
                  sub         zero, a2, a2
                  c.addi16sp  sp, 432
                  sub         s4, t3, t2
                  lui         zero, 31814
                  mulhsu      zero, a5, s8
                  xor         s8, a6, t3
                  or          zero, a3, sp
                  sub         s3, s1, s7
                  c.sub       s1, s0
                  bge         a7, t1, 2822f
                  c.add       a6, t0
                  c.lui       t4, 15
                  c.beqz      a3, 2817f
                  nop
                  srai        s11, ra, 4
                  blt         s3, a3, 2823f
                  c.and       a0, a3
2810:             rem         zero, a6, s9
                  c.beqz      a3, 2813f
                  srli        a2, gp, 8
2813:             c.beqz      a0, 2817f
                  andi        t1, s1, 1928
                  bne         gp, gp, 2834f
                  sltiu       s0, zero, 1711
2817:             xori        gp, t3, 187
                  slti        a7, a1, -522
                  srai        a6, t2, 17
                  bltu        s9, s10, 2840f
                  bge         t0, t2, 2840f
2822:             c.addi16sp  sp, 112
2823:             slt         zero, t4, a2
                  slt         gp, a1, s9
                  c.sub       a0, a2
                  c.and       a2, s1
                  c.slli      s7, 19
                  lui         s1, 874403
                  c.addi      a1, -1
                  c.srli      a2, 6
                  addi        sp, s6, -1163
                  bltu        s0, a2, 2849f
                  lui         sp, 493961
2834:             blt         a7, s11, 2848f
                  divu        sp, s10, a1
                  c.nop
                  sra         s1, sp, sp
                  c.nop
                  ori         s7, a5, -1524
2840:             add         t3, a3, s11
                  andi        s7, ra, 1014
                  mulh        s0, t2, t3
                  sll         t0, t3, gp
                  sra         t0, s5, a4
                  sub         s3, s11, s4
                  nop
                  blt         a2, a4, 2867f
2848:             sltu        a6, t1, s8
2849:             sra         s7, s4, t0
                  div         t3, s10, a4
                  c.andi      a4, -1
                  c.sub       a2, a3
                  c.slli      s2, 10
                  beq         t1, s10, 2866f
                  mulhu       t3, t4, t3
                  c.addi      a4, -1
                  beq         s5, zero, 2875f
                  c.li        a1, -1
                  xori        t6, a6, -1423
                  sltu        a1, ra, sp
                  blt         s7, a6, 2875f
                  bge         s7, s10, 2872f
                  nop
                  c.srli      a1, 25
                  c.li        s4, -1
2866:             or          zero, s11, a0
2867:             c.mv        ra, t6
                  sra         s2, t5, s6
                  mulhsu      a3, t4, a1
                  c.srai      a2, 31
                  bne         t3, s7, 2877f
2872:             bltu        a1, a6, 2880f
                  slti        t4, t4, -1767
                  sltu        a1, ra, s3
2875:             addi        s2, t1, 176
                  rem         gp, s4, t0
2877:             bge         s6, s7, 2890f
                  c.lui       s6, 26
                  c.nop
2880:             bltu        s4, s3, 2900f
                  c.add       a2, gp
                  or          s11, a2, s1
                  sub         a6, zero, t6
                  auipc       s11, 699666
                  slli        s3, s4, 23
                  div         a3, t2, sp
                  slti        a1, s4, -198
                  c.sub       a1, a3
                  and         s11, a0, a7
2890:             bne         s10, sp, 2898f
                  c.srai      a4, 8
                  add         a7, s1, t1
                  or          s1, tp, t1
                  auipc       s0, 945856
                  c.nop
                  c.sub       a2, a2
                  lui         s3, 662881
2898:             sra         gp, s3, s6
                  slt         s3, a2, t3
2900:             c.lui       a5, 3
                  c.xor       a0, a5
                  sra         a5, s4, zero
                  c.srli      a5, 20
                  divu        a3, s6, a0
                  andi        t4, s11, 1562
                  sub         s4, t2, t5
                  c.or        a0, a1
                  add         t3, s11, tp
                  nop
                  xor         s4, t2, a1
                  addi        gp, s7, 869
                  c.nop
                  bne         t0, a7, 2915f
                  blt         s2, s8, 2923f
2915:             nop
                  add         s0, s8, ra
                  srai        zero, s1, 5
                  c.slli      ra, 25
                  c.xor       a3, a3
                  c.xor       a0, a1
                  srl         s4, t1, a7
                  c.mv        a5, t5
2923:             slli        s3, t3, 8
                  xor         a1, a6, t6
                  c.sub       a2, s0
                  sltu        sp, s11, s6
                  c.and       a1, s1
                  c.sub       a2, a3
                  slt         ra, t4, a7
                  sltiu       s8, a6, 321
                  slti        s1, a7, -1939
                  sltu        a4, t6, a1
                  c.xor       a5, s1
                  nop
                  c.andi      a2, -1
                  bne         a0, ra, 2956f
                  srai        a3, a0, 31
                  srai        t1, t1, 5
                  c.srai      a0, 30
                  mul         zero, s10, sp
                  c.andi      a5, -1
                  c.or        a0, s0
                  add         zero, ra, a5
                  nop
                  div         s1, a0, s11
                  c.addi4spn  a0, sp, 608
                  c.addi      s6, -1
                  auipc       a4, 862297
                  ori         a3, s10, 835
                  c.addi      ra, 15
                  blt         tp, t4, 2959f
                  beq         t4, a5, 2964f
                  bgeu        s11, t3, 2955f
                  c.or        a0, a0
2955:             rem         s1, t6, a1
2956:             rem         gp, a3, s6
                  bgeu        t3, s10, 2974f
                  sltiu       a1, t5, -663
2959:             c.li        s9, 12
                  and         t0, a3, s8
                  srl         s8, t1, t3
                  xor         s7, s9, t3
                  beq         a2, gp, 2980f
2964:             bltu        s6, sp, 2981f
                  c.add       t0, s5
                  srli        zero, s1, 26
                  bge         tp, a6, 2986f
                  bltu        s5, s2, 2980f
                  mul         zero, t4, a0
                  c.slli      s3, 23
                  c.lui       a0, 24
                  c.andi      a3, 10
                  sll         t0, ra, s4
2974:             c.beqz      a3, 2988f
                  srai        s6, s1, 13
                  c.li        ra, 18
                  c.srai      a0, 18
                  c.addi      a2, 4
                  bge         s6, s5, 2994f
2980:             c.or        a3, s1
2981:             c.mv        s2, t3
                  srai        a3, t1, 3
                  blt         t3, zero, 2989f
                  or          zero, a0, a2
                  mulh        t4, t0, a1
2986:             c.sub       a0, a2
                  c.beqz      a3, 3007f
2988:             c.mv        s11, t3
2989:             blt         t4, sp, 3008f
                  c.sub       a0, a0
                  beq         s11, t3, 2995f
                  c.li        a1, -1
                  divu        s2, s10, t1
2994:             c.xor       a2, s1
2995:             srai        a4, s2, 8
                  beq         a5, t4, 3010f
                  blt         t3, s10, 3007f
                  sra         a5, s5, t2
                  or          tp, tp, a2
                  mulhsu      a5, a7, s5
                  nop
                  c.add       a7, t1
                  or          t4, a6, s5
                  srai        s5, a3, 2
                  blt         s7, sp, 3011f
                  srli        a1, s7, 25
3007:             c.or        a0, a1
3008:             srli        zero, a2, 28
                  c.slli      t6, 20
3010:             sll         a5, ra, s1
3011:             sra         a4, t1, a0
                  c.xor       a0, a0
                  sll         t3, s5, t6
                  blt         s4, t4, 3034f
                  bne         s1, zero, 3035f
                  srli        zero, s6, 5
                  srli        s9, a5, 8
                  or          zero, t0, t6
                  and         a1, ra, s3
                  c.add       sp, s0
                  mulh        s11, s11, s5
                  c.li        a2, -1
                  c.mv        a7, t2
                  srl         a1, gp, a3
                  c.addi      ra, 10
                  srli        a5, a1, 10
                  sltu        t6, a0, ra
                  c.sub       a2, a2
                  divu        s5, s5, s8
                  bne         s7, ra, 3047f
                  mulhsu      a4, s4, s0
                  divu        s1, t1, t5
                  c.xor       a0, a0
3034:             sltu        zero, t1, s8
3035:             sll         s6, a6, t0
                  sltu        a4, s5, a5
                  lui         zero, 145458
                  c.nop
                  slli        s3, s3, 15
                  sub         a6, sp, zero
                  c.andi      a5, 0
                  c.slli      t6, 6
                  srli        s0, s7, 11
                  c.add       gp, s3
                  rem         ra, sp, s0
                  c.addi4spn  a0, sp, 704
3047:             mulhsu      t0, s3, tp
                  bgeu        tp, s10, 3060f
                  div         a7, t5, sp
                  mul         t4, zero, s10
                  sltu        s8, t2, s3
                  andi        a4, t3, -70
                  c.addi16sp  sp, 96
                  mulhu       gp, sp, a4
                  c.addi      a4, -1
                  srai        a0, tp, 12
                  xori        s6, s9, 769
                  c.and       a2, a1
                  srl         s0, a2, t3
3060:             slti        a6, ra, 66
                  c.beqz      a0, 3069f
                  slt         s6, a0, s3
                  beq         a4, s1, 3083f
                  and         sp, a5, zero
                  c.nop
                  lui         ra, 643357
                  ori         s7, tp, 450
                  nop
3069:             sra         t0, s0, t2
                  c.and       s1, a0
                  andi        s2, zero, -319
                  nop
                  lui         gp, 974820
                  add         s6, ra, a4
                  lui         tp, 956085
                  c.mv        tp, gp
                  mulhsu      s8, t2, s0
                  mulhsu      s9, a2, zero
                  mulhu       a0, t1, a2
                  bgeu        t2, t4, 3099f
                  nop
                  slli        s2, ra, 25
3083:             c.slli      t1, 5
                  c.srai      a0, 29
                  or          a5, a7, s6
                  c.and       a0, a2
                  or          s7, t0, t1
                  sltu        s1, a2, t3
                  ori         zero, a4, -768
                  c.or        a3, a2
                  c.or        a2, a3
                  slli        a2, t3, 10
                  bltu        s3, s4, 3102f
                  c.nop
                  srli        sp, s4, 15
                  div         zero, t1, t0
                  c.addi4spn  a0, sp, 544
                  mulhsu      zero, t6, s1
3099:             c.nop
                  srli        s4, s8, 29
                  mulhu       zero, s8, t2
3102:             c.or        a2, a0
                  beq         t6, a6, 3107f
                  c.lui       t6, 6
                  xori        s8, s0, 460
                  c.beqz      s0, 3120f
3107:             bltu        a3, a7, 3127f
                  add         gp, s8, s6
                  c.xor       a0, a3
                  beq         s11, s11, 3122f
                  lui         a2, 609062
                  sll         s2, a4, a0
                  bge         a7, s4, 3119f
                  c.srli      a0, 26
                  c.srai      a0, 13
                  slt         s4, a5, s7
                  srl         ra, a2, s5
                  rem         t6, t6, s9
3119:             c.add       s3, s9
3120:             c.srai      a0, 27
                  slti        s7, a3, -1980
3122:             and         s11, s6, sp
                  sub         sp, t4, s2
                  lui         a4, 1017207
                  mul         ra, a3, gp
                  c.srli      a0, 31
3127:             lui         t4, 805733
                  c.li        s2, -1
                  bge         t0, s3, 3146f
                  sub         a1, zero, t5
                  c.add       ra, t3
                  ori         a2, t4, 1347
                  c.or        a0, a2
                  bltu        s6, s8, 3142f
                  auipc       s6, 731409
                  c.xor       a0, s1
                  and         sp, s4, a4
                  mulhu       a2, gp, t1
                  c.or        a0, a1
                  srai        zero, s10, 1
                  div         s11, zero, a2
3142:             c.srli      a0, 8
                  lui         s0, 98173
                  slli        a0, zero, 4
                  beq         s7, gp, 3164f
3146:             lui         ra, 594544
                  bgeu        s9, a1, 3165f
                  c.or        a0, a3
                  srli        s6, t3, 2
                  c.lui       ra, 21
                  mul         a1, tp, t6
                  c.nop
                  c.or        a0, a1
                  rem         zero, s1, t3
                  mul         zero, t5, s8
                  sll         s7, a5, s11
                  xor         t0, t5, s3
                  c.and       a0, a2
                  rem         gp, a1, s6
                  c.addi4spn  a2, sp, 624
                  c.srai      a0, 4
                  or          gp, s3, s8
                  sltu        a6, s9, t5
3164:             srai        s1, a7, 10
3165:             c.xor       a5, a3
                  mulhu       zero, s10, s0
                  bgeu        s2, s2, 3169f
                  slti        tp, s9, -2035
3169:             slt         s1, s7, sp
                  c.addi16sp  sp, -16
                  bne         s8, a5, 3188f
                  c.addi      t4, -1
                  c.add       a4, t2
                  c.and       a0, a2
                  or          a7, t3, t6
                  c.srli      a1, 6
                  c.addi16sp  sp, -16
                  bltu        zero, s9, 3192f
                  c.addi4spn  a0, sp, 224
                  bne         a7, a0, 3197f
                  c.srai      a0, 2
                  sltu        a3, tp, a4
                  c.slli      ra, 24
                  sra         s0, sp, s2
                  c.srli      a0, 23
                  c.lui       a3, 29
                  c.add       ra, ra
3188:             mulhu       tp, t6, t4
                  sub         a2, s9, tp
                  slli        s9, s10, 20
                  slti        t6, s6, 429
3192:             slti        s4, a1, 755
                  divu        t6, t2, tp
                  xor         s7, gp, a6
                  xor         a0, s6, a1
                  srl         a7, s6, a2
3197:             srai        t4, s8, 28
                  c.srai      a0, 19
                  c.nop
                  slti        a6, s2, 1988
                  ori         a5, tp, 1599
                  add         s0, s2, s1
                  c.srli      s1, 7
                  c.slli      t0, 19
                  c.srli      a2, 5
                  beq         s3, s8, 3208f
                  sltu        a4, tp, ra
3208:             c.add       a2, ra
                  mul         tp, s2, sp
                  xori        zero, s0, -292
                  div         t6, s3, s2
                  c.add       a6, a3
                  srl         s11, s1, s4
                  srl         s1, t0, s0
                  addi        a7, a2, 686
                  c.slli      s5, 2
                  slt         sp, s6, s9
                  c.andi      a0, 1
                  bgeu        s8, t5, 3234f
                  add         s2, s4, a5
                  bltu        s4, s4, 3234f
                  c.srai      a0, 25
                  sltiu       sp, a4, 1856
                  mul         s1, s4, s1
                  lui         zero, 871250
                  mul         a6, a7, t3
                  and         t0, t6, s6
                  sll         a5, t1, tp
                  c.xor       s0, s0
                  c.srai      a4, 14
                  c.addi      a5, 5
                  bgeu        s5, a5, 3251f
                  sub         s6, a1, a7
3234:             mulhsu      t0, gp, a3
                  c.addi16sp  sp, -16
                  add         s2, s8, s3
                  sltiu       tp, t3, -1949
                  mulh        sp, t2, a2
                  c.andi      a0, -1
                  sra         zero, a0, a2
                  srai        a6, t2, 28
                  lui         s2, 346352
                  add         a6, a3, t5
                  auipc       s3, 781755
                  div         s8, s10, a4
                  c.mv        gp, t6
                  sltiu       sp, sp, 691
                  c.andi      a2, -1
                  c.srai      a2, 19
                  c.or        a0, a1
3251:             auipc       t1, 869108
                  sra         a1, a0, s10
                  sltu        a1, s9, a3
                  bge         s7, a3, 3262f
                  c.slli      a6, 8
                  c.xor       a0, s0
                  srai        a7, t2, 1
                  bne         s1, t4, 3270f
                  c.slli      s9, 29
                  c.andi      a0, 31
                  c.srli      a2, 25
3262:             bgeu        a1, a6, 3281f
                  srli        a5, a5, 18
                  srai        a6, t5, 28
                  or          s3, s9, t2
                  auipc       s8, 330254
                  bge         s4, sp, 3287f
                  bgeu        t0, sp, 3282f
                  beq         s5, a7, 3286f
3270:             mulhu       t1, a5, t5
                  slti        t3, s11, 808
                  mulh        a0, t6, s9
                  rem         a6, t0, sp
                  andi        a6, s10, -1244
                  c.lui       a7, 23
                  sltu        a5, a6, ra
                  andi        s0, t4, 12
                  c.mv        ra, t5
                  nop
                  c.beqz      a3, 3297f
3281:             ori         t1, zero, -363
3282:             sra         sp, a5, s8
                  divu        s8, t5, ra
                  lui         s2, 773236
                  blt         a3, s8, 3291f
3286:             c.or        a0, a0
3287:             ori         gp, s5, -368
                  mul         t3, s7, s6
                  mulhu       gp, s6, zero
                  c.mv        ra, a4
3291:             nop
                  divu        s1, a0, s3
                  srai        zero, a0, 10
                  bltu        s3, t2, 3308f
                  c.addi16sp  sp, 288
                  c.li        s2, -1
3297:             sra         s9, gp, a6
                  sub         a1, a7, s9
                  bgeu        s9, t0, 3316f
                  c.addi4spn  a2, sp, 16
                  add         t4, s9, a6
                  srl         s2, s4, tp
                  beq         sp, a1, 3311f
                  c.and       a3, s0
                  c.add       a4, s9
                  nop
                  sltu        t0, s0, s10
3308:             bge         t2, s9, 3326f
                  or          a0, a5, t4
                  srl         a1, gp, t1
3311:             xori        s7, a2, -1974
                  mul         zero, gp, zero
                  bge         s11, a3, 3322f
                  and         t0, zero, a1
                  sll         a5, a1, s3
3316:             div         s1, s2, s11
                  c.and       a0, a5
                  c.xor       a3, a0
                  c.li        t1, -1
                  srl         s4, s10, a0
                  c.nop
3322:             slli        t1, t2, 4
                  c.xor       a0, a4
                  bgeu        s9, t4, 3336f
                  or          a3, t0, t0
3326:             slt         t3, s4, a7
                  slli        t4, zero, 2
                  ori         s5, s3, -1873
                  sub         a1, tp, tp
                  bge         t0, a0, 3336f
                  lui         a5, 146680
                  add         s1, s1, s0
                  nop
                  bltu        sp, a3, 3342f
                  bne         t6, t1, 3348f
3336:             srli        s11, a3, 17
                  mul         a0, s9, ra
                  addi        a7, s1, 966
                  sll         zero, s7, a0
                  sltu        zero, a5, s2
                  c.addi      s9, 5
3342:             mulhsu      a6, t3, t2
                  mulhsu      s6, t4, gp
                  mulh        s6, t5, a3
                  bgeu        s2, t6, 3347f
                  bgeu        s6, s2, 3366f
3347:             srai        s8, s5, 29
3348:             add         s6, a5, tp
                  slt         zero, s6, a3
                  and         t6, ra, t6
                  bltu        s11, a7, 3365f
                  nop
                  addi        s4, t2, 508
                  slli        a1, t5, 3
                  c.addi16sp  sp, -16
                  bltu        s5, s6, 3373f
                  c.srli      a0, 18
                  auipc       a7, 278413
                  c.xor       a2, s0
                  srli        a3, a4, 15
                  div         a6, s9, a1
                  c.andi      a2, 28
                  sra         s3, a5, a4
                  c.add       s2, t3
3365:             mul         s3, a5, a1
3366:             c.and       a2, a0
                  sub         sp, t4, zero
                  lui         a7, 246048
                  c.lui       s6, 5
                  bgeu        s1, t6, 3372f
                  c.lui       ra, 10
3372:             and         a1, s6, t4
3373:             c.addi16sp  sp, 304
                  addi        s9, s9, 525
                  xori        s3, a1, 242
                  mulh        zero, tp, sp
                  c.nop
                  blt         t3, s9, 3397f
                  lui         t1, 134294
                  srli        a5, t6, 27
                  addi        s8, s1, -210
                  c.beqz      a0, 3401f
                  c.li        a0, -1
                  mulh        zero, s11, s11
                  xori        t6, t5, -36
                  c.li        a4, 31
                  addi        t6, a1, -56
                  c.andi      a0, -1
                  c.addi      sp, 13
                  c.slli      s1, 17
                  c.add       ra, s3
                  rem         t4, a7, s2
                  lui         s5, 142763
                  mulh        a3, s11, a7
                  lui         gp, 684042
                  mulh        s4, s11, s8
3397:             bge         s5, s5, 3417f
                  beq         t3, a1, 3408f
                  c.or        a5, a2
                  c.addi      s5, 21
3401:             sra         zero, s0, tp
                  srli        ra, t2, 2
                  sra         t6, s10, s11
                  c.slli      s8, 24
                  c.xor       a3, a2
                  beq         t0, a3, 3410f
                  mulhsu      a7, ra, s7
3408:             sub         t1, a1, t5
                  c.nop
3410:             sltiu       zero, t5, -322
                  c.srli      a2, 14
                  sub         zero, s11, a5
                  mulh        t4, a4, a5
                  c.mv        s1, s10
                  c.slli      s8, 11
                  bge         a4, a2, 3436f
3417:             or          s9, tp, a6
                  c.addi      s11, 11
                  blt         s1, t3, 3431f
                  c.slli      gp, 2
                  bltu        tp, s6, 3429f
                  c.srli      a0, 10
                  sra         t6, a3, t6
                  andi        gp, zero, -642
                  bge         a1, gp, 3437f
                  srai        s9, s3, 18
                  bge         t3, a4, 3442f
                  sll         t4, t2, a2
3429:             c.slli      ra, 11
                  c.sub       a2, a0
3431:             mulh        s6, a4, s5
                  slli        t4, s0, 25
                  div         zero, t4, ra
                  srai        tp, s2, 5
                  and         a1, s8, s9
3436:             rem         s6, t4, t2
3437:             lui         t6, 757135
                  c.addi16sp  sp, -16
                  and         s2, sp, t1
                  c.beqz      a0, 3458f
                  c.beqz      a0, 3453f
3442:             bge         ra, s7, 3456f
                  xor         s7, t5, a2
                  nop
                  c.sub       a2, a0
                  blt         a1, a2, 3465f
                  mul         t4, s11, sp
                  slli        s5, zero, 0
                  ori         s8, tp, -1876
                  sltiu       sp, t2, -1871
                  slt         s4, sp, t6
                  bgeu        ra, sp, 3469f
3453:             div         t3, s11, t0
                  blt         a2, s11, 3462f
                  and         s1, s6, t1
3456:             c.xor       a0, s1
                  bgeu        a4, a7, 3466f
3458:             slt         sp, s0, tp
                  bge         s10, s10, 3476f
                  c.li        a3, 24
                  ori         s5, t6, -1585
3462:             c.beqz      a0, 3482f
                  srli        t4, s3, 30
                  slli        t3, a6, 17
3465:             bne         zero, a4, 3485f
3466:             c.srai      a2, 21
                  c.addi16sp  sp, 16
                  sltu        t6, zero, a6
3469:             srli        a4, a4, 10
                  or          a5, s8, t6
                  nop
                  c.or        a0, a2
                  sll         s2, t2, s2
                  mul         zero, s8, s7
                  c.srli      a4, 14
3476:             andi        t3, s1, 54
                  divu        a7, s5, t4
                  add         a7, ra, a7
                  lui         t0, 42246
                  div         zero, s7, s9
                  c.srai      a0, 6
3482:             div         t4, s11, s2
                  add         a1, s6, a6
                  c.li        s4, -1
3485:             or          zero, s0, zero
                  xori        a3, s6, 411
                  c.slli      s9, 1
                  andi        a0, s5, -1104
                  bgeu        s0, s1, 3509f
                  or          s8, s6, s2
                  and         s4, s6, t2
                  mulhsu      a7, s3, t0
                  div         s7, t5, t4
                  srl         s3, s2, s2
                  c.nop
                  c.add       s2, t4
                  mul         s7, t4, t6
                  sub         s11, s4, t1
                  c.or        a0, a2
                  ori         s4, s0, -811
                  add         a3, s1, tp
                  c.addi16sp  sp, -16
                  sll         a7, s11, s1
                  c.beqz      a3, 3521f
                  c.slli      tp, 8
                  sltu        s11, a7, s7
                  c.or        a0, a0
                  xor         a1, s10, s3
3509:             and         a0, a2, s9
                  div         s6, t4, a4
                  c.mv        ra, a1
                  c.li        s2, -1
                  c.mv        s7, s10
                  c.slli      s9, 7
                  bne         t0, t3, 3534f
                  auipc       a2, 265398
                  add         zero, s9, s7
                  c.andi      a0, -1
                  slt         s3, s1, s3
                  srai        s7, gp, 0
3521:             c.or        a2, a1
                  nop
                  mulhsu      a3, s1, a4
                  add         s5, sp, a7
                  c.sub       a2, a0
                  bgeu        sp, s2, 3543f
                  bgeu        t2, a7, 3539f
                  c.li        ra, -1
                  c.and       a0, a1
                  auipc       s11, 834725
                  divu        s11, s8, t2
                  c.srli      a0, 29
                  blt         s0, t3, 3553f
3534:             beq         t6, t1, 3542f
                  mul         zero, a2, a7
                  or          t3, sp, tp
                  c.addi4spn  a3, sp, 656
                  c.addi4spn  a2, sp, 912
3539:             slli        zero, s5, 18
                  c.slli      a0, 17
                  c.nop
3542:             c.addi16sp  sp, 192
3543:             nop
                  c.sub       a3, s1
                  addi        zero, zero, 1491
                  and         s1, s1, s8
                  divu        a6, s10, t5
                  sra         ra, s9, s10
                  c.sub       a3, a0
                  c.beqz      a2, 3563f
                  lui         a0, 30059
                  mulhsu      a0, t5, ra
3553:             sll         s0, s10, a1
                  and         s8, s8, a6
                  xori        ra, a3, 281
                  srai        ra, s10, 8
                  xori        zero, tp, -316
                  srli        t0, s10, 18
                  bge         s1, s5, 3573f
                  c.and       a2, a0
                  c.add       t0, t1
                  xor         a4, s8, s6
3563:             c.slli      s4, 21
                  c.addi      s11, -1
                  slt         s4, t0, s7
                  auipc       a5, 481131
                  c.li        s6, 24
                  blt         tp, t0, 3574f
                  slt         a7, a1, t1
                  c.lui       ra, 30
                  sltu        s1, t3, gp
                  beq         s3, ra, 3574f
3573:             c.srli      a0, 30
3574:             srai        a3, t2, 9
                  mulhsu      gp, s6, s5
                  c.add       s5, ra
                  c.xor       a0, a0
                  c.or        a0, a3
                  add         s3, t6, t3
                  c.add       gp, t2
                  bgeu        s0, s10, 3591f
                  c.srli      a0, 26
                  c.mv        s3, ra
                  c.addi      ra, -1
                  addi        a5, a1, 300
                  and         s5, t4, a7
                  divu        t4, ra, t3
                  add         zero, s10, a7
                  blt         t1, zero, 3597f
                  c.li        a6, 30
3591:             xori        zero, s7, 1833
                  mulhu       a7, t4, sp
                  c.add       s7, s3
                  sltu        a6, s1, t4
                  mul         a7, zero, s9
                  c.nop
3597:             div         s8, s9, s3
                  c.li        a1, 7
                  c.nop
                  c.xor       s1, a1
                  divu        zero, s6, zero
                  lui         s1, 633054
                  beq         a0, a5, 3605f
                  andi        t6, a2, 1157
3605:             c.and       a0, a1
                  c.srai      a4, 24
                  sub         s3, t0, gp
                  addi        t3, s7, 1529
                  blt         s8, s9, 3621f
                  mulh        s6, s3, s2
                  ori         s11, t1, -736
                  mul         sp, t4, a7
                  mulhu       s5, gp, s6
                  sll         ra, zero, zero
                  bge         a7, t2, 3621f
                  bgeu        gp, t0, 3635f
                  sltu        zero, zero, t4
                  bgeu        t0, s10, 3622f
                  c.addi4spn  a0, sp, 976
                  sll         s6, t3, s2
3621:             c.beqz      a0, 3636f
3622:             divu        t3, s2, gp
                  divu        s5, t3, s9
                  c.beqz      a2, 3638f
                  bgeu        s7, a5, 3644f
                  bgeu        t2, a6, 3628f
                  mulhsu      a1, a2, sp
3628:             c.and       a0, a4
                  slti        s8, a0, 1268
                  divu        zero, t2, tp
                  slti        s3, zero, -1304
                  andi        zero, a2, 875
                  slt         zero, a7, a0
                  slti        zero, a4, 260
3635:             divu        s1, a5, s9
3636:             mulhsu      s3, s10, a2
                  nop
3638:             or          t3, s4, gp
                  xori        s1, a0, -1775
                  or          s8, a2, s5
                  sra         a0, t4, s7
                  sltu        s5, sp, t2
                  slli        a7, t1, 25
3644:             lui         s0, 733979
                  c.slli      t3, 20
                  c.addi      a2, 8
                  rem         t1, s9, s7
                  c.addi4spn  a0, sp, 112
                  bne         a7, t1, 3669f
                  sltiu       zero, s0, 1380
                  blt         a2, a0, 3663f
                  bgeu        gp, s7, 3672f
                  rem         s1, a2, s11
                  slli        a0, t1, 29
                  addi        zero, a1, -1981
                  mulhsu      a0, a0, s10
                  c.xor       a0, a3
                  c.lui       s0, 27
                  or          t3, t3, s11
                  c.or        a3, a5
                  c.mv        t6, a2
                  c.beqz      a0, 3674f
3663:             c.addi16sp  sp, -16
                  bgeu        t2, t3, 3683f
                  bgeu        s1, ra, 3677f
                  c.sub       a2, a1
                  srli        t0, ra, 31
                  c.srai      a3, 11
3669:             c.li        ra, 4
                  sll         s0, a2, a7
                  sra         a1, s7, t1
3672:             c.nop
                  c.beqz      s0, 3682f
3674:             ori         s3, t2, -190
                  slti        tp, s2, -180
                  sltiu       s1, ra, 700
3677:             sltiu       t1, s0, 1785
                  srl         sp, s5, ra
                  or          zero, a5, gp
                  bge         sp, a3, 3694f
                  addi        zero, gp, 1152
3682:             c.addi4spn  a3, sp, 656
3683:             c.and       a3, s1
                  div         s4, a1, zero
                  addi        s4, a6, -1952
                  nop
                  c.mv        a6, s5
                  c.add       t3, a4
                  c.nop
                  addi        zero, s10, 226
                  mulh        gp, s4, t2
                  c.lui       a0, 17
                  rem         zero, t0, a3
3694:             c.slli      s0, 1
                  c.addi4spn  a0, sp, 960
                  sll         s8, sp, a1
                  c.xor       a0, a1
                  mulhu       s0, a1, a3
                  srai        a4, s4, 16
                  slli        s0, s10, 28
                  c.beqz      a3, 3705f
                  nop
                  auipc       s9, 425017
                  c.lui       s5, 5
3705:             divu        s7, t1, s4
                  rem         a1, tp, a3
                  c.andi      a0, -1
                  c.addi4spn  a5, sp, 672
                  xor         a5, a5, s3
                  c.add       s4, t3
                  div         zero, a3, t0
                  div         a6, s2, s10
                  mulhu       s5, s5, t1
                  sra         zero, t1, a1
                  c.sub       a0, s1
                  c.mv        s2, a2
                  mulhu       s5, a4, tp
                  mulhu       a6, a4, ra
                  mulh        a2, s9, t5
                  bgeu        t4, a3, 3722f
                  andi        a7, a7, -255
3722:             ori         a3, ra, -802
                  slli        s6, zero, 8
                  c.beqz      a0, 3741f
                  nop
                  c.lui       t1, 1
                  sra         zero, s6, t0
                  c.beqz      a0, 3742f
                  addi        t6, t3, 744
                  c.andi      a3, -1
                  c.slli      t6, 23
                  mulhu       zero, s5, a4
                  sub         t4, s3, a6
                  mul         s3, a0, a7
                  divu        t3, s4, t6
                  srli        s6, ra, 17
                  sra         s6, s10, gp
                  mulh        s2, t4, s11
                  div         sp, t1, gp
                  c.addi16sp  sp, -16
3741:             auipc       a3, 950683
3742:             sll         gp, a0, s8
                  c.beqz      a3, 3751f
                  auipc       gp, 827199
                  andi        a3, s0, -23
                  srl         sp, t5, s0
                  c.xor       a3, a2
                  c.or        a0, a2
                  mul         gp, t3, gp
                  beq         ra, t2, 3758f
3751:             c.beqz      a0, 3771f
                  c.li        t0, 12
                  sub         s3, s6, s7
                  div         zero, sp, s11
                  srai        a0, s11, 9
                  blt         t1, a0, 3774f
                  nop
3758:             auipc       zero, 856118
                  slt         zero, t6, t1
                  slti        sp, t4, 1652
                  c.or        a0, a1
                  ori         s0, t0, -1458
                  mulhsu      a0, s10, t2
                  c.andi      a0, 3
                  c.nop
                  c.addi16sp  sp, 368
                  srl         t0, s0, s8
                  or          gp, t2, t0
                  nop
                  sra         s4, a5, s0
3771:             sltiu       a7, gp, 1432
                  srl         a1, tp, t4
                  divu        s6, s10, t0
3774:             blt         s3, s4, 3788f
                  c.and       a2, a0
                  or          s8, tp, t0
                  auipc       zero, 911129
                  beq         a1, gp, 3784f
                  mulhu       a5, ra, s9
                  ori         s0, s11, 538
                  sub         a7, ra, s9
                  c.srai      a2, 15
                  ori         a7, a0, 300
3784:             srai        zero, s3, 19
                  bge         a6, gp, 3795f
                  c.add       s2, s2
                  c.nop
3788:             divu        tp, gp, a5
                  bne         s3, s7, 3809f
                  bge         s3, a6, 3809f
                  c.mv        t0, s4
                  c.srli      a0, 7
                  bgeu        a5, zero, 3810f
                  c.li        a2, 12
3795:             slli        s7, s4, 9
                  andi        gp, s10, 1482
                  beq         s9, s4, 3803f
                  c.sub       a5, a5
                  or          t1, s8, s0
                  c.or        s0, s0
                  c.add       ra, s6
                  mul         t3, a3, a3
3803:             c.slli      s7, 12
                  c.and       a0, a1
                  sub         s7, sp, s0
                  slti        t1, a2, 1073
                  c.sub       a0, a1
                  mulhsu      a7, s7, s8
3809:             sub         zero, t0, t2
3810:             mulhsu      a4, t3, t4
                  and         a0, a7, s9
                  c.xor       a0, a4
                  bgeu        s0, s1, 3821f
                  sub         t0, s3, a6
                  c.xor       a0, a3
                  mulhsu      s8, s5, sp
                  xori        zero, s1, 111
                  sll         s4, s0, ra
                  c.nop
                  sltiu       t6, t0, -324
3821:             c.and       a0, a1
                  rem         a2, s11, a3
                  c.lui       s8, 11
                  and         a5, s6, s9
                  andi        s6, gp, 1579
                  c.beqz      a0, 3843f
                  auipc       a7, 192620
                  xori        gp, s5, -331
                  c.srli      a0, 22
                  srai        zero, a6, 25
                  c.li        ra, -1
                  bltu        s9, tp, 3845f
                  bltu        s6, t1, 3850f
                  xor         a1, sp, zero
                  andi        gp, s9, -1849
                  c.addi4spn  a0, sp, 640
                  sltu        s1, s10, s0
                  c.addi16sp  sp, 96
                  mul         s7, t1, s3
                  bge         a2, t0, 3855f
                  c.nop
                  bltu        s10, s0, 3848f
3843:             xori        s8, ra, -1843
                  and         s3, t1, s3
3845:             bge         s10, t2, 3854f
                  c.beqz      a5, 3865f
                  beq         s11, t2, 3866f
3848:             c.srli      a2, 21
                  c.addi4spn  a0, sp, 480
3850:             slt         t0, a4, t3
                  c.or        a2, a5
                  c.lui       a1, 22
                  c.slli      sp, 21
3854:             c.sub       a3, a2
3855:             c.srli      a2, 18
                  slli        zero, sp, 11
                  xori        s8, ra, -1423
                  c.mv        s8, a7
                  c.srli      a3, 30
                  blt         t6, a5, 3879f
                  bne         a2, a7, 3874f
                  nop
                  c.slli      t0, 22
                  sll         a2, s7, s10
3865:             c.andi      a3, 5
3866:             ori         t6, s4, 1703
                  xor         a3, a4, s11
                  c.srai      a0, 28
                  sra         s9, s6, a7
                  and         s8, s6, s10
                  div         s4, s7, gp
                  c.add       a3, s1
                  div         t0, t0, a0
3874:             addi        s5, ra, -600
                  mul         a3, t3, ra
                  mulhsu      a5, a5, t6
                  c.lui       a4, 30
                  c.li        ra, 4
3879:             srl         a2, a3, a7
                  slt         s6, a6, a6
                  c.add       ra, a3
                  slt         tp, a4, a7
                  srai        s1, s11, 3
                  c.andi      a0, 25
                  srai        a7, a6, 7
                  c.lui       ra, 29
                  c.sub       a0, a2
                  mulh        a6, s2, s0
                  rem         a7, a0, s9
                  c.srli      a0, 19
                  ori         s5, s9, -78
                  sra         a1, s11, s4
                  c.addi4spn  a2, sp, 736
                  div         s0, t6, t4
                  mulhsu      s6, t2, a6
                  c.addi      ra, -1
                  c.addi16sp  sp, -16
                  addi        a0, a2, 662
                  c.slli      s2, 29
                  beq         t6, gp, 3920f
                  xori        a0, s3, 1837
                  sll         zero, s9, s1
                  sll         gp, t5, s8
                  xor         zero, tp, s5
                  and         s6, a7, a6
                  rem         zero, t6, s8
                  auipc       gp, 759812
                  c.beqz      a3, 3928f
                  slt         zero, s8, a0
                  c.srli      a2, 17
                  div         a1, ra, a4
                  srl         a3, s0, s8
                  c.li        s9, -1
                  srai        zero, a7, 27
                  c.or        a0, a1
                  c.and       a3, a3
                  c.srli      a2, 11
                  sll         a4, t3, ra
                  c.xor       a0, a2
3920:             c.addi4spn  a0, sp, 704
                  c.slli      s8, 19
                  mul         t6, s4, ra
                  srai        t3, s5, 1
                  xori        t3, a6, 562
                  rem         a7, a7, a5
                  slli        t0, a3, 27
                  c.add       ra, t0
3928:             c.addi16sp  sp, -16
                  srai        s7, t1, 0
                  or          zero, a5, t0
                  sltiu       a5, a1, -275
                  mul         s11, t2, gp
                  andi        a5, a5, 1318
                  sltu        s4, tp, s0
                  c.and       a1, a1
                  c.srli      a0, 3
                  mulh        sp, t6, sp
                  beq         t0, t3, 3942f
                  addi        s11, s5, 924
                  xori        a4, s11, -502
                  srli        s9, zero, 29
3942:             c.srli      a3, 4
                  slti        a3, t2, 217
                  xor         s3, s9, s10
                  sub         a6, s1, t3
                  blt         s4, s1, 3954f
                  c.nop
                  sltu        s2, s5, gp
                  div         a1, s3, s5
                  c.li        t6, 29
                  nop
                  add         s11, s10, a3
                  c.beqz      a0, 3973f
3954:             xor         zero, s1, s5
                  auipc       s3, 875555
                  c.andi      a0, 9
                  divu        a1, s10, t3
                  addi        t1, t4, 1831
                  c.and       a5, a1
                  lui         t1, 283416
                  c.srai      a2, 12
                  c.addi      a7, 12
                  c.sub       a2, s0
                  c.srli      a0, 19
                  xor         s3, sp, s4
                  rem         s5, sp, zero
                  sra         zero, s2, t3
                  c.srli      s0, 12
                  c.xor       a3, a2
                  beq         a5, s2, 3985f
                  c.add       a5, a5
                  div         zero, t0, a1
3973:             bltu        t4, s0, 3979f
                  c.addi      ra, 19
                  c.xor       a0, s1
                  bne         t4, a1, 3984f
                  c.addi      s11, 27
                  bltu        s0, t1, 3988f
3979:             c.add       gp, s3
                  xori        s4, a0, -1228
                  slli        sp, t3, 9
                  mulh        s8, s2, s3
                  c.nop
3984:             srli        a2, t4, 7
3985:             lui         s2, 360767
                  c.srli      a0, 13
                  slti        s6, zero, -1772
3988:             and         a1, t3, a6
                  and         s3, t5, s9
                  c.and       a0, s1
                  bgeu        a2, sp, 4005f
                  auipc       zero, 249044
                  c.beqz      a0, 4013f
                  addi        a0, gp, 1899
                  c.srli      s1, 1
                  slli        s5, t4, 10
                  add         a4, s0, tp
                  c.add       tp, t0
                  c.and       a0, a3
                  c.srli      a2, 21
                  xori        a7, s0, -1348
                  mulhsu      a0, s7, t1
                  c.nop
                  slli        s1, t2, 17
4005:             bge         s5, a7, 4022f
                  auipc       a7, 971987
                  c.nop
                  c.slli      t1, 14
                  sltiu       t6, s11, -673
                  c.add       a4, a1
                  sll         s8, s5, s6
                  c.addi      tp, 15
4013:             c.andi      a0, -1
                  sub         s2, t1, s9
                  div         zero, a1, s11
                  c.srai      a0, 10
                  mul         t1, s9, t1
                  addi        s9, s8, -290
                  slt         zero, a0, t0
                  c.addi      gp, 20
                  srl         s6, t5, t5
4022:             slt         a7, s8, s1
                  sltiu       zero, a6, 1296
                  add         a6, s2, t0
                  sub         s3, sp, a4
                  c.srli      a2, 15
                  srli        zero, t3, 13
                  mulhsu      s3, t1, t3
                  sltiu       s2, gp, -1583
                  c.slli      gp, 3
                  slli        gp, s10, 16
                  auipc       s9, 474532
                  and         s1, t1, t3
                  c.nop
                  c.li        t3, 26
                  lui         gp, 948712
                  lui         zero, 334377
                  or          a2, a7, t1
                  auipc       s1, 586400
                  mulhu       a5, a5, a1
                  c.mv        ra, gp
                  c.lui       a0, 14
                  mulhsu      t6, t0, t2
                  srl         a1, t3, a3
                  bge         a1, t6, 4057f
                  srai        s9, a2, 17
                  slti        s9, a0, -1700
                  auipc       zero, 776549
                  bgeu        a2, s10, 4057f
                  and         s1, s3, s11
                  c.slli      a6, 24
                  addi        s1, t1, -837
                  rem         t1, s6, a6
                  c.slli      gp, 14
                  c.li        a0, 19
                  bltu        a5, a5, 4058f
4057:             c.xor       a0, a2
4058:             bne         zero, t3, 4072f
                  c.addi4spn  a0, sp, 64
                  nop
                  ori         s3, zero, 1958
                  sltiu       a5, s4, -1120
                  c.srai      a5, 19
                  beq         a6, s10, 4066f
                  bne         a0, a3, 4083f
4066:             add         t1, s6, s5
                  auipc       a5, 767326
                  mulhsu      t0, s1, ra
                  c.sub       a0, a1
                  c.beqz      a0, 4082f
                  bne         s3, a0, 4085f
4072:             mul         t3, s3, s7
                  bge         t3, a2, 4090f
                  c.lui       tp, 1
                  div         sp, t1, a7
                  c.sub       a1, a1
                  mul         zero, a0, t4
                  auipc       s2, 1001889
                  bge         s8, a1, 4096f
                  and         a7, a7, s2
                  c.li        s6, 23
4082:             blt         t0, a1, 4099f
4083:             and         a6, s11, t2
                  c.add       s8, ra
4085:             c.xor       a0, a4
                  auipc       s1, 758117
                  mulhsu      a2, t0, s0
                  slli        s7, a7, 18
                  slti        s0, zero, 1284
4090:             xor         sp, s3, a1
                  bltu        sp, a1, 4103f
                  srai        s4, t2, 22
                  bge         s2, sp, 4113f
                  sltu        a0, t5, a6
                  mulh        a5, s5, s2
4096:             div         gp, s8, a6
                  c.andi      a0, 24
                  slti        a3, a1, 285
4099:             div         s3, sp, s0
                  c.slli      t1, 17
                  beq         s1, s2, 4105f
                  ori         sp, a5, -1575
4103:             xori        t0, a7, -71
                  slt         a7, t6, s11
4105:             c.sub       a0, a1
                  bge         t2, t0, 4120f
                  srl         sp, sp, s7
                  c.sub       a0, a3
                  divu        zero, a1, s4
                  sub         s8, tp, t1
                  c.addi4spn  a2, sp, 144
                  c.addi4spn  a0, sp, 752
4113:             c.andi      a0, 29
                  c.or        a3, a2
                  c.slli      t6, 23
                  c.addi4spn  a0, sp, 944
                  div         a4, t2, t5
                  c.sub       a2, a0
                  sra         t1, zero, sp
4120:             srai        a4, tp, 25
                  c.srli      a2, 27
                  srl         s5, s8, t4
                  srl         s2, ra, a5
                  bgeu        s11, s5, 4132f
                  xori        a4, sp, -1544
                  bltu        s6, s7, 4146f
                  c.sub       a0, a2
                  srli        s2, s0, 7
                  sub         zero, a4, a7
                  beq         a5, s7, 4149f
                  slti        s0, a5, -931
4132:             srai        a3, a2, 8
                  c.lui       t4, 3
                  c.slli      t1, 6
                  mulh        zero, s8, s10
                  andi        s2, s4, -2047
                  slti        s3, a5, -1129
                  c.sub       a0, a0
                  c.andi      a3, 8
                  andi        s1, t1, -669
                  c.and       a0, a3
                  slt         a3, s4, a2
                  c.or        a0, a3
                  sll         a6, gp, t2
                  bge         a7, a0, 4157f
4146:             c.mv        t0, t0
                  nop
                  c.li        gp, -1
4149:             add         s6, s5, s9
                  c.slli      s11, 6
                  c.li        s11, -1
                  sltu        s3, a5, t3
                  c.and       s1, a2
                  sltiu       t4, t1, -1149
                  bgeu        a6, t0, 4168f
                  slti        t6, a1, 310
4157:             srai        zero, t5, 25
                  sub         s9, a2, a4
                  bge         s11, s3, 4174f
                  mulhu       s9, s1, s7
                  addi        s0, s6, 626
                  ori         t0, a7, 530
                  slti        t6, gp, -1552
                  sll         s5, s5, a2
                  bgeu        t1, s7, 4174f
                  sra         a5, a6, s9
                  srai        s11, a0, 3
4168:             c.addi4spn  a0, sp, 704
                  andi        s6, gp, -195
                  xor         s5, s9, t0
                  or          t4, s8, t0
                  c.srai      a0, 1
                  rem         s9, a6, a4
4174:             mul         t1, t2, s6
                  mulhsu      t3, a2, s5
                  blt         gp, a2, 4182f
                  mulh        s1, a3, sp
                  c.sub       a5, a4
                  auipc       s9, 310154
                  slt         s8, tp, a1
                  nop
4182:             c.addi      a7, 13
                  c.srai      a0, 30
                  sltu        zero, s2, a5
                  divu        a4, a7, t1
                  sll         s7, a2, s4
                  bne         a1, sp, 4201f
                  c.xor       a3, a0
                  mulhsu      s0, a4, s9
                  c.slli      tp, 16
                  c.lui       a3, 15
                  bge         a5, a6, 4211f
                  div         zero, t3, tp
                  c.add       s2, s0
                  c.srli      a3, 1
                  c.srli      a4, 5
                  andi        a5, a2, 1480
                  bge         tp, sp, 4200f
                  mulhu       a7, tp, a0
4200:             c.nop
4201:             mulhu       s2, sp, t5
                  or          sp, t3, gp
                  c.or        a0, s1
                  c.sub       a0, a2
                  mul         zero, a0, t4
                  auipc       s8, 266385
                  div         zero, a0, s4
                  ori         t6, ra, 1100
                  sltu        t6, zero, ra
                  c.sub       a0, a0
4211:             c.addi      t6, 21
                  c.nop
                  sltu        t3, t1, a7
                  ori         s2, sp, 1697
                  div         zero, s4, a6
                  beq         a1, a2, 4226f
                  c.lui       a2, 15
                  c.andi      a0, -1
                  c.addi4spn  a0, sp, 880
                  add         s5, sp, s10
                  xori        a1, t5, -1884
                  xor         s0, s2, s4
                  blt         tp, s3, 4240f
                  rem         a3, zero, zero
                  blt         t5, s2, 4237f
4226:             div         s7, s6, a6
                  c.andi      a2, 0
                  div         a7, a4, s10
                  sub         s2, s5, t4
                  bgeu        zero, a6, 4236f
                  c.slli      s7, 18
                  lui         s5, 364795
                  andi        s8, s2, 1438
                  c.or        a4, a0
                  c.srli      a0, 6
4236:             mulhsu      s7, s6, s8
4237:             c.lui       a1, 20
                  c.or        a0, a2
                  c.add       ra, s0
4240:             c.addi16sp  sp, 208
                  auipc       s8, 447355
                  div         zero, s1, a1
                  blt         t2, a3, 4263f
                  mulhu       a1, t0, a6
                  bge         t1, s0, 4264f
                  c.and       s1, a1
                  c.nop
                  srli        s1, sp, 11
                  ori         a2, t2, -1296
                  sltu        a5, a1, t3
                  xor         s4, t5, s1
                  and         a4, s11, a2
                  c.nop
                  c.srli      s1, 13
                  bltu        s11, gp, 4267f
                  or          s8, t1, s4
                  mul         zero, t4, s7
                  mulh        zero, t1, t3
                  c.xor       a3, a0
                  srai        zero, a5, 2
                  c.and       a3, a1
                  sltu        zero, s8, gp
4263:             sltu        s0, s3, a1
4264:             xor         s3, s10, s4
                  sll         s7, s9, s11
                  c.nop
4267:             c.addi4spn  a4, sp, 592
                  sub         a7, a2, a4
                  xori        s2, a5, -1440
                  mulhsu      t0, s4, a3
                  c.addi      t0, 18
                  srai        t1, t3, 15
                  add         s8, t4, s7
                  c.xor       a2, a2
                  div         s4, t2, t4
                  bgeu        tp, a2, 4296f
                  slli        s6, a4, 17
                  c.addi      s5, 8
                  blt         a3, gp, 4296f
                  and         s7, s6, tp
                  ori         zero, s7, -1727
                  c.or        a0, a2
                  bltu        a4, s10, 4301f
                  sltiu       s9, zero, -402
                  c.andi      a2, -1
                  mulhsu      zero, sp, a0
                  andi        a0, gp, -1281
                  c.nop
                  xor         a2, a2, a5
                  c.addi      ra, 12
                  slli        s9, a4, 11
                  mulhsu      sp, tp, tp
                  c.li        a0, -1
                  c.li        tp, 12
                  bgeu        a5, s9, 4312f
4296:             sltiu       a2, s2, 440
                  mul         a5, s6, t2
                  c.or        a0, a2
                  ori         zero, s7, 94
                  c.addi4spn  a0, sp, 528
4301:             sltu        s4, s10, s2
                  sra         a5, a7, a0
                  mulh        tp, a1, sp
                  rem         a3, t5, s9
                  slli        gp, sp, 26
                  c.xor       a0, a3
                  c.xor       a3, a3
                  sltu        s4, t0, s9
                  c.and       a0, s1
                  div         sp, ra, s2
                  slt         s1, s10, t5
4312:             c.slli      s9, 23
                  lui         a3, 310764
                  c.nop
                  sltu        s4, t3, s2
                  c.mv        a0, t4
                  c.mv        t0, s1
                  c.addi      gp, -1
                  c.srai      a4, 5
                  bltu        t4, t3, 4328f
                  c.lui       a5, 18
                  slti        sp, t4, -1409
                  xor         a7, t2, s4
                  c.lui       t4, 18
                  xori        ra, s0, -595
                  c.addi16sp  sp, -16
                  slt         a4, s3, s9
4328:             c.mv        a3, s5
                  c.xor       a3, a0
                  mulhsu      a6, s0, a6
                  c.lui       ra, 30
                  c.sub       a2, a1
                  c.addi4spn  a2, sp, 32
                  auipc       s0, 869545
                  slt         a3, s9, t6
                  mulh        s6, s4, t0
                  and         a6, a4, sp
                  rem         zero, s8, t6
                  slti        a4, s2, -313
                  bltu        s7, s11, 4348f
                  c.sub       a2, a2
                  mulhsu      sp, s3, a5
                  c.addi      gp, -1
                  slti        s2, a5, -1454
                  sltiu       s9, t4, 18
                  c.xor       a0, a2
                  andi        t1, s9, -1186
4348:             bge         s4, gp, 4365f
                  c.and       a0, a1
                  c.or        a0, a2
                  beq         a4, sp, 4365f
                  rem         a1, a1, ra
                  c.li        a1, -1
                  c.lui       t6, 26
                  nop
                  c.srli      s0, 28
                  c.addi      t1, 5
                  c.addi      s1, -1
                  sltiu       zero, a2, -186
                  c.addi4spn  a0, sp, 944
                  lui         gp, 498486
                  slli        a3, s7, 10
                  sra         tp, a7, s1
                  c.and       a0, a0
4365:             sub         ra, t5, a6
                  slti        a2, sp, 228
                  divu        t1, s6, s11
                  beq         ra, s8, 4370f
                  sra         s11, s1, s2
4370:             mul         s9, s0, a2
                  rem         s3, t4, a6
                  c.mv        a0, t0
                  c.sub       a0, a1
                  c.add       a0, t5
                  div         a3, s11, s3
                  c.andi      a2, -1
                  bge         gp, gp, 4389f
                  andi        s3, s9, 501
                  divu        a7, t0, s11
                  sra         t6, a0, s6
                  rem         zero, t1, a2
                  sra         s3, s0, a1
                  c.mv        t6, s2
                  div         s1, s6, a3
                  rem         a3, a7, a6
                  sra         s2, t3, s3
                  bgeu        s9, tp, 4407f
                  sub         a0, a0, t2
4389:             div         s8, s11, s9
                  div         t0, a4, ra
                  bgeu        a3, a2, 4395f
                  or          zero, s1, t0
                  sub         a3, t1, s6
                  slt         gp, s8, s8
4395:             or          ra, a3, s2
                  sra         s9, t6, a1
                  andi        s8, tp, -1240
                  sub         sp, s2, tp
                  srli        a0, t2, 28
                  c.slli      s8, 5
                  blt         a2, s7, 4421f
                  c.mv        sp, s4
                  c.srli      a4, 16
                  c.slli      ra, 14
                  or          s7, a1, a1
                  c.or        a2, a0
4407:             or          tp, t5, a7
                  srl         gp, s7, t1
                  xori        a3, a0, -1968
                  c.srai      a0, 30
                  beq         a6, s8, 4428f
                  or          t0, t4, s11
                  divu        a6, s9, s5
                  c.or        a2, a1
                  lui         s6, 29646
                  add         s0, s10, s10
                  auipc       s2, 881803
                  slt         zero, s11, s3
                  c.li        a5, 18
                  c.srli      a0, 2
4421:             c.mv        s9, a7
                  mul         s2, gp, a1
                  and         a7, gp, tp
                  sll         s0, a1, tp
                  c.addi4spn  a5, sp, 304
                  xori        t4, t2, 2026
                  c.add       a2, s10
4428:             ori         zero, t1, 1436
                  c.nop
                  c.li        tp, -1
                  c.slli      a3, 19
                  andi        s5, a5, -1543
                  mulhu       s9, a1, t2
                  slti        zero, ra, -1079
                  c.mv        a6, t5
                  c.xor       a0, a2
                  c.addi      s6, -1
                  c.lui       a5, 27
                  srai        a4, s10, 24
                  or          zero, a3, a2
                  lui         s3, 594028
                  div         s3, s4, t4
                  c.or        s1, a2
                  c.xor       a0, a1
                  c.srai      a1, 31
                  srl         sp, s2, s1
                  rem         t4, t5, s9
                  slti        a3, t5, -1332
                  srl         a6, s5, t2
                  c.slli      a0, 23
                  sra         s0, a7, t4
                  slti        a0, s8, 1046
                  c.addi      a7, 19
                  c.slli      a1, 9
                  div         zero, s9, s7
                  sltu        s5, s5, a1
                  bltu        a0, sp, 4476f
                  c.beqz      a0, 4460f
                  divu        a3, a2, zero
4460:             nop
                  divu        s5, s7, ra
                  sll         zero, s4, a4
                  mulhsu      t3, a6, ra
                  c.lui       s0, 1
                  c.lui       tp, 24
                  xori        t1, s8, -864
                  c.xor       a0, a3
                  c.add       a2, t1
                  mul         sp, s10, s9
                  c.slli      ra, 12
                  c.slli      s2, 3
                  c.beqz      a2, 4489f
                  addi        t1, a4, -1708
                  c.beqz      a0, 4489f
                  c.addi16sp  sp, 96
4476:             add         a3, t5, a5
                  rem         s11, s7, gp
                  c.xor       a3, s0
                  sltiu       a7, t4, -1327
                  slti        a6, s5, -872
                  add         s5, s3, a1
                  c.li        gp, 4
                  bgeu        t0, s8, 4496f
                  add         zero, zero, t2
                  mul         s4, s2, s0
                  bge         a7, t4, 4500f
                  bge         a2, t6, 4496f
                  rem         s5, s4, s8
4489:             c.xor       a0, s0
                  c.add       a5, t3
                  addi        s7, a5, -1926
                  c.addi16sp  sp, 416
                  slt         s5, s11, s11
                  xori        s5, zero, 709
                  bge         zero, t1, 4497f
4496:             addi        s6, s7, -1878
4497:             rem         tp, tp, a2
                  mul         tp, s1, s4
                  c.andi      a0, 20
4500:             mulhsu      a0, tp, t2
                  c.beqz      s0, 4513f
                  c.nop
                  mulh        s7, ra, t0
                  c.addi16sp  sp, 320
                  and         zero, a6, a3
                  slt         zero, sp, gp
                  c.addi16sp  sp, 416
                  bltu        s4, tp, 4522f
                  slti        sp, a4, 1162
                  divu        s8, s6, a3
                  bltu        t6, ra, 4525f
                  beq         s10, a4, 4529f
4513:             srai        s2, t4, 1
                  slti        a4, tp, 287
                  c.slli      t3, 19
                  bltu        s3, tp, 4533f
                  sub         zero, t0, a1
                  c.addi4spn  a0, sp, 544
                  c.nop
                  c.srli      a2, 27
                  c.nop
4522:             ori         a0, ra, -436
                  slti        zero, a6, 1111
                  div         s7, s0, s3
4525:             mulh        a5, s8, s10
                  bgeu        a5, t1, 4534f
                  c.beqz      a3, 4546f
                  sll         zero, t4, t4
4529:             auipc       t0, 916175
                  bgeu        t6, s2, 4549f
                  lui         s2, 407680
                  srai        s0, s11, 21
4533:             mulh        s6, a7, t3
4534:             lui         zero, 408368
                  bltu        gp, s4, 4545f
                  slli        zero, a1, 5
                  beq         zero, s3, 4545f
                  sltu        a0, s9, tp
                  c.and       a0, a3
                  c.and       a0, s1
                  slti        a7, s7, -340
                  auipc       zero, 894782
                  c.addi4spn  a0, sp, 480
                  c.and       a0, a2
4545:             sub         tp, s8, s2
4546:             c.srai      a0, 17
                  c.nop
                  bge         s4, a1, 4568f
4549:             sltiu       t3, gp, 147
                  c.srli      a0, 2
                  mulhsu      tp, a3, t3
                  bge         s10, t6, 4572f
                  c.andi      a3, -1
                  addi        s5, gp, -1011
                  mulhsu      s4, a7, s4
                  div         tp, t1, a0
                  slti        a2, a1, -856
                  c.addi16sp  sp, -16
                  bne         s11, a1, 4567f
                  auipc       a0, 1022406
                  c.sub       a3, a0
                  divu        t1, a2, ra
                  c.srai      a1, 8
                  mulhsu      s8, t1, t6
                  slli        t6, t6, 6
                  xori        gp, a3, -1569
4567:             c.beqz      a3, 4579f
4568:             addi        a5, a6, 485
                  srl         a1, s6, s7
                  c.xor       a1, a3
                  slti        t0, tp, -698
4572:             divu        a0, ra, ra
                  bne         a1, t3, 4591f
                  blt         sp, a3, 4580f
                  srli        tp, s10, 16
                  c.slli      t1, 8
                  c.nop
                  mulhu       s0, s8, s2
4579:             mulh        zero, a7, a6
4580:             c.srli      s0, 7
                  srl         s9, t0, t0
                  srl         zero, s2, a3
                  sra         s0, sp, s11
                  auipc       zero, 588512
                  c.slli      ra, 28
                  c.li        gp, 5
                  sltu        s9, s8, t1
                  srai        a1, t5, 9
                  sub         tp, a1, t4
                  c.srli      a2, 15
4591:             andi        a0, s0, 157
                  c.or        a0, a1
                  divu        s2, s10, s10
                  sltiu       t1, t4, 449
                  bltu        a4, a1, 4601f
                  c.slli      s5, 1
                  srl         s5, t3, s11
                  nop
                  mulhu       a7, t3, s8
                  div         s11, s5, t3
4601:             c.sub       a3, a1
                  sltiu       zero, s6, 1088
                  c.or        a3, a2
                  c.mv        a5, tp
                  bge         s1, t5, 4622f
                  sltu        a4, s2, sp
                  beq         s5, s0, 4621f
                  bne         a7, a6, 4626f
                  c.addi4spn  a0, sp, 144
                  divu        zero, s0, tp
                  mulh        t1, a4, s6
                  mulhsu      a5, s7, t6
                  beq         a1, s1, 4633f
                  c.sub       a0, a1
                  rem         t3, t0, s7
                  sltu        a7, s4, a7
                  div         s4, s0, gp
                  beq         tp, a2, 4638f
                  bge         t4, a1, 4636f
                  c.and       a0, a0
4621:             nop
4622:             bgeu        s5, a3, 4634f
                  auipc       ra, 350024
                  or          a3, t0, s3
                  blt         a7, s3, 4639f
4626:             c.addi      sp, 29
                  c.and       a3, a1
                  c.mv        s9, tp
                  c.andi      a5, -1
                  ori         s9, s5, -790
                  xori        a4, t5, 1031
                  slli        a4, t2, 18
4633:             and         t6, a1, s4
4634:             bltu        a2, a4, 4653f
                  srli        gp, s6, 18
4636:             nop
                  bne         a7, a4, 4657f
4638:             nop
4639:             c.addi4spn  a2, sp, 528
                  sltu        ra, t0, t4
                  sltu        s1, t1, s8
                  mulh        t0, s4, a0
                  auipc       zero, 213150
                  div         s2, s1, s0
                  slt         s11, a7, s4
                  div         a4, s8, t6
                  sll         a5, s1, a7
                  c.addi4spn  s0, sp, 208
                  xori        s6, gp, -1354
                  c.srli      s1, 1
                  bge         a3, s10, 4653f
                  c.srai      a0, 1
4653:             bgeu        ra, s6, 4661f
                  c.add       a4, s1
                  c.lui       s5, 7
                  c.lui       a3, 17
4657:             add         s0, t1, t0
                  ori         zero, a3, -911
                  bne         s9, s10, 4667f
                  ori         ra, t2, 933
4661:             slt         s0, s9, ra
                  ori         a3, sp, 567
                  lui         zero, 935063
                  bne         s5, s3, 4672f
                  c.srli      a0, 20
                  nop
4667:             sra         zero, t0, tp
                  srl         t0, s9, a4
                  slt         zero, a7, a6
                  nop
                  and         s6, tp, a6
4672:             slti        s3, t2, -1779
                  bgeu        s9, a2, 4685f
                  srl         t1, t6, s10
                  c.lui       ra, 4
                  rem         s5, s11, tp
                  c.addi4spn  a5, sp, 128
                  lui         s6, 504953
                  bgeu        s4, t3, 4696f
                  c.nop
                  bltu        s11, s1, 4694f
                  xor         tp, a4, t0
                  andi        zero, gp, 580
                  c.li        a4, -1
4685:             c.lui       s1, 20
                  srai        s4, s3, 10
                  or          s8, zero, s9
                  and         a0, zero, a1
                  ori         ra, s4, 1759
                  rem         a5, s3, t3
                  c.li        ra, -1
                  sltu        a6, t1, s4
                  c.andi      a2, -1
4694:             beq         a6, a0, 4696f
                  sltu        a2, t5, t4
4696:             c.mv        s8, a6
                  bltu        tp, s11, 4707f
                  srai        zero, t4, 3
                  add         zero, a0, s2
                  sltu        sp, t4, s7
                  xor         a0, s10, t4
                  srai        t4, a5, 7
                  mulhsu      a7, tp, a1
                  c.add       s6, a3
                  mulhsu      s0, gp, s6
                  bgeu        zero, s9, 4718f
4707:             c.addi4spn  a0, sp, 176
                  beq         sp, gp, 4727f
                  divu        gp, a1, s2
                  c.srai      a4, 19
                  slt         a1, s5, s3
                  mulhsu      a1, a7, ra
                  nop
                  mulhsu      s9, s2, a7
                  auipc       t6, 666927
                  xor         t0, s4, a0
                  c.beqz      a4, 4734f
4718:             bltu        s2, s6, 4732f
                  mul         a1, t0, a4
                  or          zero, sp, a6
                  mul         sp, gp, a3
                  c.and       a1, a5
                  c.mv        gp, s4
                  srli        tp, a2, 27
                  addi        a5, s11, -534
                  xori        s0, t0, 736
4727:             c.addi4spn  a0, sp, 992
                  slt         s6, t1, t6
                  beq         a6, s4, 4749f
                  or          zero, t5, s3
                  blt         t1, t4, 4735f
4732:             slt         a0, s5, tp
                  c.sub       a0, a3
4734:             bge         tp, ra, 4753f
4735:             c.slli      s8, 23
                  rem         s7, zero, a3
                  div         s5, gp, a5
                  sub         a7, s6, sp
                  sub         s8, gp, t2
                  add         gp, s11, s1
                  ori         zero, tp, -664
                  srai        tp, t5, 5
                  andi        a7, ra, 1136
                  mulh        a7, s3, s9
                  c.sub       a0, a3
                  srli        a0, s10, 16
                  xori        tp, t3, -1177
                  c.add       s1, t2
4749:             srl         gp, t4, a1
                  xor         a2, a7, a5
                  c.slli      a4, 2
                  div         s5, t0, a7
4753:             bge         t1, s5, 4762f
                  srli        sp, a2, 5
                  xor         s3, gp, s2
                  ori         t1, t0, -1483
                  c.sub       a3, a1
                  lui         a5, 359669
                  ori         gp, s2, -189
                  slli        a0, zero, 26
                  c.nop
4762:             sra         t3, t4, s0
                  and         s0, ra, t6
                  srl         tp, s1, s5
                  mulh        ra, a0, s11
                  c.xor       a0, a0
                  c.addi4spn  a2, sp, 880
                  sra         a6, a4, s1
                  bltu        a5, s1, 4775f
                  c.andi      a0, 1
                  or          s3, gp, s8
                  blt         a4, s0, 4778f
                  mulhsu      s2, s0, tp
                  mulh        zero, t0, tp
4775:             div         s1, s1, a0
                  slli        zero, a4, 11
                  sll         s7, ra, a5
4778:             rem         s6, zero, s0
                  sll         s11, a0, t0
                  bne         a1, t4, 4795f
                  div         a5, t3, s7
                  srai        a1, t2, 16
                  c.slli      tp, 30
                  slli        s5, tp, 26
                  sltu        zero, s7, t3
                  sub         s9, ra, t6
                  c.srli      a2, 9
                  c.li        t6, -1
                  c.nop
                  addi        s6, s10, -1409
                  bltu        a5, a6, 4799f
                  c.srli      a0, 26
                  blt         zero, tp, 4813f
                  c.addi4spn  s0, sp, 704
4795:             addi        t0, s4, -1484
                  c.addi      s11, 6
                  bgeu        s9, a2, 4803f
                  sra         t1, s2, t1
4799:             mulhu       s0, t0, a4
                  sltiu       s1, s5, 1306
                  c.nop
                  c.nop
4803:             xor         zero, a1, a4
                  srai        s9, gp, 5
                  srli        tp, s9, 19
                  mulhsu      zero, a5, tp
                  blt         s8, s10, 4824f
                  c.srai      a2, 31
                  bge         t0, zero, 4826f
                  c.add       tp, t4
                  srl         t3, t0, a1
                  mulhu       t1, s4, tp
4813:             ori         a2, s1, -863
                  sll         zero, tp, s11
                  c.xor       a5, a0
                  bltu        s2, s1, 4830f
                  sll         t4, t1, zero
                  c.beqz      a1, 4830f
                  ori         s2, a0, -786
                  slt         tp, t4, s11
                  c.addi16sp  sp, -16
                  bltu        s0, t4, 4842f
                  ori         s3, tp, -1860
4824:             mulhsu      t3, zero, s7
                  c.srli      a3, 9
4826:             c.sub       a0, a2
                  sra         zero, zero, s0
                  mulhu       s3, t1, s9
                  sltu        a1, t5, s3
4830:             slti        t6, s5, 1886
                  mul         t1, s0, tp
                  slt         s6, a6, a3
                  andi        s4, s0, -801
                  c.li        s9, -1
                  nop
                  c.or        a0, a2
                  addi        t0, a4, -862
                  sub         zero, t5, s5
                  c.andi      a3, -1
                  c.and       a0, a1
                  lui         a4, 1048124
4842:             and         a1, a1, s5
                  mulhsu      sp, a5, a5
                  c.xor       a4, s1
                  mulhsu      t1, a1, t0
                  beq         t2, a1, 4856f
                  c.beqz      a3, 4861f
                  c.addi16sp  sp, -16
                  sltiu       t0, s3, 1601
                  c.nop
                  c.andi      a0, 26
                  sll         a1, a4, s6
                  blt         t6, s10, 4867f
                  srli        ra, s5, 28
                  c.beqz      a0, 4873f
4856:             c.addi16sp  sp, 128
                  ori         a3, s6, -1199
                  mul         ra, a5, tp
                  andi        gp, a0, 1947
                  c.srai      a2, 2
4861:             bge         s8, s5, 4869f
                  bgeu        a1, gp, 4879f
                  c.add       gp, a6
                  c.li        a5, 24
                  srli        s8, t4, 23
                  sltiu       a4, s3, -1256
4867:             bltu        s3, t2, 4886f
                  sltu        a4, s11, t0
4869:             sll         t4, s5, a3
                  c.and       a3, a1
                  lui         a7, 1020148
                  mulh        tp, s6, t1
4873:             sltiu       zero, t3, -1758
                  slt         a0, s8, s0
                  c.slli      ra, 9
                  c.mv        t1, s11
                  div         a0, t3, s6
                  and         s4, a0, t4
4879:             c.xor       a2, s0
                  or          zero, a6, t6
                  andi        s4, s0, 287
                  srli        s1, t4, 18
                  mulhsu      ra, a4, a0
                  c.nop
                  add         zero, a5, a2
4886:             nop
                  c.add       s0, sp
                  lui         t1, 1040584
                  c.beqz      a0, 4909f
                  rem         t0, s2, ra
                  c.li        ra, -1
                  sra         s7, s2, s6
                  c.sub       a3, s1
                  blt         a7, sp, 4896f
                  c.sub       a2, a1
4896:             bltu        ra, gp, 4905f
                  bltu        s2, t1, 4914f
                  c.srli      a3, 24
                  c.addi16sp  sp, 320
                  c.and       a0, s1
                  c.mv        s11, a5
                  srli        a2, s6, 6
                  andi        a1, a4, -232
                  add         zero, t6, s11
4905:             beq         s6, s8, 4924f
                  slt         a7, a5, sp
                  c.srli      a3, 13
                  mulhsu      sp, a1, s2
4909:             c.addi      a6, -1
                  srli        zero, gp, 22
                  bne         t2, a2, 4913f
                  c.beqz      a2, 4924f
4913:             srai        a5, s11, 8
4914:             bltu        s10, a4, 4920f
                  andi        ra, a5, 2039
                  c.srai      a2, 5
                  andi        s3, a1, -1479
                  c.addi4spn  a4, sp, 752
                  slti        a1, a6, 1332
4920:             rem         t6, gp, s10
                  c.andi      a0, 18
                  slli        a1, s8, 26
                  auipc       a2, 506130
4924:             slti        gp, s4, 333
                  add         ra, t0, a5
                  ori         s8, s10, 1190
                  blt         a7, t5, 4935f
                  mulh        tp, t2, s9
                  mulhsu      ra, t6, s4
                  bgeu        s8, t2, 4934f
                  srli        zero, a2, 15
                  rem         s6, s2, s4
                  srai        a0, t4, 17
4934:             bge         a5, a1, 4949f
4935:             srai        gp, t4, 12
                  sub         gp, t5, s2
                  c.addi16sp  sp, -16
                  lui         a3, 693931
                  c.xor       a3, a3
                  c.addi4spn  a0, sp, 816
                  c.srli      a2, 26
                  xori        s6, s3, 250
                  c.mv        t1, a3
                  srl         s3, s3, a0
                  bgeu        ra, a5, 4957f
                  c.add       t1, ra
                  c.nop
                  sra         s0, t4, t0
4949:             rem         t4, s1, s1
                  c.addi16sp  sp, -16
                  andi        tp, ra, -502
                  nop
                  rem         a6, s5, t3
                  sll         s4, zero, a7
                  bgeu        a7, s5, 4974f
                  sltiu       s5, s2, 509
4957:             or          t3, s0, s7
                  sll         s5, s3, t2
                  bltu        s0, t3, 4979f
                  bne         a7, s1, 4973f
                  add         s1, s7, t6
                  mulhu       gp, a7, zero
                  div         a2, a5, sp
                  c.xor       a0, a3
                  srli        a2, s9, 31
                  srai        a5, t6, 5
                  bne         t0, s3, 4981f
                  c.add       a2, a2
                  c.srli      a5, 2
                  addi        s0, t3, 1748
                  sltiu       s7, a3, -120
                  lui         a1, 203944
4973:             c.beqz      a3, 4977f
4974:             mulh        a7, t4, t1
                  mul         a7, a2, a1
                  c.addi4spn  a1, sp, 816
4977:             sub         a0, ra, s11
                  c.beqz      a0, 4998f
4979:             sra         a1, t1, s6
                  srl         s2, sp, s5
4981:             c.addi16sp  sp, -16
                  mulh        s11, s5, s9
                  c.add       ra, t6
                  auipc       tp, 390403
                  c.slli      s2, 15
                  add         s7, zero, a6
                  c.sub       a1, a0
                  c.xor       s0, a3
                  c.nop
                  slli        s4, ra, 3
                  andi        t3, a0, -767
                  bne         a6, a0, 5009f
                  rem         tp, s6, t1
                  srli        s5, ra, 8
                  srai        s9, tp, 18
                  sltu        s8, t4, a3
                  c.addi      a3, 31
4998:             sll         tp, s5, s8
                  sra         zero, a7, s6
                  rem         sp, a2, a1
                  div         t3, a1, s8
                  slli        s8, s10, 28
                  c.add       ra, s0
                  c.or        a3, a2
                  c.add       ra, gp
                  c.addi      s5, -1
                  c.addi16sp  sp, 160
                  c.mv        s7, ra
5009:             lui         s5, 533358
                  beq         t3, s3, 5012f
                  c.or        s0, a3
5012:             c.and       a0, a2
                  beq         s7, a3, 5021f
                  c.add       a2, ra
                  c.nop
                  sll         s8, a0, ra
                  mul         zero, s4, s6
                  c.addi      t1, -1
                  mulhu       a2, gp, s1
                  slti        s11, s8, 1919
5021:             divu        s1, gp, a5
                  c.sub       s1, a1
                  nop
                  c.add       t3, t2
                  c.andi      a0, 3
                  sub         zero, t1, s9
                  c.sub       a3, a3
                  sra         ra, t4, t4
                  bne         s2, zero, 5047f
                  c.and       a5, a2
                  blt         s0, s7, 5046f
                  blt         t5, s10, 5041f
                  c.sub       a2, s1
                  c.sub       a0, a0
                  c.addi      sp, -1
                  blt         a1, s2, 5044f
                  sll         a6, t4, a6
                  xori        s2, t4, 1485
                  sub         zero, s3, t5
                  c.xor       a0, s1
5041:             blt         a4, a1, 5058f
                  add         a4, gp, t5
                  or          a5, s9, s5
5044:             sll         t4, tp, t6
                  c.addi16sp  sp, 112
5046:             or          a7, t3, t3
5047:             c.and       a2, a4
                  slli        zero, s8, 26
                  c.addi16sp  sp, -16
                  sltiu       a2, s10, 131
                  andi        gp, s1, 1085
                  sltu        a6, a7, s10
                  c.li        a3, 4
                  lui         a5, 325968
                  sll         s1, a3, s9
                  ori         s2, tp, -1665
                  sltiu       s4, zero, -1669
5058:             lui         s6, 363832
                  or          s7, a5, s0
                  mul         t1, a3, s3
                  c.mv        t4, ra
                  sltu        s7, s2, s5
                  c.addi16sp  sp, 192
                  c.or        a2, a5
                  c.sub       a0, a0
                  rem         a4, a4, s2
                  c.srli      s0, 22
                  div         t4, a0, gp
                  c.nop
                  bne         t6, a3, 5090f
                  beq         s7, s3, 5077f
                  nop
                  bgeu        s4, t4, 5093f
                  c.xor       a0, a1
                  c.addi16sp  sp, -16
                  c.andi      a0, 18
5077:             sltiu       s7, a0, -1332
                  c.beqz      a0, 5090f
                  and         s8, a6, t4
                  lui         s9, 149493
                  and         t6, s5, a4
                  ori         s9, a0, 1740
                  slt         zero, s10, s3
                  mul         zero, t4, sp
                  slti        a7, a3, -84
                  c.beqz      a2, 5092f
                  bgeu        tp, s4, 5106f
                  c.slli      ra, 3
                  slt         t0, t3, a0
5090:             c.addi16sp  sp, 224
                  c.sub       a0, a0
5092:             slt         ra, s10, s9
5093:             div         s5, a4, gp
                  sub         t0, a6, s10
                  c.andi      a0, -1
                  c.and       s1, a2
                  slt         s7, s4, ra
                  auipc       s7, 210321
                  slt         s2, t2, a4
                  mulh        a1, zero, sp
                  addi        zero, a1, -1538
                  lui         a1, 927749
                  xor         a5, s3, s5
                  xori        s8, gp, 1261
                  c.sub       a0, a0
5106:             c.addi16sp  sp, -16
                  ori         s9, a6, -361
                  c.srli      a0, 21
                  beq         t4, a6, 5123f
                  addi        a7, s9, -861
                  beq         s0, t1, 5113f
                  c.srli      s1, 12
5113:             or          a4, sp, s4
                  lui         a3, 493005
                  beq         s3, a2, 5132f
                  and         a3, t3, s2
                  srli        s8, s1, 24
                  srl         a3, s8, s9
                  c.addi16sp  sp, -16
                  c.li        s0, -1
                  div         a3, s7, s6
                  mulhsu      zero, s4, a3
5123:             xori        a7, a5, -596
                  c.andi      a2, -1
                  beq         t5, t4, 5142f
                  bne         s2, t2, 5145f
                  c.li        s4, -1
                  c.srli      a3, 15
                  sltu        a7, s7, t4
                  srli        s7, s0, 7
                  slli        t0, a6, 29
5132:             bne         s1, a7, 5144f
                  c.addi16sp  sp, 288
                  lui         gp, 817561
                  mulhsu      t4, a5, s4
                  bltu        t6, s3, 5144f
                  lui         t3, 57790
                  nop
                  addi        sp, zero, -1859
                  c.addi4spn  a0, sp, 304
                  auipc       t1, 371696
5142:             beq         s1, a2, 5154f
                  auipc       zero, 885697
5144:             bgeu        t1, t6, 5158f
5145:             c.nop
                  c.addi4spn  a0, sp, 528
                  xor         zero, s6, a6
                  mulh        s6, a4, s8
                  sltiu       tp, s2, 388
                  c.beqz      a0, 5170f
                  srl         t0, sp, a6
                  srl         t4, s2, t6
                  slli        s8, s2, 27
5154:             c.addi16sp  sp, 288
                  bltu        s10, a1, 5168f
                  andi        zero, t3, -421
                  nop
5158:             bltu        sp, s11, 5168f
                  andi        a6, t6, -318
                  add         s2, gp, s7
                  c.addi16sp  sp, 112
                  srli        a1, t6, 14
                  c.add       ra, s5
                  lui         s7, 932568
                  or          s8, t6, sp
                  c.srli      a0, 1
                  c.and       a0, a1
5168:             rem         s1, a4, t5
                  divu        s7, a1, t5
5170:             mulhu       s9, a6, s7
                  sll         t3, a1, ra
                  rem         zero, ra, ra
                  bge         a4, t3, 5192f
                  mulhu       a1, t4, gp
                  c.add       a0, t2
                  sra         a5, a1, s8
                  xor         s6, t3, t3
                  ori         a2, t6, -361
                  c.andi      a2, -1
                  nop
                  add         s3, t6, s3
                  xori        tp, a3, 1371
                  xori        s4, t2, -1890
                  div         zero, tp, s6
                  slti        t1, a5, -784
                  c.mv        a7, s9
                  slli        s4, a0, 30
                  divu        s7, s6, a6
                  srl         s3, s6, s8
                  c.mv        s2, a0
                  mul         s1, a6, tp
5192:             sltiu       ra, t2, -1113
                  c.sub       a0, a1
                  beq         s9, a4, 5208f
                  srl         s9, a4, s0
                  slt         a4, t4, a0
                  andi        s4, sp, -684
                  div         zero, a2, a6
                  div         t1, t1, s9
                  and         tp, a3, a7
                  c.or        a2, s1
                  srl         zero, s9, a1
                  xori        t6, a3, 1053
                  sub         zero, a0, a2
                  slt         t4, a5, a0
                  c.or        a3, s1
                  slti        s9, a3, 1776
5208:             c.addi16sp  sp, 288
                  c.sub       a0, a1
                  divu        t1, sp, t6
                  bltu        t6, t0, 5223f
                  mul         s6, s5, a5
                  xori        s5, t6, -1181
                  c.add       a5, t6
                  xor         zero, s9, zero
                  sltu        t4, s10, s4
                  rem         s9, s11, t3
                  rem         t1, t4, t1
                  c.xor       a3, a3
                  mulhu       a6, s3, a3
                  c.addi4spn  a0, sp, 368
                  rem         s1, s1, a1
5223:             c.mv        t0, s9
                  srli        gp, s8, 18
                  xori        gp, s11, 1213
                  bltu        t4, s5, 5239f
                  c.mv        a1, t5
                  c.addi      s5, 14
                  div         s6, a3, t5
                  sra         a5, s7, t0
                  c.nop
                  c.andi      s0, 17
                  c.addi4spn  a0, sp, 992
                  srli        s0, a4, 12
                  and         s9, t2, gp
                  and         s7, s9, t5
                  c.srai      a2, 10
                  srai        a1, a6, 23
5239:             c.addi      t1, 10
                  div         t1, s8, gp
                  c.add       a6, a4
                  mulhsu      s0, t6, a1
                  mulhsu      t4, s1, gp
                  sub         a6, s5, s1
                  div         t0, t0, zero
                  mulhu       s6, s0, t3
                  xor         s9, s8, s0
                  mulh        s5, t1, zero
                  c.beqz      a0, 5266f
                  bne         s9, zero, 5254f
                  sltiu       gp, a2, 1505
                  or          a4, s5, s9
                  mulhu       gp, t6, a3
5254:             srli        t1, t2, 3
                  c.add       a0, s2
                  srl         t0, t5, s10
                  sub         s5, a5, s3
                  andi        gp, t1, -1444
                  c.lui       a7, 2
                  sra         zero, s10, s2
                  sra         s11, a3, t2
                  c.srai      a0, 1
                  c.andi      a3, -1
                  srai        t3, a6, 25
                  slt         a6, s10, a1
5266:             c.addi16sp  sp, 288
                  c.mv        a3, a2
                  addi        t6, t6, 1651
                  c.and       a0, s1
                  nop
                  slt         t3, zero, t5
                  divu        s4, t5, t6
                  add         a2, a3, a4
                  xori        a0, a2, -758
                  c.andi      a0, -1
                  bne         s4, t2, 5296f
                  c.li        t4, 30
                  div         t4, sp, a1
                  blt         s5, a0, 5293f
                  xor         s3, zero, s11
                  beq         t4, s5, 5300f
                  sra         s0, t2, a1
                  c.xor       a0, a2
                  sltu        t3, a1, zero
                  c.add       a7, s11
                  mulh        zero, a1, t2
                  srli        tp, a2, 0
                  c.slli      t0, 14
                  c.mv        gp, s6
                  srl         t1, t1, t4
                  mulhu       a3, a4, a4
                  lui         s6, 344132
5293:             c.andi      a0, -1
                  auipc       t0, 776823
                  c.sub       a0, a3
5296:             c.srli      a2, 21
                  bge         s2, a1, 5299f
                  slt         a3, t1, tp
5299:             c.andi      a3, -1
5300:             sra         s9, s1, zero
                  c.or        a0, a1
                  or          s0, a5, a2
                  xor         a4, t1, t6
                  sltiu       a3, t5, -1152
                  xor         zero, s4, t3
                  slli        t4, gp, 29
                  slt         s5, a1, t6
                  blt         s5, s8, 5318f
                  c.srli      s0, 15
                  divu        zero, tp, s8
                  c.mv        t6, sp
                  andi        t4, gp, 1359
                  auipc       a7, 474461
                  lui         a3, 460433
                  c.addi4spn  a0, sp, 176
                  bltu        s1, a5, 5331f
                  mulhsu      a1, a2, s4
5318:             c.lui       s8, 16
                  sltu        s0, t5, t6
                  sra         tp, a0, s1
                  c.andi      s0, -1
                  c.and       a0, a1
                  c.lui       a4, 11
                  auipc       a2, 774744
                  xori        a0, s5, 1184
                  mulhu       gp, s0, zero
                  sltiu       s1, t0, -2048
                  c.nop
                  mulhsu      tp, t5, sp
                  srai        a1, t1, 10
5331:             auipc       t1, 313274
                  c.beqz      a0, 5341f
                  bne         s5, a5, 5345f
                  xor         s7, a2, t2
                  c.add       t3, tp
                  srl         t1, ra, a4
                  c.srai      a0, 25
                  or          a2, a5, a7
                  and         ra, zero, gp
                  divu        s11, a7, a6
5341:             sub         t1, a7, t0
                  c.add       a6, t3
                  c.mv        a1, t5
                  c.srai      a0, 26
5345:             c.srai      a1, 21
                  sll         ra, tp, s6
                  auipc       ra, 49154
                  xor         zero, s9, s1
                  ori         ra, tp, 463
                  xor         s3, t6, t6
                  c.srai      a2, 7
                  c.srai      a0, 18
                  sra         s9, a6, a4
                  srli        gp, a2, 12
                  sltu        zero, t6, t6
                  sltiu       sp, s5, -1300
                  c.srai      s0, 7
                  c.andi      a3, -1
                  c.add       s4, s5
                  sra         t6, ra, tp
                  mulh        s5, a2, s7
                  c.and       a2, a1
                  c.srai      a0, 5
                  ori         zero, a1, -147
                  sra         s2, s6, s11
                  slli        t1, s3, 23
                  blt         t5, s7, 5384f
                  beq         t3, t6, 5387f
                  bltu        s5, a0, 5375f
                  c.add       ra, t2
                  andi        a2, a4, -268
                  mulhu       ra, sp, zero
                  srai        t4, zero, 6
                  srai        s2, s11, 17
5375:             bgeu        t0, s9, 5383f
                  sltiu       s5, s9, 1873
                  mul         a7, t0, s4
                  srl         ra, s6, a5
                  sltu        a1, sp, s8
                  sub         sp, s8, t6
                  c.beqz      a1, 5401f
                  slli        t4, a5, 0
5383:             c.srai      a3, 18
5384:             c.addi      a1, -1
                  c.add       a5, a0
                  blt         s3, zero, 5406f
5387:             blt         t3, s3, 5395f
                  rem         ra, tp, a1
                  srli        s3, s11, 11
                  c.li        s9, -1
                  ori         gp, t0, 1439
                  c.sub       a3, a0
                  divu        s8, gp, ra
                  addi        t6, t5, 1575
5395:             c.beqz      a0, 5412f
                  mulhu       t3, s10, a5
                  andi        s1, s9, 1551
                  divu        a7, t0, t6
                  c.beqz      s0, 5405f
                  c.beqz      a4, 5420f
5401:             andi        s9, t3, 1918
                  c.slli      s2, 2
                  div         sp, s3, a0
                  beq         s4, ra, 5416f
5405:             bne         a7, s2, 5423f
5406:             auipc       a0, 788510
                  beq         s1, t2, 5424f
                  sltiu       s7, ra, 1277
                  and         zero, a6, sp
                  c.or        a0, a2
                  c.srli      a0, 3
5412:             c.lui       t3, 2
                  srli        zero, t5, 14
                  divu        sp, t0, t6
                  c.andi      a0, -1
5416:             xor         t4, s0, s8
                  add         t1, a1, s5
                  xori        t4, s10, -84
                  c.nop
5420:             mulhsu      s2, s8, s5
                  slti        t4, t4, -1201
                  c.and       s1, s1
5423:             xori        zero, s11, -112
5424:             sltiu       gp, t3, 1759
                  mulhsu      s0, a5, s6
                  or          a4, a0, s1
                  c.srai      a0, 14
                  c.addi16sp  sp, -16
                  c.slli      t6, 6
                  sltiu       sp, s0, -1562
                  srl         a2, s6, s5
                  sub         zero, t0, s5
                  c.or        a0, a3
                  c.nop
                  mulhu       s5, ra, s0
                  c.slli      ra, 27
                  sltiu       a2, a5, 1033
                  srl         s3, s8, a1
                  xori        s9, s4, 910
                  c.beqz      a0, 5459f
                  c.and       a0, a1
                  c.or        a0, a1
                  nop
                  bge         t2, s10, 5458f
                  c.nop
                  and         gp, s4, s1
                  slt         s0, a2, a5
                  ori         s0, a0, -814
                  sub         a2, sp, s6
                  c.and       a0, a5
                  div         s5, t6, a4
                  bgeu        a3, t4, 5454f
                  c.srai      a3, 3
5454:             c.add       sp, sp
                  c.nop
                  andi        tp, a7, -720
                  sub         a7, a0, t6
5458:             andi        a5, sp, 1392
5459:             beq         s9, a1, 5467f
                  srli        zero, s4, 10
                  and         a1, a3, a5
                  c.nop
                  sub         a4, a4, a6
                  nop
                  c.addi4spn  a0, sp, 944
                  c.slli      s1, 20
5467:             blt         a6, s1, 5479f
                  c.xor       a1, a0
                  andi        a6, a6, -363
                  srai        s7, s2, 11
                  c.nop
                  c.and       a0, a2
                  srai        s8, t6, 9
                  c.add       s1, s6
                  beq         tp, s7, 5487f
                  srl         a7, a4, gp
                  c.addi4spn  a2, sp, 576
                  slt         a5, s5, s0
5479:             bgeu        zero, tp, 5485f
                  slti        s9, a5, 736
                  c.srai      a0, 26
                  slli        s8, a0, 20
                  c.addi      ra, 14
                  c.add       a5, s5
5485:             c.slli      s7, 14
                  srli        a1, a1, 19
5487:             sub         a2, a4, t3
                  mulhsu      ra, ra, a0
                  blt         s9, a4, 5493f
                  c.mv        ra, ra
                  c.mv        sp, s0
                  c.li        a3, -1
5493:             c.mv        sp, s5
                  mul         t1, t6, gp
                  slt         t4, t1, a7
                  bge         t6, a0, 5504f
                  c.nop
                  c.slli      s3, 21
                  c.xor       a2, a3
                  blt         s5, s2, 5502f
                  mulh        a7, zero, s10
5502:             c.andi      a2, -1
                  slti        s11, s3, 109
5504:             sub         a1, sp, s5
                  c.lui       ra, 22
                  nop
                  sll         ra, t1, a0
                  srai        s8, t6, 17
                  bge         s6, gp, 5528f
                  and         zero, t5, gp
                  c.srli      a0, 31
                  ori         s1, t1, -1278
                  addi        a0, tp, -1573
                  div         s6, t6, tp
                  c.lui       s9, 25
                  addi        s2, s8, 1262
                  slti        s6, sp, 353
                  c.nop
                  bge         s0, t4, 5521f
                  slli        s0, a1, 20
5521:             c.andi      a3, 12
                  c.nop
                  c.and       a0, a2
                  c.addi4spn  a2, sp, 864
                  andi        a2, t5, 134
                  addi        s2, s6, -795
                  c.mv        t1, a0
5528:             srl         s1, s6, s4
                  and         s1, a5, zero
                  sra         s2, a5, t1
                  ori         s1, a1, 1335
                  bne         zero, s11, 5544f
                  ori         s3, t4, 110
                  divu        zero, t5, s4
                  nop
                  xor         s9, a6, s8
                  c.add       s8, a4
                  c.or        a0, a3
                  div         t1, t4, a0
                  c.addi16sp  sp, -16
                  bne         s11, a2, 5556f
                  c.andi      a0, -1
                  blt         a6, ra, 5560f
5544:             add         sp, tp, s11
                  add         a7, s8, s8
                  bgeu        s9, a3, 5563f
                  mulh        s1, a7, a3
                  mulh        gp, s8, tp
                  c.srai      a3, 1
                  c.addi16sp  sp, 96
                  nop
                  sll         ra, sp, t1
                  bne         zero, ra, 5561f
                  div         a5, t4, t3
                  andi        s11, t4, 1095
5556:             auipc       tp, 1043794
                  sltu        a5, t0, sp
                  andi        s11, s6, -1162
                  or          zero, a0, s8
5560:             and         s4, s0, t3
5561:             bgeu        t5, sp, 5581f
                  bltu        a6, a2, 5582f
5563:             slti        t1, t0, -190
                  bgeu        s0, s8, 5584f
                  c.nop
                  c.li        tp, -1
                  sltu        s9, s10, a1
                  srai        a0, s6, 24
                  addi        zero, s2, -1887
                  div         s6, t2, s0
                  slti        a2, s5, 1446
                  c.nop
                  c.andi      a0, 13
                  sra         t4, a3, a5
                  auipc       t6, 391355
                  c.addi      s7, 13
                  sub         a7, s4, ra
                  c.andi      a0, 19
                  c.beqz      s1, 5593f
                  mulhu       t1, a6, s8
5581:             div         t3, a3, a4
5582:             mulhu       a7, ra, a6
                  xor         a0, a7, s4
5584:             andi        s8, s6, 110
                  sub         sp, t6, s11
                  div         zero, s4, s1
                  sltu        s1, a4, a3
                  c.slli      s8, 8
                  and         s5, t2, s6
                  c.addi4spn  a3, sp, 848
                  c.lui       ra, 5
                  bge         a4, tp, 5609f
5593:             c.addi4spn  s0, sp, 1008
                  sub         t3, s5, t2
                  bltu        s9, gp, 5615f
                  div         s2, s9, a2
                  srai        t4, a2, 6
                  c.mv        s1, t2
                  sltu        sp, s3, a0
                  blt         a7, tp, 5619f
                  sltu        t6, sp, ra
                  addi        sp, t6, -19
                  sltiu       t6, zero, -1329
                  srl         s3, t0, s6
                  slti        a6, tp, -344
                  blt         t5, a1, 5612f
                  bge         s0, s9, 5626f
                  c.addi      tp, -1
5609:             ori         a5, tp, 1184
                  c.xor       a5, s1
                  srai        gp, a1, 7
5612:             div         s9, s4, a5
                  bne         t6, s5, 5631f
                  c.add       t1, a3
5615:             mulh        s9, sp, a1
                  blt         s8, s8, 5624f
                  c.or        a4, s0
                  slli        s1, a0, 16
5619:             srli        s0, a5, 24
                  mul         s11, a7, s7
                  nop
                  c.andi      a3, -1
                  nop
5624:             c.slli      t3, 1
                  auipc       t0, 728089
5626:             xor         s3, a5, t3
                  bge         s0, s6, 5637f
                  c.addi      tp, -1
                  div         a0, s5, s7
                  mulh        a5, t4, zero
5631:             c.lui       s4, 23
                  c.li        a0, -1
                  mulh        t4, t0, a6
                  divu        s6, t0, s10
                  srli        s9, t6, 5
                  bne         t1, s11, 5649f
5637:             beq         s5, t0, 5651f
                  nop
                  divu        t1, s3, a0
                  and         s8, t0, t3
                  xor         a5, s8, s5
                  mulhu       s11, s6, s11
                  sra         a2, zero, s2
                  c.li        t6, -1
                  c.andi      a3, -1
                  mulhsu      ra, ra, t0
                  c.addi      t3, -1
                  c.andi      a3, 11
5649:             mulh        s11, a4, t0
                  sra         sp, s9, s10
5651:             c.nop
                  beq         s0, t1, 5666f
                  xor         s6, tp, s5
                  bge         t2, a0, 5671f
                  bne         tp, s1, 5664f
                  c.slli      ra, 10
                  rem         t3, sp, a5
                  blt         t3, s7, 5675f
                  blt         s5, s1, 5667f
                  nop
                  slt         a3, s11, t4
                  slt         s11, zero, zero
                  c.sub       a4, a3
5664:             c.sub       s1, a0
                  bne         s3, gp, 5683f
5666:             or          a3, a6, s4
5667:             srai        s9, a7, 1
                  bltu        a4, s2, 5682f
                  slt         zero, s7, a6
                  mul         t0, a6, a3
5671:             bgeu        a0, tp, 5680f
                  c.sub       a2, a1
                  c.lui       s5, 29
                  c.or        a3, a3
5675:             c.add       s9, a2
                  c.or        a0, a1
                  bge         s11, a1, 5689f
                  mul         sp, s3, s1
                  bne         a5, t6, 5693f
5680:             bltu        s9, a6, 5695f
                  ori         a6, s3, -263
5682:             blt         s5, a0, 5701f
5683:             c.srli      a3, 4
                  or          zero, s4, s4
                  c.xor       a0, a1
                  c.xor       a0, a2
                  c.or        a2, a1
                  c.or        a0, s0
5689:             blt         s11, a5, 5706f
                  c.mv        a1, s1
                  c.addi16sp  sp, -16
                  sra         a1, s5, s1
5693:             c.li        a3, 9
                  c.addi4spn  a2, sp, 592
5695:             srli        a0, t6, 7
                  mul         s0, t0, a6
                  mulhsu      s5, t4, zero
                  sub         s0, s11, s0
                  mulhu       zero, t0, a3
                  slti        t0, t1, -655
5701:             c.sub       s1, a2
                  bltu        t0, s5, 5710f
                  c.sub       a2, s1
                  rem         t4, tp, gp
                  c.lui       s0, 16
5706:             c.or        a0, a0
                  bltu        s8, s9, 5727f
                  rem         t6, s3, s4
                  c.srai      a0, 14
5710:             c.srli      a0, 10
                  andi        s2, tp, -591
                  c.and       a0, a0
                  sub         s4, s4, zero
                  divu        s2, a0, s6
                  c.or        a0, a1
                  sltiu       ra, a0, 1543
                  slli        t0, s5, 12
                  c.andi      a5, -1
                  c.addi4spn  a1, sp, 976
                  c.li        t0, 21
                  lui         t4, 211894
                  addi        gp, t4, 1584
                  c.andi      s1, 26
                  xor         tp, a5, s7
                  sltiu       zero, t5, 629
                  sltiu       t4, a2, -901
5727:             srai        zero, a3, 15
                  c.lui       a4, 3
                  slti        s6, t1, -1849
                  add         a3, t0, s10
                  srai        a1, t0, 16
                  c.addi16sp  sp, 176
                  xor         zero, zero, a1
                  c.add       gp, sp
                  sub         a6, s9, s3
                  c.mv        s11, a0
                  xor         ra, t2, sp
                  c.xor       a3, a4
                  srl         s1, s0, s10
                  c.sub       a0, a3
                  c.add       t0, s9
                  slti        t4, a1, 410
                  xori        a3, a7, -855
                  lui         a0, 848576
                  c.sub       a0, a3
                  c.and       a3, a1
                  or          s9, s11, s6
                  c.andi      s0, -1
                  auipc       a2, 722808
                  rem         tp, tp, a2
                  sltiu       zero, a0, -687
                  mulhu       tp, t6, s10
                  c.and       a5, a3
                  sll         s8, a4, t6
                  bgeu        t2, t2, 5774f
                  mulhsu      zero, t0, a3
                  slt         s6, t0, a7
                  div         gp, a5, s4
                  c.xor       a0, a3
                  c.sub       a0, a0
                  add         t0, s7, zero
                  divu        s4, s11, sp
                  sub         s7, t6, s11
                  c.srli      a2, 25
                  c.addi16sp  sp, -16
                  c.and       a0, a3
                  beq         s4, s7, 5773f
                  mulh        a7, ra, t1
                  c.or        a3, a0
                  xor         t3, sp, a7
                  srai        s5, s11, 15
                  nop
5773:             mulhu       gp, s10, t6
5774:             mulhu       s5, a6, t4
                  mulhu       s8, s5, s2
                  c.srli      a3, 6
                  c.beqz      a0, 5797f
                  div         zero, s5, a4
                  c.addi4spn  a3, sp, 96
                  add         t4, s7, t6
                  c.xor       a3, a0
                  srl         gp, a4, s2
                  c.xor       a3, a3
                  bltu        s9, t4, 5790f
                  mulh        s3, t3, a0
                  blt         t1, s8, 5790f
                  c.sub       a0, a2
                  bne         s1, a4, 5802f
                  sub         t3, s3, s5
5790:             add         t6, s0, s5
                  c.slli      a3, 1
                  sll         a3, s0, t1
                  c.nop
                  rem         a5, zero, a2
                  sra         s4, t6, tp
                  xor         s4, zero, t2
5797:             sub         a0, zero, s10
                  beq         zero, s6, 5818f
                  xor         s9, ra, s1
                  sra         s2, s1, a3
                  add         s5, t6, tp
5802:             xor         zero, t1, s0
                  sltiu       a4, t1, -423
                  srai        s4, a5, 21
                  sra         s2, a1, gp
                  c.xor       a0, s0
                  add         zero, t2, t2
                  sra         a7, gp, tp
                  divu        t3, s9, t5
                  c.li        s9, -1
                  add         s11, a3, s10
                  srai        sp, s9, 6
                  c.srai      a3, 24
                  lui         s8, 766188
                  sub         a5, tp, s11
                  sub         s2, a6, s11
                  c.slli      a2, 9
5818:             srli        t6, s5, 18
                  lui         t3, 1025320
                  addi        a1, a2, 72
                  and         t6, t2, a1
                  mulhu       s7, tp, s7
                  c.sub       a0, a0
                  c.addi16sp  sp, 432
                  c.mv        s7, s5
                  srli        s2, t4, 21
                  c.andi      a2, -1
                  c.srai      a5, 1
                  blt         s8, s9, 5846f
                  c.nop
                  and         s9, sp, s9
                  mul         s6, s1, zero
                  srl         zero, t5, s10
                  srli        zero, t6, 8
                  srai        s4, t3, 9
                  c.beqz      a3, 5844f
                  add         a5, a2, a5
                  c.and       a0, a3
                  and         a5, s3, s9
                  ori         s11, s1, 1692
                  or          s5, s2, s4
                  srli        t3, gp, 31
                  and         a1, s2, tp
5844:             c.addi      s6, 20
                  sll         zero, zero, a1
5846:             sra         t1, t6, tp
                  c.addi      s0, 7
                  xori        t4, t1, 2019
                  srl         a4, t4, s1
                  sra         zero, a7, t1
                  blt         sp, t6, 5861f
                  c.addi16sp  sp, -16
                  xor         s9, s8, a6
                  bge         zero, tp, 5874f
                  c.mv        ra, s4
                  srli        s11, s10, 28
                  bge         s9, a7, 5870f
                  sub         a2, t5, s7
                  bge         s3, gp, 5876f
                  c.addi4spn  a3, sp, 384
5861:             addi        t0, s4, 115
                  divu        s8, s2, zero
                  slt         ra, t3, s10
                  c.sub       s1, s0
                  add         t4, t2, a5
                  slt         zero, zero, s9
                  ori         s11, s9, -9
                  auipc       a4, 761832
                  c.nop
5870:             bne         a7, s1, 5882f
                  slti        s2, s5, -3
                  lui         zero, 60909
                  mulhu       s2, s8, s3
5874:             slt         s1, s8, s10
                  andi        t0, sp, 1054
5876:             c.andi      a0, -1
                  c.add       s4, tp
                  mul         a4, t1, s5
                  mulh        s11, s10, s9
                  bne         s5, s11, 5882f
                  mulhsu      t3, s0, t1
5882:             xor         t4, t5, s10
                  bge         s6, s9, 5885f
                  c.nop
5885:             add         s11, s4, t5
                  ori         gp, s11, -1734
                  mulhsu      s5, gp, s4
                  c.addi4spn  a0, sp, 784
                  sltu        t6, s3, ra
                  mulh        a6, a0, t5
                  sub         a6, a7, t1
                  addi        s2, tp, -259
                  addi        a5, a1, -1449
                  srl         a6, t6, s3
                  blt         s4, s5, 5914f
                  c.nop
                  add         zero, s7, s6
                  c.slli      a5, 1
                  c.or        a0, a3
                  sll         s5, t5, a2
                  andi        t3, zero, 1475
                  c.mv        ra, a7
                  divu        tp, s3, a2
                  xori        a0, s1, 774
                  c.or        a3, a2
                  sub         zero, t4, t3
                  c.addi4spn  a0, sp, 416
                  addi        s9, a5, -557
                  c.nop
                  bgeu        s10, ra, 5922f
                  divu        s3, a3, s2
                  c.addi      a4, -1
                  slt         s4, t0, t3
5914:             slti        s4, a4, -1244
                  sltu        a2, t5, s1
                  c.srai      a3, 7
                  mulhsu      s11, a5, ra
                  c.addi      a3, 8
                  c.or        a0, a1
                  c.mv        a4, sp
                  sltiu       t1, a5, 1104
5922:             slti        s7, s10, 1893
                  mul         zero, a1, gp
                  divu        s8, a1, t3
                  c.add       s8, s7
                  lui         s7, 261959
                  or          s3, a7, t0
                  beq         t2, ra, 5942f
                  c.addi      s6, -1
                  c.xor       a2, a4
                  c.addi      a7, -1
                  mulhsu      t1, a5, s5
                  xor         a5, s5, sp
                  rem         zero, t1, a2
                  bge         s6, t6, 5954f
                  bltu        a2, s5, 5956f
                  slti        s3, t1, -1719
                  bne         tp, t5, 5958f
                  c.nop
                  nop
                  bge         s3, a7, 5961f
5942:             c.beqz      a0, 5944f
                  bltu        a7, s2, 5955f
5944:             c.nop
                  sltu        ra, sp, s0
                  or          s4, s0, t6
                  sll         s6, sp, s5
                  sub         a4, gp, s3
                  c.or        a1, a3
                  c.li        ra, 0
                  addi        gp, zero, -1188
                  c.or        a2, a2
                  c.li        s11, -1
5954:             srai        a2, s7, 5
5955:             c.addi16sp  sp, 128
5956:             srli        a7, t5, 28
                  c.slli      s0, 19
5958:             xori        t4, a7, 382
                  slt         s0, s3, zero
                  bgeu        a0, s10, 5977f
5961:             mulhu       zero, a6, a6
                  c.addi4spn  a0, sp, 416
                  slli        a0, ra, 11
                  auipc       s3, 326468
                  xor         s9, a7, s10
                  c.addi4spn  a2, sp, 496
                  c.nop
                  beq         ra, a6, 5982f
                  bgeu        t1, a1, 5977f
                  and         s8, s4, a3
                  c.addi      t1, -1
                  c.sub       s1, s0
                  c.xor       a0, a3
                  lui         a3, 235362
                  srl         t0, t3, s2
                  c.lui       ra, 26
5977:             c.sub       a0, a3
                  bne         t1, s10, 5986f
                  slti        zero, t3, 791
                  lui         zero, 406559
                  div         t4, s7, s11
5982:             xori        t6, gp, 1936
                  or          zero, t6, s8
                  c.addi16sp  sp, 336
                  c.li        s11, -1
5986:             bltu        ra, a1, 5994f
                  bgeu        s4, s10, 5989f
                  divu        gp, t5, s0
5989:             srli        s8, a4, 6
                  c.addi16sp  sp, -16
                  and         s9, ra, a2
                  c.and       a0, a0
                  or          a6, s0, a5
5994:             c.slli      s6, 11
                  srai        a1, s7, 18
                  beq         t2, s4, 6006f
                  c.addi      t1, 1
                  add         t0, t4, ra
                  auipc       s11, 220901
                  nop
                  mulh        t6, s11, t3
                  sub         t6, ra, s9
                  c.or        a0, a0
                  xori        s3, s11, -1178
                  add         a7, s6, t2
6006:             c.or        a0, a0
                  sra         a2, a4, s11
                  addi        t0, s11, 1429
                  xor         gp, s9, s7
                  srli        zero, a3, 5
                  sll         s1, t0, a7
                  c.or        a0, a2
                  auipc       s3, 1015594
                  mul         a3, t5, t6
                  slt         a3, s9, t4
                  sltiu       s3, s2, -1147
                  srl         s2, a4, a1
                  mul         t1, s10, s0
                  bgeu        t4, a1, 6038f
                  divu        zero, s11, s5
                  c.mv        s4, s7
                  srl         s1, a6, t0
                  xori        s6, t3, -731
                  c.nop
                  beq         s8, s7, 6037f
                  blt         sp, tp, 6032f
                  and         s11, s0, a5
                  c.andi      a2, -1
                  c.nop
                  c.or        s1, s1
                  c.or        a0, s0
6032:             c.lui       t0, 18
                  beq         t1, s10, 6050f
                  div         s7, a0, ra
                  slti        gp, s2, -1793
                  blt         a2, s6, 6051f
6037:             bne         s0, sp, 6049f
6038:             srai        zero, s11, 2
                  auipc       s0, 598025
                  auipc       t3, 18295
                  bltu        a4, gp, 6061f
                  srl         s1, s4, zero
                  bne         t3, t3, 6049f
                  c.li        t1, -1
                  c.srli      a2, 7
                  bltu        a4, s8, 6065f
                  ori         zero, a7, 726
                  xor         s6, s4, a3
6049:             bge         s1, a3, 6066f
6050:             c.addi4spn  a2, sp, 544
6051:             xor         s7, a5, s6
                  bne         t3, a0, 6070f
                  c.or        a3, a2
                  sub         s8, s9, a5
                  or          a5, s9, s1
                  xor         a5, gp, gp
                  srli        zero, s5, 18
                  sltiu       a3, s4, -1915
                  srl         s5, t3, t4
                  c.add       a3, t3
6061:             c.or        a2, a0
                  sra         s5, tp, tp
                  c.addi      a6, -1
                  slt         s1, tp, a5
6065:             nop
6066:             c.add       t0, a0
                  mulhsu      a0, sp, a5
                  and         s2, t3, gp
                  c.lui       ra, 4
6070:             lui         s5, 224952
                  beq         a2, t2, 6085f
                  xor         a2, s2, s11
                  sltu        t0, a6, s2
                  mulh        zero, s11, t6
                  srl         t3, a1, s7
                  c.addi      s0, -1
                  c.lui       t3, 23
                  sub         s11, s7, a3
                  c.addi4spn  a0, sp, 944
                  xor         gp, a4, t3
                  bltu        tp, s9, 6090f
                  mulhsu      s9, s5, s11
                  c.or        a0, s1
                  beq         t4, s4, 6088f
6085:             slli        s2, t5, 17
                  srli        s3, t0, 30
                  sltiu       a6, a6, 786
6088:             c.srli      s1, 4
                  addi        t6, s9, 254
6090:             bge         ra, sp, 6103f
                  bne         s11, a4, 6108f
                  xori        t6, s0, -721
                  sub         s2, sp, t1
                  beq         s0, s9, 6114f
                  divu        a3, s11, s10
                  c.addi16sp  sp, -16
                  c.or        a0, a4
                  c.srli      a3, 27
                  srai        s11, sp, 22
                  div         gp, a0, a6
                  srli        sp, ra, 6
                  c.xor       a0, s1
6103:             c.srai      a0, 12
                  blt         t4, s9, 6121f
                  c.andi      a0, -1
                  bne         s6, s7, 6108f
                  blt         s6, s5, 6116f
6108:             c.sub       a2, a2
                  c.nop
                  slti        s6, t2, 209
                  sll         zero, t0, t3
                  div         s8, s9, a1
                  c.sub       a0, s1
6114:             nop
                  c.addi16sp  sp, 304
6116:             xori        zero, t4, -966
                  mul         zero, a3, s1
                  c.nop
                  sll         s9, a0, s0
                  c.add       t0, s1
6121:             rem         t1, t1, a0
                  c.addi16sp  sp, 256
                  c.beqz      a1, 6142f
                  xori        s2, s3, -1347
                  rem         t3, s11, gp
                  xor         s3, gp, a2
                  c.srli      a3, 22
                  divu        t0, ra, s8
                  c.addi4spn  a1, sp, 944
                  c.addi      s2, 24
                  slti        t3, s9, 1720
                  nop
                  c.addi4spn  s0, sp, 784
                  c.addi      ra, 5
                  and         s11, s4, gp
                  srai        t6, s10, 1
                  c.beqz      a0, 6149f
                  c.srli      a0, 20
                  c.mv        t1, a0
                  blt         s4, a2, 6159f
                  lui         gp, 854647
6142:             mul         tp, s8, a1
                  rem         a5, t1, t5
                  andi        s11, s7, 316
                  c.or        a3, a2
                  mulh        a5, s11, s10
                  sltu        s2, s2, s6
                  blt         t6, t1, 6154f
6149:             bgeu        tp, tp, 6167f
                  sll         t0, t5, s4
                  c.addi4spn  a0, sp, 416
                  c.or        a0, a2
                  slli        s5, s7, 16
6154:             blt         t2, a7, 6168f
                  divu        zero, t6, t1
                  mulhu       s6, s2, gp
                  divu        s8, t0, s2
                  c.nop
6159:             srl         a7, a0, t2
                  bne         s3, s11, 6168f
                  srli        s1, gp, 15
                  c.lui       s7, 11
                  srai        t1, a1, 5
                  sra         a0, s8, s6
                  addi        sp, s2, 1446
                  slt         s11, a2, t3
6167:             c.sub       s0, a0
6168:             c.srli      a5, 16
                  xori        s4, s3, 1863
                  sltiu       a6, t6, -1757
                  lui         s8, 252298
                  c.add       a0, a6
                  blt         t0, s5, 6188f
                  bltu        t1, a5, 6187f
                  addi        ra, t0, 1362
                  c.xor       s0, a3
                  bne         t5, s3, 6194f
                  srli        s1, s0, 12
                  srli        a5, a0, 3
                  c.nop
                  c.andi      a1, 20
                  c.sub       a0, a0
                  sll         s6, tp, s7
                  sub         a0, gp, t2
                  c.li        ra, 6
                  xor         t0, t5, a3
6187:             slti        a0, t2, 1573
6188:             srli        a7, a4, 24
                  c.slli      s0, 1
                  c.li        t6, -1
                  xori        s9, s7, -1848
                  c.addi      s5, 29
                  rem         t1, s4, s6
6194:             lui         s0, 310104
                  mul         t0, a6, s5
                  or          a2, s4, s8
                  div         s7, t2, t6
                  c.beqz      s0, 6210f
                  c.or        a0, a1
                  xori        t4, t0, -1002
                  srai        a5, t2, 19
                  or          a4, s3, s8
                  c.lui       s3, 6
                  bgeu        s9, s10, 6216f
                  bltu        a6, sp, 6219f
                  c.srli      a3, 25
                  sub         a2, s9, a3
                  c.addi      t1, 29
                  auipc       s11, 331127
6210:             srai        a3, t5, 19
                  mul         s6, s4, a6
                  slt         a1, t2, s10
                  xor         a3, a0, a6
                  c.beqz      a0, 6231f
                  addi        zero, s0, -1974
6216:             addi        s2, s9, -1085
                  mul         a4, s1, s11
                  c.nop
6219:             sub         a7, a7, a7
                  sltu        sp, t5, s5
                  div         s7, s8, a1
                  xor         s2, zero, t1
                  c.add       a7, a3
                  c.srai      a2, 28
                  c.nop
                  div         s4, sp, t4
                  xor         a1, t6, s9
                  c.slli      ra, 13
                  rem         zero, t3, t6
                  xor         zero, t1, t5
6231:             sra         a0, s1, zero
                  c.and       a0, a2
                  srl         t6, t3, s7
                  slli        zero, s5, 26
                  slt         s1, a7, a3
                  rem         s1, t3, zero
                  sll         a3, s7, a4
                  bne         ra, s3, 6257f
                  c.srli      a2, 1
                  sltiu       a7, s7, -552
                  xori        s6, a3, 35
                  lui         a7, 147052
                  c.or        a3, a1
                  c.andi      a0, -1
                  c.mv        t4, a1
                  srl         zero, t2, t6
                  c.and       a3, s0
                  div         sp, s7, a2
                  addi        zero, s2, -68
                  c.sub       a0, a2
                  c.mv        t1, s4
                  mulh        zero, a0, t0
                  c.beqz      a0, 6273f
                  bgeu        a7, t6, 6260f
                  srai        s7, s0, 15
                  c.add       t3, s3
6257:             c.xor       a0, a1
                  add         a0, s4, s1
                  sub         zero, tp, s3
6260:             blt         s4, t0, 6268f
                  and         t4, t4, t5
                  c.add       a6, ra
                  xori        s11, t4, 484
                  sub         a3, t3, t2
                  c.and       a0, a3
                  sll         gp, a5, s7
                  srl         s8, t0, a2
6268:             mulh        t3, t1, s7
                  divu        zero, s5, ra
                  c.and       a0, a3
                  c.andi      a0, 12
                  div         t1, s2, t0
6273:             c.add       a2, tp
                  mul         s8, t2, a6
                  c.beqz      a0, 6285f
                  blt         a7, a1, 6278f
                  rem         s2, s0, t4
6278:             c.nop
                  nop
                  c.add       s9, t0
                  sub         t1, a4, s8
                  auipc       a7, 485492
                  c.srai      a2, 10
                  c.li        sp, -1
6285:             divu        s8, s11, a6
                  c.sub       a2, a3
                  c.addi4spn  a0, sp, 880
                  c.nop
                  c.mv        s0, s0
                  xori        gp, ra, 65
                  c.srli      a2, 19
                  sll         t6, s10, s6
                  c.beqz      a0, 6301f
                  bne         t4, s9, 6314f
                  sltu        s3, a4, sp
                  mulhsu      a7, s6, s11
                  c.li        ra, -1
                  xori        s0, t1, 2024
                  sra         a5, s10, s11
                  c.srli      a3, 5
6301:             c.andi      a3, -1
                  c.addi4spn  a4, sp, 640
                  mulhsu      s9, s5, s6
                  sll         a6, s6, s9
                  srai        sp, s1, 26
                  sltiu       zero, s4, -132
                  xori        s5, t5, -1443
                  slti        t1, a3, 949
                  c.xor       s1, a1
                  c.lui       ra, 8
                  c.beqz      a0, 6315f
                  c.srli      a3, 13
                  beq         t6, s3, 6327f
6314:             c.beqz      a0, 6334f
6315:             c.mv        s4, t1
                  c.srai      a0, 3
                  mulhu       gp, s5, t5
                  divu        zero, t5, s5
                  c.sub       a2, a3
                  c.srai      s0, 30
                  mul         t4, s1, a5
                  rem         s2, a5, t4
                  mulhu       zero, t2, a1
                  divu        sp, a4, t1
                  c.andi      s1, -1
                  nop
6327:             mul         a1, s0, t6
                  c.andi      a2, 30
                  xori        t4, t0, 1131
                  c.xor       a0, s0
                  xor         t6, a7, s9
                  c.lui       a2, 12
                  auipc       zero, 105787
6334:             c.mv        a1, t6
                  addi        tp, s10, 427
                  c.or        a0, a0
                  blt         s4, t4, 6354f
                  ori         a0, s6, -1124
                  slt         s9, t4, gp
                  c.and       a1, a2
                  xor         a4, a0, t4
                  bge         a2, a6, 6351f
                  srl         a0, s6, t5
                  bltu        ra, s5, 6356f
                  slt         zero, s2, a0
                  sltiu       a2, s11, 1590
                  c.slli      s4, 19
                  add         a3, t2, t0
                  nop
                  c.andi      a0, -1
6351:             add         s6, t4, a1
                  sltu        t1, t3, sp
                  c.addi      s3, -1
6354:             srli        s9, t2, 19
                  bltu        s0, a5, 6372f
6356:             c.add       s9, s5
                  c.sub       a3, a3
                  slti        s4, s2, 1261
                  c.sub       a0, a1
                  andi        s11, s5, 1371
                  c.mv        a3, ra
                  nop
                  c.xor       a0, a0
                  c.or        a2, s1
                  xori        t1, t3, 1521
                  c.addi16sp  sp, 192
                  c.beqz      a3, 6382f
                  divu        t3, s6, s2
                  c.sub       a0, s1
                  c.beqz      a3, 6389f
                  slli        t4, s4, 3
6372:             or          zero, s10, s5
                  c.li        s0, 4
                  c.andi      a2, -1
                  sub         a5, s1, t2
                  c.srai      a3, 19
                  c.or        a0, s0
                  srli        ra, a5, 8
                  c.and       a0, a0
                  rem         a4, t3, a0
                  blt         s8, a3, 6401f
6382:             auipc       s5, 405216
                  xor         tp, t1, t2
                  sll         s6, ra, s10
                  c.addi4spn  a3, sp, 496
                  addi        s4, s6, -335
                  mulhu       a0, s9, t2
                  sra         a2, ra, t3
6389:             xori        s2, s3, 1612
                  c.lui       s1, 9
                  xor         s4, a7, s1
                  and         s9, t1, gp
                  or          t6, t0, s11
                  auipc       t0, 289234
                  c.mv        s9, t4
                  c.add       sp, s8
                  c.or        a2, a3
                  and         zero, s8, s9
                  c.sub       a2, a0
                  c.or        a3, a2
6401:             c.li        s9, -1
                  c.addi      tp, -1
                  and         sp, zero, sp
                  c.srai      a0, 25
                  sltu        gp, zero, tp
                  blt         gp, t4, 6410f
                  beq         s3, a6, 6413f
                  srl         t0, a2, a6
                  srli        zero, s4, 11
6410:             divu        sp, sp, t2
                  ori         s5, a3, -1688
                  div         a0, a7, t0
6413:             bltu        s6, s9, 6421f
                  addi        zero, a5, 1133
                  c.srli      s1, 21
                  srai        t3, s4, 20
                  srli        a6, s2, 17
                  sra         s5, t4, t4
                  sltu        sp, s1, s5
                  rem         t4, t2, a7
6421:             and         s7, s5, ra
                  la x30, test_done
                  jalr x0, x30, 0
test_done:        
                  li gp, 1
                  ecall
write_tohost:     
                  sw gp, tohost, t5

_exit:            
                  j write_tohost

instr_end:        
                  nop

.section .data
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
                  csrrw x26, 0x340, x26
                  add x26, x7, zero
                  1: addi x26, x26, -124
                  sw x1, 4(x26)
                  sw x2, 8(x26)
                  sw x3, 12(x26)
                  sw x4, 16(x26)
                  sw x5, 20(x26)
                  sw x6, 24(x26)
                  sw x7, 28(x26)
                  sw x8, 32(x26)
                  sw x9, 36(x26)
                  sw x10, 40(x26)
                  sw x11, 44(x26)
                  sw x12, 48(x26)
                  sw x13, 52(x26)
                  sw x14, 56(x26)
                  sw x15, 60(x26)
                  sw x16, 64(x26)
                  sw x17, 68(x26)
                  sw x18, 72(x26)
                  sw x19, 76(x26)
                  sw x20, 80(x26)
                  sw x21, 84(x26)
                  sw x22, 88(x26)
                  sw x23, 92(x26)
                  sw x24, 96(x26)
                  sw x25, 100(x26)
                  sw x26, 104(x26)
                  sw x27, 108(x26)
                  sw x28, 112(x26)
                  sw x29, 116(x26)
                  sw x30, 120(x26)
                  sw x31, 124(x26)
                  csrr x27, 0x300 # MSTATUS
                  csrr x27, 0x342 # MCAUSE
                  srli x27, x27, 31
                  bne x27, x0, mmode_intr_handler

mmode_exception_handler:
                  csrr x27, 0x341 # MEPC
                  csrr x27, 0x342 # MCAUSE
                  li x25, 0xb # ECALL_MMODE
                  beq x27, x25, ecall_handler
                  li x25, 0x2 # ILLEGAL_INSTRUCTION
                  beq x27, x25, illegal_instr_handler
                  csrr x25, 0x343 # MTVAL
                  1: la x30, test_done
                  jalr x1, x30, 0

ecall_handler:    
                  la x27, _start
                  sw x0, 0(x27)
                  sw x1, 4(x27)
                  sw x2, 8(x27)
                  sw x3, 12(x27)
                  sw x4, 16(x27)
                  sw x5, 20(x27)
                  sw x6, 24(x27)
                  sw x7, 28(x27)
                  sw x8, 32(x27)
                  sw x9, 36(x27)
                  sw x10, 40(x27)
                  sw x11, 44(x27)
                  sw x12, 48(x27)
                  sw x13, 52(x27)
                  sw x14, 56(x27)
                  sw x15, 60(x27)
                  sw x16, 64(x27)
                  sw x17, 68(x27)
                  sw x18, 72(x27)
                  sw x19, 76(x27)
                  sw x20, 80(x27)
                  sw x21, 84(x27)
                  sw x22, 88(x27)
                  sw x23, 92(x27)
                  sw x24, 96(x27)
                  sw x25, 100(x27)
                  sw x26, 104(x27)
                  sw x27, 108(x27)
                  sw x28, 112(x27)
                  sw x29, 116(x27)
                  sw x30, 120(x27)
                  sw x31, 124(x27)
                  la x30, write_tohost
                  jalr x0, x30, 0

illegal_instr_handler:
                  csrr  x27, 0x341
                  addi  x27, x27, 4
                  csrw  0x341, x27
                  lw x1, 4(x26)
                  lw x2, 8(x26)
                  lw x3, 12(x26)
                  lw x4, 16(x26)
                  lw x5, 20(x26)
                  lw x6, 24(x26)
                  lw x7, 28(x26)
                  lw x8, 32(x26)
                  lw x9, 36(x26)
                  lw x10, 40(x26)
                  lw x11, 44(x26)
                  lw x12, 48(x26)
                  lw x13, 52(x26)
                  lw x14, 56(x26)
                  lw x15, 60(x26)
                  lw x16, 64(x26)
                  lw x17, 68(x26)
                  lw x18, 72(x26)
                  lw x19, 76(x26)
                  lw x20, 80(x26)
                  lw x21, 84(x26)
                  lw x22, 88(x26)
                  lw x23, 92(x26)
                  lw x24, 96(x26)
                  lw x25, 100(x26)
                  lw x26, 104(x26)
                  lw x27, 108(x26)
                  lw x28, 112(x26)
                  lw x29, 116(x26)
                  lw x30, 120(x26)
                  lw x31, 124(x26)
                  addi x26, x26, 124
                  add x7, x26, zero
                  csrrw x26, 0x340, x26
                  mret

pt_fault_handler: 

.align 2
mmode_intr_handler:
                  csrr  x27, 0x300 # MSTATUS;
                  csrr  x27, 0x304 # MIE;
                  csrr  x27, 0x344 # MIP;
                  csrrc x27, 0x344, x27 # MIP;
                  lw x1, 4(x26)
                  lw x2, 8(x26)
                  lw x3, 12(x26)
                  lw x4, 16(x26)
                  lw x5, 20(x26)
                  lw x6, 24(x26)
                  lw x7, 28(x26)
                  lw x8, 32(x26)
                  lw x9, 36(x26)
                  lw x10, 40(x26)
                  lw x11, 44(x26)
                  lw x12, 48(x26)
                  lw x13, 52(x26)
                  lw x14, 56(x26)
                  lw x15, 60(x26)
                  lw x16, 64(x26)
                  lw x17, 68(x26)
                  lw x18, 72(x26)
                  lw x19, 76(x26)
                  lw x20, 80(x26)
                  lw x21, 84(x26)
                  lw x22, 88(x26)
                  lw x23, 92(x26)
                  lw x24, 96(x26)
                  lw x25, 100(x26)
                  lw x26, 104(x26)
                  lw x27, 108(x26)
                  lw x28, 112(x26)
                  lw x29, 116(x26)
                  lw x30, 120(x26)
                  lw x31, 124(x26)
                  addi x26, x26, 124
                  add x7, x26, zero
                  csrrw x26, 0x340, x26
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
