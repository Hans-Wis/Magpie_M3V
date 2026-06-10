set top_name cpu_m1_asic_top
set target_period_ns 1.43
set phase_dir "/home/edauser/project/SOC/Magpie_M1/flow/v2_pipeline/phase_p_asic"
set filelist_path [file join $phase_dir files.f]
set stdcell_db "/home/edauser/project/SOC/Magpie_X3/APR/ref/db/tcbn28hpcplusbwp40p140tt0p9v25c.db"
set sram_db "/home/edauser/project/SOC/Magpie_X3/APR/ref/db/tsdn28hpcpa512x32m4mwaso_130a_tt0p9v25c.db"
cd $phase_dir

proc timestamp {} {
    return [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%S%z"]
}

proc first_regexp_match {path pattern default_value} {
    if {![file exists $path]} {
        return $default_value
    }
    set fp [open $path r]
    set text [read $fp]
    close $fp
    if {[regexp -line -- $pattern $text -> value]} {
        return $value
    }
    return $default_value
}

file mkdir reports db work logs
set status_path [file join $phase_dir reports status.txt]
set prov_path [file join $phase_dir reports provenance.log]
set prov [open $prov_path w]
puts $prov "timestamp=[timestamp]"
puts $prov "host=[exec hostname]"
puts $prov "dc_shell_version=[get_app_var sh_product_version]"
puts $prov "tool_path=[info nameofexecutable]"
puts $prov "top=$top_name"
puts $prov "target_period_ns=$target_period_ns"
puts $prov "stdcell_db=$stdcell_db"
puts $prov "sram_db=$sram_db"
puts $prov "rtl_filelist=$filelist_path"
puts $prov "constraints=mirrors phase_05_01_synth_ppa/run_dc.tcl"
close $prov

if {![file exists $stdcell_db]} {
    set sfp [open $status_path w]
    puts $sfp "status=missing_stdcell_db"
    puts $sfp "stdcell_db=$stdcell_db"
    close $sfp
    quit
}
if {![file exists $sram_db]} {
    set sfp [open $status_path w]
    puts $sfp "status=missing_sram_db"
    puts $sfp "sram_db=$sram_db"
    close $sfp
    quit
}

define_design_lib WORK -path work
set_app_var search_path [list . ../../../IP/cpu_m1/rtl/pipeline_v2/ch2_lab08e [file dirname $stdcell_db] [file dirname $sram_db]]
set_app_var target_library [list $stdcell_db]
set_app_var link_library [concat "*" [list $stdcell_db] [list $sram_db] [list dw_foundation.sldb]]
set_app_var synthetic_library [list dw_foundation.sldb]
set_app_var hdlin_enable_vpp true
set_app_var hdlin_infer_multibit default_all

set failed 0
set err_msg ""
if {[catch {
    analyze -format verilog -vcs "-f $filelist_path"
    elaborate $top_name
    current_design $top_name
    link
    check_design > reports/check_design.rpt

    create_clock -name clk -period $target_period_ns [get_ports clk]
    set_clock_uncertainty 0.05 [get_clocks clk]
    set_input_delay 0.10 -clock clk [remove_from_collection [all_inputs] [get_ports clk]]
    set_output_delay 0.10 -clock clk [all_outputs]
    set_driving_cell -lib_cell BUFFD1BWP40P140 [remove_from_collection [all_inputs] [get_ports clk]]
    set_load 0.01 [all_outputs]

    compile_ultra

    report_qor > reports/qor.rpt
    report_area -hierarchy > reports/area.rpt
    report_timing -delay_type max -max_paths 20 -nworst 5 > reports/timing.rpt
    report_power -analysis_effort low > reports/power.rpt
    report_constraint -all_violators > reports/constraints.rpt
    write -format ddc -hierarchy -output db/${top_name}.ddc
    write -format verilog -hierarchy -output db/${top_name}.mapped.v
} err_msg]} {
    set failed 1
}

if {$failed} {
    set sfp [open $status_path w]
    puts $sfp "status=failed"
    puts $sfp "error=$err_msg"
    close $sfp
    quit
}

set wns [first_regexp_match reports/qor.rpt {Design[ ]+WNS:[ ]+([-0-9.]+)} "NA"]
set tns [first_regexp_match reports/qor.rpt {Design[ ]+WNS:[ ]+[-0-9.]+[ ]+TNS:[ ]+([-0-9.]+)} "NA"]
set area [first_regexp_match reports/area.rpt {Total cell area:[ ]+([-0-9.]+)} "NA"]

if {$wns eq "NA"} {
    set fmax "NA"
} else {
    set critical_period [expr {$target_period_ns - $wns}]
    if {$critical_period <= 0.0} {
        set fmax "NA"
    } else {
        set fmax [format "%.2f" [expr {1000.0 / $critical_period}]]
    }
}

set sfp [open $status_path w]
puts $sfp "status=complete"
puts $sfp "fmax_mhz=$fmax"
puts $sfp "wns_ns=$wns"
puts $sfp "tns_ns=$tns"
puts $sfp "area_um2=$area"
puts $sfp "stdcell_db=$stdcell_db"
puts $sfp "sram_db=$sram_db"
close $sfp

quit
