# Phase 4.4 Illegal Compressed Trap + M-Unit Coverage

Status: coverage-delta-pass candidate

This phase merges two remaining high-value coverage buckets on top of Phase 4.3:

- M-unit corner/stall/result coverage for `mul.v`, `div.v`, and core M-unit
  result-latch paths.
- Illegal compressed decode and terminal trap semantics.

The illegal compressed path in the active lab08e-derived RTL is a simplified
terminal trap path: `cdec_illegal` propagates through decode/execute/writeback,
sets `trap`, and halts forward progress. It is not a full CSR exception flow.

This phase checks that model explicitly; it does not claim full illegal
instruction exception sign-off.
