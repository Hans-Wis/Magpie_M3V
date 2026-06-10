// cpu_m1 sim filelist = RTL + DV testbench. Build: verilator -f cpu_m1.f
-f ../rtl/filelist.f
// add ONE testbench per build (top-module):
// ../dv/tb/tb_spike_lockstep.v | ../dv/tb/tb_riscvdv_lockstep.v
