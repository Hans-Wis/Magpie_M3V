set_fml_appmode FPV
read_file -top axil_bridge_formal -format sverilog -sva {
  ../../../design/cpu_m1/rtl/axil_bridge.v
  axil_bridge_formal.sv
}
create_clock clk -period 10
create_reset resetn -sense low
check_fv_setup
check_fv -block
report_fv -list > formal_results.txt
report_fv > formal_summary.txt
exit
