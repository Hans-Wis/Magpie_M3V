# Phase-C C1 (same-width integer multiply) — review + verification record (2026-07-05)

Instrs: `vmul` `vmulh` `vmulhu` `vmulhsu` (Zve32x). ADR-0056 §5 C1.

## Legs
- **Grok (architecture)**: `docs/reviews/2026-07-05_phase_c_plan_grok.md` — sub-slice order
  C1→C3→C2→C4→C5; C1 sign matrix / f6 / f3-disjointness (vsll OPIVX, vmv<nr>r OPIVI)
  all confirmed matching the implementation.
- **Spike golden probe (correctness authority)**: hand case -2^31 * 2 on Spike
  `--isa=rv32imf_zve32x_zvl128b`: vmul=0x00000000, vmulh=0xFFFFFFFF(-1),
  vmulhu=0x00000001, vmulhsu=0xFFFFFFFF(-1). RTL matched every element.
- **Spike lockstep**: `make c1` -> 125 commits bit-exact (4 variants x vv/vx x SEW
  8/16/32 sign matrix, e32/m2 group smoke, masked-vmul-writing-v0 illegal terminator).
  Regression: 13 vector targets green incl vmem/s3/vrand(1324). Gate gate_66.

## Implementation note
Dedicated per-SEW loops (g_mul8/16/32) mirror the widening-loop style: form the full
2*SEW product in self-determined signed/unsigned wires, then slice low (vmul,
sign-agnostic) or high (mulh/mulhu/mulhsu). The signed*unsigned product uses
`p_su = as * $signed({1'b0, b})` — a sign-extended, b zero-extended (MSB forced 0),
sidestepping the recurring signed-in-ternary zero-extend trap. op_muls joins beats_op
so m2/m4 groups iterate via the existing VM_GRP FSM + atomic WB commit.

## Gemini full-context review — verdict
The RISC-V RVV Zve32x Phase-C C1 RTL implementation is **clean and fully compliant with the specification**. No bugs or spec conformance issues were found.

Here is the architectural verification of the key checks:

### 1. Width & Sign Correctness of the $2 \times \text{SEW}$ Products (The Signed-Unsigned Multiply Idiom)
The code uses the following idiom for `vmulhsu` (signed $\times$ unsigned):
```verilog
wire signed [2*SEW-1:0] p_su = as * $signed({1'b0, b});
```
This is **100% correct and robust** under Verilog-2001 and SystemVerilog rules:
- **Signed Multiplier Context:** Since both operands (`as` and `$signed({1'b0, b})`) are signed, the multiplication `*` is executed as a signed multiplication.
- **Proper Sign/Zero Extension:** In a context-determined expression of width $2 \times \text{SEW}$ (e.g., 16/32/64 bits):
  - `as` (signed, $\text{SEW}$ bits) is correctly sign-extended to $2 \times \text{SEW}$ bits.
  - `$signed({1'b0, b})` (signed, $\text{SEW}+1$ bits) is sign-extended to $2 \times \text{SEW}$ bits. Because its most-significant bit is hardcoded to `1'b0`, sign-extending it to $2 \times \text{SEW}$ pads it with zeros, resulting in a correct zero-extension of `b`.
- **Dynamic Range Safety:** For all SEW widths (8, 16, 32), the maximum possible product of a signed $\text{SEW}$ integer and an unsigned $\text{SEW}$ integer fits exactly within the $2 \times \text{SEW}$ signed width without overflow or truncation.

### 2. Low-bit `vmul` from Signed-Signed Product (`p_ss`)
The code selects `p_ss[SEW-1:0]` for `vmul`. This is mathematically correct because:
- The lower $\text{SEW}$ bits of a product are identical for signed $\times$ signed, unsigned $\times$ unsigned, and signed $\times$ unsigned multiplications (i.e., the lower bits of multiplication are sign-agnostic). Using `p_ss` for all `vmul` cases avoids redundant multiplier instances.

### 3. Operand & Decode Select Correctness
- **OPMVV vs. OPMVX Select:** `b` is correctly multiplexed to use `vs1_data` when `is_opmvv` is asserted, and to use the scalar register `scalar_b` (properly truncated to the current SEW) when `is_opmvx` is asserted.
- **Instruction Encodings:** The `funct6` mappings for `vmul` (`100101`), `vmulh` (`100111`), `vmulhu` (`100100`), and `vmulhsu` (`100110`) match the RVV v1.0 specifications exactly.

### 4. Vector Masking and Multi-Beat Register Groups (LMUL > 1)
- **Masking & Boundaries:** The elements are correctly kept undisturbed (`vd_old`) when they are masked off (`vm` is 0 and mask bit `m` is 0), or when the element index falls outside the active range (`gi < vst_view` or `gi >= vl_view`).
- **Multi-Beat Group Integration:** `op_muls` correctly joins `beats_op`, which ensures that operations under `LMUL > 1` (e.g., `m2`, `m4` groups) are processed over multiple beats using the FSM. `part_res` successfully routes `res_mul` to `grp_stage[0]` for multi-beat write-backs.
- **Overlap Hazard Prevention:** The instruction is correctly flagged as illegal if `vm = 0` (masked) and the destination register `vd` is `v0` (`vd_i == 5'd0`).

**Verdict: clean, fully compliant — no RTL change from review** (verified the
signed-unsigned idiom, low-bit vmul, OPMVV/OPMVX operand select, masking + groups).
