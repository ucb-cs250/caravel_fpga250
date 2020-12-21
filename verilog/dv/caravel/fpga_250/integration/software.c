#include "../../defs.h"
#include "bitstream.h"
/*
	Config Test:
		- Configure FPGA
*/

#define TAIL_BITS ((BITS_PER_COLUMN >> 3) * 8 - BITS_PER_COLUMN)

void main()
{
	static volatile uint32_t *	const config_base_00 	= (void*)(0x30000000);
	static volatile uint32_t *	const counters_00		  = (void*)(0x30000004);
	static volatile uint32_t *	const bitstream_00	 	= (void*)(0x30000008);
	static volatile uint32_t *	const config_base_10 	= (void*)(0x30000010);
	static volatile uint32_t *	const counters_10		  = (void*)(0x30000014);
	static volatile uint32_t *	const bitstream_10	 	= (void*)(0x30000018);

  // follow the FPGA GPIO pin assigments here:  verilog/rtl/user_project_wrapper.v
  reg_mprj_io_15 = GPIO_MODE_USER_STD_INPUT_NOPULL; // gpio_north[0]
  reg_mprj_io_16 = GPIO_MODE_USER_STD_INPUT_NOPULL; // gpio_north[1]
  reg_mprj_io_17 = GPIO_MODE_USER_STD_INPUT_NOPULL; // gpio_north[2]
  reg_mprj_io_18 = GPIO_MODE_USER_STD_INPUT_NOPULL; // gpio_north[3]
  reg_mprj_io_19 = GPIO_MODE_USER_STD_INPUT_NOPULL; // gpio_north[4]
  reg_mprj_io_20 = GPIO_MODE_USER_STD_INPUT_NOPULL; // gpio_north[5]
  reg_mprj_io_21 = GPIO_MODE_USER_STD_INPUT_NOPULL; // gpio_north[6]
  reg_mprj_io_22 = GPIO_MODE_USER_STD_INPUT_NOPULL; // gpio_north[7]
  reg_mprj_io_23 = GPIO_MODE_USER_STD_INPUT_NOPULL; // gpio_north[8]
  reg_mprj_io_10 = GPIO_MODE_USER_STD_INPUT_NOPULL; // gpio_north[9] --> fabric reset

  reg_mprj_io_0 = GPIO_MODE_USER_STD_INPUT_NOPULL; // gpio_east[0]
  reg_mprj_io_1 = GPIO_MODE_USER_STD_INPUT_NOPULL; // gpio_east[1]
  reg_mprj_io_2 = GPIO_MODE_USER_STD_INPUT_NOPULL; // gpio_east[2]
  reg_mprj_io_3 = GPIO_MODE_USER_STD_INPUT_NOPULL; // gpio_east[3]
  reg_mprj_io_4 = GPIO_MODE_USER_STD_INPUT_NOPULL; // gpio_east[4]
  reg_mprj_io_5 = GPIO_MODE_USER_STD_INPUT_NOPULL; // gpio_east[5]
  reg_mprj_io_6 = GPIO_MODE_USER_STD_INPUT_NOPULL; // gpio_east[6]
  reg_mprj_io_7 = GPIO_MODE_USER_STD_INPUT_NOPULL; // gpio_east[7]
  reg_mprj_io_8 = GPIO_MODE_USER_STD_INPUT_NOPULL; // gpio_east[8]
  reg_mprj_io_9 = GPIO_MODE_USER_STD_INPUT_NOPULL; // gpio_east[9]

  reg_mprj_io_24 = GPIO_MODE_USER_STD_OUTPUT; // gpio_south[0]
  reg_mprj_io_25 = GPIO_MODE_USER_STD_OUTPUT; // gpio_south[1]
  reg_mprj_io_26 = GPIO_MODE_USER_STD_OUTPUT; // gpio_south[2]
  reg_mprj_io_27 = GPIO_MODE_USER_STD_OUTPUT; // gpio_south[3]
  reg_mprj_io_11 = GPIO_MODE_USER_STD_OUTPUT; // gpio_south[4]
  reg_mprj_io_12 = GPIO_MODE_USER_STD_OUTPUT; // gpio_south[5]
  reg_mprj_io_13 = GPIO_MODE_USER_STD_OUTPUT; // gpio_south[6]
  reg_mprj_io_14 = GPIO_MODE_USER_STD_OUTPUT; // gpio_south[7]

  reg_mprj_io_28 = GPIO_MODE_USER_STD_OUTPUT; // gpio_west[0]
  reg_mprj_io_29 = GPIO_MODE_USER_STD_OUTPUT; // gpio_west[1]
  reg_mprj_io_30 = GPIO_MODE_USER_STD_OUTPUT; // gpio_west[2]
  reg_mprj_io_31 = GPIO_MODE_USER_STD_OUTPUT; // gpio_west[3]
  reg_mprj_io_32 = GPIO_MODE_USER_STD_OUTPUT; // gpio_west[4]
  reg_mprj_io_33 = GPIO_MODE_USER_STD_OUTPUT; // gpio_west[5]
  reg_mprj_io_34 = GPIO_MODE_USER_STD_OUTPUT; // gpio_west[6]
  reg_mprj_io_35 = GPIO_MODE_USER_STD_OUTPUT; // gpio_west[7]
  reg_mprj_io_36 = GPIO_MODE_USER_STD_OUTPUT; // gpio_west[8]
  reg_mprj_io_37 = GPIO_MODE_USER_STD_OUTPUT; // gpio_west[9]

  /* Apply configuration */
  reg_mprj_xfer = 1;

	*config_base_00 = 0;
	*counters_00    = 0xFFFFFFFF;
	*config_base_10 = 0;
	*counters_10    = 0xFFFFFFFF;

	for (int i = 0; i < (BITS_PER_COLUMN >> 3); i++) {
		*bitstream_00 = (column3[i] << 24) | (column2[i] << 16) | (column1[i] << 8) | column0[i];
		*bitstream_10 = (0 << 24)          | (column6[i] << 16) | (column5[i] << 8) | column4[i];
	}

  // We know that the number of bits per column is divisible by 8
  // (since we have 8 row)
  // so just need to set the counter to 0 to activate the set config signal
	*counters_00 = 0;
	*counters_10 = 0;

  bitstream_00[0] = 0;
  bitstream_10[0] = 0;
}

