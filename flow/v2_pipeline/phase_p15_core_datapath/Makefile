TOOLCHAIN_DIR    = /home/edauser/miniforge3/pkgs/riscv-tools-1.0.6-0_h1234567_g56c29e0/riscv-tools/bin
TOOLCHAIN_PREFIX = $(TOOLCHAIN_DIR)/riscv64-unknown-elf-
TOOLCHAIN_LIBS   = /home/edauser/miniforge3/pkgs/mpfr-4.2.2-he0a73b1_0/lib:/home/edauser/miniforge3/pkgs/gmp-6.3.0-hac33072_2/lib:/home/edauser/miniforge3/pkgs/mpc-1.4.0-he0a73b1_0/lib
TOOLCHAIN_ENV    = LD_LIBRARY_PATH=$(TOOLCHAIN_LIBS)

VERILATOR ?= /home/edauser/miniforge3/envs/magpie_claude/bin/verilator
VCS       ?= vcs
URG       ?= urg

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
VCS_RTL_SRCS = $(wildcard $(RTL_DIR)/*.v)
TB_RTL   = tb_directed_lockstep.v
FW_SRCS  = firmware.S firmware.lds

VFLAGS = --binary -j 4 \
         --coverage \
         --trace --trace-depth 2 --trace-structs \
         --top-module tb_directed_lockstep \
         --timescale 1ns/1ns \
         -I$(RTL_DIR) \
         -Wall -Wno-PROCASSINIT -Wno-DECLFILENAME -Wno-TIMESCALEMOD \
         -Wno-UNUSEDSIGNAL -Wno-SYNCASYNCNET

SIM_BIN = obj_dir/Vtb_directed_lockstep
CM      = line+cond+branch+fsm+tgl
VCS_DIR = vcs
VCS_SIM = $(VCS_DIR)/simv
VCS_VDB = $(VCS_DIR)/simv.vdb

all: p15_core_datapath.log

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

dut_commit.trace wave.vcd sim.log coverage.dat: $(SIM_BIN) firmware.hex firmware.disasm
	./$(SIM_BIN) | tee sim.log
	@grep -q '^PASS' sim.log || (echo "FAIL: sim did not report PASS" && exit 1)
	@test -s coverage.dat || (echo "FAIL: coverage.dat missing" && exit 1)

p15_core_datapath.log: dut_commit.trace coverage.dat firmware_spike.elf directed_lockstep.py analyze_delta.py
	python3 directed_lockstep.py | tee directed_lockstep.log
	@grep -q '^PASS' directed_lockstep.log || (echo "FAIL: directed lockstep did not report PASS" && exit 1)
	python3 analyze_delta.py | tee p15_core_datapath.log
	@grep -q '^PASS' p15_core_datapath.log || (echo "FAIL: P15 datapath analysis did not report PASS" && exit 1)

$(VCS_SIM): $(TB_RTL) $(VCS_RTL_SRCS) $(RTL_DIR)/def.vh firmware.hex
	mkdir -p $(VCS_DIR)
	$(VCS) -full64 -sverilog -timescale=1ns/1ns \
	    -cm $(CM) -cm_dir $(VCS_VDB) \
	    +incdir+$(RTL_DIR) \
	    $(VCS_RTL_SRCS) $(TB_RTL) \
	    -top tb_directed_lockstep -o $(VCS_SIM) > $(VCS_DIR)/vcs_build.log 2>&1

$(VCS_VDB): $(VCS_SIM) firmware.hex
	./$(VCS_SIM) -cm $(CM) -cm_dir $(VCS_VDB) > $(VCS_DIR)/vcs_run.log 2>&1
	@grep -q '^PASS' $(VCS_DIR)/vcs_run.log || (echo "FAIL: VCS sim did not report PASS" && exit 1)

vcs: $(VCS_VDB)

urg: vcs
	$(URG) -full64 -dir $(VCS_VDB) -report $(VCS_DIR)/urgReport \
	    -metric $(CM) > $(VCS_DIR)/urg.log 2>&1

clean:
	rm -rf obj_dir wave.vcd sim.log coverage.dat firmware.elf firmware.hex firmware.disasm \
	    firmware_spike.elf dut_commit.trace spike.log spike_commit.trace \
	    directed_lockstep.log directed_lockstep_report.md p15_core_datapath.log \
	    p15_core_datapath_report.md coverage module_delta.csv $(VCS_DIR)

.PHONY: all clean vcs urg
