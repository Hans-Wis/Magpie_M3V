# Magpie_M3V npu_dma DC synthesis — DMA_DATA_W SKU PPA sweep (M3c, ADR-0068/M3).
# Synthesizes npu_dma (the DMA datapath+FSM, std-cell only, NO mem array) at a
# chosen AXI data width DMA_DATA_W in {32,64,128,256}, at a FIXED clock, and
# reports area+power+timing so the four width SKUs are compared apples-to-apples.
# DMA_DATA_W is passed via the DMA_DATA_W env var:
#   DMA_DATA_W=32 (regression) / 64 (LANES1) / 128 (LANES2) / 256 (LANES4)
# The area/power delta is the wide datapath (m_rdata/m_wdata/wstrb/wdata_mux +
# WPB burst math) cost. TCM/SRAM mem arrays are macros, NOT synthesized here.

set w    [expr {[info exists ::env(DMA_DATA_W)] ? $::env(DMA_DATA_W) : 32}]
set clkp [expr {[info exists ::env(CLK_PERIOD)] ? $::env(CLK_PERIOD) : 1.2}]

set here    [file normalize [file dirname [info script]]]
set root_dir [file normalize "$here/../.."]
set rpt_dir  [file normalize "$root_dir/reports/dc_npu_dma/W$w"]
file mkdir $rpt_dir

source "$here/lib_setup.tcl"

define_design_lib WORK -path "$here/work_dma_w$w"
analyze -format sverilog -define SYNTHESIS "$root_dir/design/npu/rtl/npu_dma.v"
elaborate npu_dma -parameters "DMA_DATA_W=$w"
# DC suffixes the elaborated name with the param value (npu_dma_DMA_DATA_W<w>);
# select it by glob rather than the bare module name.
current_design [lindex [get_designs -quiet "npu_dma*"] 0]
link

create_clock -name clk -period $clkp [get_ports clk]
set_input_delay  [expr {$clkp*0.3}] -clock clk [remove_from_collection [all_inputs] [get_ports clk]]
set_output_delay [expr {$clkp*0.3}] -clock clk [all_outputs]
set_max_area 0

compile_ultra

report_qor                            > "$rpt_dir/dc.qor.rpt"
report_area                           > "$rpt_dir/dc.area.rpt"
report_power                          > "$rpt_dir/dc.power.rpt"
report_timing -max_paths 8 -nworst 4  > "$rpt_dir/dc.timing.rpt"

puts "MAGPIE_M3V DMA_DATA_W=$w CLK=$clkp synthesis done -> $rpt_dir"
exit
