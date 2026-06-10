# P18 Core BP/RAS Recovery Integration

Status: report-only, not gate-green.

This phase is the P18 integration slice for `core.v` BP/RAS recovery wiring.
It runs the full core through Verilator with coverage, emits a DUT commit
trace, compares every DUT commit against Spike, and reports only the P18
`core.v` roster delta. BP/RAS leaf table and stack internals remain P13/P14
owned and are not re-claimed here.

Directed fixtures:

- taken/not-taken backward branch pairs,
- 4+ taken updates at one branch offset plus repeated not-taken outcomes,
- two taken branches separated by 64 bytes for same-index target aliasing,
- `jal`/`ret` call-return with RAS push/pop,
- poisoned `ra` return to force RAS target mismatch recovery,
- JAL target training and redirect wrong-path clearing.

Run:

```sh
make -C flow/v2_pipeline/phase_p18_core_bpras -B p18_core_bpras.log
```

Primary outputs:

- `directed_lockstep_report.md`
- `p18_core_bpras_report.md`
- `module_delta.csv`
- `coverage/merged_with_phase_p18.dat`
- `coverage/coverage.info`
