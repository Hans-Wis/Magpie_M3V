# A2 (Zba+Zbb+Zbs+Zicond) — design map (pre-RTL, ADR-0026 A2)

## Toolchain acceptance — VERIFIED 2026-06-11 (gate precondition)
- gcc 13.2 assembles all ops with `-march=rv32imc_zba_zbb_zbs_zicond_zicsr_zifencei` (probe: `toolchain_probe.S`).
- Spike executes + commit-logs all ops with the same ISA string (`--pc=0x80000000`).
- riscv-dv: generator stays RV32IMC; Zb*/Zicond lockstep stimulus = in-stream INJECTION (proven
  CSR/fence/RAS-pattern mechanism) + directed phase. Deterministic results → lockstep-safe.

## misa.B policy — RESOLVED (Spike parity, probed)
- spike `--priv=m --isa=rv32imc_zicsr` → misa 0x40001104 == DUT today (exact).
- spike `--priv=m --isa=rv32imc_zba_zbb_zbs_zicond_zicsr` → **0x40001106 (B bit set)**.
- A2: DUT `csr.v` misa gains bit1 (B) gated by the RV32B config param; farm `run_spike` adds
  `--priv=m` (also closes the latent S/U-bit misa divergence surface that existed with default priv).

## µarch decision: separate BMU (bit-manip unit), NOT alu_op widening
- alu_op is 4-bit with 12/16 used; A2 adds ~26 ops → would force 6-bit + bloat the base-ALU case mux
  (ADR flags Zb* mux growth as the freq-erosion risk).
- Instead: `bmu.v` pure-comb unit beside the ALU, own op encoding; EX result mux
  `ex_result = id_is_bmu ? bmu_result : alu_result` (one 2:1 mux on the EX path — per-sub-phase DC
  smoke validates; heavy ops clz/ctz/cpop/rol/ror/rev8/orc.b stay OUT of the base ALU path).
- Pipeline behavior identical to ALU ops (single-cycle at EX, EX/MEM forwardable, WB_SEL_ALU) —
  NO hazard/forward/control change at all (A1 was the control change; A2 is pure decode+datapath).

## Decode insertion (idu.v) — encoding truth source = toolchain_probe disasm
- OPC_OP (0110011): sh1/2/3add (f7=0010000, f3=010/100/110) · andn/orn/xnor (f7=0100000,
  f3=111/110/100) · min/minu/max/maxu (f7=0000101, f3=100/101/110/111) · rol/ror (f7=0110000,
  f3=001/101) · bclr/bext (f7=0100100, f3=001/101) · binv (0110100,001) · bset (0010100,001) ·
  zext.h (f7=0000100, f3=100, rs2=00000) · czero.eqz/nez (f7=0000111, f3=101/111)
- OPC_OP_IMM: clz/ctz/cpop/sext.b/sext.h (f7=0110000, f3=001, rs2sel=00000/00001/00010/00100/00101) ·
  rori (0110000,101) · orc.b (0010100,101,rs2=00111) · rev8 (0110100,101,rs2=11000) ·
  bclri/bexti (0100100,001/101) · binvi (0110100,001) · bseti (0010100,001)
- Everything else in those funct7/f3 slots stays ILLEGAL (negative tests per ADR D3).

## Gates (per ADR D2 row A2)
1. toolchain-acceptance (this doc + probe build/run record)        — BEFORE RTL merge ✓
2. directed lockstep phase_a2 (every op, +/- operands, edge shamt) — full per-commit
3. illegal-op negative tests (undecoded neighbors must trap)
4. in-stream injection lockstep at scale (farm)
5. CoreMark -march=...zba_zbb_zbs_zicond → KPI ≥2.9 CoreMark/MHz + instr-count budget check
6. DC smoke ≥650 MHz (bmu mux on EX path is the watch item)
