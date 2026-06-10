# Phase 4.7 CSR/IDU Residual Coverage

Purpose: close the reachable CSR and IDU line residuals identified after
Phase 4.6 without changing RTL.

Stimulus style:

- Direct `csr` instance for high-counter reads, explicit `mepc`/`mcause` writes,
  and unsupported CSR write default handling.
- Direct `idu` instance for `FENCE`, `FENCE.I`, unsigned branch decode, and a
  reserved branch funct3 default decode arm.

This is a coverage-delta phase only. It is not sign-off: toggle coverage remains
below target and functional coverage bins are still not implemented.

Run:

```bash
make -B csr_idu_residual_coverage.log
```
