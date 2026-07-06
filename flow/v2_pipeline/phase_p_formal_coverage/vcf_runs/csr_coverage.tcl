set_fml_appmode FPV
set outdir flow/v2_pipeline/phase_p_formal_coverage
set design csr
read_file -top $design -format sverilog -sva -cov all -vcs {+incdir+design/cpu_m1/rtl design/cpu_m1/rtl/csr.v design/cpu_m1/dv/formal/csr_assert_bind.sv}
create_clock clk -period 10
create_reset resetn -value low
sim_run -stable
sim_save_reset
check_fv -block
redirect -file $outdir/logs/csr_coverage_report_fv.txt {report_fv}
redirect -file $outdir/logs/csr_coverage_report_fv_verbose.txt {report_fv -verbose -no_summary}
analyze_fv_coverage -hierdepth 100
redirect -file $outdir/logs/csr_fv_coverage.txt {report_fv_coverage -hierdepth 100}
redirect -file $outdir/logs/csr_fv_coverage_covered.txt {report_fv_coverage -hierdepth 100 -list_covered}
redirect -file $outdir/logs/csr_fv_coverage_uncovered.txt {report_fv_coverage -hierdepth 100 -list_uncovered}
set fp [open $outdir/logs/csr_coverage_props.tsv w]
puts $fp "property\tstatus"
foreach_in_collection prop [get_props -usage assert] {
    puts $fp "[get_attribute $prop name]\t[get_attribute $prop status]"
}
close $fp
