# ADR-0047 — 列 6 殘項:hard reset(與 soft abort 的明確區分)

- Status: **ACCEPTED**(§2 架構確認;功能補齊路線圖順位 1)。Mode:PL design + Grok
  pre-critique + Codex post-review。
- Date: 2026-07-04
- Relates: ADR-0038(soft abort:證據持久)、ADR-0044(記憶體;內容持久語義)。

## Coral 對照(§2 第 1 問)

Kelvin 的控制暫存器 reset 比「完成當前 burst 後停住」更廣——是把 device 邏輯帶回
power-on。ADR-0038 記錄的殘項正是 hard/soft 區分:**soft(CTRL[2])= 復原導向**(fault
證據持久、ring/config 保留,host ack 後續跑);**hard(CTRL[4])= 掃除導向**(登記器面
全部歸 power-on,像重新上電,只有 SRAM 內容留下)。

## 契約(§2 第 2 問)

1. `CTRL[4]` momentary。寫入先在 AXI 上正常完成(bvalid),同時觸發**既有 soft-abort
   機構**(start 清、GO 鎖、DMA burst-邊界 drain、mat 即停)。
2. npu_top 層 FSM latch `hard_pending`;待 `engines_quiet` **且 host 無 in-flight AXI
   交易**(w_busy/r_busy idle)後,打 **2 拍內部 domain reset**:npu_axil_regs 全暫存器
   (ERR_CAUSE/ERR_PC、RING_BASE/SIZE/HEAD/TAIL、CQ_CTRL/cq_err、DMA/WB/MAT config、
   IRQ pending、CTRL 本身)+ npu_dma + mat_engine 歸 power-on。core 維持停(start=0)。
3. `STATUS[9] = hard_resetting`(drain + reset 窗全程);reset 窗內 host 讀在 arready
   上自然等待(bus-idle 前置條件保證無交易被吞)。完成判準:STATUS==0 且 ERR_CAUSE==0。
4. **ITCM/DTCM 內容持久**(SRAM 語義;host 想清資料自己重載)。IRQ 線在 reset 中強制 0
   (無毛刺)。
5. 與 soft 的可觀測區分 = DV 的核心斷言:同一 fault,soft 後證據在、hard 後全清。

## 驗證計畫(§2 第 3 問)

gate_54(tb_npu_hard_reset):S1 fault→**soft**→證據持久(基準對照);S2 同 fault→
**hard**→ERR_CAUSE/ERR_PC/ring/CTRL/STATUS 全零、IRQ 低、DTCM marker 持久;S3 4096-beat
DMA 中途 hard→AXI 乾淨(quiesce 後零 AR)才 reset;S4 冷重啟:重設 ring、跑完整矩陣
batch 到 DONE(power-on 等價);double-hard / soft 進行中疊 hard 的冪等性。

## 結果 + review 處置

gate_54 全綠(18 checks):soft-vs-hard 證據區分、mid-4096-beat drain 後零 AR、double-hard
冪等、冷重啟完整 batch + 無假 IRQ、DTCM marker 持久。實作時抓到 **CTRL bit 碰撞**(bit3 已是
irq_enable → hard 移至 **CTRL[4]**,DV 抓的)。Grok 採納:freeze 防輪詢餓死、IRQ 無毛刺、
IMEM 持久列為對 Coral 的有意偏離。**Codex 4 發現全修**:①freeze 未蓋 2 拍 reset 窗(交易
可在 regs 失聰時握手)→ freeze 併入 `hard_rst_cnt≠0`;②只遮 ready 造成 target 側 ghost
接受 → **valid+ready 兩側同遮**;③AW 已收、W 被凍 → 死鎖 → `w_ok = ~freeze | w_busy`
(在途寫放行);④soft 路徑復用使 quiesce 在 reset 前先 latch ABORTED → ERR IRQ 對外毛刺
→ `hard_q` 抑制證據 latch 與 irq 輸出(由 domain reset 自然清除)。
