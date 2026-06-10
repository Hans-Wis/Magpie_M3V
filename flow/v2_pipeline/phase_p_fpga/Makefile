ROOT := ../../..
RTL_DIR := $(ROOT)/IP/cpu_m1/rtl
SOC_DIR := $(ROOT)/IP/cpu_m1/soc
BUILD := build

RISCV_GCC ?= riscv-none-elf-gcc
RISCV_OBJCOPY ?= riscv-none-elf-objcopy
VERILATOR ?= verilator
VERILATOR_FLAGS := -sv -Wall -Wno-DECLFILENAME -Wno-TIMESCALEMOD \
	-Wno-PINCONNECTEMPTY -Wno-UNUSEDSIGNAL

PROGRAM := fpga_boot_magic
ELF := $(BUILD)/$(PROGRAM).elf
BIN := $(BUILD)/$(PROGRAM).bin
HEX := $(BUILD)/$(PROGRAM).hex
LOG := $(BUILD)/sim.log

RTL_SRCS := \
	$(RTL_DIR)/rfu.v \
	$(RTL_DIR)/alu.v \
	$(RTL_DIR)/idu.v \
	$(RTL_DIR)/ifu.v \
	$(RTL_DIR)/lsu.v \
	$(RTL_DIR)/csr.v \
	$(RTL_DIR)/mul.v \
	$(RTL_DIR)/div.v \
	$(RTL_DIR)/forward.v \
	$(RTL_DIR)/hazard.v \
	$(RTL_DIR)/bp.v \
	$(RTL_DIR)/ras.v \
	$(RTL_DIR)/cdec.v \
	$(RTL_DIR)/core.v \
	$(RTL_DIR)/cpu_m1_top.v \
	$(RTL_DIR)/axil_bridge.v \
	$(RTL_DIR)/cpu_m1_axil_top.v \
	$(SOC_DIR)/axil_bootrom.v \
	$(SOC_DIR)/axil_dp_bram.v \
	$(SOC_DIR)/cpu_m1_fpga_top.v

.PHONY: all run lint clean

all: run

$(BUILD):
	mkdir -p $(BUILD)

$(ELF): $(PROGRAM).S | $(BUILD)
	$(RISCV_GCC) -march=rv32imc -mabi=ilp32 -nostdlib -nostartfiles \
		-Wl,--no-relax -Wl,-Ttext=0x20000000 -Wl,-e,_start \
		-o $@ $<

$(BIN): $(ELF)
	$(RISCV_OBJCOPY) -O binary -j .text $< $@

$(HEX): $(BIN)
	xxd -e -g4 -c4 $< | awk '{print $$2}' > $@

lint: $(HEX)
	$(VERILATOR) --lint-only $(VERILATOR_FLAGS) \
		+incdir+$(RTL_DIR) $(RTL_SRCS) tb_cpu_m1_fpga_top.sv --top-module tb_cpu_m1_fpga_top

run: $(HEX)
	$(VERILATOR) --binary $(VERILATOR_FLAGS) \
		+incdir+$(RTL_DIR) $(RTL_SRCS) tb_cpu_m1_fpga_top.sv --top-module tb_cpu_m1_fpga_top
	./obj_dir/Vtb_cpu_m1_fpga_top | tee $(LOG)

clean:
	rm -rf $(BUILD) obj_dir
