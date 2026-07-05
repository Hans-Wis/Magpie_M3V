# ADR-0052 — CQ autonomous MAT_OP:批次預取消軟體序列化稅(架構確認)

- Status: **ACCEPTED**(§2 架構確認 + 實作驗證完成 2026-07-05;User 裁示「走新 step 2」+「移 weight region 0x680→0x700」)。
  實作=firmware(`cq_sequencer.c`)+ **User 核准的 memory-map bump**(weight 0x680→0x700,§6);不動 RTL、不動 SSOT。
- Date: 2026-07-05
- Mode: Fable 設計 + Grok 架構複核(見附)+ 我方獨立分析。
- Relates: ADR-0035(command queue)、ADR-0037/0039/0042(matrix 命令)、ADR-0043(producer ABI)、
  **ADR-0051 §2.5**(DC 量測:mat_engine ~730MHz 非瓶頸 → 真 ROI 在此軟體路徑)。

---

## §1 Coral 對照(§2 第 1 問)

Coral 的 IREE runtime 以低開銷 command stream 卸載,doorbell 驅動。我們的 sequencer(stripped
NPU core)**每個 descriptor 都用一次完整 DMA round-trip 從 shared-mem ring @0x8000 抓進 TCM
scratch 再解碼**——這是單發核逐 descriptor 的序列化稅。autonomous MAT_OP = **批次預取
descriptor**,把 fetch 成本攤掉,逼近 Coral 的低開銷 streaming,而**不複製 Coral 的硬體 VCQ**
(§4 規則 + Grok 早先裁定:不做硬體 VCQ)。

---

## §2 現況瓶頸(事實,讀碼所得)

`cq_sequencer.c` 主迴圈,**每個 descriptor**:
1. poll `CQ_HEAD`/`CQ_TAIL`(2 CSR 讀)
2. 寫 `CQ_EVENT=BUSY`
3. 讀 `CQ_RING_BASE`/`CQ_RING_SIZE`(2 CSR 讀,**loop-invariant 卻每輪重讀**)
4. **`dma_read(ring_base+head*16, scratch, 4 words)`:4 CSR 寫(SRC/DST/LEN/GO)+ `wait_dma_done`
   輪詢 + DMA burst —— 每個 16-byte descriptor 一次 DMA round-trip。**這是主導稅。**
5. 讀 w0..w3、解碼、dispatch
6. MAT_OP:2 CSR 寫(A/B)+ `mat_run`(1 CSR 寫 CTRL + 輪詢 STATUS)
7. HEAD 前進

一個 TFLM 層 = descriptor 串(CFG→ACC_CLR→OP×tiles→RESCALE→STORE),**每個都付 step-4 的
DMA-fetch+poll**。NPU core 無法直接 load 0x8000(host/shared AXI 空間),只能經 DMA 複製到 TCM
——這是 per-descriptor DMA 的根因。**step-4(fetch)成本 ≫ step-6(每 op 3 CSR 寫)**:fetch 是
4 CSR 寫 + DMA + 輪詢 ≈ 數十拍;3 CSR 寫 ≈ 個位數拍。∴ **主攻 fetch,批次化。**

**Grok 量化(採納)**:fetch 開銷對 compute-heavy 層 ≈ **2-5×** engine-issue 開銷,對 metadata
descriptor(CFG/ACC_CLR/RESCALE/STORE/FENCE)≈ **10-50×**(step-6 幾乎為零,fetch 佔近 100% wall
time)。一個 64-tile 層(68 ring entry)光 fetch ≈ **6,800-10,000+** 固定拍。「sequencer 在當
16-byte 包裹快遞員,花在搬信封的時間多過驅動引擎」。

---

## §3 契約:批次預取(§2 第 2 問)—— 純 firmware,engine 命令流逐位不變

**核心不變量:mat_engine + DMA 執行的命令序列逐位等同今日**(mat_golden.py 權威;gate_37
等價明文允許「CQ transport may add descriptor fetches」)。

```c
// 迴圈外一次(loop-invariant,次要win 4a):
ring_base = CQ_RING_BASE; ring_size = CQ_RING_SIZE;
if (ring_base & 0xF) cq_halt(DESC_ALIGN);

static cq_desc_t batch[BATCH_N];        // @scratch 0xF00, BATCH_N=8 (128B;良好 AXI burst)
                                        // Grok:N=8 甜蜜點,engine/op 時間常超過 8-desc fetch 節省;
                                        // N=16 可行但遞減報酬。編譯期常數,gate 可 A/B。

for (;;) {
  head = CQ_HEAD; tail = CQ_TAIL;
  if (head == tail) continue;
  pending = (tail - head) & (ring_size - 1);
  to_wrap = ring_size - head;            // 單次連續 DMA 只到環繞邊界
  n = min3(pending, to_wrap, BATCH_N);
  CQ_EVENT = BUSY;
  dma_read(ring_base + head*16, batch_scratch_w, n*4);   // 一次 DMA 抓 n 個 descriptor
  for (i = 0; i < n; i++) {
    decode+dispatch(batch[i]);           // 與今日逐 descriptor 完全相同(含 FENCE/IRQ/LAST/ERR)
    head = (head + 1) & (ring_size - 1);
    CQ_HEAD = head;                      // HEAD 仍逐 descriptor 前進(host 進度視角不變)
  }
}
```

**保序/正確性(逐項對今日等價)**:
- **wrap**:單次 DMA 只抓到 `ring_size - head` 邊界;環繞段下輪處理 → 維持連續-DMA 假設。
- **TAIL re-poll**:每輪頂重讀 tail;中途 producer 新增的 descriptor 下輪拾取。只處理快照時已
  commit 的 [head, head+n)(producer fence-before-doorbell 保證 commit 完整)→ 無 torn read。
- **HEAD 逐 descriptor 前進**:host 看到的 HEAD 進度與今日逐筆相同;批次中途 cq_halt 時 HEAD
  精確反映已完成數(同今日)。host 依 HEAD 回收 ring slot;本地已有副本,host 覆寫已消費 slot 無害。
- **FENCE/IRQ/LAST/ERR**:`cq_w0_fence/irq/last`、`cq_halt` 逐 descriptor 呼叫,順序不變。
- **RING_OVERRUN**:host 端 producer 紀律,不變。

**成本**:descriptor-fetch DMA 由「每 descriptor 1 次」降為「每 batch 1 次」→ 一個 ~5-8 descriptor
的層鏈由 5-8 次 fetch round-trip 降為 1 次。step-6 的 3 CSR 寫維持(佔比小)。

**掃到的次要 win**:4a(ring config 迴圈外讀)採納;4b(issue/poll overlap)、4c(硬體 command
FIFO)= **RTL,scope-creep,defer**(Grok 早先:engine 側 double-buffer 對同 bank 累加無 win)。

---

## §4 驗證計畫(§2 第 3 問)+ green-wash 守衛

**等價的正確定義(Grok E1/E2/E3 框定,採納)**——批次預取「刻意」改變 descriptor-fetch DMA,
但不動 engine 命令流。等價契約必須停止把「快遞行程」與「計算命令」混為一談:
- **E1(權威)engine-command-stream 等價**:CQ 批次路徑 vs 直接-CSR 路徑 → `mat_engine` CSR 交易
  序列(opcode/operand/順序)逐筆相同。權威 = mat_golden.py + gate_46/48/49/50。
- **E2 per-descriptor 語義等價**:HEAD 逐 descriptor 前進的節奏、FENCE/IRQ/LAST/ERR 行為、ERR
  halt 點、LAST mailbox —— 全同今日。
- **E3 descriptor-fetch DMA(刻意不等價,informational)**:shared-mem 讀 burst 數/大小刻意變少變大;
  記為優化 metric(burst 數 ↓、總 bytes =),**不 fail**。

| gate | 驗什麼(E 對應) | 動作 |
|---|---|---|
| **gate_46** cq_matrix_e2e | E1:輸出 tile **逐位** vs mat_golden.py | 應原樣綠(engine 流不變);**bit-exact 硬門檻** |
| **gate_37** cq_exec_equiv | E1/E3:CQ vs 直接 CSR 等價 | **先實測是否破**(讀 tb_npu_cq_equiv.v 比對粒度):docstring 已寫「may add descriptor fetches」,若比對只看 weight-source read + write-channel 則原樣綠;若把 ring-read 也算進 → 依 E1/E3 修比對器**只比 engine CSR window 交易**,fetch-DMA 移 non-blocking metric。**修比對器不得放寬 engine 序列比對** |
| **gate_36** cq_ring | E2:ring wrap/FULL | `to_wrap` 切分,逐 descriptor 語義不變 → 應綠 |
| **gate_39** cq_lockstep_mmio | E2:全 consume 鏈 Spike lockstep(MMIO-shadow) | **⚠️ MMIO-shadow(poll-free golden)在 fetch/poll 結構變後需重生**;重生後 engine 側 commit 序列須與舊 golden 逐筆一致,只准 fetch/poll MMIO 序列變 |
| **gate_47/53/54** | traps/trace/hard-reset(皆載 cq_sequencer firmware) | 迴圈結構改變,需全部重綠 |

**green-wash 守衛**:
1. **bit-exact 硬門檻**:gate_46 輸出 tile 一位不符即退。
2. **throughput 必須實證下降**:量 descriptor-fetch 的 DMA GO 次數/層 —— 批次後應 ≈ `ceil(descriptors/BATCH_N)`,不得只宣稱變快不出數字。
3. **wrap 跨批**:必有一個 batch 跨越 ring wrap 邊界的 directed 案例(gate_36 覆蓋或新增)。
4. **MMIO-shadow 重生不得掩蓋分歧**:gate_39 shadow 重生後,lockstep commit 數與 engine 命令序列須與舊 golden 的**引擎側**逐筆一致(只准 fetch/poll 的 MMIO 序列變)。
5. 純 firmware:**不新增/改任何 .v**(green-wash 守衛:diff 只含 cq_sequencer.c + 測試/golden)。

---

## §5 review 後才實作(§2 第 4 問)

accepted 後:我方外科改 `cq_sequencer.c`(或 Codex)→ `make -C IP/npu/sw/cq_sequencer` 重生
firmware.hex → 跑 gate_36/37/39/46/47/53/54 全綠 + throughput 出數字 → 處理 gate_39 MMIO-shadow
重生 → Codex review diff → commit。**BATCH_N 起手 8**(Grok);**不動 RTL/SSOT**。

## §6 實作結果(2026-07-05)

**批次預取落地(BATCH_N=8),但實作揭露一個 firmware-only 無法規避的約束(User 裁示處理)**:
- **footprint 撞牆**:sequencer firmware 有凍結預算 `text+data+bss < TCM_WEIGHT_B`(gate_51 守衛;
  weight region 0x680 被 golden/TB/gate 共用契約)。原 firmware 1620B(僅 44B headroom);批次預取
  即使 `noinline`(csr_read/write/cq_halt/dma_read/writeback,回收 116B)+ `-Oz` + gc-sections
  仍 **1716B,超 0x680 達 52B**。批次的 loop+wrap+min-clamp 機具是固有成本,N 大小不影響。
- **決策(User 2026-07-05:「移 weight region 0x680→0x700」)**:**scope 從「firmware-only」擴為
  含 memory-map bump**(ADR-0043 weight region 第三次移位:0x400→0x600→0x680→**0x700**)。
  firmware 1716B < 0x700(margin 76B)。cascade 更新(bit-exact 逐一驗):cq_sequencer.c(TCM_WEIGHT_B)、
  golden tflm_fc.py/tflm_runtime.py(TCM_BLOB_B,參數化 a/b/bias 自動跟隨)、tb_npu_cq_mat/equiv/
  smoke/strided/hard_reset/p05(硬編碼 a@0x700/b@0x740、STORE src、weight readback)、gate_48
  (bias assert)、gate_51(footprint guard 0x680→0x700)。gate_51 codec 測試值(0x680,與 memory-map
  無關)保留。對齊/容量已驗:0x700 32B 對齊、k_dim=64 blob 尾 0xD40<0xF00、gate_46 a/b 尾 0x760<
  MAT_OUT 0x800、weight 容量 544→512 words(測試最大載入 <512)。
- **驗證(20 gate 全綠,bit-exact 保住)**:gate_36/37/46(ring/等價/矩陣 e2e 逐位)、gate_48/49/50
  (TFLM FC/MLP/CNN 逐位)、gate_39(MMIO-shadow lockstep,**自動保持,無需重生**)、gate_47/51/54/53
  (traps/offload/hard-reset/trace)、gate_45/52/35/38(mat golden/memory/SSOT/ERR)。
- **等價 gate 未需修比對器**:gate_37 本就容忍「CQ transport may add descriptor fetches」(E1/E3
  框定天然成立),批次改變 descriptor-fetch DMA 但 engine 命令流不變 → 原樣綠。
- **throughput(結構性保證)**:firmware 每 batch 一次 `dma_read`(源碼可驗);gate_46 的 5-descriptor
  環一次抓取 → **fetch DMA 5→1**;一般 N-descriptor 層 → `ceil(N/8)`(Grok 68-desc 例:68→9,~7.6×)。
- **size 技巧記錄**:`-Os` 把 csr_read/write(~30 呼叫)全 inline 進 main 很肥;`noinline` 於高頻小
  函式回收 ~116B。weight region 每次 text 成長就 bump(既有模式)。

## §7 Codex review 處置(2026-07-05)

- **Finding 1(High)→ 記為 deviation(不加碼)**:批次 DMA 若在 descriptor `bi>0` faults,
  `wait_done` 在 dispatch 前 `cq_halt`,descriptors `0..bi-1` 未執行、HEAD 停在批起點;舊單發
  fetch 迴圈會先執行 `0..bi-1` 再於 `bi` 的 fetch fault。**判斷:批次只讀 ring 內有效已 commit
  slot(to_wrap + pending 界定),ring 是有效連續 buffer;mid-batch 讀取 fault 需 host 把 ring 配到
  錯誤記憶體 = host 誤配,同 RING_OVERRUN 類 host-discipline 偏離。且 ADR-0035 deviation #2 已記
  「DMA_FAULT on descriptor fetch 未有 CQ-level directed test」。** ∴ 記為誠實界偏離:批次 fetch
  fault 的 per-descriptor 顆粒度不保留(有效 ring 讀取不預期 fault;faulting ring = host 紀律)。
- **Finding 2(Medium)→ 已修驗**:batch buffer 現佔 0xF00..0xF80(多個 descriptor),而 MAT_STORE
  src 上限原為 0x1000 → 可讀回未 dispatch 的預取 descriptor(舊碼 scratch 只存 1 個 16B descriptor)。
  修法:STORE src 天花板 `0x1000 → TCM_SCRATCH_B(0xF00)`——**scratch/descriptor-prefetch buffer 為
  firmware-private,禁當 STORE source**。constant-only(firmware 1716→1720B,仍 margin 72);gate_46/
  51/48 的合法 STORE(src 0x700/0x800,皆 <0xF00)全綠。

---

## 附:Grok 架構複核(2026-07-05,全文歸檔 docs/reviews/2026-07-05_cq_autonomous_prefetch_grok.md)

**收斂**:①step-4 fetch 是主導稅(確認+量化)②批次預取是正確 P0 軟體優化 ③wrap 用 `to_wrap`
上限、HEAD 逐 descriptor、TAIL 批邊界重讀 ④loop-invariant ring config ⑤engine 命令流逐位不變
→ bit-exact ⑥S3(A/B staging)低 ROI、S4(硬體 command FIFO)= RTL scope-creep,**拒絕**。
**Grok 精修(採納)**:①**N=8 非 16**(遞減報酬)②**E1/E2/E3 等價框定**(§4)+ 建議把全-AXI diff
移到 non-blocking metric 或獨立 `gate_39b_prefetch_sanity`(burst 數 ↓、總 bytes =)③FENCE 在其
descriptor 執行 drain 才 HEAD++,同批 fence 後的預取資料 inert 直到執行序到達(安全)④ERR 時
**不得**把 local_idx 推進未執行的預取槽。
**分歧**:無實質分歧;Grok 更保守建議「FENCE 後可選重讀 TAIL」(producer 可能 fence 後才 doorbell)
——列為選配,bit-exact 不需要。
