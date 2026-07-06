OUTPUT_ARCH("riscv")
ENTRY(_start)
/* ADR-0062 S0 / gemma-e2e blocker fix: code is FETCHED from ITCM (npu_top: fetch = ITCM,
 * ADR-0044) while data + the CQ scratch regions (weight 0x700, MAT_OUT 0x800, descriptor
 * scratch 0xF00) live in the DTCM. The firmware .bss (latched CFG state) MUST NOT sit in the
 * weight-DMA region, or a GEMM weight blob overwrites it and hangs the engine. As code grows
 * (S0 added MAT_ACT_LUT/MAT_EWISE_MUL + int64 srdhm/rdbpot) .bss crept past 0x700; place it
 * high in the DTCM (0x2000, above all CQ scratch regions) instead. The DTCM copy of .text
 * that blobs overwrite is harmless — execution is from ITCM. No runtime-address changes. */
/* dtcm ORIGIN sits just above the CQ scratch regions (weight/blob top ~0xD40, descriptor
 * scratch 0xF00..0xF80) at 0x1000, and BELOW the 8K ITCM top — the same firmware.hex is
 * $readmemh'd into both the 8K ITCM and the 32K DTCM, so .rodata/.bss LMAs must fit the
 * smaller ITCM. Data is only READ from the DTCM copy; the ITCM copy is loaded but unused. */
MEMORY
{
  itcm (rx) : ORIGIN = 0x00000000, LENGTH = 8K
  dtcm (rw) : ORIGIN = 0x00001000, LENGTH = 28K
}
SECTIONS
{
  /* .text -> ITCM (fetched). .rodata (switch jump table etc.) is READ AS DATA from the
   * DTCM, so it — like .bss and the stack — must live ABOVE the CQ scratch regions
   * (weight/blob up to ~0xD40, descriptor scratch 0xF00), else a weight blob overwrites
   * it and the switch jumps to garbage. Park all DTCM-read data at 0x2000+. */
  .text : { *(.init) *(.text*) } > itcm
  .rodata : { *(.rodata*) } > dtcm
  .data : { *(.data*) } > dtcm
  .bss : { *(.bss*) *(.sbss*) *(COMMON) } > dtcm
}
