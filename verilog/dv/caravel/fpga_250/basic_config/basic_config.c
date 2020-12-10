#include "../../defs.h"
#include "basic_config.bits.h"
/*
	Config Test:
		- Configure FPGA
*/

#define TAIL_BITS ((BITS_PER_COLUMN >> 3) * 8 - BITS_PER_COLUMN)

void main()
{
	static volatile uint32_t *	const config_base 	= (void*)(0x30000000);
	static volatile uint8_t *	const counters		= (void*)(0x30000004);
	static volatile uint8_t *	const bitstream 	= (void*)(0x30000008);

	// Configure lower 8-IOs as user output
	// Observe counter value in the testbench
	reg_mprj_io_0 =  GPIO_MODE_USER_STD_OUTPUT;
	reg_mprj_io_1 =  GPIO_MODE_USER_STD_OUTPUT;
	reg_mprj_io_2 =  GPIO_MODE_USER_STD_OUTPUT;
	reg_mprj_io_3 =  GPIO_MODE_USER_STD_OUTPUT;
	reg_mprj_io_4 =  GPIO_MODE_USER_STD_OUTPUT;
	reg_mprj_io_5 =  GPIO_MODE_USER_STD_OUTPUT;
	reg_mprj_io_6 =  GPIO_MODE_USER_STD_OUTPUT;
	reg_mprj_io_7 =  GPIO_MODE_USER_STD_OUTPUT;

    /* Apply configuration */
    reg_mprj_xfer = 1;
    while (reg_mprj_xfer == 1);

	*config_base = 0;
	counters[0] = 255;
	counters[1] = 255;
	counters[2] = 255;
	counters[3] = 255;

	for (int i = 0; i < (BITS_PER_COLUMN >> 3); i++) {
		bitstream[0] = column0[i];
		bitstream[1] = column1[i];
		bitstream[2] = column2[i];
		bitstream[3] = 0b10101010;
	}

	counters[0] = TAIL_BITS - 1;
	counters[1] = TAIL_BITS - 1;
	counters[2] = TAIL_BITS - 1;
	
	bitstream[0] = column0[BITS_PER_COLUMN >> 3];
	bitstream[1] = column1[BITS_PER_COLUMN >> 3];
	bitstream[2] = column2[BITS_PER_COLUMN >> 3];
	bitstream[3] = 0b01010101;

	*config_base = 1;
}

