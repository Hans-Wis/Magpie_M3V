# =============================================================================
# Phase 2 Step 4 — NPU sequencer lockstep (ADR-0034): Verilator npu_top DUT +
# Spike rv32im golden + riscv64-unknown-elf-gcc firmware. One-command rerun.
#   make directed                 -> firmware_directed.S, bar >=500 commits
#   make random SEED=n            -> loop-wrapped rv32im random, bar >=10000 commits
# =============================================================================
TOOLCHAIN_DIR    = /home/edauser/miniforge3/pkgs/riscv-tools-1.0.6-0_h1234567_g56c29e0/riscv-tools/bin
TOOLCHAIN_PREFIX = $(TOOLCHAIN_DIR)/riscv64-unknown-elf-
TOOLCHAIN_LIBS   = /home/edauser/miniforge3/pkgs/mpfr-4.2.2-he0a73b1_0/lib:/home/edauser/miniforge3/pkgs/gmp-6.3.0-hac33072_2/lib:/home/edauser/miniforge3/pkgs/mpc-1.4.0-he0a73b1_0/lib
TOOLCHAIN_ENV    = LD_LIBRARY_PATH=$(TOOLCHAIN_LIBS)

VERILATOR ?= /home/edauser/miniforge3/envs/magpie_claude/bin/verilator

# NPU sequencer contract (ADR-0032/0034): rv32im, NO C — green-wash guard
GCC_MARCH = rv32im_zicsr_zifencei
GCC_MABI  = ilp32

CPU_RTL_DIR = ../../../IP/cpu_m1/rtl
NPU_RTL_DIR = ../../../IP/npu/rtl
CPU_SRCS = $(addprefix $(CPU_RTL_DIR)/, rfu.v alu.v bmu.v idu.v ifu.v lsu.v csr.v \
           trigger.v pmp.v mul.v div.v forward.v hazard.v bp.v ras.v cdec.v vexu.v core.v cpu_m1_top.v)
NPU_SRCS = $(addprefix $(NPU_RTL_DIR)/, npu_top.v npu_axil_regs.v npu_dma.v npu_tcm.v axil_decerr.v)
TB_RTL   = tb_npu_lockstep.v

SEED  ?= 20260703
COUNT ?= 96
ITERS ?= 110
MAX_CYCLES ?= 1000000

VFLAGS = --binary --timing -j 4 \
         --top-module tb_npu_lockstep \
         --timescale 1ns/1ns \
         -I$(CPU_RTL_DIR) \
         -Wno-fatal -Wno-DECLFILENAME -Wno-TIMESCALEMOD \
         -Wno-UNUSEDSIGNAL -Wno-SYNCASYNCNET

SIM_BIN = obj_dir/Vtb_npu_lockstep

# coverage-instrumented build (ADR-0034 strip-coverage bar, gate_34)
VERILATOR_COV ?= $(VERILATOR)_coverage
COV_BIN = obj_cov/Vtb_npu_lockstep
VFLAGS_COV = $(subst -j 4,-j 4 --coverage-line,$(VFLAGS)) -Mdir obj_cov

.PHONY: all directed random coverage clean

all: directed

directed:
	$(MAKE) FW_ASM=firmware_directed.S MIN_COMMITS=500 lockstep.log

random: firmware_rand.S
	$(MAKE) FW_ASM=firmware_rand.S MIN_COMMITS=10000 lockstep.log

.PHONY: firmware_rand.S
firmware_rand.S: gen_npu_random_program.py
	python3 gen_npu_random_program.py --seed $(SEED) --count $(COUNT) --iters $(ITERS) --out $@

FW_ASM ?= firmware_directed.S
MIN_COMMITS ?= 500

# firmware outputs are PHONY: FW_ASM changes between directed/random invocations,
# so timestamp-based rebuild would silently reuse the previous program image.
.PHONY: firmware.elf firmware_spike.elf firmware.hex firmware.disasm

firmware.elf: $(FW_ASM) firmware.lds
	$(TOOLCHAIN_ENV) $(TOOLCHAIN_PREFIX)gcc -Os \
	    -march=$(GCC_MARCH) -mabi=$(GCC_MABI) \
	    -nostartfiles -nostdlib -ffreestanding \
	    -Wl,-Bstatic,-T,firmware.lds,--strip-debug \
	    -o $@ $(FW_ASM)

firmware_spike.elf: $(FW_ASM) firmware_spike.lds
	$(TOOLCHAIN_ENV) $(TOOLCHAIN_PREFIX)gcc -Os \
	    -march=$(GCC_MARCH) -mabi=$(GCC_MABI) \
	    -nostartfiles -nostdlib -ffreestanding \
	    -Wl,-Bstatic,-T,firmware_spike.lds,--strip-debug \
	    -o $@ $(FW_ASM)

firmware.hex: firmware.elf
	$(TOOLCHAIN_ENV) $(TOOLCHAIN_PREFIX)objcopy -O verilog --verilog-data-width=4 $< $@

firmware.disasm: firmware.elf
	$(TOOLCHAIN_ENV) $(TOOLCHAIN_PREFIX)objdump -d $< > $@

$(SIM_BIN): $(TB_RTL) $(NPU_SRCS) $(CPU_SRCS)
	$(VERILATOR) $(VFLAGS) $(NPU_SRCS) $(CPU_SRCS) $(TB_RTL)

.PHONY: sim.log
sim.log: $(SIM_BIN) firmware.hex firmware.disasm
	./$(SIM_BIN) +max_cycles=$(MAX_CYCLES) +min_commits=$(MIN_COMMITS) | tee sim.log
	@grep -q '^PASS' sim.log || (echo "FAIL: sim did not report PASS" && exit 1)

.PHONY: lockstep.log
lockstep.log: sim.log firmware_spike.elf npu_lockstep.py
	python3 npu_lockstep.py --min-commits $(MIN_COMMITS) --instructions 20000 | tee lockstep.log
	@grep -q '^PASS' lockstep.log || (echo "FAIL: lockstep did not report PASS" && exit 1)

$(COV_BIN): $(TB_RTL) $(NPU_SRCS) $(CPU_SRCS)
	$(VERILATOR) $(VFLAGS_COV) $(NPU_SRCS) $(CPU_SRCS) $(TB_RTL)

coverage: $(COV_BIN)
	$(MAKE) FW_ASM=firmware_directed.S firmware.hex firmware_spike.elf firmware.disasm
	./$(COV_BIN) +max_cycles=$(MAX_CYCLES) +min_commits=500 | tee sim.log
	@grep -q '^PASS' sim.log || (echo "FAIL: directed coverage run did not PASS" && exit 1)
	cp coverage.dat cov_directed.dat
	$(MAKE) firmware_rand.S
	$(MAKE) FW_ASM=firmware_rand.S firmware.hex firmware_spike.elf firmware.disasm
	./$(COV_BIN) +max_cycles=$(MAX_CYCLES) +min_commits=10000 | tee sim.log
	@grep -q '^PASS' sim.log || (echo "FAIL: random coverage run did not PASS" && exit 1)
	cp coverage.dat cov_random.dat
	$(VERILATOR_COV) --write cov_merged.dat cov_directed.dat cov_random.dat
	rm -rf ann_cov && $(VERILATOR_COV) --annotate ann_cov --annotate-min 1 cov_merged.dat
	python3 cov_npu_strip.py | tee coverage.log

clean:
	rm -rf obj_dir obj_cov sim.log firmware.elf firmware.hex firmware.disasm firmware_rand.S \
	    firmware_spike.elf dut_commit.trace spike.log spike_commit.trace \
	    lockstep.log lockstep_report.md coverage.dat cov_*.dat ann_cov coverage.log coverage_report.md
