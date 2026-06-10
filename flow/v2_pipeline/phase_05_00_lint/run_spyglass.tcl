set project_name cpu_m1_phase_05_00_lint
set top_name cpu_m1_top

new_project $project_name -force
set_option top $top_name
set_option language_mode mixed
read_file -type sourcelist files.f
current_methodology $env(SPYGLASS_HOME)/GuideWare/latest/block/rtl_handoff

run_goal lint/lint_rtl
write_report moresimple > reports/lint_rtl.moresimple.rpt

# This rtl_handoff methodology does not provide lint/lint_turbo.
# STARC/starc2005 policy rules are loaded and reported by lint/lint_rtl.

save_project
exit -force
