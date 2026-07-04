# 功能補齊路線圖(User 裁示 2026-07-04:先功能 → 再架構優化 → 最後 VCS/Spyglass/coverage)

目標:把 §3 四個 PARTIAL 列的功能殘項收掉,期間**不動**微架構形狀(外掛 MAC、單發 scalar 維持;優化評估見 docs/reviews/2026-07-04_control_path_and_mac_scaling_grok.md)。

| 順位 | 項目 | 列 | 規模 | ADR/gate |
|---|---|---|---|---|
| 1 | hard vs soft reset 區分 | 6 | 小 | ADR-0047 / gate_54 |
| 2 | trace v1:rvfi_insn + mem trace + mtval/mstatus | 8 | 中 | ADR-0048 / gate_55 |
| 3 | Zve32x 指令面補全(mask/fixed-point/strided-indexed/slides/…,以 Spike lockstep 分族收) | 2 | 大 | ADR-0049+ / gate_56+ |
| 4 | scalar F(RV32IMF,Spike lockstep) | 1 | 最大 | ADR-005x / gate_5x |

完成定義:各列殘項備權威證據後升級;§3 全列 GREEN-leaning 才進架構優化評估。
