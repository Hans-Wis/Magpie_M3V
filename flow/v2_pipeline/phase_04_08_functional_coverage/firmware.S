.section .init
.global _start

.option push
.option norvc
_start:
    lui  sp, %hi(16*1024)
    addi sp, sp, %lo(16*1024)

    # Enter the aliased high-PC view of this 16 KiB phase memory. Fetch uses
    # low address bits in tb_random_func_cov, so PC 0x00100100 executes the
    # instruction stored at image offset 0x100.
    lui  t0, 0x100
    addi t0, t0, 0x100
    jalr x0, 0(t0)

    .org 0x100
j_min:
    # Raw RV32 JAL x0,-0x100000. From high PC 0x00100100 the architectural
    # target is 0x00000100, keeping the target inside the 16 KiB phase image.
    .word 0x8000006f
.option pop
