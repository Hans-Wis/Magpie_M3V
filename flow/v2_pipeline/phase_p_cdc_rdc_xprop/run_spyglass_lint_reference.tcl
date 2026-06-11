set project_name cpu_m1_phase_p_lint_current
set top_name cpu_m1_top

new_project $project_name -force
set_option top $top_name
set_option language_mode mixed
read_file -type sourcelist files.f
read_file -type awl magpie_m1_lint_waivers.awl
current_methodology $env(SPYGLASS_HOME)/GuideWare/latest/block/rtl_handoff

run_goal lint/lint_rtl
write_report moresimple > reports/lint_rtl.moresimple.rpt

# The rtl_handoff methodology includes STARC/starc2005 policies under lint/lint_rtl.
save_project
exit -force
