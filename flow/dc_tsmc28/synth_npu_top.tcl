# Magpie_M3V npu_top FULL DC synthesis (M3-signoff / ADR-0051 step1).
# Whole NPU: stripped+RVV cpu_m1 sequencer core + mat_engine + npu_dma + npu_ml_ctrl
# + npu_axil_regs + fabric. TCM (npu_tcm/npu_itcm) is BLACK-BOXED (SRAM macro; the
# mem arrays are not synthesized as flops). Flagship SKU: MAT_LANES=4, DMA_DATA_W=256,
# ML_V2_EN=1. Reports logic area/power/Fmax; TCM macro area is separate (memory compiler).

set clkp [expr {[info exists ::env(CLK_PERIOD)] ? $::env(CLK_PERIOD) : 2.0}]
set lanes [expr {[info exists ::env(MAT_LANES)] ? $::env(MAT_LANES) : 4}]
set dw    [expr {[info exists ::env(DMA_DATA_W)] ? $::env(DMA_DATA_W) : 256}]
set mlv2  [expr {[info exists ::env(ML_V2_EN)] ? $::env(ML_V2_EN) : 1}]

set here    [file normalize [file dirname [info script]]]
set root_dir [file normalize "$here/../.."]
set rpt_dir  [file normalize "$root_dir/reports/dc_npu_top"]
file mkdir $rpt_dir

source "$here/lib_setup.tcl"
set_app_var search_path [concat [get_app_var search_path] \
    [list "$root_dir/design/cpu_m1/rtl" "$root_dir/design/npu/rtl"]]
set_app_var hdlin_enable_vpp true

define_design_lib WORK -path "$here/work_npu_top"

# cpu_m1 stripped+RVV sequencer core (no fexu; bp/ras compiled but param-disabled)
set cpu_m1 {rfu alu bmu idu ifu lsu csr trigger pmp mul div forward hazard bp ras cdec vexu core cpu_m1_top}
foreach m $cpu_m1 { analyze -format sverilog -define SYNTHESIS "$root_dir/design/cpu_m1/rtl/$m.v" }
# npu domain logic
foreach m {npu_axil_regs npu_dma npu_ml_ctrl mat_engine axil_decerr} {
    analyze -format sverilog -define SYNTHESIS "$root_dir/design/npu/rtl/$m.v"
}
# TCM black-box stub (SRAM macro hole) INSTEAD of the real npu_tcm.v
analyze -format sverilog "$here/npu_tcm_bb.v"
analyze -format sverilog -define SYNTHESIS "$root_dir/design/npu/rtl/npu_top.v"

elaborate npu_top -parameters "MAT_LANES=$lanes, DMA_DATA_W=$dw, ML_V2_EN=$mlv2"
current_design [lindex [get_designs -quiet "npu_top*"] 0]
link
check_design > "$rpt_dir/check_design.rpt"

create_clock -name clk -period $clkp [get_ports clk]
set_clock_uncertainty 0.05 [get_clocks clk]
set_input_delay  [expr {$clkp*0.3}] -clock clk [remove_from_collection [all_inputs] [get_ports clk]]
set_output_delay [expr {$clkp*0.3}] -clock clk [all_outputs]
set_max_area 0

compile_ultra

report_qor                            > "$rpt_dir/dc.qor.rpt"
report_area -hierarchy                > "$rpt_dir/dc.area.rpt"
report_power -analysis_effort low     > "$rpt_dir/dc.power.rpt"
report_timing -max_paths 12 -nworst 4 > "$rpt_dir/dc.timing.rpt"

puts "MAGPIE_M3V npu_top FULL synth done LANES=$lanes DW=$dw ML_V2=$mlv2 CLK=$clkp -> $rpt_dir"
exit
