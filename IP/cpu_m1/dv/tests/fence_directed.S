// Directed FENCE / FENCE.I (Zifencei) lockstep program (P1 bar-B-minus).
// riscv-dv pyflow does NOT generate random fence (instr_category skip), so FENCE/FENCE.I
// coverage comes from this directed test, verified per-commit against Spike. fence.i is a
// decoded architected NOP on cpu_m1 (no I-cache); it must retire equivalently to Spike and
// NOT decode-trap as illegal. Mixes fence with arith/load/store/mul so retirement ordering
// around the fences is exercised.

.section .init
.global _start

_start:
    lui  sp, %hi(16*1024)
    addi sp, sp, %lo(16*1024)

    addi s0, zero, 5
    addi s1, zero, 7
    fence                 # FENCE iorw,iorw (data fence)
    add  s2, s0, s1       # 12
    fence.i               # FENCE.I (Zifencei) — architected NOP here
    sw   s2, data_word, t0
    fence rw, rw          # explicit predecessor/successor set
    lw   s3, data_word    # 12
    fence.i
    mul  s4, s2, s1       # 84
    fence
    addi s5, s4, -3       # 81

.option push
.option rvc
    c.li   s6, 1
    c.addi s6, 2          # 3 — compressed around a following fence (alignment)
.option pop
    fence.i
    add  s7, s5, s6       # 84

done:
    ebreak

    .balign 4
data_word:
    .word 0
