RTL=../../../IP/cpu_m1/rtl
SOC=../../../IP/cpu_m1/soc
VERILATOR?=verilator
SHELL:=/bin/bash
.SHELLFLAGS:=-o pipefail -c

RTL_SRCS=$(RTL)/rfu.v $(RTL)/alu.v $(RTL)/idu.v $(RTL)/ifu.v $(RTL)/lsu.v \
	$(RTL)/csr.v $(RTL)/mul.v $(RTL)/div.v $(RTL)/forward.v $(RTL)/hazard.v \
	$(RTL)/trigger.v $(RTL)/bp.v $(RTL)/ras.v $(RTL)/cdec.v $(RTL)/core.v $(SOC)/dm.v \
	$(SOC)/dtm.v

.PHONY: all clean openocd-smoke bridge
all: sim.log

obj_dir/Vtb_debug_jtag: tb_debug_jtag.v $(RTL_SRCS)
	$(VERILATOR) --binary -j 4 --top-module tb_debug_jtag --timescale 1ns/1ns \
		-I$(RTL) -I$(SOC) -Wall -Wno-PROCASSINIT -Wno-DECLFILENAME \
		-Wno-TIMESCALEMOD -Wno-UNUSEDSIGNAL -Wno-SYNCASYNCNET \
		$(RTL_SRCS) tb_debug_jtag.v

sim.log: obj_dir/Vtb_debug_jtag
	./obj_dir/Vtb_debug_jtag | tee sim.log

obj_dir/Vtb_debug_openocd: tb_debug_openocd.v remote_bitbang_main.cpp $(RTL_SRCS)
	$(VERILATOR) --cc --exe --build -j 4 --top-module tb_debug_openocd --timescale 1ns/1ns \
		-I$(RTL) -I$(SOC) -Wall -Wno-PROCASSINIT -Wno-DECLFILENAME \
		-Wno-TIMESCALEMOD -Wno-UNUSEDSIGNAL -Wno-SYNCASYNCNET \
		$(RTL_SRCS) tb_debug_openocd.v remote_bitbang_main.cpp

bridge: obj_dir/Vtb_debug_openocd

openocd-smoke:
	./openocd_smoke.sh | tee openocd_smoke.log

clean:
	rm -rf obj_dir sim.log openocd_smoke.log sim_remote_bitbang.log openocd_stdout.log
