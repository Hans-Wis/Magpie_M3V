# soc M3b — writeback 寬化 + CQ 泛化對齊 + 兩-bus 實體分域 · for review

- **Status:** DESIGN（待 Grok 架構 + Codex 整合實況 review）· 2026-07-08 · Claude
- **上位:** ADR-0068 §2.5 / M3 · 承 M3a（@62a4e59,讀/載入路寬化,dma 1539→363@256b）
- **鐵律:** 全用本地 IP;功能權威 = bit-exact vs golden + dma floor 實測下降;**default DMA_DATA_W=32 零回歸**。

---

## §0 M3b 三部分（承 M3a）

M3a 拓寬**讀/權重-載入路**(dma 1539→363@256b),但 **writeback 保持窄**(awsize=2,1 字/beat)。實測 dma=363 floor 中,
**per-tile STORE 16 字 × 8 tiles = 128 字仍走窄 = 128 beats**(佔 floor 一大塊)。M3b:
1. **M3b-1 writeback 寬化**（主 perf 槓桿）:STORE 路寬化 → 128 beats → 16 beats,推 dma floor 更低。
2. **M3b-2 CQ sequencer 泛化對齊**:讓**通用 CQ 路**(cq_sequencer,非只 npu_ml_ctrl)也能用寬 DMA——LOAD_W/STORE 保 WPB 對齊或補 tail。
3. **M3b-3 兩-bus 實體分域**:M2 已邏輯分（control lite + data full bridge/arbiter）;實體化=命名 bridge、控制 32/資料寬清晰分離、文件對齊 ADR-0068 §2.5。

## §1 Coral 對照

Coral 卸載寫回經 128-bit 埠。M3a 已對齊讀路;M3b-1 補寫路對稱 → 卸載雙向皆寬,匹配 Coral 埠寬（隨 SKU）。

## §2 M3b-1 writeback 寬化（M3a 讀路鏡像）

現況（M3a）:npu_dma 寫路 `m_awsize=3'b010`（窄）、`wdata_mux` 把單 `buf_rdata`(32-bit) 放對應 lane、1 字/beat;
npu_tcm DMA 讀埠 `dma_rdata[31:0]`（單字,line 41）。**寬化**（對稱 M3a 讀路）:
1. **npu_tcm DMA 讀埠**:`dma_rdata`→`[DMA_DATA_W-1:0]`,一拍讀 WPB 連續字（`for gw: dma_rdata[gw*32+:32]=mem[dma_raddr+gw]`,鏡像 write 側 124-126;WPB≤8 bank-parallel）。**真並行讀**(green-wash:非序列)。
2. **npu_dma 寫路**:`m_awsize=$clog2(DMA_DATA_W/8)`（寬 fast path）;`wdata_mux` 組 WPB 字（`buf_rdata`→WPB 寬）;`buf_raddr += WPB`;`cur_addr += beats*WPB*4`;4KB cap 寬 beats;**writeback ERR_ALIGN**（`dst%(W/8)==0 && src_word%WPB==0 && len%WPB==0`,否則窄退 or err——見 §5 Q1）。
3. **DMA_DATA_W=32**→WPB=1→退化今日窄寫（零回歸）。
- **ROI**:ml_v2 B1.1 STORE 128 字（8 tiles×16）窄 128 beats → 寬@256b 16 beats,dma floor ~363→~250。

## §3 M3b-2 CQ sequencer 泛化對齊

現況:`cq_sequencer.c` `dma_read(src,dst_word,len)` / `dma_writeback(src_word,dst,len)` 設 CSR,只保 4-byte 對齊、任意 cols。
M3a ERR_ALIGN 要求 weight-load fast path WPB 對齊。**泛化**:讓通用 CQ 路寬 DMA 安全:
- **方案 A（傾向）**:sequencer 保證 LOAD_W/STORE 的 src/dst/len **WPB 對齊**（tile 佈局 pad 到 WPB 倍數;weights 區已 32B 對齊,len pad 到 8 字）。零 RTL,firmware/ABI 契約。
- **方案 B**:npu_dma 支援 **tail beat**（partial wstrb + TCM lane-valid),len 非 WPB 倍數時尾 beat 部分寫。RTL 複雜,但免 firmware pad。
- **決策傾向 A**（對齊契約,honest ERR_ALIGN 守衛;B 留長尾）。gate_46/gemma 通用 CQ 路建 wide 驗證。

## §4 M3b-3 兩-bus 實體分域

M2 soc_m3v_top 已:控制 AXI-lite（host→soc_axil_decode→CSR/TCM/PLIC）+ 資料 AXI-full（npu_dma + host-bridge via axil_to_full → arbiter → 寬 SRAM)。**實體化**:
- **命名 bridge**:`axil_to_full`(host lite→資料 full) = 具名 control→data bridge;文件/圖標明。
- **確保分離**:控制 AXI 恆 32-bit（CSR/PLIC/doorbell）;資料 AXI 寬（DMA_DATA_W);SRAM 控制側窄寫（byte-lane）+ 資料側寬（M3a 已做）。
- **region guard**（Grok M3 §5）:decode 防單 descriptor 跨 CQ/weight 邊界。
- **範圍**:多為結構命名 + 文件 + region guard;無新 perf。可與 M3b-1 併 commit 或獨立小 commit。

## §5 開放問題（給 review）

1. **writeback 對齊 policy**:STORE 也強制 WPB 對齊 → ERR_ALIGN（同讀路）vs 窄退化（保相容任意 len)?ml_v2 STORE=16 字（WPB 對齊）;通用 CQ STORE 可能非對齊 → A（對齊契約)or tail-beat?傾向對齊 + ERR_ALIGN 一致。
2. **TCM DMA 讀埠 bank 衝突**:寬讀 WPB 字 vs engine 256-bit 讀/core 讀/checker——writeback 時 engine idle（run-to-completion）→ M3b 序列化下不撞?bank-budget checker 讀側已計,寬 dma 讀要納入?
3. **M3b-1/2/3 staging**:三者獨立?傾向序 **M3b-1（writeback,perf）→ M3b-2（CQ align,泛化）→ M3b-3（兩-bus,結構)**,各自 verify + commit。或 1+3 併（都動 soc/dma）?
4. **writeback wide vs 讀路共用 npu_dma**:同一 npu_dma 實例讀寬/寫窄（M3a)→ 現寫寬,`m_arsize`(讀)與 `m_awsize`(寫)各自寬 = 對稱?單一寬 AXI 介面雙向寬,無衝突。
5. **通用 CQ 路 wide 驗證點**:gate_46（直接 CQ MAT e2e）建 wide（MAT_LANES=2/4）→ bit-exact?gemma layer gate 同?哪個當 M3b-2 驗收 golden。

## §6 Review resolutions（Grok APPROVE-WITH-CHANGES + Codex needs-changes,2026-07-08）

兩份收斂,方向 APPROVE,**分階段 M3b-1→M3b-2→M3b-3 各自 verify+commit**（不 bundle;M3b-2 依賴 M3b-1 對齊 policy)。定案（file:line by Codex）:

1. **M3b-1 writeback（機械清楚,安全,先做)**:widen npu_dma 寫路（`buf_rdata`寬、`m_awsize=AXI_SIZE`、寫 beats=`remaining/WPB`、4KB cap 用 AXI_SIZE、`words_in_burst=beats<<WPB_LG2`、full-width wdata/wstrb、`buf_raddr+=WPB`、**寫側 ERR_ALIGN** 對稱讀路 npu_dma.v:149）+ npu_tcm DMA 讀埠寬（`dma_rdata[gw*32+:32]=mem[dma_raddr+gw]`,鏡像 M3a 寫 loop 124-126）。**不動 TCM 寫**（Grok:已 WPB bank-parallel)。
2. **對齊 policy**:writeback 也**強制 WPB 對齊 + ERR_ALIGN**（同讀路;**不靜默窄退化=green-wash trap**）。ml_v2 STORE=16 字已對齊。
3. **P1 TCM read-budget checker**:現只計 `dma_raddr[2:0]` 單 bank（npu_tcm.v:165);寬讀要計全 WPB banks。writeback 不與 engine 讀重疊（serialized:mat_run 阻塞於 dma_writeback 前 cq_sequencer.c:178/345;npu_ml_ctrl S_STO 在 S_RSC_W mat_done 後 270/276）→ 功能安全,但 checker 需修正。
4. **M3b-2 CQ 泛化（有 blocker,Codex 關鍵發現)**:**CQ descriptor prefetch 本身是 DMA**（`n<<2` 字,cq_sequencer.c:286)——WPB=8 時 5-descriptor batch=20 字 **觸 ERR_ALIGN**!Option A:①CQ ABI 保證 `src%AXI_BYTES==0`、TCM word `%WPB==0`、len `%WPB==0` ②pad LOAD_W/STORE rows/len 到 WPB ③**pad/split descriptor prefetch 到 WPB 倍數**（不處理 padded descriptors)。gate_46 需 widen TB（現 hardwire 32-bit,tb_npu_cq_mat.v:29/43）+ 修 prefetch 對齊 + 加 LOAD_W case。
5. **M3b-3 兩-bus（region-guard 是非-cosmetic 價值)**:M2 已邏輯分（control lite soc_axil_decode + data full axil_to_full/arbiter/sram);實體化=**region-decode guard**（拒/split 跨 CQ-ring/weight 邊界的寬 burst——寬 burst 增大錯 addr/len blast radius,256b×LEN15 跨界靜默腐蝕)+ 命名 + 文件。無新 coherency hazard（M2 fence/doorbell 已管）。**naming-only 不足,必含 guard 或明確 defer**。
6. **零回歸**:WPB=1→AWSIZE=clog2(4)=2、buf_raddr+=1、wstrb=4'hf → 退化今日（npu_top.v:83 default 已容 32 regression)。
7. **gate_29 scoreboard**（Grok）:計寬 beats + W-channel partial-abort。**re-measure 公布 floor**（~363→~250 預期,非空口 8×)。

**觸及**（Codex）:npu_dma/npu_tcm/npu_top（M3b-1）· cq_sequencer.c + CQ emitter + tb_npu_cq_mat + gate_46（M3b-2）· soc_m3v_top/soc_axil_decode region-guard（M3b-3）。

## §7 M3b-3 輕量收尾（兩-bus 形式化 + region 保護層級,User 裁示 2026-07-08）

M3b-1/M3b-2 已交付實質價值。M3b-3 經評估**實質內容偏薄**(M2 已邏輯分兩-bus、無新 coherency hazard、region guard 與既有守衛重疊),User 裁示**輕量收尾**(命名/文件 + 確認現有 guard,無新 HW)。

### 兩-bus 已實現(M2 + 命名形式化)
| Bus | 實體 | 職責 | 寬度 |
|---|---|---|---|
| **控制 AXI** | host M_AXI_D → `soc_axil_decode` → {NPU CSR/TCM 0x3000 · PLIC 0x0c00 · SRAM bridge 0x8000} | CSR/doorbell/PLIC/TCM 載入 | 32-bit(恆) |
| **資料 AXI** | `npu_dma`(master)+ host bridge(`axil_to_full`)→ `axi_full_arbiter_2x1` → `axi_full_sram` @0x8000 | 權重/結果 DMA 串流 | DMA_DATA_W(64×LANES) |
| **Bridge** | `axil_to_full`(host lite→資料 full,窄 beat on 寬 bus) | host 偶發設定寫入跨域 | 窄→寬 |

同-clock 下兩-bus = 邏輯 + 命名分域;獨立 clock domain(async bridge)留未來。

### Region 保護層級(誠實,已測)
| 層 | 機制 | 證據 |
|---|---|---|
| NPU CSR out-of-window | `npu_top` DECERR → SLVERR(no CSR alias) | gate_28 ✅ |
| TCM out-of-range offset | `npu_tcm` SLVERR(**no wrap**) | gate_28 ✅ |
| DMA read/write SLVERR | `npu_dma` latch → STATUS.dma_err(非 silent OK) | gate_28/29 ✅ |
| 韌體 region 邊界 | `cq_sequencer` bound-check(rows*cols > region → cq_halt CQ_ERR_MAT_PARAM);weight 0x700 / scratch 0xF00 | gate_51 footprint + cq consume gates |
| burst 邊界 | npu_dma 每 burst ≤256 beats + 不跨 4KB | M3a/M3b-1 gate |

**誠實限制(記於此,非隱藏)**:`axi_full_sram`(shared SRAM @0x8000)綁 `rresp/bresp=OKAY` 且 addr 截斷到 AW → **out-of-range 靜默 alias(不 SLVERR)**。故 shared SRAM 內 intra-region(ring vs weight vs result)保護目前**靠韌體 bound-check + 4KB burst bound**,非 HW。寬 burst 增大 buggy descriptor 的 blast radius——**HW region guard(axi_full_sram out-of-range SLVERR + region-boundary CSRs)= M3b-3-full,deferred**(defense-in-depth,與韌體檢查重疊,ROI 中等)。

**M3b-3 輕量收尾 = 上述形式化 + 確認 gate_28/29 現有守衛運作(4 passed 獨立)。M3b 完成(M3b-1 writeback perf + M3b-2 generic-CQ-safe + M3b-3 兩-bus 形式化)。**

---
**M3b 實作史**:M3b-1 writeback(@4e52b3a,dma 363→251)· M3b-2 narrow two-tier(@a067fd9,generic CQ @256 安全)· M3b-3 輕量收尾(本 §7)。**下一步:M3c(全 SKU DC PPA)/ v2 Phase A.2(K>64 多 chunk)/ RMSNorm→RVV(134k)。**
