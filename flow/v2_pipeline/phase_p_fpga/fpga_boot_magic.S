    .option rvc
    .section .text
    .globl _start
_start:
    lui   s0, 0x20000          /* BRAM base: 0x20000000 */
    addi  s1, zero, 7
    addi  s2, zero, 0
    sw    zero, 0x0f8(s0)      /* scratch at 0x200000f8 */

loop:
    lw    t0, 0x0f8(s0)
    add   t0, t0, s1
    sw    t0, 0x0f8(s0)
    addi  s2, s2, 1
    addi  s1, s1, -1
    bnez  s1, loop

    lw    t1, 0x0f8(s0)        /* expected loop sum = 28 */
    addi  t1, t1, -28
    bnez  t1, fail

    lui   t2, 0xcafef
    addi  t2, t2, 13           /* 0xcafef00d */
    lui   t3, 0x20001
    addi  t3, t3, -4           /* 0x20000ffc */
    sw    t2, 0(t3)

    ebreak
done:
    j     done

fail:
    lui   t2, 0xbad00
    addi  t2, t2, 13
    lui   t3, 0x20001
    addi  t3, t3, -4
    sw    t2, 0(t3)
fail_loop:
    j     fail_loop
