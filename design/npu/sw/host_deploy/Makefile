TOOLCHAIN_DIR    = /home/edauser/miniforge3/pkgs/riscv-tools-1.0.6-0_h1234567_g56c29e0/riscv-tools/bin
TOOLCHAIN_PREFIX = $(TOOLCHAIN_DIR)/riscv64-unknown-elf-
TOOLCHAIN_LIBS   = /home/edauser/miniforge3/pkgs/mpfr-4.2.2-he0a73b1_0/lib:/home/edauser/miniforge3/pkgs/gmp-6.3.0-hac33072_2/lib:/home/edauser/miniforge3/pkgs/mpc-1.4.0-he0a73b1_0/lib
TOOLCHAIN_ENV    = LD_LIBRARY_PATH=$(TOOLCHAIN_LIBS)

GCC_MARCH = rv32im_zicsr_zifencei
GCC_MABI  = ilp32
CFLAGS    = -march=$(GCC_MARCH) -mabi=$(GCC_MABI) -Os -ffreestanding -fno-builtin -nostartfiles -nostdlib -I../host_producer

.PHONY: all clean

all: host_deploy.flashhex

../host_producer/npu_fw_load.inc:
	$(MAKE) -C ../host_producer npu_fw_load.inc

# XIP-only firmware: linked straight into the flash window (crt0/ld shared
# conventions with host_producer's xip link).
host_deploy.elf: crt0.S host_deploy.c host_deploy.ld ../host_producer/npu_fw_load.inc
	$(TOOLCHAIN_ENV) $(TOOLCHAIN_PREFIX)gcc $(CFLAGS) -Wl,-Bstatic,-T,host_deploy.ld,--strip-debug -o $@ crt0.S host_deploy.c

host_deploy.flashhex: host_deploy.elf
	$(TOOLCHAIN_ENV) $(TOOLCHAIN_PREFIX)objcopy -O verilog --verilog-data-width=1 --change-addresses -0x40000000 $< $@
	sed -i 's/\r$$//' $@

clean:
	rm -f host_deploy.elf host_deploy.flashhex
