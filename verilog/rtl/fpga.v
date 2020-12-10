(* blackbox *)
module fpga #(
  parameter MX = 3,
  parameter MY = 4,
  // There are 38 IO pins in Caravel, so we distribute them around the chip.
  parameter IO_NORTH = 10,
  parameter IO_SOUTH = 8,
  parameter IO_EAST = 10,
  parameter IO_WEST = 10,

  // SRAM

  // MAC
  parameter MAC_CONF_WIDTH = 4,
  parameter MAC_MIN_WIDTH = 8,
  parameter MAC_MULT_WIDTH = 2*MAC_MIN_WIDTH,
  parameter MAC_ACC_WIDTH = 2*MAC_MULT_WIDTH,
  parameter MAC_INT_WIDTH = 5*MAC_MIN_WIDTH,
  parameter DCB_NS_W = 192,
  parameter IX_IN_OUT_W = DCB_NS_W+2,
  parameter DCB_DATAIN = 8,
  parameter DCB_DATAOUT = 8,

  // CLBs
  parameter S_XX_BASE = 4,
  parameter NUM_LUTS = 4,
  
  parameter WS = 4,
  parameter WD = 8,
  parameter WG = 0,
  parameter CLBIN = 10,
  parameter CLBIN_EACH_SIDE = 10,
  parameter CLBOUT = 5,
  parameter CLBOUT_EACH_SIDE = 5,
  parameter CLBOS = 4,
  parameter CLBOD = 4,
  parameter CLBX = 1
)(
  inout [IO_NORTH-1:0] gpio_north,
  inout [IO_SOUTH-1:0] gpio_south,
  inout [IO_WEST-1:0] gpio_west,
  inout [IO_EAST-1:0] gpio_east,

  // Global signals
  input wb_clk_i,
  input wb_rst_i,

  // Wishbone signals
  input wbs_stb_i,
  input wbs_cyc_i,
  input wbs_we_i,
  // Write mask
  input [3:0] wbs_sel_i,
  input [31:0] wbs_data_i,
  input [31:0] wbs_addr_i,
  output wbs_ack_o,
  output [31:0] wbs_data_o,
);
endmodule
