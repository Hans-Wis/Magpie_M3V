# TSMC28 (28HPC+) library setup for Magpie_M3V DC scripts.
# tcbn28hpcplusbwp40p140 tt 0.9V 25C — the same std-cell library as the
# cpu_m1_top ~699MHz trial. std-cell only (mat_engine has no SRAM macro;
# the TCM sits outside the engine as read/write ports).

set t28_root [expr {[info exists ::env(T28_ROOT)] ? $::env(T28_ROOT) : "/home/edauser/project/PDK"}]
set std_db   [expr {[info exists ::env(TSMC28_STD_DB)] ? $::env(TSMC28_STD_DB) : ""}]

if {$std_db eq ""} {
    set std_candidates [glob -nocomplain \
        "$t28_root/TSMC28/logic/tcbn28hpcplusbwp40p140_180b/AN61001_20180509/TSMCHOME/digital/Front_End/timing_power_noise/NLDM/tcbn28hpcplusbwp40p140_180a/tcbn28hpcplusbwp40p140tt0p9v25c.db" \
        "$t28_root/TSMC28/logic/tcbn28hpcplusbwp40p140_180b/AN61001_20180509/TSMCHOME/digital/Front_End/timing_power_noise/NLDM/tcbn28hpcplusbwp40p140_180a/tcbn28hpcplusbwp40p140tt0p9v1v25c.db"]
    if {[llength $std_candidates] == 0} {
        error "No TSMC28 std-cell .db found. Set T28_ROOT or TSMC28_STD_DB."
    }
    set std_db [lindex $std_candidates 0]
}

set_app_var search_path [list "." [file dirname $std_db]]
set_app_var target_library [list $std_db]
set_app_var link_library [list "*" $std_db]
set_app_var synthetic_library [list dw_foundation.sldb]

puts "Std cell .db: $std_db"
