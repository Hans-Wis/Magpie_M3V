# ADR-0036 gate_40/41 — vector-CSR lockstep (Stage 3A): Verilator npu_top DUT
# (EN_RVV=1 sequencer) vs Spike --isa=rv32im_zve32x_zvl128b golden.
#   make grid    -> firmware_vcsr_grid.S   (gate_40)
#   make vill    -> firmware_vill_ladder.S (gate_41)
# TB is reused from phase_20 (DMA tied off; CTRL.start release; commit trace).
TOOLCHAIN_DIR    = /home/edauser/miniforge3/pkgs/riscv-tools-1.0.6-0_h1234567_g56c29e0/riscv-tools/bin
TOOLCHAIN_PREFIX = $(TOOLCHAIN_DIR)/riscv64-unknown-elf-
TOOLCHAIN_LIBS   = /home/edauser/miniforge3/pkgs/mpfr-4.2.2-he0a73b1_0/lib:/home/edauser/miniforge3/pkgs/gmp-6.3.0-hac33072_2/lib:/home/edauser/miniforge3/pkgs/mpc-1.4.0-he0a73b1_0/lib
TOOLCHAIN_ENV    = LD_LIBRARY_PATH=$(TOOLCHAIN_LIBS)
VERILATOR ?= /home/edauser/miniforge3/envs/magpie_claude/bin/verilator

# 3A contract ISA (ADR-0036): vector config, no C, no F
GCC_MARCH = rv32im_zve32x_zvl128b_zicsr_zifencei
GCC_MABI  = ilp32

CPU_RTL_DIR = ../../../IP/cpu_m1/rtl
NPU_RTL_DIR = ../../../IP/npu/rtl
CPU_SRCS = $(addprefix $(CPU_RTL_DIR)/, rfu.v alu.v bmu.v idu.v ifu.v lsu.v csr.v \
           trigger.v pmp.v mul.v div.v forward.v hazard.v bp.v ras.v cdec.v core.v cpu_m1_top.v)
NPU_SRCS = $(addprefix $(NPU_RTL_DIR)/, npu_top.v npu_axil_regs.v npu_dma.v npu_tcm.v axil_decerr.v)
TB_RTL   = ../phase_20_npu_core_lockstep/tb_npu_lockstep.v
EXTRA_V ?=

VFLAGS = --binary --timing -j 4 --top-module tb_npu_lockstep --timescale 1ns/1ns \
         -I$(CPU_RTL_DIR) -Wno-fatal -Wno-DECLFILENAME -Wno-TIMESCALEMOD \
         -Wno-UNUSEDSIGNAL -Wno-SYNCASYNCNET

SIM_BIN = obj_dir/Vtb_npu_lockstep

.PHONY: all grid vill clean firmware.elf firmware_spike.elf firmware.hex

all: grid

grid:
	$(MAKE) FW_ASM=firmware_vcsr_grid.S MIN_COMMITS=80 lockstep.log

vill:
	$(MAKE) FW_ASM=firmware_vill_ladder.S MIN_COMMITS=40 lockstep.log

FW_ASM ?= firmware_vcsr_grid.S
MIN_COMMITS ?= 40

firmware.elf: $(FW_ASM) ../phase_20_npu_core_lockstep/firmware.lds
	$(TOOLCHAIN_ENV) $(TOOLCHAIN_PREFIX)gcc -Os -march=$(GCC_MARCH) -mabi=$(GCC_MABI) \
	    -nostartfiles -nostdlib -ffreestanding \
	    -Wl,-Bstatic,-T,../phase_20_npu_core_lockstep/firmware.lds,--strip-debug \
	    -o $@ $(FW_ASM)

firmware_spike.elf: $(FW_ASM) ../phase_20_npu_core_lockstep/firmware_spike.lds
	$(TOOLCHAIN_ENV) $(TOOLCHAIN_PREFIX)gcc -Os -march=$(GCC_MARCH) -mabi=$(GCC_MABI) \
	    -nostartfiles -nostdlib -ffreestanding \
	    -Wl,-Bstatic,-T,../phase_20_npu_core_lockstep/firmware_spike.lds,--strip-debug \
	    -o $@ $(FW_ASM)

firmware.hex: firmware.elf
	$(TOOLCHAIN_ENV) $(TOOLCHAIN_PREFIX)objcopy -O verilog --verilog-data-width=4 $< $@

$(SIM_BIN): $(TB_RTL) $(NPU_SRCS) $(CPU_SRCS)
	$(VERILATOR) $(VFLAGS) $(NPU_SRCS) $(CPU_SRCS) $(EXTRA_V) $(TB_RTL)

.PHONY: sim.log lockstep.log
sim.log: $(SIM_BIN) firmware.hex
	./$(SIM_BIN) +max_cycles=100000 +min_commits=$(MIN_COMMITS) | tee sim.log
	@grep -q '^PASS' sim.log || (echo "FAIL: sim did not report PASS" && exit 1)

lockstep.log: sim.log firmware_spike.elf vcsr_lockstep.py
	python3 vcsr_lockstep.py --min-commits $(MIN_COMMITS) | tee lockstep.log
	@grep -q '^PASS' lockstep.log || (echo "FAIL: lockstep did not report PASS" && exit 1)

clean:
	rm -rf obj_dir sim.log firmware.elf firmware.hex firmware_spike.elf \
	    dut_commit.trace spike.log spike_commit.trace lockstep.log lockstep_report.md
