VERILATOR ?= /home/edauser/miniforge3/envs/magpie_claude/bin/verilator
VC_STATIC_HOME ?= /soft/synopsys/vcs/X-2025.06-SP1/vcfca
SHELL := /bin/bash

RTL_DIR  = ../../../design/cpu_m1/rtl
RTL_SRCS = $(RTL_DIR)/rfu.v $(RTL_DIR)/alu.v $(RTL_DIR)/idu.v \
           $(RTL_DIR)/ifu.v $(RTL_DIR)/lsu.v $(RTL_DIR)/csr.v \
           $(RTL_DIR)/mul.v $(RTL_DIR)/div.v \
           $(RTL_DIR)/forward.v $(RTL_DIR)/hazard.v \
           $(RTL_DIR)/bp.v $(RTL_DIR)/ras.v $(RTL_DIR)/cdec.v \
           $(RTL_DIR)/core.v $(RTL_DIR)/cpu_m1_top.v \
           $(RTL_DIR)/axil_bridge.v $(RTL_DIR)/cpu_m1_axil_top.v

VFLAGS_COMMON = --binary -j 4 --timescale 1ns/1ns -I$(RTL_DIR) \
                -Wall -Wno-PROCASSINIT -Wno-DECLFILENAME -Wno-TIMESCALEMOD \
                -Wno-UNUSEDSIGNAL -Wno-SYNCASYNCNET -Wno-WIDTH \
                -Wno-BLKSEQ -Wno-CASEINCOMPLETE -Wno-UNSIGNED

EQUIV_SIM = obj_dir_equiv/Vtb_axil_equiv
ARCH_SIM  = obj_dir_arch/Vtb_axil_archtest

all: equiv-sim arch-sim

equiv-sim: $(EQUIV_SIM)

$(EQUIV_SIM): tb_axil_equiv.v axil_lite_mem_bfm.v $(RTL_SRCS)
	$(VERILATOR) $(VFLAGS_COMMON) --Mdir obj_dir_equiv --top-module tb_axil_equiv \
	    $(RTL_SRCS) axil_lite_mem_bfm.v tb_axil_equiv.v

arch-sim: $(ARCH_SIM)

$(ARCH_SIM): tb_axil_archtest.v axil_lite_mem_bfm.v $(RTL_SRCS)
	$(VERILATOR) $(VFLAGS_COMMON) --Mdir obj_dir_arch --top-module tb_axil_archtest \
	    $(RTL_SRCS) axil_lite_mem_bfm.v tb_axil_archtest.v

run-equiv: $(EQUIV_SIM)
	mkdir -p runs/equiv_wait0 runs/equiv_wait3
	cd runs/equiv_wait0 && ../../$(EQUIV_SIM) \
	    +HEX=../../../phase_03_04_directed_lockstep/firmware.hex \
	    +NATIVE_TRACE=native_commit.trace +AXI_TRACE=axi_commit.trace \
	    +WAIT=0 +MAX_CYCLES=1000000 | tee sim.log
	cd runs/equiv_wait3 && ../../$(EQUIV_SIM) \
	    +HEX=../../../phase_03_04_directed_lockstep/firmware.hex \
	    +NATIVE_TRACE=native_commit.trace +AXI_TRACE=axi_commit.trace \
	    +WAIT=3 +MAX_CYCLES=3000000 | tee sim.log

run-arch: $(ARCH_SIM)
	python3 run_axil_archtest.py --tests add-01 mul-01 --wait 0 3

formal:
	set -o pipefail; \
	export VC_STATIC_HOME="$(VC_STATIC_HOME)"; \
	export PATH="$(VC_STATIC_HOME)/bin:$$PATH"; \
	export LD_LIBRARY_PATH="/soft/synopsys/verdi/X-2025.06-SP1-1/platform/linux64/lib/Qt5/lib:$$LD_LIBRARY_PATH"; \
	vc_static_shell -batch -no_ui -no_init -out_dir vcformal_axil.out \
	    -output_log_file vcformal_axil.full.log -f vcformal_axil.tcl | tee vcformal_axil.log; \
	status=$${PIPESTATUS[0]}; \
	if grep -q -- "- # proven       : 18" formal_results.txt && \
	   grep -q -- "- # non_vacuous  : 18" formal_results.txt; then \
	    exit 0; \
	fi; \
	exit $$status

clean:
	rm -rf obj_dir_equiv obj_dir_arch runs archtest_axi_results.csv \
	    archtest_axi_summary.json verilator_*_build.log vcformal_axil.out \
	    vcformal_axil.log formal_results.txt formal_summary.txt

.PHONY: all equiv-sim arch-sim run-equiv run-arch formal clean
