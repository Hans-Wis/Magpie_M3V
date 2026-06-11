set project_name cpu_m1_phase_p_cdc_rdc_xprop
set top_name cpu_m1_top
set phase_dir /home/edauser/project/SOC/Magpie_M1/flow/v2_pipeline/phase_p_cdc_rdc_xprop

cd $phase_dir
file mkdir reports

new_project $project_name -force
set_option top $top_name
set_option language_mode mixed
set_option enableSV 1
read_file -type sourcelist files.f
read_file -type sgdc cdc_rdc_xprop.sgdc
read_file -type awl magpie_m1_cdc_rdc_xprop_waivers.awl
current_methodology $env(SPYGLASS_HOME)/GuideWare/latest/block/rtl_handoff

run_goal cdc/cdc_verify_struct
write_report moresimple > reports/cdc_verify_struct.moresimple.rpt

run_goal rdc/rdc_verify_struct
write_report moresimple > reports/rdc_verify_struct.moresimple.rpt

save_project
exit -force
