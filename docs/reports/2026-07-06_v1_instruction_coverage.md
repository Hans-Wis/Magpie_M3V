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

## V1 閉合(完成)= zve32x 69%→87%,non-segment op-level 100%
`firmware_cov.S`(phase_22 `make cov`)系統性打過 **45 個未測 op-form**(.vi/.vx/.vv/.w*),
每個 vse+lw 觀察 → **Spike-lockstep 176 commits 全符**(G2:執行 **且** 驗證,非 toggle-only)。
涵蓋:vand.vi/vsll.vi/vsrl.vi、vor.vx/vmax[u].vx/vmin[u].vx/vremu.vx、compares 全 .vx/.vi/.vv、
vmnor.mm、vmerge.vxm/.vim、averaging 全 .vx/.vv、saturating .vx/.vi、scaling vssrl/vssra .vv/.vx、
widening vwadd.vx/vwsubu.vx/vwaddu.wx/vwsub.wx、narrowing vnclip[u].wv/.wx。

**閉合後(全回歸 + cov)**:
| | 覆蓋 |
|---|---|
| Zve32x(raw)| **226/261 = 87%** |
| **Zve32x non-segment(op-level,segment 矩陣 representative-waived)** | **226/226 = 100%** |
| TOTAL(raw)| **362/402 = 90%** |

**剩 35 = 全 segment nf×eew 矩陣**(`vlseg3e16.v`…)。**representative-coverage waiver(ADR-0063)**:
segment 由**單一通用 vmem-FSM** 處理所有 nf×eew(gate_78 e2 已測 nf2-4/e8 + nf2 e16/e32 + m2/m4
群組代表);其餘組合 covered-by-construction,測全 42 為低值冗餘。**op-level 已無缺口。**

## scalar 殘項閉合 → RV32IMC 100%(完成)
`phase_03_20_isacov_host`(clone phase_03_00 rv32imc lockstep harness)+ `firmware.S` directed:
c.jalr(indirect call `jalr a0`→16-bit)、c.jr(computed jump `jr a1` + compressed `ret`)、
csrrsi/csrrci(CSR-immediate,rd≠x0 保 base mnemonic)。**DUT lockstep 13c PASS(G2:DUT 驗證
非 Spike-only)**。
- **c: 25→27/27 = 100% ; zicsr: 4→6/6 = 100% → RV32IMC = 100%**(i/m/c 全 100%)。
- **殘 = wfi(priv,50%)**:**非 RV32IMC**(privileged hint,需 IRQ-wait 情境)——不影響 IMC 100%
  宣稱,列 priv 桶低值 nice-to-have。
- **附帶 lint 修**:vexu.v vcompress `vs1_data[cpi[3:0]]`→`[cpi[6:0]]`(128-bit 索引寬度,消
  WIDTHEXPAND,為 V2 Spyglass/VCS lint 鋪路;值不變,vcompress gate_81/cov/vrand 全綠)。
- **harness 修**:old tb_spike_lockstep 對 x0-dest jump(c.jr/ret)記 writeback bus,RVFI 應為 0;
  comparator local 遮罩 rd==0 wdata(架構 don't-care)→ lockstep PASS。加 `-Wno-PINMISSING`
  (老 TB 未接 core 新增 RVFI/RVVI trace ports,ADR-0045/0048 漣漪)。

## 最終覆蓋(全回歸 + cov + host closure)
| ext | 覆蓋 |
|---|---|
| **RV32IMC(i+m+c)** | **100%** |
| f / zba / zbb / zbs / zicond / zifencei / **zicsr** | **100%** |
| priv | 50%(wfi,非 IMC)|
| **Zve32x non-segment(op-level)** | **100%**(226/226)|
| Zve32x raw | 87%(226/261;剩 35 = segment 矩陣 waiver)|
| **TOTAL** | **91%**(366/402)|

## 下一步(續)
- **V2(Spyglass lint/RDC)/ V3b(整合 soc_m3v_top)/ V5(Verilator code-cov)** 平行。
- gate_90(7 tests)凍結:scalar+**RV32IMC+zicsr 100%** + non-segment zve32x 100% + cov/host
  lockstep(G2)+ ledger=32 + 零 excluded-hit。只准 ratchet up。
