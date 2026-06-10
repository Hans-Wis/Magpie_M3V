Magpie-M1 計畫目標

• 依據 /docs 目前可確認的 Magpie_M1 CPU IP 開發計畫目標如下。

  總目標

  建立一顆 evidence-first 的 Magpie_M1 CPU IP，作為 AI Design IDE CPU IP 開發流程範例。流程要求每個階段都必須有可重跑證據，不得把未執
  行 gate 標成 PASS。

  主要來源：
  docs/ai_design_ide_rv32imac_proposal.md:1、
  docs/adr/0001-isa-scope.md:1

  目前已知計畫目標

  1. ISA 目標
      - active 目標：RV32IMC_Zicsr_Zifencei, M-mode only
      - ADR-0001 已標為 superseded-for-implementation
      - ADR-0002 已 accepted，lab08e 是 active implementation baseline
      - A 延後為 roadmap，需要 ADR/gate/DV/coverage closure。

  2. Reference policy
      - RISC-V spec 是架構權威來源。
      - CVA6、Rocket、X1、Ch2 lab、其他開源 CPU 可作為合法參考。
      - 若參考內容影響決策或實作，需記錄 provenance、license 約束與 Magpie_M1 自身驗證證據。
      - 直接納入第三方 RTL 需要 license review + ADR/waiver。
      - ISA scope、CSR policy、misaligned policy、C/A 支援策略都要進 ADR。

  3. 微架構目標
      - active 目標是 Ch2 `lab08e` 衍生 4-stage pipeline。
      - 包含 fetch/RV32C/pre-fetch、decode、execute、memory、writeback、CSR/trap、commit trace。
      - pipeline hazard、forwarding、flush、wrong-path suppression 都是 active sign-off 必要項。
      - pipeline target 已整合 Ch2 `lab08e` 到 `IP/cpu_m1/rtl`，目標是把 4-stage + BP + RAS + RV32C + pre-fetch 從 lab 變成實用 IP。
      - `lab08b` 仍保留為較小 RV32IM pipeline checkpoint。
      - v2 qualification 需另跑 RV32C/pre-fetch/RAS/BP、pipeline hazard/forwarding/flush/commit arbitration、Spike lockstep、coverage、lint/PPA gates。

  4. 記憶體介面目標
      - ADR 推薦 CPU IP v1 先用 standalone imem / dmem simple valid/ready protocol。
      - AXI4-Lite/AXI4 adapter 屬於後續 integration stage。
      - Proposal gate 目標包含 aligned/halfword fetch、load/store byte lane、misaligned policy。

  5. Privilege / CSR / Trap 目標
      - 支援 Zicsr。
      - 支援 selected M-mode subset。
      - 測試範圍包含 ecall、ebreak、illegal instruction、mret、interrupt timing。
      - 需要明確定義 mepc、mcause、mstatus、trap PC 行為。

  6. RVC 目標（roadmap）
      - 支援 compressed instruction fetch/decompress。
      - 需驗證 16-bit fetch alignment、illegal compressed encoding、PC +2/+4。
      - Spike lockstep 必須通過 compressed directed tests。

  7. RV32M 目標
      - 支援 multiply/divide/remainder。
      - 測試需包含 div-by-zero、overflow、mul/div busy/stall、result commit。
      - Gate 要求 M tests Spike lockstep PASS。

  8. RV32A 目標（roadmap）
      - RV32A atomic 延後，不屬 v1 sign-off。
      - 需要 atomic memory model、reservation scoreboard、LR/SC success/fail、AMO read-modify-write。
      - 若升級為 scope，需獨立 ADR、reservation/AMO scoreboard、Google RISC-V DV constraint 與 coverage closure。

  9. DV / Verification 目標
      - Directed ISA bring-up。
      - Spike ISS per-commit lockstep。
      - Google RISC-V DV constrained random。
      - riscv-arch-test 作為 stretch architecture compatibility gate。
      - RVFI-lite commit trace 作為 directed、lockstep、coverage triage、formal 的共同觀察點。
      - riscv-formal selected checks 屬 stretch：RV32I/M、register consistency、PC progression、unique retire、selected CSR checks。

  10. Coverage / Quality 目標

  - Line coverage 100%；若未達 100%，必須列出每個 uncovered line 的原因、可達性、補測計畫或 waiver
  - Toggle coverage >= 85%
  - Functional coverage >= 95%
  - Architecture compatibility supported groups 100% pass
  - Selected formal RVFI checks 100% pass
  - Spyglass high/critical unwaived issues 0
  - Sign-off Google RISC-V DV mixed tests 10,000+
  - FPGA-based PPA evaluation：LUT/FF/BRAM/DSP、timing/Fmax、optional power 與 regression delta

  11. Evidence-first / AI Design IDE 目標

      - 每個 development gate 必須產生 spec、ADR、RTL、log、VCD、coverage、DV result、risk、waiver。
  - AI Design IDE 顯示 RTL、block diagram、simulation artifacts、waveform、PM rollup、gate matrix。
  - 主要 artifacts：
      - tests/gates/gate_*.py
      - flow/state/*.state.json
      - flow/sim/**/*.log
      - flow/sim/**/*.vcd
      - IP/cpu_m1/rtl
      - IP/cpu_m1/docs/spec.md
      - flow/coverage
      - dv/riscv-dv/out

  12. Development Gate 目標

  下列 gate 是由 ADR-0001 的 ISA scope 與 v1 multi-cycle FSM 微架構推導，不是固定數字，也不是 pipeline stage。

  - 00 ISA scope
  - 01 Fetch
  - 02 Decode/execute
  - 03 Core assembly
  - 04 CSR/trap
  - 05 Memory
  - 06 Spike lockstep
  - 07 Coverage
  - 08 Lint/synth sign-off

  13. 建議里程碑

  - M0 Flow bootstrap: gate_00_spec、AI Design IDE discovery、state JSON、proposal
  - M1 RV32I/M bring-up: fetch/decode/execute directed tests PASS
  - M2 Core correctness: core FSM/memory/CSR/trap/interrupt closure
  - M3 Random DV: Google RISC-V DV + Spike lockstep seed ladder
  - M4 Sign-off pack: coverage、Spyglass、waiver、handoff HTML/Markdown

  專業判斷

  目前文件已採 Option 1 修正版：ADR-0001 的 greenfield FSM 實作線已 superseded，ADR-0002 將 Ch2 lab08e 升為 Magpie_M1 active implementation baseline。主線 scope 是 RV32IMC_Zicsr_Zifencei、M-mode、4-stage + BP + RAS + RV32C + pre-fetch。後續需建立 wrapper 與完整 pipeline qualification gates；A、formal、arch-test、CoreMark、ASIC PPA 維持 roadmap/stretch，除非另開 ADR 提升 scope。
