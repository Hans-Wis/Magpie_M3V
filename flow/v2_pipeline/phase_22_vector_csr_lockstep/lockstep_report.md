# ADR-0036 3A vector-CSR lockstep report (P0④)

Status: pass

Result: vcsr-lockstep matched 51 commits

Commits compared: 51 (bar: >= 40)

Spike ISA: `rv32im_zve32x_zvl128b_zicsr_zifencei`. Checkpoint discipline: csrr vl/vtype/vstart after every
config change; vsetvli rd values in-stream (ADR-0036 P0④ contract).
