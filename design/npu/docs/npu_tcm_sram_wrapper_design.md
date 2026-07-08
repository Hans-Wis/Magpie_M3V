# npu_tcm banked dual-port SRAM wrapper — 真 TCM macro(取代 black-box)· for review

- **Status:** DESIGN(待 Grok + Codex review)· 2026-07-08 · Claude
- **上位:** DC 全設計綜合(@8b783a0 RTL Presto-clean)· memory compiler 確認(@571eadb)· `~/EDA/13`
- **鐵律:** 全本地;功能權威 = 現有全 gate suite bit-exact(sim 路不變);目標 = DC 拿到含真 SRAM macro 的 TCM PPA。

---

## §0 Part 1 完成:SRAM macro 已生成

TSMC28 memory compiler(mc2-eu,`~/EDA/13`)產出 **dual-port SRAM**(.v sim + .lib DC,全 PVT):
- **DTCM bank** = `TSDN28HPCPA1024X32M4FWBASO`(1024×32,mux4)· **ITCM** = `TSDN28HPCPA2048X32M8FWBASO`(2048×32,mux8)。
- 埠:**Port A**(AA/DA/QA/WEBA/CEBA/CLKA/BWEBA)+ **Port B**(AB/DB/QB/WEBB/CEBB/CLKB/BWEBB),各獨立 R/W(WEB=0 寫/1 讀)。
- **★ 讀是同步(registered):QA/QB 在 CLKA/CLKB 沿更新 = 1-cycle 讀延遲**(`reg bQA` + CLKA→QA arc)。生成 runner `flow/dc_tsmc28/gen_tcm_sram.sh`。

## §1 現況:npu_tcm = flat `reg[]` 多埠、組合讀

現 `npu_tcm.v` = `reg[31:0] mem[]`(8-way word-interleaved 概念),埠:host s_axi · dma-rw(寬 DMA_DATA_W)·
**eng_a 256-bit 組合讀 + eng_b 256-bit 組合讀**(各 8 字)· eng-write(1 字)· core-rw(1 字)。**所有讀組合**(同拍)。

## §2 banking 方案(對 dual-port SRAM）

- **DTCM(8192×32)= 8 個 word-interleaved bank × (1024×32 dual-port)**。bank = `word_addr[2:0]`,bank 內位址 = `word_addr>>3`。
  - eng_a 256-bit 讀(8 連續字,8 對齊)→ **8 bank 全體,Port A,位址 `eng_a_addr>>3`**。
  - eng_b 256-bit 讀 → **8 bank 全體,Port B**。→ 計算期(OP)兩 port 用滿。
- **ITCM(2048×32)= 1 顆 2048×32 dual-port**(Port A=core fetch 讀、Port B=host 寫)。
- 寫/其他讀(dma-rw、eng-write、core-rw、host)**時序分相**(mat FSM:LOAD_W→LOADACC→OP→RESCALE→STORE;
  npu_ml_ctrl 序列化)→ 非 OP 相時 port 空,可服寫。**per-bank 仲裁** mirror 現優先(dma>eng>core>host)+ 讀 strobe。

## §3 ★ 核心決策:registered 讀 vs 現組合讀

真 SRAM 讀晚 1 拍;mat_engine/core/dma 現期望**同拍** eng/core/dma 讀。兩選項:

| 選項 | 做法 | 優 | 劣 |
|---|---|---|---|
| **A 全整合(tape-out)** | 引入 1-cycle 讀延遲 + 改 mat_engine/core/dma FSM 吸收(加 pipeline 級)| netlist 真正功能正確、可流片 | **大微架構改**、改 cycle 數、全 re-verify、需 ADR(mat S_RUN 多拍化=Phase 7 已記偏離)|
| **B synth-wrapper(推薦,先做)** | `ifdef USE_SRAM_MACRO`:synth 走 8-bank SRAM(registered);**sim 走現 flat mem(組合,行為零改)** | **sim 全 gate bit-exact 不變**;DC 拿**真 macro 面積/timing/power**(比 black-box 精確,含 SRAM 讀 arc)；bounded 改動 | synth netlist 讀 timing(registered)≠ sim(組合)——PPA 具代表性但非 cycle-accurate 到 sim;非流片-ready |

**推薦 B**:直接達成 User 目標(真 SRAM macro 重合成 = 真 PPA)且 sim 行為 100% 保留。A(registered 讀全整合)= 流片前的較大 follow-on(改 cycle,獨立 ADR)。

## §4 實作(選 B):npu_tcm.v `ifdef` 雙路

```verilog
`ifdef USE_SRAM_MACRO
  // DTCM: 8 × TSDN28HPCPA1024X32M4FWBASO(word-interleaved)+ per-bank Port A/B 仲裁
  //   Port A: eng_a 讀 / (非 OP 相)dma/core/host 讀寫  · Port B: eng_b 讀 / eng/dma 寫
  //   位址 word>>3;bank=word[2:0];256-bit 讀 = 8 bank QA/QB 拼接
  // ITCM: 1 × TSDN28HPCPA2048X32M8FWBASO(Port A fetch / Port B host 寫)
  // 讀 registered → 用暫存 addr/strobe 對齊(synth-timing 用)
`else
  reg [31:0] mem [0:WORDS-1];  // 現行 flat 組合(sim,行為不變)
  ... 現有全部邏輯 ...
`endif
```
- npu_tcm 對外**埠完全不變**(npu_top 例化不動)。
- synth:`flow/dc_tsmc28/synth_npu_top.tcl` 加 `-define USE_SRAM_MACRO` + analyze 真 npu_tcm.v(不再用 npu_tcm_bb 黑盒)+ SRAM `.db`(.lib→.db)進 `link_library`。
- sim:預設 `ifndef` → flat mem,gate 全綠不變。

## §5 驗證計畫

- **sim 零回歸**:預設(無 USE_SRAM_MACRO)→ npu_tcm 走 flat mem → **全 gate suite bit-exact**(gate_27/45/46/gemma/soc/RVV+F 76…)不變。這是主要正確性保證。
- **synth PPA**:`-define USE_SRAM_MACRO` + SRAM .db → DC elaborate+compile npu_top(含真 TCM macro)→ **含 TCM 的真 area/power/Fmax**(取代 black-box 版)。隔夜 job。
- **(可選)synth-path lint**:USE_SRAM_MACRO 下 Verilator lint clean(bank 拼接/仲裁無 latch/寬度錯)。
- **green-wash 守衛**:sim 必走 flat mem(不偷改行為);synth macro 必真 8-bank 拼接(非假接);PPA 註明「B synth-wrapper,讀 timing registered ≠ sim 組合」誠實界。

## §6 開放問題(給 review)

1. **A vs B**:先 B(PPA,sim 不變)夠嗎?還是 User 要 A(流片-ready,改 cycle)?傾向 B(達標且低風險),A 記為 follow-on。
2. **eng 位址對齊**:eng_a/eng_b 256-bit 讀是否恆 8-字對齊(ADR-0040 tail/對齊)?若否,8 bank 位址各異(需 per-bank `(addr+bank)>>3` + rotate),wrapper 複雜度升。確認對齊契約。
3. **per-bank 仲裁正確性**:計算期 Port A=eng_a/Port B=eng_b;寫在非-OP 相——確認 mat FSM/npu_ml_ctrl 真無 eng 讀 vs 寫同拍(B1 review 曾記 DMA 寫 vs RESCALE 寫撞;此處 registered 讀更要確認相位)。
4. **ITCM 埠**:core fetch(Port A 讀)+ host 寫(Port B)夠嗎?ITCM 有無其他埠(s_axi)?
5. **DTCM 剩餘埠**(host s_axi、core_d、dma-rw)在 registered-read synth 路怎麼對齊(暫存 strobe)——只為 synth-timing,不需 cycle-accurate。
6. **.lib→.db**:read_lib/write_lib 產 SRAM .db 進 link_library 的實作點(synth_npu_top.tcl)。

**下一步:review(Grok:banking/仲裁/A-vs-B/registered-read 決策;Codex RTL 實況:npu_tcm 埠映射、SRAM 埠接法、ifdef 雙路、mat FSM 相位無衝突、eng 對齊、synth tcl .db link)→ 定 §6 → 實作(選定 A/B)→ sim 零回歸 + synth 真 macro PPA → commit + ADR。**
