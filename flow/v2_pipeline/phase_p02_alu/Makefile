VERILATOR ?= verilator
VERILATOR_COVERAGE ?= verilator_coverage
VCS ?= vcs
URG ?= urg

ROOT := ../../..
RTL_DIR := $(ROOT)/IP/cpu_m1/rtl
TB := $(ROOT)/IP/cpu_m1/dv/tb/tb_alu_unit.v
ALU := $(RTL_DIR)/alu.v

VFLAGS := --binary -j 4 --coverage --coverage-line --coverage-toggle \
          --top-module tb_alu_unit --timescale 1ns/1ps \
          -I$(RTL_DIR) -Wall -Wno-DECLFILENAME -Wno-TIMESCALEMOD

SIM_BIN := obj_dir/Vtb_alu_unit

.PHONY: all verilator vcs urg clean

all: verilator

$(SIM_BIN): $(TB) $(ALU) $(RTL_DIR)/def.vh
	$(VERILATOR) $(VFLAGS) $(ALU) $(TB) > logs/verilator_build.log 2>&1

verilator: $(SIM_BIN)
	./$(SIM_BIN) > logs/verilator_run.log 2>&1
	cp coverage.dat coverage/coverage.dat
	$(VERILATOR_COVERAGE) --write-info coverage/coverage.info coverage.dat > logs/verilator_write_info.log 2>&1
	$(VERILATOR_COVERAGE) --annotate coverage/annotated coverage.dat > logs/verilator_annotate.log 2>&1
	grep -q '^PASS: alu unit ' logs/verilator_run.log

vcs:
	cd vcs && $(VCS) -full64 -sverilog -timescale=1ns/1ps \
	    -cm line+cond+branch+tgl -cm_dir simv.vdb \
	    +incdir+../../../../IP/cpu_m1/rtl \
	    ../../../../IP/cpu_m1/rtl/alu.v \
	    ../../../../IP/cpu_m1/dv/tb/tb_alu_unit.v \
	    -top tb_alu_unit -o simv > ../logs/vcs_build.log 2>&1
	cd vcs && ./simv -cm line+cond+branch+tgl -cm_dir simv.vdb > ../logs/vcs_run.log 2>&1
	grep -q '^PASS: alu unit ' logs/vcs_run.log

urg: vcs
	cd vcs && $(URG) -full64 -dir simv.vdb -report urgReport \
	    -metric line+cond+branch+tgl > ../logs/urg.log 2>&1

clean:
	rm -rf obj_dir coverage.dat coverage/coverage.dat coverage/coverage.info \
	    coverage/annotated logs/*.log vcs/*
