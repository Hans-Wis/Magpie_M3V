#!/bin/csh -f
setenv VCS_HOME /soft/synopsys/vcs/X-2025.06-SP1/vcfca/vcs-mx
setenv VC_STATIC_HOME /soft/synopsys/vcs/X-2025.06-SP1/vcfca
setenv SYNOPSYS_SIM_SETUP /home/edauser/project/SOC/Magpie_M1/flow/v2_pipeline/phase_p_formal/vcf_runs/forward_session_rtdb/.internal/design/synopsys_sim.setup

$VCS_HOME/bin/vcs /home/edauser/project/SOC/Magpie_M1/flow/v2_pipeline/phase_p_formal/vcf_runs/forward_session_rtdb/.internal/design/undef_vcs.v -file /home/edauser/project/SOC/Magpie_M1/flow/v2_pipeline/phase_p_formal/vcf_runs/forward_session_rtdb/.internal/design/vcsCmd -Xvcstatic_extns=0x100  +warn=noSM_CCE  -error=IRRIPS  -kdb=common_elab  -Xufe=parallel:incrdump  -kdb=incopt  +warn=noKDB-ELAB-E  +warn=noELW_UNBOUND  -Xverdi_elab_opts=-saveLevel  -verdi_opts "-logdir /home/edauser/project/SOC/Magpie_M1/flow/v2_pipeline/phase_p_formal/vcf_runs/forward_session_rtdb/verdi/elabcomLog " -Xvd_opts=-silent,-ssy,-ssv,-ssz,+disable_message+C00373, -full64
