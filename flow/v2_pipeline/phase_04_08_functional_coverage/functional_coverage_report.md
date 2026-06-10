# Phase 4.8 Functional Coverage Report

Overall functional coverage: 100.00% (210/210 effective bins); raw before exclusions: 99.53% (210/211 bins); gate threshold: 100%.
Execution status: measured.

| covergroup | hit% | hit/total | notable uncovered bins |
| --- | ---: | ---: | --- |
| cg_opcode_instr_class | 100.00 | 13/13 | none |
| cg_alu_m_funct | 100.00 | 21/21 | none |
| cg_load_store | 100.00 | 12/12 | none |
| cg_branch_jump_bp_ras | 100.00 | 10/10 | none |
| cg_hazard_flush | 100.00 | 6/6 | none |
| cg_csr_trap | 100.00 | 10/10 | none |
| cg_riscvisacov_operands | 100.00 | 103/103 | none |
| cg_riscvisacov_value_corners | 100.00 | 12/12 | none |
| cg_riscvisacov_immediates | 100.00 | 23/23 | j:max (justified exclusion) |

## Uncovered Bin Triage

| covergroup | bin | reason | reachability | waiver |
| --- | --- | --- | --- | --- |
| cg_riscvisacov_immediates | j:max | JUSTIFIED EXCLUSION: structural memory-map limit | RV32 JAL max positive offset is +0xFFFFE; from any nonzero JAL PC this requires an approximately 1 MiB forward executable target, but this phase/SKU config maps only 16 KiB (firmware.lds rom LENGTH=16K; tb_random_func_cov MEM_SIZE=4096 words indexed by i_mem_addr[13:2]) | waive |

## Justified Exclusions

| covergroup | bin | justification |
| --- | --- | --- |
| cg_riscvisacov_immediates | j:max | RV32 JAL max positive offset is +0xFFFFE; from any nonzero JAL PC this requires an approximately 1 MiB forward executable target, but this phase/SKU config maps only 16 KiB (firmware.lds rom LENGTH=16K; tb_random_func_cov MEM_SIZE=4096 words indexed by i_mem_addr[13:2]) |

## Provenance

Key commands are captured in `provenance.log`; raw VCS/URG logs and databases remain in this phase directory.
