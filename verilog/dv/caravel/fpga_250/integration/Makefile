VCS = vcs -full64
FIRMWARE_PATH      = ../..
RTL_PATH           = ../../../../rtl
IP_PATH            = ../../../../ip
BEHAVIOURAL_MODELS = ../..
PDK_PATH           = $(PDK_ROOT)/sky130A
SIM_PATH           = ..
SCRIPTS            = ../../../../../scripts

GCC_PATH = /home/aa/users/tan.nqd/riscv64-unknown-elf-gcc/bin
GCC_PREFIX?=riscv64-unknown-elf

INCS = $(RTL_PATH)+$(IP_PATH)+$(BEHAVIOURAL_MODELS)+$(SIM_PATH)+$(PDK_PATH)

SRCS = integration_tb.v

# Bare minimum required VCS flag
OPTS = -sverilog

SIMV = ./integration.simv
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
	$(VCS) $(OPTS) +incdir+$(INCS) +define+FUNCTIONAL+SIM+USE_POWER_PINS $(SRCS) -o $@

sim-rtl: $(SIMV)
	$(SIMV) -q +ntb_random_seed_automatic +load_gpio_output=gpio_output.txt

clean:
	rm -rf *simv* csrc ucli.key *.elf *.bits.h *.hex *.bin *.vcd *.log
