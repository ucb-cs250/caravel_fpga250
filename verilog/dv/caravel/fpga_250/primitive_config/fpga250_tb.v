// This is an adaptation of [fabric_team]/testbench/fpga_test_harness.v for
// the user_project_wrapper in Caravel.

`timescale 1ns/1ns

//`include "consts.vh"
//`define DEBUG_CONFIG

module fpga250_tb();

  reg clk, rst;

  localparam FABRIC_CLOCK_PERIOD = 10; // 100 MHz

  initial clk = 0;
  always #(FABRIC_CLOCK_PERIOD/2) clk = ~clk;

  wire 

  user_project_wrapper #(
    .BITS(32)
  ) dut (
    .wb_clk_i(clk),
    .wb_rst_i(rst),

    // Wishbone signals
    .wbs_stb_i(wbs_stb_i),   // input
    .wbs_cyc_i(wbs_cyc_i),   // input
    .wbs_we_i(wbs_we_i),     // input
    // Write mask
    .wbs_sel_i(wbs_sel_i),   // input
    .wbs_dat_i(wbs_data_i),  // input
    .wbs_adr_i(wbs_addr_i),  // input
    .wbs_ack_o(wbs_ack_o),   // output
    .wbs_data_o(wbs_data_o)  // output

    .io_in,
    .io_out(),
    .io_oeb(),
    .la_data_in(),
    .la_data_out(),
    .la_oen(),
    .analog_io(),
    .user_clock2()
  );

  reg [31:0] address = 32'h3000_0000;
  reg [31:0] write_data = 0;
  reg transact = 0;
  reg we = 0;
  // FIXME: assume the fabric has 4 columns for now
  reg [3:0] select = 4'b1111;

  wire ack;
  wire [31:0] read_data;

  assign wbs_stb_i  = transact;
  assign wbs_cyc_i  = transact;
  assign wbs_we_i   = we;
  assign wbs_sel_i  = select;
  assign wbs_data_i = write_data;
  assign wbs_addr_i = address;
  assign ack        = wbs_ack_o;
  assign read_data  = wbs_data_o;

  reg fabric_reset;
  assign gpio_north[9] = fabric_reset;

  // MSB<[bitstream(0,0), bitstream(1,0), ..., bitstream(N-1,0)],
  //     [bitstream(0,1), bitstream(1,1), ..., bitstream(N-1,1)],
  //     ...
  //     [bitstream(0,N-1), bitstream(1,N-1), ..., bitstream(N-1,N-1)]>LSB

  localparam COL_BITS  = `CLB_TILE_BITSTREAM_SIZE * MY;
  localparam FPGA_BITS = COL_BITS * MX;
  reg [FPGA_BITS-1:0] bitstream[1];
  reg [8*MX*MY-1:0]   gold_sync_output[1];
  reg [8*MX*MY-1:0]   gold_comb_output[1];

  reg [1023:0] load_config = 0;
  reg [1023:0] load_sync_output = 0;
  reg [1023:0] load_comb_output = 0;

  initial begin
    $value$plusargs("load_config=%s",      load_config);
    $value$plusargs("load_sync_output=%s", load_sync_output);
    $value$plusargs("load_comb_output=%s", load_comb_output);

    #1 $readmemb(load_config, bitstream);
    #1 $readmemb(load_sync_output, gold_sync_output);
    #1 $readmemb(load_comb_output, gold_comb_output);
  end

  wire [COL_BITS-1:0] col_bitstream [MX-1:0];

  genvar k, x, y;
  generate
    for (k = 0; k < MX; k = k + 1) begin
      assign col_bitstream[MX-1-k] = bitstream[0][COL_BITS * (k + 1) - 1: COL_BITS * k];
    end
  endgenerate

  wire [8*MX*MY-1:0] fabric_sync_output;
  wire [8*MX*MY-1:0] fabric_comb_output;

  // Extract the current registers' states from the Fabric
  // They will be compared against the golden registers' states given by a test
  generate
    for (x = 0; x < MX; x = x + 1) begin
      for (y = 0; y < MY; y = y + 1) begin
        assign fabric_sync_output[x * MY * 8 + y * 8 +: 8] = dut.fpga.X[MX-1-x].Y[MY-1-y].clb.slice.sync_output;
        assign fabric_comb_output[x * MY * 8 + y * 8 +: 8] = dut.fpga.X[MX-1-x].Y[MY-1-y].clb.slice.comb_output;
      end
    end
  endgenerate

  reg debug_config = 0;
  reg failed_tests = 0;

  localparam NUM_BYTES = COL_BITS / 8;
  localparam REM_BITS  = COL_BITS - NUM_BYTES * 8;
  integer i, j;
  initial begin
    $dumpfile("fpga_test_harness.vcd");
    $dumpvars;

    rst = 1'b1;
    fabric_reset= 1'b1;
    repeat (10) @(posedge clk);

    @(negedge clk);
    rst = 1'b0;
    fabric_reset = 1'b0;

    address <= 32'h3000_0001;
    write_data <= {8'hFF, 8'hFF, 8'hFF, 8'hFF};
    we <= 1;
    transact <= 1;

    @(posedge ack);
    transact <= 0;
    we <= 0;
    @(negedge ack);

    repeat(5) @(posedge clk);

    for (i = 0; i < NUM_BYTES; i = i + 1) begin
      // sending the bits
      address <= 32'h3000_0002;
      for (j = 0; j < MX; j = j + 1) begin
        write_data[j * 8 +: 8] <= col_bitstream[j][i * 8 +: 8];
      end
      we <= 1;
      transact <= 1;

      @(posedge ack);
      transact <= 0;
      we <= 0;
      @(negedge ack);
    repeat(5) @(posedge clk);

    end

    // Send the remaining bits
    address <= 32'h3000_0001;
    write_data <= {8'hFF, 8'hFF, 8'hFF, 8'hFF};
    for (i = 0; i < MX; i = i + 1) begin
      write_data[i * 8 +: 8] <= REM_BITS;
    end

    we <= 1;
    transact <= 1;

    @(posedge ack);
    transact <= 0;
    we <= 0;
    @(negedge ack);

    repeat(5) @(posedge clk);

    // sending the bits
    address <= 32'h3000_0002;
    for (i = 0; i < MX; i = i + 1) begin
      write_data[i * 8 +: 8] <= col_bitstream[i][COL_BITS - 1 : NUM_BYTES * 8];
    end
    we <= 1;
    transact <= 1;

    @(posedge ack);
    transact <= 0;
    we <= 0;
    @(negedge ack);

    repeat(5) @(posedge clk);

    $display("Configuration done!");

    repeat (100) @(posedge clk);

    $display("Number of bits per column: %d\n", COL_BITS);
    $display("Bitstream size: %d\n", FPGA_BITS);

`ifdef DEBUG_CONFIG
    @(negedge clk);
    debug_config = 1'b1;
    @(negedge clk);
    debug_config = 1'b0;
`endif

    $display("GPIO_NORTH=%b", gpio_north);
    $display("GPIO_SOUTH=%b", gpio_south);
    $display("GPIO_EAST=%b", gpio_east);
    $display("GPIO_WEST=%b", gpio_west);

    $display("fabric_sync_output = %b", fabric_sync_output);
    $display("gold_sync_output   = %b", gold_sync_output[0]);

    $display("fabric_comb_output = %b", fabric_comb_output);
    $display("gold_comb_output   = %b", gold_comb_output[0]);

    if (fabric_sync_output === gold_sync_output[0])
      $display("[sync test] PASSED!");
    else begin
      $display("[sync test] FAILED: sync_output mismatch!");
      failed_tests = failed_tests + 1;
    end

    if (fabric_comb_output === gold_comb_output[0])
      $display("[comb test] PASSED!");
    else begin
      $display("[comb test] FAILED: comb_output mismatch!");
      failed_tests = failed_tests + 1;
    end

    #100;
    $display("Fabric test done! Num tests failed: %d", failed_tests);
    $finish;
  end

`ifdef DEBUG_CONFIG
  // Print the config states of all the tiles for debuggging
  generate
    for (x = 0; x < 2; x = x + 1) begin
      for (y = 0; y < 1; y = y + 1) begin
        always @(posedge clk) begin
          if (debug_config === 1'b1) begin

            $display("X[%d]Y[%d] S44_0 config: split=%b, LUT_1=%h, LUT_0=%h",
              x, y,
              dut.fpga.X[x].Y[y].clb.slice.sliceluroni.genblk1[0].lut.split,
              dut.fpga.X[x].Y[y].clb.slice.sliceluroni.genblk1[0].lut.second_lut.latches0.mem,
              dut.fpga.X[x].Y[y].clb.slice.sliceluroni.genblk1[0].lut.first_lut.latches0.mem,
            );

            $display("X[%d]Y[%d] S44_1 config: split=%b, LUT_1=%h, LUT_0=%h",
              x, y,
              dut.fpga.X[x].Y[y].clb.slice.sliceluroni.genblk1[1].lut.split,
              dut.fpga.X[x].Y[y].clb.slice.sliceluroni.genblk1[1].lut.second_lut.latches0.mem,
              dut.fpga.X[x].Y[y].clb.slice.sliceluroni.genblk1[1].lut.first_lut.latches0.mem,
            );

            $display("X[%d]Y[%d] S44_2 config: split=%b, LUT_1=%h, LUT_0=%h",
              x, y,
              dut.fpga.X[x].Y[y].clb.slice.sliceluroni.genblk1[2].lut.split,
              dut.fpga.X[x].Y[y].clb.slice.sliceluroni.genblk1[2].lut.second_lut.latches0.mem,
              dut.fpga.X[x].Y[y].clb.slice.sliceluroni.genblk1[2].lut.first_lut.latches0.mem,
            );

            $display("X[%d]Y[%d] S44_3 config: split=%b, LUT_1=%h, LUT_0=%h",
              x, y,
              dut.fpga.X[x].Y[y].clb.slice.sliceluroni.genblk1[3].lut.split,
              dut.fpga.X[x].Y[y].clb.slice.sliceluroni.genblk1[3].lut.second_lut.latches0.mem,
              dut.fpga.X[x].Y[y].clb.slice.sliceluroni.genblk1[3].lut.first_lut.latches0.mem,
            );

            $display("X[%d]Y[%d] clb_inter_lut_mux_config = %b",
              x, y,
              dut.fpga.X[x].Y[y].clb.slice.sliceluroni.muxes.config_state);
            $display("X[%d]Y[%d] clb_config_use_cc = %b",
              x, y,
              dut.fpga.X[x].Y[y].clb.slice.sliceluroni.use_cc);
            $display("X[%d]Y[%d] clb_regs_config_in = %b",
              x, y,
              dut.fpga.X[x].Y[y].clb.slice.sliceluroni.sync_out);

            $display("X[%d]Y[%d] cb_east_config_bits = %b",
              x, y,
              dut.fpga.X[x].Y[y].clb.cb_east.inst.connectaroni.c);

            $display("X[%d]Y[%d] cb_north_config_bits = %b",
              x, y,
              dut.fpga.X[x].Y[y].clb.cb_north.inst.connectaroni.c);

            $display("X[%d]Y[%d] sb_config_bits = %b",
              x, y,
              dut.fpga.X[x].Y[y].clb.sb.switcharoni.c);
          end
        end
      end
    end
  endgenerate
`endif

endmodule
