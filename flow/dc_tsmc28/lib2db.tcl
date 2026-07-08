# Compile the TCM SRAM NLDM .lib files into Synopsys .db files for DC linking.
# Run standalone:  dc_shell -f flow/dc_tsmc28/lib2db.tcl
# synth_npu_top.tcl sources this when the .db files are missing.
#
# NOTE (gotcha, see ~/EDA/13/14): write_lib needs (1) `enable_write_lib_mode` first,
# and (2) the LIBRARY name from the .lib `library(<name>) {` — NOT the cell name.

enable_write_lib_mode

set here [file normalize [file dirname [info script]]]
set sram_root "$here/sram_macros"
set sram_db_dir "$here/sram_db"
file mkdir $sram_db_dir

# {libname  lib_path  db_path}   — libname = the `library()` name inside the .lib
set sram_lib2db_jobs [list \
    [list tsdn28hpcpa1024x32m4fwbaso_tt0p9v25c \
        "$sram_root/tsdn28hpcpa1024x32m4fwbaso_130a/NLDM/tsdn28hpcpa1024x32m4fwbaso_130a_tt0p9v25c.lib" \
        "$sram_db_dir/TSDN28HPCPA1024X32M4FWBASO_tt0p9v25c.db"] \
    [list tsdn28hpcpa2048x32m8fwbaso_tt0p9v25c \
        "$sram_root/tsdn28hpcpa2048x32m8fwbaso_130a/NLDM/tsdn28hpcpa2048x32m8fwbaso_130a_tt0p9v25c.lib" \
        "$sram_db_dir/TSDN28HPCPA2048X32M8FWBASO_tt0p9v25c.db"] \
]

foreach job $sram_lib2db_jobs {
    lassign $job libname lib db
    if {![file exists $lib]} { error "Missing SRAM .lib: $lib (run gen_tcm_sram.sh first)" }
    if {![file exists $db] || [file mtime $db] < [file mtime $lib]} {
        puts "Compiling SRAM library $lib -> $db"
        read_lib $lib
        write_lib $libname -format db -output $db
    } else {
        puts "SRAM .db up to date: $db"
    }
}
