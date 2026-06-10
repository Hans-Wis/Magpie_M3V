VERILATOR ?= verilator
VERILATOR_COVERAGE ?= verilator_coverage
VCS ?= vcs
URG ?= urg

ROOT := ../../..
RTL_DIR := $(ROOT)/IP/cpu_m1/rtl
TB := $(ROOT)/IP/cpu_m1/dv/tb/tb_ifu_unit.v
IFU := $(RTL_DIR)/ifu.v

VFLAGS := --binary -j 4 --coverage --coverage-line --coverage-toggle \
          --top-module tb_ifu_unit --timescale 1ns/1ps \
          -I$(RTL_DIR) -Wall -Wno-DECLFILENAME -Wno-TIMESCALEMOD \
          -Wno-UNUSEDSIGNAL -Wno-BLKSEQ -Wno-WIDTH

SIM_BIN := obj_dir/Vtb_ifu_unit
CM := line+cond+fsm+tgl+branch

.PHONY: all verilator vcs urg clean dirs

all: verilator

dirs:
	mkdir -p logs coverage/annotated vcs

$(SIM_BIN): $(TB) $(IFU) $(RTL_DIR)/def.vh | dirs
	$(VERILATOR) $(VFLAGS) $(IFU) $(TB) > logs/verilator_build.log 2>&1

verilator: $(SIM_BIN)
	./$(SIM_BIN) > logs/verilator_run.log 2>&1
	cp coverage.dat coverage/coverage.dat
	$(VERILATOR_COVERAGE) --write-info coverage/coverage.info coverage.dat > logs/verilator_write_info.log 2>&1
	$(VERILATOR_COVERAGE) --filter-type toggle --write-info coverage/coverage_toggle.info coverage.dat > logs/verilator_write_toggle_info.log 2>&1
	$(VERILATOR_COVERAGE) --annotate coverage/annotated coverage.dat > logs/verilator_annotate.log 2>&1
	grep -q '^PASS: ifu unit ' logs/verilator_run.log

vcs: dirs
	cd vcs && $(VCS) -full64 -sverilog -timescale=1ns/1ps \
	    -cm $(CM) -cm_dir simv.vdb \
	    +incdir+../../../../IP/cpu_m1/rtl \
	    ../../../../IP/cpu_m1/rtl/ifu.v \
	    ../../../../IP/cpu_m1/dv/tb/tb_ifu_unit.v \
	    -top tb_ifu_unit -o simv > ../logs/vcs_build.log 2>&1
	cd vcs && ./simv -cm $(CM) -cm_dir simv.vdb > ../logs/vcs_run.log 2>&1
	grep -q '^PASS: ifu unit ' logs/vcs_run.log

urg: vcs
	cd vcs && $(URG) -full64 -dir simv.vdb -report urgReport \
	    -metric $(CM) > ../logs/urg.log 2>&1

clean:
	rm -rf obj_dir coverage.dat coverage/coverage.dat coverage/coverage.info \
	    coverage/coverage_toggle.info coverage/annotated logs/*.log vcs/*
