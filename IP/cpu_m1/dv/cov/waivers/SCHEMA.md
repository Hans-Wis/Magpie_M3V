# Coverage waiver schema (P01 infrastructure)

Per-stage waiver file: `waivers/Pnn_<scope>.json`. A waiver excludes STRUCTURALLY-unreachable coverage
points from the ADJUSTED metric. RAW always reports the un-waived number. Producer (Codex) drafts;
reviewer (Codex 2nd pass) challenges every line; approver (Claude) sets `approved:true` and commits —
producer≠approver (platform-0007). Behavioral bins are NEVER waived without a Spike-unreachability log.

```json
{
  "stage": "P11_csr",
  "waivers": [
    {
      "waiver_id": "TW-CSR-CYCLE-HI",
      "module": "csr.v",
      "dut_scope": "core",
      "signal_re": "cycle_cnt|instret_cnt",
      "bit_lo": 31, "bit_hi": 63,
      "toggle_count": 66,
      "structural_basis": "64-bit HW-increment-only counters; bit k needs 2^k retires; sim budget 1e8 -> bits>=31 unreachable. csr.v:82-83, RO (csr.v:21).",
      "quant_bound": "sim_budget=1e8 commits; waive bit k where 2^k > 1e8 (k>=27); conservative k>=31",
      "stimulus_considered": "max-length riscv-dv farm; cannot reach 2^31 retires in bounded sim",
      "spike_impact": "none (coverage-only; counters are Spike-lockstep-checked at low bits)",
      "approved": false,
      "approver": null
    }
  ]
}
```

## Field rules (Grok adjudication)
- `module`/`signal_re`/`bit_lo`/`bit_hi`: scope of the exclusion (regex on the coverage object name).
- `structural_basis`: RTL topology OR spec mandate OR proven width-excess — cite file:line / spec §. NOT
  "sim too short" alone (except the quantified counter case with `quant_bound`).
- `stimulus_considered`: the directed/random stimulus that was tried — proves no legal stimulus covers it.
- `spike_impact`: must be "none" (coverage-only); a behavioral effect means it is NOT a structural waiver.
- `approved`/`approver`: only Claude (not the coverage producer) sets these. Un-approved waivers are
  ignored by cov_metrics (RAW==ADJUSTED until approved).

## Forbidden (green-wash — auto-reject in review)
"firmware stays in low memory" (PC bits — stimulus choice) · "random DV didn't hit it in N seeds" ·
"tied off in this TB" without measuring on the correct top · blanket module waivers without per-signal proof.
