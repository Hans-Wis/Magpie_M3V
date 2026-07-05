# Magpie_M3V DC TSMC28 (28HPC+) flow — mat_engine Fmax + critical-path locator.
# ADR-0051. std-cell only (no SRAM macro inside mat_engine). VCS/DC = per §5
# licensed-EDA; this runs in-place with the /soft/synopsys distro.
DC_SHELL ?= /soft/synopsys/syn/X-2025.06-SP2/bin/dc_shell
export T28_ROOT ?= /home/edauser/project/PDK
CLK_PERIOD ?= 2.0

.PHONY: mat clean
mat:
	CLK_PERIOD=$(CLK_PERIOD) $(DC_SHELL) -f synth_mat.tcl 2>&1 | tee mat.dc.log
	@grep -q 'synthesis done' mat.dc.log && echo "PASS: mat_engine DC done"

clean:
	rm -rf work alib-* command.log default.svf *.log filenames.log synth_mat_1p2.tcl
