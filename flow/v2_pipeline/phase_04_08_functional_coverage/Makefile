TOOLCHAIN_DIR    = /home/edauser/miniforge3/pkgs/riscv-tools-1.0.6-0_h1234567_g56c29e0/riscv-tools/bin
TOOLCHAIN_PREFIX = $(TOOLCHAIN_DIR)/riscv64-unknown-elf-
TOOLCHAIN_LIBS   = /home/edauser/miniforge3/pkgs/mpfr-4.2.2-he0a73b1_0/lib:/home/edauser/miniforge3/pkgs/gmp-6.3.0-hac33072_2/lib:/home/edauser/miniforge3/pkgs/mpc-1.4.0-he0a73b1_0/lib
TOOLCHAIN_ENV    = LD_LIBRARY_PATH=$(TOOLCHAIN_LIBS)
VCS ?= /soft/synopsys/vcs/X-2025.06-SP1/bin/vcs
URG ?= /soft/synopsys/vcs/X-2025.06-SP1/bin/urg
SEED ?= 20260607
COUNT ?= 48
TESTS = random_arith branch_bp_ras csr_ops irq_mret misalign m_ext ecall illegal load_use muldiv_busy fetch_stall riscv_isacov_gaps jal_imm_zero jal_imm_min
GCC_MARCH = rv32imc_zicsr_zifencei
GCC_MABI  = ilp32
RTL_DIR  = ../../../design/cpu_m1/rtl
PHASE35  = ../phase_03_05_random_lockstep
WRAP_FW_SRC = stim_load_use.S
WRAP_ELF = wrapper_memstall.elf
WRAP_HEX = wrapper_memstall.hex
WRAP_IMODE = 3
WRAP_DMODE = 1
WRAP_MAX_CYCLES = 220000
RTL_SRCS = $(RTL_DIR)/rfu.v $(RTL_DIR)/alu.v $(RTL_DIR)/idu.v \
           $(RTL_DIR)/ifu.v $(RTL_DIR)/lsu.v $(RTL_DIR)/csr.v \
           $(RTL_DIR)/mul.v $(RTL_DIR)/div.v $(RTL_DIR)/forward.v \
           $(RTL_DIR)/hazard.v $(RTL_DIR)/bp.v $(RTL_DIR)/ras.v \
           $(RTL_DIR)/cdec.v $(RTL_DIR)/core.v
RTL_WRAPPER_SRCS = $(RTL_SRCS) $(RTL_DIR)/cpu_m1_top.v
TB_RTL = tb_random_func_cov.sv cpu_m1_func_cov_bind.sv
TB_WRAPPER = tb_wrapper_func_cov.sv cpu_m1_func_cov_bind.sv
CM = line+tgl+cond+fsm+branch+assert
VCS_FLAGS = -full64 -sverilog -timescale=1ns/1ns -debug_access+all \
            -cm $(CM) -cm_dir coverage/compile.vdb \
            +vcs+lic+wait +lint=TFIPC-L -l vcs_compile.log +incdir+$(RTL_DIR)
SIMV = simv
SIMV_WRAPPER = simv_wrapper

all: functional_coverage_report.md

generated/random_arith.S: $(PHASE35)/gen_random_program.py
	mkdir -p generated
	python3 $(PHASE35)/gen_random_program.py --seed $(SEED) --count $(COUNT) --out $@

firmware.S: generated/random_arith.S
	cp $< $@

firmware.elf: firmware.S $(PHASE35)/firmware.lds
	$(TOOLCHAIN_ENV) $(TOOLCHAIN_PREFIX)gcc -Os -march=$(GCC_MARCH) -mabi=$(GCC_MABI) \
	    -nostartfiles -nostdlib -ffreestanding \
	    -Wl,-Bstatic,-T,$(PHASE35)/firmware.lds,--strip-debug -o $@ firmware.S

firmware_spike.elf: firmware.S $(PHASE35)/firmware_spike.lds
	$(TOOLCHAIN_ENV) $(TOOLCHAIN_PREFIX)gcc -Os -march=$(GCC_MARCH) -mabi=$(GCC_MABI) \
	    -nostartfiles -nostdlib -ffreestanding \
	    -Wl,-Bstatic,-T,$(PHASE35)/firmware_spike.lds,--strip-debug -o $@ firmware.S

firmware.hex: firmware.elf
	$(TOOLCHAIN_ENV) $(TOOLCHAIN_PREFIX)objcopy -O verilog --verilog-data-width=4 $< $@

firmware.disasm: firmware.elf
	$(TOOLCHAIN_ENV) $(TOOLCHAIN_PREFIX)objdump -d $< > $@

$(SIMV): $(RTL_SRCS) $(TB_RTL)
	mkdir -p coverage
	$(VCS) $(VCS_FLAGS) $(RTL_SRCS) $(TB_RTL) -top tb_random_func_cov -o $(SIMV)

$(SIMV_WRAPPER): $(RTL_WRAPPER_SRCS) $(TB_WRAPPER)
	mkdir -p coverage
	$(VCS) $(VCS_FLAGS) $(RTL_WRAPPER_SRCS) $(TB_WRAPPER) -top tb_wrapper_func_cov -o $(SIMV_WRAPPER)

$(WRAP_HEX): $(WRAP_FW_SRC) $(PHASE35)/firmware.lds
	$(TOOLCHAIN_ENV) $(TOOLCHAIN_PREFIX)gcc -Os -march=$(GCC_MARCH) -mabi=$(GCC_MABI) \
	    -nostartfiles -nostdlib -ffreestanding \
	    -Wl,-Bstatic,-T,$(PHASE35)/firmware.lds,--strip-debug -o $(WRAP_ELF) $<
	$(TOOLCHAIN_ENV) $(TOOLCHAIN_PREFIX)objcopy -O verilog --verilog-data-width=4 $(WRAP_ELF) $@

run_tests.stamp: $(SIMV) $(SIMV_WRAPPER) $(WRAP_HEX) generated/random_arith.S stim_branch_bp_ras.S stim_csr_ops.S stim_irq_mret.S stim_misalign.S stim_m_ext.S stim_ecall.S stim_illegal.S stim_load_use.S stim_muldiv_busy.S stim_fetch_stall.S stim_jal_imm_zero.S stim_jal_imm_min.S
	rm -rf coverage/vdb coverage/events logs
	mkdir -p coverage/vdb coverage/events logs
	set -e; for test in $(TESTS); do \
	    case $$test in \
	        random_arith) src=generated/random_arith.S; plusargs= ;; \
	        branch_bp_ras) src=stim_branch_bp_ras.S; plusargs= ;; \
	        csr_ops) src=stim_csr_ops.S; plusargs= ;; \
	        irq_mret) src=stim_irq_mret.S; plusargs="+irq_at_0x80 +stop_after_mret" ;; \
	        misalign) src=stim_misalign.S; plusargs= ;; \
	        m_ext) src=stim_m_ext.S; plusargs= ;; \
	        load_use) src=stim_load_use.S; plusargs= ;; \
	        muldiv_busy) src=stim_muldiv_busy.S; plusargs= ;; \
	        fetch_stall) src=stim_fetch_stall.S; plusargs= ;; \
	        riscv_isacov_gaps) src=stim_riscvisacov_gaps.S; plusargs= ;; \
	        jal_imm_zero) src=stim_jal_imm_zero.S; plusargs="+stop_after_commits=6" ;; \
	        jal_imm_min) src=stim_jal_imm_min.S; plusargs="+stop_after_commits=7" ;; \
	        ecall) src=stim_ecall.S; plusargs= ;; \
	        illegal) src=stim_illegal.S; plusargs= ;; \
	    esac; \
	    cp $$src firmware.S; \
	    $(TOOLCHAIN_ENV) $(TOOLCHAIN_PREFIX)gcc -Os -march=$(GCC_MARCH) -mabi=$(GCC_MABI) \
	        -nostartfiles -nostdlib -ffreestanding \
	        -Wl,-Bstatic,-T,$(PHASE35)/firmware.lds,--strip-debug -o firmware.elf firmware.S; \
	    $(TOOLCHAIN_ENV) $(TOOLCHAIN_PREFIX)objcopy -O verilog --verilog-data-width=4 firmware.elf firmware.hex; \
	    $(TOOLCHAIN_ENV) $(TOOLCHAIN_PREFIX)objdump -d firmware.elf > logs/$$test.disasm; \
	    rm -f functional_events.csv dut_commit.trace; \
	    ./$(SIMV) -cm $(CM) -cm_dir coverage/vdb/$$test.vdb $$plusargs -l logs/$$test.sim.log; \
	    grep -q '^PASS' logs/$$test.sim.log; \
	    test -s functional_events.csv; \
	    cp functional_events.csv coverage/events/$$test.functional_events.csv; \
	    test -d coverage/vdb/$$test.vdb; \
	done
	rm -f functional_events.csv
	./$(SIMV_WRAPPER) -cm $(CM) -cm_dir coverage/vdb/wrapper_memstall.vdb +imode=$(WRAP_IMODE) +dmode=$(WRAP_DMODE) +max_cycles=$(WRAP_MAX_CYCLES) -l logs/wrapper_memstall.sim.log
	test -s functional_events.csv
	cp functional_events.csv coverage/events/wrapper_memstall.functional_events.csv
	test -d coverage/vdb/wrapper_memstall.vdb
	awk 'FNR == 1 && NR != 1 { next } { print }' coverage/events/*.functional_events.csv > functional_events.csv
	touch run_tests.stamp

functional_events.csv: run_tests.stamp
	test -s functional_events.csv

urgReport/dashboard.html: run_tests.stamp
	rm -rf urgReport
	$(URG) -full64 -lca -flex_merge code_union -dir coverage/compile.vdb coverage/vdb/*.vdb -report urgReport > urg.log 2>&1
	test -s urgReport/dashboard.html

provenance.log: run_tests.stamp urgReport/dashboard.html
	{ \
	    echo "host=$$(hostname)"; \
	    echo "date_utc=$$(date -u +%Y-%m-%dT%H:%M:%SZ)"; \
	    printf "vcs_version="; $(VCS) -ID 2>&1 | head -n 1; \
	    printf "urg_version="; $(URG) -ID 2>&1 | head -n 1; \
	    echo "key_commands=make clean all; ./simv -cm $(CM) -cm_dir coverage/vdb/<test>.vdb [+irq_at_0x80] -l logs/<test>.sim.log"; \
	    echo "merge_cmd=$(URG) -full64 -lca -flex_merge code_union -dir coverage/compile.vdb coverage/vdb/*.vdb -report urgReport"; \
	    echo "tests=$(TESTS)"; \
	} > provenance.log

functional_coverage_report.md functional_coverage_summary.csv uncovered_bins.csv: functional_events.csv urgReport/dashboard.html provenance.log analyze_functional_coverage.py
	python3 analyze_functional_coverage.py

clean:
	rm -rf csrc simv simv_wrapper simv.daidir DVEfiles coverage urgReport generated logs run_tests.stamp *.log *.vpd *.key \
	    firmware.S firmware.elf firmware_spike.elf firmware.hex firmware.disasm \
	    wrapper_memstall.elf wrapper_memstall.hex \
	    wave.vcd functional_events.csv dut_commit.trace functional_coverage_report.md \
	    functional_coverage_summary.csv uncovered_bins.csv

.PHONY: all clean
