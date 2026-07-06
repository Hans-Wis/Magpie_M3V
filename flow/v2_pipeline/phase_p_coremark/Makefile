TOOLCHAIN_DIR    = /home/edauser/.local/opt/riscv/xpack-riscv-none-elf-gcc-13.2.0-2/bin
TOOLCHAIN_PREFIX = $(TOOLCHAIN_DIR)/riscv-none-elf-

VERILATOR ?= /home/edauser/miniforge3/envs/magpie_claude/bin/verilator

COREMARK_DIR = /home/edauser/project/RISC-V/reference/ibex/vendor/eembc_coremark
GCC_MARCH    = rv32imc
GCC_MABI     = ilp32
ITERATIONS  ?= 1
FREQ_MHZ    ?= 699

OPT_FLAGS = -O2 -funroll-loops -fno-common -fno-builtin
COMMON_FLAGS = $(OPT_FLAGS) -march=$(GCC_MARCH) -mabi=$(GCC_MABI) \
               -ffreestanding -nostartfiles -nostdlib \
               -I. -I$(COREMARK_DIR) \
               -DITERATIONS=$(ITERATIONS) -DTOTAL_DATA_SIZE=2000 \
               -DPERFORMANCE_RUN=1 -DHAS_FLOAT=0 -DHAS_TIME_H=0 \
               -DUSE_CLOCK=0 -DHAS_STDIO=0 -DHAS_PRINTF=0 \
               -DMAIN_HAS_NOARGC=1 -DMEM_METHOD=MEM_STATIC \
               -DFLAGS_STR='"$(OPT_FLAGS) -march=$(GCC_MARCH) -mabi=$(GCC_MABI) -ffreestanding -nostartfiles -nostdlib -DITERATIONS=$(ITERATIONS) -DTOTAL_DATA_SIZE=2000 -DPERFORMANCE_RUN=1 -DMEM_METHOD=MEM_STATIC"'

RTL_DIR  = ../../../design/cpu_m1/rtl
RTL_SRCS = $(RTL_DIR)/rfu.v $(RTL_DIR)/alu.v $(RTL_DIR)/idu.v \
           $(RTL_DIR)/ifu.v $(RTL_DIR)/lsu.v $(RTL_DIR)/csr.v \
           $(RTL_DIR)/mul.v $(RTL_DIR)/div.v \
           $(RTL_DIR)/forward.v $(RTL_DIR)/hazard.v \
           $(RTL_DIR)/bp.v \
           $(RTL_DIR)/ras.v \
           $(RTL_DIR)/cdec.v \
           $(RTL_DIR)/core.v
TB_RTL = tb_coremark.v

COREMARK_SRCS = \
    $(COREMARK_DIR)/core_main.c \
    $(COREMARK_DIR)/core_list_join.c \
    $(COREMARK_DIR)/core_matrix.c \
    $(COREMARK_DIR)/core_state.c \
    $(COREMARK_DIR)/core_util.c
FW_SRCS = start.S core_portme.c ee_printf.c $(COREMARK_SRCS) firmware.lds

VFLAGS = --binary -j 4 \
         --top-module tb_coremark \
         --timescale 1ns/1ns \
         -I$(RTL_DIR) \
         -Wall -Wno-PROCASSINIT -Wno-DECLFILENAME -Wno-TIMESCALEMOD \
         -Wno-UNUSEDSIGNAL -Wno-SYNCASYNCNET -Wno-WIDTH

SIM_BIN = obj_dir/Vtb_coremark

all: result.md

firmware.elf: $(FW_SRCS)
	$(TOOLCHAIN_PREFIX)gcc $(COMMON_FLAGS) \
	    -Wl,-Bstatic,-T,firmware.lds,-Map,firmware.map \
	    -o $@ start.S core_portme.c ee_printf.c $(COREMARK_SRCS) -lgcc

firmware.hex: firmware.elf
	$(TOOLCHAIN_PREFIX)objcopy -O verilog --verilog-data-width=4 $< $@

firmware.disasm: firmware.elf
	$(TOOLCHAIN_PREFIX)objdump -d $< > $@

$(SIM_BIN): $(TB_RTL) $(RTL_SRCS)
	$(VERILATOR) $(VFLAGS) $(RTL_SRCS) $(TB_RTL)

sim.log: $(SIM_BIN) firmware.hex firmware.disasm
	./$(SIM_BIN) | tee sim.log

result.md: sim.log summarize_coremark.py
	python3 summarize_coremark.py --iterations $(ITERATIONS) --freq-mhz $(FREQ_MHZ) > result.md
	cat result.md

clean:
	rm -rf obj_dir wave.vcd sim.log dut_commit.trace firmware.elf firmware.hex \
	    firmware.disasm firmware.map result.md

.PHONY: all clean
