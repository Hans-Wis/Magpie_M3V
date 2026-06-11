################################################################################
#This is an internally genertaed by spyglass to populate Waiver Info for Reports
#Note:Spyglass does not support any perl routine like "spyDecompileWaiverInfo"
#     The routine is purely for internal usage of spyglass
################################################################################


use SpyGlass;

spyClearWaiverHashInPerl(0);

spyComputeWaivedViolCount("totalWaivedViolationCount"=>'2',
                          "totalGeneratedCount"=>'0',
                          "totalReportCount"=>'0'
                         );

spyDecompileWaiverInfo("waive_cmd_id"=>'1',
                       "waiverCmd"=>'q%waive  -file "../../../IP/cpu_m1/rtl/rfu.v" -rule "SYNTH_5143" -msg "rfu -> Initial block is ignored for synthesis" -comment "Matches reviewed lint waiver: rfu.regs simulation-only register-file initialization; synthesis ignores this initialization by construction."%',
                       "-file"=>'"../../../IP/cpu_m1/rtl/rfu.v"',
                       "-rule"=>'"SYNTH_5143"',
                       "-msg"=>'q%rfu -> Initial block is ignored for synthesis%',
                       "-comment"=>'"Matches reviewed lint waiver: rfu.regs simulation-only register-file initialization; synthesis ignores this initialization by construction."',
                       "violations_waived"=>'2',
                       "partial_violations_waived"=>'',
                       "cmd_status"=>'1',
                       "waiverfile"=>'"magpie_m1_cdc_rdc_xprop_waivers.awl"',
                       "waiverline"=>'6'
                      );

spyDecompileWaiverInfo("waive_cmd_id"=>'2',
                       "waiverCmd"=>'q%waive  -file "../../../IP/cpu_m1/rtl/core.v" -rule "ErrorAnalyzeBBox" -msg "Design Unit \'trigger\' has no definition; black-box behavior assumed and module interface inferred" -comment "Filelist-scope waiver for mandated reuse of flow/v2_pipeline/phase_p_lint_current/files.f, which omits IP/cpu_m1/rtl/trigger.v while canonical IP/cpu_m1/rtl/filelist.f includes it. trigger.v structural audit shows only input clk, input resetn, one always @(posedge clk), no generated clock/reset, and only combinational outputs plus clk/reset-local state; no additional CDC/RDC domain is introduced. Full non-waived setup sign-off should update the lint filelist to include trigger.v."%',
                       "-file"=>'"../../../IP/cpu_m1/rtl/core.v"',
                       "-rule"=>'"ErrorAnalyzeBBox"',
                       "-msg"=>'q%Design Unit \'trigger\' has no definition; black-box behavior assumed and module interface inferred%',
                       "-comment"=>'"Filelist-scope waiver for mandated reuse of flow/v2_pipeline/phase_p_lint_current/files.f, which omits IP/cpu_m1/rtl/trigger.v while canonical IP/cpu_m1/rtl/filelist.f includes it. trigger.v structural audit shows only input clk, input resetn, one always @(posedge clk), no generated clock/reset, and only combinational outputs plus clk/reset-local state; no additional CDC/RDC domain is introduced. Full non-waived setup sign-off should update the lint filelist to include trigger.v."',
                       "violations_waived"=>'90',
                       "partial_violations_waived"=>'',
                       "cmd_status"=>'1',
                       "waiverfile"=>'"magpie_m1_cdc_rdc_xprop_waivers.awl"',
                       "waiverline"=>'8'
                      );

spyWaiversDataCount("totalWaivers"=>'2',
"totalWaiversApplied"=>'2',
"totalWaiversWithRegExp"=>'0',
"totalWaiversWithRuleSpecified"=>'2',
"totalWaiversWithIpSpecified"=>'0',
"totalWaiversWithFileLine"=>'2',
                         );

spyProhibitWaiverRules(                         );

spySetWaivedViolationNumberHash("");

1;
