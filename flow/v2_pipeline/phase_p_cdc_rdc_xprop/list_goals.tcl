set project_name cpu_m1_phase_p_cdc_rdc_xprop_goal_probe
set top_name cpu_m1_top
cd /home/edauser/project/SOC/Magpie_M1/flow/v2_pipeline/phase_p_cdc_rdc_xprop

new_project $project_name -force
set_option top $top_name
set_option language_mode mixed
read_file -type sourcelist files.f
current_methodology $env(SPYGLASS_HOME)/GuideWare/latest/block/rtl_handoff

puts "INFO: available goals matching CDC/RDC/X-prop keywords"
catch {puts [list_goal -all]} all_goals
puts $all_goals
exit -force
