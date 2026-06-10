TOOLCHAIN_DIR    = /home/edauser/miniforge3/pkgs/riscv-tools-1.0.6-0_h1234567_g56c29e0/riscv-tools/bin
TOOLCHAIN_PREFIX = $(TOOLCHAIN_DIR)/riscv64-unknown-elf-
TOOLCHAIN_LIBS   = /home/edauser/miniforge3/pkgs/mpfr-4.2.2-he0a73b1_0/lib:/home/edauser/miniforge3/pkgs/gmp-6.3.0-hac33072_2/lib:/home/edauser/miniforge3/pkgs/mpc-1.4.0-he0a73b1_0/lib
TOOLCHAIN_ENV    = LD_LIBRARY_PATH=$(TOOLCHAIN_LIBS)

VERILATOR ?= /home/edauser/miniforge3/envs/magpie_claude/bin/verilator

TRACE_DEPTH ?= 2
RUN_ARGS ?=

GCC_MARCH = rv32imc_zicsr_zifencei
GCC_MABI  = ilp32

RTL_DIR  = ../../../IP/cpu_m1/rtl
RTL_SRCS = $(RTL_DIR)/rfu.v $(RTL_DIR)/alu.v $(RTL_DIR)/idu.v \
           $(RTL_DIR)/ifu.v $(RTL_DIR)/lsu.v $(RTL_DIR)/csr.v \
           $(RTL_DIR)/mul.v $(RTL_DIR)/div.v \
           $(RTL_DIR)/forward.v $(RTL_DIR)/hazard.v \
           $(RTL_DIR)/bp.v \
           $(RTL_DIR)/ras.v \
           $(RTL_DIR)/cdec.v \
           $(RTL_DIR)/core.v
TB_RTL   = tb_illegal_munit_coverage.v
FW_SRCS  = firmware.S firmware.lds

VFLAGS = --binary -j 4 \
         --coverage \
         --trace --trace-depth $(TRACE_DEPTH) --trace-structs \
         --top-module tb_illegal_munit_coverage \
         --timescale 1ns/1ns \
         -I$(RTL_DIR) \
         -Wall -Wno-PROCASSINIT -Wno-DECLFILENAME -Wno-TIMESCALEMOD \
         -Wno-UNUSEDSIGNAL -Wno-SYNCASYNCNET

SIM_BIN = obj_dir/Vtb_illegal_munit_coverage

all: illegal_munit_coverage.log

firmware.elf: $(FW_SRCS)
	$(TOOLCHAIN_ENV) $(TOOLCHAIN_PREFIX)gcc -Os \
	    -march=$(GCC_MARCH) -mabi=$(GCC_MABI) \
	    -nostartfiles -nostdlib -ffreestanding \
	    -Wl,-Bstatic,-T,firmware.lds,--strip-debug \
	    -o $@ firmware.S

firmware_spike.elf: firmware.S firmware_spike.lds
	$(TOOLCHAIN_ENV) $(TOOLCHAIN_PREFIX)gcc -Os \
	    -march=$(GCC_MARCH) -mabi=$(GCC_MABI) \
	    -nostartfiles -nostdlib -ffreestanding \
	    -Wl,-Bstatic,-T,firmware_spike.lds,--strip-debug \
	    -o $@ firmware.S

firmware.hex: firmware.elf
	$(TOOLCHAIN_ENV) $(TOOLCHAIN_PREFIX)objcopy -O verilog --verilog-data-width=4 $< $@

firmware.disasm: firmware.elf
	$(TOOLCHAIN_ENV) $(TOOLCHAIN_PREFIX)objdump -d $< > $@

$(SIM_BIN): $(TB_RTL) $(RTL_SRCS)
	$(VERILATOR) $(VFLAGS) $(RTL_SRCS) $(TB_RTL)

verilate: $(SIM_BIN)

sim.log wave.vcd coverage.dat: $(SIM_BIN) firmware.hex firmware.disasm
	./$(SIM_BIN) $(RUN_ARGS) | tee sim.log
	@grep -q '^PASS' sim.log || (echo "FAIL: sim did not report PASS" && exit 1)
	@test -s coverage.dat || (echo "FAIL: coverage.dat missing" && exit 1)

illegal_munit_coverage.log: sim.log coverage.dat analyze_delta.py
	python3 analyze_delta.py | tee illegal_munit_coverage.log
	@grep -q '^PASS' illegal_munit_coverage.log || (echo "FAIL: coverage delta did not report PASS" && exit 1)

clean:
	rm -rf obj_dir wave.vcd sim.log coverage.dat firmware.elf firmware_spike.elf \
	    firmware.hex firmware.disasm coverage illegal_munit_coverage.log \
	    illegal_munit_coverage_report.md module_delta.csv

.PHONY: all verilate clean
