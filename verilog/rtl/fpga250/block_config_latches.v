/* 
 * Block of latches for use of SLICEL
 * This exists to make it easier to swap in a custom config of latches
 */
module block_config_latches #(
    parameter ADDR_BITS=4, 
    parameter MEM_SIZE=2**ADDR_BITS
) (
    // IO
    input [ADDR_BITS-1:0] addr, 
    output out,

    // Block Style Configuration
    input clk,
    input comb_set,
    input [MEM_SIZE-1:0] config_in
);

reg [MEM_SIZE-1:0] mem = 0;
assign out = mem[addr];

// Block Style Configuration Logic
always @(posedge clk) begin
    if (comb_set) begin
        mem <= config_in;
    end
end

endmodule

