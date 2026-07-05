# ADR-0053 — S_RSC requant 流水化(架構確認)

- Status: **ACCEPTED**(§2 架構確認 + 實作驗證完成 2026-07-05;User 裁示「step 3:S_RSC requant 流水」)。
  mat_engine.v RTL 改動,已實作驗證(§6)。
- Date: 2026-07-05
- Mode: Fable 設計 + Grok 架構複核(見附)+ 我方獨立分析。
- Relates: **ADR-0051 §2.5**(DC 量測:requant 是 mat_engine critical path,64 level 1.25ns,
  S_RUN MAC 較快掉出 worst-30)、ADR-0037/0040/0042(mat_engine / requant datapath)。

---

## §1 Coral 對照(§2 第 1 問)

Coral Kelvin 的 requant(TFLite gemmlowp SRDHM + RoundingDivideByPOT)在其 datapath 內是
管線化的定點運算。我們的 mat_engine 目前把整條 requant(32×32 乘 + SRDHM + RDBPOT + clamp)
做在**單一組合拍**(一 element/cycle)——DC 實測這就是 mat_engine 的 critical path。本 ADR 把它
切成多拍/流水,讓 requant 不再是 Fmax 限制,對齊 Coral「requant 不在關鍵路徑」的時序形狀。
**功能語義完全不變**(同一 gemmlowp 位元精確運算),只改「何時算完」。

## §2 現況(DC 量測事實)

DC+TSMC28(ADR-0051 §2.5):1.2ns 積極時脈下 **30/30 worst path 終點 = pack_q_reg**
(requant),64 logic level,cell 鏈是 32×32 乘法器 partial-product tree;S_RUN 的 256-MAC
累加**掉出 worst-30**(較快)。∴ requant 是**唯一**關鍵路徑,切它可提 Fmax。

requant 組合鏈(mat_engine.v:112-135):
`acc_el * cur_mult`(**32×32→64b,最深**)→ nudge/s_sum/q_tz(SRDHM)→ t32 → rmask/remv/
thr/q_pot(RoundingDivideByPOT,變數右移)→ withzp → clamp → out8。
FSM(byte-serial):`S_RSC`(pack 1 byte/cycle,el_i 0..63)→ 每 4 element 進 `S_RSW` 寫 32b 字
(16 字)→ `S_FIN`。

## §3 契約(§2 第 2 問)—— 切點 + FSM + bit-exact

**切點:32×32 乘法後**(`ab` 是最深子路徑)。stage-1 = 乘法 + 選 per-element 控制;stage-2 =
SRDHM + RDBPOT + clamp + pack。

**必須進 pipeline register 的 el_i-相依項(關鍵——否則 stage-2 用到已前進的 el_i 會錯)**:
- `rq_ab[63:0]` = `acc_el * cur_mult`(stage-1;acc 於 rescale 期間不被寫,acc_el 穩定)
- `rq_sat` = `(acc_el==0x8000_0000)&&(cur_mult==0x8000_0000)`(需 stage-1 的 acc_el/cur_mult)
- `rq_exp[5:0]` = `cur_shift[5:0]-31`(per-channel cur_shift 由 el_i[2:0] 選 → **必須 stage-1 捕獲**)
- (rs_zp/rs_min/rs_max 為 per-tensor CSR,rescale 期間常數 → **不需** pipeline)

**方案定案:真流水 + inline word-write(移除 S_RSW bubble)**。
> 更正:原以為多拍化(2×拍/element)throughput 可忽略——**錯**。small-K 層 requant 是 throughput
> 瓶頸(K=64:MAC ~16 拍 vs rescale 80 拍)。∴ 走真流水(+1 拍非 +64)。Grok 定案:cut after
> `ab`(乘法後,最深),register `rq_ab[63:0]`/`rq_sat`/`rq_exp[5:0]`/`rq_v`;**不** cut after
> s_sum/q_tz(會把乘法與更多邏輯串一起)。

**dual counter FSM(inline write,無 S_RSW bubble)**:
- `el_iss`(stage-1 索引 0..63)、`el_pack`(= el_iss 延遲 1 拍,stage-2 pack/write 索引)、`rq_v`
  (stage-2 valid;首拍 bubble=0)。
- 每 S_RSC 拍:stage-1 從 `el_iss` 算 `ab/sat/exp_r` → 存 `rq_*`;stage-2(若 rq_v)從 `rq_*` 算
  `out8` → `pack_q<={out8,pack_q[31:8]}`;**當 `el_pack[1:0]==3` inline 寫字**(`t_we<=1`,
  `t_waddr<=out_base_word + el_pack[5:2]`,`t_wdata<=pack_next`——注意用 el_pack[5:2] 直接得字
  索引,無需舊碼的 -1)。`el_pack<=el_iss`;`el_iss` 到 63 後 hold。
- **cycle 時序(66 拍 vs 原 80)**:cycle0 fill(rq_v=0 無 pack)、cycle1..63 pack elem0..62、
  cycle64 drain pack elem63 + 寫 word15 → S_FIN、cycle65 `done<=1`(trail 末寫 1 拍,保「done=
  outputs visible」= gate_45 抓 stale 之守衛)。**移除 16 個 S_RSW 寫 bubble → 反而快 14 拍**。
- **el_i-相依項全捕獲於 stage-1(Grok hazard 表)**:`cur_mult`(mult_c[el_i[2:0]])、`cur_shift`
  (shift_c[el_i[2:0]])、`acc_el`(acc[bank_q][el_i])→ 只在 stage-1 消費入 rq_*;**stage-2 嚴禁**
  用 el_i 重選 mult_c/shift_c/acc(silent bit-corruption)。pack 位置用 `el_pack[1:0]`、寫址用
  `el_pack[5:2]`。rs_zp/min/max = per-tensor CSR,rescale 期間常數 → 不需 pipeline。

**bit-exact**:requant 純 feed-forward(無 loop-carry;acc 於 rescale 不變),`out8[k]=g(acc[k],
mult[k],shift[k],zp,min,max)` 不變,只延遲 1 拍且 `el_pack=el_iss-1` 保 pack 位置與寫址對映 →
輸出 byte 逐位等同今日。權威 = mat_golden.py。SRDHM/RDBPOT 公式一字不改,只加 register 邊界。

## §4 驗證計畫(§2 第 3 問)+ green-wash 守衛

- **bit-exact 硬門檻**:gate_45(mat_engine golden,1629 checks)、gate_46(CQ 矩陣 e2e 逐位)、
  gate_48/49/50(TFLM FC/MLP/CNN 逐位)—— 一位不符即退。
- **Fmax 重量測(核心證據)**:改後重跑 `flow/dc_tsmc28`(1.2ns),確認 **worst path 不再是 requant**
  (pack_q 掉出或 slack 改善),記錄新 Fmax + 新 critical path 端點。**不得只宣稱變快不出 DC 數字**。
- **throughput**:requant 拍數 +（方案 A ~×1.8 / 方案 B +1 drain）——記錄,確認矩陣 e2e 仍過
  throughput gate(若有)。
- **lint**:mat_engine 改後必重跑 Verilator lint(3D 教訓:RTL 改動後必 lint)。
- green-wash:**不裂算術**(SRDHM/RDBPOT 公式一字不改,只加 register 邊界);gate_52 memory 不受影響。

## §5 review 後才實作(§2 第 4 問)

accepted 後:Codex 外科實作(方案定案)→ 我跑 gate_45/46/48/49/50 bit-exact + Verilator lint
→ 重跑 DC 確認 critical path 移動 + 新 Fmax → Codex review diff → commit。**沒有 DC 證據不宣稱 Fmax 提升。**

---

## §6 實作結果(2026-07-05)

- **RTL**:mat_engine.v combinational 拆 stage-1(`ab/sat_s1/exp_s1` from `el_iss`)/ stage-2
  (`nudge..out8` from `rq_ab/rq_sat/rq_exp`);S_RSC 改串流流水 + inline word-write,退休 S_RSW
  (localparam 移除)。新 reg:`el_iss/el_pack/rq_v/rq_ab/rq_sat/rq_exp`。
- **bit-exact(全綠)**:gate_45(mat_golden **1629 checks** 含 last-word-stale 守衛)+ gate_46
  (CQ 矩陣 e2e)+ gate_48/49/50(TFLM FC/MLP/CNN)——輸出逐位等同,零 golden 改動。
- **lint**:Verilator clean(僅 pre-existing UNUSEDSIGNAL;新 S_RSW UNUSEDPARAM 已移除)。
- **throughput bonus**:移除 16 個 S_RSW 寫 bubble → rescale **80→66 拍**(反而快 14 拍)+ 流水化。
- **Fmax(DC 重量測,Synopsys DC + TSMC28,reports/dc_mat_pipe)= 決定性**:
  | | 改前 monolithic | 改後 流水化 |
  |---|---|---|
  | 1.2ns slack | **−0.17 VIOLATED** | **0.00 MET,0 違規** |
  | critical path | 1.25ns / 64 level | **1.03ns / 30 level** |
  | worst 30 path 終點 | 30/30 **pack_q(requant)** | 26/30 **acc_reg(MAC)**、4/30 rq_ab(隔離 32×32 乘)、**0 pack_q** |
  **requant 完全移離 critical path**(pack_q 30/30→0/30),且達標 1.2ns(改前違規)。新瓶頸轉到
  **S_RUN MAC 累加**(如 Grok 預測),= step 4 候選(目前 standby)。
  **1.0ns 精確上限(reports/dc_mat_pipe_1p0)**:**達標 1.0ns,slack 0,0 違規**,critical path
  0.88ns / 29 level,29/30 worst = acc_reg(MAC)、1 = rq_ab。∴ **mat_engine Fmax:~730MHz →
  ~1.0 GHz(+37%)**;requant 徹底不再是限制,MAC 成為 ~1.0GHz 的新天花板。
- **Codex review**:**No suspected defects found**——六 focus 全 clean(stage-2 不用 el_iss 重選、
  位址 out_base+0..15、pack byte 序、fill/drain 保 done trail、兩 entry 路徑 init el_iss/rq_v、
  無 width/signedness 問題)。

## 附:Grok 架構複核(2026-07-05,全文歸檔 docs/reviews/2026-07-05_requant_pipeline_grok.md)

**收斂**:①cut after `ab`(乘法後,最深子路徑),register `rq_ab/rq_sat/rq_exp/rq_v`;**不**
cut after s_sum/q_tz(會把乘法串更多邏輯)②dual counter `el_iss`/`el_pack`(延遲 1),+1 fill
bubble +1 drain ③hazard:`cur_mult/cur_shift/acc_el` 只在 stage-1 消費,stage-2 嚴禁用 el_iss
重選(silent bit-corruption)④bit-exact by construction(feed-forward,acc 於 rescale 不變)
⑤**不要**同時流水 S_RUN(DC 證 MAC 較快;有 acc loop-carry 風險)。**我方變體(採納)**:inline
word-write 移除 S_RSW bubble(Grok cycle 表本就 65 拍無 bubble,與其 FSM snippet 的 S_RSW 略有
不一致;inline 版更乾淨且更快)。
