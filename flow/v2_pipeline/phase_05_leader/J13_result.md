## summary
- full-RV32IMC-noCSR seeds clean: YES, 5/5 seeds (`2026060801..2026060805`) matched 6882 commits total.
- summary JSON status is `INCOMPLETE` only because target_commits was set to 999999 to force all seeds; no divergence rows and unresolved_real_dut_divergences=0.

## divergences
- REAL-DUT: branch `c.beqz` @pc=0x17a4 redirected to 0x17ba while wrong-path `mulhsu zero,s3,a3` @pc=0x17a6 asserted M stall/start; DUT target commit initially corrupted vs Spike `c.addi16sp sp,-16`, x2=0xffffffe0. Fix: redirect overrides fetch stall and kills/gates decode-side M start in `core.v`; ADR-0009.
- REAL-DUT: M done/result boundary was same class as ADR-0004 and the open `rem s10,s8,gp` @pc=0x1478 symptom: result association depended on same-edge done sampling. Fix: `mul.v`/`div.v` latch result before asserting `done`; ADR-0009.
- HARNESS: after RTL fix, branch @pc=0x191e diverged because DUT ran at reset PC 0 while Spike ran ELF at 0x1000; post-normalizing writebacks could not preserve Spike control flow (`mul s10,s6,ra` @pc=0x18f0 evidence). Fix: reset DUT to ELF_BASE, translate TB memory offsets, Spike `--pc=0x1000`, no writeback-base normalization.

## revalidate
- `python3 -m pytest tests/gates/gate_*.py -q`: PASS, 180 passed.
- `gate_03_08_lockstep_revalidate`: PASS, 1 passed; current RTL arith lockstep rerun matched DUT/Spike traces.
- `gate_02_01_mem_wrapper`: PASS, 6 passed; `gate_04_08_functional_coverage`: PASS, 5 passed and report says 100.00% (72/72 bins).
- Prior arith >=100k artifact checked in J11_result: PASS 114216 commits; not relaunched per J13 no-full-100k constraint.

## regressions
- none observed in the 5-seed RV32IMC-noCSR sweep.

## open
- none remaining in mem + ctrlflow + M noCSR scope; CSR intentionally still off; full 100k RV32IMC was not launched.

## tokens
- not metered by local tools.
