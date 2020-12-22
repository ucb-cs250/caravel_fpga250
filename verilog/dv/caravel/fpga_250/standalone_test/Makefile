VCS = vcs -full64
IVERILOG  = iverilog

FIRMWARE_PATH      = ../..
RTL_PATH           = ../../../../rtl
IP_PATH            = ../../../../ip
BEHAVIOURAL_MODELS = ../..
SIM_PATH           = ..
SCRIPTS            = ../../../../../scripts

GCC_PATH?=/ef/apps/bin
GCC_PREFIX?=riscv32-unknown-elf
PDK_PATH?=/ef/tech/SW/sky130A

INCS = $(RTL_PATH)+$(IP_PATH)+$(BEHAVIOURAL_MODELS)+$(SIM_PATH)+$(PDK_PATH)

SRCS = user_project_wrapper_tb.v

all: sim-rtl

# Bare minimum required VCS flag
VCS_OPTS = -sverilog

SIMV = ./standalone_test.simv
VVP  = ./standalone_test.vvp

$(SIMV): $(SRCS)
	$(VCS) $(VCS_OPTS) +incdir+$(INCS) +define+SIM+FUNCTIONAL+USE_POWER_PINS+UNIT_DELAY="#0.1" $(SRCS) -o $@

sim-rtl: $(SIMV)
	$(SIMV) -q +ntb_random_seed_automatic +load_config=bitstream.txt +load_sync_output=sync_output.txt +load_comb_output=comb_output.txt +load_gpio_output=gpio_output.txt

$(VVP): $(SRCS)
	$(IVERILOG) -g2005-sv -I $(RTL_PATH) -I $(IP_PATH) -I $(BEHAVIOURAL_MODELS) -I $(SIM_PATH) -I $(PDK_PATH) -DSIM -DFUNCTIONAL -DUSE_POWER_PINS -DUNIT_DELAY="#0.1" $(SRCS) -o $@

sim-rtl-iverilog: $(VVP)
	vvp $(VVP) +load_config=bitstream.txt +load_sync_output=sync_output.txt +load_comb_output=comb_output.txt +load_gpio_output=gpio_output.txt

clean:
	rm -rf *simv* csrc ucli.key *.elf *.bin *.vcd *.log *.vvp
