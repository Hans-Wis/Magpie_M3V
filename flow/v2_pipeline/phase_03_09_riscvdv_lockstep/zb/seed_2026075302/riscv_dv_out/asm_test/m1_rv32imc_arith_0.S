.include "user_define.h"
.globl _start
.section .text
_start:           
                  .include "user_init.s"
                  csrr x5, 0xf14
                  li x6, 0
                  beq x5, x6, 0f

0: la x14, h0_start
jalr x0, x14, 0
h0_start:
                  li x30, 0x40001104
                  csrw 0x301, x30
kernel_sp:        
                  la x9, kernel_stack_end

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
                  li x0, 0x0
                  li x1, 0xe845d46f
                  li x2, 0x1d24aa9f
                  li x3, 0x0
                  li x4, 0x0
                  li x5, 0x0
                  li x6, 0xb
                  li x7, 0xdffec5fc
                  li x8, 0x0
                  li x10, 0xf6c7d585
                  li x11, 0x80000000
                  li x12, 0xf41331ab
                  li x13, 0xa
                  li x14, 0x80000000
                  li x15, 0xd
                  li x16, 0xb
                  li x17, 0x0
                  li x18, 0x0
                  li x19, 0x80000000
                  li x20, 0x80000000
                  li x21, 0x1
                  li x22, 0x6
                  li x23, 0xb809f225
                  li x24, 0xd0be6c4f
                  li x25, 0x7
                  li x26, 0x71494e
                  li x27, 0x80000000
                  li x28, 0xf6fed2db
                  li x29, 0xfc1b66c0
                  li x30, 0x5
                  la x31, user_stack_end
main:             xori        s4, a5, -691
                  add         t2, t3, s0
                  c.addi4spn  a0, sp, 144
                  c.add       t5, tp
                  mulhu       sp, s7, t1
                  add         t5, a6, s9
                  c.add       s6, s3
                  c.andi      a1, 9
                  c.mv        s10, ra
                  c.addi4spn  a3, sp, 960
                  nop
                  c.mv        tp, gp
                  bgeu        s9, s0, 18f
                  c.bnez      a2, 21f
                  sll         t2, s1, a5
                  lui         t0, 994073
                  slli        s7, s4, 17
                  blt         tp, s9, 19f
18:               c.and       a1, a1
19:               addi        t0, t6, -1625
                  c.slli      a3, 8
21:               c.addi      t2, 4
                  div         s7, t1, s7
                  srli        zero, t4, 27
                  sub         t5, t4, s1
                  c.addi4spn  a0, sp, 272
                  c.beqz      a2, 36f
                  c.slli      ra, 10
                  bgeu        gp, tp, 36f
                  c.addi16sp  sp, 224
                  nop
                  c.andi      s0, -1
                  xori        a1, s10, 277
                  c.lui       t2, 20
                  rem         zero, a7, tp
                  blt         a3, a2, 42f
36:               sra         sp, s1, t2
                  ori         s4, t1, 1634
                  c.mv        sp, s8
                  c.addi      s11, -1
                  andi        s10, tp, -823
                  mulhsu      zero, s5, a7
42:               addi        s9, s7, 496
                  c.srli      a3, 23
                  blt         s8, tp, 51f
                  mul         a7, s3, ra
                  mulhu       s3, a1, s1
                  srli        a0, t5, 24
                  c.add       s8, t0
                  andi        s9, zero, 1310
                  auipc       s10, 827738
51:               auipc       s4, 201701
                  mulhu       s2, s2, t6
                  divu        s0, t1, t0
                  blt         a2, s0, 60f
                  sra         a7, a0, a2
                  c.add       s9, s4
                  c.lui       s0, 2
                  slti        a2, s8, -1619
                  slti        s10, tp, 1659
60:               mulhsu      t3, a6, s2
                  mulh        a5, a4, t2
                  bne         s0, s2, 70f
                  nop
                  c.add       a6, s11
                  c.andi      a0, 10
                  sltiu       s0, a4, -503
                  c.li        s4, -1
                  beq         a5, s3, 78f
                  c.slli      ra, 9
70:               auipc       sp, 230229
                  srli        zero, s10, 9
                  srli        sp, t5, 10
                  xori        gp, s9, 523
                  srai        a1, s1, 8
                  mulh        s2, ra, s10
                  sltu        t5, s7, s10
                  blt         s3, s6, 79f
78:               add         s6, a5, s5
79:               slti        s5, gp, -1355
                  rem         zero, s1, ra
                  divu        s6, sp, t1
                  c.beqz      a3, 94f
                  mul         t1, t6, s0
                  c.or        s0, a0
                  bne         zero, s8, 86f
86:               c.mv        t0, ra
                  mulhsu      a1, s2, a2
                  mul         tp, gp, sp
                  c.li        s10, 30
                  divu        a5, s7, s4
                  c.slli      ra, 5
                  sltiu       s7, a7, -1799
                  div         tp, s1, a5
94:               sra         s2, a5, s4
                  andi        s3, s11, -1949
                  mulhsu      tp, s3, a7
                  andi        t3, t4, -456
                  bltu        t5, s7, 109f
                  auipc       zero, 613719
                  c.li        t1, 25
                  c.and       a2, a3
                  c.addi      a2, -1
                  add         t4, s9, s1
                  ori         t1, s4, 1234
                  rem         ra, s1, a6
                  mulh        a5, s8, s3
                  c.xor       a0, s1
                  c.lui       t2, 24
109:              bltu        t1, t3, 111f
                  c.lui       a5, 23
111:              ori         s6, t6, 603
                  mulh        s4, t6, tp
                  add         gp, a6, a2
                  mulhsu      t1, sp, a2
                  c.andi      a1, 5
                  srl         a1, a6, zero
                  c.andi      a3, -1
                  c.mv        s2, s8
                  c.nop
                  beq         zero, s6, 136f
                  bltu        sp, a0, 133f
                  c.addi      s10, 10
                  beq         t3, s5, 127f
                  xor         t2, s1, s8
                  c.and       a3, a0
                  c.beqz      a5, 132f
127:              c.andi      a1, -1
                  ori         s5, s0, -1926
                  sra         a3, t6, a7
                  sltiu       gp, s1, -1128
                  sub         a3, t0, a5
132:              mulhu       t3, t3, a7
133:              sub         a7, a4, s8
                  sltu        s7, a2, a4
                  bltu        s6, tp, 145f
136:              c.li        a5, 15
                  divu        sp, s9, s11
                  bgeu        s6, tp, 143f
                  sll         t3, tp, tp
                  sltiu       t4, t0, -1548
                  beq         a1, t6, 143f
                  bltu        s6, t5, 149f
143:              slli        t3, t2, 17
                  srli        t0, t5, 2
145:              c.mv        s10, tp
                  andi        t5, s8, 1025
                  c.slli      sp, 1
                  divu        s8, t5, tp
149:              c.bnez      a2, 161f
                  c.nop
                  c.addi4spn  a0, sp, 320
                  nop
                  c.andi      a3, -1
                  bne         gp, t0, 173f
                  addi        s7, t4, -349
                  sltiu       a3, a4, 701
                  mul         zero, t2, a1
                  xor         t3, a7, zero
                  srai        s9, t6, 21
                  c.addi4spn  a0, sp, 384
161:              c.xor       s0, a3
                  bgeu        a5, zero, 167f
                  rem         zero, a2, t3
                  mulh        s6, a0, s7
                  c.srai      a2, 3
                  div         ra, t5, ra
167:              c.lui       s5, 1
                  add         s11, a1, t1
                  slt         a3, a1, t5
                  c.add       ra, s10
                  addi        a1, a6, -1015
                  mulh        a7, s3, s2
173:              div         a1, t1, a4
                  mulhu       zero, t4, a0
                  c.andi      a0, 26
                  c.slli      a0, 27
                  bne         s2, a3, 183f
                  c.sub       a5, a1
                  bne         a1, a1, 183f
                  mulhu       t3, t6, t2
                  slt         s6, gp, gp
                  c.slli      tp, 1
183:              c.li        tp, -1
                  and         zero, t0, t2
                  or          a0, t5, s9
                  mul         a3, s4, t3
                  mulhu       s4, t6, t2
                  c.andi      a3, -1
                  addi        tp, s1, -1068
                  c.li        s8, -1
                  c.addi4spn  a0, sp, 416
                  slli        t0, t3, 24
                  nop
                  c.add       s11, t2
                  sra         s9, a2, a7
                  mulhu       gp, s6, t4
                  c.nop
                  bne         zero, s5, 211f
                  or          t5, ra, t1
                  bltu        tp, s0, 201f
201:              bgeu        a0, a6, 212f
                  sltiu       a5, s4, -522
                  c.xor       a0, a3
                  c.srai      a3, 12
                  c.or        a2, a3
                  c.slli      a2, 16
                  c.add       tp, gp
                  c.or        s0, a0
                  sltiu       a5, sp, 9
                  beq         a5, s2, 215f
211:              c.sub       a0, s1
212:              rem         a6, a4, a7
                  c.beqz      a0, 218f
                  sra         s4, ra, t4
215:              c.addi16sp  sp, 368
                  sll         a3, s9, t3
                  c.sub       a1, a3
218:              c.bnez      a2, 237f
                  nop
                  slli        s0, a0, 25
                  c.andi      a2, 19
                  rem         a0, s8, t2
                  c.srai      a2, 24
                  bgeu        a6, s1, 231f
                  c.or        a3, a0
                  ori         ra, a6, 986
                  andi        t4, sp, 1854
                  c.addi4spn  a0, sp, 672
                  div         zero, s4, s0
                  c.addi16sp  sp, 208
231:              sltu        s7, s11, a5
                  c.andi      a2, 2
                  xori        t3, t0, -1318
                  sub         t2, s11, s1
                  c.or        a3, a0
                  c.andi      a2, 15
237:              mul         zero, s1, a3
                  c.add       ra, s10
                  c.xor       a2, a0
                  blt         s10, gp, 241f
241:              or          s0, s7, s10
                  nop
                  add         zero, t0, s1
                  xori        zero, t0, -1178
                  add         t0, t2, s3
                  c.addi16sp  sp, -16
                  c.srai      a0, 12
                  c.slli      t5, 20
                  slti        s11, t3, 416
                  auipc       a3, 658307
                  srai        s0, a2, 1
                  xori        a6, t1, -1161
                  sltiu       zero, ra, -278
                  c.lui       ra, 5
                  c.slli      s11, 6
                  c.addi16sp  sp, -16
                  divu        zero, gp, a6
                  c.slli      s9, 26
                  c.lui       ra, 24
                  c.li        a6, -1
                  c.addi4spn  a3, sp, 544
                  srl         s8, t3, t5
                  xor         s5, t2, a3
                  c.and       a0, a2
                  bge         t5, t1, 273f
                  blt         s8, a0, 276f
                  mul         s0, ra, t6
                  lui         sp, 11778
                  mulhsu      a5, s6, t2
                  lui         s7, 619892
                  sltu        zero, t1, s11
                  nop
273:              slli        a5, tp, 0
                  c.bnez      a1, 276f
                  nop
276:              bge         t0, s7, 278f
                  blt         s5, t0, 287f
278:              c.beqz      a3, 285f
                  c.beqz      s0, 285f
                  mul         s4, s2, t5
                  auipc       ra, 996717
                  slt         s8, a0, a1
                  c.li        sp, -1
                  c.and       a0, a0
285:              slt         s2, s0, a7
                  xor         a7, s7, s7
287:              slli        s9, t2, 5
                  bltu        s9, s4, 301f
                  c.li        t1, 3
                  sll         a2, a2, t3
                  c.sub       a0, s1
                  divu        tp, s5, a5
                  c.add       ra, sp
                  c.nop
                  c.lui       s11, 12
                  slti        a6, ra, 1481
                  andi        s0, s3, 1086
                  c.addi4spn  a3, sp, 112
                  auipc       zero, 318360
                  addi        a1, tp, 1230
301:              c.addi4spn  a2, sp, 464
                  ori         s4, t0, 1735
                  c.srli      a3, 12
                  c.li        s9, -1
                  bltu        a1, a7, 313f
                  c.xor       a2, a3
                  ori         zero, s0, -1842
                  divu        zero, t1, t4
                  mulh        zero, a2, a0
                  mulhsu      t0, a1, s10
                  xori        s5, gp, 268
                  divu        a0, a0, tp
313:              divu        s5, t2, a6
                  c.srai      a2, 22
                  auipc       zero, 931364
                  bltu        s1, s4, 318f
                  lui         t3, 200413
318:              c.addi4spn  a3, sp, 528
                  c.srli      a3, 8
                  c.srli      a1, 5
                  c.addi      t0, 16
                  lui         a3, 405277
                  nop
                  sltu        a3, gp, s11
                  sltu        zero, s8, t4
                  mulhu       a2, t5, t4
                  andi        s10, a1, 1937
                  slti        s5, a2, -660
                  sll         s0, t6, t1
                  c.sub       s0, a2
                  c.xor       a0, a1
                  c.mv        s10, s9
                  c.and       a2, a2
                  c.srli      a0, 21
                  srl         t2, s1, t2
                  c.addi16sp  sp, -16
                  srli        t4, t5, 6
                  c.srai      a3, 15
                  mul         zero, a6, a0
                  c.srai      a0, 26
                  beq         a2, a3, 351f
                  c.add       t2, a3
                  blt         a3, t3, 349f
                  mulhsu      s4, zero, ra
                  xor         a0, t5, s2
                  xor         s7, t0, t3
                  xori        zero, a0, 1137
                  c.addi16sp  sp, -16
349:              c.and       a1, a1
                  nop
351:              slt         sp, s8, s0
                  c.srli      a2, 14
                  sub         s3, tp, s11
                  srli        a1, a0, 20
                  beq         a4, a2, 362f
                  auipc       zero, 502531
                  auipc       zero, 300339
                  bltu        a4, s10, 362f
                  c.or        a0, a2
                  c.addi4spn  a3, sp, 528
                  xori        s0, zero, -1749
362:              slti        zero, t4, 1550
                  c.andi      a2, 0
                  addi        t3, s5, 387
                  c.nop
                  c.addi4spn  a0, sp, 656
                  bge         s9, s8, 369f
                  beq         t5, t4, 369f
369:              lui         s0, 416152
                  c.addi      a6, 10
                  bge         a6, gp, 383f
                  c.nop
                  c.addi4spn  a1, sp, 928
                  c.sub       a0, a2
                  slli        zero, s4, 3
                  mulh        a1, s2, s2
                  mulhu       t0, t1, t3
                  c.add       s7, t1
                  c.li        s0, -1
                  or          a6, s4, a3
                  sltiu       a5, s9, 864
                  srl         zero, t0, s10
383:              c.add       t5, s11
                  addi        zero, t5, 259
                  srli        s8, t4, 31
                  slt         a0, s0, s8
                  srl         zero, s1, sp
                  srli        ra, a1, 1
                  srai        s10, t3, 12
                  bgeu        t3, s1, 406f
                  bgeu        t4, s4, 403f
                  c.li        ra, 18
                  c.addi      ra, 3
                  divu        a7, a0, s3
                  c.addi4spn  a3, sp, 288
                  auipc       zero, 12514
                  div         a1, s1, zero
                  c.andi      a3, -1
                  auipc       gp, 751937
                  mulhsu      a5, gp, a1
                  bge         t3, s3, 407f
                  sll         a1, t4, s1
403:              c.mv        s2, s2
                  sll         t2, s0, s11
                  and         s3, t1, t3
406:              c.li        a2, -1
407:              slti        zero, t3, -1096
                  c.andi      a1, 11
                  srai        a6, s10, 27
                  slt         sp, tp, t6
                  and         sp, s0, s6
                  or          s11, gp, s9
                  blt         zero, a6, 425f
                  c.add       s9, ra
                  bltu        s4, s1, 423f
                  c.nop
                  andi        s9, s6, -693
                  c.lui       s3, 29
                  srl         t1, s3, t1
                  c.nop
                  mul         a7, a3, s2
                  beq         a5, s4, 426f
423:              mul         tp, sp, gp
                  rem         s3, t0, a3
425:              div         t5, zero, s6
426:              ori         a0, a4, 217
                  mulh        zero, s2, t5
                  slli        s2, t1, 12
                  c.mv        s3, t3
                  or          a0, s6, a3
                  sltiu       s11, ra, 468
                  nop
                  c.lui       s6, 27
                  c.xor       a0, a1
                  xor         sp, a2, t1
                  c.srai      a3, 15
                  c.xor       s0, a3
                  mulh        t2, a2, a3
                  bltu        t6, s11, 445f
                  c.mv        a0, s4
                  or          s11, s6, a2
                  rem         s2, s8, s6
                  lui         s11, 1017098
                  rem         a5, gp, s10
445:              blt         a3, s4, 451f
                  div         s9, tp, gp
                  ori         gp, a6, -1557
                  c.bnez      a0, 454f
                  lui         a3, 772693
                  c.nop
451:              srli        zero, a1, 21
                  sra         zero, a2, a1
                  slti        s4, ra, 516
454:              slt         t5, a2, a2
                  c.srai      a0, 6
                  c.lui       s11, 11
                  nop
                  c.beqz      a0, 466f
                  bgeu        s0, tp, 469f
                  c.mv        t1, ra
                  or          s10, s11, s3
                  c.mv        t3, a0
                  xori        t4, sp, -59
                  addi        s8, s9, -1271
                  slli        s6, ra, 14
466:              c.nop
                  xori        s10, s0, 1654
                  and         a7, s4, a7
469:              srai        s3, a5, 23
                  c.nop
                  c.and       s0, s1
                  c.sub       s0, s1
                  xor         s8, s4, sp
                  divu        a3, gp, zero
                  mulhsu      a0, s9, a1
                  bgeu        gp, a1, 486f
                  sub         zero, tp, a2
                  div         t3, s5, a1
                  bge         s0, a6, 481f
                  c.lui       a5, 24
481:              slt         zero, s5, t1
                  srai        gp, s6, 5
                  auipc       t3, 961260
                  mulhu       ra, a4, t4
                  c.lui       s5, 6
486:              c.xor       a1, a3
                  c.xor       a2, a1
                  c.andi      a2, 7
                  c.bnez      a0, 496f
                  rem         t1, s1, a0
                  mulh        ra, zero, sp
                  slti        gp, s5, -828
                  mulh        a6, s2, s0
                  c.xor       s0, a3
                  ori         a1, s11, -115
496:              auipc       s6, 154046
                  c.xor       a3, a0
                  c.addi      ra, -1
                  c.lui       s8, 31
                  srai        zero, t2, 31
                  srl         a2, sp, s7
                  slli        a5, a0, 24
                  slti        t2, ra, 505
                  nop
                  ori         tp, t4, 941
                  nop
                  c.srai      a3, 12
                  srai        s0, t1, 13
                  or          a0, a2, s7
                  slti        zero, zero, -915
                  srl         t4, s4, s0
                  c.li        a0, 9
                  rem         s7, s1, s11
                  auipc       a7, 296349
                  c.addi4spn  s0, sp, 384
                  xori        a7, t5, -758
                  ori         s2, a3, -1546
                  xori        t3, zero, 367
                  mulh        a0, a2, t5
                  ori         s6, s9, 1740
                  lui         s5, 511010
                  c.srai      a1, 7
                  auipc       a0, 705692
                  or          a7, a3, s3
                  c.mv        gp, s7
                  sltu        a7, a1, a0
                  bgeu        a2, t3, 538f
                  c.add       a5, s7
                  c.xor       s0, a2
                  rem         t3, a7, t2
                  addi        t1, t3, 1821
                  nop
                  lui         t5, 736128
                  blt         ra, s7, 535f
535:              c.or        a2, a3
                  c.nop
                  sll         s10, s10, s3
538:              beq         s9, s2, 543f
                  c.mv        a7, s2
                  sll         a3, s5, s7
                  c.nop
                  mulh        zero, s9, s7
543:              blt         a2, a7, 550f
                  c.bnez      s0, 550f
                  c.add       ra, tp
                  mul         t5, s10, a0
                  c.nop
                  bgeu        s10, s4, 550f
                  auipc       s10, 602168
550:              rem         s0, a3, s10
                  slt         tp, a3, t6
                  mul         a1, t4, s10
                  sltiu       a1, s8, 493
                  bge         a0, a2, 560f
                  c.addi16sp  sp, 144
                  sltu        t5, a4, gp
                  c.beqz      s0, 569f
                  nop
                  nop
560:              slti        s8, a2, -1686
                  rem         s11, s2, s9
                  srli        s6, s5, 28
                  div         t4, a0, s4
                  c.addi      tp, 2
                  sltiu       s5, t0, -1399
                  slt         t1, s0, gp
                  auipc       zero, 735908
                  slti        t2, t0, 1540
569:              bne         gp, zero, 577f
                  slli        s4, s4, 21
                  c.addi4spn  a3, sp, 496
                  xor         a2, a5, zero
                  slli        s8, a5, 14
                  andi        t1, ra, -1689
                  mulhsu      t1, a0, a2
                  c.addi16sp  sp, 304
577:              slt         s10, a6, t5
                  sltu        sp, s2, s11
                  slti        t5, t6, -463
                  c.andi      a2, -1
                  srai        t5, t3, 24
                  c.nop
                  mulhsu      a0, t5, a7
                  bne         s7, s2, 597f
                  c.li        s3, 30
                  mulhu       s5, a5, s1
                  nop
                  slt         a0, s5, s10
                  c.add       a3, a6
                  mulhu       s3, s5, s11
                  c.xor       a0, a3
                  div         ra, s6, s3
                  mul         s6, gp, a4
                  c.beqz      s0, 606f
                  slt         a7, gp, s1
                  blt         s6, a7, 615f
597:              mulh        a6, s3, a7
                  div         t1, s10, s3
                  blt         a4, t3, 607f
                  c.addi16sp  sp, 80
                  xor         a0, t6, s6
                  bne         zero, t4, 609f
                  blt         a2, a1, 615f
                  mulh        t3, a6, a2
                  c.xor       a0, s1
606:              c.and       a0, s1
607:              c.addi      a0, 28
                  bltu        s0, t6, 612f
609:              ori         a3, s8, -346
                  xor         zero, a2, t3
                  c.srai      s0, 16
612:              slti        a7, gp, 1158
                  srl         zero, s2, s10
                  blt         s5, t5, 615f
615:              sra         s3, a4, gp
                  sub         a0, s5, ra
                  c.beqz      a0, 621f
                  sra         t3, t2, ra
                  sltu        zero, a7, s0
                  xori        a5, t2, 462
621:              mulh        a6, a5, a5
                  srl         s9, t2, a1
                  c.li        t3, -1
                  bgeu        s3, tp, 634f
                  and         t0, s5, s5
                  mul         s10, tp, gp
                  mulhsu      tp, a1, t6
                  addi        s2, t5, 15
                  c.srli      a2, 6
                  bge         t6, s8, 646f
                  sltu        ra, s8, t2
                  c.nop
                  andi        a5, a5, 1355
634:              c.lui       s11, 26
                  c.xor       a0, a1
                  c.li        tp, 20
                  c.and       s0, s0
                  andi        t3, a7, -1407
                  srl         sp, s6, a7
                  srai        t3, t5, 7
                  c.li        s11, 29
                  or          s3, s5, s4
                  c.li        a0, -1
                  auipc       s4, 447846
                  xor         t3, a6, a1
646:              c.add       t3, s10
                  c.beqz      a5, 649f
                  c.addi      s10, 4
649:              sub         sp, t1, t5
                  c.nop
                  sub         s11, a2, s11
                  srl         s7, t2, sp
                  c.nop
                  srli        s11, s2, 12
                  rem         a7, t3, a5
                  rem         t5, ra, a7
                  c.andi      a0, -1
                  beq         zero, s9, 660f
                  bne         a1, a3, 664f
660:              slti        tp, s11, 1673
                  c.nop
                  sltu        zero, a7, a1
                  ori         tp, a7, -1909
664:              c.andi      a1, -1
                  srai        t2, s0, 12
                  c.andi      a1, -1
                  c.addi4spn  a3, sp, 416
                  nop
                  c.addi      a3, -1
                  c.slli      ra, 2
                  c.li        s7, 28
                  c.addi16sp  sp, 320
                  xori        a2, a4, 1407
                  blt         t5, a1, 680f
                  sra         a0, s4, s9
                  c.li        t3, 28
                  slli        s8, t0, 16
                  sra         ra, a0, s0
                  addi        zero, t4, -84
680:              slli        t5, a1, 10
                  slt         ra, s5, t0
                  sll         ra, tp, s9
                  slli        s11, gp, 0
                  auipc       a7, 510254
                  c.addi      t0, 20
                  c.addi4spn  a0, sp, 464
                  mulhu       zero, a4, s0
                  lui         s4, 437335
                  c.mv        ra, t4
                  divu        s11, t1, s11
                  div         t2, s2, s9
                  sra         t5, s5, t3
                  slli        t0, s9, 7
                  srli        zero, t1, 21
                  c.andi      a3, 23
                  slti        s11, s3, 53
                  c.and       a1, a5
                  c.add       s2, s7
                  addi        s5, a4, -881
                  c.li        sp, 31
                  c.addi4spn  a0, sp, 96
                  rem         s0, a2, s6
                  divu        zero, s11, sp
                  sltiu       a7, s2, 1346
                  add         t5, t0, s1
                  bgeu        t4, a2, 712f
                  mul         s0, a3, s4
                  c.mv        a5, s8
                  c.and       a2, a3
                  div         s11, a3, ra
                  srli        s8, a6, 7
712:              c.srai      a2, 25
                  c.beqz      s0, 718f
                  mulhsu      a1, t2, t1
                  divu        a0, sp, s8
                  c.bnez      a1, 717f
717:              mul         s5, s4, sp
718:              xori        s2, s3, 1220
                  div         a2, s0, t2
                  c.srli      a3, 23
                  div         t5, a1, a1
                  sltu        a2, s6, a4
                  slli        t2, s9, 9
                  mul         a5, s2, a1
                  sll         t1, t1, s5
                  add         sp, s8, s5
                  c.slli      t1, 19
                  bltu        s1, a6, 741f
                  srli        s11, a7, 7
                  c.addi      a6, 22
                  ori         gp, a3, 318
                  sltu        gp, t6, s2
                  sltiu       s11, s2, 1952
                  sll         t3, t4, a3
                  mul         t5, a1, s6
                  c.slli      t5, 28
                  and         t1, a6, s4
                  add         zero, zero, t0
                  lui         a2, 313877
                  bge         s8, s6, 752f
741:              c.addi16sp  sp, -16
                  mulhsu      gp, sp, s5
                  slti        s11, s5, 1611
                  srai        s0, a2, 6
                  ori         sp, s7, 242
                  andi        s5, a3, -767
                  lui         a5, 102926
                  rem         s8, a0, s0
                  sll         a6, s4, t3
                  blt         t6, a0, 754f
                  c.nop
752:              c.mv        t4, s1
                  slt         t3, s3, a3
754:              mul         a7, t0, s5
                  lui         s11, 942910
                  andi        tp, s6, 1668
                  c.addi16sp  sp, -16
                  auipc       s11, 824975
                  or          s8, ra, s2
                  c.lui       s3, 13
                  c.addi      s10, 24
                  c.lui       s4, 27
                  c.lui       ra, 6
                  sra         t4, s6, s4
                  bge         t2, t3, 781f
                  sltu        a2, s11, a4
                  bgeu        t5, t1, 778f
                  c.lui       t0, 16
                  addi        ra, s7, -1014
                  c.addi16sp  sp, 80
                  slti        t4, s2, -1319
                  bge         s6, sp, 774f
                  bne         s8, a7, 778f
774:              slt         s2, s8, s8
                  c.mv        a0, a3
                  c.or        a3, a1
                  c.add       a5, t2
778:              c.bnez      a0, 788f
                  slli        a2, gp, 30
                  srl         s4, zero, s4
781:              mulhsu      a1, t4, s0
                  mulhu       a0, t5, a4
                  slt         a7, sp, a1
                  c.addi4spn  a0, sp, 480
                  sra         zero, s11, t6
                  bgeu        t5, a1, 794f
                  c.nop
788:              c.andi      a0, 2
                  andi        sp, zero, -977
                  bltu        s9, a4, 792f
                  bltu        sp, a5, 799f
792:              c.add       s7, t0
                  srai        zero, a6, 19
794:              c.addi16sp  sp, 416
                  or          s4, s7, t4
                  sltiu       zero, a0, -1177
                  blt         a1, s3, 799f
                  nop
799:              xor         s0, t3, tp
                  c.lui       gp, 25
                  mul         t4, gp, s10
                  bge         a0, s8, 806f
                  c.slli      a1, 6
                  blt         t4, t6, 806f
                  c.or        a3, a1
806:              bne         t4, s5, 807f
807:              slli        zero, t5, 7
                  slli        s4, s6, 1
                  c.nop
                  c.addi      ra, -1
                  bltu        s2, s11, 821f
                  c.andi      a3, -1
                  c.addi      t5, -1
                  c.or        a0, a5
                  c.bnez      a3, 822f
                  add         t3, t0, t5
                  mulh        t0, s6, s8
                  divu        s6, a6, zero
                  c.sub       a3, a1
                  mul         tp, a1, a4
821:              addi        t0, t6, -445
822:              c.addi      t5, -1
                  c.lui       s2, 14
                  mulhu       s11, a5, s2
                  c.lui       a5, 9
                  sltiu       s4, s5, 900
                  nop
                  or          s11, t6, t4
                  c.mv        a0, s3
                  slt         a3, t3, s0
                  srai        s3, t3, 22
                  bltu        s9, s2, 839f
                  divu        zero, ra, s9
                  xori        s8, s7, -861
                  c.addi4spn  a0, sp, 944
                  sltu        s9, t0, s8
                  lui         sp, 70319
                  mulh        a1, s3, s1
839:              c.and       a1, a1
                  sra         s5, t2, a3
                  c.srli      a0, 25
                  sub         s2, s4, s2
                  c.mv        tp, tp
                  sra         s8, s2, sp
                  or          s11, ra, t0
                  mulhsu      t1, a2, ra
                  nop
                  blt         s4, a4, 860f
                  bne         gp, t2, 861f
                  c.addi16sp  sp, -16
                  rem         ra, s6, sp
                  c.addi16sp  sp, -16
                  bge         s2, s6, 859f
                  c.mv        a0, s0
                  c.slli      s4, 18
                  ori         gp, a3, 606
                  bne         t5, t1, 876f
                  mulhsu      zero, s4, a6
859:              and         zero, zero, zero
860:              c.srli      a5, 27
861:              slli        zero, s3, 22
                  sub         a5, a2, a7
                  slli        s7, t5, 4
                  c.beqz      a0, 871f
                  slt         a6, zero, s5
                  mul         t3, s3, t0
                  bltu        a0, s11, 875f
                  c.or        a3, a3
                  sll         s5, s4, tp
                  or          t2, s1, zero
871:              c.addi4spn  a3, sp, 720
                  c.xor       a1, a2
                  divu        gp, a3, tp
                  bltu        s2, a0, 884f
875:              c.or        a2, a0
876:              mul         sp, s1, s5
                  bge         s10, t6, 883f
                  c.xor       a0, a0
                  lui         a7, 315015
                  mul         tp, a7, sp
                  c.lui       s5, 4
                  auipc       ra, 41208
883:              xori        a5, a7, -226
884:              beq         s3, t6, 889f
                  c.or        a3, a3
                  c.andi      a0, 30
                  bltu        t0, a3, 895f
                  slti        a1, a6, -922
889:              c.srai      s0, 24
                  rem         s8, s1, ra
                  c.srli      a5, 23
                  bge         a0, a3, 894f
                  sltu        tp, a5, s7
894:              beq         gp, a1, 901f
895:              c.li        s5, -1
                  blt         a6, tp, 906f
                  ori         t1, s0, -1216
                  andi        s10, s11, -35
                  rem         sp, t0, s0
                  c.slli      s2, 3
901:              slt         a3, s3, t6
                  andi        s0, s10, 1050
                  c.beqz      a1, 919f
                  blt         a4, s0, 911f
                  slti        t0, s1, 741
906:              ori         s2, t4, -670
                  add         s7, tp, s6
                  sltu        a6, s1, zero
                  c.mv        sp, t5
                  mul         s9, t4, a7
911:              blt         sp, s8, 923f
                  c.or        a0, a3
                  c.andi      a2, -1
                  or          s6, gp, sp
                  c.srli      a0, 20
                  beq         s10, tp, 922f
                  slti        s6, s3, 900
                  srli        sp, a4, 13
919:              xori        t3, t6, 77
                  xori        s0, a7, -413
                  blt         zero, sp, 925f
922:              srl         gp, a4, tp
923:              c.addi      s10, -1
                  c.andi      s0, -1
925:              mulh        t2, ra, s8
                  c.add       t0, t2
                  c.lui       s10, 24
                  c.beqz      a0, 941f
                  bne         s10, t1, 931f
                  ori         s6, t5, 44
931:              c.srai      a1, 5
                  lui         s4, 635076
                  rem         a3, t6, s0
                  sltiu       a3, s5, 1733
                  c.addi16sp  sp, 192
                  c.addi4spn  s0, sp, 272
                  xori        s2, t2, -1013
                  add         zero, ra, s10
                  c.andi      a0, 0
                  sltu        t3, s0, a2
941:              andi        s10, a4, 494
                  nop
                  divu        s4, a0, s7
                  bne         ra, a7, 946f
                  c.lui       tp, 5
946:              c.andi      s0, 0
                  mulhu       s4, t4, t6
                  lui         zero, 487208
                  add         a3, s1, a3
                  ori         s2, t1, 1570
                  slli        s7, sp, 24
                  mulh        a7, s0, a1
                  beq         t3, a5, 957f
                  c.addi      s3, 26
                  or          s2, zero, s9
                  c.li        s8, -1
957:              c.li        a5, 15
                  c.slli      t4, 17
                  c.xor       a1, a4
                  bge         s0, a6, 966f
                  or          a1, s10, a3
                  bne         s2, a3, 970f
                  c.addi4spn  a2, sp, 240
                  sra         tp, a7, t2
                  auipc       a6, 1021067
966:              bne         a7, t2, 978f
                  sra         s4, s8, s9
                  mul         s3, t0, t1
                  c.mv        a6, ra
970:              slti        s11, s8, 1512
                  sll         a5, s1, zero
                  lui         s10, 48059
                  divu        tp, s7, t5
                  c.or        a0, a3
                  mulhsu      tp, s11, s10
                  slli        s5, s11, 15
                  srai        a1, a2, 31
978:              mulh        s3, t4, sp
                  slli        ra, s9, 2
                  c.nop
                  beq         s10, t1, 988f
                  c.add       s10, s8
                  c.or        a3, a1
                  addi        ra, t1, 1522
                  srai        ra, a3, 23
                  c.and       a0, a5
                  bgeu        ra, s10, 1006f
988:              srai        a6, t5, 11
                  bge         a3, a3, 990f
990:              c.andi      a3, -1
                  bne         t0, gp, 996f
                  bltu        s10, gp, 1004f
                  mulhu       sp, s1, t2
                  div         s8, t6, gp
                  c.srai      a0, 21
996:              beq         a1, s4, 1007f
                  beq         ra, s2, 998f
998:              srai        zero, t3, 5
                  c.nop
                  c.andi      a3, 17
                  slli        s2, s7, 2
                  c.slli      s2, 23
                  rem         zero, a6, a6
1004:             mul         a0, t2, s5
                  nop
1006:             mulhsu      a7, a4, sp
1007:             xori        a0, s4, 1369
                  c.li        s4, 7
                  c.lui       a2, 4
                  or          t1, a6, a4
                  c.mv        s0, s1
                  sra         a5, s8, s11
                  sltu        s3, s2, s9
                  mulh        s8, s7, a1
                  c.xor       a0, s1
                  slli        s5, s10, 11
                  slli        zero, t3, 13
                  add         zero, s0, s9
                  or          s11, s4, s9
                  slti        s8, t1, -227
                  c.addi4spn  a0, sp, 480
                  mul         a7, a0, s11
                  c.add       t3, t5
                  srli        zero, s7, 2
                  addi        t4, a4, 1036
                  bge         t3, sp, 1032f
                  c.addi      a3, 23
                  sll         zero, s10, s11
                  c.and       a0, a3
                  c.lui       t3, 26
                  c.addi16sp  sp, -16
1032:             andi        ra, a7, -128
                  c.addi      t3, 16
                  c.bnez      a3, 1040f
                  rem         s10, a5, s2
                  rem         t0, s10, a0
                  nop
                  c.nop
                  c.andi      a3, -1
1040:             or          zero, a3, a5
                  bge         zero, t2, 1051f
                  c.xor       a3, s0
                  c.beqz      a1, 1045f
                  c.andi      a3, 25
1045:             c.bnez      a2, 1053f
                  sltiu       zero, sp, 1966
                  rem         tp, t6, zero
                  c.srli      a3, 20
                  srl         gp, a0, gp
                  srai        a7, s4, 13
1051:             auipc       t0, 774568
                  mulh        s5, a7, ra
1053:             or          a0, s1, t4
                  c.sub       a0, a0
                  c.beqz      a0, 1065f
                  c.addi16sp  sp, -16
                  c.mv        a5, a6
                  div         zero, t2, s7
                  andi        zero, t5, 690
                  c.li        gp, 28
                  slli        s3, s3, 7
                  xori        zero, s1, -1440
                  xor         zero, s4, zero
                  c.addi      s9, -1
1065:             c.lui       t3, 4
                  mulh        a7, a3, t1
                  bltu        a2, a0, 1077f
                  bltu        a4, s5, 1080f
                  addi        zero, zero, -858
                  sltiu       zero, t1, -1211
                  c.li        s9, -1
                  mul         s11, tp, a6
                  sltu        zero, s3, zero
                  c.add       ra, t6
                  srl         tp, a5, tp
                  c.or        a5, a4
1077:             mul         t3, t4, gp
                  slli        a3, s2, 21
                  bgeu        a1, s7, 1092f
1080:             c.addi4spn  a3, sp, 480
                  nop
                  bltu        t3, s7, 1088f
                  c.addi16sp  sp, -16
                  c.beqz      a3, 1090f
                  slli        a5, t5, 17
                  beq         s10, t5, 1094f
                  mulhu       t3, t0, s1
1088:             slt         s4, a4, s7
                  sltiu       s10, s1, -1588
1090:             rem         t4, gp, a0
                  add         a7, t5, a7
1092:             nop
                  mul         t2, s5, t3
1094:             bge         a6, s7, 1104f
                  c.xor       a0, a2
                  c.mv        ra, ra
                  c.beqz      s0, 1101f
                  blt         s10, a7, 1105f
                  c.srli      a0, 12
                  xori        a5, s10, -661
1101:             c.srli      a3, 7
                  c.mv        tp, s2
                  c.nop
1104:             srai        s3, a7, 6
1105:             c.add       a5, s4
                  xori        a3, t4, -1161
                  c.andi      a3, -1
                  bgeu        gp, s3, 1110f
                  bltu        ra, zero, 1111f
1110:             c.and       a3, a0
1111:             c.and       a1, a4
                  srai        gp, s0, 22
                  sltiu       t4, zero, 287
                  ori         zero, s10, 1030
                  addi        gp, ra, -54
                  add         tp, s3, s11
                  c.sub       a3, a2
                  mulhu       a0, s8, a2
                  bge         t4, t4, 1124f
                  c.nop
                  bge         s2, t5, 1128f
                  xori        zero, s5, -1842
                  slli        tp, s1, 15
1124:             c.slli      ra, 2
                  bne         a4, s5, 1126f
1126:             xori        gp, s10, -1408
                  sltiu       s6, ra, -721
1128:             c.sub       s0, s0
                  rem         a1, a7, t0
                  slli        s5, a3, 9
                  c.add       s0, s7
                  blt         zero, s6, 1139f
                  or          zero, tp, t2
                  auipc       s9, 471547
                  bltu        s2, tp, 1147f
                  c.srai      a2, 31
                  c.or        a3, a3
                  sltiu       zero, s4, -783
1139:             mulhu       a3, t2, t2
                  add         a1, t0, a4
                  sra         t4, a1, t1
                  c.lui       s5, 10
                  add         t5, s0, t4
                  c.mv        t5, a3
                  slli        s6, a4, 5
                  slti        t4, a1, 369
1147:             slli        ra, a7, 22
                  mulh        t1, s5, a1
                  bltu        zero, t0, 1151f
                  sub         t5, t6, t4
1151:             bltu        s8, a2, 1163f
                  c.andi      s0, 1
                  rem         zero, a6, a7
                  or          s11, s4, s11
                  mulhu       s7, s2, a7
                  bltu        t0, s1, 1160f
                  c.addi4spn  a0, sp, 816
                  c.or        a1, a0
                  addi        s7, a7, 1865
1160:             slli        zero, s10, 15
                  c.addi      tp, -1
                  srli        s3, s9, 26
1163:             mulh        a2, s1, a7
                  c.srai      a1, 3
                  lui         t4, 787694
                  nop
                  c.xor       a3, a0
                  divu        t4, t1, s5
                  c.mv        a0, s9
                  slli        zero, s9, 13
                  lui         zero, 996517
                  divu        s7, gp, s9
                  c.or        a3, s1
                  div         a3, s3, tp
                  srai        s6, s6, 7
                  c.li        ra, -1
                  ori         a1, a4, 961
                  c.li        a2, -1
                  sll         a6, a2, zero
                  rem         ra, t0, s1
                  auipc       a1, 557088
                  srl         gp, s11, t0
                  and         a1, tp, s10
                  c.addi      s10, -1
                  mul         s10, a3, gp
                  add         a2, s11, a4
                  slt         t5, t5, a4
                  c.bnez      a3, 1196f
                  c.srai      a1, 8
                  or          t2, t6, a2
                  c.mv        a2, t6
                  divu        tp, sp, s0
                  nop
                  c.srai      a0, 7
                  xori        s8, t5, 142
1196:             srli        tp, t0, 22
                  srl         zero, sp, s7
                  addi        s7, a4, 499
                  c.li        s0, -1
                  c.li        t1, 12
                  mulhsu      a1, zero, s8
                  c.mv        t0, s2
                  xor         t0, tp, ra
                  srli        t1, a5, 23
                  c.and       a0, a0
                  c.and       a0, a2
                  add         s6, ra, s3
                  slt         s6, a1, t3
                  lui         gp, 642445
                  mul         a0, s11, sp
                  srai        s9, s2, 16
                  mulh        a3, t5, s1
                  slti        t0, t5, -473
                  sltiu       a1, t0, 983
                  c.mv        ra, s11
                  srl         tp, gp, s4
                  c.lui       t1, 1
                  c.nop
                  lui         t3, 929075
                  blt         a0, t5, 1225f
                  lui         a2, 244446
                  mulhu       gp, s8, zero
                  mulhu       zero, a6, a5
                  divu        s0, s5, s7
1225:             bne         sp, s2, 1227f
                  bge         a0, ra, 1232f
1227:             c.add       s0, a7
                  c.xor       a1, a1
                  mulh        s5, s5, sp
                  xori        s3, gp, 796
                  xor         t4, s8, a4
1232:             add         t0, t6, tp
                  sltu        ra, t0, gp
                  divu        a6, a2, gp
                  c.addi      s11, 11
                  lui         t0, 280887
                  slt         t2, tp, a4
                  c.srli      a2, 4
                  bltu        t0, ra, 1247f
                  c.slli      s10, 22
                  nop
                  c.bnez      a2, 1253f
                  c.beqz      s0, 1253f
                  c.srli      a1, 30
                  andi        t0, s4, -1605
                  nop
1247:             c.and       s0, s0
                  addi        zero, s7, 1863
                  c.and       a2, s1
                  andi        a0, t5, 1432
                  c.lui       t5, 12
                  or          a1, s4, a2
1253:             div         t1, s9, a2
                  sltiu       s7, s7, -541
                  c.add       t2, gp
                  sll         a3, s9, s11
                  c.andi      a0, -1
                  mul         ra, tp, t0
                  c.bnez      s0, 1265f
                  c.bnez      a1, 1279f
                  lui         t1, 386921
                  divu        s5, a6, s10
                  c.addi      ra, 10
                  sll         t0, s3, ra
1265:             beq         s6, a1, 1266f
1266:             blt         s8, s9, 1282f
                  blt         s10, a6, 1275f
                  andi        a3, t4, -1997
                  c.sub       a1, a3
                  c.xor       s0, a1
                  c.srai      a3, 2
                  blt         t5, t1, 1273f
1273:             divu        t1, a4, t5
                  slt         a6, t0, t2
1275:             sub         zero, a0, a1
                  auipc       a3, 944283
                  c.slli      ra, 1
                  bltu        tp, a6, 1286f
1279:             c.srli      a3, 27
                  srli        a3, s4, 24
                  c.li        t5, -1
1282:             mulhu       a0, t0, a4
                  sub         t5, a2, t6
                  blt         a6, a5, 1292f
                  srli        t0, tp, 28
1286:             slli        a2, s6, 0
                  sltiu       s6, s10, -1010
                  nop
                  c.xor       a0, s1
                  mulhu       s9, zero, a4
                  c.lui       s6, 12
1292:             c.xor       a0, a0
                  or          a0, s8, gp
                  c.addi4spn  a1, sp, 176
                  auipc       sp, 120460
                  ori         s8, s2, 604
                  sltu        gp, a7, s9
                  lui         t1, 48168
                  slti        s2, a4, -1056
                  mulhsu      s10, s8, s11
                  ori         t1, a6, 1922
                  c.srli      a1, 28
                  c.and       s0, a2
                  c.lui       s7, 1
                  c.xor       a2, a1
                  c.or        a0, a3
                  slti        t3, s3, -385
                  slt         zero, a3, a1
                  mulh        s5, a2, s7
                  c.andi      a0, 24
                  rem         t5, s7, ra
                  c.nop
                  c.xor       s0, a2
                  xori        tp, s8, -779
                  c.srai      s0, 26
                  divu        s11, s9, s9
                  mulhsu      zero, s4, t6
                  rem         zero, t6, ra
                  sltu        t1, s2, a1
                  sll         zero, t0, s5
                  add         t3, s9, t3
                  c.addi16sp  sp, -16
                  bge         a5, s1, 1335f
                  slli        a6, s6, 2
                  divu        a7, zero, tp
                  c.slli      t0, 27
                  c.lui       s3, 24
                  srli        s0, t1, 13
                  c.srli      a3, 25
                  auipc       s6, 1045359
                  addi        ra, ra, -1340
                  c.xor       a2, a4
                  blt         s8, s9, 1339f
                  or          gp, a2, s1
1335:             c.li        a6, -1
                  srai        t4, t1, 7
                  slli        s5, s3, 17
                  sll         t0, s6, tp
1339:             mulhu       a6, t4, a7
                  lui         s4, 13344
                  srl         a6, gp, a7
                  xor         t3, a2, s10
                  slti        t3, s0, 1943
                  div         a2, s9, s8
                  ori         s0, a2, -661
                  andi        s3, sp, 1981
                  c.xor       a2, a0
                  bgeu        t6, t2, 1361f
                  sub         s9, s6, a2
                  c.nop
                  div         a0, s4, a3
                  c.xor       a0, a0
                  sltiu       zero, a3, 681
                  c.slli      a2, 3
                  divu        s4, t5, a2
                  srl         s3, a0, s5
                  c.slli      s11, 15
                  c.or        a0, a0
                  xor         s11, a5, t1
                  sub         a3, sp, t3
1361:             bne         tp, a5, 1362f
1362:             c.sub       a3, a1
                  bgeu        s1, a3, 1367f
                  c.and       a0, s0
                  srai        s11, tp, 26
                  mulhsu      zero, s4, a4
1367:             lui         s0, 717756
                  andi        s7, a2, -1548
                  sra         a0, t4, a1
                  bgeu        s7, t2, 1380f
                  bltu        gp, s7, 1376f
                  and         a2, a2, a4
                  xori        s2, gp, 1595
                  sub         a3, s8, s6
                  slti        zero, a0, -328
1376:             mul         t5, s0, s9
                  andi        t0, sp, 4
                  divu        t1, s10, a1
                  mul         zero, a1, gp
1380:             c.xor       a2, a0
                  blt         a3, t3, 1387f
                  c.bnez      a0, 1392f
                  bgeu        gp, a6, 1385f
                  c.slli      a2, 7
1385:             c.beqz      s0, 1390f
                  ori         s3, s8, 1220
1387:             c.mv        a3, s6
                  div         zero, a5, gp
                  rem         tp, s10, s7
1390:             c.xor       a0, a0
                  c.mv        a7, s2
1392:             c.addi16sp  sp, 464
                  sltu        t5, s1, a1
                  c.slli      ra, 13
                  beq         s7, a7, 1397f
                  xor         s7, s10, ra
1397:             mulh        a7, s4, tp
                  mul         tp, a4, s0
                  c.slli      a5, 21
                  bne         ra, t4, 1407f
                  xori        a1, s2, 853
                  bltu        t1, a1, 1404f
                  mulh        zero, s3, s10
1404:             rem         zero, s10, s7
                  bge         s5, gp, 1411f
                  mulhu       s11, s3, s3
1407:             and         a7, t4, a3
                  c.srli      a0, 26
                  add         s5, a3, s9
                  add         s4, s4, a5
1411:             mulh        s5, t6, s6
                  c.addi      s7, 3
                  addi        gp, a7, -1287
                  srai        tp, s10, 0
                  slt         sp, a4, s6
                  andi        s11, s3, -1309
                  c.srli      a3, 10
                  c.beqz      a3, 1424f
                  srai        s3, a1, 11
                  c.nop
                  c.nop
                  c.xor       a0, a1
                  andi        s11, s11, -912
1424:             c.srai      a3, 28
                  slt         s2, a7, tp
                  c.and       a0, a2
                  sub         a6, a7, tp
                  and         t3, tp, t0
                  c.slli      s0, 16
                  c.xor       a5, a5
                  srli        s9, s3, 16
                  addi        zero, s11, -1816
                  sltu        zero, s1, t5
                  divu        s9, s4, a4
                  sltiu       a2, s4, 725
                  bltu        ra, s11, 1448f
                  divu        tp, tp, s2
                  c.nop
                  blt         s6, zero, 1451f
                  c.xor       a0, a3
                  srl         s11, t2, s7
                  c.mv        ra, a1
                  c.and       a3, a1
                  ori         zero, t2, -1520
                  c.lui       a0, 12
                  c.li        ra, 24
                  sra         s10, a2, t3
1448:             add         s6, s2, s6
                  slti        s0, a1, -1888
                  sltu        sp, t1, s10
1451:             c.andi      a1, 23
                  c.add       s7, t0
                  bne         s8, t3, 1457f
                  bne         gp, s8, 1461f
                  rem         zero, t0, a4
                  mul         tp, a4, a5
1457:             c.srli      a3, 10
                  nop
                  mulhsu      gp, s6, s6
                  bltu        s6, a3, 1470f
1461:             andi        s7, a0, 279
                  sltu        s4, s11, a3
                  bne         s10, s4, 1479f
                  c.mv        a0, s8
                  nop
                  mulhu       t0, s3, s6
                  srli        zero, t4, 15
                  and         t3, s6, ra
                  nop
1470:             c.xor       a3, a0
                  bge         a4, t1, 1473f
                  c.addi4spn  a0, sp, 960
1473:             sub         gp, sp, t2
                  mulhsu      ra, a5, sp
                  c.addi16sp  sp, 448
                  c.bnez      a5, 1487f
                  c.or        a3, s0
                  c.li        s4, -1
1479:             addi        s8, t3, 1710
                  xor         s2, a6, s6
                  c.bnez      a2, 1488f
                  ori         a5, sp, -2027
                  mulh        s8, s4, s10
                  sub         s0, tp, sp
                  c.mv        s3, t3
                  slli        t0, s2, 12
1487:             mulh        s10, s10, t5
1488:             srl         s9, s8, a7
                  c.bnez      a2, 1508f
                  divu        s11, s5, a3
                  ori         a1, a5, -1816
                  blt         s4, a6, 1499f
                  ori         s10, s9, -480
                  addi        s3, sp, 1075
                  srl         a6, t6, t3
                  c.addi4spn  a0, sp, 400
                  c.mv        s3, t5
                  xor         t2, a1, s9
1499:             add         a3, s4, t4
                  c.and       a0, a3
                  sra         ra, s1, s3
                  sll         zero, s10, sp
                  slti        t3, s7, -1791
                  xori        zero, s1, 1421
                  bgeu        t4, s7, 1515f
                  c.nop
                  xori        ra, t0, 1070
1508:             c.addi4spn  a1, sp, 272
                  xori        t5, s6, 500
                  addi        a1, s4, -251
                  c.sub       a0, a3
                  sub         zero, a6, s9
                  div         s10, s0, s3
                  ori         s9, a6, 651
1515:             sltiu       t5, ra, -1647
                  c.add       a6, a7
                  c.mv        s0, a7
                  add         s9, s0, s3
                  c.add       ra, a3
                  c.beqz      a0, 1532f
                  c.srai      s0, 9
                  sltiu       zero, a2, 1230
                  c.mv        a3, s0
                  bgeu        t1, s9, 1525f
1525:             sub         zero, s4, s10
                  c.srli      a0, 13
                  and         sp, t2, a5
                  sll         s3, a3, a7
                  c.slli      t5, 29
                  sub         zero, t6, a3
                  auipc       a3, 510386
1532:             xori        t4, a3, 774
                  c.slli      s3, 22
                  lui         zero, 284743
                  c.addi16sp  sp, 96
                  c.and       a3, a1
                  and         s9, s6, t1
                  mul         s2, sp, t4
                  bltu        a7, a6, 1543f
                  sra         s5, a2, s6
                  c.and       a0, a2
                  addi        s11, s1, -1830
1543:             c.bnez      a5, 1553f
                  c.xor       a1, a2
                  c.li        gp, -1
                  mulhu       s10, zero, a5
                  nop
                  sltu        s3, s2, a0
                  srai        zero, ra, 5
                  c.addi      s3, 10
                  c.beqz      a1, 1557f
                  c.andi      a3, -1
1553:             slli        t3, t2, 29
                  sltiu       s5, a1, -1945
                  c.srli      a2, 6
                  c.beqz      a0, 1562f
1557:             add         a6, zero, a7
                  bge         a6, s0, 1568f
                  slt         t1, t6, a1
                  c.bnez      a3, 1571f
                  slli        a5, a1, 5
1562:             add         s11, t1, ra
                  c.or        s0, a0
                  andi        zero, zero, -1003
                  rem         s0, a4, t0
                  c.lui       s9, 9
                  sra         tp, s2, sp
1568:             sltiu       s10, s8, 1848
                  divu        a5, s9, t2
                  c.srai      a3, 20
1571:             c.addi4spn  a3, sp, 144
                  c.bnez      a0, 1574f
                  c.lui       gp, 21
1574:             sll         t5, s4, a7
                  slti        gp, ra, -969
                  c.mv        s2, t4
                  ori         s3, t2, 142
                  xori        tp, s5, 1884
                  c.lui       ra, 19
                  auipc       a1, 541501
                  andi        s4, sp, -566
                  mulh        a5, a4, ra
                  sltiu       ra, a6, -2017
                  c.srli      a1, 13
                  bgeu        gp, a7, 1591f
                  divu        s2, s5, t5
                  c.li        a5, 22
                  c.beqz      a0, 1590f
                  c.srai      a3, 21
1590:             c.beqz      a0, 1597f
1591:             c.sub       a1, a5
                  divu        s9, s8, s5
                  c.srai      a1, 20
                  beq         s7, s4, 1610f
                  mul         s7, sp, s4
                  mulhu       zero, a4, t6
1597:             sltu        a0, zero, s10
                  xor         t3, t5, t0
                  divu        zero, s11, s6
                  mulh        a6, s9, s4
                  auipc       s9, 293563
                  c.bnez      a1, 1604f
                  slti        s6, a3, 1361
1604:             c.li        ra, 31
                  mulhu       t5, s10, s10
                  c.lui       ra, 12
                  sub         s3, s3, a1
                  xori        s6, a7, -808
                  slli        t3, s6, 15
1610:             c.addi16sp  sp, -16
                  slti        zero, a3, -1248
                  sll         t3, s3, tp
                  bne         s8, s10, 1621f
                  divu        a2, t2, ra
                  sll         t2, s11, sp
                  xori        t3, t2, -40
                  c.srai      a0, 13
                  beq         s1, t6, 1626f
                  divu        t1, t1, a0
                  bge         s0, s2, 1632f
1621:             slli        t0, s5, 11
                  bltu        t2, t4, 1635f
                  c.nop
                  c.bnez      a2, 1628f
                  slli        zero, s7, 10
1626:             lui         s10, 509900
                  c.addi4spn  a0, sp, 448
1628:             srai        s2, a6, 27
                  c.addi16sp  sp, 320
                  slt         a6, t6, s1
                  slt         a3, tp, t2
1632:             add         sp, a7, t1
                  mulhu       s3, a4, a3
                  mulh        s10, t4, s7
1635:             slt         a3, sp, t3
                  c.srli      a1, 20
                  bge         a4, a0, 1642f
                  mulh        s11, a7, zero
                  nop
                  nop
                  c.addi16sp  sp, -16
1642:             blt         s4, t2, 1644f
                  c.li        s7, 9
1644:             xor         ra, s5, a4
                  bgeu        s4, a5, 1664f
                  sra         zero, s8, sp
                  xor         a7, a4, a0
                  lui         a0, 555142
                  bltu        t3, gp, 1656f
                  c.mv        s3, s7
                  srl         s6, t6, a7
                  auipc       s2, 705489
                  c.andi      a0, -1
                  srli        t5, s3, 2
                  sra         t5, t2, a3
1656:             sub         a2, t0, t5
                  rem         a0, t2, s4
                  mul         zero, t4, a0
                  addi        sp, a5, 1751
                  xor         t4, zero, tp
                  add         t1, a0, s8
                  c.addi      ra, 22
                  sltiu       a1, ra, 444
1664:             c.srli      a1, 13
                  c.xor       a0, a3
                  c.srai      a2, 5
                  mulhu       t4, s7, s11
                  c.add       ra, s9
                  mulh        s4, t3, s5
                  c.addi4spn  a1, sp, 240
                  sltu        s5, s1, t6
                  slti        zero, s4, -201
                  slt         a6, a2, a2
                  c.li        ra, -1
                  c.beqz      a3, 1683f
                  bgeu        a1, a7, 1682f
                  bge         s9, a4, 1678f
1678:             srai        a1, s4, 25
                  c.addi4spn  a0, sp, 240
                  mulh        tp, t6, s1
                  c.nop
1682:             srli        ra, s8, 5
1683:             nop
                  c.add       t4, s5
                  xori        s10, a0, -1520
                  c.and       s0, a2
                  c.sub       s0, a0
                  ori         tp, s3, -1230
                  mulh        s8, a3, gp
                  or          a3, a0, s9
                  andi        a2, a7, -539
                  c.addi16sp  sp, 480
                  slt         zero, ra, t1
                  c.addi      s2, -1
                  c.beqz      a1, 1700f
                  bltu        s6, s9, 1708f
                  c.addi      t1, 4
                  c.mv        ra, s0
                  c.addi16sp  sp, -16
1700:             slti        s11, sp, -19
                  slt         a3, zero, t1
                  div         a3, a7, s2
                  blt         zero, t3, 1722f
                  bgeu        t4, zero, 1709f
                  bltu        a7, a0, 1712f
                  c.or        s0, a3
                  sll         s9, s5, a2
1708:             c.addi4spn  a0, sp, 192
1709:             sltiu       a0, sp, 584
                  c.addi4spn  a2, sp, 416
                  andi        s0, t6, 1442
1712:             addi        t2, t1, 1526
                  c.addi      a0, -1
                  slli        a6, t0, 14
                  c.andi      a2, -1
                  srai        zero, t5, 18
                  andi        a5, a3, 1280
                  c.lui       gp, 31
                  rem         s3, a4, t2
                  slt         tp, t5, s11
                  c.bnez      a1, 1731f
1722:             c.add       t5, sp
                  beq         s2, ra, 1725f
                  srl         s7, sp, a7
1725:             sra         s0, zero, gp
                  mul         zero, a5, t5
                  c.mv        tp, a4
                  div         a0, a5, t1
                  c.add       s2, s11
                  slt         t5, s9, s7
1731:             sll         s4, s5, s8
                  c.bnez      s0, 1738f
                  c.xor       a0, a3
                  c.beqz      a3, 1736f
                  c.and       a2, a1
1736:             c.mv        sp, s1
                  c.addi16sp  sp, -16
1738:             c.srai      s0, 1
                  c.nop
                  andi        t3, t1, 350
                  beq         t6, a2, 1749f
                  c.slli      gp, 19
                  blt         t1, s6, 1755f
                  c.add       ra, a5
                  c.srli      a2, 10
                  xor         a3, t5, s4
                  c.srli      a3, 16
                  c.xor       a0, a2
1749:             c.add       a3, ra
                  c.and       a2, a3
                  c.andi      a2, -1
                  c.li        a3, -1
                  div         s6, t2, s7
                  slt         a0, t1, s4
1755:             bne         a7, t2, 1765f
                  c.lui       s3, 23
                  srli        t5, s1, 31
                  c.addi16sp  sp, 256
                  addi        s3, a0, -1624
                  sub         s11, s8, s5
                  c.addi16sp  sp, -16
                  slt         a1, s0, t6
                  c.mv        ra, a7
                  c.addi4spn  a2, sp, 800
1765:             c.and       a3, a0
                  div         a5, ra, s7
                  andi        s3, s2, -1942
                  sltu        a7, t0, a7
                  c.and       a3, s0
                  c.slli      s7, 26
                  mulhsu      s2, s3, s3
                  xori        t1, s8, -498
                  div         s2, t6, s5
                  bne         zero, t4, 1776f
                  addi        ra, a4, 301
1776:             andi        s6, a6, -311
                  nop
                  c.srai      a0, 30
                  xor         sp, a7, zero
                  bge         t6, t3, 1793f
                  addi        a7, ra, -1844
                  c.or        a3, a0
                  blt         a6, s4, 1790f
                  bgeu        a1, a4, 1785f
1785:             xor         a6, s9, t2
                  c.andi      s0, -1
                  divu        a6, a2, a1
                  c.srai      s0, 11
                  sub         s7, s4, a7
1790:             c.and       a2, a4
                  c.beqz      a1, 1797f
                  slli        s0, ra, 1
1793:             sra         s9, tp, s10
                  srl         s7, a0, a6
                  c.bnez      a1, 1806f
                  addi        a1, t1, 141
1797:             andi        s3, a7, 1479
                  slti        s3, a3, -1311
                  lui         s5, 904820
                  mul         a1, gp, a4
                  c.addi      s0, -1
                  bgeu        t5, s10, 1804f
                  slli        s11, t1, 0
1804:             andi        t0, t3, -1858
                  rem         s5, a3, s6
1806:             c.sub       s0, a0
                  c.add       sp, tp
                  mulhsu      zero, s11, tp
                  c.xor       a3, a1
                  sltiu       t0, a5, -1374
                  srli        s4, s9, 30
                  srli        a6, t0, 30
                  slt         a0, s7, s11
                  ori         zero, s7, -128
                  lui         t1, 198224
                  mulhsu      s11, t1, a5
                  c.lui       s9, 4
                  mulhsu      sp, s9, t1
                  c.sub       a1, a4
                  ori         t2, t3, -1447
                  c.li        ra, 5
                  c.beqz      a3, 1827f
                  c.srai      a0, 24
                  divu        t1, a3, s7
                  c.nop
                  sltiu       a6, t2, -1872
1827:             c.addi4spn  a1, sp, 208
                  add         a6, a0, a6
                  c.andi      a0, -1
                  beq         t3, s3, 1846f
                  mulhu       s7, t5, sp
                  sra         tp, t6, t1
                  c.or        a1, s1
                  c.nop
                  slli        zero, t0, 22
                  slti        t4, a6, -316
                  addi        t5, a3, 564
                  c.srli      a0, 1
                  rem         s10, s6, ra
                  c.nop
                  c.addi      t0, -1
                  c.lui       s2, 26
                  xor         s11, t1, s6
                  c.mv        s2, a2
                  andi        s6, a5, -1096
1846:             lui         ra, 523384
                  xori        s9, t1, 398
                  slli        s9, a3, 16
                  auipc       a1, 574388
                  div         s7, s6, a5
                  div         gp, a2, zero
                  srai        t3, a7, 22
                  c.or        a0, s1
                  slli        a1, a7, 15
                  c.addi      t3, 24
                  bgeu        zero, t6, 1862f
                  rem         a5, a6, s9
                  c.beqz      a1, 1866f
                  mulhsu      a7, s4, a6
                  c.srli      a2, 7
                  sub         zero, tp, a5
1862:             xor         s6, s3, s3
                  c.and       a3, a4
                  mul         a2, t6, gp
                  sub         a2, s6, s3
1866:             c.sub       a0, a2
                  mul         s5, s10, a2
                  rem         t1, gp, s8
                  addi        t5, s8, 847
                  andi        s7, s5, -1754
                  xori        s0, s6, -376
                  c.lui       a2, 26
                  c.beqz      a0, 1885f
                  c.mv        ra, a0
                  sltiu       s2, s6, -762
                  divu        s0, s3, s9
                  blt         s11, s10, 1881f
                  sll         s3, s7, s11
                  c.slli      ra, 10
                  srli        tp, zero, 31
1881:             c.bnez      s0, 1882f
1882:             mulh        t2, t5, t3
                  nop
                  nop
1885:             mulhsu      s10, t5, t4
                  srli        s8, a2, 3
                  rem         s10, a2, a0
                  or          a3, s11, s4
                  c.nop
                  c.bnez      s0, 1897f
                  srli        a6, t6, 13
                  mulhu       t5, s9, s8
                  beq         t4, a6, 1899f
                  or          sp, a0, sp
                  auipc       zero, 406559
                  slti        s4, t6, -552
1897:             mulhsu      t2, s8, a6
                  c.nop
1899:             c.addi4spn  a0, sp, 320
                  c.srai      a0, 21
                  c.srai      a2, 30
                  mulhu       a3, zero, a6
                  c.srai      a3, 16
                  mul         s5, ra, a4
                  c.lui       a3, 21
                  add         a7, a6, s6
                  or          t4, a0, s0
                  add         a3, tp, a1
                  srl         s0, a3, a1
                  c.addi      a3, 2
                  xori        s10, s7, -557
                  c.xor       a0, a3
                  bgeu        t1, a3, 1921f
                  blt         s10, sp, 1918f
                  nop
                  c.mv        t0, s8
                  c.srli      a0, 17
1918:             slti        zero, t0, 1599
                  c.slli      s3, 30
                  c.mv        t0, t1
1921:             andi        a5, t4, -109
                  add         tp, s0, zero
                  c.or        a2, a0
                  blt         a0, s9, 1936f
                  c.addi      gp, 21
                  mul         a5, t6, s9
                  andi        a5, s4, -937
                  c.addi4spn  a3, sp, 896
                  c.beqz      a3, 1939f
                  c.li        a5, -1
                  slti        s9, a7, 1046
                  mulhu       sp, t0, s0
                  rem         zero, s8, s3
                  c.addi4spn  a2, sp, 336
                  c.addi4spn  a0, sp, 304
1936:             beq         t5, a0, 1938f
                  c.or        a5, a0
1938:             bne         zero, a4, 1939f
1939:             c.srli      a0, 14
                  c.beqz      s0, 1952f
                  mulhsu      a7, s2, s10
                  srli        t1, t1, 12
                  andi        s6, a2, -641
                  c.xor       s0, a3
                  c.mv        a0, t0
                  c.srli      a3, 12
                  beq         t0, t0, 1963f
                  xori        a6, s10, -806
                  srli        s2, s5, 4
                  sub         a2, s2, a6
                  c.nop
1952:             sub         ra, t0, s5
                  lui         s4, 53897
                  sll         a5, a0, s3
                  lui         a0, 489297
                  c.li        s8, -1
                  c.mv        t5, s9
                  sltu        a1, a4, s5
                  sra         a6, s0, s3
                  lui         gp, 949204
                  beq         a6, t6, 1965f
                  sub         zero, s10, s1
1963:             bltu        s0, t6, 1968f
                  c.or        s0, a3
1965:             or          t4, s9, s3
                  and         s0, s7, sp
                  sub         a2, a2, s9
1968:             slli        s4, s6, 12
                  xori        gp, t1, 965
                  sra         a6, tp, t0
                  srai        t5, s7, 27
                  ori         sp, a1, 229
                  sll         s3, a1, t3
                  c.slli      a0, 21
                  bge         s4, a4, 1988f
                  or          s3, a3, s3
                  bltu        zero, a2, 1987f
                  and         gp, t5, a6
                  or          t2, t5, s11
                  sltu        s5, s1, zero
                  srai        s10, gp, 9
                  c.srai      a0, 19
                  sltiu       ra, sp, 1076
                  c.add       t3, sp
                  c.beqz      a2, 2004f
                  sltiu       t2, s8, 1775
1987:             c.andi      a0, -1
1988:             c.slli      sp, 12
                  lui         a1, 465828
                  c.srai      a0, 8
                  mulhsu      a0, s6, a5
                  bgeu        t2, t0, 1998f
                  mulhsu      s0, t4, tp
                  sra         t5, zero, sp
                  c.addi4spn  a0, sp, 192
                  xori        ra, a6, 1019
                  c.and       a3, a3
1998:             add         s10, ra, s2
                  bltu        s0, t5, 2010f
                  c.bnez      s0, 2010f
                  ori         s4, t4, -1357
                  blt         t3, s11, 2010f
                  srai        s10, s7, 14
2004:             bge         gp, s10, 2006f
                  c.addi4spn  a2, sp, 656
2006:             srl         gp, gp, tp
                  nop
                  or          t5, a5, a6
                  xor         a5, s6, s10
2010:             srl         t0, s6, s1
                  bne         a4, s2, 2017f
                  c.xor       a2, a3
                  div         zero, s3, ra
                  c.sub       a0, a0
                  sub         s5, s1, a3
                  slt         s6, s0, zero
2017:             and         s0, s7, s7
                  sltu        s6, s7, a1
                  c.addi16sp  sp, -16
                  c.sub       a1, a1
                  sll         s11, a2, s11
                  c.xor       a2, s0
                  div         t2, zero, a1
                  srai        a1, tp, 28
                  addi        ra, a7, -1568
                  divu        zero, s2, a2
                  auipc       s10, 201868
                  xor         s0, t2, t6
                  mul         gp, t2, gp
                  c.or        a2, a3
                  srl         t2, s9, s9
                  c.slli      s0, 27
                  srli        a2, t0, 5
                  c.and       a3, a3
                  sltu        s2, s5, a3
                  divu        a2, s5, ra
                  c.slli      s8, 4
                  c.beqz      s0, 2042f
                  blt         a1, t3, 2045f
                  and         a6, a5, ra
                  bltu        t5, a0, 2048f
2042:             addi        gp, s10, -16
                  c.sub       a5, s1
                  c.bnez      a1, 2046f
2045:             c.xor       a0, a1
2046:             c.addi      tp, 24
                  srli        s11, t6, 21
2048:             c.nop
                  bltu        t2, s3, 2056f
                  bge         t3, s0, 2058f
                  c.bnez      s0, 2053f
                  c.andi      s0, 31
2053:             c.srli      a2, 18
                  c.and       a0, a1
                  sra         a2, a1, a5
2056:             sltiu       s11, s11, -1331
                  c.or        a0, a0
2058:             xori        s9, a3, -563
                  c.addi4spn  a0, sp, 736
                  c.nop
                  srli        tp, a5, 18
                  nop
                  c.xor       a0, a0
                  c.xor       a2, a1
                  slt         s7, a7, sp
                  slli        tp, a6, 6
                  c.mv        s5, sp
                  rem         tp, s1, t1
                  srl         s6, a2, s11
                  srai        t1, a4, 28
                  c.addi16sp  sp, 432
                  add         s5, zero, ra
                  c.add       s10, s8
                  lui         tp, 261330
                  bgeu        s5, t3, 2087f
                  c.li        t0, -1
                  bge         t6, a6, 2084f
                  addi        gp, t3, -1610
                  sub         t0, t0, s9
                  add         tp, t6, s7
                  lui         s10, 483314
                  c.bnez      a3, 2094f
                  c.andi      s0, 14
2084:             c.addi4spn  a3, sp, 592
                  slti        t4, s5, -222
                  mul         s4, t2, s2
2087:             mulhsu      s4, s8, t5
                  and         s8, t1, t3
                  mul         zero, tp, s11
                  beq         a6, a2, 2095f
                  srli        s6, t0, 26
                  c.srli      a1, 30
                  c.lui       ra, 26
2094:             c.nop
2095:             andi        zero, t4, 146
                  blt         a2, a3, 2102f
                  mul         s4, t5, a0
                  or          s5, s4, s6
                  c.srli      s0, 22
                  sltu        t4, s9, s7
                  andi        a6, s10, 111
2102:             xori        t5, a3, 1318
                  c.lui       a6, 6
                  c.srli      a3, 2
                  mulhsu      zero, ra, s5
                  ori         zero, ra, 1594
                  sra         a0, t0, s5
                  c.bnez      a2, 2109f
2109:             mul         a7, s9, s0
                  bgeu        s2, a7, 2118f
                  c.add       ra, s0
                  bltu        t1, s9, 2122f
                  andi        t2, a0, 546
                  nop
                  and         s2, t6, s5
                  c.addi16sp  sp, 416
                  c.andi      a3, -1
2118:             c.and       a3, a2
                  c.and       s0, a0
                  add         s8, ra, s9
                  c.or        a3, a3
2122:             bltu        s8, a3, 2130f
                  xori        s9, t5, 806
                  sra         s11, s10, s6
                  andi        s0, t2, 1747
                  c.li        ra, -1
                  c.srli      a1, 10
                  sra         a3, gp, tp
                  c.bnez      a2, 2136f
2130:             c.slli      s3, 18
                  c.addi      sp, 12
                  mulhu       gp, s7, s2
                  slti        s4, s1, 1717
                  sub         s5, a6, s2
                  c.srli      a3, 21
2136:             bltu        a5, s9, 2143f
                  c.mv        t1, s2
                  c.slli      s3, 15
                  and         s9, s6, tp
                  mulh        a3, a6, s8
                  bltu        s7, a2, 2152f
                  c.addi      tp, -1
2143:             srai        t5, a2, 2
                  xori        zero, tp, -20
                  sltu        t5, a5, t4
                  blt         t0, ra, 2159f
                  bgeu        sp, ra, 2154f
                  bgeu        a6, s6, 2150f
                  nop
2150:             slli        sp, s2, 18
                  c.addi16sp  sp, -16
2152:             c.xor       a0, a0
                  c.or        a2, a3
2154:             mulhsu      s6, a7, a2
                  addi        s4, t5, -992
                  c.srli      a3, 24
                  divu        t2, s9, a4
                  srai        a2, s0, 18
2159:             c.beqz      a0, 2165f
                  add         s4, a4, a5
                  xor         s5, t5, s10
                  c.slli      sp, 25
                  sra         a2, s3, a1
                  c.sub       s0, a3
2165:             c.nop
                  nop
                  lui         a5, 900792
                  div         a6, t3, t3
                  ori         t0, s11, -1739
                  srai        s2, t1, 19
                  slti        t0, ra, 1329
                  bgeu        s9, t4, 2174f
                  c.and       s0, a2
2174:             mulhu       s11, t4, a6
                  slti        s4, a2, -441
                  slti        tp, s1, -1189
                  c.addi      a0, 1
                  bge         s6, a2, 2186f
                  add         t3, t0, t3
                  mulhsu      t4, a6, gp
                  and         s0, t4, t1
                  xori        s2, gp, 1526
                  c.add       ra, tp
                  ori         t3, a5, 874
                  mul         gp, a5, s6
2186:             xor         a3, gp, s6
                  srai        s7, t4, 17
                  lui         zero, 280630
                  c.and       a3, a2
                  xor         t2, a6, ra
                  bge         ra, s8, 2193f
                  andi        a5, t3, 1891
2193:             c.srli      a3, 12
                  sll         s10, s3, s1
                  divu        t5, t1, a5
                  sra         zero, s10, s9
                  c.addi4spn  a3, sp, 560
                  xor         t3, ra, s11
                  c.mv        a6, ra
                  sll         s9, s3, a5
                  ori         s4, a1, 457
                  or          s6, t1, s8
                  c.or        s0, a0
                  c.slli      t2, 14
                  c.or        a0, a1
                  c.sub       a3, a0
                  c.beqz      a3, 2211f
                  c.bnez      a3, 2210f
                  bne         s9, s8, 2214f
2210:             srl         zero, sp, a2
2211:             addi        t3, s4, 1526
                  sub         s7, s0, a5
                  c.xor       a0, a0
2214:             c.slli      ra, 24
                  c.xor       a3, a0
                  add         a7, a5, tp
                  mulh        s4, t1, s6
                  xor         a6, t5, a5
                  auipc       a0, 682565
                  sll         s7, s0, t3
                  mulhsu      t4, s5, sp
                  sltiu       zero, a0, 354
                  bne         t3, s7, 2242f
                  mulh        tp, zero, s10
                  slti        a7, a2, -860
                  xori        tp, t6, 1333
                  bge         t1, tp, 2232f
                  auipc       tp, 960288
                  c.or        a3, a0
                  mulh        t4, s2, s0
                  div         t1, t1, t4
2232:             c.or        a0, a2
                  c.slli      s8, 8
                  c.mv        gp, s0
                  c.or        a3, a0
                  mulhsu      s3, a4, a6
                  c.andi      a3, -1
                  c.or        a0, a3
                  xor         s7, s11, a7
                  bltu        a2, s11, 2252f
                  srl         gp, s10, t4
2242:             bge         a0, t2, 2243f
2243:             c.add       s11, t3
                  bgeu        s0, s9, 2260f
                  xori        a5, a5, 122
                  divu        a1, s11, s3
                  divu        a2, a7, zero
                  slt         zero, s7, tp
                  sub         s0, s4, s2
                  xori        a5, t0, -1259
                  bge         t6, s7, 2257f
2252:             divu        zero, t0, a3
                  sltiu       ra, t1, 1416
                  sll         ra, t0, t0
                  c.srai      a0, 14
                  c.bnez      a0, 2268f
2257:             c.and       a1, a0
                  bgeu        a0, a2, 2270f
                  bge         s0, s0, 2265f
2260:             c.beqz      a3, 2264f
                  c.or        a3, a0
                  or          zero, t6, t2
                  ori         a5, a1, -1217
2264:             bge         s6, t0, 2272f
2265:             c.nop
                  c.bnez      a5, 2276f
                  sub         a0, a5, s5
2268:             blt         sp, ra, 2278f
                  blt         t2, a7, 2275f
2270:             c.beqz      a3, 2271f
2271:             c.sub       a1, a2
2272:             srai        a2, t1, 8
                  lui         s5, 212940
                  mulhsu      a5, s11, s4
2275:             c.addi      s5, 26
2276:             addi        zero, s2, 97
                  rem         s6, s11, s3
2278:             sltu        a2, s7, a0
                  xori        a1, t6, -555
                  div         s3, t1, s3
                  c.nop
                  srl         zero, sp, s3
                  c.li        ra, -1
                  slti        t2, s4, -2020
                  sll         sp, a7, gp
                  divu        s6, a0, a5
                  c.sub       a0, a0
                  c.beqz      a0, 2298f
                  c.mv        s5, a1
                  srli        sp, t6, 26
                  sltu        a2, s11, a2
                  c.xor       a0, a2
                  c.nop
                  andi        tp, a2, 702
                  c.mv        ra, t2
                  nop
                  c.and       a0, a3
2298:             c.li        ra, 22
                  mulhsu      ra, sp, t4
                  bne         t4, sp, 2307f
                  c.addi4spn  a2, sp, 80
                  sub         a1, s3, sp
                  c.bnez      a0, 2308f
                  srl         s7, a0, t2
                  divu        a1, s2, s7
                  srli        s10, gp, 14
2307:             c.andi      a1, 8
2308:             srai        t5, t4, 5
                  c.srli      a3, 4
                  sra         s11, a7, t1
                  c.sub       a1, a2
                  bge         t6, s8, 2313f
2313:             srai        t2, gp, 31
                  ori         t3, s11, 919
                  addi        s5, tp, -1918
                  srai        t4, a6, 17
                  rem         t4, zero, s10
                  c.and       a3, a1
                  lui         sp, 280839
                  slt         t0, t1, zero
                  div         s9, s2, a0
                  slti        s4, s3, 1187
                  nop
                  sub         gp, tp, t2
                  c.and       a2, a1
                  div         t4, ra, s4
                  sltiu       a3, sp, -1695
                  c.or        a0, a3
                  c.srai      a3, 13
                  mulh        a0, s1, t1
                  slli        t0, a3, 10
                  sltiu       a0, s3, -1832
                  c.beqz      a0, 2337f
                  c.srai      a1, 30
                  c.andi      a0, 4
                  mulhu       a1, ra, a0
2337:             mulhsu      tp, t1, s7
                  c.bnez      s0, 2340f
                  slti        s4, tp, -1041
2340:             sll         t3, s5, s11
                  mulh        t2, a2, a0
                  srli        t2, zero, 7
                  sltiu       a6, s7, -1799
                  c.addi4spn  a3, sp, 368
                  div         t3, t1, tp
                  bne         s0, t4, 2351f
                  mulh        zero, t6, s5
                  srli        tp, t5, 0
                  c.addi4spn  a0, sp, 176
                  xor         s7, s4, t3
2351:             srai        t1, tp, 29
                  srli        s6, t2, 7
                  c.sub       a0, s1
                  c.li        s0, -1
                  sltu        t2, sp, a5
                  c.and       a3, s1
                  c.or        a3, s1
                  c.or        a5, a2
                  slli        s6, a4, 8
                  c.bnez      a3, 2372f
                  c.andi      a3, -1
                  c.addi4spn  s0, sp, 240
                  c.nop
                  addi        t5, a1, -1581
                  c.srai      a0, 29
                  divu        zero, s7, zero
                  c.addi16sp  sp, 208
                  slti        s0, s7, -1492
                  lui         t1, 239500
                  sra         sp, a2, s10
                  c.and       a1, a2
2372:             sltiu       zero, a1, 1672
                  bne         t2, a5, 2375f
                  c.xor       a2, a2
2375:             nop
                  c.and       a3, a2
                  c.nop
                  mulhsu      zero, a3, s9
                  c.or        a1, a3
                  c.lui       ra, 30
                  slli        t1, t4, 18
                  srai        zero, a6, 17
                  c.mv        s4, s5
                  c.srai      a1, 11
                  bltu        a0, a7, 2392f
                  slt         t0, t5, s11
                  bne         t5, s3, 2399f
                  xori        a3, s8, 1678
                  div         a3, s10, s11
                  bge         a7, s8, 2394f
                  c.and       a2, s1
2392:             c.xor       a2, s1
                  nop
2394:             div         zero, t0, a1
                  divu        t5, t4, a1
                  div         s10, s0, a4
                  bne         t3, sp, 2410f
                  c.and       a0, a3
2399:             sltu        s7, t5, a7
                  c.addi4spn  a0, sp, 352
                  c.srai      a0, 12
                  sltu        a2, a4, sp
                  divu        s0, s10, s9
                  and         s4, gp, zero
                  c.nop
                  divu        t5, s5, t0
                  mulhu       a0, a7, t3
                  xori        ra, s11, 978
                  div         t5, t4, a5
2410:             mul         gp, t4, s4
                  beq         t6, s1, 2417f
                  xor         a1, s5, a2
                  bgeu        t4, a0, 2419f
                  nop
                  mul         t1, a3, a4
                  c.andi      a3, -1
2417:             or          sp, a2, s3
                  c.xor       a3, a1
2419:             c.addi      a1, 16
                  sra         t3, s1, t1
                  sub         zero, t0, s1
                  xori        s2, ra, -1181
                  lui         s4, 1041823
                  blt         s10, s10, 2426f
                  c.addi4spn  a1, sp, 352
2426:             add         zero, s2, a5
                  slti        s3, a5, 1688
                  andi        s3, ra, -895
                  c.li        a5, 17
                  c.andi      a3, 11
                  sltiu       a1, a3, -773
                  sra         a0, a4, sp
                  bne         a5, t5, 2439f
                  c.and       a3, a2
                  c.add       sp, s8
                  andi        s6, a1, 358
                  srai        s4, a6, 17
                  sltu        s7, s8, a3
2439:             divu        s8, a1, s11
                  andi        t4, a0, 864
                  mul         tp, s0, s6
                  beq         tp, s1, 2454f
                  c.srai      a3, 10
                  slli        a3, a6, 22
                  sll         s0, a2, a7
                  c.srai      a0, 11
                  srl         s3, t5, t3
                  slli        t4, s9, 7
                  c.mv        t4, t3
                  sra         t4, t6, t4
                  and         s9, a4, gp
                  addi        s8, a0, 808
                  mulh        a2, a2, s10
2454:             c.or        s0, a0
                  srli        s5, a3, 25
                  srl         t2, t1, t3
                  sltu        a6, zero, zero
                  c.slli      s3, 18
                  srai        s7, s2, 23
                  bgeu        t2, a7, 2470f
                  sub         a6, tp, s6
                  bltu        t0, t5, 2472f
                  slti        s0, t2, 1102
                  c.or        a1, s1
                  beq         t2, s4, 2473f
                  blt         a4, s0, 2468f
                  and         a0, t5, t3
2468:             beq         gp, a4, 2484f
                  sltu        t5, s8, a3
2470:             or          s3, s7, a4
                  c.add       a1, s11
2472:             c.and       a0, s1
2473:             c.and       a2, a1
                  ori         s6, s1, 489
                  and         t3, tp, s4
                  sra         a7, a5, t2
                  ori         s5, a4, 545
                  c.slli      ra, 6
                  c.or        a0, a0
                  add         tp, t6, t2
                  blt         s7, a1, 2492f
                  c.addi4spn  a3, sp, 48
                  slli        s10, t4, 8
2484:             bne         s1, a2, 2492f
                  bltu        s3, t3, 2495f
                  divu        a5, t4, s0
                  bgeu        s4, gp, 2495f
                  srli        s0, s4, 2
                  c.beqz      a5, 2495f
                  c.addi16sp  sp, 112
                  auipc       zero, 864519
2492:             mulh        s0, t1, s4
                  divu        tp, s5, a5
                  c.nop
2495:             bltu        t5, tp, 2496f
2496:             slli        a3, s0, 2
                  c.and       a2, s1
                  bgeu        s1, t4, 2517f
                  c.beqz      a3, 2506f
                  divu        t2, a3, a4
                  srli        a5, ra, 14
                  c.xor       a0, a0
                  c.sub       a3, a4
                  c.lui       a0, 17
                  mulh        t3, t3, zero
2506:             bge         t2, a2, 2519f
                  div         a5, t4, s4
                  divu        s11, a5, t3
                  or          a7, sp, t2
                  c.beqz      a0, 2514f
                  xori        s5, s6, 1832
                  blt         t0, s4, 2520f
                  c.addi4spn  a3, sp, 320
2514:             slt         s11, s0, s8
                  c.and       s0, a2
                  c.add       a0, s11
2517:             mulhsu      s4, s9, gp
                  sra         s6, a5, s11
2519:             srai        s11, zero, 20
2520:             lui         s0, 987271
                  c.beqz      a2, 2533f
                  c.addi      t3, 1
                  srli        zero, s11, 22
                  c.bnez      a1, 2532f
                  beq         t6, s11, 2537f
                  c.addi4spn  a3, sp, 784
                  div         s11, zero, ra
                  slti        s2, s11, 673
                  lui         t2, 820606
                  blt         t6, s3, 2532f
                  c.slli      ra, 23
2532:             c.slli      t4, 7
2533:             c.addi4spn  a3, sp, 352
                  slti        zero, t3, 1138
                  blt         t1, t6, 2536f
2536:             srl         s3, ra, t5
2537:             c.or        a1, a2
                  bne         s10, t4, 2545f
                  srl         a5, t6, t4
                  srli        s6, s11, 5
                  slti        s11, a7, 1214
                  c.addi      a5, 28
                  mulh        zero, s11, t4
                  slli        s3, a6, 9
2545:             srli        t1, t3, 17
                  c.addi4spn  a0, sp, 720
                  blt         s3, t0, 2549f
                  addi        s6, gp, 390
2549:             bltu        t6, t5, 2556f
                  auipc       ra, 861095
                  c.xor       a3, a2
                  add         a6, s10, gp
                  c.addi16sp  sp, -16
                  slli        a0, s7, 5
                  nop
2556:             nop
                  and         s4, s11, t6
                  c.bnez      a3, 2564f
                  div         s0, t3, a5
                  c.xor       a0, s1
                  bne         t2, a7, 2569f
                  divu        a5, t4, t0
                  c.or        a1, a2
2564:             c.andi      a0, 2
                  add         t4, s6, t0
                  slti        t2, a3, -887
                  slli        t0, a7, 0
                  srai        a7, s6, 21
2569:             and         zero, t0, zero
                  c.slli      s3, 26
                  c.xor       a0, a2
                  divu        gp, a2, s0
                  xor         s7, s10, a5
                  ori         s6, s8, 1288
                  or          a5, t6, a2
                  c.addi4spn  s0, sp, 128
                  sll         s3, t0, s9
                  bgeu        s4, a0, 2584f
                  nop
                  slt         ra, tp, s5
                  or          a7, a4, s9
                  addi        t1, a2, 1291
                  c.li        s5, -1
2584:             c.xor       s0, a0
                  mulh        zero, a3, zero
                  bge         a4, t3, 2590f
                  srl         zero, a5, s10
                  bge         a0, s11, 2600f
                  bgeu        t2, t3, 2599f
2590:             div         s7, t0, a3
                  srai        s11, a1, 26
                  slti        zero, a1, 1989
                  c.mv        t5, s9
                  c.slli      s7, 20
                  mulh        t0, t1, a5
                  addi        s0, s8, 1278
                  c.andi      a3, 11
                  mul         s2, t4, a4
2599:             bge         zero, t5, 2609f
2600:             or          a2, s1, s10
                  beq         gp, t3, 2608f
                  bgeu        s3, tp, 2618f
                  sltu        t2, s6, a0
                  and         zero, t5, zero
                  mulhu       s11, gp, s10
                  auipc       s7, 680970
                  c.xor       a0, a2
2608:             sltu        zero, a4, s4
2609:             mul         t3, s4, a1
                  sll         a0, tp, s8
                  c.addi4spn  a5, sp, 80
                  ori         t3, s0, 1823
                  c.addi      a2, -1
                  sll         s6, s9, t1
                  andi        s0, s9, 782
                  blt         s3, gp, 2622f
                  c.sub       a0, s1
2618:             beq         t5, s1, 2637f
                  sub         t3, s6, t6
                  c.addi      s9, -1
                  c.and       a0, s0
2622:             sra         ra, s8, s11
                  c.slli      gp, 10
                  c.nop
                  mulhu       zero, a0, s0
                  srai        a2, ra, 20
                  xori        a7, a5, 1464
                  and         gp, t6, a2
                  c.mv        t1, t1
                  c.slli      s7, 16
                  bgeu        s7, s8, 2633f
                  blt         a6, t3, 2634f
2633:             beq         a1, s0, 2634f
2634:             auipc       t4, 478090
                  c.slli      a6, 10
                  divu        t1, a5, t6
2637:             sra         gp, sp, s7
                  blt         s11, t4, 2649f
                  xor         t4, t6, t6
                  mulh        a2, a6, s9
                  sll         s7, sp, t2
                  mulh        s3, s1, a7
                  c.addi16sp  sp, -16
                  slli        s10, s3, 4
                  bge         s0, s8, 2655f
                  slti        t5, a7, 453
                  nop
                  c.sub       a3, s0
2649:             c.sub       a3, a3
                  beq         a4, a6, 2655f
                  mulhu       s2, a0, a5
                  sub         s9, a5, s5
                  c.srai      a1, 24
                  c.addi16sp  sp, 240
2655:             sltiu       a1, s4, 349
                  slli        s8, s4, 10
                  beq         s10, s11, 2662f
                  add         s7, t5, tp
                  mul         a5, a1, tp
                  ori         s11, gp, 948
                  c.and       a0, a2
2662:             beq         s6, s1, 2668f
                  ori         gp, t5, -1074
                  c.lui       a7, 3
                  bge         zero, t1, 2666f
2666:             srai        s0, s10, 29
                  bge         tp, a6, 2672f
2668:             or          t5, zero, t4
                  ori         s6, s0, 1132
                  add         a5, s2, a4
                  mul         tp, s4, t6
2672:             sltiu       t4, a2, -482
                  c.sub       a0, a3
                  slt         s8, t4, s6
                  bgeu        s3, s5, 2683f
                  c.and       a0, a0
                  c.srai      a3, 12
                  sub         zero, s3, t0
                  c.srli      a0, 16
                  c.addi      s10, -1
                  srl         a5, t2, a5
                  beq         s4, a2, 2688f
2683:             c.addi4spn  a5, sp, 432
                  mul         s2, s8, a3
                  c.srai      a0, 8
                  mul         s7, t0, s3
                  bne         t4, s9, 2689f
2688:             mul         zero, s5, t5
2689:             c.or        a2, a4
                  c.srli      a1, 16
                  bltu        a5, a6, 2703f
                  bge         t3, t1, 2705f
                  xor         s0, s11, a7
                  c.andi      a2, -1
                  nop
                  andi        ra, s3, 1292
                  slt         tp, t3, s6
                  c.srli      a3, 9
                  c.li        s3, 9
                  c.addi4spn  a2, sp, 736
                  c.addi4spn  a3, sp, 432
                  sltiu       sp, ra, 1827
2703:             c.add       s6, t1
                  divu        a3, s4, a7
2705:             c.sub       a0, a1
                  addi        t2, ra, -279
                  c.addi16sp  sp, -16
                  sll         s7, s9, s0
                  beq         zero, a7, 2721f
                  bne         s5, t2, 2712f
                  c.xor       a5, a3
2712:             c.addi16sp  sp, -16
                  c.srli      a3, 26
                  srli        zero, s9, 24
                  c.srai      s0, 10
                  slli        zero, t1, 28
                  c.xor       a0, a1
                  c.sub       a3, a1
                  c.xor       a0, a2
                  bgeu        t5, t4, 2736f
2721:             mul         s10, s5, a1
                  srli        s3, t2, 13
                  c.add       a6, gp
                  sll         t0, gp, s1
                  srai        a3, a0, 30
                  c.sub       a0, a3
                  c.andi      a3, 19
                  add         a1, s11, t4
                  c.beqz      a3, 2734f
                  slti        s8, sp, -593
                  c.and       a0, s1
                  sub         s7, t1, t1
                  div         a2, s10, t2
2734:             sltiu       s0, a0, -1480
                  c.slli      sp, 4
2736:             sltu        a7, t1, t1
                  c.li        gp, -1
                  slt         zero, s6, a4
                  c.srai      a2, 30
                  xor         zero, a5, a1
                  c.addi      a3, 5
                  mulhsu      s9, s7, a6
                  c.addi      ra, 20
                  c.srai      a3, 31
                  mulhsu      s10, a6, ra
                  c.beqz      a2, 2752f
                  slti        a7, s11, 196
                  slti        s4, s4, 344
                  and         s4, t4, s4
                  c.mv        ra, s11
                  bltu        t0, s1, 2758f
2752:             add         t0, t3, t5
                  slt         s5, s0, tp
                  sra         a3, s7, sp
                  xori        ra, a5, 784
                  c.nop
                  lui         s10, 66690
2758:             sltiu       s2, s8, -357
                  c.bnez      a0, 2771f
                  c.xor       a0, a1
                  and         a6, ra, ra
                  srai        t0, s6, 4
                  c.lui       s2, 16
                  c.bnez      s0, 2768f
                  mulhu       t5, tp, a3
                  mulh        tp, t2, a5
                  sltu        t3, t0, gp
2768:             c.bnez      a3, 2769f
2769:             c.beqz      a2, 2775f
                  beq         a5, s1, 2780f
2771:             srl         a1, a6, s2
                  beq         a5, s6, 2776f
                  nop
                  addi        a2, t3, 1248
2775:             sra         s6, s8, s4
2776:             c.lui       a3, 2
                  c.xor       a3, a1
                  auipc       zero, 680232
                  addi        zero, s6, -401
2780:             divu        s2, t2, s10
                  xor         t3, s6, a5
                  sra         zero, s11, a6
                  c.and       s0, a1
                  bltu        s8, zero, 2792f
                  sra         zero, s1, a5
                  c.addi16sp  sp, -16
                  sra         s7, s0, a2
                  c.beqz      a0, 2799f
                  mulhu       s4, a7, t3
                  nop
                  slti        gp, a3, -1099
2792:             c.srli      s0, 10
                  mulhu       tp, s10, t0
                  srai        t2, s5, 12
                  c.xor       a1, a1
                  c.sub       a2, a0
                  andi        a5, s3, 1236
                  sub         s0, s7, t5
2799:             c.sub       a1, a3
                  c.slli      t2, 11
                  auipc       s4, 682110
                  divu        s11, t0, t0
                  c.srli      a3, 5
                  c.nop
                  slti        a5, s11, -476
                  bge         a7, t6, 2813f
                  sltu        a2, s7, s2
                  srai        s4, s9, 0
                  ori         s0, s1, -411
                  andi        zero, s10, -589
                  slli        t5, gp, 5
                  c.lui       a2, 29
2813:             c.beqz      s0, 2815f
                  sra         s11, s10, s7
2815:             c.andi      a0, 27
                  beq         sp, a5, 2835f
                  blt         s6, t4, 2824f
                  c.lui       a5, 20
                  c.li        t5, 28
                  slt         a6, t1, a1
                  c.nop
                  c.sub       a0, a0
                  nop
2824:             ori         a6, t3, 1925
                  div         a3, s0, s9
                  addi        s9, s11, 805
                  beq         s1, s4, 2833f
                  beq         s7, ra, 2838f
                  and         a1, s11, a5
                  srl         zero, a0, ra
                  addi        t2, zero, 1859
                  ori         zero, t4, -1005
2833:             blt         a7, t5, 2835f
                  sltiu       s6, s10, 513
2835:             c.srai      a0, 15
                  mulh        s9, a1, a2
                  addi        t3, s6, -1445
2838:             andi        zero, t4, 1408
                  xor         gp, a6, a1
                  c.add       ra, s8
                  rem         a1, ra, gp
                  c.sub       a3, a3
                  div         a6, s2, a5
                  sltiu       s0, t5, -1308
                  c.lui       s8, 25
                  c.and       a1, a1
                  mulh        a5, a3, t1
                  c.addi      a5, 28
                  sub         a5, sp, s2
                  srl         s11, s7, s5
                  c.lui       a7, 1
                  blt         ra, a1, 2860f
                  c.mv        t5, s7
                  mulhu       s2, s5, ra
                  sll         t0, s0, s9
                  andi        ra, tp, 142
                  mulhu       s11, t6, t4
                  lui         a1, 567935
                  sub         s2, t5, s2
2860:             slt         a1, t6, t1
                  mulh        t4, a0, zero
                  c.lui       ra, 27
                  add         s4, ra, a5
                  sub         a5, a2, a6
                  sub         sp, sp, t0
                  srl         s7, s1, s7
                  srl         s3, a5, t1
                  c.addi4spn  a0, sp, 528
                  srai        gp, t5, 21
                  mulhu       t5, gp, a1
                  lui         a6, 133084
                  c.srai      s0, 27
                  mulhsu      zero, a7, s9
                  slt         zero, t2, s0
                  bltu        t3, s6, 2885f
                  sra         s3, a0, gp
                  blt         t5, ra, 2896f
                  divu        a3, s9, tp
                  c.and       a3, a1
                  or          gp, sp, s5
                  blt         zero, s0, 2885f
                  andi        s0, t0, 496
                  auipc       zero, 525044
                  c.slli      a2, 1
2885:             c.or        a0, a1
                  c.xor       a3, a4
                  c.beqz      a1, 2894f
                  and         t0, s1, a3
                  addi        s10, s2, -806
                  xor         t5, a7, s0
                  div         a2, a7, t0
                  mul         s10, a5, a6
                  rem         s5, a3, s9
2894:             add         a0, s11, s6
                  srai        a3, s6, 31
2896:             c.sub       a1, a3
                  ori         s9, s4, -1452
                  c.li        s7, 25
                  srl         t0, a7, s0
                  sub         t0, t5, zero
                  rem         tp, a7, a2
                  nop
                  xori        t0, ra, 846
                  mulhsu      t3, a2, a2
                  c.xor       a2, s1
                  xori        s8, t5, 1627
                  c.andi      a0, -1
                  sltiu       a1, a5, 1348
                  slt         t4, a3, s3
                  c.xor       a0, a2
                  c.xor       a2, a1
                  bne         s11, t6, 2918f
                  slli        a0, s3, 16
                  c.li        a3, -1
                  c.xor       a0, a3
                  c.slli      ra, 16
                  sub         a0, s2, a7
2918:             c.xor       s0, s0
                  c.add       a7, s6
                  add         a0, t2, s8
                  sub         a6, s9, s8
                  srl         tp, s6, t0
                  c.addi16sp  sp, -16
                  sltu        zero, t2, s6
                  andi        s4, s9, 1326
                  beq         t2, t3, 2932f
                  c.nop
                  c.beqz      a2, 2934f
                  nop
                  sltiu       s8, gp, 200
                  xor         s10, s4, t2
2932:             sub         ra, zero, t4
                  beq         s11, t1, 2944f
2934:             slt         s5, t0, a2
                  c.srai      a1, 18
                  div         a3, s1, s9
                  mulh        s5, s4, zero
                  c.addi16sp  sp, 16
                  c.bnez      a3, 2941f
                  c.slli      s11, 5
2941:             c.beqz      a1, 2953f
                  c.slli      s9, 3
                  add         s8, a2, t5
2944:             slti        sp, a7, -888
                  addi        t4, a4, 105
                  mulhu       t2, tp, a7
                  c.and       a3, s1
                  c.bnez      a0, 2955f
                  addi        a2, t3, 919
                  c.bnez      a3, 2952f
                  c.beqz      a0, 2963f
2952:             sltiu       a0, t2, 157
2953:             mul         a3, s8, a2
                  c.nop
2955:             c.addi16sp  sp, -16
                  c.lui       a6, 12
                  c.srai      a2, 2
                  nop
                  auipc       t4, 494680
                  bne         s6, t3, 2968f
                  srl         t4, a2, t1
                  c.srli      s0, 5
2963:             c.nop
                  or          t1, a5, a0
                  c.bnez      a0, 2973f
                  lui         s7, 936089
                  c.andi      a0, -1
2968:             slti        s0, a6, -390
                  sltu        zero, t0, zero
                  slt         a5, t1, t5
                  c.slli      ra, 29
                  c.addi4spn  a3, sp, 576
2973:             c.nop
                  or          a1, s10, a1
                  slt         s0, s1, a4
                  bltu        s3, s7, 2984f
                  c.xor       s0, a5
                  c.andi      a1, 12
                  bltu        t2, ra, 2989f
                  c.bnez      s0, 2986f
                  blt         t4, t4, 2988f
                  sub         s7, t2, s9
                  c.or        a2, a3
2984:             sltiu       gp, s2, -870
                  sltiu       s7, s9, 1106
2986:             c.srli      a3, 30
                  auipc       t0, 980799
2988:             slti        t5, a3, -1793
2989:             xori        s7, a5, -334
                  c.sub       s0, a0
                  bltu        t1, a0, 2996f
                  slli        tp, a7, 19
                  c.or        a0, a2
                  divu        t3, t6, s5
                  c.li        a2, -1
2996:             srl         a6, a5, t2
                  srai        t0, t6, 30
                  srl         s0, t1, s9
                  xori        s0, sp, -511
                  sll         a1, sp, s6
                  c.srai      a1, 15
                  beq         t2, gp, 3014f
                  andi        s6, t6, 1673
                  c.nop
                  c.andi      a3, -1
                  divu        s4, t2, a4
                  c.addi16sp  sp, 304
                  c.add       ra, s0
                  c.nop
                  c.addi4spn  a1, sp, 288
                  auipc       a5, 10564
                  sltu        zero, a7, t6
                  c.and       a3, a2
3014:             xor         t0, s2, gp
                  c.sub       a1, s1
                  sub         s4, zero, s8
                  srli        a5, s2, 19
                  srli        s2, s10, 25
                  c.bnez      a3, 3035f
                  bgeu        a3, a7, 3022f
                  c.beqz      s0, 3034f
3022:             sltiu       s4, t0, -1957
                  or          s6, t2, a1
                  c.addi16sp  sp, -16
                  c.beqz      a0, 3035f
                  andi        s10, t3, 267
                  c.li        ra, 30
                  c.li        t2, -1
                  sra         zero, s8, t3
                  c.andi      a0, -1
                  mulhsu      t3, s10, t6
                  auipc       zero, 407684
                  c.addi      a2, 30
3034:             c.nop
3035:             rem         s4, t0, s10
                  srli        zero, a2, 8
                  c.mv        ra, a5
                  c.slli      a3, 4
                  auipc       t5, 244380
                  c.srli      s0, 17
                  bge         s8, s0, 3042f
3042:             lui         s3, 400549
                  c.srai      a1, 11
                  add         tp, zero, s3
                  srai        zero, t2, 21
                  c.and       a2, s1
                  c.andi      a1, 26
                  slti        a2, ra, 994
                  sltiu       s9, s5, -287
                  srl         s6, a6, t4
                  bgeu        a0, s0, 3052f
3052:             sltiu       t5, sp, 1795
                  c.and       s0, s1
                  mulhsu      a3, a2, s2
                  c.xor       a1, a4
                  bgeu        a5, a4, 3058f
                  c.lui       a3, 23
3058:             sll         a2, s3, s7
                  srai        a3, t0, 10
                  bgeu        s4, s6, 3064f
                  srli        s0, s6, 12
                  sra         zero, ra, zero
                  c.slli      a5, 24
3064:             sltiu       a2, s11, 740
                  div         a1, tp, a2
                  rem         a0, tp, s9
                  c.beqz      a5, 3077f
                  bne         s6, s6, 3073f
                  sltiu       zero, s9, 626
                  divu        t2, tp, t3
                  bgeu        s5, s1, 3077f
                  mul         a7, t2, a2
3073:             sra         a1, a2, s6
                  bltu        ra, s11, 3093f
                  c.bnez      a0, 3087f
                  srai        zero, t3, 17
3077:             bge         a5, t6, 3079f
                  sub         s10, gp, s8
3079:             mul         s8, tp, s9
                  srl         s0, t2, s4
                  auipc       s5, 926924
                  ori         s2, s6, -193
                  rem         a2, s10, tp
                  c.nop
                  nop
                  bgeu        s0, a6, 3094f
3087:             srai        t1, a3, 14
                  mul         s10, t3, s8
                  c.or        s0, a0
                  c.nop
                  c.srli      a3, 9
                  lui         s11, 416983
3093:             bgeu        tp, t6, 3095f
3094:             slli        t1, a1, 25
3095:             bne         t4, tp, 3105f
                  c.and       a3, a0
                  andi        t4, t4, 1155
                  add         a6, a4, t5
                  c.addi      s5, -1
                  bltu        s10, s10, 3113f
                  c.beqz      a1, 3109f
                  add         sp, a3, s2
                  c.xor       a0, a5
                  c.andi      a2, -1
3105:             sra         s10, s5, s1
                  xor         s4, tp, a3
                  xor         s9, s0, s2
                  c.andi      a3, 21
3109:             c.srli      a3, 4
                  mul         s7, a1, s0
                  sll         zero, sp, sp
                  or          s2, t6, t5
3113:             c.andi      s0, -1
                  srai        a5, gp, 19
                  bne         t1, s11, 3116f
3116:             c.li        s3, -1
                  c.lui       a3, 12
                  c.lui       s9, 2
                  c.srli      a1, 13
                  andi        s0, t6, 441
                  c.addi      s5, -1
                  c.addi16sp  sp, 176
                  divu        s3, s3, a2
                  xor         s11, s4, tp
                  lui         t4, 408979
                  sub         t3, tp, s11
                  c.mv        s8, a5
                  add         zero, sp, s6
                  blt         s3, t1, 3141f
                  c.or        a2, a1
                  bge         t1, s2, 3141f
                  c.slli      s3, 28
                  mulh        t5, s0, s9
                  c.bnez      s0, 3144f
                  bltu        sp, s7, 3143f
                  sltiu       t4, t6, -2028
                  divu        zero, t1, s5
                  blt         s5, s2, 3140f
                  rem         a5, s9, gp
3140:             mulhsu      sp, zero, s7
3141:             add         t0, s4, a7
                  srl         t2, tp, s6
3143:             slt         s0, zero, a1
3144:             xor         a1, a4, t1
                  c.srli      a3, 9
                  bne         t6, tp, 3147f
3147:             addi        t5, a6, -896
                  mulhu       zero, s2, a7
                  c.and       a0, s1
                  mulh        zero, s5, s11
                  c.xor       a2, s0
                  c.sub       a1, a2
                  c.addi4spn  a3, sp, 528
                  sub         tp, s6, gp
                  c.or        a3, a3
                  c.slli      t0, 23
                  divu        t1, a1, t6
                  c.nop
                  sra         gp, s7, a0
                  bgeu        t2, sp, 3166f
                  c.sub       a0, a1
                  and         s8, s8, s8
                  c.mv        tp, a1
                  mulh        t2, a3, gp
                  c.xor       a3, s1
3166:             auipc       s8, 717597
                  mulh        a5, t0, gp
                  mul         s11, s2, s2
                  slli        sp, s7, 23
                  sra         a2, s11, a2
                  sra         s7, ra, s1
                  div         zero, sp, s8
                  auipc       zero, 2858
                  c.nop
                  c.and       a0, a2
                  c.or        a1, a1
                  mul         zero, s10, a2
                  c.lui       a6, 4
                  c.addi      sp, 29
                  nop
                  c.li        a1, -1
                  c.li        s4, -1
                  sll         s6, a5, t5
                  c.addi4spn  a3, sp, 640
                  c.nop
                  beq         a4, t0, 3198f
                  beq         s3, t1, 3194f
                  and         s8, gp, a7
                  auipc       a7, 697271
                  mul         a1, t1, t5
                  mul         t2, a4, a1
                  blt         t0, a6, 3198f
                  bltu        gp, t4, 3198f
3194:             c.sub       a3, a2
                  or          a0, a6, a7
                  or          zero, a2, a3
                  c.bnez      a2, 3213f
3198:             c.and       a0, a3
                  add         a1, tp, s3
                  c.srai      a0, 29
                  sra         t4, a6, s0
                  andi        t5, sp, -1097
                  c.lui       t5, 25
                  sltu        s9, sp, a7
                  c.addi16sp  sp, 304
                  mulhsu      zero, a3, ra
                  c.and       a3, a2
                  c.srli      a0, 10
                  c.slli      t5, 25
                  sub         s8, a4, a4
                  c.nop
                  c.srli      a0, 14
3213:             xor         s8, a4, t6
                  divu        zero, a3, a1
                  srl         t2, t5, a3
                  mulh        sp, tp, s11
                  c.addi4spn  a2, sp, 848
                  sub         s0, ra, a3
                  c.andi      a0, -1
                  beq         zero, s7, 3225f
                  sra         a1, s6, t1
                  c.addi      tp, 9
                  c.add       gp, s9
                  c.nop
3225:             xori        t5, gp, -1190
                  div         s4, s1, t0
                  mulh        a3, a5, s11
                  beq         a0, s10, 3234f
                  bltu        a3, a1, 3233f
                  add         zero, s3, s0
                  c.addi4spn  a0, sp, 384
                  c.nop
3233:             slli        s3, a4, 12
3234:             c.and       a0, a1
                  slt         t4, s6, s3
                  div         a1, s4, a3
                  divu        s7, t1, t1
                  c.addi16sp  sp, 32
                  andi        t5, a7, 1182
                  sll         s8, t5, s11
                  c.srli      a3, 10
                  auipc       s2, 12586
                  mulhsu      s4, a6, sp
                  c.add       s4, s3
                  c.bnez      s0, 3252f
                  nop
                  bltu        a7, t1, 3251f
                  c.and       s0, a1
                  beq         s2, s5, 3260f
                  c.nop
3251:             c.and       a3, s1
3252:             xor         s10, a6, s9
                  rem         a7, s11, s8
                  addi        a0, s5, -646
                  xor         a0, a6, a0
                  blt         s8, a2, 3258f
                  mul         zero, tp, tp
3258:             c.srai      a0, 26
                  c.srli      a5, 19
3260:             ori         a6, t2, -861
                  c.add       a7, s8
                  c.lui       s4, 24
                  auipc       gp, 1015833
                  c.mv        t5, t0
                  nop
                  or          t4, s8, s3
                  c.or        a5, a3
                  c.lui       a0, 24
                  c.xor       a0, a1
                  addi        s8, a7, 1403
                  or          a3, ra, t1
                  and         a2, s2, s3
                  srli        a1, a7, 3
                  div         zero, t4, a6
                  c.nop
                  div         a6, a3, a6
                  sub         s5, s8, a4
                  c.addi16sp  sp, -16
                  bltu        gp, tp, 3286f
                  c.slli      s10, 14
                  lui         s2, 264870
                  srl         s10, t0, s0
                  c.addi16sp  sp, 352
                  c.bnez      a0, 3296f
                  c.addi16sp  sp, -16
3286:             and         t2, zero, sp
                  slt         ra, t5, a0
                  mulh        s6, a5, a7
                  c.and       a0, a0
                  slti        t3, a3, -1675
                  sltu        t0, a0, s10
                  c.li        s3, 13
                  c.mv        a0, a0
                  c.addi4spn  s0, sp, 64
                  addi        s4, t4, 2011
3296:             c.nop
                  andi        ra, s3, 1225
                  sra         a0, s4, tp
                  mulhu       a0, s8, a2
                  c.addi16sp  sp, 48
                  srl         s9, s8, a1
                  mulhu       a7, s4, s3
                  divu        s10, a1, t2
                  c.beqz      a3, 3306f
                  mul         ra, s8, tp
3306:             c.addi4spn  a3, sp, 576
                  mulhsu      a3, t1, s7
                  add         zero, s10, a4
                  c.lui       t5, 6
                  slt         zero, a1, s4
                  c.srli      s0, 29
                  c.add       t1, a6
                  c.li        gp, 30
                  mulh        tp, a6, s4
                  c.xor       s0, a1
                  c.or        a3, a2
                  c.srli      a1, 1
                  mulhsu      t0, zero, gp
                  srl         zero, t6, a2
                  c.add       s3, s5
                  slt         s0, a3, s10
                  slt         t5, s9, s2
                  bltu        s8, t6, 3331f
                  c.sub       a0, s1
                  c.sub       a2, a1
                  slt         a6, t2, t4
                  or          a6, a5, s9
                  mul         sp, s9, t5
                  divu        s11, tp, s7
                  c.add       a1, s1
3331:             bge         t3, t2, 3337f
                  c.addi16sp  sp, 448
                  sltiu       t1, s4, 1107
                  sll         a5, s6, a1
                  xor         t2, s4, s9
                  lui         s6, 555089
3337:             sub         a1, ra, a6
                  bgeu        a0, a2, 3345f
                  slli        s6, t5, 31
                  slti        zero, s4, -2037
                  xori        s6, t2, 1654
                  or          tp, t4, a2
                  bgeu        t3, sp, 3355f
                  c.mv        ra, t3
3345:             mulhsu      tp, t5, tp
                  c.add       s5, s2
                  xori        a2, s2, -402
                  sltiu       a7, s0, 1866
                  mul         a2, s8, ra
                  sra         zero, a5, t5
                  c.srai      a0, 1
                  mulhu       t3, s0, a7
                  c.srli      a0, 27
                  c.xor       a3, a1
3355:             add         a6, a3, t5
                  c.lui       s8, 17
                  blt         t1, t3, 3365f
                  c.xor       a3, a0
                  c.slli      s11, 29
                  div         s6, s11, s3
                  sll         t4, a3, t2
                  c.slli      gp, 16
                  xori        a6, s0, -83
                  c.bnez      a3, 3366f
3365:             c.srli      a2, 28
3366:             c.li        sp, 10
                  sra         a0, t6, a0
                  c.lui       s6, 16
                  c.or        a2, a3
                  andi        s5, s11, 1575
                  c.addi16sp  sp, 16
                  c.addi4spn  a0, sp, 784
                  c.srai      a0, 23
                  ori         s0, s3, 613
                  c.xor       a0, s0
                  c.sub       a0, a3
                  sub         s5, t1, s11
                  bge         s4, s7, 3383f
                  blt         t1, s1, 3391f
                  nop
                  xor         a6, a7, s5
                  c.bnez      s0, 3384f
3383:             lui         s9, 55166
3384:             ori         s10, a2, -1055
                  andi        a3, a1, 1120
                  or          a0, a7, t2
                  sltu        zero, tp, s10
                  or          a5, s6, s10
                  bge         a2, tp, 3391f
                  slti        s4, a3, -1337
3391:             mulhsu      ra, a4, s7
                  mulh        s0, s2, s7
                  sra         t2, s7, gp
                  mulhu       s9, tp, s1
                  c.add       s0, a6
                  divu        a7, t0, t4
                  sub         gp, s2, zero
                  add         zero, s11, s5
                  sltiu       s11, s5, -1805
                  and         ra, t4, a6
                  c.srli      s0, 27
                  blt         a1, s6, 3406f
                  sra         zero, t5, s8
                  c.sub       a0, a2
                  c.mv        a0, ra
3406:             c.addi16sp  sp, 96
                  c.add       a3, tp
                  c.or        a2, a1
                  or          s10, t0, a5
                  mul         a5, s0, t0
                  xori        s4, a1, -864
                  andi        s9, s10, 81
                  srai        zero, tp, 19
                  c.srai      a1, 25
                  c.add       a0, s11
                  divu        a1, s10, zero
                  bltu        t0, t3, 3427f
                  mul         zero, a1, s9
                  c.addi16sp  sp, -16
                  and         a7, t2, s3
                  srl         a5, sp, s6
                  sra         a2, a1, a2
                  c.addi4spn  s0, sp, 112
                  c.addi4spn  a3, sp, 176
                  mulh        s11, s11, s11
                  slti        t0, s6, -16
3427:             ori         a0, a3, 1011
                  srai        tp, tp, 7
                  sll         a5, a6, zero
                  srl         a1, a7, a6
                  c.or        a3, a2
                  sltu        a2, a7, sp
                  or          t2, zero, s9
                  c.and       s0, a1
                  c.srai      a1, 3
                  rem         s7, s5, a6
                  c.li        a0, 9
                  mulhu       t0, s10, zero
                  srl         t2, a5, s4
                  c.and       a3, a3
                  rem         zero, s11, s1
                  bge         t3, a1, 3447f
                  c.srli      a3, 25
                  c.li        s2, 24
                  beq         a0, t1, 3464f
                  bltu        s6, gp, 3450f
3447:             sll         tp, s8, a0
                  beq         t2, s4, 3449f
3449:             c.add       s3, tp
3450:             slti        s0, s4, 136
                  mul         a6, s7, a7
                  c.andi      a0, -1
                  slli        s0, zero, 31
                  bge         ra, s10, 3464f
                  andi        t5, gp, -343
                  bge         s3, s4, 3457f
3457:             mulhu       gp, s7, t2
                  sltu        t0, a1, a1
                  ori         a6, a6, 277
                  sltu        s10, a4, s4
                  bge         s11, s9, 3469f
                  and         ra, a7, s3
                  c.beqz      a0, 3470f
3464:             c.or        a3, a3
                  c.sub       a0, a3
                  blt         s5, ra, 3472f
                  c.addi16sp  sp, -16
                  c.slli      s3, 17
3469:             c.lui       a7, 28
3470:             sltu        ra, tp, a7
                  bne         s6, s6, 3482f
3472:             sra         zero, s11, s8
                  lui         a0, 355874
                  sltu        a5, s9, s9
                  or          s10, a4, s4
                  c.beqz      a0, 3482f
                  bne         s10, s11, 3487f
                  bgeu        s4, zero, 3485f
                  and         s8, a6, t2
                  and         t1, t1, s5
                  c.sub       a2, a2
3482:             c.slli      tp, 18
                  beq         s6, a4, 3499f
                  bgeu        a7, tp, 3490f
3485:             c.add       sp, t2
                  sltiu       s8, s1, -1660
3487:             c.slli      s8, 6
                  c.and       a1, a2
                  andi        s5, t4, -169
3490:             c.srai      a3, 26
                  srli        a3, t1, 13
                  beq         a3, s10, 3505f
                  rem         t2, s9, ra
                  c.sub       a3, a3
                  c.add       s4, s4
                  c.beqz      a2, 3500f
                  c.or        a3, a0
                  c.beqz      a3, 3505f
3499:             c.add       s0, t1
3500:             c.addi4spn  s0, sp, 208
                  ori         s6, s4, -921
                  c.and       a1, a1
                  bgeu        s3, s8, 3505f
                  andi        a7, s4, 1715
3505:             c.add       s7, t5
                  c.mv        sp, s5
                  andi        t0, a7, -641
                  and         a0, s1, a5
                  c.addi      s8, 21
                  c.bnez      a1, 3520f
                  c.xor       a0, a5
                  c.andi      a3, 15
                  srli        t2, s4, 30
                  xori        t3, s2, -134
                  c.srli      a0, 7
                  nop
                  srai        s3, zero, 13
                  andi        a2, s5, -1587
                  xor         ra, s0, gp
3520:             mulhsu      t5, t4, sp
                  bne         ra, s9, 3527f
                  add         ra, ra, a3
                  nop
                  c.add       s0, s0
                  c.and       s0, s1
                  c.addi4spn  a0, sp, 592
3527:             auipc       zero, 473262
                  c.beqz      s0, 3538f
                  mulhu       s9, sp, t1
                  slt         s0, s1, a6
                  sll         a1, t6, a3
                  beq         ra, s11, 3537f
                  sll         t1, s3, s1
                  sltiu       s5, s2, -348
                  andi        t4, tp, -953
                  ori         zero, s4, 698
3537:             ori         s6, s1, 1962
3538:             c.or        a1, a3
                  c.beqz      a0, 3551f
                  sltiu       s2, t2, 1825
                  srai        sp, t6, 8
                  bgeu        s3, s7, 3561f
                  srai        zero, s2, 23
                  bge         s8, s2, 3557f
                  c.bnez      a2, 3553f
                  divu        t3, s4, s1
                  c.addi      s2, 17
                  add         gp, s3, a6
                  bltu        t4, a2, 3551f
                  bgeu        s10, s4, 3556f
3551:             mulhsu      sp, sp, a3
                  c.addi16sp  sp, 432
3553:             rem         s7, s10, a7
                  c.or        s0, a3
                  sltu        s6, a7, s3
3556:             sltiu       s9, t0, -1039
3557:             or          t1, t1, t1
                  lui         s11, 112556
                  bgeu        a7, t2, 3560f
3560:             ori         s7, t0, -1124
3561:             c.srai      a0, 22
                  sub         a6, s9, t2
                  c.srli      a3, 20
                  mul         a5, a5, t1
                  mulh        t5, t5, s4
                  bltu        a5, s10, 3573f
                  c.and       s0, a2
                  c.andi      a3, 24
                  bltu        tp, s1, 3581f
                  rem         a6, t4, s4
                  c.and       a0, a3
                  divu        s11, sp, s8
3573:             c.bnez      a0, 3579f
                  mul         ra, a1, t3
                  mulhsu      t5, t4, t6
                  srli        zero, a1, 7
                  beq         a6, a2, 3589f
                  slli        zero, s9, 4
3579:             sll         a3, a5, s11
                  sltu        s9, t2, t3
3581:             c.andi      a0, 27
                  blt         t4, s6, 3584f
                  slti        a6, s4, -664
3584:             c.lui       t2, 22
                  sltiu       s11, a4, 2024
                  c.sub       a0, a3
                  c.nop
                  addi        zero, a2, 1493
3589:             mul         zero, s8, s1
                  xori        a0, s5, 2038
                  mulh        a1, tp, s7
                  mulhsu      tp, ra, s0
                  sra         a6, s6, ra
                  sub         s11, s5, a3
                  mulh        s5, s11, sp
                  sra         s6, a4, a2
                  c.addi4spn  a5, sp, 448
                  c.sub       a1, a1
                  c.xor       a0, a2
                  lui         a2, 71072
                  lui         t0, 434760
                  sll         ra, a3, a7
                  mulhu       s5, t4, a0
                  beq         sp, a0, 3612f
                  mulh        s8, t4, s4
                  c.sub       a0, a0
                  c.xor       a2, a0
                  c.slli      a5, 22
                  c.nop
                  or          a3, s10, a5
                  bltu        s8, sp, 3621f
3612:             mul         s0, ra, s7
                  c.sub       s0, a0
                  rem         a1, s2, s6
                  c.or        a1, s0
                  c.sub       a2, a3
                  sra         sp, sp, t4
                  add         t4, t6, sp
                  c.addi16sp  sp, -16
                  sltiu       s6, t3, 477
3621:             c.or        a0, s1
                  nop
                  c.mv        ra, s8
                  c.addi16sp  sp, 208
                  c.beqz      a3, 3629f
                  c.sub       a0, a3
                  slli        s8, s9, 14
                  c.addi4spn  a1, sp, 96
3629:             add         zero, t5, sp
                  c.addi      s5, -1
                  c.li        s2, 30
                  xor         a1, s5, gp
                  c.and       a3, a1
                  c.beqz      a3, 3642f
                  c.lui       ra, 18
                  slti        zero, s5, -1703
                  addi        t5, a4, 1780
                  slt         t2, s3, s7
                  c.or        a1, a2
                  c.sub       a1, a3
                  srai        t5, t5, 0
3642:             slti        t1, t3, 861
                  c.beqz      a1, 3649f
                  c.mv        a3, t5
                  sub         a2, s0, s5
                  bgeu        t0, t2, 3657f
                  sltiu       a3, s3, -312
                  nop
3649:             c.or        s0, a4
                  bgeu        t6, t2, 3657f
                  c.sub       a1, s1
                  c.bnez      a1, 3657f
                  bge         t3, a1, 3669f
                  lui         a1, 805550
                  c.sub       a0, a1
                  beq         t6, a1, 3657f
3657:             slli        zero, t3, 15
                  c.andi      a1, -1
                  srai        sp, s4, 23
                  bltu        t5, t3, 3662f
                  mulhsu      s4, s7, s1
3662:             auipc       s2, 684408
                  mul         a7, gp, tp
                  sub         zero, a4, t2
                  div         s2, a0, t4
                  ori         s7, tp, 1474
                  xor         t1, s10, ra
                  lui         t3, 58794
3669:             divu        s6, s7, t4
                  c.srai      a1, 2
                  c.addi      s10, 23
                  mulhu       tp, s0, s3
                  c.srli      a0, 1
                  sltiu       t3, a0, 1757
                  lui         zero, 252228
                  c.andi      a2, 22
                  c.addi      sp, 25
                  c.andi      a2, 28
                  and         a7, s3, tp
                  bltu        s6, a7, 3688f
                  srl         a7, t2, tp
                  sltu        ra, a4, s4
                  c.andi      a0, 21
                  slti        a1, s10, 1817
                  bltu        s7, a3, 3691f
                  andi        s5, t0, 850
                  c.lui       s6, 19
3688:             c.slli      t0, 14
                  rem         a1, s11, s1
                  c.mv        ra, ra
3691:             slti        a2, t6, 1485
                  add         ra, s9, s5
                  rem         zero, s6, s3
                  c.sub       a3, a0
                  auipc       a0, 269956
                  c.lui       s11, 12
                  mulh        zero, t2, s11
                  blt         s6, t3, 3699f
3699:             blt         t3, s0, 3710f
                  srai        zero, t6, 16
                  c.slli      t1, 28
                  sll         s7, gp, sp
                  auipc       t1, 164780
                  xori        t0, s0, 149
                  c.add       ra, t2
                  c.li        sp, -1
                  mul         s9, s7, s6
                  nop
                  sra         s8, a7, s9
3710:             c.slli      t5, 26
                  mulhsu      s10, gp, gp
                  srl         s2, s2, s2
                  mulh        t4, t0, s8
                  xor         t3, t6, tp
                  c.beqz      a0, 3727f
                  c.srli      a3, 16
                  slli        zero, a0, 17
                  c.addi      ra, -1
                  c.xor       a2, s1
                  slti        s9, s3, 925
                  c.addi      sp, 20
                  c.mv        t5, t4
                  c.srli      a0, 22
                  bne         s1, t2, 3728f
                  slli        zero, sp, 26
                  c.nop
3727:             bge         a7, sp, 3734f
3728:             c.sub       a3, a2
                  slt         t4, s8, zero
                  sra         s4, s7, tp
                  slli        s2, a4, 1
                  c.xor       a5, a3
                  sltiu       a6, ra, 110
3734:             c.addi4spn  a3, sp, 912
                  mulhu       t2, t4, a3
                  c.slli      s5, 30
                  bge         s10, a0, 3749f
                  c.addi4spn  a3, sp, 192
                  and         a0, a4, a1
                  sltiu       a2, zero, -1168
                  add         a6, s1, s0
                  sra         zero, s4, ra
                  mulhu       a1, a3, s6
                  mulhsu      t5, t1, a1
                  mulhsu      t3, t0, sp
                  bge         s3, t3, 3753f
                  divu        a6, t2, s11
                  or          s9, s1, s9
3749:             c.beqz      a0, 3762f
                  and         zero, s3, a5
                  c.srli      a3, 26
                  sll         tp, s0, s3
3753:             addi        a2, t0, 1102
                  mulh        zero, s9, s9
                  mulhsu      a0, s6, t5
                  bne         t5, gp, 3758f
                  c.sub       a1, s1
3758:             c.add       s11, s6
                  div         s8, t4, a7
                  c.bnez      a0, 3770f
                  sub         a7, s3, s9
3762:             xor         s10, t3, t2
                  c.xor       a1, s0
                  bge         a4, ra, 3766f
                  c.and       s0, a3
3766:             c.mv        ra, t5
                  c.bnez      a2, 3775f
                  srli        gp, a6, 10
                  nop
3770:             slti        s9, sp, -415
                  mul         s0, s9, s7
                  c.sub       a0, a3
                  c.andi      a3, -1
                  c.bnez      s0, 3780f
3775:             beq         a7, t0, 3794f
                  c.lui       s11, 2
                  c.nop
                  c.xor       s0, a3
                  or          s2, sp, t6
3780:             bltu        a6, s9, 3790f
                  c.srai      a0, 19
                  auipc       t4, 525654
                  auipc       zero, 702105
                  bne         s10, a2, 3794f
                  sub         ra, ra, a6
                  divu        s9, a7, s9
                  slli        a2, a7, 17
                  sltu        zero, zero, s9
                  auipc       a2, 975679
3790:             srai        s4, s8, 24
                  xor         t2, t2, s8
                  c.srai      a2, 2
                  blt         a6, a2, 3794f
3794:             beq         s3, s4, 3799f
                  c.sub       a3, a3
                  nop
                  addi        a1, a0, -1200
                  c.slli      a3, 1
3799:             mulhu       s11, s7, s11
                  slt         s3, a4, s6
                  c.lui       a1, 12
                  srl         s5, ra, s10
                  divu        a3, a1, t5
                  and         s10, t3, a7
                  c.srli      s0, 12
                  bne         a4, t1, 3810f
                  c.mv        s10, s10
                  ori         t1, s5, -438
                  c.bnez      s0, 3825f
3810:             bltu        t2, ra, 3822f
                  slti        a0, t6, -773
                  mulhsu      t5, a6, zero
                  c.addi4spn  a0, sp, 576
                  c.bnez      a3, 3820f
                  blt         s8, s4, 3822f
                  c.or        a0, a3
                  blt         s0, a4, 3819f
                  slt         s8, s4, s7
3819:             c.bnez      a3, 3827f
3820:             xori        a1, s5, -1120
                  srli        tp, s8, 23
3822:             c.andi      a3, 19
                  c.srai      a1, 22
                  or          t0, t3, s2
3825:             bge         a3, s5, 3830f
                  c.addi      s11, -1
3827:             bge         t1, t1, 3833f
                  c.nop
                  c.li        ra, 12
3830:             sltu        s10, s6, sp
                  c.bnez      a0, 3833f
                  bgeu        s11, s8, 3834f
3833:             c.bnez      a0, 3837f
3834:             c.addi      gp, -1
                  bge         s3, s1, 3841f
                  sltiu       s11, s7, 353
3837:             c.addi16sp  sp, 288
                  sll         sp, t4, t6
                  sll         zero, s10, a7
                  auipc       a0, 734797
3841:             c.sub       s0, a1
                  or          a6, a1, a4
                  bne         s9, t3, 3849f
                  xor         s0, t6, a4
                  auipc       a0, 990865
                  sltiu       gp, a6, 1778
                  xor         s6, t6, s4
                  c.addi16sp  sp, -16
3849:             srl         s9, s8, a0
                  c.beqz      a0, 3858f
                  rem         a2, s7, t5
                  and         a0, t5, s2
                  bltu        a6, s4, 3863f
                  c.mv        a7, s11
                  beq         a7, t6, 3860f
                  c.sub       a1, a3
                  c.addi16sp  sp, -16
3858:             nop
                  slt         a2, t1, t1
3860:             c.addi16sp  sp, 176
                  nop
                  c.or        a0, s0
3863:             bgeu        s5, s3, 3867f
                  divu        tp, s2, sp
                  nop
                  nop
3867:             c.xor       a1, s1
                  c.mv        s3, s1
                  sub         s9, gp, sp
                  andi        t5, s10, -83
                  nop
                  sub         s9, s1, s11
                  add         tp, tp, s1
                  andi        t1, t5, 1620
                  c.srai      a0, 16
                  xori        t4, a2, -425
                  addi        t5, t5, -605
                  xor         zero, s0, s1
                  div         s6, a6, a1
                  c.andi      a0, 19
                  c.and       a3, a0
                  mulhu       s2, s10, t3
                  auipc       zero, 995054
                  or          s11, s0, s7
                  add         gp, a0, t6
                  div         s7, s3, a3
                  c.sub       a3, a1
                  srai        s2, s7, 6
                  slti        s2, t5, 717
                  c.add       s5, a3
                  c.add       ra, s10
                  c.slli      t4, 4
                  addi        gp, s5, 934
                  c.li        a3, 18
                  beq         s11, a2, 3905f
                  c.xor       a1, a1
                  c.slli      t2, 31
                  c.and       a3, a1
                  c.andi      a3, -1
                  and         s7, t3, a6
                  blt         s7, tp, 3903f
                  nop
3903:             or          s4, tp, s10
                  rem         zero, a3, t2
3905:             srai        tp, t2, 27
                  sll         a7, a5, t2
                  mulhu       a6, s2, t1
                  or          a1, t2, a3
                  c.andi      a1, 19
                  c.slli      t2, 28
                  bltu        a6, t6, 3913f
                  mul         t4, ra, s7
3913:             and         zero, s1, s3
                  srai        zero, s2, 25
                  c.and       s0, a1
                  c.beqz      a2, 3924f
                  div         s11, s10, t3
                  rem         t1, a4, s2
                  sll         s3, ra, tp
                  sll         zero, s0, a2
                  c.mv        s3, s6
                  mulhsu      s6, s2, s1
                  c.xor       a3, a1
3924:             addi        s5, a1, -1482
                  sltu        zero, s9, a4
                  add         a7, s8, s10
                  slli        zero, s11, 10
                  c.add       ra, s9
                  blt         sp, s3, 3939f
                  lui         t5, 814173
                  sra         a2, s10, t6
                  c.nop
                  bge         a0, a2, 3949f
                  bne         s9, s4, 3942f
                  srli        a0, a7, 6
                  ori         s8, a7, 954
                  or          s9, t4, s6
                  mul         s0, s4, s2
3939:             srai        zero, t5, 8
                  mulhu       s9, s11, s3
                  sub         s10, s11, a7
3942:             c.addi4spn  a3, sp, 304
                  srl         sp, sp, s7
                  slli        tp, a2, 31
                  sltu        s6, a5, s1
                  c.mv        t0, t6
                  sll         a2, s11, s8
                  xori        t1, s2, -1198
3949:             slli        s5, gp, 0
                  c.lui       ra, 1
                  and         tp, a2, s7
                  c.andi      a0, 4
                  beq         a0, t1, 3960f
                  c.xor       a0, a3
                  srai        s2, gp, 21
                  sra         a3, s1, a3
                  addi        t1, t1, -1645
                  c.andi      a0, -1
                  sra         t3, s1, t3
3960:             c.xor       a3, a3
                  slli        tp, t2, 4
                  andi        a1, s8, -597
                  sub         s0, s1, a1
                  c.andi      a3, -1
                  bltu        a2, a6, 3971f
                  beq         a3, t5, 3973f
                  slti        s5, a5, 232
                  or          s7, a6, s4
                  divu        t3, s8, t6
                  sra         t0, s9, tp
3971:             xor         s7, s6, a3
                  c.sub       a0, a1
3973:             srai        a3, t0, 7
                  blt         a5, t5, 3993f
                  andi        sp, a7, -1904
                  beq         tp, s3, 3983f
                  div         t0, t3, t2
                  srl         s4, gp, a5
                  c.add       s3, s1
                  or          t5, zero, s8
                  mulhu       s8, a0, a5
                  c.xor       a0, a1
3983:             sll         t1, t5, t4
                  c.addi4spn  a5, sp, 320
                  andi        a6, s11, -122
                  slli        a6, a0, 12
                  sltiu       a2, s8, -1126
                  c.mv        t2, sp
                  c.or        a3, a1
                  srl         t1, a7, s3
                  divu        a5, s3, s3
                  andi        s11, t6, -445
3993:             nop
                  beq         s11, s5, 4000f
                  add         a1, t3, s5
                  slt         s5, a7, a4
                  mulhsu      sp, t6, a4
                  c.addi      s5, 7
                  sra         zero, sp, a6
4000:             bge         tp, s2, 4012f
                  srai        a1, a7, 20
                  c.xor       a1, a2
                  c.addi16sp  sp, -16
                  addi        s6, a4, -1244
                  rem         a0, t3, s6
                  c.sub       a1, s0
                  beq         s3, s8, 4019f
                  c.slli      s2, 5
                  bltu        a4, s7, 4020f
                  c.nop
                  lui         zero, 371583
4012:             c.addi4spn  a1, sp, 816
                  sra         s6, t4, tp
                  add         sp, a7, s8
                  c.mv        s11, t4
                  c.slli      a7, 1
                  lui         s4, 723791
                  blt         s4, t4, 4030f
4019:             andi        zero, t4, 1865
4020:             divu        a3, t3, a6
                  xori        t4, s2, 2022
                  c.addi      a1, 22
                  c.andi      a0, 15
                  xor         t3, s9, t3
                  c.add       t1, sp
                  bne         t6, a5, 4027f
4027:             xori        s10, t0, 1874
                  xor         zero, a3, s6
                  mul         gp, t1, ra
4030:             xori        zero, a0, -509
                  lui         s4, 736479
                  mulhsu      s8, tp, a7
                  andi        s5, ra, 1584
                  mulhsu      a7, t6, ra
                  add         a1, gp, s0
                  and         s7, a2, t0
                  bltu        t6, t6, 4050f
                  div         t1, t0, t2
                  blt         s11, s6, 4040f
4040:             c.addi      a3, 8
                  srai        a5, t2, 5
                  c.lui       s11, 18
                  sll         s2, t5, a7
                  c.add       s3, s0
                  mulh        zero, s6, s10
                  sra         a2, s3, a3
                  and         s6, a6, tp
                  sltu        zero, s6, s4
                  srli        s10, a6, 13
4050:             lui         a7, 446363
                  beq         a7, a6, 4056f
                  c.beqz      a3, 4054f
                  c.xor       a0, a1
4054:             divu        s0, s9, t6
                  andi        s9, t1, -1235
4056:             c.addi16sp  sp, -16
                  div         s3, a3, t5
                  or          s0, s1, sp
                  add         s4, s8, a7
                  sltiu       tp, s0, 1600
                  beq         a4, t2, 4071f
                  bgeu        a3, t4, 4068f
                  bltu        a1, s3, 4067f
                  div         zero, sp, tp
                  add         a7, gp, s9
                  c.li        t1, -1
4067:             andi        a3, a3, -1910
4068:             c.mv        gp, t2
                  bgeu        sp, s8, 4085f
                  c.addi      tp, 4
4071:             c.li        a1, 10
                  c.and       s0, a1
                  c.or        a3, a2
                  c.and       a5, a1
                  lui         t5, 803534
                  div         s4, a3, t3
                  mulhu       s7, a7, s5
                  div         t0, a5, a0
                  div         ra, a7, s1
                  c.xor       a1, a0
                  ori         t5, zero, 1814
                  andi        s2, s7, -1643
                  c.and       a0, a0
                  nop
4085:             c.andi      a1, 27
                  ori         tp, a3, 1748
                  andi        s0, s4, -880
                  c.nop
                  blt         s0, s3, 4100f
                  divu        sp, a5, a0
                  c.lui       t2, 8
                  bne         s9, a4, 4099f
                  rem         ra, t0, a6
                  bltu        s3, a7, 4102f
                  ori         s4, t2, 1016
                  xori        s0, t2, -1347
                  c.slli      ra, 24
                  c.bnez      a2, 4100f
4099:             div         s5, t6, t5
4100:             xori        gp, t6, -1967
                  c.lui       ra, 23
4102:             addi        ra, s8, 1570
                  c.nop
                  ori         s6, a4, 441
                  xori        s0, t3, -1073
                  ori         a6, s0, 1292
                  c.srli      a0, 27
                  c.beqz      a3, 4110f
                  c.sub       a3, a2
4110:             c.xor       a3, a1
                  c.or        a3, a1
                  c.nop
                  mulhu       a0, t3, s1
                  mulhsu      a6, zero, a1
                  c.xor       a3, a3
                  slt         zero, t4, s8
                  or          a7, t2, sp
                  sltiu       zero, s8, -344
                  auipc       s7, 810164
                  slti        t3, ra, -1975
                  sltu        ra, zero, gp
                  mul         s4, a7, a4
                  c.srli      a2, 6
                  xori        tp, s11, 451
                  c.mv        a0, a5
                  bne         a3, a5, 4132f
                  srl         s9, a6, s0
                  slli        s6, s2, 1
                  slti        t2, a6, -1654
                  c.andi      s0, -1
                  c.xor       a3, a1
4132:             c.srai      a0, 13
                  srai        tp, t3, 14
                  c.and       a0, a4
                  ori         zero, a2, 855
                  lui         gp, 450199
                  c.andi      a1, -1
                  ori         s7, s1, -139
                  srai        t0, s8, 7
                  c.li        a2, -1
                  slt         s2, t2, t5
                  srli        zero, a6, 4
                  c.slli      s6, 7
                  srl         s10, ra, t4
                  divu        s0, a1, s2
                  divu        s8, s8, t0
                  sub         t0, s3, a0
                  srli        a2, a6, 25
                  bge         s7, s10, 4161f
                  c.li        a6, 29
                  slt         s3, zero, t1
                  or          a7, a5, zero
                  c.and       a3, s1
                  mulh        t5, s4, a1
                  c.andi      a0, 19
                  or          a2, s4, t3
                  sra         s5, sp, tp
                  c.sub       a0, s0
                  c.beqz      a0, 4171f
                  c.nop
4161:             c.lui       s10, 17
                  slti        ra, t6, 325
                  bge         s5, ra, 4173f
                  c.beqz      a1, 4177f
                  beq         t4, ra, 4173f
                  c.addi16sp  sp, -16
                  bge         a7, s2, 4169f
                  sltiu       s0, s9, -635
4169:             sub         s5, a1, s10
                  xor         s10, tp, s10
4171:             bge         sp, t4, 4177f
                  srl         s3, a5, s8
4173:             c.addi4spn  a5, sp, 80
                  sub         ra, tp, a7
                  add         s11, t4, s10
                  c.srai      a1, 16
4177:             and         a7, a1, s3
                  srl         zero, a7, s0
                  mulh        zero, s8, t4
                  c.lui       s3, 25
                  c.xor       a0, s0
                  sltu        a7, sp, s10
                  div         a2, t4, a5
                  xor         t4, a3, a4
                  xor         zero, sp, s7
                  c.andi      a1, -1
                  sra         zero, s7, a7
                  sltu        s4, a4, s10
                  c.or        a3, a3
                  c.sub       a3, a0
                  nop
                  c.sub       a1, a1
                  c.add       a3, s1
                  slti        zero, tp, -1022
                  c.nop
                  bgeu        s10, t6, 4203f
                  slli        s4, sp, 0
                  srl         a3, ra, t3
                  bltu        t6, a3, 4200f
4200:             xor         t1, t2, s5
                  c.addi      ra, -1
                  mulhu       t5, a5, t6
4203:             bne         s10, tp, 4204f
4204:             bgeu        a1, t4, 4223f
                  c.addi16sp  sp, 432
                  srli        s10, a2, 0
                  slli        s9, s10, 6
                  beq         s0, s1, 4215f
                  c.bnez      a3, 4217f
                  sll         s9, s6, s0
                  nop
                  c.nop
                  c.srli      a0, 17
                  nop
4215:             c.bnez      a3, 4220f
                  c.add       a2, a0
4217:             c.or        a3, a4
                  mulhsu      s5, a2, s3
                  srli        t4, a4, 11
4220:             xori        zero, s6, -1976
                  c.li        a2, 4
                  c.and       a3, a3
4223:             beq         tp, a5, 4225f
                  sltiu       a7, t6, 678
4225:             c.andi      a0, -1
                  and         s8, s4, a3
                  ori         a5, tp, -1803
                  add         a6, t3, t0
                  c.addi16sp  sp, 256
                  rem         a6, a4, s7
                  bge         a3, s8, 4237f
                  ori         s2, s8, -1203
                  bge         zero, tp, 4237f
                  c.addi      ra, 23
                  slli        zero, a0, 3
                  addi        s4, sp, -1729
4237:             bgeu        t6, a5, 4249f
                  c.srli      s0, 12
                  blt         t0, s3, 4244f
                  sub         a5, s7, t0
                  srai        s6, t3, 19
                  sltiu       gp, s8, 10
                  slti        ra, a4, -87
4244:             slli        s3, tp, 16
                  nop
                  mulhu       s4, s10, a5
                  c.xor       s0, a2
                  mulh        a7, s4, s3
4249:             c.lui       ra, 11
                  c.xor       a2, a3
                  mulhu       s6, tp, s1
                  and         tp, s6, tp
                  xori        a5, a0, 1824
                  and         s9, t3, s1
                  c.mv        s8, t2
                  c.beqz      a0, 4266f
                  addi        s6, sp, 1184
                  andi        gp, s9, -1392
                  c.beqz      a1, 4261f
                  c.bnez      a1, 4271f
4261:             ori         s5, s7, 1636
                  auipc       t4, 379675
                  c.mv        ra, t0
                  c.andi      a0, -1
                  mulhu       tp, a0, s0
4266:             c.xor       a0, a3
                  sra         a7, a7, a6
                  c.addi16sp  sp, -16
                  c.bnez      a3, 4282f
                  srli        sp, t4, 9
4271:             mulh        gp, s11, t6
                  c.sub       a3, a0
                  divu        zero, a0, s8
                  mul         a7, t5, a5
                  c.xor       a0, a2
                  c.srai      s0, 9
                  auipc       s0, 128227
                  mul         a7, sp, a3
                  mulh        a7, s10, t3
                  c.bnez      a3, 4290f
                  srai        zero, s0, 23
4282:             c.li        ra, 4
                  bne         s0, s6, 4289f
                  sra         t5, s10, zero
                  c.xor       a3, s1
                  c.sub       a0, a4
                  auipc       a7, 586896
                  c.addi      s9, 22
4289:             or          s4, s4, t2
4290:             andi        a6, t2, 312
                  nop
                  sll         t2, a6, s0
                  blt         s7, s4, 4297f
                  slt         s11, s9, t1
                  xor         s9, t4, a2
                  c.lui       s2, 3
4297:             c.xor       a1, s1
                  c.andi      a0, 9
                  ori         gp, a2, -1610
                  srli        s9, s1, 18
                  add         t4, t5, s10
                  ori         s6, t2, -858
                  c.addi16sp  sp, -16
                  auipc       t3, 95705
                  c.srli      a0, 8
                  div         zero, a5, t5
                  mulhu       a1, sp, a5
                  rem         a5, gp, sp
                  or          s6, a7, t0
                  c.mv        s3, s6
                  sltu        s10, t0, s0
                  c.sub       s0, a3
                  c.or        a1, a2
                  c.nop
                  beq         a7, a2, 4323f
                  blt         s7, ra, 4323f
                  srli        zero, t5, 17
                  nop
                  mulh        s6, a0, s7
                  beq         zero, a2, 4326f
                  xor         a6, t6, t4
                  divu        s3, t6, a7
4323:             slti        s2, gp, 1657
                  mul         s4, a1, t6
                  div         a0, s5, t1
4326:             c.addi4spn  a2, sp, 688
                  and         t5, t6, t5
                  c.or        a0, s1
                  c.lui       ra, 26
                  blt         s11, s3, 4338f
                  c.bnez      a3, 4336f
                  rem         zero, s11, s6
                  mul         s2, a3, tp
                  c.andi      a1, -1
                  div         a5, a2, gp
4336:             nop
                  c.lui       tp, 26
4338:             c.and       a3, a3
                  nop
                  slli        s3, t1, 7
                  auipc       zero, 799204
                  c.addi      t2, -1
                  c.slli      a7, 21
                  bgeu        a2, s8, 4356f
                  nop
                  bltu        t5, a0, 4348f
                  mulhu       gp, ra, s2
4348:             bne         s11, t2, 4349f
4349:             c.bnez      a0, 4356f
                  mulhu       tp, a4, a7
                  c.srli      a0, 2
                  sra         zero, a7, s5
                  add         a2, zero, a5
                  lui         t3, 1021075
                  sltu        s4, s4, t1
4356:             c.addi      ra, 8
                  bltu        t2, s5, 4369f
                  c.srai      a3, 30
                  sub         a6, a3, s10
                  c.li        gp, 17
                  sub         a6, a1, t0
                  auipc       s2, 578324
                  sltu        t5, s11, zero
                  c.lui       t5, 28
                  and         s4, s6, s0
                  and         a3, s4, zero
                  srli        a1, a1, 0
                  andi        t2, a6, 1961
4369:             c.addi16sp  sp, -16
                  c.nop
                  sub         zero, t4, s7
                  bgeu        tp, s9, 4380f
                  add         a1, t4, t3
                  mulhsu      a3, t3, t6
                  c.sub       s0, a2
                  addi        t1, a2, 818
                  nop
                  bgeu        s4, t3, 4380f
                  c.bnez      a0, 4395f
4380:             c.add       ra, a5
                  xor         a1, a4, s7
                  mulhsu      a5, s0, a6
                  bltu        a3, s11, 4393f
                  c.xor       a0, a3
                  c.slli      t3, 17
                  bne         t1, a2, 4391f
                  slti        s3, t0, -1618
                  xor         t2, a7, s9
                  c.srli      a1, 8
                  srl         s0, t2, a1
4391:             slti        gp, a7, -2000
                  srai        t5, s9, 11
4393:             ori         t5, s9, 207
                  sub         s9, t3, s3
4395:             c.andi      a2, 30
                  mul         sp, s2, sp
                  c.bnez      a3, 4409f
                  bgeu        a0, sp, 4402f
                  add         t5, a7, t1
                  bne         s10, t2, 4401f
4401:             c.mv        s11, s3
4402:             mulhsu      t0, s10, s10
                  c.srai      a1, 2
                  mul         zero, a1, tp
                  bgeu        s7, a2, 4424f
                  c.bnez      a3, 4413f
                  or          gp, a0, a2
                  ori         s2, tp, -1650
4409:             sll         t5, t1, t3
                  c.srai      a0, 22
                  srai        t0, a0, 7
                  addi        a0, t4, 1372
4413:             slli        s10, t3, 26
                  ori         gp, a1, -1811
                  and         zero, t5, s10
                  slt         s5, t6, t1
                  c.srai      a3, 6
                  c.slli      s4, 25
                  mul         a3, s9, t5
                  addi        t2, t0, -1955
                  srli        s10, s6, 7
                  c.srli      a1, 22
                  c.andi      a5, 17
4424:             c.lui       a3, 28
                  add         s11, a7, s7
                  bne         s3, a4, 4428f
                  c.slli      ra, 15
4428:             divu        a2, s6, zero
                  sll         tp, t1, ra
                  srli        sp, a7, 16
                  lui         s10, 766980
                  c.bnez      a0, 4438f
                  slt         a6, s5, t6
                  c.addi4spn  a3, sp, 448
                  c.bnez      a0, 4441f
                  nop
                  mulhu       tp, s3, gp
4438:             bne         a6, a1, 4448f
                  c.addi4spn  a3, sp, 688
                  ori         ra, s10, 350
4441:             divu        s2, t6, a0
                  sra         a6, a6, sp
                  c.addi4spn  a1, sp, 848
                  blt         s8, gp, 4463f
                  or          tp, t1, t6
                  andi        a5, a6, 1898
                  bge         zero, s9, 4455f
4448:             slli        s7, t0, 2
                  c.addi      a0, -1
                  srai        t1, s10, 16
                  c.andi      s0, 13
                  div         s6, s0, t5
                  c.addi16sp  sp, 432
                  rem         gp, s9, t5
4455:             ori         a7, s3, -1836
                  c.beqz      a3, 4463f
                  add         zero, a1, t1
                  c.srli      a2, 26
                  mulh        t2, a2, t1
                  mulhsu      gp, s0, s3
                  divu        s2, a5, tp
                  mulhsu      a2, gp, t4
4463:             mul         a1, t4, s0
                  c.andi      a2, 14
                  c.and       a0, a0
                  sltiu       zero, s5, 821
                  mul         zero, s8, s9
                  sub         t1, t2, t6
                  slt         a3, t1, s2
                  c.and       s0, a2
                  c.slli      a2, 3
                  ori         s7, ra, 1063
                  xori        s3, s4, 1132
                  sub         s6, s7, tp
                  mul         zero, a7, t2
                  srai        a2, s2, 6
                  bgeu        s2, s4, 4484f
                  lui         t4, 411032
                  auipc       sp, 887139
                  slti        s9, zero, 1208
                  slti        t3, a6, -1914
                  c.slli      s2, 6
                  and         s5, s9, t0
4484:             c.add       tp, a4
                  sub         sp, gp, zero
                  slti        t2, sp, 1362
                  c.srli      a3, 21
                  nop
                  or          t3, s11, t5
                  rem         a3, s5, s0
                  srl         zero, s10, s4
                  divu        zero, s6, zero
                  rem         s9, t1, t3
                  c.or        a0, a4
                  bne         s2, t6, 4505f
                  slli        sp, s6, 6
                  sltu        ra, a4, s2
                  xor         ra, tp, s7
                  or          t5, s11, t1
                  xori        s11, a2, -281
                  div         s6, s6, t6
                  divu        zero, s9, t0
                  sltiu       s7, t5, 1076
                  beq         s7, t5, 4509f
4505:             addi        t3, s10, -1500
                  mulh        a5, s1, s9
                  c.lui       t5, 10
                  c.slli      s2, 1
4509:             add         s8, a1, s4
                  or          zero, a2, t0
                  srli        s4, t2, 25
                  add         s4, tp, s9
                  bltu        t2, s4, 4525f
                  c.addi4spn  a3, sp, 272
                  xor         a5, t5, a0
                  bgeu        s3, t0, 4518f
                  c.slli      t3, 3
4518:             andi        sp, t0, 907
                  sll         s8, s0, s9
                  slt         zero, s7, gp
                  slti        ra, tp, 1664
                  mulh        gp, a2, t3
                  mulhu       a1, s4, s2
                  xori        s7, t4, -1840
4525:             c.addi16sp  sp, -16
                  add         a2, t6, a7
                  slli        a3, ra, 27
                  c.beqz      s0, 4530f
                  mulh        a3, a5, s8
4530:             slt         s5, a3, s1
                  c.xor       a1, a3
                  mul         s7, s4, s2
                  c.sub       s0, a1
                  sub         t2, s1, sp
                  sll         s3, gp, t6
                  nop
                  blt         t1, s5, 4545f
                  auipc       a3, 398453
                  mulhu       a6, a5, t1
                  lui         a6, 1004683
                  c.lui       s0, 6
                  or          gp, a3, a4
                  srai        a0, zero, 29
                  c.and       a3, a0
4545:             c.slli      s9, 12
                  ori         s2, t1, 791
                  c.mv        t5, t1
                  beq         s10, a4, 4549f
4549:             sltu        s8, gp, s4
                  mulh        a5, s1, s1
                  divu        a5, t6, a6
                  bge         tp, t1, 4565f
                  sltiu       s0, s10, 1161
                  sra         t5, s5, t5
                  c.or        a1, a2
                  or          t0, t5, a0
                  bltu        s8, t5, 4559f
                  andi        s4, a7, 1693
4559:             bne         s6, sp, 4563f
                  c.srli      a0, 20
                  slti        zero, s5, 1431
                  c.lui       tp, 7
4563:             nop
                  mulhsu      zero, t3, a2
4565:             divu        t1, s3, s11
                  mulhu       ra, a0, a1
                  c.beqz      a0, 4573f
                  sltu        t0, s4, t4
                  sltiu       a3, a7, 189
                  c.sub       a2, a2
                  c.or        a3, a0
                  xori        t4, a6, 1227
4573:             c.xor       a3, a0
                  srli        sp, s8, 1
                  bgeu        t0, s4, 4582f
                  addi        a3, t6, -1495
                  bge         t4, a0, 4583f
                  c.and       a0, a1
                  xor         s10, t2, s10
                  c.srai      a1, 6
                  auipc       t5, 56641
4582:             c.and       a0, a0
4583:             mulhu       s9, s8, s9
                  c.srli      a0, 2
                  slli        gp, ra, 11
                  and         t0, s1, t3
                  c.add       t3, a0
                  beq         sp, s8, 4590f
                  c.li        ra, -1
4590:             c.addi16sp  sp, -16
                  c.or        a0, a2
                  c.li        a6, 26
                  c.addi      s0, 23
                  bne         s4, s9, 4606f
                  divu        s7, ra, s3
                  c.xor       a0, a3
                  xori        t5, s10, -1930
                  mulh        a0, a4, t4
                  srli        s8, tp, 9
                  mulhsu      tp, t1, t6
                  slli        s6, s10, 6
                  c.srli      a3, 29
                  c.addi      a0, 22
                  c.slli      ra, 1
                  c.andi      a0, 3
4606:             andi        zero, a5, -553
                  blt         t6, s8, 4611f
                  c.slli      gp, 1
                  srai        s4, s7, 1
                  blt         s5, t6, 4622f
4611:             c.addi16sp  sp, -16
                  c.srli      a3, 9
                  c.or        s0, a1
                  slti        gp, a7, -1851
                  ori         t1, ra, -479
                  divu        s6, ra, s8
                  c.bnez      a3, 4627f
                  and         s5, gp, s10
                  beq         s1, s5, 4625f
                  lui         zero, 394345
                  c.add       a7, s11
4622:             c.li        tp, 10
                  c.addi16sp  sp, -16
                  andi        s11, s8, -2028
4625:             c.andi      a0, 23
                  div         s9, a4, s3
4627:             bltu        t0, t3, 4632f
                  mulh        t1, s2, t3
                  sltiu       s3, sp, -2008
                  xor         gp, tp, t4
                  c.slli      a1, 13
4632:             blt         zero, a0, 4642f
                  div         t1, t1, gp
                  c.or        a2, a3
                  c.beqz      a0, 4641f
                  sltu        tp, a0, t3
                  c.lui       ra, 25
                  mulh        a7, a0, s0
                  sltiu       a1, gp, 1694
                  and         s7, s7, t6
4641:             c.mv        s8, t6
4642:             sll         sp, s11, tp
                  and         s7, t3, t4
                  c.srai      s0, 7
                  c.add       ra, s3
                  addi        t2, s1, -2008
                  bne         t1, zero, 4655f
                  srl         s9, a5, a6
                  auipc       a2, 415159
                  add         a5, t5, t2
                  mulh        sp, ra, t3
                  sltu        a3, s4, s3
                  c.addi      ra, -1
                  c.xor       a1, a3
4655:             addi        zero, s5, -576
                  lui         a3, 777533
                  blt         t1, t0, 4668f
                  c.beqz      a1, 4674f
                  sll         s4, s5, s9
                  slli        a1, t4, 5
                  beq         t5, t2, 4662f
4662:             c.li        tp, 12
                  bltu        a6, a2, 4682f
                  div         t4, t6, s1
                  sltiu       s6, zero, -836
                  addi        s6, ra, -1575
                  slli        ra, s4, 24
4668:             c.lui       a6, 15
                  or          a0, t1, a3
                  c.li        s5, 19
                  srai        s0, s10, 31
                  c.slli      s0, 25
                  divu        t2, t6, zero
4674:             sltiu       s3, a2, 197
                  ori         s3, tp, 55
                  c.add       s3, s3
                  nop
                  c.sub       a3, a1
                  c.or        a0, a3
                  c.slli      t1, 24
                  mul         zero, t3, a0
4682:             c.slli      s3, 16
                  rem         s4, a4, s2
                  blt         ra, a5, 4692f
                  c.add       t4, s2
                  mulhu       s6, a0, s10
                  srai        a1, t0, 27
                  sra         zero, s1, s1
                  slt         a1, t0, a6
                  bge         a2, a3, 4692f
                  mulhsu      s8, t2, a1
4692:             rem         zero, s11, s9
                  bltu        zero, t4, 4699f
                  div         t3, s11, s3
                  slt         t0, s4, s6
                  andi        a2, t1, 1126
                  ori         s8, s6, 1927
                  div         t1, s3, s5
4699:             bne         t6, ra, 4711f
                  sub         s11, t6, t4
                  c.sub       a0, a1
                  nop
                  c.nop
                  srli        s10, tp, 15
                  c.lui       ra, 4
                  rem         s11, a0, a3
                  c.lui       a7, 31
                  c.srli      a3, 14
                  c.lui       ra, 24
                  c.srli      a2, 2
4711:             sltiu       a5, a4, -1700
                  ori         a3, s2, -347
                  beq         a0, a3, 4725f
                  div         s0, t6, t5
                  c.xor       a3, s1
                  nop
                  rem         s3, a6, a4
                  sltiu       t4, s11, -1870
                  auipc       t3, 536366
                  mulhsu      t2, a7, a0
                  auipc       s7, 612899
                  add         s3, tp, s3
                  lui         a0, 854968
                  bgeu        s8, gp, 4731f
4725:             c.srli      a0, 1
                  bge         gp, a3, 4733f
                  c.slli      t4, 11
                  bne         s6, s7, 4735f
                  c.nop
                  slli        s0, s11, 2
4731:             or          s7, tp, a4
                  c.nop
4733:             nop
                  slt         s4, a6, a5
4735:             nop
                  c.beqz      a0, 4746f
                  add         a6, s9, t0
                  rem         t5, gp, a6
                  c.or        s0, a5
                  div         s10, s5, sp
                  c.slli      a2, 22
                  nop
                  sltiu       a1, t5, -931
                  c.andi      a3, -1
                  srai        zero, t5, 21
4746:             slli        a0, s3, 4
                  rem         t4, s11, s9
                  and         t2, zero, a7
                  bltu        t2, gp, 4754f
                  c.addi      s0, 7
                  auipc       t4, 698710
                  c.or        s0, a3
                  andi        zero, s3, 1710
4754:             c.bnez      a0, 4756f
                  lui         s2, 680591
4756:             c.srli      a3, 3
                  lui         s3, 891784
                  srai        a0, t6, 2
                  sll         t1, s5, zero
                  blt         s8, a2, 4766f
                  mul         s7, s4, s3
                  lui         zero, 369065
                  mul         s0, ra, zero
                  mulhu       s9, t0, t0
                  sltu        s10, a2, a3
4766:             c.nop
                  or          s8, s5, s6
                  c.andi      a3, 18
                  addi        s7, s11, 1228
                  c.addi      s7, 8
                  nop
                  sltiu       a3, t0, 644
                  srai        gp, s4, 15
                  mulhu       s9, a7, t4
                  sra         gp, s3, s2
                  ori         s0, a0, 754
                  and         zero, a7, a7
                  lui         zero, 748578
                  slli        s7, gp, 26
                  c.or        a1, s1
                  mul         s2, t3, s0
                  rem         a5, s0, a7
                  ori         zero, tp, -692
                  div         t3, a5, t0
                  sll         t4, gp, s5
                  slli        s0, a6, 14
                  c.srai      a5, 21
                  or          s4, a0, s4
                  c.slli      a1, 8
                  c.or        a0, a3
                  c.addi      ra, 28
                  c.beqz      s0, 4794f
                  mulhsu      s0, a2, s9
4794:             mulh        t3, t1, s3
                  srl         s4, a4, t3
                  sltu        a7, ra, s3
                  bgeu        s3, a4, 4805f
                  or          s7, sp, s11
                  div         tp, a7, t5
                  c.li        t4, -1
                  div         a5, s7, a2
                  sltiu       zero, s1, 1833
                  sll         s6, a2, t6
                  c.nop
4805:             sltiu       zero, sp, -1010
                  srai        t4, s3, 0
                  slli        a1, tp, 4
                  bltu        t5, t5, 4814f
                  blt         ra, a5, 4821f
                  bltu        a0, a2, 4820f
                  c.andi      a3, -1
                  mulh        a2, t3, tp
                  slt         s0, t5, s10
4814:             mulh        a3, t4, ra
                  c.srai      s0, 24
                  div         sp, s7, a6
                  slti        zero, ra, 1219
                  c.beqz      a3, 4819f
4819:             sltu        zero, t3, s9
4820:             sltiu       zero, a5, -459
4821:             mulh        s9, a5, s7
                  c.lui       t1, 20
                  sub         a0, a6, tp
                  bgeu        s11, a0, 4837f
                  c.slli      s5, 5
                  mul         t0, s0, s10
                  mul         a6, a7, a1
                  xor         ra, a1, a3
                  c.bnez      a0, 4833f
                  bge         a3, t1, 4835f
                  sll         a5, a3, gp
                  c.or        a3, a0
4833:             mulhsu      a6, s11, s2
                  bne         s3, s1, 4835f
4835:             sltiu       t4, t6, -398
                  c.andi      a5, -1
4837:             sub         s2, t1, s10
                  sltiu       s3, t3, -663
                  c.slli      t5, 20
                  bne         t5, t6, 4846f
                  c.nop
                  c.add       s3, tp
                  lui         t5, 717375
                  and         ra, s10, t0
                  c.beqz      a0, 4853f
4846:             c.add       s2, a6
                  divu        a3, zero, a1
                  mulhu       a5, a5, sp
                  c.lui       a1, 20
                  and         sp, t5, t3
                  slli        s11, s5, 14
                  xori        s0, s9, -1549
4853:             bltu        t1, s10, 4857f
                  c.mv        t3, s8
                  sra         s6, a5, s0
                  blt         t6, a4, 4858f
4857:             c.srli      a2, 16
4858:             srai        zero, gp, 8
                  c.andi      a3, -1
                  c.srai      a0, 1
                  slli        t4, s4, 9
                  bgeu        tp, gp, 4878f
                  slli        t1, s0, 30
                  c.beqz      a2, 4875f
                  c.sub       a1, a3
                  bne         t4, s5, 4876f
                  sll         s6, s8, sp
                  slti        a0, s5, 149
                  c.add       sp, t0
                  andi        t0, s8, 1559
                  addi        tp, s2, 1918
                  c.or        s0, a1
                  bge         t1, t1, 4878f
                  sltiu       s7, t5, -684
4875:             srl         zero, t6, zero
4876:             bge         t2, a0, 4882f
                  c.bnez      a1, 4884f
4878:             c.bnez      a1, 4897f
                  sltiu       s6, s3, 1308
                  srai        t0, sp, 15
                  div         s6, s2, a1
4882:             c.mv        a7, s0
                  slt         s5, s5, gp
4884:             xor         s11, s5, s11
                  auipc       s11, 446739
                  c.srai      s0, 11
                  sub         t2, zero, s9
                  sltiu       t1, ra, 582
                  auipc       sp, 784652
                  or          s2, a7, s2
                  rem         s6, zero, t3
                  c.addi      s2, 14
                  andi        t2, a7, -1368
                  auipc       s0, 620003
                  bne         a3, a0, 4905f
                  div         a1, zero, a1
4897:             div         zero, ra, sp
                  or          zero, s9, t1
                  divu        a6, s6, s3
                  sltu        s5, tp, a5
                  divu        a2, sp, s7
                  c.add       s7, a7
                  srai        sp, t1, 20
                  c.addi      ra, 26
4905:             c.mv        t1, a4
                  auipc       t5, 922738
                  slt         s3, t4, s5
                  c.nop
                  c.xor       a3, a2
                  bge         sp, s0, 4914f
                  ori         ra, s10, -1720
                  c.bnez      a3, 4920f
                  blt         a5, t3, 4924f
4914:             c.addi4spn  a1, sp, 480
                  c.bnez      a3, 4925f
                  c.bnez      a3, 4928f
                  c.addi16sp  sp, 272
                  divu        a7, a6, gp
                  sltiu       ra, s3, -1146
4920:             c.or        a2, a2
                  or          s11, a3, a0
                  c.add       t5, a7
                  divu        zero, t5, s10
4924:             c.li        a6, -1
4925:             c.srai      s0, 1
                  slli        s11, s1, 31
                  c.bnez      a1, 4928f
4928:             bgeu        t2, s5, 4934f
                  andi        t5, t1, -1026
                  blt         a2, gp, 4943f
                  c.xor       a2, a2
                  sra         s7, a5, s7
                  c.or        a5, a3
4934:             c.addi16sp  sp, 80
                  c.and       a0, a2
                  blt         t4, tp, 4937f
4937:             slli        t2, s3, 16
                  c.slli      s9, 21
                  add         t4, t4, sp
                  sltiu       t3, a0, 902
                  or          s3, s5, t5
                  lui         s11, 926433
4943:             bltu        s4, s7, 4945f
                  c.lui       s0, 26
4945:             c.bnez      a0, 4947f
                  bne         t5, a1, 4954f
4947:             addi        s7, a3, 1406
                  c.sub       a0, a0
                  divu        s2, t6, s8
                  c.addi      ra, -1
                  c.addi      ra, 9
                  nop
                  bne         t1, gp, 4955f
4954:             mulhu       s8, ra, a7
4955:             mulhsu      a7, zero, a0
                  slli        s8, tp, 8
                  slli        s9, t5, 24
                  mulhu       zero, s6, s4
                  nop
                  c.and       a1, a3
                  c.beqz      a2, 4968f
                  and         zero, a1, t3
                  beq         a4, a6, 4971f
                  c.mv        s10, t3
                  srli        gp, s7, 19
                  c.beqz      a0, 4978f
                  mul         sp, t1, a2
4968:             c.slli      ra, 14
                  div         s5, tp, s3
                  c.and       s0, s1
4971:             c.mv        a2, s0
                  lui         s3, 77959
                  sra         a5, s3, t5
                  c.andi      a3, 30
                  sltiu       s3, s11, -313
                  c.addi      t4, 30
                  c.bnez      a0, 4979f
4978:             nop
4979:             c.slli      t5, 24
                  addi        s7, t4, -532
                  beq         s10, a6, 4985f
                  c.add       s8, s9
                  sltiu       a0, a1, 1215
                  bge         s9, zero, 4990f
4985:             sll         s7, gp, t4
                  srai        s4, s2, 11
                  c.and       a1, a5
                  rem         gp, t1, s10
                  bltu        s8, t3, 4995f
4990:             bltu        t5, s2, 4995f
                  or          s8, sp, t6
                  c.or        a1, a2
                  auipc       t1, 773066
                  div         s11, a1, s2
4995:             c.srli      a1, 23
                  rem         a7, s11, s8
                  bne         t2, zero, 5013f
                  c.addi      a7, -1
                  div         t3, a5, s3
                  sub         zero, t2, s10
                  c.slli      tp, 24
                  mulhu       s0, t4, tp
                  ori         s7, a6, -621
                  mul         a2, t1, t0
                  c.nop
                  divu        zero, s6, s11
                  auipc       zero, 376210
                  bgeu        a7, s2, 5020f
                  c.or        a2, a0
                  c.slli      s8, 1
                  and         s10, a4, t5
                  c.lui       s3, 1
5013:             sll         zero, a1, s9
                  c.li        t5, -1
                  andi        sp, t5, -380
                  srl         s7, a2, a4
                  c.lui       a0, 28
                  xor         a6, sp, s7
                  srli        sp, s0, 5
5020:             mulhsu      t1, a7, t4
                  bltu        t2, s1, 5028f
                  mul         tp, s3, t6
                  bge         s3, t4, 5033f
                  xor         a3, sp, tp
                  sll         s11, s1, s1
                  c.nop
                  beq         s5, s11, 5029f
5028:             c.or        a3, a1
5029:             add         t4, a0, a2
                  c.srai      a0, 7
                  mulhu       s7, t4, zero
                  divu        t2, t1, s9
5033:             c.mv        s7, s3
                  andi        t1, s5, -757
                  srai        a0, s4, 12
                  sra         a5, a7, t6
                  slli        s9, a6, 17
                  sll         t5, a3, a7
                  auipc       zero, 41700
                  addi        a3, a6, 301
                  mulh        t3, s0, s11
                  mulhu       a5, ra, t0
                  c.srli      a0, 25
                  divu        a5, zero, t2
                  c.addi      t3, -1
                  c.or        a3, a2
                  c.srai      a0, 25
                  srai        t0, a1, 22
                  and         sp, a0, t0
                  c.xor       a0, s0
                  nop
                  bgeu        t2, a2, 5059f
                  ori         t2, s6, -1896
                  bne         t2, zero, 5056f
                  bne         s3, a4, 5061f
5056:             c.addi16sp  sp, 304
                  mulhu       zero, a6, s9
                  sll         t0, a2, a5
5059:             slli        a6, gp, 17
                  divu        a6, t5, s5
5061:             mulhu       s2, s5, a0
                  auipc       t2, 957461
                  mul         s5, a2, ra
                  c.srai      a1, 13
                  bltu        sp, a6, 5071f
                  blt         s1, a6, 5078f
                  bne         s6, s9, 5069f
                  c.srli      a2, 13
5069:             c.xor       a5, s1
                  c.andi      a2, 4
5071:             bne         sp, gp, 5072f
5072:             or          gp, a2, s11
                  slli        zero, t0, 23
                  c.add       t5, s4
                  or          zero, s6, s7
                  sll         gp, a6, s7
                  mulhsu      a7, a7, ra
5078:             slli        a3, t0, 12
                  srl         t5, ra, zero
                  ori         s9, a0, -706
                  and         s4, s3, a5
                  c.srai      a3, 25
                  xor         s10, s3, s8
                  auipc       s9, 714579
                  c.sub       a1, a3
                  slt         t0, s10, s0
                  c.and       a2, s1
                  mulh        t0, a6, t0
                  bltu        a3, s11, 5093f
                  and         t5, s4, s7
                  divu        a3, s0, a6
                  and         sp, s0, s2
5093:             or          ra, a2, t5
                  c.add       sp, t3
                  bltu        s3, s6, 5101f
                  sll         s0, s2, t3
                  sll         a7, sp, s9
                  mulhsu      t1, a0, t5
                  sra         zero, t3, s4
                  c.xor       a3, a1
5101:             mulhu       a7, s6, s6
                  c.slli      a1, 31
                  c.srai      a0, 11
                  srl         s10, a7, t6
                  c.xor       a0, a0
                  c.nop
                  nop
                  divu        s8, s10, a1
                  xor         s0, s2, s0
                  andi        zero, s0, -2043
                  sub         a6, t0, sp
                  bne         a5, s9, 5122f
                  slli        t5, a3, 14
                  auipc       sp, 285328
                  slli        t4, tp, 7
                  c.slli      s8, 17
                  c.nop
                  slt         a2, a0, gp
                  c.and       a3, a2
                  c.andi      a3, -1
                  sra         a0, s2, t4
5122:             mulhsu      zero, a4, a4
                  c.addi16sp  sp, 272
                  slli        s4, a1, 23
                  sltu        t3, a5, a7
                  div         zero, s1, s2
                  c.mv        s6, sp
                  sltu        s0, a0, t4
                  c.or        a1, a1
                  c.nop
                  sll         s7, t0, s7
                  slli        s9, t2, 27
                  bne         a3, s3, 5141f
                  andi        s2, t0, 918
                  bltu        s10, s6, 5141f
                  c.srli      a2, 10
                  c.bnez      a3, 5141f
                  addi        zero, s7, 789
                  c.srli      a2, 26
                  blt         a2, zero, 5152f
5141:             bne         t1, s1, 5152f
                  c.xor       a0, a0
                  c.bnez      a0, 5150f
                  c.addi      s9, -1
                  c.andi      a3, -1
                  slli        a2, s0, 7
                  bgeu        s11, s2, 5148f
5148:             c.mv        s3, ra
                  srai        a6, s11, 4
5150:             auipc       a0, 598103
                  mul         a2, s3, a4
5152:             c.lui       t5, 26
                  bne         s10, s5, 5158f
                  c.or        a5, s1
                  lui         zero, 378334
                  c.or        a3, a1
                  or          s2, s4, a2
5158:             c.slli      t0, 30
                  xori        s7, a3, -1531
                  xori        t4, s1, 302
                  mulhsu      s6, a3, a5
                  beq         s4, t5, 5178f
                  c.add       s4, s2
                  c.xor       s0, a0
                  auipc       s10, 427854
                  c.srai      a5, 19
                  srai        tp, t3, 15
                  addi        s4, a0, -1735
                  sub         a3, a7, a1
                  xor         a6, t2, s6
                  sltu        a1, gp, a6
                  bge         t1, tp, 5184f
                  c.add       t0, s7
                  xor         zero, a7, sp
                  mul         zero, ra, s10
                  c.lui       ra, 5
                  c.xor       a1, a2
5178:             nop
                  auipc       a2, 303197
                  div         s6, ra, t3
                  addi        a1, s10, 775
                  bge         t6, s6, 5187f
                  ori         a2, a7, 1559
5184:             nop
                  addi        s9, s8, -610
                  blt         s9, a0, 5196f
5187:             srl         zero, t2, s11
                  rem         t3, a6, t6
                  srai        s8, s6, 23
                  bgeu        a2, tp, 5192f
                  c.srai      a1, 29
5192:             ori         t1, s1, -617
                  bge         a1, t6, 5203f
                  c.andi      a3, 11
                  c.addi      s4, 19
5196:             or          a7, s4, t2
                  c.xor       s0, a0
                  beq         s4, tp, 5206f
                  c.or        a2, a0
                  bne         a5, a6, 5213f
                  or          zero, ra, s0
                  c.sub       a1, a0
5203:             ori         s2, s11, 24
                  srai        zero, a4, 30
                  c.nop
5206:             c.slli      s5, 22
                  divu        a7, a1, a6
                  c.or        a3, s1
                  xor         s6, s6, a1
                  add         s3, t3, a0
                  div         ra, s7, t3
                  sra         zero, s9, t3
5213:             srl         s4, s4, sp
                  auipc       t3, 613313
                  c.xor       s0, a1
                  slt         s2, sp, a3
                  c.li        a2, 5
                  mulh        a0, s11, s5
                  c.addi16sp  sp, 400
                  addi        s5, s8, -804
                  sltu        s2, s7, zero
                  c.addi4spn  a3, sp, 192
                  beq         s7, s9, 5231f
                  divu        a2, a4, sp
                  rem         a5, t3, a7
                  c.andi      s0, -1
                  div         s7, a0, s2
                  mulh        s11, s1, s10
                  c.mv        t3, t3
                  c.beqz      a3, 5237f
5231:             blt         a3, gp, 5250f
                  bne         t4, t4, 5239f
                  blt         s11, t1, 5237f
                  c.and       a3, s1
                  div         sp, tp, a1
                  c.bnez      a0, 5246f
5237:             srli        zero, t1, 16
                  andi        a6, t0, 404
5239:             srl         t2, a2, a6
                  c.beqz      a3, 5246f
                  sub         sp, a1, a7
                  c.lui       s7, 5
                  blt         tp, a1, 5245f
                  bne         t3, s3, 5251f
5245:             bge         ra, t0, 5253f
5246:             c.addi      ra, -1
                  srl         s2, a5, ra
                  c.nop
                  mulh        s8, sp, s7
5250:             c.addi16sp  sp, -16
5251:             xori        t3, s2, -1148
                  c.andi      a1, -1
5253:             lui         t5, 630756
                  blt         a6, s5, 5255f
5255:             lui         s8, 261130
                  mulhu       a1, a6, t3
                  divu        sp, s11, t4
                  blt         s4, t3, 5260f
                  beq         s2, t3, 5278f
5260:             bne         s4, t0, 5268f
                  bne         s6, a3, 5267f
                  xor         t0, a6, a4
                  c.addi      s7, 11
                  c.mv        s10, s8
                  addi        s6, s9, 1471
                  sra         s11, t4, s0
5267:             mulh        s10, a6, s3
5268:             and         t0, a6, ra
                  or          s2, s8, a3
                  andi        a1, zero, -1381
                  c.slli      a1, 6
                  mul         t0, t5, a0
                  c.slli      a1, 20
                  nop
                  mulhsu      t3, s1, tp
                  beq         s2, tp, 5286f
                  mulhu       zero, a2, t0
5278:             mulhu       t0, s10, a2
                  addi        s7, t6, -1238
                  mulh        gp, a0, s9
                  srl         s11, t3, t4
                  mulhu       a2, a2, ra
                  ori         zero, zero, 437
                  and         t0, a0, s10
                  auipc       s8, 396123
5286:             sra         s2, a4, a5
                  c.add       s0, t4
                  c.and       a3, a3
                  c.bnez      a3, 5302f
                  bne         tp, zero, 5306f
                  c.nop
                  sltiu       zero, a4, -1105
                  and         s3, s9, t5
                  xori        sp, s5, -1899
                  divu        zero, gp, s7
                  sltiu       a6, s9, -1856
                  div         s4, a6, t3
                  sltu        s10, s4, t5
                  srl         ra, a1, a3
                  c.sub       a0, a1
                  sltu        zero, s3, s10
5302:             div         s10, t0, t5
                  c.or        a0, a1
                  c.li        sp, 3
                  andi        t1, a7, -362
5306:             c.addi      s10, 29
                  c.addi      s0, 15
                  lui         zero, 84788
                  addi        s0, t6, 230
                  c.xor       s0, a1
                  sub         zero, s6, s6
                  c.sub       a0, s1
                  srli        s3, a7, 17
                  sltiu       s9, t6, 196
                  c.slli      tp, 1
                  c.bnez      s0, 5328f
                  slli        zero, s2, 1
                  xor         s8, s2, t1
                  xor         tp, t6, a1
                  c.mv        t1, s2
                  ori         t0, t6, -882
                  slli        zero, zero, 28
                  slli        t2, a2, 4
                  srai        s2, a1, 5
                  beq         ra, s5, 5331f
                  rem         t4, a2, a2
                  xor         s9, s6, t0
5328:             srli        s8, s10, 28
                  beq         t6, tp, 5335f
                  c.lui       s0, 12
5331:             add         a1, ra, s6
                  beq         t3, s9, 5340f
                  c.nop
                  c.or        a0, a0
5335:             mul         t3, t6, a3
                  lui         zero, 843486
                  auipc       s10, 163013
                  divu        zero, t1, a2
                  sll         s4, s1, s0
5340:             mulhsu      t1, a6, a4
                  bne         s10, a6, 5343f
                  c.srai      a0, 15
5343:             c.bnez      a0, 5348f
                  c.beqz      a2, 5356f
                  c.and       s0, a2
                  c.nop
                  c.addi16sp  sp, 48
5348:             sub         a0, sp, ra
                  slt         s4, s4, ra
                  c.li        t4, -1
                  c.bnez      a0, 5363f
                  srai        gp, s5, 20
                  sub         a3, a5, a2
                  rem         zero, a5, a2
                  c.srli      s0, 8
5356:             mulhu       t4, a3, s5
                  sltu        s2, a3, s2
                  beq         a3, a3, 5365f
                  sll         s11, s2, a1
                  c.lui       t1, 12
                  c.slli      ra, 1
                  divu        sp, s4, s9
5363:             c.addi      s8, -1
                  c.xor       a0, a0
5365:             xori        s4, t2, -1314
                  auipc       ra, 875267
                  mulh        t5, s7, s0
                  c.bnez      a0, 5372f
                  addi        zero, s4, -1883
                  mulhu       zero, s2, s7
                  xor         a6, sp, zero
5372:             c.addi4spn  a0, sp, 48
                  auipc       s9, 568954
                  sra         s4, s4, s4
                  xor         s0, sp, s0
                  c.add       a3, ra
                  nop
                  c.addi16sp  sp, 256
                  blt         a3, s3, 5380f
5380:             c.or        a0, a1
                  c.slli      ra, 30
                  slti        s10, t6, -436
                  slti        tp, a6, -752
                  sll         s11, t4, a6
                  c.slli      s9, 24
                  sltu        ra, a4, sp
                  nop
                  c.addi16sp  sp, -16
                  bge         s10, ra, 5399f
                  c.beqz      a3, 5392f
                  lui         zero, 949582
5392:             and         ra, t1, a0
                  xor         sp, a6, a0
                  c.and       a0, a2
                  mulh        a6, a0, s6
                  sub         s7, tp, a2
                  or          t2, t1, t2
                  mulhu       s10, t0, t2
5399:             lui         s8, 210511
                  c.or        a0, s1
                  sub         s4, a4, s10
                  xor         a2, t4, sp
                  c.bnez      a3, 5414f
                  or          s7, a1, gp
                  srli        t4, t6, 21
                  and         zero, sp, zero
                  and         a6, s10, s9
                  slt         t2, a4, a7
                  sub         s4, s0, t0
                  addi        a3, s9, -86
                  auipc       a7, 390532
                  mulhsu      s11, t4, a4
                  mulhsu      a0, s10, t3
5414:             slli        sp, s4, 28
                  rem         a2, s8, t5
                  sub         t1, ra, a5
                  nop
                  slti        gp, s11, 1060
                  c.addi4spn  a3, sp, 176
                  sub         s2, a7, s5
                  slli        s6, s4, 28
                  c.addi      a3, -1
                  srl         s7, a2, s0
                  sll         zero, t3, s2
                  c.addi16sp  sp, -16
                  or          zero, a7, s4
                  c.nop
                  c.bnez      a3, 5433f
                  c.sub       a5, a0
                  mul         a7, t3, s4
                  srli        t4, t3, 5
                  c.nop
5433:             c.addi16sp  sp, -16
                  mul         s5, s8, t4
                  slli        a3, s1, 23
                  c.addi4spn  a3, sp, 320
                  c.li        a7, -1
                  beq         s4, t3, 5450f
                  c.sub       a0, s0
                  blt         t6, tp, 5442f
                  mul         zero, a6, a7
5442:             bltu        t4, t0, 5447f
                  add         a7, t5, a2
                  rem         zero, t6, a7
                  c.mv        tp, s5
                  mul         t0, t2, a5
5447:             c.addi16sp  sp, -16
                  addi        ra, s4, -1963
                  c.beqz      a2, 5459f
5450:             slli        zero, s4, 23
                  mulhsu      zero, s4, a6
                  mul         a5, gp, a6
                  or          s2, a7, t5
                  sltiu       t1, t4, -1219
                  bgeu        t3, a4, 5456f
5456:             srli        s5, gp, 23
                  c.or        s0, a3
                  div         a7, a2, ra
5459:             beq         a0, t1, 5475f
                  sltiu       sp, s1, 1916
                  srl         t2, s3, s0
                  mulhsu      tp, s9, t4
                  srl         a7, a5, t5
                  c.and       a2, a1
                  srli        a2, s5, 10
                  bgeu        s4, ra, 5485f
                  xori        zero, s7, 1117
                  srai        s4, gp, 26
                  xori        a3, s1, -408
                  c.li        s0, 18
                  c.addi      sp, -1
                  c.addi      s6, -1
                  mulhsu      tp, t6, s0
                  c.and       a0, s1
5475:             c.addi4spn  s0, sp, 624
                  c.addi16sp  sp, -16
                  c.srli      a0, 24
                  sltiu       t0, t6, 57
                  srli        s7, a6, 1
                  mulh        a5, t5, a2
                  beq         a3, s7, 5483f
                  bge         a1, s1, 5492f
5483:             c.beqz      a3, 5485f
                  sll         t2, a7, t0
5485:             beq         sp, a5, 5493f
                  auipc       s2, 553564
                  div         t1, t6, s9
                  c.srli      a3, 26
                  c.add       ra, t4
                  c.bnez      a3, 5502f
                  blt         a6, s11, 5495f
5492:             divu        s3, s1, s7
5493:             c.and       a3, a0
                  mulhsu      t5, s7, s1
5495:             mul         t0, a7, t4
                  c.andi      a3, -1
                  c.andi      a1, -1
                  c.or        a3, a1
                  andi        a5, t3, -1931
                  c.srai      a0, 1
                  slt         s6, s4, s10
5502:             srl         s4, s8, a6
                  srai        a2, s3, 27
                  divu        t4, s5, s0
                  c.sub       a3, a4
                  slli        s5, s4, 14
                  nop
                  bgeu        s4, ra, 5520f
                  c.nop
                  mulhsu      tp, t4, a6
                  mulh        ra, s9, tp
                  srli        s7, t6, 3
                  mulh        a6, s2, s7
                  add         a1, s9, s7
                  or          s4, s1, tp
                  c.srli      a0, 1
                  c.bnez      s0, 5524f
                  blt         s3, zero, 5525f
                  sra         a1, t0, t3
5520:             lui         s9, 551922
                  andi        t5, a7, -1672
                  sll         s7, a3, s9
                  c.srli      s0, 27
5524:             srl         zero, a6, s5
5525:             c.srli      a3, 17
                  bltu        gp, t0, 5532f
                  rem         a6, a2, t6
                  c.mv        s3, s3
                  c.beqz      a3, 5534f
                  c.addi4spn  a1, sp, 272
                  c.beqz      a3, 5539f
5532:             c.li        s7, 15
                  srli        s2, s9, 16
5534:             sll         s10, a3, s5
                  div         s3, s1, zero
                  c.lui       s5, 7
                  div         a6, s2, s8
                  beq         s8, s11, 5544f
5539:             ori         a7, a0, 990
                  bltu        s9, a2, 5544f
                  addi        s5, ra, -207
                  bltu        a6, s2, 5555f
                  andi        zero, sp, -604
5544:             add         a0, s4, s8
                  sltu        t2, a5, s2
                  c.slli      tp, 16
                  sub         s7, t6, gp
                  add         s11, t4, a0
                  sll         t2, t1, t5
                  c.bnez      a3, 5556f
                  mulh        t1, s7, ra
                  addi        a3, t6, -816
                  bge         s3, s3, 5564f
                  c.addi4spn  a0, sp, 800
5555:             bne         a5, a1, 5565f
5556:             c.srai      a1, 16
                  c.or        a2, a2
                  lui         a6, 1028542
                  c.andi      a1, 6
                  bgeu        t0, a2, 5567f
                  c.addi16sp  sp, -16
                  lui         s6, 593713
                  divu        ra, a3, a7
5564:             c.addi4spn  a0, sp, 64
5565:             xori        a3, t3, 1565
                  srai        ra, a2, 20
5567:             nop
                  c.add       t1, a7
                  slli        s7, t6, 0
                  rem         zero, a3, t1
                  c.nop
                  sltu        a1, a4, s3
                  sll         s6, t3, zero
                  auipc       t5, 828509
                  sub         s10, s10, tp
                  c.sub       a3, a0
                  mulhsu      tp, a5, s10
                  auipc       tp, 3526
                  c.nop
                  c.lui       s8, 26
                  xori        s5, s3, 310
                  mulhu       a2, a4, a6
                  slli        s10, t5, 25
                  mulhu       zero, s4, t1
                  bge         s5, s11, 5587f
                  or          t0, a7, s11
5587:             sll         s4, tp, a5
                  rem         zero, a1, t3
                  c.srai      a1, 17
                  c.nop
                  bne         t1, a2, 5599f
                  c.srai      a2, 10
                  bge         s2, s0, 5594f
5594:             c.or        a2, a2
                  nop
                  c.mv        ra, t4
                  srai        s0, s5, 24
                  c.and       a3, s1
5599:             c.srai      a1, 21
                  mulhsu      s7, t1, t2
                  mul         s7, t1, s4
                  sub         t4, t0, s0
                  div         a0, a2, zero
                  sra         zero, s1, s11
                  c.addi      ra, -1
                  sltu        t3, t1, a0
                  c.li        t3, 30
                  add         s4, a6, s8
                  srai        a7, t5, 1
                  sltiu       s9, s7, 1290
                  mulhu       s9, a6, t4
                  c.xor       a0, a2
                  lui         zero, 949219
                  c.slli      gp, 14
                  xor         zero, t3, t3
                  c.nop
                  c.bnez      s0, 5623f
                  c.nop
                  xor         a2, a6, t0
                  lui         s0, 43952
                  c.lui       ra, 6
                  blt         t4, s2, 5634f
5623:             or          t1, gp, s6
                  c.mv        s9, s0
                  xori        a3, s2, -841
                  srai        s11, ra, 17
                  rem         a5, a3, s10
                  andi        s0, a5, -553
                  c.nop
                  xori        zero, a0, -423
                  xori        s11, s4, -1890
                  bltu        a7, s10, 5639f
                  c.andi      a2, -1
5634:             xori        gp, a2, 1997
                  or          s3, s10, s3
                  mulhu       a7, s1, s0
                  slt         gp, a4, t5
                  c.lui       s9, 25
5639:             c.andi      a0, 4
                  add         t2, s6, t1
                  srl         sp, s0, t5
                  c.or        a2, a2
                  c.srai      a0, 23
                  slli        t1, t4, 8
                  slli        zero, s10, 18
                  slli        zero, gp, 31
                  sll         s3, a7, tp
                  mul         s7, ra, a6
                  or          tp, a5, a3
                  add         a7, s4, s9
                  sll         tp, a1, s11
                  c.slli      t0, 19
                  c.andi      s0, 26
                  c.srli      a0, 21
                  addi        s2, s4, -1244
                  mulh        s2, a0, zero
                  slli        t3, t4, 5
                  blt         s4, s5, 5660f
                  c.addi      s9, -1
5660:             auipc       s2, 263125
                  addi        ra, t2, -646
                  c.andi      a0, -1
                  and         s2, s4, gp
                  c.bnez      a3, 5674f
                  add         s4, a4, s11
                  c.srli      s0, 3
                  c.beqz      a3, 5673f
                  and         zero, s3, a0
                  c.beqz      a3, 5670f
5670:             lui         s5, 544625
                  c.li        ra, 2
                  divu        s6, a6, s4
5673:             sll         s6, a3, a5
5674:             c.beqz      a0, 5684f
                  mulhu       zero, a2, s6
                  add         t5, s4, a0
                  c.bnez      a5, 5684f
                  xori        s11, a0, 173
                  sltiu       ra, t4, 469
                  sub         a0, s10, t4
                  srai        a3, sp, 21
                  c.or        a0, a2
                  sltu        a0, a3, t6
5684:             c.mv        a3, a4
                  c.mv        s0, t4
                  beq         gp, a5, 5694f
                  xor         s3, a0, s9
                  mulh        s2, s1, s8
                  c.srli      s0, 31
                  andi        t1, s9, -1498
                  slt         s2, a0, t2
                  bne         a0, t0, 5702f
                  c.srli      a3, 30
5694:             c.srli      a3, 26
                  mulh        sp, s2, s3
                  add         zero, s11, t3
                  sub         t5, s3, s2
                  add         t2, s9, s10
                  c.lui       s10, 30
                  c.beqz      a5, 5704f
                  slli        zero, s8, 14
5702:             andi        zero, s0, 665
                  nop
5704:             c.and       a0, s0
                  lui         t2, 86195
                  blt         s10, s1, 5718f
                  bge         s8, t6, 5709f
                  srl         zero, s1, t5
5709:             slt         a3, a6, a7
                  sltu        s6, a7, a1
                  rem         s0, t0, s4
                  c.or        a3, a5
                  slli        ra, t1, 26
                  c.addi      t1, -1
                  bgeu        a4, s7, 5727f
                  slt         s5, s7, s9
                  auipc       sp, 195816
5718:             c.lui       a0, 1
                  srai        t4, t0, 25
                  c.addi16sp  sp, 320
                  sltu        a0, s3, a4
                  c.or        s0, a5
                  and         sp, t1, a4
                  sub         gp, s5, s3
                  auipc       zero, 193976
                  div         s8, zero, s4
5727:             c.lui       t0, 22
                  slt         a3, s8, a7
                  beq         t4, t1, 5736f
                  c.andi      a1, -1
                  sll         s9, gp, s6
                  beq         s7, t6, 5738f
                  bgeu        a3, gp, 5741f
                  mulhu       s8, a1, a6
                  srai        sp, t4, 15
5736:             add         s5, a3, t6
                  c.li        t0, 25
5738:             c.and       a0, a0
                  addi        a2, a7, 1140
                  srai        a7, a7, 9
5741:             c.add       sp, s6
                  c.lui       a1, 27
                  sll         a7, a4, a6
                  mulhu       t1, s7, a0
                  c.addi16sp  sp, 32
                  c.srai      a0, 17
                  c.beqz      a3, 5752f
                  slli        tp, a0, 18
                  c.srli      a2, 31
                  bge         a3, tp, 5756f
                  slt         s7, s6, s5
5752:             c.srai      a0, 25
                  c.addi4spn  a3, sp, 496
                  xor         s6, s9, s9
                  c.mv        a3, a0
5756:             rem         a6, s7, s11
                  mulhsu      s4, a4, s3
                  sll         sp, a1, t4
                  c.and       a0, a2
                  lui         zero, 858761
                  c.addi4spn  a3, sp, 800
                  nop
                  c.sub       a1, a0
                  bne         a3, s2, 5769f
                  sub         s10, a6, a1
                  or          t3, s8, gp
                  slti        zero, t5, 1539
                  auipc       sp, 322678
5769:             mulh        t1, s3, t6
                  bltu        tp, s1, 5772f
                  ori         s5, s9, 1133
5772:             xori        zero, s10, -878
                  srl         s6, gp, s11
                  c.slli      s8, 13
                  addi        s8, s10, 388
                  xor         a1, s10, s3
                  bge         s6, t3, 5785f
                  or          t0, t3, s9
                  srl         s6, s0, t0
                  div         a7, t5, a4
                  andi        a0, sp, 1623
                  mulhu       t0, s5, s10
                  sltiu       s7, s7, -2006
                  c.or        a1, a4
5785:             c.sub       a2, a3
                  slti        zero, s3, 847
                  rem         a5, sp, s3
                  lui         t2, 546730
                  xor         a1, s4, gp
                  andi        s2, s6, 483
                  divu        s6, sp, a5
                  add         s2, s2, s6
                  mulhsu      t2, s0, s2
                  srai        a7, a2, 29
                  bltu        s6, a1, 5801f
                  auipc       t4, 591629
                  c.andi      a2, 22
                  xor         s8, a4, s6
                  sra         a3, tp, t6
                  c.mv        t0, t1
5801:             srli        s6, t2, 31
                  c.addi4spn  a0, sp, 272
                  c.beqz      a1, 5819f
                  c.beqz      a0, 5823f
                  div         zero, a4, s8
                  bne         sp, t5, 5819f
                  sub         gp, a7, zero
                  c.addi      gp, 28
                  mulhu       zero, s10, s1
                  c.srai      s0, 1
                  bge         t4, a6, 5822f
                  lui         t5, 802386
                  sll         s8, t3, s0
                  c.add       t3, t3
                  bgeu        s10, t0, 5817f
                  srai        t0, t5, 21
5817:             c.andi      a2, 28
                  beq         s10, a3, 5819f
5819:             c.andi      a0, 12
                  slti        t3, s10, -1991
                  c.nop
5822:             and         t3, s11, t5
5823:             c.beqz      a0, 5827f
                  bne         s9, s6, 5832f
                  sra         a6, t5, a4
                  c.or        s0, a3
5827:             sltiu       a2, s11, -300
                  or          zero, s4, t5
                  or          s2, t3, t0
                  slt         s2, a4, a6
                  mulhsu      s6, gp, tp
5832:             c.mv        t5, a4
                  srai        zero, a3, 25
                  srai        a5, a7, 6
                  c.li        ra, -1
                  slti        ra, a2, 50
                  slti        s10, s6, -1395
                  divu        s2, s10, ra
                  auipc       s10, 912175
                  mulhsu      sp, a0, t3
                  c.slli      t1, 3
                  c.addi      t4, -1
                  ori         a7, t3, -1344
                  sltiu       s4, t6, -1505
                  div         s3, s1, s3
                  mulhu       sp, s3, s0
                  div         t0, s4, a3
                  c.li        s11, -1
                  c.nop
                  c.xor       s0, s0
                  slti        s8, a5, -1129
                  c.slli      s5, 19
                  c.or        a0, a4
                  mulhu       a7, a3, a2
                  c.addi      ra, -1
                  bge         t3, s3, 5862f
                  srli        a5, s6, 7
                  rem         s2, t0, a2
                  andi        s4, ra, -1699
                  c.lui       t1, 13
                  bltu        s6, s7, 5868f
5862:             bgeu        t3, s6, 5872f
                  sub         a2, s2, t0
                  mulhu       tp, t0, t2
                  lui         s9, 275485
                  or          t0, s9, zero
                  xori        t5, a5, 874
5868:             sub         s2, a1, zero
                  add         a2, s5, s1
                  sll         a3, s11, a6
                  mulhu       zero, a0, zero
5872:             slt         s5, s9, t1
                  bne         s3, a6, 5881f
                  srl         a0, gp, a0
                  c.beqz      a2, 5891f
                  c.addi      a3, 7
                  slt         s6, t2, s9
                  sll         a0, tp, s7
                  slt         t0, a0, t0
                  sltiu       tp, t6, 1370
5881:             mul         t0, t3, s11
                  srai        t1, a7, 26
                  sra         s0, s9, sp
                  bge         s5, t6, 5886f
                  srl         a0, s10, a6
5886:             rem         ra, zero, s1
                  beq         s9, s11, 5897f
                  c.andi      s0, 25
                  beq         a4, s7, 5896f
                  div         t4, ra, a4
5891:             sll         s3, s2, s4
                  add         s9, s3, t5
                  nop
                  sltu        t2, s8, a0
                  rem         a3, ra, s5
5896:             bne         s6, a4, 5908f
5897:             or          sp, t6, a3
                  c.bnez      a3, 5900f
                  xori        t1, a5, -1302
5900:             sra         t3, t3, gp
                  c.andi      a2, 13
                  bne         s5, t0, 5906f
                  ori         s6, zero, -1365
                  mulhu       s3, s5, s5
                  c.nop
5906:             andi        sp, s8, 1488
                  c.and       a2, a4
5908:             bgeu        ra, s1, 5927f
                  c.bnez      a0, 5920f
                  xor         s7, t5, t6
                  mul         zero, a5, t1
                  srli        s3, a6, 2
                  sll         zero, s8, tp
                  bne         s11, s3, 5926f
                  sltu        s10, a6, a2
                  div         sp, s10, a1
                  mulhsu      a1, s11, a7
                  slt         zero, t1, t6
                  c.sub       a0, a3
5920:             bge         s11, t4, 5933f
                  sltu        s0, t2, s9
                  srl         s6, t6, a5
                  addi        s10, sp, -410
                  mulhsu      a7, s2, s6
                  c.mv        a1, a6
5926:             c.addi16sp  sp, -16
5927:             rem         a3, a1, a3
                  c.addi      s10, 13
                  nop
                  c.li        t3, -1
                  bne         s3, t4, 5932f
5932:             div         a3, t3, s6
5933:             c.andi      s0, -1
                  divu        a2, a3, s2
                  c.beqz      a2, 5937f
                  c.addi4spn  a3, sp, 16
5937:             c.add       t4, s0
                  bgeu        a1, a0, 5944f
                  beq         t4, gp, 5944f
                  sll         zero, a4, sp
                  c.sub       a3, a3
                  mulhsu      zero, a5, s10
                  mulhu       s9, s1, s5
5944:             lui         a1, 991606
                  c.srai      a1, 10
                  bgeu        t5, s6, 5947f
5947:             c.andi      a0, 25
                  sra         s10, a4, s6
                  add         t5, a5, t5
                  c.li        a2, -1
                  mul         t4, a2, a3
                  blt         t2, tp, 5958f
                  bge         s1, a1, 5963f
                  c.and       a0, a3
                  rem         sp, s0, s5
                  c.xor       a0, a2
                  c.or        a2, a3
5958:             c.or        a2, a2
                  bltu        s8, t4, 5961f
                  andi        s2, s6, -1174
5961:             ori         gp, s9, -1373
                  or          s3, t5, s7
5963:             and         t4, a7, sp
                  mulh        a1, s0, s10
                  nop
                  c.bnez      a1, 5973f
                  and         s4, sp, gp
                  c.srai      a0, 28
                  c.mv        t2, a4
                  and         zero, t3, a1
                  sltu        t0, s7, a0
                  xori        zero, s7, 812
5973:             slti        s9, t6, 28
                  or          t2, a0, tp
                  add         s2, a6, s3
                  bne         t5, s6, 5984f
                  auipc       s11, 1023788
                  auipc       s9, 656171
                  nop
                  slli        a7, t6, 21
                  mulhu       s11, a2, s4
                  xor         t0, s1, sp
                  c.nop
5984:             c.li        s6, 30
                  and         t4, a1, a2
                  c.li        s0, -1
                  xori        zero, t1, 1431
                  auipc       ra, 793406
                  srl         a6, zero, sp
                  mul         s10, s6, t2
                  mulhsu      s4, sp, s2
                  c.addi16sp  sp, 384
                  xori        zero, s5, -179
                  c.bnez      a3, 6000f
                  mulhu       t5, a1, a0
                  xor         ra, s9, t1
                  nop
                  nop
                  slli        t2, t4, 20
6000:             sub         t5, a1, a6
                  c.bnez      a3, 6013f
                  c.srai      a3, 21
                  lui         s0, 729937
                  c.andi      a3, -1
                  ori         s7, s7, 2027
                  sltiu       s9, t2, 777
                  xor         zero, s6, ra
                  srli        s8, s0, 9
                  mulhsu      s10, t4, s3
                  slt         s0, a3, s2
                  mulhsu      s8, s10, a0
                  c.addi16sp  sp, 320
6013:             xori        a2, sp, 318
                  slti        zero, s4, 1241
                  nop
                  c.slli      gp, 29
                  c.slli      s3, 29
                  blt         s11, t1, 6022f
                  rem         zero, s9, s4
                  and         s6, s11, s2
                  sub         a1, t3, s1
6022:             c.addi4spn  a3, sp, 48
                  auipc       gp, 754219
                  beq         a5, s3, 6029f
                  bne         tp, sp, 6031f
                  c.addi      a7, -1
                  ori         s8, s4, 329
                  bltu        t1, a5, 6029f
6029:             sub         s3, t1, tp
                  sub         s4, s5, s7
6031:             c.nop
                  c.and       a3, a3
                  slti        zero, s3, -1582
                  c.addi16sp  sp, 288
                  lui         t2, 357711
                  mulhu       t0, a6, a1
                  slti        a0, ra, 1499
                  sub         s9, t1, a0
                  divu        t5, t4, s11
                  c.andi      a2, 2
                  srl         t0, a7, a3
                  xor         s4, s10, t4
                  addi        a6, t5, -1693
                  ori         s5, a2, -645
                  sltu        a3, t4, s8
                  c.addi      t0, 21
                  c.beqz      a1, 6060f
                  mulhu       t0, t5, s10
                  addi        t4, t2, 853
                  c.srli      a0, 1
                  auipc       a0, 917404
                  c.li        s2, -1
                  add         zero, s10, gp
                  sub         t3, a2, s1
                  mulh        s11, t0, s10
                  c.addi16sp  sp, -16
                  addi        a2, a2, -264
                  c.addi      s5, 19
                  nop
6060:             c.beqz      a3, 6070f
                  c.bnez      a0, 6063f
                  srli        zero, t1, 1
6063:             c.srai      a5, 7
                  srl         zero, s9, s5
                  bgeu        a6, t3, 6076f
                  xor         gp, s10, s11
                  c.addi16sp  sp, -16
                  c.srai      s0, 25
                  c.slli      s8, 22
6070:             c.addi16sp  sp, 80
                  bgeu        t5, sp, 6090f
                  and         a6, sp, s6
                  andi        sp, s6, -2021
                  mulhsu      s3, t0, a4
                  divu        zero, tp, a4
6076:             div         t0, zero, t5
                  beq         a3, t1, 6083f
                  sll         t2, a3, tp
                  bltu        s2, a4, 6089f
                  xori        a0, s6, 1981
                  add         t2, s3, a3
                  c.andi      s0, 3
6083:             c.addi      tp, -1
                  sra         t5, a4, t3
                  sub         s3, s11, s5
                  lui         a2, 625576
                  srai        tp, a7, 30
                  c.lui       ra, 8
6089:             c.add       t1, s9
6090:             bltu        zero, s6, 6106f
                  c.addi4spn  a3, sp, 112
                  xori        a0, zero, 1789
                  c.srli      a2, 24
                  srai        s4, a0, 25
                  mulh        tp, s4, s10
                  srl         t1, a0, gp
                  divu        a6, t6, t6
                  bltu        a6, t0, 6102f
                  auipc       s4, 443343
                  sltiu       a6, s10, -1350
                  c.bnez      a1, 6109f
6102:             and         a0, a2, t1
                  bne         s3, s8, 6108f
                  srl         t4, s3, t5
                  bge         s0, s5, 6111f
6106:             andi        a1, a6, 306
                  c.add       t3, ra
6108:             and         s11, a7, s3
6109:             div         zero, t4, s7
                  c.or        a2, a0
6111:             nop
                  c.bnez      a3, 6114f
                  xor         sp, a7, ra
6114:             bgeu        s9, a4, 6126f
                  sll         zero, s11, a1
                  sll         t0, a6, ra
                  srli        t0, zero, 20
                  c.and       a2, a2
                  c.addi16sp  sp, 432
                  lui         a5, 726424
                  c.mv        s11, a1
                  slli        t0, a4, 4
                  or          a7, zero, t0
                  sub         sp, s11, s8
                  mulh        t0, s2, a3
6126:             xori        zero, s0, 596
                  c.beqz      a2, 6135f
                  c.srli      s0, 18
                  slti        s11, s4, -1639
                  c.srai      a3, 1
                  c.andi      a3, -1
                  c.xor       a0, s0
                  xori        t3, zero, -761
                  srl         s6, t5, zero
6135:             c.beqz      a0, 6137f
                  beq         s10, s5, 6141f
6137:             xor         s6, t3, sp
                  sltu        a7, s1, a0
                  mulhu       a7, t0, s5
                  or          t5, a1, a7
6141:             c.slli      s2, 4
                  bltu        s8, a2, 6154f
                  andi        s2, t0, 1122
                  rem         t2, a0, a2
                  c.addi4spn  s0, sp, 176
                  c.mv        ra, t5
                  c.sub       a3, a1
                  sub         zero, gp, ra
                  mulh        s0, a7, a2
                  c.add       s11, s8
                  and         s10, t2, s10
                  sra         zero, a5, a1
                  mul         zero, t3, gp
6154:             c.addi      s3, -1
                  addi        zero, t6, 1146
                  srai        a1, a2, 16
                  c.mv        a0, s2
                  srli        s6, t1, 13
                  andi        zero, s2, 241
                  c.bnez      a0, 6170f
                  c.mv        a3, s0
                  srl         zero, s9, a7
                  xori        t0, t2, -1829
                  c.nop
                  or          s10, s9, t5
                  c.mv        s0, s3
                  slli        s6, s3, 0
                  auipc       t1, 814781
                  c.add       tp, a5
6170:             c.sub       a1, a3
                  slt         a0, t4, t1
                  bne         s8, s6, 6179f
                  sltiu       zero, s7, 1192
                  beq         t3, sp, 6181f
                  beq         a0, s11, 6176f
6176:             nop
                  c.lui       a3, 13
                  slt         t1, t1, t3
6179:             bltu        a7, gp, 6186f
                  srl         s9, gp, s11
6181:             andi        zero, a1, -521
                  sub         zero, t5, t6
                  srai        a6, a6, 30
                  c.addi16sp  sp, -16
                  srli        a1, s1, 5
6186:             andi        a0, s5, 829
                  c.xor       a0, a3
                  c.srai      s0, 13
                  auipc       a3, 892799
                  slt         s9, t6, a1
                  c.addi16sp  sp, 128
                  add         s2, a3, s8
                  lui         a0, 28887
                  c.li        a7, -1
                  mulhu       t4, a5, a2
                  lui         t5, 528517
                  srai        s4, t6, 1
                  slti        sp, s0, -1817
                  sra         t1, a3, s5
                  lui         s4, 310649
                  c.addi4spn  s0, sp, 640
                  bne         s0, zero, 6208f
                  c.mv        s5, ra
                  mul         zero, s1, s11
                  c.slli      ra, 6
                  divu        t3, sp, a0
                  addi        t2, a6, 911
6208:             c.or        a3, a0
                  xor         a1, a7, t6
                  sra         t5, s3, sp
                  mul         a2, t4, a6
                  addi        s6, s10, 453
                  c.add       t5, s11
                  c.srli      a1, 25
                  c.sub       a0, a0
                  xor         s8, ra, zero
                  mulhu       t2, a1, s0
                  c.add       tp, ra
                  lui         a5, 553250
                  mul         ra, a0, ra
                  srl         s9, s5, tp
                  beq         s10, a5, 6234f
                  sll         a7, t1, a5
                  c.beqz      a2, 6228f
                  lui         tp, 392592
                  c.nop
                  srl         t1, a0, s3
6228:             xori        s8, s3, 487
                  c.addi16sp  sp, 304
                  nop
                  sub         zero, tp, sp
                  c.slli      s8, 22
                  sll         s5, t2, a0
6234:             c.mv        t5, s7
                  sra         s10, s6, s7
                  bne         ra, sp, 6244f
                  srai        a7, a6, 7
                  bgeu        a6, s7, 6240f
                  mulh        s10, s6, a4
6240:             slli        zero, t5, 14
                  xor         s2, s3, s7
                  c.bnez      a1, 6248f
                  bge         a7, t5, 6255f
6244:             xori        a6, a3, 1659
                  mul         s7, t5, s10
                  bgeu        a1, s2, 6251f
                  mulhsu      a0, s2, ra
6248:             xor         t4, t4, s3
                  sub         s7, t0, a2
                  c.andi      a1, -1
6251:             c.sub       a3, a3
                  c.add       s4, a1
                  c.sub       a3, a1
                  ori         gp, s4, -2025
6255:             c.slli      sp, 5
                  rem         t2, s3, s0
                  slti        s4, sp, 1592
                  or          s2, a5, t1
                  bne         a2, s10, 6270f
                  bne         s9, a5, 6276f
                  xor         s2, t4, s9
                  bgeu        s2, s10, 6270f
                  c.add       s3, t2
                  slti        t5, t4, -1401
                  mulhsu      s9, a4, s7
                  c.srli      a3, 23
                  xori        a6, s2, -1338
                  c.add       s11, a1
                  c.mv        gp, s5
6270:             auipc       s11, 277214
                  c.li        ra, -1
                  c.mv        s4, a4
                  mulh        s0, t4, s7
                  and         t3, a4, t0
                  nop
6276:             c.andi      a2, -1
                  bne         a4, s9, 6285f
                  sra         s9, t6, t3
                  bgeu        a0, s11, 6281f
                  c.sub       a0, a1
6281:             andi        ra, a5, 1272
                  bne         t2, s1, 6292f
                  c.or        a3, a3
                  auipc       zero, 693274
6285:             mulh        a1, t1, t2
                  c.addi4spn  a3, sp, 464
                  c.slli      tp, 14
                  sltiu       t3, s10, 1841
                  mul         sp, ra, a5
                  c.addi4spn  a3, sp, 704
                  c.bnez      a0, 6301f
6292:             bge         s10, s1, 6305f
                  xor         a7, s10, zero
                  slti        zero, t2, -110
                  xori        ra, a6, -1423
                  bge         t5, s6, 6301f
                  divu        gp, a3, a1
                  andi        t1, s6, 1219
                  addi        zero, a3, -395
                  sltu        zero, s1, a6
6301:             sltu        a2, t5, s2
                  c.lui       t1, 6
                  c.xor       a2, a2
                  c.andi      a2, 5
6305:             bgeu        s1, a6, 6307f
                  bne         a4, s0, 6325f
6307:             c.li        a5, -1
                  srai        t1, t0, 16
                  add         s4, gp, t1
                  c.addi16sp  sp, 432
                  bne         s5, a5, 6312f
6312:             add         t0, s3, a5
                  c.beqz      a1, 6325f
                  xori        t2, s0, -1434
                  xori        a5, a1, -1277
                  auipc       s7, 471374
                  mulhsu      t4, s11, s2
                  auipc       sp, 821369
                  slli        t1, a4, 30
                  srli        a1, a6, 7
                  and         s8, a7, tp
                  bgeu        s10, sp, 6329f
                  xori        s6, a4, -1644
                  sltu        s2, tp, t2
6325:             addi        s5, s0, -496
                  lui         s9, 366501
                  mul         t4, s7, t5
                  andi        t3, a4, 693
6329:             or          s3, a0, tp
                  addi        s3, t6, 1358
                  c.addi4spn  a0, sp, 752
                  c.addi4spn  a0, sp, 832
                  c.addi4spn  a3, sp, 784
                  beq         s4, s2, 6344f
                  nop
                  bltu        gp, t2, 6338f
                  and         zero, a4, s7
6338:             andi        t2, a6, -831
                  c.andi      a3, 5
                  c.or        a0, s1
                  auipc       s0, 549501
                  slt         a0, s1, t2
                  ori         s3, t0, -1734
6344:             auipc       s6, 828372
                  srli        t3, s5, 3
                  bltu        a3, s11, 6350f
                  rem         a2, t4, t5
                  lui         a5, 61258
                  mulhu       zero, s4, s2
6350:             or          s8, s11, gp
                  slti        zero, t3, -955
                  c.bnez      a0, 6353f
6353:             sltiu       s9, t4, -1617
                  c.beqz      a3, 6356f
                  c.srai      a1, 17
6356:             sltu        s5, t3, s9
                  xor         a1, s3, s2
                  mulh        sp, t4, gp
                  c.andi      a3, -1
                  or          t5, s5, s5
                  bltu        s8, a3, 6365f
                  sltiu       s3, t4, 2002
                  nop
                  blt         t3, s7, 6370f
6365:             mulhsu      gp, a3, s1
                  bne         ra, a0, 6378f
                  sltiu       ra, s2, -1216
                  slt         tp, a2, a0
                  ori         s5, a3, 16
6370:             c.li        ra, -1
                  auipc       s5, 566199
                  bgeu        tp, s9, 6379f
                  blt         t6, t3, 6379f
                  bgeu        s8, sp, 6382f
                  andi        gp, s5, -782
                  mulhsu      s2, a3, a2
                  c.addi4spn  a3, sp, 32
6378:             c.and       a0, a0
6379:             addi        s0, sp, 1475
                  c.nop
                  c.xor       a1, s1
6382:             c.li        ra, 13
                  slt         s10, t6, s7
                  or          s10, s6, t4
                  divu        a0, s0, s8
                  c.or        a0, a0
                  bltu        t6, t1, 6394f
                  mulhsu      s5, s4, zero
                  srl         a6, s8, s6
                  c.beqz      a0, 6396f
                  slti        s6, zero, 1187
                  c.nop
                  and         a3, s7, t0
6394:             bge         s9, s2, 6402f
                  blt         s10, a3, 6402f
6396:             xori        s8, a2, 596
                  c.and       a0, a2
                  c.xor       a3, s0
                  c.xor       a3, a3
                  bgeu        a5, zero, 6410f
                  c.li        gp, -1
6402:             c.lui       s4, 26
                  sll         t4, s4, s2
                  ori         s0, s11, -1257
                  srai        s3, s10, 13
                  ori         ra, t4, -761
                  rem         s10, t2, a2
                  srl         zero, a6, t3
                  sll         s5, s9, s7
6410:             srai        s3, a4, 23
                  mulhu       s8, t6, s9
                  sll         s5, a3, t4
                  srl         s10, s11, s2
                  sltu        s7, gp, s9
                  c.bnez      a3, 6416f
6416:             c.add       s5, t0
                  mulhsu      zero, t4, tp
                  blt         a7, t4, 6423f
                  sltu        s5, tp, t1
                  mulhsu      s0, s9, s3
                  c.addi16sp  sp, -16
                  mul         s3, sp, t3
6423:             c.li        t2, 13
                  c.mv        s0, t1
                  sll         t4, s9, a2
                  or          a7, s7, sp
                  beq         s9, s3, 6438f
                  and         s8, t0, gp
                  c.srli      s0, 31
                  ori         s10, s4, -551
                  and         s5, a6, s11
                  bge         s8, s0, 6434f
                  sltiu       s9, t1, -892
6434:             c.slli      s3, 26
                  blt         s3, s8, 6454f
                  srai        a7, ra, 5
                  nop
6438:             c.xor       a2, a0
                  c.andi      s0, -1
                  srai        gp, s4, 24
                  nop
                  andi        zero, t0, 868
                  or          a6, t3, a7
                  c.nop
                  lui         zero, 222749
                  c.lui       ra, 25
                  c.lui       t5, 9
                  mulhu       t0, a7, s3
                  c.slli      t0, 5
                  c.li        s4, 10
                  c.xor       s0, a0
                  bge         ra, s0, 6459f
                  c.lui       a1, 27
6454:             lui         zero, 1017275
                  mulhu       gp, t5, t3
                  bltu        a0, ra, 6462f
                  srai        gp, sp, 0
                  or          a0, s4, a1
6459:             beq         a1, t5, 6471f
                  bgeu        s5, ra, 6462f
                  c.andi      s0, -1
6462:             blt         s6, t2, 6464f
                  c.li        s4, 24
6464:             c.addi16sp  sp, -16
                  c.sub       a0, a0
                  mulhsu      t3, s3, s3
                  addi        a1, s8, -740
                  slt         sp, s5, t6
                  c.lui       s10, 11
                  andi        s8, a1, 405
6471:             slli        a1, a0, 12
                  mulh        t4, a6, t5
                  c.sub       a0, a0
                  bge         s10, a1, 6481f
                  or          t2, s2, s1
                  and         s9, s8, s3
                  srai        a2, a4, 30
                  c.lui       s4, 10
                  or          t1, tp, s8
                  c.mv        t5, a5
6481:             sll         sp, t6, t6
                  c.li        s4, 6
                  sltu        s3, t0, a4
                  rem         t5, s0, a4
                  xor         a7, s2, a3
                  beq         t5, s9, 6494f
                  bne         s8, a3, 6491f
                  c.li        s5, -1
                  c.add       ra, s5
                  rem         a0, s4, tp
6491:             bltu        gp, zero, 6496f
                  beq         a2, a3, 6496f
                  srai        tp, t2, 1
6494:             srai        zero, s10, 30
                  beq         t1, t0, 6511f
6496:             blt         a3, t4, 6498f
                  c.bnez      a1, 6509f
6498:             sra         t3, a1, s7
                  mulhsu      a7, a6, a4
                  bge         t5, s9, 6510f
                  c.xor       a0, a3
                  c.mv        a0, t4
                  sra         tp, s0, s5
                  mulhsu      t5, t1, t1
                  rem         a7, s7, a7
                  sll         s11, s3, zero
                  c.or        a2, a0
                  c.srli      a2, 26
6509:             sll         s3, a0, a7
6510:             srli        s11, s6, 17
6511:             c.lui       t3, 4
                  slli        t1, t2, 16
                  c.li        gp, 12
                  lui         s6, 308836
                  auipc       s6, 845247
                  and         t0, a7, ra
                  rem         t4, s8, t2
                  c.xor       a0, a2
                  mul         s10, a7, s0
                  c.andi      s0, -1
                  divu        gp, t3, t5
                  rem         a5, ra, a3
                  addi        a1, s6, -1074
                  sll         a0, t4, t1
                  xori        s11, t1, 517
                  mulhu       zero, a2, s6
                  addi        ra, s11, 1523
                  c.or        a3, a1
                  lui         s11, 38792
                  blt         gp, sp, 6540f
                  slt         a6, s9, ra
                  sra         sp, s11, s2
                  blt         zero, s3, 6545f
                  divu        zero, a5, ra
                  c.srai      a3, 12
                  c.or        a3, a0
                  c.slli      sp, 20
                  sub         a3, s6, a5
                  or          s4, a4, s8
6540:             bge         t2, s3, 6546f
                  andi        a1, zero, -1731
                  sub         s11, sp, s7
                  xor         s9, gp, a4
                  slli        zero, t3, 9
6545:             c.lui       tp, 4
6546:             c.or        a0, a3
                  sub         s9, a2, a4
                  and         a0, t4, tp
                  xori        s10, a4, -1048
                  blt         gp, s11, 6551f
6551:             c.srai      a0, 8
                  add         a5, s3, t0
                  mulhu       s5, s8, s5
                  bge         s1, s2, 6560f
                  blt         sp, s6, 6568f
                  sll         t1, t6, t0
                  c.addi      ra, 22
                  srai        s5, t5, 16
                  srai        sp, t5, 27
6560:             sltu        gp, t6, t1
                  mulh        s6, t0, s5
                  sll         s2, sp, a7
                  auipc       a6, 499539
                  c.and       a2, a0
                  c.sub       a3, a1
                  c.srli      a1, 13
                  mulhu       a1, s3, a2
6568:             c.and       a3, s1
                  div         a6, a3, s11
                  sltu        t4, s6, s11
                  xori        s5, a1, -1288
                  nop
                  c.sub       a3, a2
                  c.mv        a5, s10
                  c.xor       a3, a3
                  nop
                  c.srli      a3, 30
                  c.addi      t5, -1
                  c.andi      a1, -1
                  xori        s10, gp, 1014
                  bgeu        s2, s6, 6589f
                  mul         a5, s1, s7
                  srl         zero, t1, a1
                  mulhsu      zero, a6, s11
                  c.srai      a3, 28
                  blt         t2, s6, 6592f
                  c.bnez      s0, 6589f
                  auipc       s0, 344398
6589:             c.addi16sp  sp, 64
                  sltu        a2, s4, a3
                  c.srli      s0, 3
6592:             c.lui       ra, 15
                  c.xor       a1, s1
                  sltu        s8, s5, sp
                  lui         t5, 248767
                  mul         s3, s6, s9
                  addi        a0, s5, 430
                  mulhsu      s5, a2, sp
                  sll         s9, a3, zero
                  sltiu       a3, s7, -1870
                  c.and       a2, a2
                  c.li        t0, -1
                  xori        s0, t1, -808
                  rem         s5, s8, sp
                  bgeu        zero, s7, 6611f
                  nop
                  c.addi      s3, -1
                  div         a3, a3, s8
                  lui         tp, 62787
                  rem         s7, s7, a5
6611:             ori         s4, gp, -1440
                  c.or        a0, a1
                  xori        t4, t1, -417
                  xori        a1, a2, 126
                  divu        zero, s8, a7
                  mulh        t4, t3, a4
                  mul         s7, s7, a1
                  nop
                  c.bnez      a1, 6625f
                  sll         s10, a2, sp
                  rem         a3, s7, s5
                  c.and       a0, s1
                  rem         a6, t1, a5
                  mulhsu      a5, a3, t1
6625:             c.addi      ra, -1
                  c.and       a1, a4
                  bne         a2, s4, 6634f
                  divu        a0, s4, a5
                  bge         a4, s11, 6637f
                  xori        t2, a2, -1618
                  c.srli      a0, 9
                  c.lui       s9, 19
                  c.addi      t3, -1
6634:             slli        tp, s8, 16
                  lui         a3, 1012494
                  c.xor       s0, a2
6637:             auipc       a0, 396619
                  blt         zero, a3, 6650f
                  c.beqz      a0, 6649f
                  c.and       a0, a1
                  bgeu        tp, s6, 6646f
                  sltiu       s0, gp, 538
                  blt         s5, s7, 6662f
                  c.addi4spn  s0, sp, 656
                  bltu        s4, s1, 6657f
6646:             c.andi      a0, -1
                  c.addi      s7, 5
                  c.xor       a2, a3
6649:             slt         s0, t3, t6
6650:             mulhu       a0, sp, s4
                  sll         s4, t5, s7
                  add         s5, a4, tp
                  srli        t4, s1, 31
                  c.xor       a0, s0
                  c.lui       gp, 1
                  c.addi      t1, 6
6657:             beq         t3, s0, 6661f
                  divu        t0, a1, s6
                  mulhu       a7, s9, a4
                  rem         s7, t2, a3
6661:             mulh        a6, t6, sp
6662:             sll         a6, sp, s6
                  ori         t3, t3, -1155
                  c.bnez      a5, 6672f
                  bge         s2, gp, 6666f
6666:             c.nop
                  c.srai      a3, 3
                  c.bnez      a0, 6675f
                  sll         s11, s7, a3
                  c.srli      a5, 5
                  bne         s9, a2, 6672f
6672:             c.lui       ra, 14
                  c.beqz      a5, 6683f
                  c.li        t5, -1
6675:             addi        sp, t3, -1492
                  slt         s8, s8, a4
                  srai        s10, a0, 19
                  divu        a7, s3, a3
                  mulh        s10, s3, t4
                  sra         s9, ra, s6
                  xor         t1, s11, ra
                  slt         a5, s1, a2
6683:             and         a2, s10, a5
                  bge         a4, s10, 6690f
                  c.addi      s3, 6
                  add         a5, s2, a7
                  or          gp, t6, t1
                  c.sub       a3, a1
                  blt         a2, t2, 6691f
6690:             rem         sp, s9, t2
6691:             bne         s5, s3, 6693f
                  c.slli      sp, 26
6693:             c.nop
                  sltiu       gp, s0, -1717
                  xor         t0, s7, t1
                  srl         ra, s3, a7
                  srl         t0, s4, t4
                  bltu        s9, a4, 6710f
                  c.addi      sp, -1
                  mul         ra, t6, tp
                  mulhu       a5, s11, a7
                  and         s7, t0, s5
                  mulhsu      a0, s4, s2
                  c.beqz      a0, 6717f
                  srai        a6, s11, 10
                  rem         t4, t5, t1
                  beq         zero, ra, 6714f
                  c.srli      s0, 12
                  sra         zero, s11, gp
6710:             ori         s3, t0, 1398
                  divu        gp, t2, t1
                  mulh        s2, a3, t6
                  bltu        s7, a6, 6715f
6714:             c.and       a2, a4
6715:             addi        a1, tp, -1231
                  c.lui       a0, 22
6717:             slt         t2, t1, tp
                  c.and       a1, a2
                  and         zero, t4, a2
                  sub         s0, s10, sp
                  slli        t5, ra, 1
                  bge         t2, s1, 6728f
                  xor         ra, s7, s9
                  srli        s7, s4, 26
                  srl         t1, s3, s5
                  nop
                  beq         s7, t4, 6738f
6728:             c.addi16sp  sp, 112
                  c.xor       a0, a3
                  c.li        t1, 17
                  srai        a6, t1, 23
                  blt         t5, tp, 6736f
                  c.slli      a5, 3
                  c.mv        ra, s0
                  sltiu       t2, s6, -151
6736:             auipc       t1, 811343
                  c.and       a1, a0
6738:             mul         t1, t4, a5
                  c.mv        t1, s7
                  c.bnez      a3, 6745f
                  andi        s6, s2, -573
                  sra         s0, t3, t4
                  sltiu       s3, a2, 1386
                  ori         t2, a1, 954
6745:             sll         a1, s10, s10
                  div         t2, s7, a6
                  c.srai      a3, 11
                  and         ra, tp, s3
                  div         a7, s0, s0
                  auipc       s9, 500404
                  slli        a0, s7, 18
                  c.xor       a3, a2
                  bne         a5, s0, 6763f
                  divu        s5, gp, gp
                  c.xor       a0, a2
                  c.srai      a3, 23
                  c.mv        s5, s2
                  blt         s4, t5, 6774f
                  sltiu       gp, s8, 495
                  c.addi4spn  a0, sp, 912
                  c.xor       a0, s1
                  div         s0, s1, s4
6763:             srai        s8, gp, 7
                  c.sub       a1, a1
                  nop
                  and         a3, ra, s0
                  slti        t4, sp, -1302
                  mulhu       s2, s6, t0
                  c.nop
                  divu        s8, a4, s3
                  c.srai      a2, 30
                  c.mv        a7, a2
                  sll         s5, s8, a0
6774:             nop
                  xor         s2, s9, a2
                  c.lui       a5, 31
                  auipc       zero, 922579
                  srli        t4, a3, 10
                  c.xor       a3, a2
                  c.srli      a1, 16
                  div         s11, a2, tp
                  sltiu       s3, a6, -926
                  c.li        s9, 12
                  lui         sp, 563177
                  c.beqz      a3, 6793f
                  c.andi      s0, -1
                  bge         a0, tp, 6789f
                  sra         s10, s8, t3
6789:             c.addi      a2, 2
                  ori         s5, s1, 457
                  c.andi      a1, 30
                  c.andi      a0, -1
6793:             bne         s7, a6, 6801f
                  c.li        a3, 31
                  nop
                  blt         s4, a5, 6803f
                  c.andi      a2, -1
                  c.beqz      a3, 6804f
                  add         a6, s8, zero
                  srl         a3, tp, s5
6801:             mul         s9, sp, gp
                  bne         sp, t1, 6808f
6803:             or          s6, tp, t2
6804:             srai        s0, a7, 28
                  add         s7, s11, s0
                  c.addi16sp  sp, -16
                  ori         a5, a6, 1080
6808:             xori        t4, a1, -1130
                  andi        a5, zero, 1280
                  c.lui       t1, 14
                  c.slli      a0, 31
                  srl         ra, zero, a1
                  mulhsu      a7, a2, a7
                  mulh        s0, s8, tp
                  mul         s0, t4, s9
                  div         s6, s10, a3
                  c.srai      a1, 7
                  bge         gp, a7, 6830f
                  c.addi      tp, 9
                  c.xor       a0, a2
                  c.or        a2, a4
                  and         s6, t0, s0
                  c.addi      t4, -1
                  bne         a1, s5, 6828f
                  bne         s5, t3, 6835f
                  xor         t4, t0, s0
                  c.addi4spn  s0, sp, 32
6828:             andi        zero, s9, -448
                  lui         t2, 284737
6830:             c.addi16sp  sp, 32
                  rem         s7, t6, s2
                  bgeu        s1, a0, 6840f
                  blt         s7, zero, 6835f
                  c.beqz      a1, 6839f
6835:             bgeu        s10, a0, 6848f
                  blt         s1, s9, 6847f
                  c.addi16sp  sp, -16
                  or          t0, s11, t1
6839:             div         s11, s7, sp
6840:             mulhsu      tp, t1, sp
                  srli        t1, s4, 12
                  c.li        a6, -1
                  nop
                  div         t2, t4, s1
                  div         s5, a7, sp
                  add         a5, s9, gp
6847:             mulh        t1, t0, a7
6848:             c.lui       a6, 2
                  c.addi4spn  a0, sp, 704
                  srai        s10, gp, 24
                  c.sub       a0, a0
                  bltu        a1, t6, 6871f
                  bgeu        a1, a4, 6855f
                  rem         t2, zero, t5
6855:             c.sub       a0, a3
                  c.addi16sp  sp, 400
                  nop
                  add         a6, a3, t6
                  mul         a2, a4, t2
                  blt         s1, zero, 6866f
                  add         zero, zero, s10
                  c.srli      a0, 24
                  ori         s9, a2, 242
                  bltu        t5, a1, 6880f
                  mulhu       zero, t6, s5
6866:             srai        s10, s11, 30
                  srli        ra, gp, 13
                  beq         a6, s10, 6870f
                  sll         a0, t2, s10
6870:             div         a2, t1, s10
6871:             c.bnez      a3, 6876f
                  andi        ra, t3, -674
                  c.andi      a3, 4
                  blt         s0, a5, 6878f
                  c.beqz      s0, 6885f
6876:             c.srli      a3, 29
                  bne         s6, t5, 6885f
6878:             srli        a5, s4, 3
                  mulh        a0, gp, zero
6880:             c.bnez      a1, 6892f
                  c.nop
                  beq         ra, s10, 6883f
6883:             c.li        ra, -1
                  c.or        s0, s1
6885:             c.andi      a2, -1
                  c.addi16sp  sp, 496
                  addi        s11, gp, -374
                  c.addi16sp  sp, -16
                  c.srli      s0, 18
                  c.srli      a1, 25
                  c.add       t3, s1
6892:             c.bnez      a1, 6898f
                  c.bnez      a0, 6905f
                  c.sub       a1, a4
                  c.srli      a0, 19
                  slt         s7, zero, a5
                  sub         a2, tp, s1
6898:             lui         s10, 180277
                  mulhu       s10, t2, a0
                  xor         s10, ra, gp
                  bltu        s10, t3, 6902f
6902:             c.lui       s6, 25
                  slli        zero, a7, 25
                  auipc       zero, 274366
6905:             bgeu        s9, s6, 6912f
                  c.mv        t0, a6
                  c.slli      t2, 9
                  c.addi4spn  a0, sp, 1008
                  c.xor       a1, a0
                  c.addi16sp  sp, 384
                  c.and       a0, a1
6912:             bltu        a5, s5, 6919f
                  srli        s11, s9, 30
                  c.slli      s6, 23
                  nop
                  c.beqz      a2, 6926f
                  rem         a7, s1, t5
                  sll         gp, a0, ra
6919:             c.addi16sp  sp, -16
                  c.xor       a3, a3
                  c.add       a6, t1
                  slli        a6, a2, 19
                  c.sub       a3, a0
                  sll         a1, s1, s4
                  c.srli      a0, 8
6926:             c.addi16sp  sp, 240
                  mulhsu      t4, zero, a4
                  lui         t3, 786881
                  ori         s11, t5, -1081
                  nop
                  bltu        t0, ra, 6935f
                  c.slli      a0, 7
                  c.or        a3, a3
                  sltu        s5, s0, s4
6935:             c.beqz      a1, 6943f
                  bltu        s2, a1, 6947f
                  srli        gp, a2, 18
                  mulh        t5, s10, t0
                  xori        zero, t6, 832
                  ori         s8, s4, -1537
                  rem         a2, a0, s6
                  sltiu       a5, a5, -90
6943:             sltiu       t0, s2, -1019
                  c.addi16sp  sp, 480
                  c.sub       a1, a2
                  srl         a2, a3, ra
6947:             or          a2, s7, a7
                  bgeu        a4, s8, 6958f
                  bne         a4, s10, 6957f
                  c.li        s4, 7
                  mulhsu      s8, gp, s10
                  c.lui       t1, 22
                  addi        s11, s9, 1085
                  addi        t5, a0, 1907
                  or          t4, a5, a1
                  lui         zero, 730198
6957:             xor         s2, tp, s0
6958:             c.beqz      a1, 6959f
6959:             sltiu       zero, t2, -66
                  add         a7, sp, s4
                  c.srli      a3, 11
                  divu        s4, zero, zero
                  sra         a3, s0, tp
                  bgeu        tp, a5, 6965f
6965:             auipc       s6, 593804
                  divu        s2, ra, s1
                  c.bnez      s0, 6973f
                  srli        t2, s3, 20
                  c.beqz      a2, 6981f
                  nop
                  nop
                  sub         t4, t4, tp
6973:             c.add       a7, s1
                  sll         t1, s4, s11
                  c.and       a3, a1
                  sub         zero, t6, a1
                  slli        a0, s0, 10
                  sra         zero, s4, t5
                  slt         zero, zero, s0
                  andi        t1, t1, 965
6981:             ori         a1, a2, 1473
                  c.and       a0, a1
                  sra         t3, t4, t4
                  slli        t4, s10, 11
                  add         tp, s1, ra
                  rem         a6, t3, t3
                  mulh        t4, s4, tp
                  srai        s5, t4, 22
                  c.mv        t4, a2
                  c.slli      s7, 1
                  xor         t1, tp, s2
                  c.li        ra, -1
                  c.or        a3, a3
                  auipc       a5, 464228
                  c.li        t5, -1
                  srli        s8, t5, 25
                  add         t4, sp, a7
                  blt         gp, s6, 7006f
                  c.slli      a1, 8
                  blt         t4, s0, 7006f
                  c.addi4spn  a2, sp, 304
                  c.srai      a0, 19
                  c.addi      a3, -1
                  add         s3, a4, t6
                  ori         zero, s7, -1151
7006:             sltiu       s11, s2, -1639
                  div         t5, a5, t4
                  xori        a0, s2, -1522
                  add         a5, tp, gp
                  c.bnez      a2, 7015f
                  c.nop
                  divu        a7, s2, t1
                  sltu        s9, s11, s1
                  c.lui       s3, 31
7015:             c.or        a0, a2
                  bge         s5, t6, 7029f
                  srli        s2, tp, 1
                  slli        s10, zero, 16
                  lui         gp, 258495
                  bge         ra, s10, 7026f
                  ori         t2, a3, 1798
                  bgeu        sp, tp, 7028f
                  mulh        t2, a6, s6
                  and         ra, s3, a0
                  beq         tp, sp, 7027f
7026:             bge         ra, s1, 7028f
7027:             c.bnez      a0, 7046f
7028:             sra         a5, s7, t1
7029:             c.sub       a0, a0
                  srli        a7, s11, 6
                  bge         s2, t5, 7038f
                  sra         s6, t3, s1
                  c.add       sp, t3
                  div         a7, t6, zero
                  c.mv        t5, s8
                  c.slli      a7, 31
                  bge         s0, s9, 7044f
7038:             divu        t2, a5, s1
                  auipc       a5, 790007
                  c.mv        s8, t6
                  rem         s10, s8, t6
                  addi        zero, t4, -376
                  rem         s8, t5, a3
7044:             c.srli      a2, 29
                  or          a6, t4, zero
7046:             slt         s2, s3, s0
                  xor         a3, s4, sp
                  lui         zero, 892814
                  c.nop
                  andi        t4, s0, 1438
                  slt         sp, s0, s1
                  bge         t2, a3, 7062f
                  sltiu       s0, t1, -807
                  or          zero, s4, a4
                  sll         zero, a2, s3
                  beq         a1, s4, 7058f
                  sub         t5, t5, s2
7058:             bge         sp, s3, 7065f
                  c.bnez      a5, 7069f
                  xori        gp, t1, 1193
                  c.addi4spn  a2, sp, 448
7062:             or          s10, s1, s0
                  c.addi4spn  a0, sp, 368
                  divu        s5, s3, a2
7065:             slli        t4, a5, 23
                  c.li        ra, 4
                  c.and       a3, a1
                  divu        t0, s11, ra
7069:             c.xor       a3, a3
                  beq         a2, t2, 7082f
                  rem         a2, s2, tp
                  c.addi      s0, -1
                  srl         s11, s1, s6
                  c.slli      s8, 13
                  bne         t5, gp, 7077f
                  c.beqz      a0, 7080f
7077:             c.andi      s0, -1
                  ori         s2, s1, -1491
                  mulhsu      s5, t1, a4
7080:             c.sub       a0, a1
                  divu        s4, a2, s11
7082:             add         a7, t3, zero
                  and         t5, s6, s10
                  c.sub       s0, s0
                  lui         t3, 728134
                  addi        a7, a6, -896
                  srl         s6, a3, t3
                  c.addi      tp, -1
                  div         ra, t2, s4
                  c.srai      a2, 23
                  srai        s3, s5, 6
                  c.addi16sp  sp, -16
                  or          s6, t5, a6
                  andi        zero, tp, 1828
                  divu        s4, sp, s6
                  c.bnez      a1, 7108f
                  srl         a2, s5, a4
                  slt         zero, s6, s1
                  c.lui       s5, 22
                  c.andi      a3, 0
                  xor         s4, s4, a3
                  rem         s11, t5, s0
                  mulhsu      s6, a1, gp
                  slli        s6, t2, 26
                  mulhsu      tp, s3, a7
                  auipc       tp, 652981
                  bgeu        a0, a0, 7123f
7108:             nop
                  bgeu        gp, a0, 7114f
                  c.bnez      a3, 7111f
7111:             slli        s7, sp, 25
                  add         s0, s11, tp
                  srli        zero, a5, 14
7114:             c.addi      s10, 21
                  nop
                  bgeu        s4, s3, 7124f
                  c.add       ra, s0
                  div         s10, a6, s11
                  c.xor       a0, a1
                  c.nop
                  c.or        a0, a2
                  mul         zero, ra, t2
7123:             addi        s6, sp, 1474
7124:             bgeu        a6, s11, 7126f
                  sub         s11, s8, s6
7126:             c.lui       ra, 9
                  slli        a1, t6, 10
                  c.bnez      a3, 7132f
                  ori         a1, a4, -550
                  mulhu       s7, t2, t5
                  bge         a5, s4, 7133f
7132:             andi        t2, s6, 526
7133:             srai        s10, s7, 9
                  srl         a0, a0, t1
                  c.bnez      a3, 7136f
7136:             bgeu        a7, s5, 7152f
                  sub         t4, s1, zero
                  c.add       s7, t1
                  addi        s0, zero, 895
                  c.andi      a0, -1
                  c.add       s4, a4
                  c.sub       a0, a1
                  and         t1, s4, a0
                  c.xor       a3, a2
                  add         t5, a0, a0
                  c.bnez      a3, 7157f
                  bltu        s0, t2, 7157f
                  c.addi4spn  a2, sp, 144
                  beq         s1, s11, 7154f
                  rem         t4, a3, a1
                  c.addi16sp  sp, 80
7152:             and         s0, a0, a7
                  mulh        a1, t4, a1
7154:             c.srai      a1, 21
                  and         t3, s10, s8
                  bge         s3, s1, 7163f
7157:             c.mv        s9, s6
                  and         s8, tp, s2
                  srli        a6, a3, 5
                  auipc       t1, 410032
                  xor         a0, a2, t5
                  c.lui       t1, 4
7163:             slli        s3, s0, 29
                  c.li        ra, -1
                  xori        s10, a1, -484
                  c.srai      a3, 3
                  c.lui       a7, 9
                  lui         s3, 970617
                  c.nop
                  and         zero, gp, t5
                  mulhu       zero, s1, a1
                  xori        gp, s3, -909
                  c.andi      a0, 4
                  c.slli      s8, 14
                  divu        zero, s10, t5
                  rem         s5, a6, t6
                  mulhu       s0, s9, tp
                  c.bnez      a1, 7183f
                  andi        gp, a4, -1708
                  c.slli      a6, 21
                  sra         a7, a4, a6
                  mulh        a5, s2, s4
7183:             c.srai      a0, 30
                  xori        t0, t3, -1955
                  c.sub       a3, a1
                  c.add       s2, a2
                  slt         t3, t3, a2
                  bne         a1, sp, 7190f
                  blt         t2, t5, 7199f
7190:             div         a3, t1, zero
                  ori         tp, t5, -470
                  srl         s6, t0, s4
                  xor         zero, gp, ra
                  c.add       t0, ra
                  c.or        a2, a2
                  nop
                  sra         s5, sp, s1
                  bne         t3, s1, 7204f
7199:             sub         gp, s6, t6
                  c.add       ra, s9
                  c.slli      ra, 4
                  c.srli      a3, 24
                  c.srai      a1, 13
7204:             rem         zero, t1, t6
                  nop
                  c.srai      a0, 13
                  la x14, test_done
                  jalr x0, x14, 0
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
                  csrrw x31, 0x340, x31
                  add x31, x9, zero
                  1: addi x31, x31, -124
                  sw x1, 4(x31)
                  sw x2, 8(x31)
                  sw x3, 12(x31)
                  sw x4, 16(x31)
                  sw x5, 20(x31)
                  sw x6, 24(x31)
                  sw x7, 28(x31)
                  sw x8, 32(x31)
                  sw x9, 36(x31)
                  sw x10, 40(x31)
                  sw x11, 44(x31)
                  sw x12, 48(x31)
                  sw x13, 52(x31)
                  sw x14, 56(x31)
                  sw x15, 60(x31)
                  sw x16, 64(x31)
                  sw x17, 68(x31)
                  sw x18, 72(x31)
                  sw x19, 76(x31)
                  sw x20, 80(x31)
                  sw x21, 84(x31)
                  sw x22, 88(x31)
                  sw x23, 92(x31)
                  sw x24, 96(x31)
                  sw x25, 100(x31)
                  sw x26, 104(x31)
                  sw x27, 108(x31)
                  sw x28, 112(x31)
                  sw x29, 116(x31)
                  sw x30, 120(x31)
                  sw x31, 124(x31)
                  csrr x30, 0x300 # MSTATUS
                  csrr x30, 0x342 # MCAUSE
                  srli x30, x30, 31
                  bne x30, x0, mmode_intr_handler

mmode_exception_handler:
                  csrr x30, 0x341 # MEPC
                  csrr x30, 0x342 # MCAUSE
                  li x22, 0xb # ECALL_MMODE
                  beq x30, x22, ecall_handler
                  li x22, 0x2 # ILLEGAL_INSTRUCTION
                  beq x30, x22, illegal_instr_handler
                  csrr x22, 0x343 # MTVAL
                  1: la x14, test_done
                  jalr x1, x14, 0

ecall_handler:    
                  la x30, _start
                  sw x0, 0(x30)
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
                  la x14, write_tohost
                  jalr x0, x14, 0

illegal_instr_handler:
                  csrr  x30, 0x341
                  addi  x30, x30, 4
                  csrw  0x341, x30
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
                  add x9, x31, zero
                  csrrw x31, 0x340, x31
                  mret

pt_fault_handler: 

.align 2
mmode_intr_handler:
                  csrr  x30, 0x300 # MSTATUS;
                  csrr  x30, 0x304 # MIE;
                  csrr  x30, 0x344 # MIP;
                  csrrc x30, 0x344, x30 # MIP;
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
                  add x9, x31, zero
                  csrrw x31, 0x340, x31
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
