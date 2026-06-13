.include "user_define.h"
.globl _start
.section .text
_start:           
                  .include "user_init.s"
                  csrr x5, 0xf14
                  li x6, 0
                  beq x5, x6, 0f

0: la x17, h0_start
jalr x0, x17, 0
h0_start:
                  li x22, 0x40001104
                  csrw 0x301, x22
kernel_sp:        
                  la x31, kernel_stack_end

trap_vec_init:    
                  la x22, mtvec_handler
                  ori x22, x22, 0
                  csrw 0x305, x22 # MTVEC

mepc_setup:       
                  la x22, init
                  csrw 0x341, x22

init_machine_mode:
                  li x22, 0x1a00
                  csrw 0x300, x22 # MSTATUS
                  li x22, 0x0
                  csrw 0x304, x22 # MIE
                  mret
init:             
                  li x0, 0xfcf63700
                  li x1, 0x8
                  li x2, 0xd163e972
                  li x3, 0xd
                  li x4, 0xf60746cd
                  li x5, 0x37639f
                  li x6, 0xfdb3eae8
                  li x7, 0x0
                  li x8, 0xe0630342
                  li x9, 0x0
                  li x10, 0x0
                  li x11, 0x40d8ef48
                  li x12, 0x9
                  li x13, 0x80000000
                  li x14, 0xeae3926
                  li x15, 0x80000000
                  li x16, 0x80000000
                  li x17, 0xf1edcd5a
                  li x18, 0x3
                  li x19, 0xd52cbce9
                  li x20, 0x0
                  li x21, 0x1f82a40e
                  li x22, 0x1
                  li x23, 0xf403e5e0
                  li x24, 0x80000000
                  li x25, 0xb
                  li x26, 0xc2a0ca5d
                  li x27, 0x80000000
                  li x28, 0x947a63d0
                  li x29, 0x0
                  la x30, user_stack_end
main:             sltu        s2, t4, a7
                  ori         a6, s8, 1529
                  c.nop
                  c.srai      a3, 24
                  c.beqz      a3, 6f
                  sub         a5, s7, s5
6:                srl         s11, s2, a6
                  c.slli      s11, 16
                  auipc       zero, 452149
                  sltu        t2, t3, s4
                  srli        t4, a0, 31
                  bne         s0, a7, 29f
                  divu        s1, tp, s8
                  c.addi16sp  sp, -16
                  c.mv        s2, s11
                  or          t3, s8, s0
                  bge         ra, s6, 27f
                  c.bnez      a3, 26f
                  blt         a5, s9, 25f
                  sub         s0, t0, s1
                  and         s3, sp, s9
                  xori        a0, s8, 1886
                  c.addi16sp  sp, -16
                  sltu        a1, ra, s1
                  lui         s0, 42362
25:               slt         s11, s7, t2
26:               mul         tp, t6, a7
27:               c.xor       a0, a3
                  c.lui       a6, 27
29:               c.andi      a3, 24
                  mulh        zero, t5, s9
                  c.srli      a3, 7
                  sll         s11, s5, a2
                  c.srli      a3, 16
                  divu        zero, sp, s3
                  divu        a1, t6, t0
                  c.mv        tp, t6
                  auipc       s11, 833519
                  c.andi      a3, 17
                  c.li        a0, -1
                  nop
                  c.nop
                  c.and       a3, a3
                  ori         zero, s5, -1469
                  beq         s3, t6, 46f
                  or          s1, t5, a7
46:               c.slli      ra, 5
                  c.lui       ra, 16
                  srl         t0, a4, t3
                  c.sub       a3, a3
                  bge         s9, s5, 67f
                  rem         s11, s3, a6
                  bgeu        a0, t4, 61f
                  xor         a1, a3, t1
                  bltu        s8, t6, 72f
                  srli        s4, a3, 0
                  sll         zero, zero, t4
                  srai        a2, a2, 23
                  sll         a2, a6, s7
                  bne         t6, a2, 76f
                  rem         gp, a7, a0
61:               srli        sp, s6, 27
                  xori        a5, s9, 1311
                  c.beqz      a3, 68f
                  c.addi4spn  a3, sp, 96
                  srli        s0, s8, 16
                  sra         s2, a6, a0
67:               c.add       s5, s5
68:               bltu        s3, ra, 72f
                  mul         sp, s11, ra
                  addi        a6, s1, -1531
                  c.addi16sp  sp, 416
72:               rem         s7, s3, s1
                  mulhsu      s0, t1, a7
                  sll         t4, tp, t1
                  bne         t1, t3, 80f
76:               divu        a4, t5, a6
                  c.slli      s3, 4
                  c.sub       a3, a2
                  c.lui       ra, 1
80:               c.srai      a3, 22
                  c.add       s7, ra
                  c.andi      a3, -1
                  slt         s0, a5, s10
                  c.andi      a3, -1
                  sub         zero, t2, t1
                  mul         s2, s6, s8
                  c.slli      s0, 2
                  mulhu       a6, tp, s5
                  c.srai      a4, 7
                  ori         t0, t1, -1636
                  c.addi16sp  sp, -16
                  c.addi4spn  a3, sp, 352
                  c.mv        s3, a0
                  c.li        t0, 16
                  c.mv        a6, s11
                  sll         zero, t0, t5
                  slli        t4, a2, 20
                  srli        a6, ra, 11
                  mul         zero, t3, t5
                  xor         a0, a2, s4
                  c.add       t3, a0
                  c.xor       a3, a3
                  xor         a4, zero, t5
                  c.addi      a1, -1
                  c.beqz      a3, 108f
                  blt         s1, sp, 122f
                  srli        t0, s11, 4
108:              c.addi16sp  sp, -16
                  c.bnez      a3, 117f
                  or          zero, tp, s3
                  sltu        zero, s11, tp
                  c.addi      a4, -1
                  c.slli      ra, 11
                  srli        a5, zero, 5
                  c.add       t0, s1
                  bne         s3, s3, 130f
117:              srli        s7, a5, 5
                  c.addi      tp, 26
                  and         zero, a3, a4
                  sra         sp, s10, t0
                  beq         t5, s3, 126f
122:              auipc       s7, 546753
                  bne         a4, s3, 124f
124:              add         s11, a4, a2
                  add         t3, s1, s8
126:              lui         a4, 282846
                  auipc       t4, 94035
                  lui         a6, 359488
                  c.or        a3, a3
130:              addi        t2, t2, 872
                  xori        s6, s10, -1801
                  slt         a3, s3, a4
                  auipc       a6, 630357
                  c.lui       s5, 11
                  c.and       a3, a3
                  c.add       a0, s2
                  addi        a3, a6, 681
                  c.add       s4, a7
                  bltu        s1, t5, 154f
                  c.nop
                  sll         a4, t0, a3
                  sltiu       a1, s1, 512
                  div         a4, s5, s0
                  ori         s5, a4, 384
                  sub         s4, t1, a5
                  div         tp, s6, a3
                  c.lui       ra, 21
                  mulhu       zero, s1, ra
                  bge         t6, s2, 156f
                  c.addi4spn  a3, sp, 576
                  c.slli      a6, 1
                  c.mv        s6, a6
                  c.mv        gp, a5
154:              c.slli      t4, 17
                  c.andi      a3, 20
156:              slti        zero, s1, 564
                  sltiu       s7, t2, -1329
                  divu        a1, a2, s1
                  c.lui       ra, 18
                  xor         t1, s9, a7
                  c.srai      a3, 21
                  slli        zero, s9, 1
                  c.beqz      a3, 177f
                  rem         a4, s10, s8
                  xor         s5, t1, sp
                  c.addi4spn  a3, sp, 640
                  mulhsu      s11, a7, t4
                  c.lui       a4, 24
                  auipc       t1, 164794
                  div         t0, s1, s3
                  c.or        a3, s0
                  c.or        a3, a3
                  bne         ra, s4, 186f
                  c.li        t1, -1
                  mul         t0, s4, a6
                  c.beqz      a3, 178f
177:              c.nop
178:              c.mv        a0, t2
                  sll         s3, a6, sp
                  divu        a6, s4, a0
                  addi        a0, s7, 1951
                  c.and       s1, a3
                  c.add       tp, s0
                  addi        a5, t4, 1936
                  srl         zero, a0, tp
186:              c.and       a2, a3
                  sll         s4, a2, tp
                  xori        s3, a1, -1322
                  sub         a2, a1, a0
                  c.and       a3, a3
                  c.add       sp, t2
                  c.srai      a3, 23
                  c.xor       a3, a3
                  c.lui       ra, 20
                  blt         s10, s6, 203f
                  sltiu       s7, s1, 617
                  c.andi      s1, 0
                  mulh        s7, s5, t4
                  lui         t1, 717067
                  add         a0, s5, a1
                  bne         a4, s9, 209f
                  c.slli      s4, 26
203:              blt         t2, sp, 213f
                  sltiu       s5, t3, -800
                  c.lui       t0, 16
                  ori         s5, t3, -575
                  c.mv        tp, s8
                  slt         t1, t1, a6
209:              blt         t2, s8, 221f
                  bge         s11, s2, 218f
                  mulhu       s2, a0, a6
                  sra         a5, a7, s4
213:              c.addi4spn  a0, sp, 576
                  c.nop
                  bgeu        s1, t2, 224f
                  slli        s0, a0, 23
                  c.addi      t3, -1
218:              slti        t0, a6, -706
                  c.or        a3, s1
                  c.and       a2, a3
221:              mul         t0, t1, a5
                  sub         s9, a6, s10
                  mulh        s9, a0, a0
224:              srli        a1, t0, 22
                  auipc       sp, 886755
                  andi        t0, s3, -291
                  xori        a4, tp, -33
                  sra         tp, zero, s0
                  c.slli      t3, 13
                  c.add       ra, t3
                  xori        s3, s11, -1962
                  c.li        t4, 28
                  nop
                  sra         t3, a2, sp
                  c.and       a2, a3
                  div         s4, s4, a2
                  divu        t4, t1, s7
                  sub         gp, s9, t2
                  sll         a3, gp, s4
                  mulh        s10, a3, a5
                  c.sub       a3, a2
                  bge         tp, s3, 244f
                  or          s8, s7, s3
244:              sltu        s2, t1, s10
                  sltu        t4, t4, s0
                  c.srli      a3, 31
                  or          t2, s4, s10
                  c.bnez      s0, 266f
                  bge         s9, zero, 260f
                  sltu        a1, t0, gp
                  bge         t4, t5, 266f
                  c.xor       a3, a3
                  c.mv        t0, a6
                  c.add       a5, s7
                  xori        a2, s2, -952
                  sra         zero, t6, t0
                  mulh        t4, s6, t0
                  c.add       a4, gp
                  c.addi16sp  sp, 400
260:              sltiu       s0, a1, -27
                  add         a2, s7, ra
                  blt         a0, tp, 274f
                  c.slli      a5, 31
                  c.addi16sp  sp, 160
                  blt         ra, t6, 273f
266:              xor         s6, s10, s2
                  c.or        a3, a3
                  c.lui       ra, 26
                  rem         a6, t4, t5
                  andi        s10, t1, -462
                  bge         s4, t0, 279f
                  srl         t3, a1, sp
273:              c.addi4spn  a3, sp, 128
274:              c.add       s10, s4
                  c.addi4spn  a5, sp, 896
                  srai        ra, t1, 15
                  sltiu       zero, t3, 148
                  c.add       t1, t1
279:              mul         a0, s7, t3
                  sub         a6, a5, a7
                  slti        zero, zero, 1653
                  bge         s8, s7, 287f
                  srai        sp, t3, 5
                  c.andi      a3, -1
                  c.slli      s11, 3
                  c.mv        ra, a4
287:              sra         gp, t4, a1
                  sltiu       s9, t3, 491
                  beq         ra, s9, 298f
                  and         s0, ra, s2
                  sra         s11, ra, a2
                  c.andi      s0, -1
                  c.slli      ra, 9
                  mulh        s10, s8, zero
                  sra         s2, s7, t0
                  sra         t1, s11, s5
                  mulhu       a2, s10, s11
298:              slt         a0, s4, t1
                  bne         t2, a7, 307f
                  c.slli      t2, 28
                  bne         a1, t0, 314f
                  mulh        s5, s8, a5
                  srli        t1, t5, 12
                  auipc       tp, 513762
                  andi        t2, s9, 1354
                  srl         t4, s9, s5
307:              andi        s4, a4, 1702
                  c.li        a6, -1
                  nop
                  bltu        t6, sp, 314f
                  add         s0, zero, a7
                  c.slli      sp, 9
                  lui         tp, 669787
314:              sll         s4, a3, a1
                  slt         s3, a7, s10
                  auipc       t3, 492502
                  c.bnez      a3, 319f
                  sltiu       t2, s8, 428
319:              auipc       a6, 704460
                  c.addi16sp  sp, -16
                  c.and       a3, a3
                  sub         s6, s2, a5
                  c.sub       a3, a1
                  c.addi16sp  sp, -16
                  andi        a2, s5, -1328
                  c.srli      s1, 10
                  c.sub       a3, a5
                  c.slli      s7, 13
                  lui         ra, 162576
                  c.nop
                  sltiu       t0, t4, -1270
                  bgeu        t1, a6, 341f
                  beq         s11, tp, 334f
334:              c.add       ra, t4
                  andi        tp, s10, 1567
                  srai        s11, a1, 16
                  bne         a1, zero, 345f
                  rem         a1, a7, t3
                  c.li        s9, -1
                  sll         s7, t5, s5
341:              mulhu       gp, s4, a2
                  sll         s10, s0, zero
                  c.addi      sp, -1
                  c.beqz      a3, 349f
345:              slti        a0, zero, -836
                  c.addi4spn  a3, sp, 640
                  c.and       a4, a3
                  c.xor       a3, s0
349:              c.addi4spn  a3, sp, 848
                  addi        s5, t4, 876
                  lui         s1, 726963
                  mulhu       tp, s2, t2
                  c.beqz      a3, 367f
                  c.addi4spn  a3, sp, 384
                  c.and       a3, a3
                  sltu        s0, a4, s6
                  or          ra, s7, zero
                  bge         s2, s6, 361f
                  c.addi      a2, -1
                  srl         s10, tp, ra
361:              srl         gp, s9, zero
                  rem         zero, a0, tp
                  slti        s7, t0, 1547
                  or          tp, s4, a5
                  xori        s2, a6, -33
                  mul         a1, s3, t0
367:              sltiu       zero, t3, -146
                  slt         s3, s2, zero
                  srai        s5, a4, 24
                  xor         s7, a3, t4
                  c.add       s11, a2
                  bge         s11, t5, 388f
                  c.srli      a3, 2
                  and         zero, s0, s3
                  c.or        a5, a3
                  xor         s1, a6, tp
                  andi        s6, t0, 969
                  c.beqz      a3, 380f
                  nop
380:              srai        zero, t2, 31
                  sub         s4, gp, a3
                  srai        s4, zero, 10
                  lui         gp, 320436
                  xori        gp, s1, -1842
                  or          a5, s7, t3
                  xori        gp, ra, 978
                  xori        zero, a0, 94
388:              auipc       t2, 985584
                  xori        a5, a6, -175
                  c.nop
                  c.beqz      a3, 405f
                  srl         a3, a7, s11
                  andi        s2, s8, 1667
                  auipc       t2, 149010
                  c.beqz      a5, 400f
                  blt         gp, t3, 403f
                  c.srai      a0, 26
                  blt         s4, t1, 415f
                  sltu        a1, s3, s0
400:              c.srai      a3, 15
                  mulhu       zero, s0, a5
                  c.li        s6, 27
403:              c.bnez      a3, 421f
                  divu        t4, gp, s11
405:              slti        zero, s11, 1759
                  mulhsu      a4, t3, a7
                  slti        s5, tp, 1091
                  c.or        a3, a3
                  sltu        t4, a4, s6
                  srl         a6, tp, tp
                  andi        s5, s2, 634
                  sra         zero, s5, s5
                  sll         a6, s2, t3
                  mulhu       a0, a0, s9
415:              sra         s8, s11, s4
                  c.bnez      a3, 426f
                  ori         a6, ra, -1653
                  sltiu       s6, a5, -1321
                  sltu        s1, a4, s6
                  or          s2, t1, s4
421:              add         s3, t6, s5
                  c.addi16sp  sp, -16
                  c.addi      s4, 6
                  c.addi4spn  a3, sp, 896
                  slt         t4, s4, a6
426:              add         tp, s11, ra
                  mulh        t3, s7, s4
                  xori        zero, s6, 832
                  c.addi16sp  sp, 16
                  add         s10, s10, a2
                  ori         t3, s10, 811
                  blt         s10, s0, 449f
                  auipc       t3, 996516
                  mul         zero, t6, t1
                  slli        s3, s5, 4
                  and         a3, t0, a3
                  slt         t2, t0, ra
                  srai        a5, t4, 15
                  rem         t4, t1, s9
                  bltu        s1, a2, 449f
                  bltu        s0, tp, 448f
                  rem         sp, s6, a5
                  div         s7, t1, a1
                  div         a5, a6, a0
                  srai        a3, t5, 17
                  slt         s9, s2, t3
                  beq         a5, a6, 455f
448:              bgeu        s1, a5, 449f
449:              c.addi4spn  a3, sp, 816
                  sra         zero, t1, s5
                  mulhsu      ra, a4, ra
                  and         a0, t0, a6
                  c.bnez      a3, 455f
                  rem         gp, s1, a2
455:              c.or        a3, a3
                  blt         a7, a4, 472f
                  c.bnez      a3, 461f
                  sll         zero, s9, s6
                  c.or        a3, a3
                  div         a1, s3, s10
461:              divu        t0, tp, t0
                  div         s2, a5, ra
                  mul         t2, a2, s10
                  c.and       a3, a3
                  blt         a1, s11, 473f
                  mulhu       ra, s7, a4
                  mulhu       a2, s6, t6
                  or          s0, s11, tp
                  c.add       tp, s4
                  mulhu       a0, s4, t1
                  c.xor       a3, a3
472:              c.slli      s0, 29
473:              nop
                  bgeu        s8, a0, 491f
                  lui         s11, 186553
                  bne         s8, t1, 481f
                  bltu        a3, s0, 486f
                  mulhsu      a5, s9, a7
                  c.nop
                  lui         s5, 887076
481:              div         a6, a1, s10
                  bne         a0, t6, 497f
                  c.addi16sp  sp, 416
                  c.srli      a2, 8
                  mul         a0, a3, a3
486:              c.add       t0, t2
                  c.sub       a5, a3
                  c.beqz      a3, 490f
                  c.andi      a3, -1
490:              c.slli      t1, 24
491:              c.nop
                  c.xor       a3, a3
                  add         s3, s5, t6
                  sub         a0, t2, a4
                  c.nop
                  c.or        a1, a3
497:              addi        s9, a4, -591
                  mul         a0, ra, s0
                  mul         s8, s2, a0
                  c.addi      tp, -1
                  srl         a4, s0, t1
                  bne         s3, s8, 511f
                  beq         s4, t3, 512f
                  ori         s11, s8, -443
                  c.addi16sp  sp, -16
                  add         zero, a7, s5
                  div         zero, a2, a3
                  xori        s1, s6, 1291
                  beq         a1, s3, 527f
                  divu        zero, s9, a5
511:              andi        zero, a0, -271
512:              srai        t2, gp, 4
                  c.lui       gp, 17
                  bltu        s4, s2, 521f
                  nop
                  c.slli      t4, 18
                  xor         t3, ra, s5
                  rem         s2, a3, s10
                  or          s3, t5, a0
                  c.bnez      a3, 523f
521:              sub         zero, s9, s0
                  or          zero, t5, s6
523:              c.sub       a3, a3
                  nop
                  addi        s9, t0, -1192
                  c.li        s8, 25
527:              and         a2, a6, s2
                  srai        ra, gp, 0
                  sltiu       s8, a7, 590
                  c.lui       t0, 23
                  beq         s0, s10, 541f
                  xori        a2, gp, -1936
                  divu        a6, a6, s4
                  sub         s3, a3, s8
                  mulhsu      zero, s3, t0
                  xori        s2, a0, -1389
                  c.or        a1, a3
                  c.and       a3, a3
                  c.sub       a3, a3
                  sltiu       a1, s8, 748
541:              divu        ra, a3, a2
                  c.li        tp, 3
                  beq         ra, ra, 554f
                  bgeu        gp, gp, 549f
                  or          zero, tp, zero
                  slli        zero, s4, 15
                  c.nop
                  beq         s11, s8, 553f
549:              slti        zero, s0, -1142
                  c.beqz      a3, 568f
                  add         ra, s10, s9
                  xori        a1, t6, -975
553:              c.andi      a3, -1
554:              c.sub       a4, a3
                  c.sub       a3, a4
                  c.nop
                  and         t3, s7, a2
                  slti        a0, t0, 1691
                  addi        a5, s5, 1836
                  bge         t1, a5, 567f
                  c.slli      s3, 1
                  c.srli      a3, 14
                  mulh        a0, t2, s9
                  addi        s7, a7, -1815
                  c.xor       a3, a3
                  sll         a6, a1, tp
567:              c.li        a1, 10
568:              c.and       a3, a3
                  add         a5, t6, a7
                  c.addi4spn  a3, sp, 384
                  srai        ra, tp, 19
                  slt         a3, s8, t6
                  and         s11, a1, s5
                  c.addi16sp  sp, -16
                  c.li        sp, 27
                  bge         a4, s8, 584f
                  addi        zero, s8, 1823
                  sll         a4, s7, a0
                  div         zero, t2, s8
                  ori         s11, a7, 200
                  andi        t2, s9, -942
                  c.or        a3, a3
                  ori         s2, s5, 1412
584:              srai        s11, a4, 8
                  slti        a1, zero, -1738
                  c.srli      a3, 23
                  ori         a0, sp, -704
                  srl         a3, a4, s4
                  sra         ra, a1, s1
                  blt         s1, s3, 598f
                  bltu        t2, s3, 604f
                  addi        a6, s0, 1980
                  and         a5, t4, a0
                  c.or        a5, a3
                  c.addi16sp  sp, -16
                  sra         a2, s2, a0
                  c.slli      sp, 13
598:              mulhsu      zero, t4, a2
                  c.beqz      a1, 613f
                  slt         zero, zero, s11
                  c.slli      tp, 21
                  auipc       zero, 784169
                  mulh        s8, sp, s2
604:              andi        a1, t0, 1867
                  c.srai      a1, 20
                  srli        sp, tp, 20
                  srl         t1, s0, t1
                  nop
                  c.addi      s5, 24
                  c.add       t1, a7
                  lui         s11, 419447
                  xor         a0, t4, s9
613:              ori         a1, gp, -1801
                  srli        s6, tp, 12
                  slt         s6, t3, s1
                  div         s11, s6, a0
                  c.lui       s10, 7
                  xor         s11, ra, s10
                  bne         s1, t6, 633f
                  c.or        a3, a3
                  beq         a3, s10, 638f
                  slti        s4, a2, -1773
                  slti        zero, s6, -253
                  c.mv        a1, s4
                  slli        zero, t4, 10
                  and         tp, s0, t1
                  bne         tp, zero, 639f
                  nop
                  c.nop
                  bne         s11, s3, 632f
                  or          ra, s6, s11
632:              divu        s6, t6, a5
633:              beq         s4, t0, 638f
                  div         s9, s7, s6
                  c.addi16sp  sp, -16
                  c.slli      s0, 22
                  c.andi      a3, 3
638:              c.addi4spn  a3, sp, 320
639:              ori         tp, a4, -1173
                  auipc       t2, 758778
                  divu        a0, a2, s5
                  sub         s9, s10, s11
                  c.nop
                  ori         s11, t1, 1227
                  divu        gp, a4, s4
                  add         s2, s7, s3
                  sll         a0, sp, s4
                  lui         sp, 817891
                  rem         s9, gp, s3
                  c.addi      a4, 20
                  rem         ra, t0, a3
                  slt         a0, a6, a3
                  divu        sp, a3, s8
                  c.beqz      a3, 658f
                  mulhu       t1, s10, s11
                  c.or        a3, a3
                  c.add       t1, s5
658:              srli        s8, s8, 16
                  xori        sp, ra, 82
                  c.xor       a3, a1
                  sub         s4, s1, a3
                  c.lui       a0, 23
                  addi        a1, a1, 1483
                  c.beqz      a3, 682f
                  c.and       a3, s1
                  rem         a3, tp, s0
                  andi        zero, t0, 1173
                  slti        a4, a4, 1593
                  beq         a3, s5, 680f
                  c.and       a3, a3
                  or          s1, a3, t4
                  rem         sp, a2, s4
                  mulhsu      s5, a3, t6
                  divu        s1, t1, s1
                  slt         s8, a6, t1
                  sltiu       s7, t4, 1435
                  c.lui       a1, 26
                  beq         a6, t1, 695f
                  beq         s8, a6, 694f
680:              mulhu       s1, s2, s4
                  c.lui       s1, 8
682:              c.bnez      a3, 684f
                  bne         a4, a4, 701f
684:              sltiu       t3, a6, 1095
                  c.srai      a1, 6
                  c.mv        a5, ra
                  blt         s0, t6, 695f
                  andi        tp, t1, -581
                  slt         sp, t2, s6
                  c.or        a4, s1
                  div         a6, t3, s6
                  divu        a6, a7, tp
                  c.add       ra, t4
694:              xor         t0, s6, s9
695:              sltiu       zero, s5, -520
                  sltu        t1, s0, s9
                  blt         t5, s10, 710f
                  div         a2, s0, t3
                  sub         s1, sp, a3
                  c.addi16sp  sp, 480
701:              srai        zero, a6, 6
                  c.mv        s10, s11
                  c.addi      t1, 6
                  lui         t2, 467491
                  c.srli      a3, 10
                  sra         t4, tp, s1
                  mulhu       s7, s7, a2
                  divu        t4, a4, t2
                  sra         a3, a5, t0
710:              c.or        a3, a0
                  srai        s11, s11, 21
                  sltu        sp, tp, t0
                  beq         a5, s3, 721f
                  beq         t1, t0, 719f
                  c.nop
                  mulhsu      a2, a3, t5
                  beq         s10, t4, 734f
                  c.bnez      a3, 719f
719:              lui         a3, 542242
                  c.add       s5, t1
721:              mulh        s3, s1, t1
                  c.srai      a3, 25
                  c.or        a3, a3
                  c.srli      a3, 8
                  xori        a0, a2, -1773
                  c.srli      a5, 31
                  mulhsu      t4, t5, s1
                  c.bnez      a3, 735f
                  add         s10, a7, t0
                  c.add       ra, s7
                  sltu        s7, t2, s1
                  sll         sp, sp, s0
                  srai        t2, ra, 29
734:              c.andi      s0, 7
735:              slt         gp, ra, s9
                  slli        zero, a3, 11
                  c.or        a3, a5
                  c.beqz      a3, 740f
                  c.nop
740:              xori        sp, s5, -55
                  and         gp, tp, a2
                  rem         t1, s3, a1
                  nop
                  or          a2, zero, a3
                  c.nop
                  c.mv        s2, a4
                  bgeu        s9, tp, 755f
                  add         a2, a4, t5
                  xori        s2, s10, 659
                  mulh        a4, t5, a6
                  c.addi      gp, -1
                  bne         ra, s11, 759f
                  srai        t3, s6, 29
                  nop
755:              auipc       a2, 954285
                  c.beqz      a3, 768f
                  c.and       a3, a3
                  c.slli      s10, 25
759:              c.nop
                  mulhsu      t4, s6, a2
                  div         sp, a4, s1
                  c.addi16sp  sp, 400
                  slt         t3, t3, t2
                  c.bnez      a3, 780f
                  slli        t0, s10, 17
                  lui         s0, 811345
                  mulhsu      a1, t6, a5
768:              blt         a0, a5, 777f
                  xori        s5, a0, -1614
                  slti        s8, s5, -1258
                  xor         zero, s11, s4
                  addi        t2, tp, -163
                  c.and       a3, a3
                  auipc       a1, 396039
                  c.beqz      a1, 784f
                  c.slli      a2, 28
777:              blt         s8, gp, 787f
                  slti        s3, s7, -1496
                  bgeu        t3, s1, 793f
780:              rem         a0, s6, s9
                  c.li        t3, -1
                  bne         s0, s10, 787f
                  divu        s6, a2, gp
784:              srl         t4, s4, a7
                  sltu        a3, sp, gp
                  c.bnez      a3, 794f
787:              or          a0, s9, s5
                  slti        t2, a6, -1076
                  c.lui       s11, 7
                  xori        s8, t0, -1040
                  bgeu        t1, s6, 800f
                  blt         t1, s3, 806f
793:              c.li        s7, 31
794:              rem         a6, t0, s1
                  c.beqz      a3, 798f
                  xor         a2, a3, a7
                  c.bnez      a3, 799f
798:              and         s2, s4, a2
799:              slti        a6, s9, 1671
800:              mulhsu      zero, s11, s7
                  addi        s11, sp, 1409
                  xori        s10, t6, -463
                  bgeu        s9, s10, 811f
                  blt         sp, s3, 813f
                  c.addi16sp  sp, -16
806:              c.lui       s5, 6
                  and         s3, t5, gp
                  srli        a0, a2, 23
                  mul         s6, a5, tp
                  add         zero, a5, sp
811:              mulh        a4, t1, t4
                  bltu        s10, ra, 814f
813:              c.addi4spn  a1, sp, 128
814:              c.andi      a3, -1
                  slt         s8, s10, s5
                  add         s11, t0, a3
                  ori         zero, a4, 627
                  mulh        gp, s6, a2
                  c.slli      s11, 13
                  slli        zero, t1, 31
                  c.addi      tp, -1
                  mulh        a4, s1, a7
                  sltu        s2, a1, a5
                  c.xor       a3, a3
                  lui         s8, 991714
                  mul         ra, a2, s9
                  and         zero, a3, s5
                  c.srli      a3, 16
                  slt         s0, s10, s3
                  mulh        a3, t6, t0
                  rem         s0, t6, a1
                  c.andi      a3, -1
                  c.addi4spn  a3, sp, 80
                  bgeu        s1, s10, 843f
                  bgeu        s8, a5, 852f
                  xor         s4, a0, s0
                  bne         t3, s0, 855f
                  bgeu        a7, s4, 853f
                  c.srai      a3, 16
                  mulhsu      a6, s6, s4
                  xori        gp, s2, 1634
                  c.li        s7, -1
843:              sll         s5, s8, a4
                  divu        a5, t1, s4
                  addi        s10, s10, -274
                  c.add       s10, t1
                  mulh        ra, a1, ra
                  slti        zero, zero, 1535
                  mulhsu      a1, a4, a6
                  andi        s0, gp, -483
                  mulh        a2, a6, gp
852:              sltiu       a0, s9, 98
853:              div         a6, s10, t6
                  sra         t0, a4, a6
855:              auipc       t0, 9385
                  slt         a6, s2, a0
                  add         s6, sp, s0
                  c.addi16sp  sp, 128
                  sll         s2, s0, s11
                  c.beqz      a3, 876f
                  c.addi      a2, 28
                  bltu        a3, a6, 879f
                  beq         t5, zero, 881f
                  or          t3, ra, t1
                  auipc       s10, 78818
                  slti        t0, zero, -1200
                  c.xor       a3, a3
                  c.addi16sp  sp, 112
                  mul         a3, s0, gp
                  slt         gp, t2, s1
                  c.beqz      a3, 881f
                  slli        zero, tp, 8
                  addi        s5, s2, 37
                  bne         s3, s2, 876f
                  nop
876:              blt         s11, s4, 884f
                  sltu        s2, t0, a0
                  lui         t1, 638023
879:              c.mv        a2, t5
                  add         s2, t1, s10
881:              sltiu       a1, ra, -1295
                  bne         a6, s6, 889f
                  beq         gp, s2, 885f
884:              mulhu       a1, s0, s3
885:              c.bnez      a3, 886f
886:              mulhsu      s6, a1, s8
                  bltu        a3, a3, 898f
                  beq         a7, s5, 892f
889:              mulhsu      s0, t6, s4
                  mulhu       t2, s7, a2
                  add         a0, a6, s11
892:              mulhu       sp, t5, s7
                  c.xor       a3, a3
                  c.srai      a3, 6
                  sltiu       s2, s7, 1151
                  c.lui       s5, 10
                  c.add       ra, ra
898:              mulhu       gp, t3, t3
                  srli        s1, t5, 28
                  c.or        a3, a3
                  or          s8, ra, t4
                  mulhu       zero, s4, ra
                  c.lui       a6, 23
                  xor         s1, t3, s7
                  bne         s0, a5, 913f
                  bne         s8, a3, 909f
                  mul         s3, t2, t5
                  c.or        a3, s1
909:              slt         t3, s1, t1
                  xor         s1, s2, sp
                  mulhsu      a1, gp, s9
                  c.lui       t2, 12
913:              or          zero, s6, a4
                  slli        s0, a1, 18
                  sltiu       zero, s11, -1080
                  auipc       s4, 863707
                  blt         a2, s1, 929f
                  auipc       s8, 381170
                  ori         s9, a5, 1837
                  c.slli      s8, 20
                  slti        a4, tp, 1594
                  addi        s8, s7, -409
                  sra         s10, a1, a5
                  divu        s7, a1, gp
                  srl         t1, a4, s9
                  c.sub       a3, a3
                  c.slli      t1, 16
                  srai        s8, s7, 20
929:              c.sub       s1, a3
                  sltiu       sp, sp, -67
                  mul         t0, s2, t1
                  blt         sp, a6, 939f
                  c.add       s1, s5
                  c.beqz      a5, 939f
                  sll         s4, t6, zero
                  mulh        s8, t3, t1
                  c.nop
                  mul         a1, sp, a2
939:              c.addi      s7, 11
                  c.andi      a3, -1
                  sltu        s3, t6, s4
                  rem         ra, sp, s4
                  c.xor       a3, a2
                  sltu        zero, sp, tp
                  xor         zero, a7, t4
                  c.slli      t2, 11
                  rem         t1, a3, t5
                  or          t1, a6, ra
                  bgeu        s8, t3, 954f
                  sltu        s3, a5, s2
                  xori        t1, s2, -619
                  c.addi4spn  a3, sp, 640
                  c.beqz      a3, 962f
954:              sll         a3, sp, a3
                  divu        t1, s10, s11
                  ori         a3, s9, 747
                  or          zero, s3, t5
                  c.lui       ra, 24
                  andi        a0, gp, -324
                  c.or        a0, a3
                  bge         a3, s9, 975f
962:              mul         s3, s7, s10
                  bgeu        t3, a5, 971f
                  and         s1, a6, t5
                  c.mv        t0, t5
                  c.andi      a3, 5
                  c.slli      s9, 9
                  c.li        sp, 5
                  c.or        a3, a3
                  srli        sp, s9, 23
971:              c.sub       a3, a3
                  c.or        a3, a0
                  c.slli      sp, 1
                  c.and       a3, a3
975:              mul         a4, s8, a6
                  c.xor       a3, a3
                  bltu        t6, sp, 991f
                  c.nop
                  c.nop
                  mulhu       s10, s4, gp
                  add         a4, gp, ra
                  c.srli      a3, 11
                  c.srli      a3, 9
                  sll         t3, a3, s0
                  sll         gp, s3, t0
                  slli        s2, s2, 29
                  c.xor       a3, s0
                  c.andi      a3, 13
                  c.bnez      a3, 994f
                  c.sub       a3, a3
991:              c.addi16sp  sp, 288
                  bgeu        a3, t6, 1005f
                  and         s9, s0, s8
994:              c.bnez      a3, 1008f
                  bltu        a2, t1, 1010f
                  addi        s9, a3, 399
                  c.nop
                  divu        s10, tp, t2
                  mulhu       s1, a7, t5
                  sll         tp, s0, t1
                  and         s6, s7, s9
                  auipc       t0, 698564
                  slti        gp, tp, -958
                  beq         zero, s7, 1006f
1005:             bge         t2, ra, 1015f
1006:             c.addi16sp  sp, -16
                  xori        a0, a0, 1369
1008:             xori        s7, tp, 266
                  c.addi      ra, 24
1010:             slti        s7, s10, -1708
                  xor         a1, t0, t0
                  xori        sp, a3, 195
                  slti        s3, s7, 272
                  slti        s4, tp, -806
1015:             sra         a4, a6, t3
                  c.and       a3, a4
                  bltu        sp, t1, 1022f
                  ori         a3, a3, -863
                  nop
                  sra         s2, gp, s8
                  slti        t2, a2, 966
1022:             c.lui       s4, 27
                  c.slli      s2, 26
                  sub         ra, a4, s9
                  c.beqz      a3, 1032f
                  beq         tp, s5, 1028f
                  c.lui       s8, 10
1028:             c.mv        t4, t4
                  ori         ra, sp, -1684
                  addi        s4, t3, -545
                  mulh        t1, s8, t3
1032:             bgeu        s2, s8, 1045f
                  c.xor       a3, a3
                  mul         a0, gp, s3
                  sll         a6, s9, s1
                  divu        s9, ra, t0
                  bltu        s1, a0, 1054f
                  bgeu        zero, t3, 1041f
                  c.add       s10, s8
                  c.slli      a1, 6
1041:             mulhsu      ra, t4, a6
                  sra         zero, t6, s5
                  auipc       s6, 898902
                  c.addi      s3, 27
1045:             mulh        s5, t5, a0
                  c.sub       a3, a3
                  add         a0, t5, a1
                  c.mv        s3, a4
                  c.slli      ra, 2
                  mulh        a2, s3, a1
                  c.and       a3, a3
                  c.addi16sp  sp, 112
                  divu        s0, s3, a5
1054:             c.srai      a3, 30
                  auipc       s0, 1008431
                  sub         s0, a3, t1
                  slli        gp, s8, 1
                  sltiu       s1, t2, -1645
                  c.xor       a3, a0
                  sll         zero, sp, sp
                  mul         t2, a4, a4
                  mulhsu      s8, t5, s4
                  c.bnez      s1, 1072f
                  andi        sp, a6, -35
                  c.add       a0, ra
                  bge         s8, sp, 1080f
                  c.nop
                  c.andi      a3, -1
                  c.srai      a3, 8
                  sub         s6, zero, t2
                  addi        zero, s5, 1105
1072:             divu        a6, t1, s4
                  c.li        s9, -1
                  mulhu       a5, s11, s1
                  srai        tp, a7, 26
                  or          t4, t0, t3
                  c.beqz      a3, 1095f
                  mulh        a0, s7, t0
                  c.bnez      a3, 1084f
1080:             c.nop
                  nop
                  ori         s4, s0, -1350
                  auipc       zero, 826335
1084:             c.or        a3, a3
                  c.addi16sp  sp, -16
                  c.bnez      s0, 1094f
                  mul         t3, sp, a1
                  c.mv        gp, s2
                  slti        a1, s3, -844
                  c.and       a3, a3
                  c.lui       t2, 28
                  mulhsu      s11, ra, zero
                  sll         s3, gp, s1
1094:             c.bnez      a3, 1111f
1095:             div         a5, t0, a5
                  c.add       s5, t3
                  sll         s3, s9, t3
                  sltu        s7, t5, t2
                  sltiu       ra, t5, 736
                  srai        s2, s9, 9
                  sll         s1, ra, a3
                  c.srli      a3, 2
                  auipc       a1, 975803
                  sll         s11, a5, s5
                  lui         s0, 28032
                  c.addi      a1, 21
                  add         zero, s9, a2
                  c.mv        a3, gp
                  srli        a5, s10, 2
                  srl         gp, t1, s8
1111:             c.mv        gp, s7
                  bne         a5, s8, 1123f
                  slli        zero, t5, 19
                  c.add       gp, s6
                  auipc       zero, 162203
                  c.addi16sp  sp, -16
                  blt         a1, s6, 1129f
                  sra         a5, gp, t3
                  c.add       tp, gp
                  xori        s0, t2, 177
                  c.andi      a2, 14
                  bltu        t1, s8, 1130f
1123:             c.slli      s9, 31
                  c.srli      s0, 22
                  div         zero, s8, t2
                  c.mv        s5, a5
                  c.addi      a2, 18
                  c.and       a3, a3
1129:             sra         sp, s4, s5
1130:             c.sub       a3, a3
                  c.or        a3, a3
                  bge         s0, s1, 1141f
                  div         t4, s11, zero
                  xori        a0, s4, -892
                  sltu        s11, a2, sp
                  c.addi16sp  sp, -16
                  c.mv        s7, s1
                  beq         t1, s3, 1154f
                  bne         s10, s8, 1143f
                  sltiu       ra, tp, -847
1141:             c.beqz      a3, 1149f
                  divu        s6, s3, s4
1143:             addi        t2, s3, -1385
                  c.beqz      a3, 1146f
                  nop
1146:             c.andi      a3, -1
                  sra         a1, t5, sp
                  and         sp, t0, t4
1149:             slti        tp, s0, 435
                  c.or        a3, a3
                  nop
                  bgeu        zero, s10, 1160f
                  slti        a0, s3, -1286
1154:             sltiu       gp, gp, 942
                  auipc       s0, 536251
                  c.addi4spn  s0, sp, 576
                  slti        s2, t5, -916
                  bltu        a3, a0, 1176f
                  c.lui       s9, 6
1160:             add         a0, s11, a2
                  beq         a3, s0, 1170f
                  sll         t2, t0, a2
                  sub         s9, t5, ra
                  c.slli      gp, 13
                  xori        sp, s8, -1773
                  c.andi      a4, 10
                  bne         a2, s6, 1172f
                  addi        t1, a5, 1180
                  slli        tp, t5, 22
1170:             c.bnez      a3, 1171f
1171:             c.beqz      a5, 1178f
1172:             c.beqz      a3, 1180f
                  c.beqz      a0, 1191f
                  c.srai      a1, 17
                  c.xor       a0, a3
1176:             bne         s2, a6, 1185f
                  add         zero, s8, a7
1178:             nop
                  mul         zero, s11, s0
1180:             c.addi      ra, 28
                  srl         s9, t2, a0
                  c.beqz      a3, 1186f
                  c.addi4spn  a3, sp, 832
                  or          s10, tp, a6
1185:             c.li        ra, 19
1186:             lui         s4, 211001
                  slli        zero, sp, 4
                  auipc       s9, 446631
                  bgeu        t1, t1, 1191f
                  ori         s10, sp, 29
1191:             bgeu        t5, t5, 1198f
                  lui         a4, 511277
                  bge         t4, t1, 1207f
                  sltu        a3, zero, s1
                  and         zero, gp, t1
                  mulhu       t1, s6, a6
                  mulh        s1, s9, s7
1198:             xori        a5, a0, 1202
                  sub         a1, s2, t2
                  or          zero, t6, s10
                  srl         a1, t1, t0
                  c.beqz      a1, 1207f
                  c.and       a3, a2
                  c.bnez      s1, 1213f
                  c.add       gp, a2
                  slli        s4, s0, 20
1207:             mulh        a3, s5, s6
                  addi        s2, s7, 344
                  auipc       t3, 217179
                  nop
                  slti        tp, s1, 1027
                  c.srai      a3, 4
1213:             c.mv        s11, s6
                  or          a5, s3, t4
                  c.nop
                  c.andi      a3, -1
                  mulhsu      gp, s10, t5
                  c.xor       a3, a3
                  c.xor       a3, a3
                  bge         a2, s10, 1235f
                  auipc       zero, 846957
                  srl         a2, s3, tp
                  sub         sp, a5, s11
                  c.addi4spn  a5, sp, 608
                  addi        s8, a3, -981
                  c.add       t4, s1
                  c.li        s4, -1
                  sra         s3, s2, s10
                  slt         a5, a7, s0
                  c.li        a6, -1
                  sltu        s8, s9, s9
                  sll         s4, gp, s3
                  sll         zero, a5, a3
                  and         t2, a1, s6
1235:             addi        a1, zero, 662
                  c.li        ra, -1
                  blt         t5, s4, 1246f
                  sra         gp, s5, t2
                  c.srai      a3, 24
                  srai        s7, t1, 1
                  c.xor       a3, a3
                  nop
                  bne         zero, s1, 1260f
                  bge         s6, t1, 1255f
                  sltiu       a4, a0, 891
1246:             bgeu        t6, s5, 1262f
                  beq         s5, t2, 1255f
                  bge         tp, t3, 1250f
                  c.add       s6, s7
1250:             c.srai      a3, 24
                  bge         s10, a7, 1259f
                  mulhu       s10, t1, s0
                  bltu        sp, t0, 1265f
                  ori         ra, a6, 1934
1255:             slti        t1, t4, 1638
                  rem         a0, sp, s9
                  c.addi      ra, 16
                  sll         a1, s10, a2
1259:             c.addi      t2, -1
1260:             c.srai      a3, 10
                  rem         t0, t2, s1
1262:             bltu        a4, a4, 1264f
                  mulhsu      t3, s6, zero
1264:             c.addi16sp  sp, -16
1265:             addi        s1, s2, -1625
                  slt         a3, s3, a0
                  sltiu       t1, a7, -22
                  c.beqz      a3, 1282f
                  srli        s7, s0, 17
                  slli        s10, t1, 2
                  sub         t1, s2, gp
                  c.addi4spn  a1, sp, 64
                  c.addi4spn  a3, sp, 832
                  c.mv        s9, a2
                  andi        s9, s7, -238
                  sra         t4, s4, s3
                  mul         s2, a7, tp
                  c.bnez      a1, 1283f
                  nop
                  c.li        s0, 23
                  c.add       ra, gp
1282:             ori         zero, s8, 805
1283:             srai        a4, s6, 11
                  sll         s8, t5, tp
                  sltu        s1, t2, s3
                  or          tp, t0, zero
                  beq         t1, a0, 1290f
                  div         t4, s4, ra
                  bge         s5, s6, 1302f
1290:             xor         a6, a2, gp
                  mulh        s6, a2, a4
                  c.addi4spn  a3, sp, 16
                  sltiu       t2, a1, -187
                  c.bnez      a3, 1295f
1295:             div         a0, a2, t5
                  c.andi      a3, 14
                  bne         a5, s2, 1314f
                  c.sub       a3, a3
                  slti        a5, s7, 1632
                  c.addi4spn  a3, sp, 576
                  xor         a4, s10, ra
1302:             and         a1, t3, s11
                  xori        t2, s0, 377
                  mulhu       s6, t4, t4
                  mulhsu      s7, t3, a6
                  c.srli      a3, 18
                  div         zero, s2, s9
                  auipc       zero, 37513
                  mulh        s0, t0, ra
                  mulhsu      t2, t2, t1
                  sll         s7, t3, s1
                  beq         a3, s1, 1317f
                  sra         s7, s10, a3
1314:             c.li        s4, 30
                  mulh        a1, a4, t4
                  sub         t2, s7, s8
1317:             c.andi      a3, -1
                  rem         s2, sp, s9
                  bltu        t6, s6, 1329f
                  lui         s5, 1032720
                  c.xor       a3, a3
                  slt         s6, a0, s5
                  mulh        s7, t2, t2
                  c.xor       a3, a3
                  sra         s0, t1, s3
                  sra         a3, s6, t5
                  bne         t5, s5, 1335f
                  and         s9, s0, a1
1329:             ori         t1, a5, -1441
                  c.bnez      a3, 1337f
                  c.addi      t3, 24
                  add         a5, t2, s3
                  xor         t3, t2, a3
                  slti        a3, a6, 1060
1335:             c.xor       a3, a3
                  xor         s3, t5, sp
1337:             blt         t4, t3, 1355f
                  ori         t4, s5, -1968
                  c.bnez      a3, 1357f
                  sll         s11, a7, s5
                  mulh        s7, t0, s3
                  c.srli      a3, 27
                  c.sub       a3, a3
                  beq         a2, t0, 1358f
                  c.addi4spn  a3, sp, 640
                  slli        s7, sp, 22
                  div         s0, sp, s3
                  nop
                  c.sub       a3, a3
                  c.addi16sp  sp, 304
                  srli        t2, s6, 31
                  srl         zero, a6, s11
                  c.and       a3, a3
                  mulhu       s9, s10, a0
1355:             auipc       s5, 550542
                  c.bnez      a3, 1358f
1357:             c.li        sp, 10
1358:             sra         s6, t1, t4
                  c.sub       a3, a3
                  c.addi      s8, -1
                  mulhu       a6, a6, t2
                  bgeu        a2, s1, 1363f
1363:             auipc       a0, 538676
                  xor         a6, t1, s2
                  and         t3, ra, s8
                  mul         a4, a4, sp
                  srli        s4, a3, 1
                  sra         s0, sp, t4
                  srl         ra, a4, s2
                  sll         s6, gp, s1
                  slt         gp, s1, a6
                  c.slli      gp, 18
                  c.beqz      a1, 1383f
                  c.nop
                  nop
                  c.beqz      a3, 1385f
                  xori        a4, t3, 1976
                  srli        s9, zero, 5
                  c.add       t1, t4
                  c.beqz      a3, 1393f
                  c.add       t3, s4
                  c.srai      s1, 25
1383:             c.slli      ra, 14
                  bgeu        sp, s5, 1389f
1385:             slti        s0, s1, 789
                  srli        zero, s0, 11
                  c.andi      a3, -1
                  lui         s11, 154449
1389:             bltu        s4, tp, 1400f
                  c.li        s10, 25
                  sltu        s6, s2, a4
                  slt         a1, a0, ra
1393:             c.lui       t1, 8
                  divu        s10, ra, s7
                  addi        a3, t3, 1947
                  add         a6, ra, a4
                  ori         t2, s7, -2047
                  add         t1, a2, a0
                  c.nop
1400:             ori         a0, s8, -1012
                  c.add       t0, sp
                  and         ra, t4, a1
                  c.addi16sp  sp, -16
                  beq         tp, sp, 1412f
                  c.lui       s7, 5
                  c.addi4spn  a3, sp, 608
                  c.sub       a2, a3
                  blt         t3, s1, 1425f
                  beq         a0, a6, 1411f
                  sub         s8, s1, s1
1411:             c.beqz      a3, 1427f
1412:             srli        a5, t6, 13
                  mulhu       a1, s9, a1
                  c.slli      t1, 24
                  c.xor       s1, a3
                  c.addi      ra, 31
                  sub         gp, a0, s7
                  c.sub       a3, s0
                  sra         tp, s3, s10
                  add         zero, gp, t4
                  c.srai      a3, 28
                  nop
                  c.sub       a3, a3
                  bne         ra, t2, 1432f
1425:             auipc       zero, 565421
                  c.addi16sp  sp, 48
1427:             ori         t0, a4, -1504
                  c.xor       a3, a3
                  c.srli      a3, 26
                  c.mv        tp, a3
                  andi        zero, gp, -228
1432:             slt         tp, a0, a4
                  rem         zero, s10, a1
                  nop
                  c.andi      a1, -1
                  mulhu       t0, t3, s0
                  c.addi4spn  a3, sp, 128
                  slli        t0, s7, 17
                  c.xor       a3, a3
                  bge         tp, s3, 1452f
                  c.beqz      a3, 1446f
                  c.addi16sp  sp, 32
                  c.beqz      a3, 1457f
                  c.srai      a3, 22
                  slli        zero, zero, 13
1446:             add         s9, a1, t4
                  and         zero, t4, s4
                  c.addi16sp  sp, 160
                  sll         s10, a4, t6
                  c.xor       a3, a1
                  c.mv        t0, a0
1452:             c.or        a3, a3
                  c.or        a3, a3
                  xor         s5, a1, s9
                  mul         s0, t5, t0
                  nop
1457:             slli        s4, a5, 4
                  nop
                  andi        a0, s9, 1939
                  c.slli      gp, 25
                  bge         t1, t1, 1464f
                  c.or        s1, a3
                  c.slli      s0, 27
1464:             c.andi      a2, 31
                  sltiu       ra, s10, -553
                  slli        t1, a5, 23
                  div         t1, tp, s8
                  c.srli      a3, 30
                  bne         a2, ra, 1486f
                  and         s4, a6, t5
                  c.addi      ra, -1
                  c.lui       t3, 26
                  c.srli      a3, 16
                  xori        s11, zero, 1117
                  xori        t1, s7, 1052
                  c.beqz      a3, 1478f
                  andi        a2, a4, 1433
1478:             and         s9, s11, s3
                  or          s10, t4, t6
                  slli        s0, t2, 3
                  c.addi4spn  a4, sp, 800
                  blt         t3, s10, 1491f
                  add         s11, s0, s8
                  slti        a0, a1, -1308
                  mulhu       t2, t5, a7
1486:             auipc       s2, 344078
                  sll         zero, a6, gp
                  c.addi      a4, 19
                  c.addi4spn  a3, sp, 896
                  c.slli      a1, 9
1491:             sra         s7, s3, a2
                  c.srai      a3, 25
                  srli        t4, s6, 16
                  addi        sp, tp, 563
                  ori         zero, a5, -376
                  c.andi      a3, 10
                  mulh        s4, a5, s7
                  ori         s10, s1, 2036
                  mulh        ra, sp, s5
                  c.addi4spn  a3, sp, 688
                  div         a1, a7, t1
                  or          zero, s8, s11
                  slli        tp, a7, 30
                  c.addi16sp  sp, 256
                  c.mv        s11, t5
                  sll         a0, s1, a7
                  and         zero, t5, t1
                  blt         s11, s8, 1516f
                  mulhsu      s2, t0, t4
                  srai        zero, t5, 20
                  bne         a7, ra, 1515f
                  c.andi      a3, -1
                  andi        tp, ra, -1149
                  srli        s5, s9, 28
1515:             divu        zero, s3, s9
1516:             c.srli      a3, 18
                  srl         a6, a4, t2
                  bgeu        s3, t6, 1525f
                  or          a1, t3, s8
                  sltu        t0, a7, t0
                  c.xor       a3, a0
                  c.slli      s0, 12
                  mulh        s7, s5, s8
                  lui         a0, 441086
1525:             bge         a3, t5, 1533f
                  divu        s5, s2, s7
                  c.sub       a3, a3
                  bltu        a6, s6, 1537f
                  c.mv        s6, a3
                  nop
                  srai        ra, s7, 11
                  divu        gp, s10, s8
1533:             mulhsu      s9, gp, s7
                  slli        s6, s4, 8
                  and         s10, t1, a6
                  bne         tp, t5, 1541f
1537:             bltu        s10, s11, 1544f
                  c.nop
                  srai        ra, gp, 0
                  slli        t1, s11, 28
1541:             lui         a3, 909227
                  div         a4, s5, zero
                  c.bnez      a3, 1558f
1544:             auipc       zero, 768504
                  c.sub       a3, s0
                  addi        ra, a4, -494
                  mulh        t1, s11, sp
                  c.addi16sp  sp, 416
                  beq         s8, ra, 1567f
                  slt         t2, s5, a0
                  sub         a1, tp, s9
                  c.or        a3, a3
                  srl         t2, s4, s1
                  xor         t1, s5, s2
                  add         a0, s9, gp
                  add         zero, a6, a0
                  srli        s7, gp, 26
1558:             c.sub       a3, a3
                  blt         a6, a3, 1567f
                  andi        zero, gp, -330
                  c.li        sp, -1
                  xori        s6, s0, 2027
                  c.or        a3, a3
                  c.sub       a1, a3
                  lui         a6, 588039
                  c.srai      a3, 6
1567:             c.and       a3, a3
                  sll         t4, s4, a5
                  c.or        a3, a3
                  srai        zero, t0, 18
                  rem         t1, t2, a0
                  or          s8, s4, a3
                  c.srli      a3, 2
                  auipc       zero, 998121
                  c.srai      s1, 6
                  bltu        t0, a3, 1578f
                  andi        t1, a3, 1423
1578:             c.addi16sp  sp, 272
                  blt         t2, t0, 1593f
                  c.srli      a3, 17
                  xori        s1, a2, 1324
                  slt         t0, ra, s10
                  bgeu        t6, s7, 1598f
                  auipc       s1, 165462
                  sra         zero, s2, t5
                  ori         t0, zero, 2034
                  xor         a1, s4, s3
                  c.andi      a3, -1
                  sll         a1, a6, a0
                  auipc       zero, 641761
                  bge         t0, t6, 1603f
                  slti        t0, s2, 943
1593:             bge         s1, s9, 1600f
                  div         gp, a3, s9
                  and         t4, tp, s9
                  srai        s6, a1, 6
                  bge         a2, t0, 1606f
1598:             sltu        s11, a1, t4
                  c.slli      ra, 11
1600:             c.sub       a0, a3
                  c.slli      ra, 17
                  c.li        a0, 25
1603:             div         s10, s5, t0
                  c.addi16sp  sp, -16
                  bgeu        a3, ra, 1606f
1606:             div         s4, s0, t0
                  c.mv        ra, s4
                  auipc       s10, 362435
                  addi        a4, s11, 2043
                  and         zero, s6, a6
                  c.or        a3, a3
                  ori         t3, ra, -1986
                  c.and       a0, a3
                  c.srai      a3, 17
                  bge         t4, a3, 1624f
                  or          zero, gp, s5
                  c.slli      s8, 15
                  div         s4, s4, s7
                  blt         s6, s6, 1623f
                  divu        s2, a7, t5
                  c.beqz      a3, 1638f
                  srli        t3, ra, 15
1623:             c.addi4spn  s0, sp, 320
1624:             bltu        gp, s5, 1635f
                  nop
                  c.addi      s5, 15
                  slli        s9, t0, 2
                  c.nop
                  bge         s1, t4, 1647f
                  blt         s9, t0, 1635f
                  andi        a4, gp, 8
                  c.srli      a5, 19
                  sll         a6, t4, t1
                  xor         a1, s6, s2
1635:             srli        s10, t5, 18
                  slli        a2, a2, 4
                  add         s0, sp, a7
1638:             slti        s3, s10, -1878
                  c.addi16sp  sp, 480
                  sltu        s4, a2, s6
                  sra         s11, a2, a5
                  rem         ra, s9, s5
                  addi        s0, s6, 502
                  sltiu       t2, s5, 1941
                  c.andi      a1, 12
                  or          s10, a0, a4
1647:             lui         s2, 726354
                  slli        s4, a1, 14
                  or          tp, s3, gp
                  xori        a2, t1, 1790
                  c.li        sp, -1
                  c.nop
                  c.addi4spn  a3, sp, 960
                  c.xor       a3, a3
                  ori         s9, t0, 1879
                  c.slli      ra, 23
                  c.srli      a3, 18
                  mulh        t2, a4, gp
                  mulhsu      t0, tp, a2
                  c.nop
                  bne         t6, s6, 1669f
                  blt         s5, s3, 1676f
                  c.srai      a3, 16
                  ori         s9, s10, 1324
                  mulh        zero, a4, t4
                  addi        a4, sp, -966
                  bgeu        s11, ra, 1684f
                  c.addi4spn  a3, sp, 64
1669:             mulh        t0, s9, a4
                  slti        zero, s10, 1164
                  div         s0, s6, a5
                  beq         t6, s1, 1677f
                  c.li        s7, -1
                  sltu        s6, s7, t5
                  srai        s4, t2, 20
1676:             xor         s7, sp, a4
1677:             andi        s3, s6, -1019
                  c.addi16sp  sp, -16
                  div         zero, t2, s4
                  divu        s0, a4, a1
                  nop
                  sra         s4, s10, s9
                  c.xor       a3, a3
1684:             sra         s8, t6, zero
                  bltu        ra, gp, 1692f
                  c.beqz      a3, 1702f
                  srl         gp, s0, t5
                  sra         s5, s9, s10
                  auipc       t4, 162546
                  c.and       a3, a3
                  ori         sp, s2, -1683
1692:             bgeu        s8, s10, 1697f
                  bne         a1, a3, 1702f
                  or          ra, s9, s0
                  c.add       s3, a2
                  ori         s5, s2, -336
1697:             c.beqz      a3, 1707f
                  slt         zero, s1, a2
                  andi        a3, s4, 1109
                  sll         s6, s10, a6
                  c.nop
1702:             c.slli      a6, 28
                  mulh        s7, s1, gp
                  sltu        s4, s4, s1
                  nop
                  slt         s2, s9, a3
1707:             c.addi4spn  a3, sp, 864
                  add         sp, s2, s3
                  slti        a2, a7, 323
                  slt         s3, s11, t3
                  slli        t2, s1, 20
                  c.sub       a3, a3
                  and         a4, a6, s1
                  slt         t1, s10, t4
                  mulhsu      s5, t4, s11
                  c.nop
                  sltiu       sp, s10, -1306
                  xor         tp, s5, t2
                  c.addi16sp  sp, 32
                  c.mv        s0, s9
                  mulh        s3, a5, zero
                  mulhsu      ra, gp, ra
                  mul         s6, t2, s6
                  andi        s3, tp, -254
                  srai        s3, s11, 27
                  c.addi      a4, 24
                  c.addi      ra, -1
                  sltu        zero, a5, sp
                  c.mv        t1, tp
                  sltiu       s6, a0, -1537
                  mul         ra, zero, a6
                  c.li        a4, -1
                  sltu        a6, t2, zero
                  bltu        tp, t4, 1742f
                  or          s2, a0, s10
                  c.xor       a3, a3
                  sub         s5, s3, a2
                  c.addi4spn  a3, sp, 64
                  auipc       zero, 171505
                  blt         a7, s1, 1742f
                  sltiu       gp, s3, -1081
1742:             beq         s7, a0, 1760f
                  rem         s0, t4, s10
                  c.srai      a3, 20
                  mulhsu      gp, a3, a7
                  addi        s3, s0, 715
                  sltiu       zero, s4, 1637
                  or          gp, sp, s1
                  c.srai      a3, 16
                  blt         a6, gp, 1758f
                  slti        s3, s3, -569
                  c.andi      a3, -1
                  c.addi      s4, 2
                  divu        t1, tp, s11
                  c.mv        ra, s9
                  mulhu       s0, t3, s4
                  bltu        tp, s4, 1759f
1758:             mul         gp, s7, gp
1759:             auipc       a0, 859778
1760:             mulhsu      a6, gp, a6
                  mulhu       a2, a5, t2
                  sltu        zero, t2, a0
                  slli        tp, s6, 20
                  addi        t1, s7, -1956
                  sltiu       s6, zero, -1925
                  addi        s5, a1, -958
                  lui         a2, 306552
                  c.slli      t2, 6
                  nop
                  beq         t0, s5, 1773f
                  c.addi4spn  a3, sp, 128
                  andi        gp, t4, 882
1773:             c.addi16sp  sp, 192
                  sra         ra, s0, s8
                  sub         s0, gp, a7
                  slt         tp, a7, a6
                  srai        zero, gp, 0
                  sltu        a5, s4, a7
                  slt         s3, a5, t0
                  c.xor       a3, a3
                  blt         t1, a0, 1794f
                  sll         t2, a6, tp
                  c.srli      a1, 22
                  slti        s0, tp, 1454
                  slti        s4, sp, 1978
                  mul         a2, a3, a5
                  xori        a2, s11, 940
                  sub         a0, a7, zero
                  c.nop
                  mul         a4, a1, s3
                  mulh        t4, t1, s11
                  sub         zero, t0, s9
                  c.li        s2, -1
1794:             c.li        t4, -1
                  srai        tp, s5, 6
                  auipc       t4, 764961
                  slli        ra, s2, 4
                  c.mv        ra, a3
                  c.srai      a3, 12
                  c.slli      s9, 21
                  mulhsu      t1, s11, s7
                  c.addi16sp  sp, -16
                  c.slli      ra, 3
                  bne         s3, a3, 1813f
                  c.bnez      s1, 1820f
                  lui         s5, 1028236
                  c.and       a3, a3
                  c.srai      a3, 12
                  or          a3, s7, s8
                  auipc       zero, 45878
                  blt         s0, s3, 1813f
                  addi        zero, s6, -569
1813:             slti        a3, s6, -63
                  c.and       a3, a3
                  c.andi      a3, 28
                  c.addi      t0, 25
                  c.xor       a3, a3
                  bge         t5, s2, 1821f
                  c.srai      a3, 9
1820:             c.sub       a3, a3
1821:             c.lui       s6, 18
                  xori        s3, a0, 1423
                  rem         tp, t3, t3
                  c.mv        s0, s9
                  slli        a4, a2, 17
                  addi        s4, t0, -1945
                  c.and       a3, a3
                  rem         a3, s5, s7
                  lui         s4, 95502
                  mulhsu      a6, s6, t2
                  sltu        s5, s9, t2
                  xori        ra, t0, -89
                  div         s5, s4, t5
                  sll         a3, t1, s11
                  srai        s10, s11, 16
                  xor         a6, t6, a6
                  c.srli      a3, 2
                  nop
                  bge         s1, t1, 1847f
                  lui         a6, 751076
                  slt         s11, t1, s3
                  div         s5, a6, t4
                  bgeu        s8, t6, 1852f
                  sra         s10, t1, t6
                  divu        a3, a7, s9
                  divu        a3, a3, tp
1847:             addi        sp, s4, -2034
                  sltiu       a5, tp, -768
                  sub         s6, gp, a7
                  c.addi      a2, -1
                  mulh        ra, s2, a7
1852:             mulh        s10, zero, s0
                  c.srli      a3, 5
                  andi        zero, t4, -66
                  and         s11, a0, s8
                  c.andi      a3, -1
                  c.and       a3, a3
                  c.beqz      a3, 1863f
                  add         s5, s6, t1
                  sltu        s10, t5, a7
                  sra         s2, a1, a3
                  c.li        t0, -1
1863:             ori         t2, t3, -373
                  srl         zero, s11, t1
                  c.add       a0, s5
                  c.add       t3, s8
                  bgeu        s7, tp, 1874f
                  ori         a3, s11, -1674
                  bge         t4, s4, 1871f
                  and         a3, a6, t2
1871:             c.lui       ra, 9
                  srai        gp, zero, 22
                  mulh        s5, s0, s9
1874:             bltu        s5, t0, 1881f
                  c.li        sp, 4
                  c.srai      a3, 31
                  c.srli      a1, 24
                  c.srai      a3, 7
                  slli        ra, s9, 24
                  rem         s0, s4, a6
1881:             add         s8, ra, s10
                  mulhu       a0, s5, t2
                  lui         s6, 537376
                  nop
                  c.or        a3, a3
                  c.beqz      a3, 1903f
                  c.bnez      a3, 1895f
                  srl         zero, s7, zero
                  blt         a3, s2, 1902f
                  andi        zero, s0, 89
                  rem         s9, s8, ra
                  c.beqz      a4, 1904f
                  nop
                  c.sub       a3, a3
1895:             or          sp, t3, s4
                  mulh        gp, s11, t2
                  c.and       a3, a3
                  c.lui       s5, 27
                  div         s10, s10, zero
                  c.xor       a3, a3
                  c.addi      sp, 23
1902:             srai        s0, a6, 21
1903:             sra         s11, s3, t1
1904:             mulhu       t1, zero, s5
                  lui         gp, 968518
                  addi        a4, s1, 1231
                  add         a4, s8, t3
                  slti        zero, a7, 879
                  ori         s0, t1, 156
                  rem         t2, t5, t3
                  bne         s5, s2, 1916f
                  slli        ra, t6, 27
                  mulh        a4, a4, t1
                  nop
                  c.srai      a3, 7
1916:             slt         tp, s5, t4
                  c.lui       s11, 6
                  c.or        a3, a3
                  andi        t2, s1, 1494
                  c.slli      s8, 5
                  sra         s4, s2, s2
                  c.addi4spn  a4, sp, 640
                  sltiu       gp, s9, -881
                  srli        t3, t2, 10
                  mulhu       s5, a7, s0
                  srai        t1, t5, 25
                  xor         s10, zero, ra
                  bge         s5, a5, 1929f
1929:             andi        s11, a6, 16
                  sra         s9, s10, a2
                  srli        a6, a1, 26
                  c.beqz      s0, 1940f
                  and         s0, s1, s5
                  c.sub       a3, a3
                  c.srli      a3, 16
                  xori        a1, t5, 2016
                  c.addi4spn  a3, sp, 896
                  c.and       a0, a3
                  c.beqz      a3, 1953f
1940:             c.addi4spn  a2, sp, 320
                  mulhsu      zero, s10, s3
                  c.nop
                  or          zero, s2, a7
                  mulhu       s6, s2, a5
                  slti        s1, s9, 1812
                  slt         s7, t1, t6
                  slti        a2, a6, -249
                  and         s1, s4, a0
                  c.addi16sp  sp, -16
                  sll         t0, t0, t6
                  sltu        sp, s1, a6
                  nop
1953:             mulhsu      a2, t3, a2
                  add         tp, t0, a3
                  c.addi16sp  sp, -16
                  divu        s8, s11, s1
                  bgeu        a1, a0, 1968f
                  bge         s10, t1, 1963f
                  c.add       sp, a7
                  srl         s3, s10, tp
                  beq         a6, zero, 1975f
                  c.andi      a3, 14
1963:             sll         tp, t6, a1
                  andi        s1, a0, 1666
                  c.or        a3, a3
                  sltu        s2, a0, t0
                  auipc       tp, 486239
1968:             or          ra, s1, t3
                  c.or        a3, a3
                  srli        zero, a6, 29
                  beq         s5, t4, 1989f
                  sra         a2, s10, t0
                  mulh        a1, s2, tp
                  c.or        a3, a3
1975:             c.xor       s0, a1
                  bgeu        a0, s4, 1978f
                  sub         s0, s8, t1
1978:             bgeu        s10, t0, 1987f
                  div         s11, s5, a3
                  mul         a5, t0, s7
                  blt         a5, a2, 1997f
                  lui         zero, 276575
                  c.lui       tp, 31
                  or          a3, ra, s7
                  c.nop
                  c.nop
1987:             sltu        zero, t3, s10
                  c.addi16sp  sp, -16
1989:             c.lui       a0, 23
                  c.addi4spn  a3, sp, 128
                  slli        a3, a4, 19
                  srli        gp, s3, 24
                  and         a6, s8, zero
                  div         s7, s9, t5
                  mul         zero, t6, a7
                  c.and       a3, a3
1997:             bltu        a5, t2, 2005f
                  xori        t0, t1, -1919
                  xori        s10, s0, -1633
                  sltiu       s3, a2, 1343
                  c.addi4spn  a3, sp, 48
                  bltu        s4, a1, 2012f
                  bgeu        a4, t0, 2021f
                  c.andi      a3, -1
2005:             mulhu       a3, s5, t4
                  c.addi16sp  sp, -16
                  mulhu       a4, ra, s3
                  c.addi4spn  a3, sp, 592
                  c.add       t4, t0
                  bge         zero, s0, 2027f
                  auipc       s2, 195225
2012:             divu        s11, t1, a7
                  c.sub       a3, s1
                  blt         s11, s4, 2018f
                  and         a0, t3, s4
                  srl         tp, a4, a6
                  sub         tp, a0, s6
2018:             xor         t1, s9, a0
                  srai        a2, s10, 21
                  blt         a5, s6, 2028f
2021:             auipc       ra, 544450
                  srli        zero, gp, 6
                  c.li        s10, -1
                  sub         a3, s2, t1
                  slti        tp, gp, -556
                  mul         zero, s0, a0
2027:             srli        t3, gp, 7
2028:             slti        sp, s7, 1163
                  div         s8, ra, t0
                  c.addi4spn  a5, sp, 64
                  blt         t2, t0, 2036f
                  c.or        a3, a3
                  c.xor       a3, a3
                  c.add       s4, t5
                  rem         zero, t0, t6
2036:             c.and       a3, a3
                  la x17, test_done
                  jalr x0, x17, 0
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
                  csrrw x30, 0x340, x30
                  add x30, x31, zero
                  1: addi x30, x30, -124
                  sw x1, 4(x30)
                  sw x2, 8(x30)
                  sw x3, 12(x30)
                  sw x4, 16(x30)
                  sw x5, 20(x30)
                  sw x6, 24(x30)
                  sw x7, 28(x30)
                  sw x8, 32(x30)
                  sw x9, 36(x30)
                  sw x10, 40(x30)
                  sw x11, 44(x30)
                  sw x12, 48(x30)
                  sw x13, 52(x30)
                  sw x14, 56(x30)
                  sw x15, 60(x30)
                  sw x16, 64(x30)
                  sw x17, 68(x30)
                  sw x18, 72(x30)
                  sw x19, 76(x30)
                  sw x20, 80(x30)
                  sw x21, 84(x30)
                  sw x22, 88(x30)
                  sw x23, 92(x30)
                  sw x24, 96(x30)
                  sw x25, 100(x30)
                  sw x26, 104(x30)
                  sw x27, 108(x30)
                  sw x28, 112(x30)
                  sw x29, 116(x30)
                  sw x30, 120(x30)
                  sw x31, 124(x30)
                  csrr x22, 0x300 # MSTATUS
                  csrr x22, 0x342 # MCAUSE
                  srli x22, x22, 31
                  bne x22, x0, mmode_intr_handler

mmode_exception_handler:
                  csrr x22, 0x341 # MEPC
                  csrr x22, 0x342 # MCAUSE
                  li x6, 0xb # ECALL_MMODE
                  beq x22, x6, ecall_handler
                  li x6, 0x2 # ILLEGAL_INSTRUCTION
                  beq x22, x6, illegal_instr_handler
                  csrr x6, 0x343 # MTVAL
                  1: la x17, test_done
                  jalr x1, x17, 0

ecall_handler:    
                  la x22, _start
                  sw x0, 0(x22)
                  sw x1, 4(x22)
                  sw x2, 8(x22)
                  sw x3, 12(x22)
                  sw x4, 16(x22)
                  sw x5, 20(x22)
                  sw x6, 24(x22)
                  sw x7, 28(x22)
                  sw x8, 32(x22)
                  sw x9, 36(x22)
                  sw x10, 40(x22)
                  sw x11, 44(x22)
                  sw x12, 48(x22)
                  sw x13, 52(x22)
                  sw x14, 56(x22)
                  sw x15, 60(x22)
                  sw x16, 64(x22)
                  sw x17, 68(x22)
                  sw x18, 72(x22)
                  sw x19, 76(x22)
                  sw x20, 80(x22)
                  sw x21, 84(x22)
                  sw x22, 88(x22)
                  sw x23, 92(x22)
                  sw x24, 96(x22)
                  sw x25, 100(x22)
                  sw x26, 104(x22)
                  sw x27, 108(x22)
                  sw x28, 112(x22)
                  sw x29, 116(x22)
                  sw x30, 120(x22)
                  sw x31, 124(x22)
                  la x17, write_tohost
                  jalr x0, x17, 0

illegal_instr_handler:
                  csrr  x22, 0x341
                  addi  x22, x22, 4
                  csrw  0x341, x22
                  lw x1, 4(x30)
                  lw x2, 8(x30)
                  lw x3, 12(x30)
                  lw x4, 16(x30)
                  lw x5, 20(x30)
                  lw x6, 24(x30)
                  lw x7, 28(x30)
                  lw x8, 32(x30)
                  lw x9, 36(x30)
                  lw x10, 40(x30)
                  lw x11, 44(x30)
                  lw x12, 48(x30)
                  lw x13, 52(x30)
                  lw x14, 56(x30)
                  lw x15, 60(x30)
                  lw x16, 64(x30)
                  lw x17, 68(x30)
                  lw x18, 72(x30)
                  lw x19, 76(x30)
                  lw x20, 80(x30)
                  lw x21, 84(x30)
                  lw x22, 88(x30)
                  lw x23, 92(x30)
                  lw x24, 96(x30)
                  lw x25, 100(x30)
                  lw x26, 104(x30)
                  lw x27, 108(x30)
                  lw x28, 112(x30)
                  lw x29, 116(x30)
                  lw x30, 120(x30)
                  lw x31, 124(x30)
                  addi x30, x30, 124
                  add x31, x30, zero
                  csrrw x30, 0x340, x30
                  mret

pt_fault_handler: 

.align 2
mmode_intr_handler:
                  csrr  x22, 0x300 # MSTATUS;
                  csrr  x22, 0x304 # MIE;
                  csrr  x22, 0x344 # MIP;
                  csrrc x22, 0x344, x22 # MIP;
                  lw x1, 4(x30)
                  lw x2, 8(x30)
                  lw x3, 12(x30)
                  lw x4, 16(x30)
                  lw x5, 20(x30)
                  lw x6, 24(x30)
                  lw x7, 28(x30)
                  lw x8, 32(x30)
                  lw x9, 36(x30)
                  lw x10, 40(x30)
                  lw x11, 44(x30)
                  lw x12, 48(x30)
                  lw x13, 52(x30)
                  lw x14, 56(x30)
                  lw x15, 60(x30)
                  lw x16, 64(x30)
                  lw x17, 68(x30)
                  lw x18, 72(x30)
                  lw x19, 76(x30)
                  lw x20, 80(x30)
                  lw x21, 84(x30)
                  lw x22, 88(x30)
                  lw x23, 92(x30)
                  lw x24, 96(x30)
                  lw x25, 100(x30)
                  lw x26, 104(x30)
                  lw x27, 108(x30)
                  lw x28, 112(x30)
                  lw x29, 116(x30)
                  lw x30, 120(x30)
                  lw x31, 124(x30)
                  addi x30, x30, 124
                  add x31, x30, zero
                  csrrw x30, 0x340, x30
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
