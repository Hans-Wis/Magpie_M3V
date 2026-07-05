# Phase-B B4 (whole-register move) — review + verification record (2026-07-05)

Instr: `vmv1r.v` `vmv2r.v` `vmv4r.v` `vmv8r.v` (Zve32x). ADR-0055 §6 B4.

## Legs
- **Grok (architecture / spec flags)**: `docs/reviews/2026-07-05_phase_b_encoding_grok.md` §6
  gave encoding (simm5=nr-1, {0,1,3,7}), alignment, and the vtype-independence note.
- **Empirical Spike probes (correctness authority — OVERRODE one Grok flag)**: ran Spike
  `--isa=rv32imf_zve32x_zvl128b` directly on hand-built cases:
  - `vstart!=0` → **illegal trap** (NOT the partial-copy Grok predicted in §149-152).
    So the pre-existing global "known_op && vstart!=0 → illegal" rule already matches;
    no carve-out was needed. **This is exactly the divergence §4 discipline guards
    against — blindly following Grok's flag would have failed lockstep.**
  - `vmv1r.v` under an **m8 vtype** → **executes** (full copy) ⇒ vmvr must be exempt
    from the `lmul_m8` illegal term.
  - `vill=1` → illegal; misaligned `vd` (nr=2, vd odd) → illegal; nr=3 (simm=2) → illegal.
- **Spike lockstep**: `make b4` → **77 commits bit-exact**; all four nr verified by
  vse32+lw, an over-copy guard (sentinel in v24 survives vmv8r), vtype-independence
  (vmv1r under m8), misaligned-vmv2r illegal terminator. Regression: 13 vector targets
  green incl. vmem/s3/vrand(1324). Gate `tests/gates/gate_65_rvv_b4_wholereg.py`.

## Implementation note (why a dedicated copy loop)
nr=8 copies 8 registers, exceeding the existing 4-part group-staging path. So vmvr
runs its own `VM_VMVR` FSM state: one register/cycle, written directly in the sole
VRF write always-block. `q_is_grp=1` holds the core; `q_vrf_we=0`/`q_grp_w=0` so the
WB port writes nothing. Aligned groups are equal-or-disjoint ⇒ src≠dst (no hazard);
drained-start ⇒ `w_en` targets no VRF entry during the copy (single writer preserved).

## Gemini full-context review — findings + disposition
Here is the spec conformance and bug review for the `vmv<nr>r.v` Phase-B B4 implementation in `vexu.v`. 

---

### **Summary of Conformance**
The FSM-based, register-at-a-time copy loop is mostly highly conformant and robust. It correctly bypasses `lmul_m8` checks, enforces standard `vstart != 0` trap legality rules, utilizes an elegant mask-based alignment check, and disables standard writeback to ensure the FSM loop has exclusive write access.

However, three concrete issues have been identified that Spike lockstep (which is typically cycle-insensitive or ignores microarchitectural behavior like stalls and synthesis limits) would miss:

---

### **Ranked Concrete Issues & Gaps**

#### **1. Lack of Stall Gating on VRF Writes during `VM_VMVR` (High Priority - PPA & Power Waste)**
* **The Issue:** 
  The FSM state transitions and the register offset counter (`vmvr_p`) are gated by `!m_stall` in the main FSM always block:
  ```verilog
  end else if (!m_stall) begin
      case (vm_state)
          VM_VMVR: begin ... end
  ```
  However, the VRF write block is not gated by `!m_stall`:
  ```verilog
  if (vm_state == VM_VMVR)
      vrf[vd_i + {2'b0, vmvr_p}] <= vrf[vs2_i + {2'b0, vmvr_p}];
  ```
  During a pipeline stall (`m_stall == 1`), `vm_state` remains `VM_VMVR` and `vmvr_p` holds its current index. As a result, the same register `vrf[vd_i + vmvr_p]` is written with the same source value **every cycle of the stall**.
* **Impact:** 
  * Massive dynamic power waste (violating PPA targets) due to redundant toggling of VRF write-enable lines and RAM/register clock gating.
  * Potential functional hazards if any other bypass paths or clock gating domains are active during the stall.
* **Fix:** 
  Gate the VRF write with the stall signal:
  ```verilog
  if ((vm_state == VM_VMVR) && !m_stall)
      vrf[vd_i + {2'b0, vmvr_p}] <= vrf[vs2_i + {2'b0, vmvr_p}];
  ```

---

#### **2. Inhibition of Block RAM (BRAM) Synthesis / Multiple Write Drivers (Medium Priority - PPA & Area)**
* **The Issue:** 
  The VRF is written to using two structurally separate conditional statements with different address/data expressions in the same `always` block:
  ```verilog
  if (w_en)
      vrf[w_addr] <= w_data;
  if (vm_state == VM_VMVR)
      vrf[vd_i + {2'b0, vmvr_p}] <= vrf[vs2_i + {2'b0, vmvr_p}];
  ```
* **Impact:** 
  Standard ASIC/FPGA synthesizers compile 2D arrays (`vrf`) into Block RAMs or SRAMs. Even though the "drained-start" architecture guarantees that `w_en` and `vm_state == VM_VMVR` are mutually exclusive in time, the structural split forces the synthesizer to infer a multi-ported write structure. This will either **fail synthesis** or **force fallback to thousands of individual flip-flops**, massively inflating area, power, and routing congestion.
* **Fix:** 
  Mux the signals upstream to maintain a single, clean write-port interface:
  ```verilog
  wire vrf_we = w_en || ((vm_state == VM_VMVR) && !m_stall);
  wire [4:0] vrf_waddr = (vm_state == VM_VMVR) ? (vd_i + {2'b0, vmvr_p}) : w_addr;
  wire [127:0] vrf_wdata = (vm_state == VM_VMVR) ? vrf[vs2_i + {2'b0, vmvr_p}] : w_data;

  // Inside always block:
  if (vrf_we)
      vrf[vrf_waddr] <= vrf_wdata;
  ```

---

#### **3. Infinite Loop / Deadlock in `VM_VMVR` on Malformed/Illegal `vmvr_nr` (Low Priority - Robustness)**
* **The Issue:** 
  In the `VM_VMVR` loop, the FSM checks for termination using:
  ```verilog
  if ({1'b0, vmvr_p} + 4'd1 == vmvr_nr)
  ```
  If `vmvr_nr` is `4'd0` (reserved simm), the condition `{1'b0, vmvr_p} + 4'd1 == 4'd0` can never be true (as `vmvr_p` goes from 0..7). `vmvr_p` will increment, overflow, wrap around, and loop infinitely.
* **Impact:** 
  While `vmvr_illegal` is correctly decoded to trap this, defensive design rules dictate FSMs must never hang under any condition. If a simulation force, fault injection, or bypass ever triggers `m_start` with an illegal state, the processor will lock up.
* **Fix:** 
  Change the exit condition to a comparison that handles `0` safely:

### Disposition (Claude verified each)
- **F1 (m_stall gating) — APPLIED.** Not a correctness bug (the stall rewrite is
  idempotent: same source, disjoint stable groups), but redundant power and
  inconsistent with the FSM's own `!m_stall` gating. Gated the VRF write with
  `!m_stall`. Re-verified b4 + regression green.
- **F2 (BRAM / multi-driver) — NO CHANGE (premise false).** The VRF is already a
  multi-write flop array: the group commit writes up to **4 different addresses in
  one cycle** (`vrf[w_vd]`, `+1`, `+2`, `+3`). A 4-write structure is not BRAM-
  inferrable and cannot be muxed to a single port. The one extra time-exclusive
  vmvr write is consistent with that existing structure; no synthesis regression.
- **F3 (VM_VMVR hang on nr==0) — APPLIED (defensive).** Unreachable in normal
  operation (nr==0 ⇒ `vmvr_illegal` ⇒ `q_illegal` ⇒ `q_is_grp=0` ⇒ never enters
  VM_VMVR). Changed the exit test to `>=` so a forced/faulted malformed nr can never
  hang the FSM. Belt-and-braces, zero cost.
