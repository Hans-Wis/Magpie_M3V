# ADR-0035 gate_39 — CQ consume slice lockstep: Verilator npu_top+rwmem DUT vs
# Spike golden with MMIO shadow seeds in the Spike image. `make all` = full rerun.
TOOLCHAIN_DIR    = /home/edauser/miniforge3/pkgs/riscv-tools-1.0.6-0_h1234567_g56c29e0/riscv-tools/bin
TOOLCHAIN_PREFIX = $(TOOLCHAIN_DIR)/riscv64-unknown-elf-
TOOLCHAIN_LIBS   = /home/edauser/miniforge3/pkgs/mpfr-4.2.2-he0a73b1_0/lib:/home/edauser/miniforge3/pkgs/gmp-6.3.0-hac33072_2/lib:/home/edauser/miniforge3/pkgs/mpc-1.4.0-he0a73b1_0/lib
TOOLCHAIN_ENV    = LD_LIBRARY_PATH=$(TOOLCHAIN_LIBS)
VERILATOR ?= /home/edauser/miniforge3/envs/magpie_claude/bin/verilator

GCC_MARCH = rv32im_zicsr_zifencei
GCC_MABI  = ilp32
GCCFLAGS  = -Os -march=$(GCC_MARCH) -mabi=$(GCC_MABI) -nostartfiles -nostdlib -ffreestanding

CPU_RTL_DIR = ../../../design/cpu_m1/rtl
NPU_RTL_DIR = ../../../design/npu/rtl
CPU_SRCS = $(addprefix $(CPU_RTL_DIR)/, rfu.v alu.v bmu.v idu.v ifu.v lsu.v csr.v \
           trigger.v pmp.v mul.v div.v forward.v hazard.v bp.v ras.v cdec.v vexu.v core.v cpu_m1_top.v)
NPU_SRCS = $(addprefix $(NPU_RTL_DIR)/, npu_top.v npu_axil_regs.v npu_dma.v npu_tcm.v axil_decerr.v mat_engine.v)
RWMEM    = ../../../design/npu/dv/tb/axi_full_rwmem.v
TB_RTL   = tb_npu_cq_lockstep.v

VFLAGS = --binary --timing -j 4 --top-module tb_npu_cq_lockstep --timescale 1ns/1ns \
         -I$(CPU_RTL_DIR) -Wno-fatal -Wno-DECLFILENAME -Wno-TIMESCALEMOD \
         -Wno-UNUSEDSIGNAL -Wno-SYNCASYNCNET

SIM_BIN = obj_dir/Vtb_npu_cq_lockstep

.PHONY: all clean firmware.elf firmware_spike.elf firmware.hex

all: lockstep.log

firmware.elf: firmware_cq.S firmware.lds
	$(TOOLCHAIN_ENV) $(TOOLCHAIN_PREFIX)gcc $(GCCFLAGS) \
	    -Wl,-Bstatic,-T,firmware.lds,--strip-debug -o $@ firmware_cq.S

firmware_spike.elf: firmware_cq.S firmware_spike.lds
	$(TOOLCHAIN_ENV) $(TOOLCHAIN_PREFIX)gcc $(GCCFLAGS) -DSPIKE_SEED \
	    -Wl,-Bstatic,-T,firmware_spike.lds,--strip-debug -o $@ firmware_cq.S

firmware.hex: firmware.elf
	$(TOOLCHAIN_ENV) $(TOOLCHAIN_PREFIX)objcopy -O verilog --verilog-data-width=4 $< $@

$(SIM_BIN): $(TB_RTL) $(NPU_SRCS) $(CPU_SRCS)
	$(VERILATOR) $(VFLAGS) $(NPU_SRCS) $(CPU_SRCS) $(RWMEM) $(TB_RTL)

.PHONY: sim.log lockstep.log
sim.log: $(SIM_BIN) firmware.hex
	./$(SIM_BIN) | tee sim.log
	@grep -q '^PASS' sim.log || (echo "FAIL: sim did not report PASS" && exit 1)

lockstep.log: sim.log firmware_spike.elf cq_lockstep.py
	python3 cq_lockstep.py | tee lockstep.log
	@grep -q '^PASS' lockstep.log || (echo "FAIL: lockstep did not report PASS" && exit 1)

clean:
	rm -rf obj_dir sim.log firmware.elf firmware.hex firmware_spike.elf \
	    dut_commit.trace spike.log spike_commit.trace lockstep.log lockstep_report.md
