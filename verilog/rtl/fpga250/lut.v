///////// BASIC LUT /////////
// Assumptions:
//  MEM_SIZE is a multiple of CONFIG_WIDTH 

module lut #(
    parameter INPUTS=4, 
    parameter MEM_SIZE=2**INPUTS
) (
    // IO
    input [INPUTS-1:0] addr, 
    output out,

    // Block Style Configuration
    input clk,
    input comb_set,
    input [MEM_SIZE-1:0] config_in
);

block_config_latches #(.ADDR_BITS(INPUTS)) latches0 (
    .addr(addr), 
    .out(out),
    .clk(clk),
    .comb_set(comb_set),
    .config_in(config_in)
);

endmodule

