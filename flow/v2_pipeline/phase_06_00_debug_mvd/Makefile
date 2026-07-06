RTL=../../../design/cpu_m1/rtl
SOC=../../../design/cpu_m1/soc
VERILATOR?=verilator

RTL_SRCS=$(RTL)/rfu.v $(RTL)/alu.v $(RTL)/idu.v $(RTL)/ifu.v $(RTL)/lsu.v \
	$(RTL)/csr.v $(RTL)/trigger.v $(RTL)/mul.v $(RTL)/div.v $(RTL)/forward.v $(RTL)/hazard.v \
	$(RTL)/bp.v $(RTL)/ras.v $(RTL)/cdec.v $(RTL)/core.v $(SOC)/dm.v

.PHONY: all clean
all: sim.log

obj_dir/Vtb_debug_mvd: tb_debug_mvd.v $(RTL_SRCS)
	$(VERILATOR) --binary -j 4 --coverage --top-module tb_debug_mvd --timescale 1ns/1ns \
		-I$(RTL) -I$(SOC) -Wall -Wno-PROCASSINIT -Wno-DECLFILENAME \
		-Wno-TIMESCALEMOD -Wno-UNUSEDSIGNAL -Wno-SYNCASYNCNET \
		$(RTL_SRCS) tb_debug_mvd.v

sim.log coverage.dat: obj_dir/Vtb_debug_mvd
	./obj_dir/Vtb_debug_mvd | tee sim.log

clean:
	rm -rf obj_dir sim.log
