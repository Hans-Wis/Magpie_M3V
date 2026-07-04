# ADR-0040 — Phase 4 續:矩陣引擎 64 → 256 MAC/cycle(Coral 算力對等)

- Status: **ACCEPTED**(§2 per-phase 架構確認;User 裁示 2026-07-04「先(b) 64→256 MAC」)。
  Mode:PL design,Grok pre-critique(採納表列於下)+ Codex post-review。
- Date: 2026-07-04
- Relates: ADR-0037(引擎 v1 + 凍結 requant)、ADR-0039(LOADACC/TFLM lowering)。

## Coral 對照(§2 第 1 問)

Coral/Kelvin 公開數字:**512 GOP/s @ 256 MAC/cycle、int8→int32、acc 8×8×32b**。
v4 §06(SSOT 設計基準)同規格且註明 **stripmine:1 次 dispatch → 4 筆序列化 issue**——
即 8×8 acc tile,每拍消耗 **4 個 outer products(4 k-steps)= 256 MACs**。
現況引擎為每 ~5 拍 1 個 outer product(4×32-bit TCM 讀 + 1 MAC 拍)≈ 12.8 MAC/cycle
——語義對、算力差 20 倍,是 §3 列 3 的殘餘紅字。

**對等分級(Grok 採納,誠實框架)**:
- **Class A(workload 契約)**:int8 outer-product matmul + acc + requant + CQ 卸載——本 ADR 補齊到
  256 MAC/cycle,descriptor/SSOT/firmware 全不動(stripmine 藏在引擎內)。
- **Class B(微架構)**:Coral 文獻是 128-bit 記憶埠;我們用 **2×256-bit 組合讀埠**(單拍餵滿
  4 lanes)——**顯式偏離**,以「banked single-cycle SRAM(聚合 512-bit/cycle)」為架構假設;
  weight-stationary / 128-bit double-buffer 是 Phase 7/P1 的收斂路徑,不擋 compute 契約。

## 契約(§2 第 2 問)

1. **Descriptor/SSOT/firmware 零改動**:RPT 仍=總 outer products;引擎內部跑 `ceil(rpt/4)` 個
   fused 拍。CFG.K=a-bytes 不變(ADR-0039)。
2. **引擎微架構**:S_RD+S_MAC 摺成單一 **S_RUN**:每拍自兩個 256-bit 埠讀 4 個 a-向量(32B)+
   4 個 b-向量(32B),對全部 64 個 (r,c) 做 `acc += Σ_{j<4} a_j[r]·b_j[c]`(**全 signed 樹**:
   int8×int8→int16,4-lane 有號和→int32,再 wrap 加進 acc);指標每拍 +32B。
   **Tail(rpt%4≠0)**:末拍以 lane-enable 對全部 64 cell 一致遮罩(非只凍結指標)。
3. **對齊收緊**:MAT.OP 的 a/b 與 LOADACC 的 fold 指標由 4B 收緊為 **32B 對齊**(param err;
   banked-SRAM 誠實);既有全部使用點(0x600/0x680/0x6C0/0x840)已對齊。
4. **LOADACC 單拍化**(8 words 經 a-埠一拍全載)。RESCALE/CLR/abort 語義不變;abort 中的
   partial acc 屬 ADR-0038 batch-poison ABI(已文件化)。done 與 acc 寫同緣(NBA 序,後續
   RESCALE 讀到最終值)。

## 驗證計畫(§2 第 3 問)

權威 = **既有 bit-exact 證據鏈全部原樣重跑**(語義不許動):gate_45(90 corners + 24 隨機序列,
含 rpt%4≠0 的 tail 位元真值)、gate_46(CQ e2e vs mat_golden)、gate_48(TFLM 六 corner)。
**新增 throughput 檢查(green-wash 守衛——語義綠不代表算力綠)**:單元 TB 量 GO→done 拍數,
`rpt=64 ≤ 16+6`、`rpt=65 ≤ 17+6`(強制 tail 路徑);量測在引擎邊界,不含 CQ/DMA 噪音(Grok (c))。
全套回歸 0 新增失敗。

## Grok 批判處置

採納:tail 遮罩全 cell 一致、全 signed 樹、RPT 語義不得重定義為 fused-cycle 數、32B 對齊入
param、throughput bound +6 首落地、rpt=65 tail case、Class A/B 誠實框架、abort/done 條款寫明。
駁回:無(其 (a)(d) 條款全部可落地)。
