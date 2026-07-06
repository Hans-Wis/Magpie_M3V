set root [file normalize "../../.."]

read_verilog -sv [file join $root design/cpu_m1/rtl/def.vh]
read_verilog -sv [file join $root design/cpu_m1/rtl/rfu.v]
read_verilog -sv [file join $root design/cpu_m1/rtl/alu.v]
read_verilog -sv [file join $root design/cpu_m1/rtl/idu.v]
read_verilog -sv [file join $root design/cpu_m1/rtl/ifu.v]
read_verilog -sv [file join $root design/cpu_m1/rtl/lsu.v]
read_verilog -sv [file join $root design/cpu_m1/rtl/csr.v]
read_verilog -sv [file join $root design/cpu_m1/rtl/mul.v]
read_verilog -sv [file join $root design/cpu_m1/rtl/div.v]
read_verilog -sv [file join $root design/cpu_m1/rtl/forward.v]
read_verilog -sv [file join $root design/cpu_m1/rtl/hazard.v]
read_verilog -sv [file join $root design/cpu_m1/rtl/bp.v]
read_verilog -sv [file join $root design/cpu_m1/rtl/ras.v]
read_verilog -sv [file join $root design/cpu_m1/rtl/cdec.v]
read_verilog -sv [file join $root design/cpu_m1/rtl/core.v]
read_verilog -sv [file join $root design/cpu_m1/rtl/cpu_m1_top.v]
read_verilog -sv [file join $root design/cpu_m1/rtl/axil_bridge.v]
read_verilog -sv [file join $root design/cpu_m1/rtl/cpu_m1_axil_top.v]
read_verilog -sv [file join $root design/cpu_m1/soc/axil_bootrom.v]
read_verilog -sv [file join $root design/cpu_m1/soc/axil_dp_bram.v]
read_verilog -sv system_pynq_m1.v
read_xdc synth_pynq.xdc

synth_design -part xc7z020clg400-1 -top system_pynq_m1
opt_design
place_design
phys_opt_design
route_design

report_utilization -file utilization.rpt
report_timing_summary -file timing.rpt

write_checkpoint -force system_pynq_m1.dcp
write_bitstream -force system_pynq_m1.bit
