# phase_24 — real-size nonlinear-kernel microbench (ddr_wall_step1 §B).
# Same 1-cycle ideal-memory bench TB class as phase_b0 (report with that caveat);
# core config = NPU sequencer (EN_RVV=1 EN_F=1, stripped front-end).
TOOLCHAIN_DIR    = /home/edauser/miniforge3/pkgs/riscv-tools-1.0.6-0_h1234567_g56c29e0/riscv-tools/bin
TOOLCHAIN_PREFIX = $(TOOLCHAIN_DIR)/riscv64-unknown-elf-
TOOLCHAIN_LIBS   = /home/edauser/miniforge3/pkgs/mpfr-4.2.2-he0a73b1_0/lib:/home/edauser/miniforge3/pkgs/gmp-6.3.0-hac33072_2/lib:/home/edauser/miniforge3/pkgs/mpc-1.4.0-he0a73b1_0/lib
TOOLCHAIN_ENV    = LD_LIBRARY_PATH=$(TOOLCHAIN_LIBS)
VERILATOR ?= /home/edauser/miniforge3/envs/magpie_claude/bin/verilator

# march matches the shipped cq_sequencer build exactly (kernel provenance)
GCC_MARCH = rv32im_zve32x_zvl128b_zicsr_zifencei
GCC_MABI  = ilp32

RTL_DIR = ../../../design/cpu_m1/rtl
RTL_SRCS = $(addprefix $(RTL_DIR)/, rfu.v alu.v bmu.v idu.v ifu.v lsu.v csr.v \
           trigger.v pmp.v mul.v div.v forward.v hazard.v bp.v ras.v cdec.v vexu.v fexu.v core.v)

VFLAGS = --binary -j 4 --top-module tb_perf --timescale 1ns/1ns \
         -I$(RTL_DIR) -Wno-fatal -Wno-DECLFILENAME -Wno-TIMESCALEMOD \
         -Wno-UNUSEDSIGNAL -Wno-SYNCASYNCNET

SIM_BIN = obj_dir/Vtb_perf

.PHONY: all clean

all: perf_run.log

$(SIM_BIN): tb_perf.v $(RTL_SRCS)
	$(VERILATOR) $(VFLAGS) $(RTL_SRCS) tb_perf.v

perf_h640.elf: perf_h640.c crt0.S link.lds
	$(TOOLCHAIN_ENV) $(TOOLCHAIN_PREFIX)gcc -O2 -march=$(GCC_MARCH) -mabi=$(GCC_MABI) \
	    -nostdlib -nostartfiles -ffreestanding -mno-relax \
	    -Wl,-Bstatic,-T,link.lds,--strip-debug \
	    -o $@ crt0.S perf_h640.c

perf_run.log: $(SIM_BIN) perf_h640.elf
	$(TOOLCHAIN_ENV) $(TOOLCHAIN_PREFIX)objcopy -O verilog --verilog-data-width=4 perf_h640.elf firmware.hex
	./$(SIM_BIN) | tee perf_run.log
	@grep -q 'REALSIZE PERF DONE' perf_run.log || (echo "FAIL: microbench did not complete" && exit 1)

clean:
	rm -rf obj_dir perf_h640.elf firmware.hex perf_run.log
