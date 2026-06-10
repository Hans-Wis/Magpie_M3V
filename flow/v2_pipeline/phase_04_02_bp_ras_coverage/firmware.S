.section .init
.global _start

.option push
.option norvc
_start:
    lui  sp, %hi(16*1024)
    addi sp, sp, %lo(16*1024)

    li   s0, 0x10000000

    li   t0, 0
    li   t1, 24
.global bp_loop
bp_loop:
    addi t0, t0, 1
    blt  t0, t1, bp_loop

    li   t2, 0x101
    sw   t2, 0(s0)

    jal  ra, func_a
    li   t2, 0x505
    sw   t2, 16(s0)

    li   t0, 0
    li   t1, 10
.global bp_countdown
bp_countdown:
    addi t0, t0, 1
    bne  t0, t1, bp_countdown

    li   t2, 0x606
    sw   t2, 20(s0)

done:
    j done

.option push
.option norvc
func_a:
    addi sp, sp, -16
    sw   ra, 12(sp)
    li   t2, 0x202
    sw   t2, 4(s0)
    jal  ra, func_b
    lw   ra, 12(sp)
    addi sp, sp, 16
    ret

func_b:
    addi sp, sp, -16
    sw   ra, 12(sp)
    li   t2, 0x303
    sw   t2, 8(s0)
    jal  ra, func_c
    lw   ra, 12(sp)
    addi sp, sp, 16
    ret

func_c:
    li   t2, 0x404
    sw   t2, 12(s0)
    ret
.option pop
