.section .init
.global _start

_start:
    .option push
    .option rvc
    c.li   s0, 1
    c.j    target_high32
    c.nop
target_high32:
    .4byte 0x00500493
    .4byte 0x00700913
done:
    .option pop
    ebreak
