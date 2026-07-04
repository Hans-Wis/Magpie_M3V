# ADR-0044 — 列 4:ITCM 8KB / DTCM 32KB Harvard 分割 + banked DTCM(收斂 ADR-0040 Class B)

- Status: **ACCEPTED**(§2 架構確認;User 裁示 2026-07-04「列 4 記憶體 sizing」)。
  Mode:PL design + Grok pre-critique(採納於下)+ Codex post-review(**CLEAN**,2 殘留註記)。
- Date: 2026-07-04
- Relates: ADR-0040(2×256b 埠假設,本 ADR 收斂)、ADR-0034(core-in-socket)、ADR-0043(0x680)。

## Coral 對照(§2 第 1 問)

Coral row 4:**ITCM 8KB / DTCM 32KB、single-cycle SRAM、128-bit 埠**。我們此前是 4KB 單體
TCM +「flat array 魔法讀」。本 ADR:容量對齊(8K/32K)、Harvard 分割、把 ADR-0040 的頻寬
假設變成**受檢查的結構契約**。**對等表述(Grok (c) 採納)**:功能對等 = 容量 + 足以支撐
256 MAC/cycle 的持續頻寬(✓ 實測);**物理埠規格偏離**——Coral 是單一 128-bit 埠,我們是
8×32b 2R1W bank 聚合(可超過單 128b 埠峰值)——顯式記錄,SRAM macro 對映歸 Phase 7。

## 契約(§2 第 2 問)

1. **Harvard 最小漣漪分割**:既有 TCM 就地升格為 **DTCM 32KB**(所有 data 位址、firmware
   指標、CQ descriptor 常數、weight 區 0x680 全部不動);新增 **ITCM 8KB** 專供取指。
   Host 窗:0x3000 CSR / 0x3001 DTCM / **0x3002 ITCM(新)** / 0x3003+ decode err
   (adversarial 期望隨遷)。
2. **鏡像載入契約(Grok (a) 採納)**:同一 firmware image 載入**兩個**記憶體——所有
   load-visible bytes(rodata/literal pools 含)以相同位移存在於 DTCM,與 Spike 平面記憶體
   視角一致;lockstep 免改。**記錄限制**:store 不改變取指流(自修改碼會與 Spike 分歧;
   random 產生器不生成)、fetch 超過 8KB 靜默 wrap、DMA 超過 DTCM 容量 wrap(descriptor
   sanitizer 已擋合法路徑;Codex 殘留註記)。
3. **Banked DTCM 結構模型**:8-way word-interleave(bank = word_addr[2:0]),預算
   **每 bank 每拍 ≤2R + 1W**。ADR-0040 的 32B 對齊契約在此成為 load-bearing:對齊的引擎
   256b 窗恰好每 bank 一讀,雙窗 = 恰好 2R。**sim checker** 對每個帶 enable 的讀(引擎窗
   strobes、DMA、core-D、host AR)逐拍逐 bank 計數,超額即計 violation。
4. **寫埠**:既有單寫優先權(dma>eng>core>host)= ≤1W ✓ 不變。

## 驗證計畫(§2 第 3 問)+ 結果

- **gate_52**:容量邊界(末字 OK/越界 SLVERR/0x3003 err)、Harvard 隔離(同位移獨立值、
  D 寫不動取指影像)、**checker 靈敏度**(force 雙窗 + host 輪詢 → 必須 fire——Grok (b)
  的 green-wash 守衛:checker 不是裝飾)、RTL 參數斷言(8192/2048,防靜默縮水)。
- **gate_46 增斷言**:真 CQ 矩陣 batch 全程 **bank violations == 0**(併發證據在真 workload
  上取得,非序列化迴避)。
- **既有全鏈在 32KB/banked 上重綠**:lockstep(gate_31/32 directed+random)、CQ、矩陣、
  TFLM MLP/CNN、traps/abort、strided——全套 0 新增失敗。漣漪:17 個 TB(鏡像雙載、程式
  改走 0x3002、commit-trace 讀 ITCM、參數 8192/13)、DMA 位址鏈加寬(BUF_AW=TCM_AW)。
- Codex review:**CLEAN**;殘留(fetch wrap、DMA 容量 wrap)= 上述記錄限制。

## 結果

**§3 列 4 轉綠(容量/結構)**:ITCM 8KB + DTCM 32KB + 受檢查的 banked 頻寬契約;殘餘
(SRAM macro、物理埠寬、真 flush)= Phase 7 PPA/signoff。ADR-0040 Class B 從「文件假設」
變成「逐拍檢查的結構預算 + 真 workload 零違規證據」。
