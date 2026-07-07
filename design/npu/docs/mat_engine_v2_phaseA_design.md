# mat_engine v2 · Phase A 設計 — GEMM job sequencer(for review)

- **Status:** DESIGN(待 Grok 架構 + Codex RTL-reality review)· 2026-07-07 · Claude
- **上位:** ADR-0067 · `mat_engine_v2_plan.md` §6 Phase A
- **鐵律:** MAC 數學(mat_engine S_RUN/S_RSC)凍結;`ml_active=0`(default)→ 舊韌體路,gate 全綠不變;**E1 = mat_engine + dma 交易流與今日韌體逐筆相同**(時序可不同)。

---

## §1 Phase A 範圍(最小可驗)

**做**:一個硬體 FSM `ml_tile_seq`,由**一次 job kick** 展開整個 GEMM 的 tile 迴圈,直接驅動 `mat_engine` +
`npu_dma`,**tile 間不回韌體、不 scalar spin-poll**。攻實測 ~1,120 cyc/tile 韌體固定稅。
**不做(留 Phase B)**:DMA overlap / 權重 double-buffer、activation-stationary、cmd_fifo depth>1、
MAT_REQUANT_VEC job、多 K-chunk(Phase A 假設 K≤64 單 chunk,涵蓋 PoC 的 k_proj)、多 bank 輪替。

**PoC = k_proj**:[8×64]×[64×64] → 8 tiles、K=64 單 chunk、per-tensor requant。先在一條 GEMM 證全鏈。

## §2 為何 Phase A(即使不 overlap)就有大 win

實測 gate_proj:core\* 18,002(韌體 dispatch/poll)+ dma 7,236 + mat 1,360。硬體 FSM 把 6 CQ-op/tile 的
**韌體固定稅 ~187 cyc/op → ~1-2 cyc/op 硬體 dispatch**,tile 間 back-to-back。core\* 崩到 ~近 0,floor =
dma + mat + 少量 hw ovhd ≈ ~9k → **k_proj/gate_proj ~2.6×**(plan target ≥2×)。overlap(Phase B)再把 dma 藏進計算。

## §3 wiring:mux 進既有訊號(關鍵整合點)

今日 `mat_engine`(npu_top:294)與 `npu_dma`(:373)皆由 `npu_axil_regs`(CSR,韌體驅動)供訊號。
Phase A 加 `npu_ml_ctrl`,對這兩組訊號做 **2-to-1 mux**,`ml_active` 選:

```
  ml_active ? ml_*  : csr_*    →  mat_engine.{go,cmd,arg_bank,arg_rpt,a_addr,b_addr,rs_mult,rs_shift,
                                              rs_zp,rs_min,rs_max,out_base}
  ml_active ? ml_dma_*: csr_*  →  dma 的 {dma_go,dma_src,dma_dst,dma_len} + {wb_go,wb_src,wb_dst,wb_len}
  (mat_busy/mat_done/dma_busy/dma_done/wb_done 回讀給 ml_tile_seq 當內部 wait 條件)
```
`ml_active = ML_V2_EN & ml_job_busy & ~legacy_bypass`。**default `ML_V2_EN=0` → mux 恆選 csr_*,零回歸。**
mux 放 npu_top(或 npu_ml_ctrl 內含 mux 再吐最終訊號);`mat_engine`/`npu_dma`/`npu_axil_regs` 內部**不改**。

## §4 Job descriptor(TCM blob,`ML_JOB_ADDR` 指)

`ml_tile_seq` 要複製今日 `lower_layer_v2` 的 per-tile 位址算術(E1 等價),故 job 帶其常數:

| 欄位 | 意義(對照 lower_layer_v2 / cq_sequencer)|
|---|---|
| `n_groups`,`n_tiles` | 迴圈上界(job_i = 0..n_groups*n_tiles−1)|
| `blob_base`,`job_stride` | shared-mem per-tile blob:`SHARED_BLOB_B + job_i*JOB_STRIDE_B`(LOAD_W src)|
| `lw_rows`,`lw_cols` | LOAD_W 幾何(→ dma_len = rows*cols words 至 `TCM_WEIGHT_W`)|
| `a_off`,`b_off` | mat OP 的 `a_addr=TCM_BLOB_B+A_OFF`、`b_addr=TCM_BLOB_B+A_OFF+8*K`|
| `rpt`(=K/... ),`bank` | mat OP rpt、acc bank(Phase A 固定單 bank)|
| `fold_ptr` | ACC_CLR 的 fold(bias+in_off*Σw)TCM byte(GeGLU fold=0)|
| `mult`,`rsp`,`clamp`,`out_base_tcm` | per-tensor RESCALE 參數 + RESCALE 輸出 TCM base |
| `dst_base`,`dst_stride` | STORE:`SHARED_DST_B + job_i*0x40`(dma writeback)|
| `flags` | irq_on_done、last |

## §5 `ml_tile_seq` FSM(每 tile 序列,serialized)

```
S_IDLE : ML_JOB_GO & !busy → latch job; job_i=0; ml_job_busy=1
per job_i:
  S_LDW  : drive dma_go, dma_src=blob_base+job_i*job_stride, dma_dst=TCM_WEIGHT_W, dma_len=lw_rows*lw_cols
           wait dma_done
  S_CLR  : drive mat go, cmd=LOADACC(fold) 或 CLR;  bank; a_addr=fold_ptr;  wait mat_done
  S_OP   : drive mat go, cmd=OP, rpt, a_addr=TCM_BLOB+a_off, b_addr=TCM_BLOB+b_off, acc=0;  wait mat_done
  S_RSC  : drive mat go, cmd=RESCALE, mult/rsp/clamp/out_base;  wait mat_done
  S_STO  : drive wb_go, wb_src=out_base_tcm, wb_dst=dst_base+job_i*dst_stride, wb_len;  wait wb_done
  job_i++ ; if job_i==N: S_DONE
S_DONE : ml_job_busy=0; ml_job_done=1; if flags.irq → pulse IRQ (同今日 last STORE irq 語義)
```
每個 `drive` = 一拍設好 mux 訊號 + 一拍 go pulse;`wait *_done` 讀既有 busy/done。**與韌體同一組交易,
只是發射者換成硬體、tile 間無 scalar 稅。** abort/hard_reset:`npu_abort` 進 mat_engine/dma(既有),
`ml_tile_seq` 見 `npu_abort` → 回 S_IDLE 清 busy(FIFO 無,故無 drain;sticky abort 同 ADR-0038/0047)。

## §6 新 CSR(`npu_axil_regs`,core-local 窗,SSOT 加)

| CSR | 存取 | 說明 |
|---|---|---|
| `ML_JOB_ADDR` | RW | job blob TCM ptr |
| `ML_JOB_GO` | WO pulse | `ml_job_busy` 為 0 才接受 |
| `ML_JOB_STATUS` | RO | `{busy,done,err,err_code[7:0]}` |
| `ML_JOB_CFG` | RW | `[0]=legacy_bypass`(強制韌體路)|

韌體發 job:寫 blob(現有 lower 的 per-tile blob 佈局不變,只是不再逐 tile 發 CQ,而是填 job 常數)→ 寫
`ML_JOB_ADDR` → 脈 `ML_JOB_GO` → poll `ML_JOB_STATUS.done`(**一個 job 一次 poll**,取代 N tile × 6 op poll)。

## §7 驗證(gate_67)

1. **E1 等價(權威)**:`tb_ml_v2_equiv` — 對同一 k_proj,side-by-side 跑 (a) 今日韌體路 (b) ml_tile_seq 路,
   **錄下 mat_engine 每次 go 的 {cmd,bank,rpt,a,b,mult,rsp,clamp,out_base} + dma/wb 每次 go 的 {src,dst,len}**,
   斷言兩序列**逐筆相同**(時序/descriptor-fetch 不比,E3)。
2. **bit-exact**:ml_tile_seq 路的 k_proj 輸出 == mat_golden(byte-for-byte)。
3. **回歸**:`ML_V2_EN=0` 下 gate_45/46/gemma_layer 全綠(mux 恆選 csr,零改變)。
4. **profiler**:k_proj step ≥2× vs 今日。
**green-wash 守衛**:不改 mat_golden;legacy 全程綠;E1 序列比對不得只比長度;throughput 與 bit-exact 分開。

## §8 開放問題(給 review)

1. **cmd_fifo Phase A 要不要?** 提案:Phase A 直接 FSM(serialized wait-on-done),FIFO 留 Phase B(overlap 才需)。減 RTL、E1 更好證。同意?
2. **STORE 併入 job 還是獨立 `ML_JOB_STORE`?** 提案:併入(flags.store_en),per-tile S_STO。
3. **K>64 多 chunk**:Phase A 只做單 chunk(k_proj K=64)。gate_proj K=64 也單 chunk;多 chunk(down K=128)留 Phase A.2。同意分？
4. **位址算術落硬體 vs job 帶更多預算好的位址**:提案硬體算(job 帶 base+stride+count),省 job blob 大小;但增 RTL。或韌體預算好每 tile 位址存 job array(硬體純查表)——哪個 E1 風險低？
5. **Job descriptor SSOT**:新 `ml_job.yaml` 還是塞進 command_descriptor SSOT？提案獨立 `ml_job.yaml`(job≠CQ descriptor)。
6. **abort mid-job**:S_* 任一態見 npu_abort → S_IDLE、清 busy、mat/dma 各自既有 abort 收尾。夠不夠(vs 需要顯式 drain)？

---

## §9 Review 結論(Grok 架構 + Codex RTL-reality,2026-07-07)— **本節修正上文草稿,以此為實作規格**

**兩方一致:方向 APPROVE**(mux 進既有訊號 + serialized 無-FIFO + 單-chunk + 硬體展開 tile 迴圈)。**但草稿有數個真錯,Codex 讀真碼抓出,修正如下:**

**P0 修正(E1-breaker,必改):**
1. **Job 用 CSR 編程,不是 TCM blob**〔Codex:`npu_tcm` 無 ml_ctrl 讀埠(只 dma/engine/core/host)〕→ 韌體把 job 欄位寫進一組新 CSR(≤~15 欄),脈 `ML_JOB_GO`;`ml_tile_seq` 讀 CSR,不讀 TCM。省一個新 TCM 仲裁埠。(開放問題 #4/#5 隨之定:HW 算 job_i×stride 的簡單位址;job 不需獨立 SSOT,就是 CSR defs。)
2. **RESCALE 是 per-channel `RESCALE_PC`(cmd=4)不是 per-tensor**〔Codex:`lower_layer_v2:259-262` 發 param_ptr、codec RPT=1、韌體映 `MAT_CMD_RESCALE_PC`〕→ job 帶 `param_ptr`(TCM 指 8×mult+8×shift),S_RSC 發 RESCALE_PC。(per-tensor 是 ewise_mul 的事,GEMM=per-channel。)
3. **S_CLR 一律發 `LOADACC`(cmd=3)不是 CLR**〔Codex:GeGLU fold=0 但 `lower_layer_v2:247-252` 仍發 ACC_CLR(bias_tcm=0x700)→ 韌體 W2≠0 映 LOADACC〕→ 即使 fold=0 也 LOADACC a_addr=fold_ptr。**不可優化成 CLR(E1 分歧)**。gate 加 fold=0 corner。

**FSM/mux 修正:**
4. **無 S_CFG**〔Codex+我確認:MAT_CFG 是韌體 bookkeeping(設 cfg_k 驗 OP),**不驅動 mat_engine、非交易**〕→ 硬體每 tile 交易 = **LOAD_W(dma)→ LOADACC → OP → RESCALE_PC → STORE(wb)= 5 筆**,無 CFG。(Grok 誤標「缺 S_CFG」= 未見真碼,已駁。)
5. **Handshake:done 是 sticky**(mat/dma done 保持到下次 go accepted,非 1 拍)→ FSM 每步要 **ISSUE→WAIT(先見 busy 起=go accepted,再等 done)**,防採到上一命令的 stale done 而跳過 OP/RESCALE。
6. **DMA mux 在 go-merge 之前**(mux `dma_go/src/dst/len` + `wb_go/src/dst/len`,讓既有 `dma_start_write=wb_go&~dma_go` + `dma_mode_write_l` latch 處理);**ml 一次只脈 dma_go 或 wb_go 其一**(兩者同脈 write 會被丟)。
7. **mux 守衛**〔Grok〕:`ml_job_busy` 鎖 mux(job 中不可切 legacy_bypass);**ml_active 期間擋韌體對 mat_*/dma_*/wb_* 的 CSR 寫**(否則 E1 靜默破);mux 只在 S_IDLE(mat_busy=0 && dma_busy=0)切換。
8. **abort**〔兩方〕:見 npu_abort → 停發、進 abort-drain 態**等 `!mat_busy && !dma_busy_engine`**,報 `err=ABORTED`(非 done),再 S_IDLE。不即清 busy。

**P1 修正:**
9. **gate_67 只比「命令消耗的欄位」**〔Codex:韌體只在每命令前寫消耗欄位,其餘 sideband 是 stale,全比會 false-fail〕→ 按命令型別比(OP 比 cmd/bank/rpt/a/b;RESCALE_PC 比 cmd/bank/param_ptr/rsp/clamp/out_base;dma 比 src/dst/len);或 ml_tile_seq 存 CSR-like shadow reg 只更新消耗欄位。
10. **PoC 改 `q_proj`(8 tiles,K=64 單 chunk)**〔Codex:repo config hidden=64/nkv=1/hd=16 → **k_proj 只 N=16=2 tiles**;q/o_proj 才 8 tiles〕。之後加一 variant(gate_proj N=128=16 tiles,K=64 仍單 chunk)證 tile 數泛化;down_proj(K=128 多 chunk)留 Phase A.2。

**開放問題定案**:①無 FIFO(兩方)②STORE 併 job flags.store_en(Grok)③K>64 → Phase A.2(兩方)④HW 算位址(Grok;隨 CSR-job 簡化)⑤job=CSR 非獨立 SSOT(隨 P0#1)⑥abort-drain 等 busy=0(兩方)。

**Codex 給的 q_proj E1 交易表(實作對照,per tile job=0..7)**:LOAD_W `src=0x80000000|(0x2000+job*0x800) dst=0x1c0 len=400w` · LOADACC `bank0 rpt1 a=0x700` · OP `bank0 rpt64 a=0x940 b=0xB40` · RESCALE_PC `bank0 param_ptr=0x720 rsp=0 clamp=0x7f80 out_base=0x800` · STORE `src=0x200 dst=0x80000000|(0x1800+job*0x40) len=16`。

**LOC**:~400-600 行仍實際(mux + CSR + FSM 8 態 + 位址算術),前提是照上修正、單 chunk。**下一步:照 §9 修正版出 Phase A 實作規格 → Codex 外科實作 → Claude 跑 gate_67 E1 + bit-exact + profiler。**
