SHELL := /bin/bash
.SHELLFLAGS := -o pipefail -c

VERILATOR ?= /home/edauser/miniforge3/envs/magpie_claude/bin/verilator
RISCV_GCC ?= /home/edauser/miniforge3/pkgs/riscv-tools-1.0.6-0_h1234567_g56c29e0/riscv-tools/bin/riscv64-unknown-elf-gcc
RISCV_OBJCOPY ?= /home/edauser/miniforge3/pkgs/riscv-tools-1.0.6-0_h1234567_g56c29e0/riscv-tools/bin/riscv64-unknown-elf-objcopy
RISCV_OBJDUMP ?= /home/edauser/miniforge3/pkgs/riscv-tools-1.0.6-0_h1234567_g56c29e0/riscv-tools/bin/riscv64-unknown-elf-objdump

RTL_DIR  = ../../../IP/cpu_m1/rtl
RTL_SRCS = $(RTL_DIR)/rfu.v $(RTL_DIR)/alu.v $(RTL_DIR)/idu.v \
           $(RTL_DIR)/ifu.v $(RTL_DIR)/lsu.v $(RTL_DIR)/csr.v \
           $(RTL_DIR)/trigger.v \
           $(RTL_DIR)/mul.v $(RTL_DIR)/div.v \
           $(RTL_DIR)/forward.v $(RTL_DIR)/hazard.v \
           $(RTL_DIR)/bp.v $(RTL_DIR)/ras.v $(RTL_DIR)/cdec.v \
           $(RTL_DIR)/core.v

VFLAGS = --binary -j 4 --trace --trace-depth 2 --top-module tb_pmp_directed \
         --timescale 1ns/1ns -I$(RTL_DIR) -Wall \
         -Wno-PROCASSINIT -Wno-DECLFILENAME -Wno-TIMESCALEMOD \
         -Wno-UNUSEDSIGNAL -Wno-SYNCASYNCNET

SIM_BIN = obj_dir/Vtb_pmp_directed

all: $(SIM_BIN) firmware.hex

$(SIM_BIN): tb_pmp_directed.v $(RTL_SRCS)
	$(VERILATOR) $(VFLAGS) $(RTL_SRCS) tb_pmp_directed.v

firmware.elf: firmware.S firmware.lds
	LD_LIBRARY_PATH=/home/edauser/miniforge3/pkgs/mpfr-4.2.2-he0a73b1_0/lib:/home/edauser/miniforge3/pkgs/gmp-6.3.0-hac33072_2/lib:/home/edauser/miniforge3/pkgs/mpc-1.4.0-he0a73b1_0/lib \
	$(RISCV_GCC) -Os -march=rv32imac_zicsr_zifencei -mabi=ilp32 \
	    -nostartfiles -nostdlib -ffreestanding \
	    -Wl,-Bstatic,-T,firmware.lds,--strip-debug,--no-relax \
	    -o firmware.elf firmware.S

firmware.hex: firmware.elf
	LD_LIBRARY_PATH=/home/edauser/miniforge3/pkgs/mpfr-4.2.2-he0a73b1_0/lib:/home/edauser/miniforge3/pkgs/gmp-6.3.0-hac33072_2/lib:/home/edauser/miniforge3/pkgs/mpc-1.4.0-he0a73b1_0/lib \
	$(RISCV_OBJCOPY) -O verilog --verilog-data-width=4 firmware.elf firmware.hex
	LD_LIBRARY_PATH=/home/edauser/miniforge3/pkgs/mpfr-4.2.2-he0a73b1_0/lib:/home/edauser/miniforge3/pkgs/gmp-6.3.0-hac33072_2/lib:/home/edauser/miniforge3/pkgs/mpc-1.4.0-he0a73b1_0/lib \
	$(RISCV_OBJDUMP) -d firmware.elf > firmware.disasm

run: all
	./$(SIM_BIN) | tee sim.log
	grep -q "PASS: PMP directed" sim.log

clean:
	rm -rf obj_dir firmware.elf firmware.hex firmware.disasm sim.log wave.vcd

.PHONY: all run clean
