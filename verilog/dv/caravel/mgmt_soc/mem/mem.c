#include "../../defs.h"

// --------------------------------------------------------

/*
	Memory Test
	It uses GPIO to flag the success or failure of the test
*/
unsigned int ints[10];
unsigned short shorts[10];
unsigned char bytes[10];

void main()
{
    int i;

    /* Upper 16 user area pins are configured to be GPIO output */

    reg_mprj_io_31 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_30 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_29 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_28 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_27 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_26 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_25 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_24 = GPIO_MODE_MGMT_STD_OUTPUT;

    reg_mprj_io_23 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_22 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_21 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_20 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_19 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_18 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_17 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_16 = GPIO_MODE_MGMT_STD_OUTPUT;

    // Apply configuration
    reg_mprj_xfer = 1;
    while (reg_mprj_xfer == 1);

    // start test
    reg_mprj_datal = 0xA0400000;

    // Test Word R/W
    for (i=0; i<10; i++)
	ints[i] = i*5000 + 10000;
	
    for (i=0; i<10; i++)
	if ((i*5000+10000) != ints[i])
	    reg_mprj_datal = 0xAB400000;

    reg_mprj_datal = 0xAB410000;
	
    // Test Half Word R/W
    reg_mprj_datal = 0xA0200000;
    for (i=0; i<10; i++)
	shorts[i] = i*500 + 100;
	
    for(i=0; i<10; i++)
	if((i*500+100) != shorts[i])
	    reg_mprj_datal = 0xAB200000;

    reg_mprj_datal = 0xAB210000;

    // Test byte R/W
    reg_mprj_datal = 0xA0100000;
    for(i=0; i<10; i++)
	bytes[i] = i*5 + 10;
	
    for(i=0; i<10; i++)
	if((i*5+10) != bytes[i])
	    reg_mprj_datal = 0xAB100000;

    reg_mprj_datal = 0xAB110000;
}