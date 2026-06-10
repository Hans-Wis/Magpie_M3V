# Magpie_M1 FPGA Boot Verification

Date: 2026-06-10

Scope:
- RTL under test: `IP/cpu_m1/soc/cpu_m1_fpga_top.v`, `axil_bootrom.v`, `axil_dp_bram.v`
- Verification artifacts: `flow/v2_pipeline/phase_p_fpga/`
- No SoC RTL changes were made.

Commands run:
- `make lint`
- `make run`

Program:
- Source: `fpga_boot_magic.S`
- Toolchain: `riscv-none-elf-gcc -march=rv32imc -mabi=ilp32`
- Link address: `0x20000000`
- BRAM preload hex: `build/fpga_boot_magic.hex`
- Behavior: initializes scratch word at `0x200000f8`, loops with `lw/add/sw` and `bnez`, checks loop sum, stores `0xCAFEF00D` to `0x20000FFC`, then executes `ebreak` and spins.

Key disassembly:

```text
20000000: 20000437   lui   s0,0x20000
2000000c: 0f842283   lw    t0,248(s0)
20000010: 92a6       add   t0,t0,s1
20000012: 0e542c23   sw    t0,248(s0)
2000001a: f8ed       bnez  s1,2000000c
20000032: 007e2023   sw    t2,0(t3)       # 0x20000ffc = 0xcafef00d
20000036: 9002       ebreak
```

Boot-flow trace from `build/sim.log`:

```text
TRACE cycle=1  pc=00000000 instr=00000000 magic=00000000 axi_err=0
TRACE cycle=7  pc=00000004 instr=00028067 magic=00000000 axi_err=0
TRACE cycle=16 pc=20000000 instr=20000437 magic=00000000 axi_err=0
TRACE cycle=19 pc=20000004 instr=00700493 magic=00000000 axi_err=0
TRACE cycle=28 pc=2000000c instr=0f842283 magic=00000000 axi_err=0
TRACE cycle=31 pc=20000010 instr=009282b3 magic=00000000 axi_err=0
TRACE cycle=37 pc=20000012 instr=0e542c23 magic=00000000 axi_err=0
TRACE cycle=46 pc=2000001a instr=fe0499e3 magic=00000000 axi_err=0
```

Observed result:

```text
RESULT magic_mem[1023]=cafef00d dbg_axi_err=0 trap=1 saw_rom0=1 saw_rom4=1 saw_ram=1 cycles=218
PASS cpu_m1_fpga_top boot ROM -> BRAM execution wrote MAGIC
```

Notes:
- The boot path was observed: ROM debug PC at `0x00000000` and `0x00000004`, then RAM execution starting at `0x20000000`.
- The test exercised BRAM port A through I-fetch and BRAM port B through D-read/D-write.
- `dbg_axi_err` stayed `0`.
- `trap=1` at the result is expected after the terminal `ebreak`.
- The trace includes transient `dbg_pc=0` samples after the jump/control-flow events; these did not stop execution, and the RAM program completed.
