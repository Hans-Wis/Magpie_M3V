################################################################################
#This is an internally genertaed by spyglass to populate Waiver Info for Reports
#Note:Spyglass does not support any perl routine like "spyDecompileWaiverInfo"
#     The routine is purely for internal usage of spyglass
################################################################################


use SpyGlass;

spyClearWaiverHashInPerl(0);

spyComputeWaivedViolCount("totalWaivedViolationCount"=>'24',
                          "totalGeneratedCount"=>'0',
                          "totalReportCount"=>'0'
                         );

spyDecompileWaiverInfo("waive_cmd_id"=>'1',
                       "waiverCmd"=>'q%waive   -file_line "../../../design/cpu_m1/rtl/rfu.v" 36 -rule "SYNTH_5143" -msg "rfu -> Initial block is ignored for synthesis" -comment "rfu.regs simulation-only register-file initialization; synthesis ignores this initialization by construction."%',
                       "-file_line"=>'"../../../design/cpu_m1/rtl/rfu.v" 36',
                       "-rule"=>'"SYNTH_5143"',
                       "-msg"=>'q%rfu -> Initial block is ignored for synthesis%',
                       "-comment"=>'"rfu.regs simulation-only register-file initialization; synthesis ignores this initialization by construction."',
                       "violations_waived"=>'28',
                       "partial_violations_waived"=>'',
                       "cmd_status"=>'1',
                       "waiverfile"=>'"magpie_m1_lint_waivers.awl"',
                       "waiverline"=>'7'
                      );

spyDecompileWaiverInfo("waive_cmd_id"=>'2',
                       "waiverCmd"=>'q%waive   -file_line "../../../design/cpu_m1/rtl/div.v" 69 -rule "STARC05-2.11.3.1" -msg "Combinational and sequential parts of an FSM \'div.state\' described in same always block" -comment "div.state intentionally uses a single always block to keep divider state and next-state updates local."%',
                       "-file_line"=>'"../../../design/cpu_m1/rtl/div.v" 69',
                       "-rule"=>'q%STARC05-2.11.3.1%',
                       "-msg"=>'q%Combinational and sequential parts of an FSM \'div.state\' described in same always block%',
                       "-comment"=>'"div.state intentionally uses a single always block to keep divider state and next-state updates local."',
                       "violations_waived"=>'15',
                       "partial_violations_waived"=>'',
                       "cmd_status"=>'1',
                       "waiverfile"=>'"magpie_m1_lint_waivers.awl"',
                       "waiverline"=>'9'
                      );

spyDecompileWaiverInfo("waive_cmd_id"=>'3',
                       "waiverCmd"=>'q%waive   -file_line "../../../design/cpu_m1/rtl/cpu_m1_top.v" 114 -rule "STARC05-2.2.3.3" -msg "Flipflop \'primed\' is assigned over the same signal in an always construct for sequential circuits (at line \'103\')" -comment "primed uses explicit boot-prime sequential priority; later assignment intentionally overrides the reset/default path."%',
                       "-file_line"=>'"../../../design/cpu_m1/rtl/cpu_m1_top.v" 114',
                       "-rule"=>'q%STARC05-2.2.3.3%',
                       "-msg"=>'q%Flipflop \'primed\' is assigned over the same signal in an always construct for sequential circuits (at line \'103\')%',
                       "-comment"=>'"primed uses explicit boot-prime sequential priority; later assignment intentionally overrides the reset/default path."',
                       "violations_waived"=>'3',
                       "partial_violations_waived"=>'',
                       "cmd_status"=>'1',
                       "waiverfile"=>'"magpie_m1_lint_waivers.awl"',
                       "waiverline"=>'11'
                      );

spyDecompileWaiverInfo("waive_cmd_id"=>'4',
                       "waiverCmd"=>'q%waive  -regexp   -file_line "../../../design/cpu_m1/rtl/cpu_m1_top.v" 114 -rule "W415a" -msg "Signal primed is being assigned multiple times*" -comment "primed boot-prime priority is intentional last-write-wins sequential logic." --on_the_fly_compat_check%',
                       "-file_line"=>'m%../../../design/cpu_m1/rtl/cpu_m1_top.v% 114',
                       "-rule"=>'m%W415a%',
                       "-regexp"=>'1',
                       "-msg"=>'m%Signal primed is being assigned multiple times*%',
                       "-comment"=>'"primed boot-prime priority is intentional last-write-wins sequential logic."',
                       "violations_waived"=>'4',
                       "partial_violations_waived"=>'',
                       "cmd_status"=>'1',
                       "waiverfile"=>'"magpie_m1_lint_waivers.awl"',
                       "waiverline"=>'12'
                      );

spyDecompileWaiverInfo("waive_cmd_id"=>'5',
                       "waiverCmd"=>'q%waive   -file_line "../../../design/cpu_m1/rtl/csr.v" 190 -rule "STARC05-2.2.3.3" -msg "Flipflop \'mepc_reg\' is assigned over the same signal in an always construct for sequential circuits (at line \'177\')" -comment "mepc_reg trap update intentionally has priority over CSR write in the sequential CSR block."%',
                       "-file_line"=>'"../../../design/cpu_m1/rtl/csr.v" 190',
                       "-rule"=>'q%STARC05-2.2.3.3%',
                       "-msg"=>'q%Flipflop \'mepc_reg\' is assigned over the same signal in an always construct for sequential circuits (at line \'177\')%',
                       "-comment"=>'"mepc_reg trap update intentionally has priority over CSR write in the sequential CSR block."',
                       "violations_waived"=>'16',
                       "partial_violations_waived"=>'',
                       "cmd_status"=>'1',
                       "waiverfile"=>'"magpie_m1_lint_waivers.awl"',
                       "waiverline"=>'14'
                      );

spyDecompileWaiverInfo("waive_cmd_id"=>'6',
                       "waiverCmd"=>'q%waive   -file_line "../../../design/cpu_m1/rtl/csr.v" 191 -rule "STARC05-2.2.3.3" -msg "Flipflop \'mcause_reg\' is assigned over the same signal in an always construct for sequential circuits (at line \'178\')" -comment "mcause_reg trap update intentionally has priority over CSR write in the sequential CSR block."%',
                       "-file_line"=>'"../../../design/cpu_m1/rtl/csr.v" 191',
                       "-rule"=>'q%STARC05-2.2.3.3%',
                       "-msg"=>'q%Flipflop \'mcause_reg\' is assigned over the same signal in an always construct for sequential circuits (at line \'178\')%',
                       "-comment"=>'"mcause_reg trap update intentionally has priority over CSR write in the sequential CSR block."',
                       "violations_waived"=>'17',
                       "partial_violations_waived"=>'',
                       "cmd_status"=>'1',
                       "waiverfile"=>'"magpie_m1_lint_waivers.awl"',
                       "waiverline"=>'15'
                      );

spyDecompileWaiverInfo("waive_cmd_id"=>'7',
                       "waiverCmd"=>'q%waive   -file_line "../../../design/cpu_m1/rtl/csr.v" 192 -rule "STARC05-2.2.3.3" -msg "Flipflop \'mtval_reg\' is assigned over the same signal in an always construct for sequential circuits (at line \'179\')" -comment "mtval_reg trap update intentionally has priority over CSR write in the sequential CSR block."%',
                       "-file_line"=>'"../../../design/cpu_m1/rtl/csr.v" 192',
                       "-rule"=>'q%STARC05-2.2.3.3%',
                       "-msg"=>'q%Flipflop \'mtval_reg\' is assigned over the same signal in an always construct for sequential circuits (at line \'179\')%',
                       "-comment"=>'"mtval_reg trap update intentionally has priority over CSR write in the sequential CSR block."',
                       "violations_waived"=>'18',
                       "partial_violations_waived"=>'',
                       "cmd_status"=>'1',
                       "waiverfile"=>'"magpie_m1_lint_waivers.awl"',
                       "waiverline"=>'16'
                      );

spyDecompileWaiverInfo("waive_cmd_id"=>'8',
                       "waiverCmd"=>'q%waive   -file_line "../../../design/cpu_m1/rtl/csr.v" 193 -rule "STARC05-2.2.3.3" -msg "Flipflop \'mstatus_mpie\' is assigned over the same signal in an always construct for sequential circuits (at line \'171\')" -comment "mstatus_mpie trap/return sequencing intentionally uses ordered last-write-wins CSR priority."%',
                       "-file_line"=>'"../../../design/cpu_m1/rtl/csr.v" 193',
                       "-rule"=>'q%STARC05-2.2.3.3%',
                       "-msg"=>'q%Flipflop \'mstatus_mpie\' is assigned over the same signal in an always construct for sequential circuits (at line \'171\')%',
                       "-comment"=>'"mstatus_mpie trap/return sequencing intentionally uses ordered last-write-wins CSR priority."',
                       "violations_waived"=>'19',
                       "partial_violations_waived"=>'',
                       "cmd_status"=>'1',
                       "waiverfile"=>'"magpie_m1_lint_waivers.awl"',
                       "waiverline"=>'17'
                      );

spyDecompileWaiverInfo("waive_cmd_id"=>'9',
                       "waiverCmd"=>'q%waive   -file_line "../../../design/cpu_m1/rtl/csr.v" 194 -rule "STARC05-2.2.3.3" -msg "Flipflop \'mstatus_mie\' is assigned over the same signal in an always construct for sequential circuits (at line \'170\')" -comment "mstatus_mie trap/return sequencing intentionally uses ordered last-write-wins CSR priority."%',
                       "-file_line"=>'"../../../design/cpu_m1/rtl/csr.v" 194',
                       "-rule"=>'q%STARC05-2.2.3.3%',
                       "-msg"=>'q%Flipflop \'mstatus_mie\' is assigned over the same signal in an always construct for sequential circuits (at line \'170\')%',
                       "-comment"=>'"mstatus_mie trap/return sequencing intentionally uses ordered last-write-wins CSR priority."',
                       "violations_waived"=>'20',
                       "partial_violations_waived"=>'',
                       "cmd_status"=>'1',
                       "waiverfile"=>'"magpie_m1_lint_waivers.awl"',
                       "waiverline"=>'18'
                      );

spyDecompileWaiverInfo("waive_cmd_id"=>'10',
                       "waiverCmd"=>'q%waive   -file_line "../../../design/cpu_m1/rtl/csr.v" 196 -rule "STARC05-2.2.3.3" -msg "Flipflop \'mstatus_mie\' is assigned over the same signal in an always construct for sequential circuits (at line \'170\')" -comment "mstatus_mie mret restore intentionally overrides the default CSR sequential value."%',
                       "-file_line"=>'"../../../design/cpu_m1/rtl/csr.v" 196',
                       "-rule"=>'q%STARC05-2.2.3.3%',
                       "-msg"=>'q%Flipflop \'mstatus_mie\' is assigned over the same signal in an always construct for sequential circuits (at line \'170\')%',
                       "-comment"=>'"mstatus_mie mret restore intentionally overrides the default CSR sequential value."',
                       "violations_waived"=>'21',
                       "partial_violations_waived"=>'',
                       "cmd_status"=>'1',
                       "waiverfile"=>'"magpie_m1_lint_waivers.awl"',
                       "waiverline"=>'19'
                      );

spyDecompileWaiverInfo("waive_cmd_id"=>'11',
                       "waiverCmd"=>'q%waive   -file_line "../../../design/cpu_m1/rtl/csr.v" 197 -rule "STARC05-2.2.3.3" -msg "Flipflop \'mstatus_mpie\' is assigned over the same signal in an always construct for sequential circuits (at line \'171\')" -comment "mstatus_mpie mret restore intentionally overrides the default CSR sequential value."%',
                       "-file_line"=>'"../../../design/cpu_m1/rtl/csr.v" 197',
                       "-rule"=>'q%STARC05-2.2.3.3%',
                       "-msg"=>'q%Flipflop \'mstatus_mpie\' is assigned over the same signal in an always construct for sequential circuits (at line \'171\')%',
                       "-comment"=>'"mstatus_mpie mret restore intentionally overrides the default CSR sequential value."',
                       "violations_waived"=>'22',
                       "partial_violations_waived"=>'',
                       "cmd_status"=>'1',
                       "waiverfile"=>'"magpie_m1_lint_waivers.awl"',
                       "waiverline"=>'20'
                      );

spyDecompileWaiverInfo("waive_cmd_id"=>'12',
                       "waiverCmd"=>'q%waive  -regexp   -file_line "../../../design/cpu_m1/rtl/csr.v" 122 -rule "W415a" -msg "Signal csr_rdata is being assigned multiple times*" -comment "csr_rdata is an intentional combinational read mux with default assignment followed by CSR-specific override." --on_the_fly_compat_check%',
                       "-file_line"=>'m%../../../design/cpu_m1/rtl/csr.v% 122',
                       "-rule"=>'m%W415a%',
                       "-regexp"=>'1',
                       "-msg"=>'m%Signal csr_rdata is being assigned multiple times*%',
                       "-comment"=>'"csr_rdata is an intentional combinational read mux with default assignment followed by CSR-specific override."',
                       "violations_waived"=>'23',
                       "partial_violations_waived"=>'',
                       "cmd_status"=>'1',
                       "waiverfile"=>'"magpie_m1_lint_waivers.awl"',
                       "waiverline"=>'22'
                      );

spyDecompileWaiverInfo("waive_cmd_id"=>'13',
                       "waiverCmd"=>'q%waive  -regexp   -file_line "../../../design/cpu_m1/rtl/csr.v" 190 -rule "W415a" -msg "Signal mepc_reg is being assigned multiple times*" -comment "mepc_reg trap-over-CSR sequential priority is intentional last-write-wins behavior." --on_the_fly_compat_check%',
                       "-file_line"=>'m%../../../design/cpu_m1/rtl/csr.v% 190',
                       "-rule"=>'m%W415a%',
                       "-regexp"=>'1',
                       "-msg"=>'m%Signal mepc_reg is being assigned multiple times*%',
                       "-comment"=>'"mepc_reg trap-over-CSR sequential priority is intentional last-write-wins behavior."',
                       "violations_waived"=>'24',
                       "partial_violations_waived"=>'',
                       "cmd_status"=>'1',
                       "waiverfile"=>'"magpie_m1_lint_waivers.awl"',
                       "waiverline"=>'23'
                      );

spyDecompileWaiverInfo("waive_cmd_id"=>'14',
                       "waiverCmd"=>'q%waive  -regexp   -file_line "../../../design/cpu_m1/rtl/csr.v" 191 -rule "W415a" -msg "Signal mcause_reg is being assigned multiple times*" -comment "mcause_reg trap-over-CSR sequential priority is intentional last-write-wins behavior." --on_the_fly_compat_check%',
                       "-file_line"=>'m%../../../design/cpu_m1/rtl/csr.v% 191',
                       "-rule"=>'m%W415a%',
                       "-regexp"=>'1',
                       "-msg"=>'m%Signal mcause_reg is being assigned multiple times*%',
                       "-comment"=>'"mcause_reg trap-over-CSR sequential priority is intentional last-write-wins behavior."',
                       "violations_waived"=>'25',
                       "partial_violations_waived"=>'',
                       "cmd_status"=>'1',
                       "waiverfile"=>'"magpie_m1_lint_waivers.awl"',
                       "waiverline"=>'24'
                      );

spyDecompileWaiverInfo("waive_cmd_id"=>'15',
                       "waiverCmd"=>'q%waive  -regexp   -file_line "../../../design/cpu_m1/rtl/csr.v" 192 -rule "W415a" -msg "Signal mtval_reg is being assigned multiple times*" -comment "mtval_reg trap-over-CSR sequential priority is intentional last-write-wins behavior." --on_the_fly_compat_check%',
                       "-file_line"=>'m%../../../design/cpu_m1/rtl/csr.v% 192',
                       "-rule"=>'m%W415a%',
                       "-regexp"=>'1',
                       "-msg"=>'m%Signal mtval_reg is being assigned multiple times*%',
                       "-comment"=>'"mtval_reg trap-over-CSR sequential priority is intentional last-write-wins behavior."',
                       "violations_waived"=>'26',
                       "partial_violations_waived"=>'',
                       "cmd_status"=>'1',
                       "waiverfile"=>'"magpie_m1_lint_waivers.awl"',
                       "waiverline"=>'25'
                      );

spyDecompileWaiverInfo("waive_cmd_id"=>'16',
                       "waiverCmd"=>'q%waive  -regexp  -file "../../../design/cpu_m1/rtl/core.v" -rule "W287b" -msg "Instance output port \'ld_result\' is not connected" -comment "ID-stage dual-use LSU instance intentionally leaves ld_result unconnected because only address-side decode is used there."%',
                       "-file"=>'m%../../../design/cpu_m1/rtl/core.v%',
                       "-rule"=>'m%W287b%',
                       "-regexp"=>'1',
                       "-msg"=>'m%Instance output port \'ld_result\' is not connected%',
                       "-comment"=>'"ID-stage dual-use LSU instance intentionally leaves ld_result unconnected because only address-side decode is used there."',
                       "violations_waived"=>'6',
                       "partial_violations_waived"=>'',
                       "cmd_status"=>'1',
                       "waiverfile"=>'"magpie_m1_lint_waivers.awl"',
                       "waiverline"=>'27'
                      );

spyDecompileWaiverInfo("waive_cmd_id"=>'17',
                       "waiverCmd"=>'q%waive  -regexp  -file "../../../design/cpu_m1/rtl/core.v" -rule "W287b" -msg "Instance output port \'mem_wdata\' is not connected" -comment "WB-stage dual-use LSU instance intentionally leaves store data output unconnected because only load result behavior is used there."%',
                       "-file"=>'m%../../../design/cpu_m1/rtl/core.v%',
                       "-rule"=>'m%W287b%',
                       "-regexp"=>'1',
                       "-msg"=>'m%Instance output port \'mem_wdata\' is not connected%',
                       "-comment"=>'"WB-stage dual-use LSU instance intentionally leaves store data output unconnected because only load result behavior is used there."',
                       "violations_waived"=>'7',
                       "partial_violations_waived"=>'',
                       "cmd_status"=>'1',
                       "waiverfile"=>'"magpie_m1_lint_waivers.awl"',
                       "waiverline"=>'28'
                      );

spyDecompileWaiverInfo("waive_cmd_id"=>'18',
                       "waiverCmd"=>'q%waive  -regexp  -file "../../../design/cpu_m1/rtl/core.v" -rule "W287b" -msg "Instance output port \'mem_wstrb\' is not connected" -comment "WB-stage dual-use LSU instance intentionally leaves store strobe output unconnected because only load result behavior is used there."%',
                       "-file"=>'m%../../../design/cpu_m1/rtl/core.v%',
                       "-rule"=>'m%W287b%',
                       "-regexp"=>'1',
                       "-msg"=>'m%Instance output port \'mem_wstrb\' is not connected%',
                       "-comment"=>'"WB-stage dual-use LSU instance intentionally leaves store strobe output unconnected because only load result behavior is used there."',
                       "violations_waived"=>'8',
                       "partial_violations_waived"=>'',
                       "cmd_status"=>'1',
                       "waiverfile"=>'"magpie_m1_lint_waivers.awl"',
                       "waiverline"=>'29'
                      );

spyDecompileWaiverInfo("waive_cmd_id"=>'19',
                       "waiverCmd"=>'q%waive  -regexp  -file "../../../design/cpu_m1/rtl/cdec.v" -rule "W528" -msg "Variable \'rs1_q0_3\\[2:0\\]\' set but not read.*" -comment "rs1_q0_3 is a dead intermediate compressed-decode wire retained for decode structure readability." --on_the_fly_compat_check%',
                       "-file"=>'m%../../../design/cpu_m1/rtl/cdec.v%',
                       "-rule"=>'m%W528%',
                       "-regexp"=>'1',
                       "-msg"=>'m%Variable \'rs1_q0_3\\[2:0\\]\' set but not read.*%',
                       "-comment"=>'"rs1_q0_3 is a dead intermediate compressed-decode wire retained for decode structure readability."',
                       "violations_waived"=>'12',
                       "partial_violations_waived"=>'',
                       "cmd_status"=>'1',
                       "waiverfile"=>'"magpie_m1_lint_waivers.awl"',
                       "waiverline"=>'31'
                      );

spyDecompileWaiverInfo("waive_cmd_id"=>'20',
                       "waiverCmd"=>'q%waive  -regexp  -file "../../../design/cpu_m1/rtl/cdec.v" -rule "W528" -msg "Variable \'rd_q0_3\\[2:0\\]\' set but not read.*" -comment "rd_q0_3 is a dead intermediate compressed-decode wire retained for decode structure readability." --on_the_fly_compat_check%',
                       "-file"=>'m%../../../design/cpu_m1/rtl/cdec.v%',
                       "-rule"=>'m%W528%',
                       "-regexp"=>'1',
                       "-msg"=>'m%Variable \'rd_q0_3\\[2:0\\]\' set but not read.*%',
                       "-comment"=>'"rd_q0_3 is a dead intermediate compressed-decode wire retained for decode structure readability."',
                       "violations_waived"=>'13',
                       "partial_violations_waived"=>'',
                       "cmd_status"=>'1',
                       "waiverfile"=>'"magpie_m1_lint_waivers.awl"',
                       "waiverline"=>'32'
                      );

spyDecompileWaiverInfo("waive_cmd_id"=>'21',
                       "waiverCmd"=>'q%waive  -regexp  -file "../../../design/cpu_m1/rtl/core.v" -rule "W528" -msg "Variable \'cdec_illegal\' set but not read.*" -comment "cdec.illegal is a verification/diagnostic output checked by the unit TB + a sim-only invariant assertion (ADR-0016); reserved detection is via idu (expanded=0); not a synthesis trap signal." --on_the_fly_compat_check%',
                       "-file"=>'m%../../../design/cpu_m1/rtl/core.v%',
                       "-rule"=>'m%W528%',
                       "-regexp"=>'1',
                       "-msg"=>'m%Variable \'cdec_illegal\' set but not read.*%',
                       "-comment"=>'"cdec.illegal is a verification/diagnostic output checked by the unit TB + a sim-only invariant assertion (ADR-0016); reserved detection is via idu (expanded=0); not a synthesis trap signal."',
                       "violations_waived"=>'9',
                       "partial_violations_waived"=>'',
                       "cmd_status"=>'1',
                       "waiverfile"=>'"magpie_m1_lint_waivers.awl"',
                       "waiverline"=>'33'
                      );

spyDecompileWaiverInfo("waive_cmd_id"=>'22',
                       "waiverCmd"=>'q%waive  -regexp  -file "../../../design/cpu_m1/rtl/core.v" -rule "W528" -msg "Variable \'ex_wb_is_store_r\' set but not read.*" -comment "ex_wb_is_store_r is an unused pipeline register left from symmetric EX/WB control staging." --on_the_fly_compat_check%',
                       "-file"=>'m%../../../design/cpu_m1/rtl/core.v%',
                       "-rule"=>'m%W528%',
                       "-regexp"=>'1',
                       "-msg"=>'m%Variable \'ex_wb_is_store_r\' set but not read.*%',
                       "-comment"=>'"ex_wb_is_store_r is an unused pipeline register left from symmetric EX/WB control staging."',
                       "violations_waived"=>'10',
                       "partial_violations_waived"=>'',
                       "cmd_status"=>'1',
                       "waiverfile"=>'"magpie_m1_lint_waivers.awl"',
                       "waiverline"=>'34'
                      );

spyDecompileWaiverInfo("waive_cmd_id"=>'23',
                       "waiverCmd"=>'q%waive  -regexp   -file_line "../../../design/cpu_m1/rtl/forward.v" 60 -rule "W528" -msg "Variable \'_unused_wb_is_load\' set but not read.*" -comment "_unused_wb_is_load follows the Verilator unused-signal convention; SpyGlass does not infer that convention." --on_the_fly_compat_check%',
                       "-file_line"=>'m%../../../design/cpu_m1/rtl/forward.v% 60',
                       "-rule"=>'m%W528%',
                       "-regexp"=>'1',
                       "-msg"=>'m%Variable \'_unused_wb_is_load\' set but not read.*%',
                       "-comment"=>'"_unused_wb_is_load follows the Verilator unused-signal convention; SpyGlass does not infer that convention."',
                       "violations_waived"=>'14',
                       "partial_violations_waived"=>'',
                       "cmd_status"=>'1',
                       "waiverfile"=>'"magpie_m1_lint_waivers.awl"',
                       "waiverline"=>'35'
                      );

spyDecompileWaiverInfo("waive_cmd_id"=>'24',
                       "waiverCmd"=>'q%waive  -regexp   -file_line "../../../design/cpu_m1/rtl/hazard.v" 51 -rule "W528" -msg "Variable \'_unused_wb_signals\' set but not read.*" -comment "_unused_wb_signals follows the Verilator unused-signal convention; SpyGlass does not infer that convention." --on_the_fly_compat_check%',
                       "-file_line"=>'m%../../../design/cpu_m1/rtl/hazard.v% 51',
                       "-rule"=>'m%W528%',
                       "-regexp"=>'1',
                       "-msg"=>'m%Variable \'_unused_wb_signals\' set but not read.*%',
                       "-comment"=>'"_unused_wb_signals follows the Verilator unused-signal convention; SpyGlass does not infer that convention."',
                       "violations_waived"=>'27',
                       "partial_violations_waived"=>'',
                       "cmd_status"=>'1',
                       "waiverfile"=>'"magpie_m1_lint_waivers.awl"',
                       "waiverline"=>'36'
                      );

spyWaiversDataCount("totalWaivers"=>'24',
"totalWaiversApplied"=>'24',
"totalWaiversWithRegExp"=>'14',
"totalWaiversWithRuleSpecified"=>'24',
"totalWaiversWithIpSpecified"=>'0',
"totalWaiversWithFileLine"=>'24',
                         );

spyProhibitWaiverRules(                         );

spySetWaivedViolationNumberHash("");

1;
