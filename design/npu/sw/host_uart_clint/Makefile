TOOLCHAIN_DIR    = /home/edauser/miniforge3/pkgs/riscv-tools-1.0.6-0_h1234567_g56c29e0/riscv-tools/bin
TOOLCHAIN_PREFIX = $(TOOLCHAIN_DIR)/riscv64-unknown-elf-
TOOLCHAIN_LIBS   = /home/edauser/miniforge3/pkgs/mpfr-4.2.2-he0a73b1_0/lib:/home/edauser/miniforge3/pkgs/gmp-6.3.0-hac33072_2/lib:/home/edauser/miniforge3/pkgs/mpc-1.4.0-he0a73b1_0/lib
TOOLCHAIN_ENV    = LD_LIBRARY_PATH=$(TOOLCHAIN_LIBS)

GCC_MARCH = rv32im_zicsr_zifencei
GCC_MABI  = ilp32
CFLAGS    = -march=$(GCC_MARCH) -mabi=$(GCC_MABI) -Os -ffreestanding -fno-builtin -nostartfiles -nostdlib -msmall-data-limit=0 -mno-relax
LDFLAGS   = -Wl,-Bstatic,-T,host_uart_clint.ld,--strip-debug

.PHONY: all clean size

all: host_uart_clint.hex

host_uart_clint.elf: crt0.S host_uart_clint.c host_uart_clint.ld
	$(TOOLCHAIN_ENV) $(TOOLCHAIN_PREFIX)gcc $(CFLAGS) $(LDFLAGS) -o $@ crt0.S host_uart_clint.c

host_uart_clint.hex: host_uart_clint.elf
	$(TOOLCHAIN_ENV) $(TOOLCHAIN_PREFIX)objcopy -O verilog --verilog-data-width=4 $< $@
	sed -i 's/\r$$//' $@

size: host_uart_clint.elf
	$(TOOLCHAIN_ENV) $(TOOLCHAIN_PREFIX)size $<

clean:
	rm -f host_uart_clint.elf host_uart_clint.hex host_uart_clint.disasm
