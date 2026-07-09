# Standalone DC synthesis of fexu (scalar RV32F EXU) — PoC timing probe for the
# fdiv multi-cycle change (ed61f50). EN_F=1 so all FP logic is present. Fast
# `compile` pass; reports the worst path so we can see whether the fdiv
# combinational divide array has left the critical path (and what the next wall
# is — expected fsqrt, which shares the result mux).
set clkp [expr {[info exists ::env(CLK_PERIOD)] ? $::env(CLK_PERIOD) : 3.0}]
set here    [file normalize [file dirname [info script]]]
set root_dir [file normalize "$here/../.."]
set rpt_dir  [file normalize "$root_dir/reports/dc_fexu"]
file mkdir $rpt_dir
source "$here/lib_setup.tcl"
set_app_var search_path [concat [get_app_var search_path] [list "$root_dir/design/cpu_m1/rtl"]]
set_app_var hdlin_enable_vpp true
define_design_lib WORK -path "$here/work_fexu"

analyze -format sverilog -define SYNTHESIS "$root_dir/design/cpu_m1/rtl/fexu.v"
elaborate fexu -parameters "EN_F=1"
current_design [lindex [get_designs -quiet "fexu*"] 0]
link

create_clock -name clk -period $clkp [get_ports clk]
set_clock_uncertainty 0.05 [get_clocks clk]
set_input_delay  [expr {$clkp*0.3}] -clock clk [remove_from_collection [all_inputs] [get_ports clk]]
set_output_delay [expr {$clkp*0.3}] -clock clk [all_outputs]
set_max_area 0

compile -map_effort medium -area_effort low

report_qor                            > "$rpt_dir/dc.qor.rpt"
report_area                           > "$rpt_dir/dc.area.rpt"
report_timing -max_paths 8 -nworst 4  > "$rpt_dir/dc.timing.rpt"
puts "MAGPIE_M3V fexu synth done CLK=$clkp -> $rpt_dir"
exit
