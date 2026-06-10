TOOLCHAIN_DIR    = /home/edauser/miniforge3/pkgs/riscv-tools-1.0.6-0_h1234567_g56c29e0/riscv-tools/bin
TOOLCHAIN_PREFIX = $(TOOLCHAIN_DIR)/riscv64-unknown-elf-
TOOLCHAIN_LIBS   = /home/edauser/miniforge3/pkgs/mpfr-4.2.2-he0a73b1_0/lib:/home/edauser/miniforge3/pkgs/gmp-6.3.0-hac33072_2/lib:/home/edauser/miniforge3/pkgs/mpc-1.4.0-he0a73b1_0/lib
TOOLCHAIN_ENV    = LD_LIBRARY_PATH=$(TOOLCHAIN_LIBS)
VERILATOR ?= /home/edauser/miniforge3/envs/magpie_claude/bin/verilator

GCC_MARCH = rv32imc_zicsr_zifencei
GCC_MABI  = ilp32
RTL_DIR  = ../../../IP/cpu_m1/rtl
RTL_SRCS = $(RTL_DIR)/rfu.v $(RTL_DIR)/alu.v $(RTL_DIR)/idu.v \
           $(RTL_DIR)/ifu.v $(RTL_DIR)/lsu.v $(RTL_DIR)/csr.v \
           $(RTL_DIR)/mul.v $(RTL_DIR)/div.v $(RTL_DIR)/forward.v \
           $(RTL_DIR)/hazard.v $(RTL_DIR)/bp.v $(RTL_DIR)/ras.v \
           $(RTL_DIR)/cdec.v $(RTL_DIR)/core.v
TB_RTL = tb_mepc_directed.v
VFLAGS = --binary -j 4 --trace --trace-depth 2 --trace-structs \
         --top-module tb_mepc_directed --timescale 1ns/1ns \
         -I$(RTL_DIR) -Wall -Wno-PROCASSINIT -Wno-DECLFILENAME \
         -Wno-TIMESCALEMOD -Wno-UNUSEDSIGNAL -Wno-SYNCASYNCNET
RUN_ARGS ?=
SIM_BIN = obj_dir/Vtb_mepc_directed

all: mepc_directed.log

firmware.elf: firmware.S firmware.lds
	$(TOOLCHAIN_ENV) $(TOOLCHAIN_PREFIX)gcc -Os -march=$(GCC_MARCH) -mabi=$(GCC_MABI) \
	    -nostartfiles -nostdlib -ffreestanding \
	    -Wl,-Bstatic,-T,firmware.lds,--strip-debug -o $@ firmware.S

firmware.hex: firmware.elf
	$(TOOLCHAIN_ENV) $(TOOLCHAIN_PREFIX)objcopy -O verilog --verilog-data-width=4 $< $@

firmware.disasm: firmware.elf
	$(TOOLCHAIN_ENV) $(TOOLCHAIN_PREFIX)objdump -d $< > $@

$(SIM_BIN): $(TB_RTL) $(RTL_SRCS)
	$(VERILATOR) $(VFLAGS) $(RTL_SRCS) $(TB_RTL)

sim.log wave.vcd: $(SIM_BIN) firmware.hex firmware.disasm
	./$(SIM_BIN) $(RUN_ARGS) | tee sim.log
	@grep -q '^PASS' sim.log || (echo "FAIL: sim did not report PASS" && exit 1)

mepc_directed.log: sim.log
	@cp sim.log $@

clean:
	rm -rf obj_dir wave.vcd sim.log mepc_directed.log firmware.elf firmware.hex firmware.disasm

.PHONY: all clean
