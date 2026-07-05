# ADR-0055 — Zve32x Phase-B 整數核心補齊(架構確認)

- Status: **PROPOSED**(§2 架構確認;User 裁示 2026-07-05「開 Phase-B」)。ADR-0054 roadmap 之
  Phase-B。vexu.v RTL 改動;review 後才落。
- Date: 2026-07-05
- Mode: Fable 設計 + coverage inventory + Grok 複核(見附)。
- Relates: ADR-0054(roadmap)、ADR-0049(Phase-A S1-S4,同 vexu datapath/beats 機具)、ADR-0036。

---

## §1 Coral/spec 對照

Phase-B 補齊 Zve32x 的**通用整數核心**:bitwise、shift、reverse-sub、narrowing shift、
extension、carry/borrow、whole-register move。這些是任何 Zve32x 程式的基礎;現況缺(vexu 只有
TFLM 子集)。權威 = Spike lockstep `--isa=zve32x_zvl128b`。datapath 複用既有 per-SEW generate
loop(g_sew8/16/32 的 op_* mux),多數是「加 decode + 加 mux 項 + 進 known_op/beats_op」。

## §2 子片(照 Phase-A S1-S4 模式,便宜先,逐片 lockstep)

### B1 — bitwise + shift + vrsub(最便宜,同形 ALU)
純加 mux 項於 g_sew8/16/32(`r` 選擇鏈),shift amount = `b[SHW-1:0]`(SEW8→[2:0]/16→[3:0]/
32→[4:0];vi 的 sext(imm5) 低位=uimm5,統一)。皆 element-wise → 進 `beats_op`(m2/m4 群組)。

| op | f6 | forms | datapath |
|---|---|---|---|
| vand | 001001 | vv/vx/vi | `a & b` |
| vor | 001010 | vv/vx/vi | `a \| b` |
| vxor | 001011 | vv/vx/vi | `a ^ b` |
| vrsub | 000011 | vx/vi | `b - a`(reverse) |
| vsll | 100101 | vv/vx/vi | `a << b[SHW-1:0]` |
| vsrl | 101000 | vv/vx/vi | `a >> b[SHW-1:0]`(logical) |
| vsra | 101001 | vv/vx/vi | `as >>> b[SHW-1:0]`(arith) |

mask/tail 同 add(active = masked-off undisturbed);vstart≠0 arith 仍 illegal(現況一致)。

### B2 — narrowing shift + extension(複用既有寬/窄 datapath)
- **vnsrl(101100)/vnsra(101101)**(wv/wx/wi):2*SEW 源右移 → SEW 目標(取低 SEW 位)。**複用
  vnclip 的 wide→narrow 結構**,去掉 clip/round(vnclip 已在 S2)。narrowing → 非群組(≤m1,同
  vnclip 的 grp_only_illegal 規則)。
- **vzext/vsext.vf2/vf4**(OPMVV f6=010010,vs1 選變體:vf2=00110/00111、vf4=00100/00101):
  SEW/2 或 SEW/4 源零/符號延伸 → SEW。dst-only,非群組先做(m1)。
- SEW=8 時 vf4 非法(無 2-bit 源)、e8 的 nsr 需 wide=16;逐項 legality 對 Spike。

### B3 — carry/borrow(mask 當 carry 源/目標)
- **vadc(010000 vvm/vxm/vim)**:`a + b + v0[i]`;**vmadc(010001)**:carry-out → mask dest。
- **vsbc(010010)/vmsbc(010011)**:borrow 版。
- 注意:vadc/vsbc 用 mask 當 **carry-in**(非 predicate,vm=0 編碼但**所有 element 都算**);
  vmadc/vmsbc 寫 **mask register**(單暫存器,同 compare 的 mask-dest 路徑)。legality:vd 不得
  = v0(mask 源)於 vmadc/vmsbc 帶 mask 形。

### B4 — whole-register move(vmv1r/2r/4r/8r.v)
- OPIVI f6=100111,`simm` 欄編 NREG-1(0/1/3/7 → 1/2/4/8 reg)。複製 NREG 個 vector reg
  (vd..vd+N-1 = vs2..vs2+N-1),與 vl/vtype 無關(整暫存器)。用群組寫路徑(WB 多 part)或
  多-beat;vd/vs2 需 NREG 對齊。

## §3 契約(§2 第 2 問)

- **decode**:每 op 加 `wire op_X = (f6==...) && (form)`;`known_op` += 全部;`beats_op` += B1
  的 element-wise 項(B2 narrowing/ext 維持 ≤m1;B4 走自身群組)。
- **datapath**:B1 加 g_sew8/16/32 mux 項;B2 複用 nclip/widen 路徑;B3 加 carry 鏈 + mask-dest;
  B4 加 reg-group copy。
- **不動**:vector CSR 契約、mask/tail policy、EMUL/群組對齊守衛(既有,隨新 op 更新非法性)。

## §4 驗證計畫(§2 第 3 問)+ green-wash 守衛

- **權威 = Spike lockstep `--isa=zve32x_zvl128b`**(phase_22 harness)。每子片:
  - directed 網格:全 form(vv/vx/vi)× SEW(8/16/32)× LMUL(m1/m2/m4)× mask(vm/v0)× 邊界
    (vl=0/vstart/tail);shift 全 shamt(含 ≥SEW 的截斷)。
  - random 語料擴新 f6(gen_vector_random 加這些 op),多 seed。
- **green-wash 守衛**:①非法性(m8/群組對齊/widen-overlap/narrowing≤m1/vf4@e8/vmadc vd≠v0)
  必有 illegal-ladder directed ②不裂算術 ③新增 0 回歸(對 fail baseline diff)④lint clean。
- gate:gate_62(B1)... 逐子片一個 gate,或擴 gate_56/57 系列。

## §5 review 後才實作

accepted 後:Grok 複核(編碼/語意 hazard)→ Codex 外科實作(逐子片)→ 我跑 Spike lockstep
directed+random → commit。**逐子片把關,B1 證完才進 B2**(同 Phase-A 嚴格分片)。

## §6 實作結果

- **B1 完成(2026-07-05)**:vand/vor/vxor、vsll/vsrl/vsra、vrsub 加進 g_sew8/16/32 mux +
  known_op/beats_op。shift amount 取 `b[SHW-1:0]`。**bug 抓到並修**:vsra 的 `as >>> shamt` 在
  unsigned ternary context 被當**邏輯右移**(負數 sign 不延伸)——用自決定 signed 中間 wire
  `sra_r` 修(recurring Verilog gotcha,memory 已記)。**Spike lockstep `--isa=zve32x_zvl128b`
  118 commits 全符**(gate_62;全 form×SEW×LMUL m1/m2,含 shamt≥SEW 截斷、vsra sign edge)。
  既有 vector 測試(grid/s1/s2/s3/vrand)全綠無回歸。
  **三方 review(Codex/Gemini/Grok)抓到 118-commit lockstep 漏的一個真洞**:masked-body
  `vd==v0` 非法檢查漏 op_b1(masked vm=0 + vd=v0 dest 與 mask 源 v0 重疊,RVV §5.3 應 illegal;
  現有檢查涵蓋 add/sub/mm/s2same/nc 卻漏 B1)。**Codex 與 Gemini 獨立都抓到**(random 語料 vd≠0
  排除故漏,同 ADR-0049 S1 盲區)。修=`op_b1` 加進該檢查;firmware 加 illegal terminator
  (`vand.vv v0,v1,v2,v0.t`)——DUT+Spike 同點 trap illegal,lockstep **120 commits** 匹配(沒修
  會執行而分歧)。Grok 確認 B1 乾淨、給 B2 指引(narrowing 先,複用 vnclip bus + 2*SEW shift)。
  **測試基建修**:`-mno-relax` 加進 phase_22 firmware 編譯——`la`/data-table 位址在 DUT(base
  0x0)會被 relaxation 收成 `li`(絕對定址),Spike(base 0x8000_0000)不能 → instr 編碼分歧;
  `-mno-relax` 強制 PC-relative,兩邊一致。(這解鎖了 data-table + vse/lw 逐 element 驗證法。)
- **B2 __/ B3 __/ B4 __**（續）。

## 附:Grok 架構複核(2026-07-05,全文歸檔 docs/reviews/2026-07-05_phase_b_encoding_grok.md)

**B1 全對**(已 lockstep 驗)。**B2-B4 關鍵 flags(續做時務必遵守)**:
- **B2 narrowing shift amount = `log2(2*SEW)` 位(4/5/**6**),非 log2(SEW)**——源是 2*SEW,
  SEW=32 要 **6 位**;**不可複用 B1 的 SHW**(Spike-mismatch 風險)。
- **vzext/vsext = OPMVV(f3=010),f6=010010 與 vsbc(OPIVV)撞**——decode 必須以 f3 分,非只 f6。
  vext vs1 uimm 編碼:vf2=00110(z)/00111(s)、vf4=00100/00101、vf8=00010/00011。vext 無 vx/vi。
- **B2 narrowing/vext 的 EMUL/overlap**:dst EMUL = src/2(narrowing)或 ×2/×4(ext);Spike
  `require_noover` 對群組映射檢查 vd 不重疊源。「≤m1」只在 net dst EMUL=1 時套,LMUL=2→1 narrowing
  是 spec-legal,**別一律 blanket-illegal**。
- **B3 f6**:vadc 010000/vmadc 010001/vsbc 010010/vmsbc 010011,全 vvm/vxm/vim。vi 立即數:shift
  用 uimm5,但 vrsub/bitwise 的 vi 用 **sext(imm5)**(B1 已正確)。
- **B4**:OPIVI f6=100111,僅 vi。
