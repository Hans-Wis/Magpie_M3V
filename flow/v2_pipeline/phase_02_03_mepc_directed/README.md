# Phase 02.03: Directed mepc Precision

Directed M-mode tests for `mepc` WARL bit 0 masking and precise synchronous
trap PC save. The handler records `mepc/mcause/mtval` through MMIO, then forces
`mepc` to a table-driven resume PC so pre-fix observation can continue even
when the DUT saved the wrong fault PC.
