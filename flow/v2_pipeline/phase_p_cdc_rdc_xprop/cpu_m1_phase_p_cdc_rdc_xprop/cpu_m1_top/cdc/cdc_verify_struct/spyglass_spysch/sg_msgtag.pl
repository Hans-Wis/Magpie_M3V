################################################################################
#This is an internally genertaed by SpyGlass for Message Tagging Support
################################################################################


use spyglass;
use SpyGlass;
use SpyGlass::Objects;
spyRebootMsgTagSupport();

spySetMsgTagCount(361,62);
spyCacheTagValuesFromBatch(["AC_CONV_SS_SCH"]);
spyCacheTagValuesFromBatch(["AC_CONV_SUB_SS_SCH"]);
spyCacheTagValuesFromBatch(["ADV_CLK_SYNC_SS_SCH"]);
spyCacheTagValuesFromBatch(["CDC_ABSTRACT_CLK_MAPPING_SS_SCH"]);
spyCacheTagValuesFromBatch(["CDC_ABSTRACT_VALIDATION_SS_SCH"]);
spyCacheTagValuesFromBatch(["CLOCK_SYNC05A_SS_SCH"]);
spyCacheTagValuesFromBatch(["CLOCK_SYNC05_SS_SCH"]);
spyCacheTagValuesFromBatch(["CLOCK_SYNC06A_SS_SCH"]);
spyCacheTagValuesFromBatch(["CLOCK_SYNC06_SS_SCH"]);
spyCacheTagValuesFromBatch(["QS_CSV_TAG"]);
spyCacheTagValuesFromBatch(["RESET_INFO_01_SS_SCH"]);
spyCacheTagValuesFromBatch(["SETUP_BBOX01_SDC_TAG"]);
spyCacheTagValuesFromBatch(["SETUP_BBOX01_SS_SCH"]);
spyCacheTagValuesFromBatch(["SETUP_LIBRARY_SS_RTL"]);
spyCacheTagValuesFromBatch(["SETUP_LIBRARY_SS_SCH"]);
spyCacheTagValuesFromBatch(["SETUP_PORT_SDC_TAG"]);
spyCacheTagValuesFromBatch(["SETUP_PORT_SS_SCH"]);
spyCacheTagValuesFromBatch(["VIRT_CLK_MAP_SS_SCH"]);
spyCacheTagValuesFromBatch(["pe_crossprobe_tag"]);
spyParseTextMessageTagFile("./cpu_m1_phase_p_cdc_rdc_xprop/cpu_m1_top/cdc/cdc_verify_struct/spyglass_spysch/sg_msgtag.txt");

if(!defined $::spyInIspy || !$::spyInIspy)
{
    spyDefineReportGroupingOrder("ALL",
(
"BUILTIN"   => [SGTAGTRUE, SGTAGFALSE]
,"TEMPLATE" => "A"
)
);
}
spyMessageTagTestBenchmark(95,"./cpu_m1_phase_p_cdc_rdc_xprop/cpu_m1_top/cdc/cdc_verify_struct/spyglass.vdb");

1;
