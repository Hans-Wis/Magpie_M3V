TOOLCHAIN_DIR    = /home/edauser/miniforge3/pkgs/riscv-tools-1.0.6-0_h1234567_g56c29e0/riscv-tools/bin
TOOLCHAIN_PREFIX = $(TOOLCHAIN_DIR)/riscv64-unknown-elf-
TOOLCHAIN_LIBS   = /home/edauser/miniforge3/pkgs/mpfr-4.2.2-he0a73b1_0/lib:/home/edauser/miniforge3/pkgs/gmp-6.3.0-hac33072_2/lib:/home/edauser/miniforge3/pkgs/mpc-1.4.0-he0a73b1_0/lib
TOOLCHAIN_ENV    = LD_LIBRARY_PATH=$(TOOLCHAIN_LIBS)
VERILATOR ?= /home/edauser/miniforge3/envs/magpie_claude/bin/verilator

GCC_MARCH = rv32imc_zicsr_zifencei
GCC_MABI  = ilp32

RTL_DIR   = ../../../IP/cpu_m1/rtl
RTL_SRCS  = $(shell cat files.f)
TB_RTL    = tb_mem_wrapper.v

VFLAGS = --binary -j 4 --trace --trace-depth 2 --trace-structs \
         --top-module tb_mem_wrapper --timescale 1ns/1ns \
         -I$(RTL_DIR) -Wall -Wno-PROCASSINIT -Wno-DECLFILENAME \
         -Wno-TIMESCALEMOD -Wno-UNUSEDSIGNAL -Wno-SYNCASYNCNET

SIM_BIN  = obj_dir/Vtb_mem_wrapper

all: mem_wrapper.lockstep.log

firmware.elf: firmware.S firmware.lds
	$(TOOLCHAIN_ENV) $(TOOLCHAIN_PREFIX)gcc -Os -march=$(GCC_MARCH) -mabi=$(GCC_MABI) \
	    -nostartfiles -nostdlib -ffreestanding \
	    -Wl,-Bstatic,-T,firmware.lds,--strip-debug -o $@ firmware.S

firmware_spike.elf: firmware.S firmware_spike.lds
	$(TOOLCHAIN_ENV) $(TOOLCHAIN_PREFIX)gcc -Os -march=$(GCC_MARCH) -mabi=$(GCC_MABI) \
	    -nostartfiles -nostdlib -ffreestanding \
	    -Wl,-Bstatic,-T,firmware_spike.lds,--strip-debug -o $@ firmware.S

firmware_misalign.elf: firmware_misalign.S firmware.lds
	$(TOOLCHAIN_ENV) $(TOOLCHAIN_PREFIX)gcc -Os -march=$(GCC_MARCH) -mabi=$(GCC_MABI) \
	    -nostartfiles -nostdlib -ffreestanding \
	    -Wl,-Bstatic,-T,firmware.lds,--strip-debug -o $@ firmware_misalign.S

firmware.hex: firmware.elf
	$(TOOLCHAIN_ENV) $(TOOLCHAIN_PREFIX)objcopy -O verilog --verilog-data-width=4 $< $@

firmware_misalign.hex: firmware_misalign.elf
	$(TOOLCHAIN_ENV) $(TOOLCHAIN_PREFIX)objcopy -O verilog --verilog-data-width=4 $< $@

firmware.disasm: firmware.elf
	$(TOOLCHAIN_ENV) $(TOOLCHAIN_PREFIX)objdump -d $< > $@

lint: $(RTL_SRCS) $(TB_RTL)
	$(VERILATOR) --lint-only $(VFLAGS) $(RTL_SRCS) $(TB_RTL)

$(SIM_BIN): $(RTL_SRCS) $(TB_RTL)
	$(VERILATOR) $(VFLAGS) $(RTL_SRCS) $(TB_RTL)

sim.log: $(SIM_BIN) firmware.hex firmware.disasm firmware_misalign.hex firmware_misalign.elf
	./$(SIM_BIN) | tee sim.log
	@grep -q '^PASS: mem_wrapper TB gate A/B/C/D complete' sim.log || (echo "FAIL: mem wrapper tb did not pass" && exit 1)

mem_wrapper.lockstep.log: sim.log firmware_spike.elf mem_wrapper_lockstep.py
	python3 mem_wrapper_lockstep.py | tee mem_wrapper.lockstep.log
	@grep -q '^PASS:' mem_wrapper.lockstep.log || (echo "FAIL: lockstep compare did not pass" && exit 1)

clean:
	rm -rf obj_dir wave.vcd sim.log firmware.elf firmware_spike.elf firmware_misalign.elf \
	    firmware.hex firmware_misalign.hex firmware.disasm dut_commit.trace spike.log spike_commit.trace \
	    mem_wrapper.lockstep.log mem_wrapper_lockstep_report.md

.PHONY: all lint clean
