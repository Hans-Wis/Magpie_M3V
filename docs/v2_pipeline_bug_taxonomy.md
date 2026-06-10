# Magpie_M1 v2 Pipeline Bug Taxonomy

This file records bugs and risk items found while turning Ch2 `lab08e` into
Magpie_M1 CPU IP. It is qualification evidence only when paired with the listed
reproduction command and regression gate.

| ID | Area | Found by | Symptom | Root cause | Current action | Regression gate | Status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| BUG-IRQ-0001 | CSR external IRQ pending | Phase 3.1 trap/IRQ lockstep | A one-cycle IRQ pulse overlapping trap entry can leave `ext_pending` set and cause repeated IRQ after `mret`. | Pulse-based external IRQ model uses one sticky pending bit; original lab08e `pulse > trap_enter > hold` priority preserves same-cycle pulses but can retain the current IRQ pulse through trap entry. | Local Magpie_M1 `csr.v` changed to `trap_enter > pulse > hold`; ADR-0003 records this as a local deviation. | `tests/gates/gate_03_01_trap_irq_lockstep.py`; `tests/gates/gate_03_02_irq_collision.py` | Closed for current pulse contract: single compressed IRQ path and collision contract pass. |
| RISK-IRQ-0002 | CSR external IRQ pending | ADR-0003 review | A pulse sampled in the exact `trap_enter` cycle cannot be distinguished from the current IRQ event with only one pulse input and one sticky pending bit. | The IP-level external interrupt input is a one-cycle pulse, not a level-sensitive MEIP source or claim/clear handshake. | Current contract defines same-cycle pulse as acknowledged with trap entry; a pulse after trap entry must be queued. Phase 3.2 verifies this. Future level/claim-clear wrapper remains a separate architecture decision. | `tests/gates/gate_03_02_irq_collision.py` | Closed for current pulse contract; wrapper-level IRQ interface decision remains future work. |
| BUG-MD-0001 | M-unit result routing | Phase 3.5 deterministic random Spike lockstep | `div a6, a2, t5` wrote `0x00000000` in DUT while Spike expected `0x0000007b` at commit index 34. | The M-unit result path depended on current decode/done timing instead of stable state for the operation that was started. | Local Magpie_M1 `core.v` now latches active M op type and completed result with `md_active_is_div`, `md_result_valid`, and `md_result_q`; ADR-0004 records this as a local deviation. | `tests/gates/gate_03_04_directed_lockstep.py`; `tests/gates/gate_03_05_random_lockstep.py`; `tests/gates/gate_03_06_multi_seed_coverage.py`; `tests/gates/gate_03_07_muldiv_hazard.py` | Closed for directed Phase 3.4, deterministic random seed `20260607`, Phase 3.6 seeds `20260607..20260611`, and Phase 3.7 directed M hazard/corner regression; broader M-extension random/DV and coverage closure remain required. |
| BUG-IDU-0001 | Reserved branch decode | Phase 4.7 Claude Code advisory review | Reserved BRANCH funct3 encodings `010`/`011` were treated as valid branches (`illegal=0`) when Phase 4.7 used a reserved branch encoding to cover the IDU default branch compare arm. | `known_opcode` accepted any `OPC_BRANCH` instruction without checking whether `funct3` was one of BEQ/BNE/BLT/BGE/BLTU/BGEU. | Local Magpie_M1 `idu.v` now qualifies branch legality with `branch_funct3_valid`; the default branch ALU arm remains covered by direct IDU stimulus, but the reserved encoding now asserts `illegal=1`. | `tests/gates/gate_04_07_csr_idu_residual_coverage.py`; full active gate set `python -m pytest tests/gates/gate_*.py -q` | Closed after Phase 4.7 rerun and full active gate regression. |

## Reproduction

Current passing single-IRQ regression:

```sh
make -C flow/v2_pipeline/phase_03_01_trap_irq_lockstep -B trap_irq_lockstep.log
python -m pytest tests/gates/gate_03_01_trap_irq_lockstep.py
```

Expected result:

```text
PASS: prefix lockstep matched 13 commits; trap events matched mepc/mcause/mstatus/mret
```

Current passing collision-contract regression:

```sh
make -C flow/v2_pipeline/phase_03_02_irq_collision -B sim.log
python -m pytest tests/gates/gate_03_02_irq_collision.py
```

Expected result:

```text
PASS: IRQ collision contract validated
```

Current passing deterministic random M-extension regression:

```sh
make -C flow/v2_pipeline/phase_03_05_random_lockstep -B random_lockstep.log
python -m pytest tests/gates/gate_03_05_random_lockstep.py
```

Expected result:

```text
PASS: random lockstep matched 81 commits
```

Current passing multi-seed random/coverage regression:

```sh
make -C flow/v2_pipeline/phase_03_06_multi_seed_coverage -B multi_seed_coverage.log
python -m pytest tests/gates/gate_03_06_multi_seed_coverage.py
```

Expected result:

```text
PASS: multi-seed lockstep matched 5 seeds / 405 commits; line coverage 79.12% (894/1130)
```

Current passing directed M-unit hazard regression:

```sh
make -C flow/v2_pipeline/phase_03_07_muldiv_hazard -B muldiv_hazard.log
python -m pytest tests/gates/gate_03_07_muldiv_hazard.py
```

Expected result:

```text
PASS: muldiv hazard lockstep matched 45 commits
```

## Qualification Note

Phase 3.1 uses Spike for the pre-IRQ architectural prefix. Trap/IRQ CSR values
are checked by a deterministic expected-event model, not by Spike external IRQ
timing injection. Full IRQ qualification still needs broader directed tests,
random/DV stimulus, and coverage closure. Phase 3.5 is deterministic bounded
pseudo-random RV32IMC stimulus, not Google RISC-V DV or coverage closure. Phase
3.6 starts coverage measurement, but 79.12% line coverage is not closure and
requires Phase 4.0 residual analysis.
