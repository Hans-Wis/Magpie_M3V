VERILATOR ?= /home/edauser/miniforge3/envs/magpie_claude/bin/verilator

TRACE_DEPTH ?= 2
RUN_ARGS ?=

RTL_DIR  = ../../../IP/cpu_m1/rtl
RTL_SRCS = $(RTL_DIR)/csr.v $(RTL_DIR)/idu.v
TB_RTL   = tb_csr_idu_residual_coverage.v

VFLAGS = --binary -j 4 \
         --coverage \
         --trace --trace-depth $(TRACE_DEPTH) --trace-structs \
         --top-module tb_csr_idu_residual_coverage \
         --timescale 1ns/1ns \
         -I$(RTL_DIR) \
         -Wall -Wno-PROCASSINIT -Wno-DECLFILENAME -Wno-TIMESCALEMOD \
         -Wno-UNUSEDSIGNAL -Wno-SYNCASYNCNET

SIM_BIN = obj_dir/Vtb_csr_idu_residual_coverage

all: csr_idu_residual_coverage.log

$(SIM_BIN): $(TB_RTL) $(RTL_SRCS)
	$(VERILATOR) $(VFLAGS) $(RTL_SRCS) $(TB_RTL)

verilate: $(SIM_BIN)

sim.log wave.vcd coverage.dat: $(SIM_BIN)
	./$(SIM_BIN) $(RUN_ARGS) | tee sim.log
	@grep -q '^PASS' sim.log || (echo "FAIL: sim did not report PASS" && exit 1)
	@test -s coverage.dat || (echo "FAIL: coverage.dat missing" && exit 1)

csr_idu_residual_coverage.log: sim.log coverage.dat analyze_delta.py
	python3 analyze_delta.py | tee csr_idu_residual_coverage.log
	@grep -q '^PASS' csr_idu_residual_coverage.log || (echo "FAIL: coverage delta did not report PASS" && exit 1)

clean:
	rm -rf obj_dir wave.vcd sim.log coverage.dat coverage \
	    csr_idu_residual_coverage.log csr_idu_residual_coverage_report.md \
	    module_delta.csv

.PHONY: all verilate clean
