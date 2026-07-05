# Magpie_M3V mat_engine DC synthesis — Fmax + critical-path locator (ADR-0051).
# Answers the ADR-0051 open question: is the npu_top critical path the S_RUN
# 256-MAC + loop-carried accumulate, or the S_RSC 32x32 requant multiply?
# The worst-path ENDPOINT decides: acc_reg* => S_RUN; pack_q*/t_wdata* => S_RSC.

set here    [file normalize [file dirname [info script]]]
set root_dir [file normalize "$here/../.."]
set rpt_dir  [file normalize "$root_dir/reports/dc_mat_pipe_1p0"]
file mkdir $rpt_dir

source "$here/lib_setup.tcl"

define_design_lib WORK -path "$here/work"
analyze -format sverilog -define SYNTHESIS "$root_dir/IP/npu/rtl/mat_engine.v"
elaborate mat_engine
current_design mat_engine
link

source "$here/constraints_mat.sdc"

compile_ultra

report_qor                                   > "$rpt_dir/dc.qor.rpt"
report_timing -max_paths 30 -nworst 6        > "$rpt_dir/dc.timing.rpt"
# explicitly isolate the two suspects (guarded: empty match must not abort)
if {![catch {set c [get_cells -hier acc_reg*]}] && [sizeof_collection $c] > 0} {
    report_timing -to $c -max_paths 5 > "$rpt_dir/dc.timing.s_run.rpt"
}
if {![catch {set p [get_ports t_wdata*]}] && [sizeof_collection $p] > 0} {
    report_timing -to $p -max_paths 5 > "$rpt_dir/dc.timing.s_rsc.rpt"
}
report_area                                  > "$rpt_dir/dc.area.rpt"
write -format verilog -hierarchy -output "$rpt_dir/mat_engine.gate.v"

puts "MAGPIE_M3V mat_engine TSMC28 synthesis done"
exit
