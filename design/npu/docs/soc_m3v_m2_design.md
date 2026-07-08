# soc_m3v_top M2 — 兩-bus 結構重構 + PLIC/IRQ（解 meip-tie）· for review

- **Status:** DESIGN（待 Grok 架構 + Codex 整合實況 review）· 2026-07-08 · Claude
- **上位:** ADR-0068（SoC 系統框架 §2.5 兩-AXI）· 承 M1 `soc_m3v_top`（@eba4046,polling）
- **鐵律:** 全用本地 IP（`design/cpu_m1` + `design/npu` + `design/soc`）,不參考 repo 外目錄;功能權威 = IRQ-driven e2e bit-exact vs gate_46 golden + 既有單元 gate 零回歸。

---

## §0 M2 範圍（承 M1）

M1（@eba4046）已證:真 cpu_m1 host 經真 AXI fabric 驅動 NPU 卸載,**polling** STATUS.done,結果 bit-exact。
M2 做兩件事:
1. **兩-bus 結構重構**（ADR-0068 §2.5,仍 32-bit——結構先行,寬度 M3 才動）:把 M1 單-fabric 明確切成
   **控制 AXI**（host→NPU CSR/TCM + PLIC）+ **資料 AXI**（npu_dma + host-bridge → SRAM）+ 具名 **bridge**。
2. **PLIC/IRQ**（解 M1 遺留 P0）:`cpu_m1_axil_top` 綁 `.meip(1'b0)` → 換真 IRQ 路,NPU done → PLIC → host meip → trap。
   firmware 由 polling 換 **interrupt-driven**（WFI + trap handler）。

## §1 Coral 對照

Coral 卸載迴圈:`doorbell → DMA → compute → **IRQ** → host`。M1 我們用 polling 頂替 IRQ（功能等價但非 Coral 形狀）。
M2 補上真 IRQ:NPU 完成 → level IRQ → PLIC 彙整 → host M-mode external interrupt（meip/mip[11]）→ trap handler。
**與 Coral 可取代性:** 卸載完成通知從 polling 升為真中斷,對齊 Coral 的 IRQ-driven host 迴圈（§3 卸載列的「IRQ」子項）。

## §2 兩-bus 結構（M1 已有雛形,M2 具名）

M1 現況已含 proto-bridge（host 0x8000 寫入經 `axil_to_full` → arbiter 的 host leg 進資料側 SRAM）。M2 明確分域:

```
  ┌──────────────── 控制 AXI（窄 32b,低頻寬）────────────────┐
  cpu_m1(host) M_AXI_D → soc_axil_decode →
       0x3000 → npu_top.s_axi（CSR/DTCM/ITCM）
       0x0c00 → plic_axil_shim → plic（native）          ← M2 新增
       0x8000 → [BRIDGE] axil_to_full → 資料 AXI arbiter host leg
  └──────────────────────────────────────────────────────────┘
  ┌──────────────── 資料 AXI（寬-capable,32b now）───────────┐
       axi_full_arbiter_2x1（非搶占）:
          master0 = npu_dma（AXI4-full）
          master1 = host bridge（axil_to_full）
          → axi_full_sram @0x8000（weights+CQ+結果）
  └──────────────────────────────────────────────────────────┘
  IRQ 路（M2 新增,獨立於 AXI）:
       npu_top.irq → plic.sources[0] → plic.meip_o → cpu_m1_top.meip
```

**結構動作:** M1 的 `soc_axil_decode` 加 0x0c00 分支;`axil_to_full`+arbiter host leg 註記為 bridge（無 RTL 改,命名/文件）。
控制/資料分域在 M2 是**邏輯分界 + PLIC 掛控制側**;實體拓寬留 M3。

## §3 meip 解法（不改共用 IP,全本地）

`cpu_m1_top` 有真 `meip`（level 輸入,line 65 → csr mip[11]）。`cpu_m1_axil_top` 綁 `.meip(1'b0)`。
**選法:soc_m3v_top 直接實例化 `cpu_m1_top` + `axil_bridge`**（不經 cpu_m1_axil_top）,把 `plic.meip_o` 接到 `cpu_m1_top.meip`。
- 理由:不改 `cpu_m1_axil_top`（零 M1-SoC 回歸風險）、不新增共用-IP 埠、全本地在 soc_m3v_top 內兜線（~40 行,照 cpu_m1_axil_top 71-113 行 copy)。
- `axil_bridge` 介面已確認:native ibus/dbus ↔ M_AXI_I（RO）+ M_AXI_D（RW）。`cpu_m1_top`:`.meip(plic_meip)`、`.mtip(1'b0)`、`.msip(1'b0)`、`.irq_external_pulse(1'b0)`。
- **驗證債:** 動 host 實例化結構 → 必重跑 host lockstep 等價（ADR-0032）確認 core 行為不變（只是 meip 從常 0 變可 1）。

## §4 PLIC 整合

- **plic_axil_shim**（新,~60 行）:AXI-lite（0x0c00 段,來自 soc_axil_decode）→ plic native（en/addr/wstrb/wdata/rdata）。單-outstanding、combinational rdata → 小 FSM（AW+W→en+wstrb;AR→en+!wstrb;回 R/B）。
- **plic 接線:** `sources[0] = npu_top.irq`（ID 1;其餘 sources[6:1]=0）。`meip_o → cpu_m1_top.meip`。`rst = ~resetn`（plic 是 active-high reset,soc 用 resetn active-low）。
- **regmap（plic.v 凍結）:** priority[1]@0x0c000004、pending@0x0c001000、enable@0x0c002000、threshold@0x0c200000、claim/complete@0x0c200004。

## §5 IRQ firmware（host_producer_irq,interrupt-driven）

改 M1 的 poll 迴圈為中斷:
1. **trap setup:** 設 `mtvec`（handler）;`mie.MEIE`（bit 11）=1;`mstatus.MIE`=1。（模仿 `design/npu/sw/cq_sequencer/trap_test.S`。）
2. **PLIC config:** priority[1]=非零(如 1);enable[1]=1;threshold=0。
3. **NPU:** 載 fw + 寫 CQ/運算元 + `CTRL.irq_enable`(bit3)=1;fence;doorbell(TAIL)。
4. **等待:** `wfi` 迴圈（非 poll STATUS!）。
5. **handler:** PLIC claim(讀 0x0c200004 得 source id)→ 驗 id==1 → 讀 NPU STATUS 確認 npu_done → `CTRL.irq_clear`(bit1,清 irq_pending)→ PLIC complete(寫回 id)→ 設 `irq_seen` flag → mret。
6. **main:** wfi 醒後見 flag → 讀結果 0x1800 → DONE marker。

## §6 驗證計畫

- **soc IRQ smoke（gate_soc_m3v_irq）:** 同 M1 卸載,但 **interrupt-driven**;結果 bit-exact vs gate_46 `_golden_tile`（bytes=64）。
- **green-wash 守衛:**
  - 必**真中斷**:host 走 `wfi` + trap（非 poll STATUS.done）。TB 觀察 `npu_irq` 拉高 + host 進 trap（dbg_pc 跳 mtvec）方算數。
  - IRQ 必經真 PLIC（meip_o）→ 真 cpu_m1_top.meip;非 TB force。
  - 結果仍由 NPU DMA 寫回,非 host 塞 golden。
- **回歸:** gate_45/46/soc_m3v_smoke（M1 polling）全綠;host lockstep 等價（meip 結構改）。

## §7 開放問題（給 review）

1. **meip 解法:** soc_m3v_top 直接 cpu_m1_top+axil_bridge（本案）vs 新 wrapper `design/soc/cpu_host_irq.v`（可復用但多一檔）vs 改 cpu_m1_axil_top 加 meip 埠（動共用 IP)?本案傾向直接兜（零共用-IP 改）。
2. **plic reset 極性 + sources 寬:** plic `rst` active-high、`sources[6:0]`;只用 sources[0]=npu_irq,其餘綁 0——確認無 spurious。
3. **level vs pulse:** npu_top.irq 是 level（irq_pending&en）;PLIC sources 是「level→edge sticky」。claim/complete + CTRL.irq_clear 的清除次序:先清 NPU irq_pending 再 PLIC complete,或反之?防重入/遺漏。
4. **WFI 語義:** 此 cpu_m1 的 wfi 是否真停 + meip 喚醒?若 wfi 未實作可退化為「mstatus.MIE + 空迴圈等 flag」(仍中斷驅動,handler 設 flag)。Codex 確認 RTL wfi 行為。
5. **保留 M1 polling gate:** M2 新增 irq gate,M1 polling gate（soc_m3v_smoke）保留當回歸——確認兩路並存。

## §8 Review resolutions（Grok APPROVE-WITH-CHANGES + Codex needs-changes,2026-07-08）

兩份 review 收斂,方向 APPROVE,以下為定案（RTL 實況 by Codex,含 file:line）:

1. **meip 路 CONFIRM**:`meip` level → `mip[11]=(ext_pending|meip)`（csr.v:241）,gate `mie.MEIE`+`mstatus.MIE`（csr.v:758/761）,cause `0x8000000b`（def.vh:218）→ `mtvec`（core.v:2275）。trap 真可取。
2. **P0 WFI 非法** → **不用 wfi**（idu.v:159/450 分類為 illegal SYSTEM,非 nop）。韌體改:`mtvec`+`mie.MEIE`+`mstatus.MIE` → doorbell → **spin-on-flag**（`while(!irq_seen);`,handler 設 `irq_seen`）。仍中斷驅動（trap 真發、走 mtvec）,只是空轉不睡。green-wash 守衛改為:TB 觀察 `npu_irq` 拉高 + host `dbg_pc` 跳 `mtvec`（證真 trap,非 poll STATUS）。
3. **P1 PLIC edge-sticky**（非 level-repend）:pending 只在 `sources & ~sources_d` 上升沿設（plic.v:74/138）;claim 讀清該 pending（plic.v:124/159）、complete 寫清（plic.v:148）。**故高電平 NPU irq 不會 re-pend**（Grok re-entry 疑慮消解）。**但**:handler **仍須** `CTRL.irq_clear`(bit1) 清 NPU `irq_pending` 讓 `npu_top.irq` 落下——否則下個 job 完成無新上升沿 → IRQ 遺失（多-job 必要;M2 單-job 也保留以正確）。次序:**claim → verify id → read STATUS → CTRL.irq_clear → PLIC complete → set flag → mret**。文件記 edge-sticky 契約。
4. **meip 實例化 CONFIRM**:soc_m3v_top 直接 `cpu_m1_top`+`axil_bridge`（不改共用 IP）。複製 cpu_m1_axil_top 的 ties:`irq_external_pulse`/`mtip`/`msip`/debug 輸入綁低、trace 輸出不接、保留 `dbg_axi_err`;**唯一改 `.meip(1'b0)`→`.meip(plic_meip)`**（cpu_m1_axil_top.v:82）。
5. **npu.irq CONFIRM+caveat**:`= ~hard_q & irq_pending & ctrl_q[3]`（npu_axil_regs.v:324,額外 hard-reset mask,文件記）。`STATUS[4]=irq_pending`、`CTRL[1]` W1-clear。
6. **P0 plic_axil_shim**:AXI-lite → native（en/addr/wstrb/wdata + 捕 rdata）。捕 AW+W → 脈 native write 一拍 → BVALID;AR（無 pending resp 時）→ 脈 native read → **同拍捕 combinational `plic.rdata`**（claim 讀的 pending-clear 在該 clock edge,rdata combinational 同拍有效）→ RVALID。**不同拍收 read+write**（擇一優先,另一 READY 壓低）。
7. **P0 整合缺口**（現況與 M2 衝突,必補）:soc_m3v_top 換 host 實例化;`soc_axil_decode` 加 `0x0c00` route → plic_axil_shim;gate 源列補 `axil_bridge`+`plic.v`+`plic_axil_shim`;plic `rst=~resetn`（active-high,已確認正確）;`sources[0]=npu_irq`（=ID 1,對 `prio[1]`/`enable[1]`;PLIC 註記舊 ID1=UART0 需清或記 M2 重用）。
8. **P1 跨-bus ordering ABI**（Grok）:控制-AXI doorbell 與 資料-AXI SRAM 寫無硬體全序 → 韌體 **fence 於最後 payload 寫與 doorbell 之間**（M1 已有 fence_all,M2 保留 + gate 記）。

**Green-wash 守衛（M2）**:①真中斷（host 走 trap→mtvec,非 poll STATUS.done;TB 驗 npu_irq↑ + dbg_pc 跳 mtvec）②IRQ 經真 PLIC meip_o → 真 cpu_m1_top.meip（非 TB force）③結果仍 NPU DMA 寫回。

**下一步:實作（Codex 外科,照 §8 定案）→ soc IRQ smoke bit-exact（真中斷路）+ M1 polling gate 保留回歸 + host lockstep 重驗 → commit。**
