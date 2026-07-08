# soc M3b-2 — 通用 CQ 路寬-DMA 安全（256-bit SKU 全功能）· for review

- **Status:** DESIGN（待 Grok + Codex review）· 2026-07-08 · Claude
- **上位:** ADR-0068 §M3 · 承 M3b-1（@4e52b3a,writeback 寬化）· 設計母 doc `npu_dma_m3b_design.md` §6.4
- **鐵律:** 全本地;功能權威 = gate_46/通用 CQ 路建 wide 後 bit-exact 不 trap + 零回歸;**不靜默窄退化**（explicit 窄=誠實）。

---

## §0 問題（Codex M3b review 抓 blocker）

M3a/M3b-1 對**寬 DMA fast path**(npu_ml_ctrl)加 ERR_ALIGN（WPB 對齊否則 trap）。但**通用 CQ 路**(`cq_sequencer.c` firmware,gate_46/gemma 用)的 DMA 交易在寬 SKU 會 trap:
- **descriptor prefetch**（cq_sequencer.c:286）`dma_read(ring_base+hidx*16, scratch, n*4 字)`:`ring_base` 僅保證 16B 對齊、`hidx` 變動、`n`∈[1,8] 變動 → 256b(WPB=8,32B/8字對齊)**本質無法保證**（n=5→20 字非 8 倍;hidx 奇→非 32B）。128b(WPB=4)天然對齊。
- **LOAD_W/STORE**（316/345）:`rows*cols`/`cols` 字任意 → 可能非 WPB 倍數。

**目標**:256-bit SKU 全功能——通用 CQ 路**不 trap**（forward-looking:若客戶建 LANES=4/256b,gemma/直接 CQ workload 須能跑）。

## §1 Coral 對照

Coral 卸載走閉源 IREE codegen（對齊由 compiler 保證）。我們的通用 CQ 路是開源 firmware sequencer;寬 SKU 下須穩健。npu_ml_ctrl 快路（wide,對齊 by construction）已對應 Coral 的 tiled offload。

## §2 選項

| 選項 | 做法 | 優 | 劣 |
|---|---|---|---|
| **A 全 WPB-align ABI** | CQ encoder pad 所有 len/addr 到 WPB;prefetch pad ring 幾何 | 通用路也享寬 DMA | **ring 幾何(變動 hidx/n)無法乾淨對齊**;高 firmware/ABI churn + 驗證;對**編排綁定**通用路 ROI 邊際 |
| **C 顯式窄化通用路（推薦）** | npu_dma 加 `narrow_i`;CSR/通用路走窄(WPB_eff=1),npu_ml_ctrl 快路寬 | 零 firmware ABI 改;**explicit 窄=誠實**(非 silent fallback);任何 SKU 不 trap;ring 幾何無約束 | 通用路不享寬 DMA(但編排綁定,損失邊際) |
| **Hybrid** | prefetch 窄(不可對齊)+ LOAD_W/STORE 寬-對齊(pad tile) | prefetch 安全 + 資料寬 | 資料仍需 pad ABI;複雜度介於 A/C |

## §3 推薦設計:Option C（顯式窄化）

`cq_sequencer` 是**編排綁定**（npu_ml_ctrl 才是 DMA-優化快路,v2 建它正因通用路 ~1120 cyc/tile 稅）;寬 DMA 對通用路 ROI 邊際。故:
1. **npu_dma 加 `narrow_i` 輸入**:`narrow_i=1` → 該 transfer 用 WPB_eff=1（arsize/awsize=2、1 字/beat、無 ERR_ALIGN,行為同 DMA_DATA_W=32）。`narrow_i=0` → 寬（M3a/M3b-1 路）。**explicit,非 silent**。
2. **npu_top mux**:`dma_narrow = ml_active ? 1'b0 : csr_narrow`。**npu_ml_ctrl 快路 narrow=0（寬,/4.2 win 不變）**;**CSR/通用 CQ 路 narrow=1（窄,任何 SKU 安全）**。（csr_narrow 可硬綁 1 = CSR 路恆窄,或留 CSR bit 供對齊 workload opt-in wide——傾向恆窄,簡單;opt-in 留 M3b-2b。）
3. **零 firmware 改**:cq_sequencer.c 不動;prefetch/LOAD_W/STORE 恆窄 = 行為同今日,任何 DMA_DATA_W 不 trap。
4. **驗證**:gate_46（通用 CQ MAT e2e）建 **DMA_DATA_W=256**（MAT_LANES=4）→ **bit-exact 不 trap**（證通用路寬 SKU 全功能;經窄 DMA)。tb_npu_cq_mat 參數化 DMA_DATA_W。

## §4 零回歸 + green-wash

- **零回歸**:DMA_DATA_W=32 → narrow_i 無論 0/1 都退化窄（WPB=1)= 今日。所有既有 gate 位元不變。
- **green-wash 守衛**:narrow 是 **explicit 設計選擇（通用路宣告窄）**,非 DMA 見 misalign 靜默退窄（Grok 禁的 green-wash）。文件明記:通用 CQ 路=窄 DMA（穩健,任何 SKU）;優化 offload(npu_ml_ctrl)=寬 DMA（/4.2）。**不宣稱通用路寬**。
- **fast path 仍真寬**:gate_67 ml_v2 的 dma 下降不受影響（ml_active→narrow=0）。

## §5 開放問題（給 review）

1. **C vs Hybrid**:通用 CQ 資料(LOAD_W/STORE)值得寬-對齊(Hybrid)嗎?或編排綁定下恆窄(C)夠?傾向 C（簡單、誠實、ROI）;若有 DMA-bound 通用 workload 證據再 Hybrid。
2. **csr_narrow 恆 1 vs CSR bit opt-in**:恆窄簡單;opt-in 讓對齊 generic workload 享寬。傾向恆窄(M3b-2),opt-in 留後。
3. **narrow_i 時序**:與 write_mode/go 同拍鎖存(transfer 起始鎖 narrow),FSM 內用鎖存值——確認 abort/soft_reset 下乾淨。
4. **gate_46 wide 驗點**:tb_npu_cq_mat 參數化 + 建 256 → bit-exact 即證?需加 LOAD_W generic case(現 A/B host-preload)嗎?傾向現 gate_46 shape + 256 build 已證「不 trap + bit-exact」;LOAD_W wide-generic 留 M3b-2b。
5. **與 M3b-3 region-guard 關係**:窄通用路 burst 短(1 字)→ 跨界風險低;寬 fast path(npu_ml_ctrl 對齊 by construction)→ region-guard 仍 M3b-3 值得。

## §6 Review resolutions（Grok APPROVE-WITH-CHANGES + Codex needs-changes,2026-07-08）

兩份收斂 = **Option C（顯式 narrow_i,CSR/通用路 hard-tie 窄,ml_ctrl 寬）**。定案（file:line by Codex）:

1. **P0 narrow 資料路完整（Codex #1/#6,我 design 漏)**:不只 npu_dma arsize=2——**npu_tcm DMA 埠恆讀/寫 WPB 字**(npu_tcm.v:74 讀 / :130 寫)。故 narrow 需:
   - **npu_dma**:`narrow_i` 輸入(next to go/write_mode,npu_dma.v:26),**S_IDLE 鎖存 `narrow_l`**(旁 mode_write :142);`narrow_l` gate 全 width-derived 路:`m_arsize/m_awsize`(90/96)、burst word 算(115-124)、4KB(117)、align 檢查(125-132,narrow 時 disable ERR_ALIGN)、位址增量(174/208 → +1)。**narrow store 驅 1-lane WSTRB/WDATA**(addressed lane;否則 axi_full_sram:188 寫全 lane)。
   - **npu_tcm**:加 `dma_narrow` 輸入;**narrow dma write → 只寫 `mem[dma_waddr]` 1 字**(非 WPB loop)。讀側 `dma_rdata[31:0]=mem[dma_raddr]` 已是低字,narrow 用低字即可(無讀改)。
2. **npu_top mux（Codex #2,clean)**:`dma_narrow = ml_active ? 1'b0 : csr_narrow`,旁既有 dma_src/dst/len/go mux(npu_top.v:427),傳入 npu_dma(:444)+ npu_tcm。**hard-tie `csr_narrow=1'b1`**(M3b-2;CSR bit opt-in 需 npu_axil_regs ABI,留 P1)。
3. **atomic grant bundle（Grok must-fix,最高風險)**:`{master,addr,len,write,narrow}` 同拍鎖存 by selected master——ml_active 於 job 內穩定,mux 穩定;narrow_l 鎖於 accepted go(如 dma_mode_write_l npu_top.v:437)。**禁 CSR narrow 套到 ml 位址**。
4. **ERR_ALIGN gating**:僅 `narrow_l==0`(寬)觸;narrow 路無 align 約束(=行為同 32b)。ml 寬路 M3b-1 行為不變。
5. **reset/abort（Grok/Codex #6)**:soft_reset/abort 清或 idle 忽略 latched narrow;下個 go relatch。現 abort drain S_DONE(npu_dma.v:178)結構安全。
6. **CSR/通用路恆窄消全 trap（Codex #3 確認)**:sequencer 全 DMA 經 dma_read(169)/dma_writeback(189);call sites=prefetch(286)/LOAD_W contig(316)/strided(326)/STORE contig(345)/strided(353);ACC_CLR fold 走 MAT LOADACC 非 DMA。narrow=1 消全 align trap(AXI fault dma_err 仍在)。
7. **gate_46 wide 驗（Codex #4)**:tb_npu_cq_mat 現 hardwire 32-bit(30/35/39/60)+ npu_top 無 DMA_DATA_W override。**參數化 TB DMA_DATA_W → npu_top + axi_full_rwmem → 建 -GDMA_DATA_W=256(MAT_LANES=4)→ bit-exact 零 trap**。涵蓋 prefetch+STORE@256;不涵蓋 MAT_LOAD_W(A/B host-preload,:152)→ generic LOAD_W wide 留 P1。
8. **誠實界（Grok #2/#5)**:narrow=**per-requestor 政策(通用路宣告窄)**,非 DMA 見 misalign 靜默退窄。ADR/文件明記 two-tier:「ml_ctrl offload=寬 beat+ERR_ALIGN;CSR/generic orchestration port=窄 beat」;**不宣稱 full 256b everywhere**。Coral 對照:通用路窄=Coral 控制路類比,功能可取代性(bit-exact)不損。
9. **零回歸（Codex #5)**:DMA_DATA_W=32→WPB=1,narrow 0/1 皆退化 1 字/beat = 今日。

**觸及**:npu_dma/npu_tcm/npu_top（narrow 路）· tb_npu_cq_mat/gate_46（wide 驗）· tb_npu_dma_width/gate_npu_dma_width（narrow directed）· docs。

**下一步:實作（Codex 外科,照 §6;P0 narrow 完整資料路 incl. TCM 1-字寫 + 1-lane wstrb + atomic latch;hard-tie csr_narrow=1;gate_46@256 參數化）→ gate_46@256 bit-exact 零 trap + 零回歸 → commit。**
