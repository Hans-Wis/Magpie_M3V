################################################################################
#This is an internally genertaed by SpyGlass for Message Tagging Support
################################################################################


use spyglass;
use SpyGlass;
use SpyGlass::Objects;
spyRebootMsgTagSupport();

spySetMsgTagCount(144,51);
spyCacheTagValuesFromBatch(["AR_RESTCROSS01_SS_SCH"]);
spyCacheTagValuesFromBatch(["SETUP_BBOX01_SDC_TAG"]);
spyCacheTagValuesFromBatch(["SETUP_BBOX01_SS_SCH"]);
spyCacheTagValuesFromBatch(["SETUP_PORT_SDC_TAG"]);
spyCacheTagValuesFromBatch(["SETUP_PORT_SS_SCH"]);
spyParseTextMessageTagFile("./cpu_m1_phase_p_cdc_rdc_xprop/cpu_m1_top/rdc/rdc_verify_struct/spyglass_spysch/sg_msgtag.txt");

if(!defined $::spyInIspy || !$::spyInIspy)
{
    spyDefineReportGroupingOrder("ALL",
(
"BUILTIN"   => [SGTAGTRUE, SGTAGFALSE]
,"TEMPLATE" => "A"
)
);
}
spyMessageTagTestBenchmark(90,"./cpu_m1_phase_p_cdc_rdc_xprop/cpu_m1_top/rdc/rdc_verify_struct/spyglass.vdb");

1;
