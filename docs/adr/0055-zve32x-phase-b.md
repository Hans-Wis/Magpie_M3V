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
- **B2 完成(2026-07-05)= narrowing + extension**:
  - **B2a**:vnsrl/vnsra(.wv/.wx/.wi)——複用 vnclip 寬 bus(g_nc8/g_nc16)去掉 round/clip,取
    (2*SEW 源 >> d) 低 SEW 位;d 沿用 vnclip 的 b[3:0]/b[4:0]=log2(2*SEW);vnsra 用自決定 signed
    wire。只 SEW8/16(SEW32 narrowing 需 64b 源,Zve32x 無)。
  - **B2b**:vzext/vsext.vf2/vf4——OPMVV f6=010010(f3 gate,與 OPIVV vsbc 不撞);vs1[2:1]=11/10
    選 vf2/vf4、[0]=sext;低 SEW/2 或 SEW/4 lane 零/符延伸;vf2 需 SEW≥16、vf4 需 SEW32、vf8 一律
    非法。res_ext 全暫存器填(元素數不變,異於 narrowing 的半填)。
  - **三方 review(Codex/Gemini/Grok,User 指定「一起完成 B2」)**:Codex 無 defect(7 項)、
    Gemini 全一致。**Grok 抓到真 gap:vext 缺 overlap 檢查**(vext 是 widening-class,vd 不得與
    narrower 源 vs2 重疊,require_noover;narrowing 的 vd==vs2 允許不適用)——**已修**
    `vext_illegal = op_vext && (vd_i==vs2_i)`;terminator 改 `vsext.vf2 v3,v3` 驗證(沒修會執行而
    Spike trap 分歧)。**主動套用 B1 教訓**:masked-vd0 檢查一開始就含 op_nsr/op_vext(Gemini 確認)。
  - **Spike lockstep `--isa=zve32x_zvl128b` 92 commits 全符**(gate_63);b1/grid/s2/vrand + NPU
    子系統全綠無回歸。
  - **記錄的 scope/latent(roadmap 續)**:①**vext/vnsr = dst m1-only**(grp_only_illegal;EMUL
    成長的 m2/m4 需 multi-beat,同既有 widening/narrowing ≤m1 限制,列 roadmap)②**`vle32@e32/mf2`
    (vlmax=2)DUT trap 為 illegal**——Grok/Gemini 皆判與 B2 無關的 latent vsetvli/vmem fractional-
    LMUL 議題,待與 Spike 並跑確認(可能真 bug)。
- **B3 完成(2026-07-05)= carry/borrow(vadc/vsbc/vmadc/vmsbc)**:
  - **Grok spec 存 `docs/reviews/2026-07-05_phase_b3_carry_spec_grok.md`**(§1-§7:encoding/datapath/
    active-policy/legality/beats_op/hookup/golden),照它實作。
  - **arithmetic 路(vadc/vsbc → 向量 vd)**:併入 per-SEW `r` ternary(`op_adc:a+b+m` /
    `op_sbc:a-b-m`,m=`v0_view[gi]`=carry-in 1 位);`op_adcsbc` 加進 `active`(force-active,
    v0 是 carry **操作元非 predicate**,同 vmerge 精神,全 body element 都算/寫);加進 `beats_op`
    → m2/m4 群組經既有 part_res/grp_stage 自動多拍。
  - **mask 路(vmadc/vmsbc → mask vd)**:新增 g_madc8/16/32 產 SEW+1 寬 carry/borrow-out
    (`sum[SEW]`=carry、`dif[SEW]`=borrow=`a<b+bin` 無號,**非** signed underflow);cin=`vm?0:v0[i]`。
    以 `mask_dest = op_cmp || op_madcb` **泛化既有 compare mask-write 路**(res_cmp/cmp_seg/
    grp_mask_acc/grp_cmp_res/q_grp_w/grp_align 全改用 mask_dest)→ 複用 compare 的單暫存器目標 +
    m2/m4 mask 累積,零新 FSM。
  - **legality(spec §4 完整)**:`op_adcsbc && (vm||vd==0)` 非法(vm=1 保留非法;vd==0 撞 carry
    源 v0);`op_madcb && !vm && vd==0` 非法(僅 carry-in 形讀 v0 才撞,vm=1 寫 mask 到 v0 合法);
    vsbc/vmsbc decode 排除 is_opivi → 無立即數形自動非法;vstart≠0 沿用全域 known_op 規則。
    f6 010010(vsbc)與 OPMVV vzext/vsext 靠 f3 分離(disjoint)。
  - **Spike lockstep `--isa=rv32imf_zve32x_zvl128b` 178 commits 全符**:firmware_b3.S 覆蓋
    e8/e16/e32×m1 全形式(vvm/vxm/vim/vv/vx/vi)+ carry/borrow 邊界(a+b+cin=2^SEW、a<b+bin)+
    vmadc/vmsbc 兩形(vm=0 vd≠0 / vm=1 vd==v0 合法)+ **e8/m2 群組 smoke**(splat 源 + self-compare
    carry mask,驗 beats_op 群組路);terminator = `vadc.vvm v0,..`(vd==0)DUT+Spike 同點 trap。
  - **回歸全綠**:b1/b2/s1/s2/s3/grid/vill/vrand(**1324 commits**)+ NPU 子系統無回歸。
  - **三方 review**:Grok spec(arch)+ lockstep(authority)+ **Gemini 全上下文一致性 review 判
    completely clean**(legality matrix / SEW+1 carry-borrow / f3 disjoint / mask multi-beat 四維皆
    conformant,無 gap)。有別 B1/B2 各被抓一 legality gap,B3 從 spec 一次到位(主動套用 masked-vd0
    教訓 + Grok spec 已含完整 §4 matrix)。
- **B4 完成(2026-07-05,ADR-0055)= whole-register move vmv1r/2r/4r/8r.v**:OPIVI f6=100111 vm=1,
  simm5(vs1 欄)=nr-1,合法 {0,1,3,7}→nr{1,2,4,8};複製 nr 個**整暫存器** vd+p←vs2+p,**與 vtype
  (LMUL/SEW/vl)無關**。
  - **實作(自有 copy loop,非 beats_op)**:nr=8 複製 8 暫存器超出既有 4-part group staging,故 vmvr
    走**自有 FSM state VM_VMVR**——一暫存器/拍,直接寫進**唯一** VRF 寫 always-block;`q_is_grp=1` 令
    core hold、`q_vrf_we=0`/`q_grp_w=0` 令 WB port 不寫。nr-對齊群組 equal-or-disjoint→src≠dst 無 hazard;
    drained-start→copy 期間 w_en 不指向任何 VRF entry(單一寫者不破)。vm_state [1:0]→[2:0](加 VM_VMVR=4)。
  - **legality(**5 條全 Spike 實跑確認**,推翻 Grok 一條)**:①`vstart≠0`→**illegal**(Spike 實跑=trap
    **非** Grok §149-152 預言的 partial-copy;既有全域 known_op vstart 規則已匹配,**免 carve-out**——
    §4「先量再信」擋掉一次 wrong-path)②`vill`→illegal(cfg_illegal)③**m8 vtype→合法執行**(vmvr 忽略
    LMUL;故 cfg_illegal 的 lmul_m8 對 vmvr 豁免、grp_only_illegal 也豁免 op_vmvr)④bad simm(∉{0,1,3,7})
    →illegal ⑤vd/vs2 非 nr-對齊→illegal(amask=nr-1)。
  - **Spike lockstep --isa=rv32imf_zve32x_zvl128b 77 commits**:四 nr 全驗(vse32+lw 逐暫存器)+ **over-copy
    guard**(v24 sentinel 須存活過 vmv8r)+ **vtype 獨立性**(vmv1r 於 m8 vtype 執行)+ 非對齊 vmv2r illegal
    terminator。回歸 13 vector targets 全綠(含 vmem/s3/vrand 1324)。gate_65。
  - **三方**:Grok flags(arch)+ 我 Spike 實跑(authority,推翻 vstart flag)+ **Gemini 全上下文 3 findings**:
    F1(VM_VMVR 寫未 !m_stall gate→**採納**,idempotent 非正確性 bug 但省功耗+與 FSM 一致)、F2(BRAM/多驅動
    →**駁回**,VRF 本就是 group-commit 4-address/拍 的多寫 flop array,無法單埠化,前提不成立)、F3(nr==0 FSM
    hang→**採納防禦**,實際不可達因 illegal 擋入口,改 `>=` 退出零成本)。

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
