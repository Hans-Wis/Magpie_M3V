TOOLCHAIN_DIR    = /home/edauser/miniforge3/pkgs/riscv-tools-1.0.6-0_h1234567_g56c29e0/riscv-tools/bin
TOOLCHAIN_PREFIX = $(TOOLCHAIN_DIR)/riscv64-unknown-elf-
TOOLCHAIN_LIBS   = /home/edauser/miniforge3/pkgs/mpfr-4.2.2-he0a73b1_0/lib:/home/edauser/miniforge3/pkgs/gmp-6.3.0-hac33072_2/lib:/home/edauser/miniforge3/pkgs/mpc-1.4.0-he0a73b1_0/lib
TOOLCHAIN_ENV    = LD_LIBRARY_PATH=$(TOOLCHAIN_LIBS)
VERILATOR ?= /home/edauser/miniforge3/envs/magpie_claude/bin/verilator
SEED ?= 20260607
COUNT ?= 48
GCC_MARCH = rv32imc_zicsr_zifencei
GCC_MABI  = ilp32
RTL_DIR  = ../../../design/cpu_m1/rtl
RTL_SRCS = $(RTL_DIR)/rfu.v $(RTL_DIR)/alu.v $(RTL_DIR)/idu.v \
           $(RTL_DIR)/ifu.v $(RTL_DIR)/lsu.v $(RTL_DIR)/csr.v \
           $(RTL_DIR)/mul.v $(RTL_DIR)/div.v $(RTL_DIR)/forward.v \
           $(RTL_DIR)/hazard.v $(RTL_DIR)/bp.v $(RTL_DIR)/ras.v \
           $(RTL_DIR)/cdec.v $(RTL_DIR)/core.v
TB_RTL = tb_random_lockstep.v
VFLAGS = --binary -j 4 --trace --trace-depth 2 --trace-structs \
         --top-module tb_random_lockstep --timescale 1ns/1ns \
         -I$(RTL_DIR) -Wall -Wno-PROCASSINIT -Wno-DECLFILENAME -Wno-PINMISSING -Wno-WIDTHEXPAND -Wno-UNUSEDSIGNAL \
         -Wno-TIMESCALEMOD -Wno-UNUSEDSIGNAL -Wno-SYNCASYNCNET
SIM_BIN = obj_dir/Vtb_random_lockstep

all: random_lockstep.log

firmware.S: gen_random_program.py
	python3 gen_random_program.py --seed $(SEED) --count $(COUNT) --out firmware.S

firmware.elf: firmware.S firmware.lds
	$(TOOLCHAIN_ENV) $(TOOLCHAIN_PREFIX)gcc -Os -march=$(GCC_MARCH) -mabi=$(GCC_MABI) \
	    -nostartfiles -nostdlib -ffreestanding \
	    -Wl,-Bstatic,-T,firmware.lds,--strip-debug -o $@ firmware.S

firmware_spike.elf: firmware.S firmware_spike.lds
	$(TOOLCHAIN_ENV) $(TOOLCHAIN_PREFIX)gcc -Os -march=$(GCC_MARCH) -mabi=$(GCC_MABI) \
	    -nostartfiles -nostdlib -ffreestanding \
	    -Wl,-Bstatic,-T,firmware_spike.lds,--strip-debug -o $@ firmware.S

firmware.hex: firmware.elf
	$(TOOLCHAIN_ENV) $(TOOLCHAIN_PREFIX)objcopy -O verilog --verilog-data-width=4 $< $@

firmware.disasm: firmware.elf
	$(TOOLCHAIN_ENV) $(TOOLCHAIN_PREFIX)objdump -d $< > $@

$(SIM_BIN): $(TB_RTL) $(RTL_SRCS)
	$(VERILATOR) $(VFLAGS) $(RTL_SRCS) $(TB_RTL)

dut_commit.trace wave.vcd sim.log: $(SIM_BIN) firmware.hex firmware.disasm
	./$(SIM_BIN) | tee sim.log
	@grep -q '^PASS' sim.log || (echo "FAIL: sim did not report PASS" && exit 1)

random_lockstep.log: dut_commit.trace firmware_spike.elf random_lockstep.py
	python3 random_lockstep.py | tee random_lockstep.log
	@grep -q '^PASS' random_lockstep.log || (echo "FAIL: random lockstep did not report PASS" && exit 1)

clean:
	rm -rf obj_dir wave.vcd sim.log firmware.S firmware.elf firmware_spike.elf \
	    firmware.hex firmware.disasm dut_commit.trace spike.log spike_commit.trace \
	    random_lockstep.log random_lockstep_report.md

.PHONY: all clean
