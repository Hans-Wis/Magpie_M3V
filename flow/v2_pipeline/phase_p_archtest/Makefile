VERILATOR ?= /home/edauser/miniforge3/envs/magpie_claude/bin/verilator
RV32A ?= 1
PMP_ENTRIES ?= 0

RTL_DIR  = ../../../IP/cpu_m1/rtl
RTL_SRCS = $(RTL_DIR)/rfu.v $(RTL_DIR)/alu.v $(RTL_DIR)/idu.v \
           $(RTL_DIR)/ifu.v $(RTL_DIR)/lsu.v $(RTL_DIR)/csr.v \
           $(RTL_DIR)/trigger.v \
           $(RTL_DIR)/mul.v $(RTL_DIR)/div.v \
           $(RTL_DIR)/forward.v $(RTL_DIR)/hazard.v \
           $(RTL_DIR)/bp.v \
           $(RTL_DIR)/ras.v \
           $(RTL_DIR)/cdec.v \
           $(RTL_DIR)/core.v

VFLAGS = --binary -j 4 \
         --top-module tb_archtest \
         --timescale 1ns/1ns \
         -GRV32A=$(RV32A) -GPMP_ENTRIES=$(PMP_ENTRIES) \
         -I$(RTL_DIR) \
         -Wall -Wno-PROCASSINIT -Wno-DECLFILENAME -Wno-TIMESCALEMOD \
         -Wno-UNUSEDSIGNAL -Wno-SYNCASYNCNET -Wno-WIDTH

SIM_BIN = obj_dir/Vtb_archtest

all: $(SIM_BIN)

$(SIM_BIN): tb_archtest.v $(RTL_SRCS)
	$(VERILATOR) $(VFLAGS) $(RTL_SRCS) tb_archtest.v

run: $(SIM_BIN)
	python3 run_archtest.py

clean:
	rm -rf obj_dir runs logs summary.json summary.md results.csv verilator_build.log

.PHONY: all run clean
