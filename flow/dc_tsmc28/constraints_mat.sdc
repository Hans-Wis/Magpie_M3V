# mat_engine Fmax probe constraints (ADR-0051 step 0/2).
# The 256-bit t_a_rdata/t_b_rdata are modeled with near-zero input delay: this
# emulates the ADR-0051 S0 "registered TCM read" boundary, so the reported
# reg-endpoint path is the true internal MAC (mult -> tree -> accumulate) logic
# depth, not gated by an assumed upstream combinational read. CLK_PERIOD is
# deliberately tight so the worst path is fully reported; Fmax is derived as
# 1000/(CLK_PERIOD - WNS_ns) from report_qor regardless of the target.

set clk_period [expr {[info exists ::env(CLK_PERIOD)] ? $::env(CLK_PERIOD) : 2.0}]

create_clock -name clk -period $clk_period [get_ports clk]
set_clock_uncertainty 0.10 [get_clocks clk]

# data inputs arrive at the clock edge (registered-read model); control inputs
# get a small delay. reset is a global, exclude clk itself.
set data_in [get_ports {t_a_rdata* t_b_rdata*}]
set_input_delay 0.05 -clock clk $data_in
set_input_delay 0.30 -clock clk [remove_from_collection \
    [remove_from_collection [all_inputs] [get_ports clk]] $data_in]
set_output_delay 0.30 -clock clk [all_outputs]

set_max_transition 0.25 [current_design]
set_max_fanout 32 [current_design]
