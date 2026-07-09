# Grok 架構 review — soc_m3v_top 周邊整合(QSPI-XIP/UART/CLINT)

> 2026-07-09,`grok -p`。註:CLI 輸出僅保留結論段(前段逐條分析未落盤);阻斷項已全數併入 design/npu/docs/peripheral_integration_design.md §4.1a/§5。

## 4. 驗證計畫：是否夠、是否誠實

### 做得好的

- 自建 SPI-NOR model（mode-0、0x03、`$readmemh`）— 必要且對。
- gate_85 bit-exact readback + off-window SLVERR。
- gate_86 XIP-boot e2e vs 既有 golden / imem-boot 一致 — **正確的權威**。
- 明確 **不縮** host lockstep scope — green-wash 守衛對。
- filelist 三處同步提醒 — 對。

### 不足 / 不誠實的缺口

**V1 — gate_85 範圍偏「快樂路徑」**  
應明示（並實作）至少：

- 對齊 word 讀全窗抽樣 + 邊界（最後 4B）
- **非對齊 / byte / half**（若契約禁止 → 期望 SLVERR；若允許 → bit-exact）
- **I 與 D 交錯**、連續 D 讀中插入 I-fetch
- **寫 XIP 窗 → 錯誤回應**
- **offset ≥ flash 映像 → 錯誤**
- cold（reset 後首讀）/ warm（已 continuous）

沒有交錯與 write-err，**arbiter + continuous-read 主風險未測**。

**V2 — gate_86 權威夠，但成功判準要防假綠**

- 「完整 q_proj 卸載 + scoreboard + vs gate_46」— 好。
- 必須固定：`HOST_RESET_PC=0x4000_0000`、**指令與常數皆在 flash 映像**（不可一半仍靠 sim imem 偷渡）。
- **超時**：XIP 很慢，TB timeout 要比 imem-boot 大一個數量級，否則 timeout≠功能錯。
- 標明：**非 performance gate**。

**V3 — gate_87 綁 UART+CLINT 合理，但缺接線級**

- UART TX scoreboard + THRE→PLIC claim/complete — 好。
- CLINT mtimecmp→mtip→trap — 好。
- 缺：**msip 軟中斷**（若 CLINT 實作有 msip，應至少 directed 一條；若 host 暫不用可標 optional）。
- 缺：**mtip 在 CLINT 未編程時保持 0**（防 tie-1 殘留）。

**V4 — 缺少「整合 smoke」或 gate_86 的擴充聲明**  
建議：gate_86 或 gate_88 覆蓋 **XIP boot → UART 一序列 → CLINT 可選 → NPU offload**。拆 gate 可以，**合成路徑要有人跑**。

**V5 — 誠實界已寫對的，再釘死**

- 本線 QSPI **無** 與 Coral 對等宣稱 — 好。
- Spike lockstep **不含** 周邊 MMIO 行為細節 — 好；device 域用 scoreboard。
- **不得** 用 TB 旁路 SPI 去「加速」gate_86 卻仍稱 XIP-boot（例如 force 記憶體進 imem）。

**V6 — 不需要、也別假裝有的**

- 全 flash JEDEC/SFDP 合規套件 — P0 不需要。
- 真 flash 板級 — 非 RTL gate。
- Quad/prog — P2。

---

## 5. 總表：阻斷 vs 非阻斷

| ID | 級 | 問題 | 要求 |
|---|---|---|---|
| R1 | **阻斷 ADR** | I/D 匯合、單 outstanding、I 優先對 runtime 的語意未凍結 | 寫死：QSPI 前端拓樸圖；I/D 互斥假設或允許交錯；寫窗→err |
| R2 | **阻斷 gate 契約** | 同 ELF 雙 boot 路徑、flash depth vs 16MB 窗 | linker/VMA；oversize→SLVERR |
| R3 | **誠實界** | 無 prog = 不能「現場自更新」 | ADR 寫「預燒 flash」 |
| V1 | **阻斷 gate_85 定義** | 缺 I/D 交錯、write-err、對齊策略 | 補進 §5.2 |
| V2 | 強化 | gate_86 timeout / 非 perf | 一句話 |
| 接線 | **P0 實作必查** | mtip/msip 真接、PLIC bit1 | checklist |
| 合成 smoke | 強烈建議 | 部署主路徑一條龍 | gate_86 擴充或 gate_88 |

---

## 6. 建議裁示（給 User）

1. **接受** 分級 P0=XIP+UART+CLINT、P1=debug/GPIO、P2=quad/prog；`0x4000_0000`；`HOST_RESET_PC`；不搬 64-bit M6 AXI ROM。  
2. **ADR 定稿前補**：I/D→QSPI 拓樸 + 對齊/寫語意 + flash depth 錯誤 + 預燒假設 + SCLK 分頻預設。  
3. **gate_85 必須含 arbiter 壓力與 write/off-window/oversize err**；gate_86 鎖定同 ELF、純 XIP 取指、非 perf。  
4. **M6 QSPI 當 unproven IP 接入**；本線 DV 為唯一放行條件。  
5. 補完上述後可進 RTL（adapter + arbiter + decode 加寬 + 掛 uart/clint）；**沒有 flash model + gate_85 骨架就不要合入 main 當「已支援 XIP」**。

---

**Bottom line：** 架構主軸（XIP 窗避開 0x8000、I 優先 2:1、RESET_PC 參數、Lite RO adapter、本地 UART/CLINT）是 sound 的。真正問題不在「要不要 XIP」，而在 **I/D 仲裁語意、continuous-read 切換、未驗證 IP、以及 gate_85 是否測到主風險**。補齊 R1/R2/V1 後可以放行實作；其餘是誠實邊界與 bring-up 品質，不是方向錯誤。
