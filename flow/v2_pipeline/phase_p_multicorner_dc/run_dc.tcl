set top_name cpu_m1_top
set target_period_ns 1.43
set phase_dir "/home/edauser/project/SOC/Magpie_M1/flow/v2_pipeline/phase_p_multicorner_dc"
set filelist_path [file join $phase_dir files.f]
cd $phase_dir

set corners {
    {TT nominal /home/edauser/project/SOC/Magpie_X3/APR/ref/db/tcbn28hpcplusbwp40p140tt0p9v25c.db}
    {SLOW setup_fmax /home/edauser/project/SOC/Magpie_M1/flow/v2_pipeline/phase_p_multicorner_dc/compiled_db/tcbn28hpcplusbwp40p140ssg0p81v0c.db}
    {FAST hold_leak /home/edauser/project/SOC/Magpie_M1/flow/v2_pipeline/phase_p_multicorner_dc/compiled_db/tcbn28hpcplusbwp40p140ffg0p88v125c.db}
}

proc timestamp {} {
    return [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%S%z"]
}

proc format_float {value digits} {
    if {$value eq "NA"} {
        return "NA"
    }
    return [format "%.${digits}f" $value]
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

proc run_corner {corner role target_library_path} {
    global top_name target_period_ns filelist_path

    global phase_dir

    set run_dir [file join $phase_dir runs $corner]
    set rpt_dir [file join $phase_dir reports $corner]
    set db_dir [file join $phase_dir db $corner]
    set work_dir [file join $phase_dir work $corner]
    set log_dir [file join $phase_dir logs $corner]

    file mkdir $run_dir $rpt_dir $db_dir $work_dir $log_dir

    set prov_path [file join $run_dir provenance.log]
    set prov [open $prov_path w]
    puts $prov "timestamp=[timestamp]"
    puts $prov "host=[exec hostname]"
    puts $prov "dc_shell_version=[get_app_var sh_product_version]"
    puts $prov "tool_path=[info nameofexecutable]"
    puts $prov "mode=full_per_corner_resynthesis"
    puts $prov "top=$top_name"
    puts $prov "target_period_ns=$target_period_ns"
    puts $prov "target_frequency_mhz=[format_float [expr {1000.0 / $target_period_ns}] 2]"
    puts $prov "corner=$corner"
    puts $prov "corner_role=$role"
    puts $prov "target_library_path=$target_library_path"
    puts $prov "search_path=. ../../../design/cpu_m1/rtl/pipeline_v2/ch2_lab08e [file dirname $target_library_path]"
    puts $prov "target_library=$target_library_path"
    puts $prov "link_library=* $target_library_path dw_foundation.sldb"
    puts $prov "synthetic_library=dw_foundation.sldb"
    puts $prov "hdlin_enable_vpp=true"
    puts $prov "hdlin_infer_multibit=default_all"
    puts $prov "rtl_filelist=$filelist_path"
    puts $prov "constraints=mirrors flow/v2_pipeline/phase_05_01_synth_ppa/run_dc.tcl"
    close $prov

    set status_path [file join $run_dir status.txt]
    if {![file exists $target_library_path]} {
        set sfp [open $status_path w]
        puts $sfp "status=missing_library"
        puts $sfp "target_library_path=$target_library_path"
        close $sfp
        return [list $corner NA NA NA NA NA missing_library $target_library_path]
    }

    remove_design -all
    define_design_lib WORK -path $work_dir

    set_app_var search_path [list . ../../../design/cpu_m1/rtl/pipeline_v2/ch2_lab08e [file dirname $target_library_path]]
    set_app_var target_library [list $target_library_path]
    set_app_var link_library [concat "*" [list $target_library_path] [list dw_foundation.sldb]]
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
        check_design > [file join $rpt_dir check_design.rpt]

        create_clock -name clk -period $target_period_ns [get_ports clk]
        set_clock_uncertainty 0.05 [get_clocks clk]
        set_input_delay 0.10 -clock clk [remove_from_collection [all_inputs] [get_ports clk]]
        set_output_delay 0.10 -clock clk [all_outputs]
        set_driving_cell -lib_cell BUFFD1BWP40P140 [remove_from_collection [all_inputs] [get_ports clk]]
        set_load 0.01 [all_outputs]

        compile_ultra

        report_qor > [file join $rpt_dir qor.rpt]
        report_area -hierarchy > [file join $rpt_dir area.rpt]
        report_timing -delay_type max -max_paths 20 -nworst 5 > [file join $rpt_dir timing.rpt]
        report_timing -delay_type min -max_paths 20 -nworst 5 > [file join $rpt_dir timing_min.rpt]
        report_power -analysis_effort low > [file join $rpt_dir power.rpt]
        report_constraint -all_violators > [file join $rpt_dir constraints.rpt]
        write -format ddc -hierarchy -output [file join $db_dir ${top_name}.ddc]
        write -format verilog -hierarchy -output [file join $db_dir ${top_name}.mapped.v]
    } err_msg]} {
        set failed 1
    }

    if {$failed} {
        set sfp [open $status_path w]
        puts $sfp "status=failed"
        puts $sfp "error=$err_msg"
        puts $sfp "target_library_path=$target_library_path"
        close $sfp
        return [list $corner NA NA NA NA NA failed $target_library_path]
    }

    set qor_path [file join $rpt_dir qor.rpt]
    set area_path [file join $rpt_dir area.rpt]
    set power_path [file join $rpt_dir power.rpt]

    set wns [first_regexp_match $qor_path {Design[ ]+WNS:[ ]+([-0-9.]+)} "NA"]
    set tns [first_regexp_match $qor_path {Design[ ]+WNS:[ ]+[-0-9.]+[ ]+TNS:[ ]+([-0-9.]+)} "NA"]
    set area [first_regexp_match $area_path {Total cell area:[ ]+([-0-9.]+)} "NA"]
    set power [first_regexp_match $power_path {^[ ]*Total[ ]+[-0-9.eE+]+[ ]+mW[ ]+[-0-9.eE+]+[ ]+mW[ ]+[-0-9.eE+]+[ ]+nW[ ]+([-0-9.eE+]+)[ ]+mW} "NA"]

    if {$wns eq "NA"} {
        set fmax "NA"
    } else {
        set critical_period [expr {$target_period_ns - $wns}]
        if {$critical_period <= 0.0} {
            set fmax "NA"
        } else {
            set fmax [format_float [expr {1000.0 / $critical_period}] 2]
        }
    }

    if {$area eq "0.000000" || $area eq "0"} {
        set sfp [open $status_path w]
        puts $sfp "status=failed_zero_area"
        puts $sfp "target_library_path=$target_library_path"
        puts $sfp "quality_error=zero_area_indicates_unmapped_or_missing_target_library"
        close $sfp
        return [list $corner NA NA NA NA NA failed_zero_area $target_library_path]
    }

    set sfp [open $status_path w]
    puts $sfp "status=complete"
    puts $sfp "target_library_path=$target_library_path"
    puts $sfp "fmax_mhz=$fmax"
    puts $sfp "wns_ns=$wns"
    puts $sfp "tns_ns=$tns"
    puts $sfp "area_um2=$area"
    puts $sfp "power_mw=$power"
    close $sfp

    return [list $corner $fmax $wns $tns $area $power complete $target_library_path]
}

file mkdir [file join $phase_dir reports] [file join $phase_dir db] [file join $phase_dir work] [file join $phase_dir logs] [file join $phase_dir runs]
set summary_path [file join $phase_dir qor_summary.tsv]
set summary [open $summary_path w]
puts $summary "corner\tfmax_mhz\twns_ns\ttns_ns\tarea_um2\tpower_mw\tstatus\ttarget_library_path"

foreach corner_spec $corners {
    lassign $corner_spec corner role target_library_path
    set result [run_corner $corner $role $target_library_path]
    puts $summary [join $result "\t"]
    flush $summary
}

close $summary
quit
