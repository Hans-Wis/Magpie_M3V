# P17 Core Trap/IRQ/MRET Directed Lockstep

Scope: P17-owned `core.v` CSR/trap/IRQ/MRET glue only. This phase does not claim
P11 standalone `csr.v` register closure and does not mark the integration gate
green.

Run:

```sh
make -C flow/v2_pipeline/phase_p17_core_trap -B
```

Outputs:

- `dut_commit.trace` and `spike_commit.trace`: Spike lockstep commit CSVs.
- `dut_trap_events.csv`: core-owned trap-entry event evidence.
- `directed_lockstep_report.md`: Spike comparison and trap-event checks.
- `p17_core_trap_report.md`: owned-signal coverage classification.
