# Magpie_M1 Phase 1.1 Makefile -- lab08e 4-stage pipeline fetch/RV32C/pre-fetch smoke.
#
# Targets:
#   make            : firmware + sim -> wave.vcd + sim.log
#   make wave       : gtkwave wave.vcd &
#   make verilate   : Verilator build only
#   make clean      : remove generated artifacts
#
# Default waveform is review-focused: TRACE_DEPTH=2 plus REVIEW_TRACE=1 keeps
# tb/wrapper/debug signals without expanding the full core hierarchy. For deep
# debug use: make clean && make TRACE_DEPTH=5 REVIEW_TRACE=0 RUN_ARGS=+full_vcd

TOOLCHAIN_DIR    = /home/edauser/miniforge3/pkgs/riscv-tools-1.0.6-0_h1234567_g56c29e0/riscv-tools/bin
TOOLCHAIN_PREFIX = $(TOOLCHAIN_DIR)/riscv64-unknown-elf-
TOOLCHAIN_LIBS   = /home/edauser/miniforge3/pkgs/mpfr-4.2.2-he0a73b1_0/lib:/home/edauser/miniforge3/pkgs/gmp-6.3.0-hac33072_2/lib:/home/edauser/miniforge3/pkgs/mpc-1.4.0-he0a73b1_0/lib
TOOLCHAIN_ENV    = LD_LIBRARY_PATH=$(TOOLCHAIN_LIBS)

VERILATOR ?= /home/edauser/miniforge3/envs/magpie_claude/bin/verilator
GTKWAVE   ?= /home/edauser/miniforge3/envs/magpie_claude/bin/gtkwave

DELAY_ITER ?= 200
TRACE_DEPTH ?= 2
REVIEW_TRACE ?= 1
RUN_ARGS ?=

REVIEW_TRACE_FLAG = $(if $(filter 1,$(REVIEW_TRACE)),-DREVIEW_TRACE,)

GCC_MARCH = rv32imc_zicsr_zifencei
GCC_MABI  = ilp32

RTL_DIR  = ../../../design/cpu_m1/rtl
RTL_SRCS = $(RTL_DIR)/rfu.v $(RTL_DIR)/alu.v $(RTL_DIR)/idu.v \
           $(RTL_DIR)/ifu.v $(RTL_DIR)/lsu.v $(RTL_DIR)/csr.v \
           $(RTL_DIR)/mul.v $(RTL_DIR)/div.v \
           $(RTL_DIR)/forward.v $(RTL_DIR)/hazard.v \
           $(RTL_DIR)/bp.v \
           $(RTL_DIR)/ras.v \
           $(RTL_DIR)/cdec.v \
           $(RTL_DIR)/core.v
TOP_RTL  = system_pynq.v
TB_RTL   = tb_core.v
FW_SRCS  = firmware.S firmware.c firmware.lds

VFLAGS = --binary -j 4 \
         --trace --trace-depth $(TRACE_DEPTH) --trace-structs \
         --top-module tb_core \
         --timescale 1ns/1ns \
         $(REVIEW_TRACE_FLAG) \
         -I$(RTL_DIR) \
         -Wall -Wno-PROCASSINIT -Wno-DECLFILENAME -Wno-TIMESCALEMOD \
         -Wno-UNUSEDSIGNAL -Wno-SYNCASYNCNET

SIM_BIN = obj_dir/Vtb_core

all: sim.log

firmware.elf: $(FW_SRCS)
	$(TOOLCHAIN_ENV) $(TOOLCHAIN_PREFIX)gcc -Os \
	    -march=$(GCC_MARCH) -mabi=$(GCC_MABI) \
	    -DDELAY_ITER=$(DELAY_ITER) \
	    -nostartfiles -nostdlib -ffreestanding \
	    -Wl,-Bstatic,-T,firmware.lds,--strip-debug \
	    -o $@ firmware.S firmware.c

firmware.hex: firmware.elf
	$(TOOLCHAIN_ENV) $(TOOLCHAIN_PREFIX)objcopy -O verilog --verilog-data-width=4 $< $@

firmware.disasm: firmware.elf
	$(TOOLCHAIN_ENV) $(TOOLCHAIN_PREFIX)objdump -d $< > $@

$(SIM_BIN): $(TB_RTL) $(TOP_RTL) $(RTL_SRCS)
	$(VERILATOR) $(VFLAGS) $(RTL_SRCS) $(TOP_RTL) $(TB_RTL)

verilate: $(SIM_BIN)

sim.log wave.vcd: $(SIM_BIN) firmware.hex firmware.disasm
	./$(SIM_BIN) $(RUN_ARGS) | tee sim.log
	@grep -q '^PASS' sim.log || (echo "FAIL: sim did not report PASS" && exit 1)

wave: wave.vcd
	$(GTKWAVE) wave.vcd &

clean:
	rm -rf obj_dir wave.vcd sim.log firmware.elf firmware.hex firmware.disasm

.PHONY: all verilate wave clean
