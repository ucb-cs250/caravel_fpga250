/* 
 * Block of latches for use of SLICEL
 * This exists to make it easier to swap in a custom config of latches
 */
module block_config_latches #(
    parameter ADDR_BITS=4, 
    parameter MEM_SIZE=2**ADDR_BITS,
    parameter PREDEC=0 // useful only for 4-LUT right now
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

generate
    if (PREDEC==1) begin
        wire [3:0] intermediate_out; // 4 muxes -> 1 predecoded mux
        wire [3:0] intermediate_use;
        genvar i;
        for (i = 0; i < MEM_SIZE/4; i=i+1) begin
            // Why won't this map as a 4-mux?
            //assign intermediate_out[i] = mem[4*i+addr[1:0]];
            sky130_fd_sc_hd__mux4_1 _TECHMAP_MUX4 (
                .X(intermediate_out[i]),
                .A0(mem[4*i]),
                .A1(mem[4*i + 1]),
                .A2(mem[4*i + 2]),
                .A3(mem[4*i + 3]),
                .S0(addr[0]),
                .S1(addr[1])
            );
            transmission_gate tg(intermediate_out[i], out, intermediate_use[i]);
            if (i==0)
                assign intermediate_use[i] = ~addr[ADDR_BITS-1] & ~addr[ADDR_BITS-2];
            else if (i==1) 
                assign intermediate_use[i] = ~addr[ADDR_BITS-1] & addr[ADDR_BITS-2];
            else if (i==2) 
                assign intermediate_use[i] = addr[ADDR_BITS-1] & ~addr[ADDR_BITS-2];
            else 
                assign intermediate_use[i] = addr[ADDR_BITS-1] & addr[ADDR_BITS-2];
        end
    end
    else begin
        assign out = mem[addr];
    end
endgenerate

// Block Style Configuration Logic
always @(clk) begin
    if (comb_set) begin
        mem = config_in;
    end
end

endmodule

