TOOLCHAIN_DIR    = /home/edauser/miniforge3/pkgs/riscv-tools-1.0.6-0_h1234567_g56c29e0/riscv-tools/bin
TOOLCHAIN_PREFIX = $(TOOLCHAIN_DIR)/riscv64-unknown-elf-
TOOLCHAIN_LIBS   = /home/edauser/miniforge3/pkgs/mpfr-4.2.2-he0a73b1_0/lib:/home/edauser/miniforge3/pkgs/gmp-6.3.0-hac33072_2/lib:/home/edauser/miniforge3/pkgs/mpc-1.4.0-he0a73b1_0/lib
TOOLCHAIN_ENV    = LD_LIBRARY_PATH=$(TOOLCHAIN_LIBS)
VERILATOR ?= /home/edauser/miniforge3/envs/magpie_claude/bin/verilator

GCC_MARCH = rv32imc_zicsr_zifencei
GCC_MABI  = ilp32
ITER     ?= 10

CM   = coremark
PORT = port_m1
CM_SRCS = $(CM)/core_main.c $(CM)/core_list_join.c $(CM)/core_matrix.c \
          $(CM)/core_state.c $(CM)/core_util.c \
          $(PORT)/core_portme.c $(PORT)/ee_printf.c
CFLAGS = -O2 -march=$(GCC_MARCH) -mabi=$(GCC_MABI) -nostdlib -nostartfiles -ffreestanding \
         -I$(CM) -I$(PORT) -DITERATIONS=$(ITER) -DPERFORMANCE_RUN=1 -DTOTAL_DATA_SIZE=2000

RTL_DIR  = ../../../IP/cpu_m1/rtl
RTL_SRCS = $(RTL_DIR)/rfu.v $(RTL_DIR)/alu.v $(RTL_DIR)/idu.v \
           $(RTL_DIR)/ifu.v $(RTL_DIR)/lsu.v $(RTL_DIR)/csr.v \
           $(RTL_DIR)/mul.v $(RTL_DIR)/div.v $(RTL_DIR)/forward.v \
           $(RTL_DIR)/hazard.v $(RTL_DIR)/bp.v $(RTL_DIR)/ras.v \
           $(RTL_DIR)/cdec.v $(RTL_DIR)/core.v
VFLAGS = --binary -j 4 --top-module tb_bench --timescale 1ns/1ns \
         -I$(RTL_DIR) -Wall -Wno-PROCASSINIT -Wno-DECLFILENAME \
         -Wno-TIMESCALEMOD -Wno-UNUSEDSIGNAL -Wno-SYNCASYNCNET
SIM_BIN = obj_dir/Vtb_bench

all: coremark_run.log

coremark.elf: $(CM_SRCS) $(PORT)/crt0.S $(PORT)/link.lds $(PORT)/core_portme.h
	$(TOOLCHAIN_ENV) $(TOOLCHAIN_PREFIX)gcc $(CFLAGS) \
	    -Wl,-Bstatic,-T,$(PORT)/link.lds,--strip-debug \
	    -o $@ $(PORT)/crt0.S $(CM_SRCS)

firmware.hex: coremark.elf
	$(TOOLCHAIN_ENV) $(TOOLCHAIN_PREFIX)objcopy -O verilog --verilog-data-width=4 $< $@

coremark.disasm: coremark.elf
	$(TOOLCHAIN_ENV) $(TOOLCHAIN_PREFIX)objdump -d $< > $@

$(SIM_BIN): tb_bench.v $(RTL_SRCS)
	$(VERILATOR) $(VFLAGS) $(RTL_SRCS) tb_bench.v

coremark_run.log: $(SIM_BIN) firmware.hex coremark.disasm
	./$(SIM_BIN) | tee coremark_run.log
	@grep -q 'M1_BENCH' coremark_run.log || (echo "FAIL: no M1_BENCH line" && exit 1)

clean:
	rm -rf obj_dir coremark.elf firmware.hex coremark.disasm coremark_run.log

.PHONY: all clean

roofline.elf: roofline.c port_m1/crt0.S port_m1/link.lds
	$(TOOLCHAIN_ENV) $(TOOLCHAIN_PREFIX)gcc -O2 -march=$(GCC_MARCH) -mabi=$(GCC_MABI) \
	    -nostdlib -nostartfiles -ffreestanding \
	    -Wl,-Bstatic,-T,port_m1/link.lds,--strip-debug \
	    -o $@ port_m1/crt0.S roofline.c

roofline_run.log: $(SIM_BIN) roofline.elf
	$(TOOLCHAIN_ENV) $(TOOLCHAIN_PREFIX)objcopy -O verilog --verilog-data-width=4 roofline.elf firmware.hex
	./$(SIM_BIN) | tee roofline_run.log
	@grep -q 'ROOFLINE DONE' roofline_run.log || (echo "FAIL: roofline did not complete" && exit 1)
