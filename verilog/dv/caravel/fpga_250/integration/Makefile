VCS      = vcs -full64
IVERILOG = iverilog

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

SRCS = integration_tb.v

all: sim-rtl

# Bare minimum required VCS flag
VCS_OPTS = -sverilog

SIMV = ./integration.simv
VVP  = ./integration.vvp

HEX  = software.hex
software.elf: software.c bitstream.h $(FIRMWARE_PATH)/sections.lds $(FIRMWARE_PATH)/start.s
	${GCC_PATH}/${GCC_PREFIX}-gcc -march=rv32imc -mabi=ilp32 -Wl,-Bstatic,-T,$(FIRMWARE_PATH)/sections.lds,--strip-debug -ffreestanding -nostdlib -o $@ $(FIRMWARE_PATH)/start.s $<

$(HEX): software.elf
	${GCC_PATH}/${GCC_PREFIX}-objcopy -O verilog $< $@
	# to fix flash base address
	sed -i 's/@10000000/@00000000/g' $@

bitstream.h: bitstream.txt
	python3 ${SCRIPTS}/bitstream2header.py $< $@

$(SIMV): $(SRCS) $(HEX)
	$(VCS) $(VCS_OPTS) +incdir+$(INCS) +define+FUNCTIONAL+SIM+USE_POWER_PINS $(SRCS) -o $@

sim-rtl: $(SIMV)
	$(SIMV) -q +ntb_random_seed_automatic

$(VVP): $(SRCS)
	$(IVERILOG) -g2005-sv -I $(RTL_PATH) -I $(IP_PATH) -I $(BEHAVIOURAL_MODELS) -I $(SIM_PATH) -I $(PDK_PATH) -DSIM -DFUNCTIONAL -DUSE_POWER_PINS -DUNIT_DELAY="#0.1" $(SRCS) -o $@

sim-rtl-iverilog: $(VVP)
	vvp $(VVP)

clean:
	rm -rf *simv* csrc ucli.key *.elf *.bits.h *.hex *.bin *.vcd *.log *.vvp
