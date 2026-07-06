ROOT := ../../..
RTL_DIR := $(ROOT)/design/cpu_m1/rtl
SOC_DIR := $(ROOT)/design/cpu_m1/soc

RISCV_PREFIX ?= /home/edauser/.local/opt/riscv/xpack-riscv-none-elf-gcc-13.2.0-2/bin/riscv-none-elf-
VIVADO ?= /tools/Xilinx/Vivado/2024.2/bin/vivado

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
	system_pynq_m1.v

all: sim vivado

firmware.elf: firmware.S firmware.c firmware.lds
	$(RISCV_PREFIX)gcc -Os -march=rv32imc -mabi=ilp32 \
	    -nostartfiles -nostdlib -ffreestanding \
	    -Wl,-Bstatic,-T,firmware.lds,--strip-debug \
	    -o $@ firmware.S firmware.c

firmware.bin: firmware.elf
	$(RISCV_PREFIX)objcopy -O binary $< $@

firmware.hex: firmware.bin hex32.py
	python3 hex32.py $< $@

firmware.disasm: firmware.elf
	$(RISCV_PREFIX)objdump -d $< > $@

sim: sim.log

sim.log: firmware.hex tb_system_pynq_m1.v $(RTL_SRCS)
	verilator -Wall -Wno-DECLFILENAME -Wno-UNUSEDSIGNAL -Wno-BLKSEQ \
	    --timing --binary --top-module tb_system_pynq_m1 \
	    -I$(RTL_DIR) tb_system_pynq_m1.v $(RTL_SRCS)
	./obj_dir/Vtb_system_pynq_m1 | tee $@

vivado: system_pynq_m1.bit

system_pynq_m1.bit: firmware.hex synth_pynq.tcl synth_pynq.xdc $(RTL_SRCS)
	$(VIVADO) -nojournal -log synth_pynq.log -mode batch -source synth_pynq.tcl

clean:
	rm -rf obj_dir firmware.elf firmware.bin firmware.hex firmware.disasm sim.log \
	    system_pynq_m1.bit synth_pynq.log *.jou .Xil usage_statistics_webtalk.* \
	    webtalk*.* vivado_pid*.str utilization.rpt timing.rpt system_pynq_m1.dcp

.PHONY: all sim vivado clean
