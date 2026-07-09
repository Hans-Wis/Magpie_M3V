TOOLCHAIN_DIR    = /home/edauser/miniforge3/pkgs/riscv-tools-1.0.6-0_h1234567_g56c29e0/riscv-tools/bin
TOOLCHAIN_PREFIX = $(TOOLCHAIN_DIR)/riscv64-unknown-elf-
TOOLCHAIN_LIBS   = /home/edauser/miniforge3/pkgs/mpfr-4.2.2-he0a73b1_0/lib:/home/edauser/miniforge3/pkgs/gmp-6.3.0-hac33072_2/lib:/home/edauser/miniforge3/pkgs/mpc-1.4.0-he0a73b1_0/lib
TOOLCHAIN_ENV    = LD_LIBRARY_PATH=$(TOOLCHAIN_LIBS)

GCC_MARCH = rv32im_zicsr_zifencei
GCC_MABI  = ilp32
CFLAGS    = -march=$(GCC_MARCH) -mabi=$(GCC_MABI) -Os -ffreestanding -fno-builtin -nostartfiles -nostdlib
LDFLAGS   = -Wl,-Bstatic,-T,host_producer.ld,--strip-debug

.PHONY: all clean size

all: host_producer.hex

npu_fw_load.inc: gen_npu_fw_inc.py ../cq_sequencer/firmware.hex
	python3 gen_npu_fw_inc.py

host_producer.elf: crt0.S host_producer.c host_producer.ld npu_fw_load.inc
	$(TOOLCHAIN_ENV) $(TOOLCHAIN_PREFIX)gcc $(CFLAGS) $(LDFLAGS) -o $@ crt0.S host_producer.c

host_producer.hex: host_producer.elf
	$(TOOLCHAIN_ENV) $(TOOLCHAIN_PREFIX)objcopy -O verilog --verilog-data-width=4 $< $@
	sed -i 's/\r$$//' $@

size: host_producer.elf
	$(TOOLCHAIN_ENV) $(TOOLCHAIN_PREFIX)size $<

# gate_86 XIP-boot image: same sources, VMA in the QSPI window; byte-wide hex
# rebased to flash offset 0 for spi_nor_model $readmemh.
xip: host_producer_xip.flashhex

host_producer_xip.elf: crt0.S host_producer.c host_producer_xip.ld npu_fw_load.inc
	$(TOOLCHAIN_ENV) $(TOOLCHAIN_PREFIX)gcc $(CFLAGS) -Wl,-Bstatic,-T,host_producer_xip.ld,--strip-debug -o $@ crt0.S host_producer.c

host_producer_xip.flashhex: host_producer_xip.elf
	$(TOOLCHAIN_ENV) $(TOOLCHAIN_PREFIX)objcopy -O verilog --verilog-data-width=1 --change-addresses -0x40000000 $< $@
	sed -i 's/\r$$//' $@

clean:
	rm -f host_producer.elf host_producer.hex host_producer.disasm npu_fw_load.inc \
	      host_producer_xip.elf host_producer_xip.flashhex
