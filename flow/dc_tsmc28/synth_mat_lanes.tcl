# Magpie_M3V mat_engine DC synthesis — LANES SKU PPA sweep (ADR-0067).
# Synthesizes mat_engine at a chosen K-fusion width LANES in {1,2,4} => 64/128/256
# MAC, at a FIXED clock, and reports area + power + timing so the three SKUs are
# compared apples-to-apples. LANES is passed via the LANES env var.
#   LANES=1 make -f ... (64 MAC)  /  LANES=2 (128)  /  LANES=4 (256, = today)
# Fmax is set by the S_RSC requant path (ADR-0053), NOT the MAC, so all three
# meet the same clock; the delta is MAC-tree AREA + POWER only.

set lanes [expr {[info exists ::env(LANES)] ? $::env(LANES) : 4}]
set clkp  [expr {[info exists ::env(CLK_PERIOD)] ? $::env(CLK_PERIOD) : 1.2}]

set here    [file normalize [file dirname [info script]]]
set root_dir [file normalize "$here/../.."]
set rpt_dir  [file normalize "$root_dir/reports/dc_mat_lanes/L$lanes"]
file mkdir $rpt_dir

source "$here/lib_setup.tcl"

define_design_lib WORK -path "$here/work_l$lanes"
analyze -format sverilog -define SYNTHESIS "$root_dir/design/npu/rtl/mat_engine.v"
elaborate mat_engine -parameters "LANES=$lanes"
current_design mat_engine
link

# same SDC as the baseline flow, but honor a per-run CLK_PERIOD
create_clock -name clk -period $clkp [get_ports clk]
set_input_delay  [expr {$clkp*0.3}] -clock clk [remove_from_collection [all_inputs] [get_ports clk]]
set_output_delay [expr {$clkp*0.3}] -clock clk [all_outputs]
set_max_area 0

compile_ultra

report_qor                            > "$rpt_dir/dc.qor.rpt"
report_area                           > "$rpt_dir/dc.area.rpt"
report_power                          > "$rpt_dir/dc.power.rpt"
report_timing -max_paths 8 -nworst 4  > "$rpt_dir/dc.timing.rpt"

# one-line machine-readable summary for the PPA table
set qor [open "$rpt_dir/dc.qor.rpt" r]; set qtxt [read $qor]; close $qor
puts "MAGPIE_M3V LANES=$lanes CLK=$clkp synthesis done -> $rpt_dir"
exit
