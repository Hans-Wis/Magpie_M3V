# V1 — 首份 ISA 指令覆蓋報告(ADR-0063)

> 日期 2026-07-06 · HEAD 待 commit · 權威 = Spike `--log-commits`(lockstep golden)·
> 工具 `flow/v2_pipeline/lib/isa_cov.py` · SSOT `flow/coverage/isa_scope.json` ·
> 收集 `flow/coverage/collect.sh` · 基準報告 `flow/coverage/isa_cov_report.json` · gate_90。

## 方法
Spike disasm 行(mnemonic + hex 編碼)= ISA golden。ingester 抽 mnemonic、把 pseudo 正規化到
base op(每個 pseudo 就是 base 指令執行:li→addi、csrs→csrrs、j→jal…)、按 extension 分桶對
SSOT。**誠實界**:scope-cut op 移出分母且**打到不給 credit**(G7);exclusion ledger 凍結(G6)。
**coverage = 完整度,非正確性**(lockstep 才是權威,G1)。

收集來源 = 全向量回歸(phase_22 的 35 targets)+ NPU core(phase_20 rv32im directed/random)+
既有 host scalar logs(phase_03/a3/…,涵蓋 RVC/Zbb/Zba/Zbs/Zicond/F)= **62 logs / 322 distinct
mnemonics**。

## 首份結果(全回歸 union)

| ext | in-scope | covered | cov% | 缺口 |
|---|---|---|---|---|
| i(RV32I)| 40 | 40 | **100%** | — |
| c(RVC,host)| 27 | 25 | 93% | c.jalr, c.jr |
| m(RV32M)| 8 | 8 | **100%** | — |
| f(RV32F)| 26 | 26 | **100%** | — |
| zicsr | 6 | 4 | 67% | csrrci, csrrsi |
| zifencei | 1 | 1 | **100%** | — |
| zba | 3 | 3 | **100%** | — |
| zbb | 18 | 18 | **100%** | — |
| zbs | 8 | 8 | **100%** | — |
| zicond | 2 | 2 | **100%** | — |
| priv | 2 | 1 | 50% | wfi |
| **zve32x** | **261** | **181** | **69%** | 80 forms(見下)|
| **TOTAL** | **402** | **317** | **79%** | |

**exclusions(scope-cut,移出分母)= 32**:strided(vlse/vsse)、indexed(vluxei/vsuxei/…)、
fault-only-first(vle*ff)、mask ld/st(vlm/vsm)、whole-reg ld/st(vl1r/vs1r…)。無 excluded op
被打到(誠實界通過)。**surprises = 5**(c.fsd/c.subw/c.unimp/unknown/xperm4)= data 區被 disasm
成 RV64/D/crypto 的假象,無 credit。

## Zve32x 80 缺口 = 閉合 backlog(已分類)
| 類別 | 數 | 例 | 性質 |
|---|---|---|---|
| **segment nf×eew 矩陣** | ~42 | vlseg3e16.v, vlseg5e8.v, vsseg6e32.v… | 通用實作(nf2-8×eew,已測代表)→ **低值,representative-coverage waiver 候選** |
| **op 未測 form(.vi/.vx/.vv)** | ~32 | vand.vi, vsll.vi, vsrl.vi, vaadd.vx, vasubu.vx, vmsgt.vi, vmsle.vx… | **可閉合**:對已實作 op 補 .vi/.vx directed(小工作)|
| **narrow/widen .w* form** | 6 | vnclip.wv/.wx, vwaddu.wx, vwsub.wx… | 可閉合,補 directed |

## 判定
- **scalar ISA(host RV32IMC+Zba/Zbb/Zbs+Zicond + NPU RV32IMF)= 幾近全覆蓋**(i/m/f/zba/zbb/
  zbs/zicond/zifencei 100%;小缺 c.jr/c.jalr、csrrci/csrrsi、wfi)。
- **Zve32x = 69%**:主缺口 = segment 矩陣(低值)+ 30+ op-form(可閉合)。
- **零 excluded-op credit、ledger 凍結** → 誠實界守衛通過。

## 下一步(V1 閉合 + 續)
1. **閉合 op-form 缺口**:對 vand/vsll/vsrl/vsadd/vsaddu 的 .vi、averaging 的 .vx、compares 的
   .vx/.vi、narrow 的 .w* 補 directed(每個仍 Spike-lockstep,G2)→ zve32x 拉到 ~85%+。
2. **segment 矩陣**:決定 representative-coverage waiver(ADR-ID)或補幾個 nf×eew corner。
3. **scalar 小缺**:c.jr/c.jalr(host RVC register-jump)、csrrci/csrrsi、wfi —— 補 directed 或
   誠實列為 not-emitted。
4. **續 V2(Spyglass)/ V3b(整合 top)** 平行。
- gate_90 已把**基準凍結**(scalar 100% + zve32x≥181 + ledger=32 + 零 excluded-hit),日後只准
  ratchet up。
