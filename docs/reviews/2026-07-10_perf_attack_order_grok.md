# Grok 效能攻擊序分析 — HEAD 307,458/層(2026-07-10)

> `grok -p`,輸入=HEAD 熱點表+已證槓桿+約束。註:CLI 僅存留結論段(§5 gate/up 判決、執行序、seq 外推、三判斷題);前段逐項細算未落盤,結論已完整。


---

## 5) gate_proj / up_proj：現在要不要重打？

**帳**  
各 ~18k；ledger：**~187 cyc × 96 ops ≈ 18k** → 該步幾乎是 **per-op 固定稅**，不是 MAC 牆。全層 mat_engine busy 0.29% 與之一致。  
Fusion **~2%** → 融 gate/up 本身 **不是** 槓桿。

**判決**

| 情況 | 動作 |
|------|------|
| gate/up **尚未**走 q_proj 同款 **mat_engine v2 tile sequencer / 單次 launch 多 tile** | **應立刻 re-attack**，屬「套用已證明編排 HW」，不是 shared FW 瘦身。預期可比 q_proj 的 11.8× 低一階（形狀/K 不同），但仍可能 **18k→2–4k/步，兩步合計 −25–32k**。風險中、驗證中（路徑已有）。 |
| **已經**在 v2 上，18k 仍是 CQ/doorbell/CSR 結構稅 | **維持 defer** per-op FW 瘦身（高 blast radius、共享路徑）。下一槓桿是 **新編排契約**（cmd chain / fused FFN descriptor），走 §2 ADR，而不是先改 187 cyc 共享 FW。 |
| 想靠 RVV 重算 gate/up matmul | **否**——已有 256-MAC；把 matmul 搬回 RVV 是倒退。 |

**一句話**：  
- **重打「是否吃到 v2」= 現在該查、該做。**  
- **重打「共享 per-op FW 再砍 187」= 仍 defer**，除非獨立 microbench 證明 187 裡 >50% 是可刪死碼且不影響 host/CQ 契約。

---

## 依賴與建議執行序（concrete）

```
1. QK-norm RVV          # 最低風險，模板=RMSNorm，−24–32k
2. E1b ewise_mul        # 最大單步；先 RVV mul，requant 用 E1a 做 A/B
3. 查 gate/up 是否 v2   # 若否 → 套 tile-seq（潛在 −25–32k）；若是 → 記「結構稅」ADR，不砍 FW
4. RoPE RVV srdhm-split # 有 64b 難度；layout 先確認 unit-stride
5. Softmax recip        # seq=4 可做小步；為真實 seq 保命
// 並行 pending（不進本 ROI 主鏈但擋 full-model）：
//   H=640 RMSNorm/QK chunk · mat_engine K>64 multi-chunk (A.2)
```

**不要并行 1+2+4 同一驗證波**——rounding 爭議會交叉污染；QK-norm 與 ewise 可串行兩週內完成。

---

## seq 從 toy=4 長大時，誰變主犯？

**固定 per-layer（≈不隨 decode seq 長）**  
ewise_mul、gate/up、QK-norm（decode 上 Q 固定、K-norm 看實作）、FFN 相關：seq↑ 時 **占比下降**。

**隨 seq 升（decode + KV cache，單 token）**  
| 項 | 複雜度 | seq=4 | 粗外推（假設今日 softmax 7k 以 O(seq) 為主） |
|----|--------|-------|-----------------------------------------------|
| Softmax / scores reduce | O(seq) 或 O(H·seq) | 7k | seq=64 → ~0.1M 量級；seq=256 → 數 0.1M–1M 級（實作係數差很大） |
| Attn score/value 路徑（QKᵀ、AV，引擎或 RVV） | O(seq·d_h·heads) | 現在被 toy 壓住 | **很快超過 ewise 37k** |
| RoPE | decode 新 token O(d)；prefill O(seq·d) | 33k 偏 prefill/toy | **decode 反而不痛**；prefill 才痛 |
| DMA KV 搬運 | O(seq) | 小 | 中長 seq 可回到 orchestrate/DMA 牆 |

**結論（decode 真實 seq）**  
1. **Attention 帶寬 + score/softmax** 變第一名；E1b/QK-norm 的絕對省 cyc 仍在，但 **相對% 縮水**。  
2. Softmax 從「第 4 優先、+4–6k」變成 **必須項**；若不做 recip/表 + RVV，seq 數十即吞噬 RMSNorm+E1b 全部戰果。  
3. mat_engine **K≤64 單 chunk** 在長 seq 的 K 維/head 投影上會再爆 firmware 多 chunk 稅 → **Phase A.2 與 attn 編排** 的 ROI 隨 seq **單調上升**。  
4. gate/up 的 187×96 **不隨 seq 變** → 長 seq 時更不該優先砍 FW，除非 total layer 已被 attn 優完還要擠 FFN 固定稅。

**雙地平線策略**  
- **現在（ledger @ seq=4）**：QK-norm → E1b →（條件式）FFN v2 覆蓋 → RoPE。  
- **同時（小步預埋）**：Softmax 整數 recip 契約 + golden，避免 seq 一加大就整層改寫。  
- **seq 產品化**：attn matmul/tile-seq + A.2 multi-chunk + KV DMA 成為新 top-3；ewise/RoPE 變「已收固定成本」。

---

## 直接回答三個判斷題

1. **Next 3–5 by ROI**：① QK-norm RVV ② E1b ewise（RVV±requant engine）③ RoPE RVV ④ Softmax recip（絕對小、seq 戰略）⑤ gate/up **僅**在未吃 v2 時的編排套用。  
2. **gate/up per-op tax**：共享 FW 瘦身 **繼續 defer**；**先確認 v2 覆蓋**，未覆蓋則現在打編排，不是打 187。  
3. **seq↑**：**softmax + attention O(seq[/²])** 變支配；固定 FFN/ewise/norm 占比下降；RoPE 在 pure decode 降權、在 prefill 升權；A.2/長 seq tile 編排變硬需求。
