set slow_lib "/home/edauser/project/PDK/TSMC28/logic/tcbn28hpcplusbwp40p140_180b/AN61001_20180509/TSMCHOME/digital/Front_End/timing_power_noise/NLDM/tcbn28hpcplusbwp40p140_180a/tcbn28hpcplusbwp40p140ssg0p81v0c.lib"
set fast_lib "/home/edauser/project/PDK/TSMC28/logic/tcbn28hpcplusbwp40p140_180b/AN61001_20180509/TSMCHOME/digital/Front_End/timing_power_noise/NLDM/tcbn28hpcplusbwp40p140_180a/tcbn28hpcplusbwp40p140ffg0p88v125c.lib"
set out_dir "/home/edauser/project/SOC/Magpie_M1/flow/v2_pipeline/phase_p_multicorner_dc/compiled_db"

file mkdir $out_dir /home/edauser/project/SOC/Magpie_M1/flow/v2_pipeline/phase_p_multicorner_dc/logs

read_lib $slow_lib
write_lib tcbn28hpcplusbwp40p140ssg0p81v0c -format db -output [file join $out_dir tcbn28hpcplusbwp40p140ssg0p81v0c.db]

read_lib $fast_lib
write_lib tcbn28hpcplusbwp40p140ffg0p88v125c -format db -output [file join $out_dir tcbn28hpcplusbwp40p140ffg0p88v125c.db]

quit
