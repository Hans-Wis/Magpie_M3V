# J19 - fresh riscv-dv lockstep validation

Status: **PASS**.

## summary
- Fresh seed range: 2026061001..2026061019.
- Total matched commits vs Spike: 105111, exceeding the 100000 target.
- Seeds: 19 clean, 0 failed, 0 waived.
- Throughput: 59.13 matched commits/sec over 1777.60 sec wall-clock.
- Command:
  `python3 flow/v2_pipeline/phase_03_09_riscvdv_lockstep/run_riscvdv_lockstep.py --start-seed 2026061001 --seeds 120 --instr-cnt 20000 --target-commits 100000 --max-cycles 10000000`

## scope
Default core config validated as RV32IMC with CSR and sync-trap streams against Spike
golden `rv32imc_zicsr_zifencei_zicntr`.

Included: RV32I, RV32C, RV32M, load/store, branch/jump, M-mode CSR instructions,
sync-trap streams. Excluded: async interrupts, riscv-dv SYNCH/fence stream, A/F/D/V,
unsupported privileged behavior.

## divergences
None. No DUT-vs-Spike divergence was observed, no real DUT bug was classified, and no
waiver was used.

## disk_hygiene
Successful per-seed run directories were cleaned after comparison. Summary records
`passing_run_dirs_cleaned=19`; `runs/` ended at 12K. Disk free stayed effectively flat:
start 649279628 KiB, minimum 649276412 KiB, end 649277624 KiB.

## revalidate
Official summary:
`flow/v2_pipeline/phase_03_09_riscvdv_lockstep/riscvdv_lockstep_summary.json`
records `status=PASS`, `total_matched_commits=105111`, and
`unresolved_real_dut_divergences=0`.

## tokens
Codex token count not available from the local harness; validation wall-clock and
throughput are recorded in the summary JSON.
