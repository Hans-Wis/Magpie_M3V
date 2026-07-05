# Phase-E E3 (vrgather) — three-way review + verification record (2026-07-05)

ADR-0058 §2 E3. vrgather.vv/.vx/.vi.

## Legs
- **Spike probes (authority)**: vd[i]=(index>=vlmax)?0:vs2[index]; index=vs1[i](SEW)/
  rs1/uimm. f6=001100. require_noover: vd==vs2 illegal AND (.vv) vd==vs1 illegal;
  vstart!=0 illegal. Golden src[10..17] idx[3,0,7,2,9,1,5,4] -> [13,10,17,12,0,11,15,14].
- **Spike lockstep**: make e3 -> 73 commits bit-exact (.vv/.vx/.vi x SEW 8/16/32,
  out-of-range indices ->0, broadcast, masked gather, vd==vs2 overlap illegal terminator).
  Regression full vector suite incl e1/e2/d2/pool/vrand(1324) green. Gate gate_79.

## Implementation note
Combinational crossbar per SEW: idx = opivv? vs1[i] : opivi? uimm : rs1 (zero-ext to 32);
oor = (idx >= vlmax_el, fractional-aware); gval = oor ? 0 : vs2[idx[low bits]] (16:1/8:1/
4:1 lane select). vrg_illegal = vd==vs2 || (.vv && vd==vs1). m1-only (grp_only_illegal);
vstart via global rule; masked-vd0. vrgatherei16 (f6=001110 OPIVV) deferred (16-bit index
would need an EMUL>1 index register group).

## Three-way review
- **Codex — no correctness bugs**: crossbar select + OOR->0, index sources per form,
  overlap/vstart/masked-vd0/LMUL-group legality, active/mask/tail all verified.
- **Grok — no concrete bugs**: confirmed OOR uses full zero-extended idx vs vlmax_el (not
  truncated mux bits, so no fractional-LMUL aliasing); low-bit select == full index for
  legal indices; overlap/vstart/masked correct. (No .vx vd==rs1 rule needed — separate
  namespaces.)
- **Gemini — API quota-blocked** this round.
