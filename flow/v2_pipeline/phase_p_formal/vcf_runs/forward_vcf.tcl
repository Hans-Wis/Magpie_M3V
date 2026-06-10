set_fml_appmode FPV
set design forward
read_file -top $design -format sverilog -sva -vcs {+incdir+IP/cpu_m1/rtl IP/cpu_m1/rtl/forward.v IP/cpu_m1/dv/formal/forward_assert_bind.sv}
check_fv -block
redirect -file flow/v2_pipeline/phase_p_formal/logs/forward_vcf_report_fv.txt {report_fv}
redirect -file flow/v2_pipeline/phase_p_formal/logs/forward_vcf_report_fv_verbose.txt {report_fv -verbose -no_summary}
redirect -file flow/v2_pipeline/phase_p_formal/logs/forward_vcf_report_fv_list.txt {report_fv -list}
set fp [open flow/v2_pipeline/phase_p_formal/logs/forward_vcf_props.tsv w]
puts $fp "property\tstatus"
foreach_in_collection prop [get_props -usage assert] {
    puts $fp "[get_attribute $prop name]\t[get_attribute $prop status]"
}
close $fp
