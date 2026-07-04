# ADR-0043 — 列 5 卸載收尾:strided/2D DMA + host ring-producer ABI + flush-before-doorbell

- Status: **ACCEPTED**(§2 架構確認;User 裁示 2026-07-04「進行 1+2」之 2)。
- Date: 2026-07-04
- Relates: ADR-0033(writeback DMA)、ADR-0035(CQ ring/FULL advisory)、ADR-0038(fault ABI)。

## Coral 對照(§2 第 1 問)

Coral 的卸載迴圈支援張量切片搬運(非連續 2D 存取)與 host 端 ring 生產者紀律(overrun 由
軟體契約防範,device 只提供 head/tail 可見性)。快取一致性由 host 驅動(提交 buffer 前
flush)。我們對等:**2D/strided 交給 sequencer firmware 迴圈**(descriptor 驅動、RTL 零改動
——Coral 的 scalar 核同樣是搬運編排者)、**producer ABI 落成 host 函式庫**(FULL 檢查 +
doorbell 前 fence hook)、flush 契約文件化(現行 DV host=TB 無快取;SoC 整合屬 Phase 7)。

## 契約(§2 第 2 問)

1. **MAT.LOAD_W W2 = src row stride(bytes,0=連續)**:W2≠0 時 firmware 逐 row
   `dma_read(src + r·stride, dst + r·cols, cols)`(rows/cols 沿用 W3);stride ≥ cols·4、
   4B 對齊,違者 MAT_PARAM;wrap-safe 邊界檢查。dst 仍固定 TCM 0x600 起連續(im2col/
   權重切片的 gather 語義)。
2. **MAT.STORE W3[31:16] = dst row stride(words,0=連續)**:scatter 寫回
   `dma_writeback(src + r·cols, dst + r·stride·4, cols)`——輸出 tile 落進更大張量的切片。
3. **Host producer ABI(`IP/npu/sw/host/cq_host.py`)**:`CqProducer.push(descs)` 先讀
   CQ_STATUS.FULL / HEAD-TAIL 空間,不足即拒絕(RING_OVERRUN 由生產者紀律防範——與
   ADR-0035 一致,device 端偵測維持 deferred);`commit()` 執行 **fence hook →(SoC:cache
   flush)→ TAIL doorbell** 順序。DV 中 fence = no-op 佔位,契約寫入 `00_isa_contract.md`。

## 驗證計畫(§2 第 3 問)

gate_51:(a) TB 於 shared 擺 stride 布局的 2D 塊 → LOAD_W(stride) → MAT.STORE 讀回比對
(gather 正確);(b) STORE(stride) scatter 寫回 → TB 驗證非連續落點與間隙不觸碰;
(c) stride 違規(< cols·4 / 未對齊 / wrap)→ MAT_PARAM;(d) `cq_host.py` 單元測試:FULL
拒絕、空間計算(wrap)、fence-before-doorbell 順序斷言。既有 CQ gates 全綠(W2=0 路徑不變)。

## 結果 + Codex review 處置(3 發現)

gate_51 六測項全綠:2D gather(逐字比對)、scatter(落點 + 間隙 sentinel)、sanitizer 階梯
(對齊/短 stride/**容量 544 words**/**位址 wrap**→MAT_PARAM,後兩者為 Codex #3/#2 修復,對
修前 firmware 必失敗)、producer ABI(CqFull 拒絕、wrap 空間計算、fence-before-doorbell 順序
斷言)、**codec scatter 編碼 round-trip(Codex #1:generator 補 dst_stride_words/src_tcm_byte
/src_row_stride_bytes 欄位)**、firmware footprint 守衛(text+bss ≤ 0x680——本輪真實 near-miss:
strided 程式碼使 text+bss 1552B 越過 0x600 權重區,權重區遷 0x680 並以 gate 鎖住)。
TB C 階梯學到:ERR 後 HEAD 凍結,後續 case 須改寫同一 slot(gate_38 模式)。
