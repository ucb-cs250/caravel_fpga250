VCS = vcs -full64

FIRMWARE_PATH      = ../..
RTL_PATH           = ../../../../rtl
IP_PATH            = ../../../../ip
BEHAVIOURAL_MODELS = ../..
PDK_PATH           = $(PDK_ROOT)/sky130A
SCRIPTS            = ../../../../../scripts

GCC_PATH = /tools/B/tan.nqd/riscv64-unknown-elf-gcc/bin
GCC_PREFIX?=riscv64-unknown-elf

INCS = $(RTL_PATH)+$(IP_PATH)+$(BEHAVIOURAL_MODELS)+$(PDK_PATH)+./

SRCS = user_project_wrapper_tb.v

# Bare minimum required VCS flag
OPTS = -sverilog

SIMV = ./standalone_test.simv

$(SIMV): $(SRCS) $(HEX)
	$(VCS) $(OPTS) +incdir+$(INCS) +define+SIM+FUNCTIONAL+USE_POWER_PINS+UNIT_DELAY="#0.1" $(SRCS) -o $@

sim-rtl: $(SIMV)
	$(SIMV) -q +ntb_random_seed_automatic +load_config=bitstream.txt +load_sync_output=sync_output.txt +load_comb_output=comb_output.txt +load_gpio_output=gpio_output.txt

clean:
	rm -rf *simv* csrc ucli.key *.elf *.bin *.vcd *.log
