.section .init
.global _start

.option push
.option norvc
_start:
    lui  sp, %hi(16*1024)
    addi sp, sp, %lo(16*1024)

    li   s0, 0x10000000

    jal  ra, poison_ret

.global predicted_return
predicted_return:
    li   t2, 0xbad00bad
    sw   t2, 4(s0)
    j    done

.global actual_return
actual_return:
    li   t2, 0x00000406
    sw   t2, 0(s0)

done:
    j done

poison_ret:
    la   t0, actual_return
    mv   ra, t0
    ret
.option pop
