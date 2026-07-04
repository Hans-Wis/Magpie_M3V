# ADR-0037 gate_45 — matrix engine unit-level bit-exactness vs mat_golden.py.
# `make all` regenerates the vectors from the golden (SSOT) and runs the TB.
VERILATOR ?= /home/edauser/miniforge3/envs/magpie_claude/bin/verilator
GOLDEN = ../../../IP/npu/golden/mat_golden.py
RTL    = ../../../IP/npu/rtl/mat_engine.v
SEED  ?= 20260704

.PHONY: all vectors sim clean

all: sim

vectors:
	python3 $(GOLDEN) --selftest
	python3 $(GOLDEN) --emit vectors --seed $(SEED)

obj_dir/Vtb_mat_engine: tb_mat_engine.v $(RTL)
	$(VERILATOR) --binary --timing -j 4 -Wno-fatal --top-module tb_mat_engine \
	    --timescale 1ns/1ps -Wno-DECLFILENAME -Wno-UNUSEDSIGNAL $(RTL) tb_mat_engine.v

sim: vectors obj_dir/Vtb_mat_engine
	./obj_dir/Vtb_mat_engine | tee sim.log
	@grep -q '^MAT_ENGINE_PASS' sim.log || (echo "FAIL: unit TB did not pass" && exit 1)

clean:
	rm -rf obj_dir sim.log build.log vectors
