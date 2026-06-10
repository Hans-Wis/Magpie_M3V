# Magpie_M1 ASIC SRAM Subsystem Report

Scope: `cpu_m1_asic_top` = CPU -> AXI4-Lite -> one TSMC28 1RW1R 512x32 SRAM macro.

## Verilator

Command:

```sh
make -C flow/v2_pipeline/phase_p_asic clean run
```

Result: PASS.

Evidence:

```text
RESULT magic_mem[511]=cafef00d dbg_axi_err=0 trap=0 saw_rom0=1 saw_rom4=1 saw_ram=1 cycles=290
PASS cpu_m1_asic_top boot ROM -> T28 SRAM execution wrote MAGIC
```

The test holds reset while the behavioral SRAM port model is preloaded, then releases the CPU. The boot ROM fetches at `0x00000000` and `0x00000004`, jumps to `RAM_BASE=0x20000000`, executes from SRAM, and stores MAGIC at SRAM word 511 (`0x200007fc`).

## SRAM Read Latency

`axil_sram_t28` handles the synchronous 1-cycle macro read explicitly:

- AXI AR handshake asserts macro `csb` low and drives `addr`.
- A per-port `*_rd_pending` bit records the accepted request.
- On the following clock, wrapper samples macro `dout*`, drives AXI `RDATA`, and raises `RVALID`.
- D-side writes use macro port0 with `wmask0=b_wstrb`; D-side reads share port0 and are not accepted in a cycle where a write commits.

## DC Synthesis

Command:

```sh
make -C flow/v2_pipeline/phase_p_asic dc
```

Tool: Design Compiler X-2025.06-SP2.

Libraries:

- Stdcell: `/home/edauser/project/SOC/Magpie_X3/APR/ref/db/tcbn28hpcplusbwp40p140tt0p9v25c.db`
- SRAM: `/home/edauser/project/SOC/Magpie_X3/APR/ref/db/tsdn28hpcpa512x32m4mwaso_130a_tt0p9v25c.db`

Result:

- Setup target: 1.43 ns
- Setup WNS/TNS: 0.00 ns / 0.00 ns
- Estimated Fmax: 699.30 MHz
- Total cell area: 42682.454623 um2
- Macro/black-box area: 15515.090820 um2
- Macro count: 1

The mapped netlist preserves the SRAM as `TSDN28HPCPA512X32M4MWASO \u_sram/u_sram/u_macro`.

Caveat: this is not a green signoff gate. The DC QoR report still shows hold issues in this simple single-corner run: worst hold violation -0.06 ns, total hold violation -2.96 ns, 88 hold-violating paths.

## Token Record

No active Codex goal token budget was available from the session goal tracker, so exact consumed-token accounting is unavailable here.
