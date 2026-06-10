.section .init
.global _start

.option push
.option norvc
_start:
    lui  sp, %hi(16*1024)
    addi sp, sp, %lo(16*1024)

    # Retire-sample the J-format zero immediate. The phase testbench stops this
    # bounded self-loop with +stop_after_commits after the WB covergroup samples.
j_zero:
    jal x0, j_zero
.option pop
