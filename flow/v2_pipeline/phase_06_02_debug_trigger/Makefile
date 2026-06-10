RTL=../../../IP/cpu_m1/rtl
SOC=../../../IP/cpu_m1/soc
VERILATOR?=verilator

RTL_SRCS=$(RTL)/rfu.v $(RTL)/alu.v $(RTL)/idu.v $(RTL)/ifu.v $(RTL)/lsu.v \
	$(RTL)/csr.v $(RTL)/trigger.v $(RTL)/mul.v $(RTL)/div.v $(RTL)/forward.v $(RTL)/hazard.v \
	$(RTL)/bp.v $(RTL)/ras.v $(RTL)/cdec.v $(RTL)/core.v $(SOC)/dm.v

.PHONY: all clean
all: sim.log

obj_dir/Vtb_debug_trigger: tb_debug_trigger.v $(RTL_SRCS)
	$(VERILATOR) --binary -j 4 --top-module tb_debug_trigger --timescale 1ns/1ns \
		-I$(RTL) -I$(SOC) -Wall -Wno-PROCASSINIT -Wno-DECLFILENAME \
		-Wno-TIMESCALEMOD -Wno-UNUSEDSIGNAL -Wno-SYNCASYNCNET \
		$(RTL_SRCS) tb_debug_trigger.v

sim.log: obj_dir/Vtb_debug_trigger
	./obj_dir/Vtb_debug_trigger | tee sim.log

clean:
	rm -rf obj_dir sim.log
