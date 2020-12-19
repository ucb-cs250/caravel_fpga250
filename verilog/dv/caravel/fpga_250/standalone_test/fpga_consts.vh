
// CLB Tile: {CLB, CB, CB, SB, CFG}
//
// Example: 2x2 array of CLB Tiles
// ______________  ______________
// | CB1 -- SW  |  | CB1 -- SW  |
// | CLB -- CB0 |  | CLB -- CB0 |
// |    CFG     |  |    CFG     |
// |____________|  |____________|
// ______________  ______________
// | CB1 --  SW |  | CB1 --  SW |
// | CLB -- CB0 |  | CLB -- CB0 |
// |    CFG     |  |    CFG     |
// |____________|  |____________|
//

// Array dimension
`define NUM_ROWS 8
`define NUM_COLS 7

// LUT parameters
`define S_XX_BASE 4
`define NUM_LUTS 4

// Interconnect parameters
`define WS 4
`define WD 8
`define WG 0
`define CLBOS 4
`define CLBOD 4
`define CLBX 1


`define NUM_CLB_TILES (`NUM_ROWS * `NUM_COLS)
`define LUT_CFG_SIZE  (2 * (2 ** `S_XX_BASE) + 1)
`define MUX_LVLS      $clog2(`NUM_LUTS)

// 1x S44 LUT inputs, Inter-LUT MUX inputs, reg_ce
`define NUM_CLB_INS  10 // (2 * `S_XX_BASE + `MUX_LVLS + 1)

// 2x Comb. outputs, Sync. outputs
`define NUM_CLB_OUTS 5 // (2 * 2)

`define SWITCH_PER_IN  (`WS + `WD + `WG + `CLBX * `NUM_CLB_OUTS)
`define SWITCH_PER_OUT (`CLBOS + `CLBOD)

`define CLB_COMB_CFG_SIZE      (`LUT_CFG_SIZE * `NUM_LUTS + `MUX_LVLS + 1)
`define CLB_MEM_CFG_SIZE       (2 * `NUM_LUTS)
`define CB_CFG_SIZE            (2 * (`NUM_CLB_INS * `SWITCH_PER_IN + `NUM_CLB_OUTS * `SWITCH_PER_OUT))

`define SB_CFG_SIZE            (`WS + `WD / 2) * 6
`define CLB_TILE_COMB_CFG_SIZE (`CLB_COMB_CFG_SIZE + `SB_CFG_SIZE + `CB_CFG_SIZE * 2)
`define CLB_TILE_MEM_CFG_SIZE  (`CLB_MEM_CFG_SIZE)

`define CLB_TILE_BITSTREAM_SIZE (`CLB_TILE_COMB_CFG_SIZE + `CLB_TILE_MEM_CFG_SIZE + 2 + 2 + 2 + 2)

// Define the sequence of configuration bits for a tile
`define CFG_MEM_START_BIT      0
`define CFG_MEM_END_BIT        `CFG_MEM_START_BIT + `CLB_MEM_CFG_SIZE - 1
`define CFG_USE_CC_START_BIT   0
`define CFG_USE_CC_END_BIT     `CFG_USE_CC_START_BIT + 1 - 1
`define CFG_IXLUTMUX_START_BIT `CFG_USE_CC_END_BIT + 1
`define CFG_IXLUTMUX_END_BIT   `CFG_IXLUTMUX_START_BIT + `MUX_LVLS - 1
`define CFG_LUTS_START_BIT     `CFG_IXLUTMUX_END_BIT + 1
`define CFG_LUTS_END_BIT       `CFG_LUTS_START_BIT + `LUT_CFG_SIZE * `NUM_LUTS - 1
`define CFG_CB0_START_BIT      `CFG_LUTS_END_BIT + 1
`define CFG_CB0_END_BIT        `CFG_CB0_START_BIT + `CB_CFG_SIZE - 1
`define CFG_CB1_START_BIT      `CFG_CB0_END_BIT + 1
`define CFG_CB1_END_BIT        `CFG_CB1_START_BIT + `CB_CFG_SIZE - 1
`define CFG_SB_START_BIT       `CFG_CB1_END_BIT + 1
`define CFG_SB_END_BIT         `CFG_SB_START_BIT + `SB_CFG_SIZE - 1

`define CB_OFFSET0 (`NUM_CLB_INS * `SWITCH_PER_IN)
`define CB_OFFSET1 (`CB_OFFSET0 + `NUM_CLB_OUTS * `SWITCH_PER_OUT)
`define CB_OFFSET2 (`CB_OFFSET1 + `NUM_CLB_INS * `SWITCH_PER_IN)
`define SB_OFFSET0 (12 * (`WS / 2))

// Helper functions for switching connectivity

// SINGLE WIRES
// Connect wire single0[m] of Connection Block to CLB input n (from the same tile)
`define CB_SINGLE0_TO_CLB0_IN(m, n)  (`SWITCH_PER_IN * n + m)
// Connect CLB output m to wire single0[n] of Connection Block (from the same tile)
`define CLB0_OUT_TO_CB_SINGLE0(m, n) (`CB_OFFSET0 + `SWITCH_PER_OUT * m + n)
// Connect wire single0[m] of Connection Block to CLB input m (from an adjacent tile)
`define CB_SINGLE0_TO_CLB1_IN(m, n)  (`CB_OFFSET1 + `SWITCH_PER_IN * n + m)
// Connect CLB output m to wire single0[n] of Connection Block (from an adjacent tile)
`define CLB1_OUT_TO_CB_SINGLE0(m, n) (`CB_OFFSET2 + `SWITCH_PER_OUT * m + n)

// DOUBLE WIRES
// Note that with CLBOD = 4, only double[3], double[2], double[1], double[0] wires
// can be connect to CLB output pins
// Reference: ix_yukio/src/connection_block.v
// Connect wire single0[m] of Connection Block to CLB input n (from the same tile)
`define CB_DOUBLE0_TO_CLB0_IN(m, n)  (`SWITCH_PER_IN * n + `WS + m)
// Connect CLB output m to wire single0[n] of Connection Block (from the same tile)
`define CLB0_OUT_TO_CB_DOUBLE0(m, n) (`CB_OFFSET0 + `SWITCH_PER_OUT * m + `CLBOS + n)
// Connect wire single0[m] of Connection Block to CLB input m (from an adjacent tile)
`define CB_DOUBLE0_TO_CLB1_IN(m, n)  (`CB_OFFSET1 + `SWITCH_PER_IN * n + `WS + m)
// Connect CLB output m to wire single0[n] of Connection Block (from an adjacent tile)
`define CLB1_OUT_TO_CB_DOUBLE0(m, n) (`CB_OFFSET2 + `SWITCH_PER_OUT * m + `CLBOS + n)

// Connect CLB output m (from an adjacent tile) to CLB input n
`define CLB1_OUT_TO_CLB0_IN(m, n) (`SWITCH_PER_IN * m + `WS + `WD + n)
// Connect CLB output m to CLB input (from an adjacent tile)
`define CLB0_OUT_TO_CLB1_IN(m, n) (`CB_OFFSET1 + `SWITCH_PER_IN * m + `WS + `WD + n)

// Indices of Config bits for Switchbox PIPs
// Reference: ix_yukio/src/switch_box_element_two.v
//
// Convention: {Dir1}{Wire1}{Dir2}{Wire2}: enabling the connectivity of
// wire `Wire1` coming from `Dir1` and wire `Wire2` coming from `Dir2`
//
// Wire1 = {0, 1}, Wire2 = {0, 1}, Dir1 = {N, S, E, W}, Dir2 = {N, S, E, W}
//
// Note that {Dir1}{Wire1}{Dir2}{Wire2} and {Dir2}{Wire2}{Dir1}{Wire1} are
// the same (bi-directional)
//
// Each wire connects to three different directions => 8 * 3 / 2 = 12 PIPs inside
// switch_box_element_two (SBE2)

`define NUM_SBE2_PIPS 12

`define SINGLE_N0E0(x) (`NUM_SBE2_PIPS * x + 0)
`define SINGLE_N0S0(x) (`NUM_SBE2_PIPS * x + 4)
`define SINGLE_N0W1(x) (`NUM_SBE2_PIPS * x + 11)

`define SINGLE_N1E1(x) (`NUM_SBE2_PIPS * x + 8)
`define SINGLE_N1S1(x) (`NUM_SBE2_PIPS * x + 6)
`define SINGLE_N1W0(x) (`NUM_SBE2_PIPS * x + 3)

`define SINGLE_E0W0(x) (`NUM_SBE2_PIPS * x + 7)
`define SINGLE_E0N0(x) (`NUM_SBE2_PIPS * x + 0)
`define SINGLE_E0S1(x) (`NUM_SBE2_PIPS * x + 9)

`define SINGLE_E1W1(x) (`NUM_SBE2_PIPS * x + 5)
`define SINGLE_E1N1(x) (`NUM_SBE2_PIPS * x + 8)
`define SINGLE_E1S0(x) (`NUM_SBE2_PIPS * x + 1)

`define SINGLE_S0W0(x) (`NUM_SBE2_PIPS * x + 10)
`define SINGLE_S0N0(x) (`NUM_SBE2_PIPS * x + 4)
`define SINGLE_S0E1(x) (`NUM_SBE2_PIPS * x + 1)

`define SINGLE_S1W1(x) (`NUM_SBE2_PIPS * x + 2)
`define SINGLE_S1N1(x) (`NUM_SBE2_PIPS * x + 6)
`define SINGLE_S1E0(x) (`NUM_SBE2_PIPS * x + 9)

`define SINGLE_W0E0(x) (`NUM_SBE2_PIPS * x + 7)
`define SINGLE_W0S0(x) (`NUM_SBE2_PIPS * x + 10)
`define SINGLE_W0N1(x) (`NUM_SBE2_PIPS * x + 3)

`define SINGLE_W1E1(x) (`NUM_SBE2_PIPS * x + 5)
`define SINGLE_W1S1(x) (`NUM_SBE2_PIPS * x + 2)
`define SINGLE_W1N0(x) (`NUM_SBE2_PIPS * x + 11)

`define DOUBLE_N0E0(x) ((`WS / 2) * `NUM_SBE2_PIPS + `NUM_SBE2_PIPS * x + 0)
`define DOUBLE_N0S0(x) ((`WS / 2) * `NUM_SBE2_PIPS + `NUM_SBE2_PIPS * x + 4)
`define DOUBLE_N0W1(x) ((`WS / 2) * `NUM_SBE2_PIPS + `NUM_SBE2_PIPS * x + 11)

`define DOUBLE_N1E1(x) ((`WS / 2) * `NUM_SBE2_PIPS + `NUM_SBE2_PIPS * x + 8)
`define DOUBLE_N1S1(x) ((`WS / 2) * `NUM_SBE2_PIPS + `NUM_SBE2_PIPS * x + 6)
`define DOUBLE_N1W0(x) ((`WS / 2) * `NUM_SBE2_PIPS + `NUM_SBE2_PIPS * x + 3)

`define DOUBLE_E0W0(x) ((`WS / 2) * `NUM_SBE2_PIPS + `NUM_SBE2_PIPS * x + 7)
`define DOUBLE_E0N0(x) ((`WS / 2) * `NUM_SBE2_PIPS + `NUM_SBE2_PIPS * x + 0)
`define DOUBLE_E0S1(x) ((`WS / 2) * `NUM_SBE2_PIPS + `NUM_SBE2_PIPS * x + 9)

`define DOUBLE_E1W1(x) ((`WS / 2) * `NUM_SBE2_PIPS + `NUM_SBE2_PIPS * x + 5)
`define DOUBLE_E1N1(x) ((`WS / 2) * `NUM_SBE2_PIPS + `NUM_SBE2_PIPS * x + 8)
`define DOUBLE_E1S0(x) ((`WS / 2) * `NUM_SBE2_PIPS + `NUM_SBE2_PIPS * x + 1)

`define DOUBLE_S0W0(x) ((`WS / 2) * `NUM_SBE2_PIPS + `NUM_SBE2_PIPS * x + 10)
`define DOUBLE_S0N0(x) ((`WS / 2) * `NUM_SBE2_PIPS + `NUM_SBE2_PIPS * x + 4)
`define DOUBLE_S0E1(x) ((`WS / 2) * `NUM_SBE2_PIPS + `NUM_SBE2_PIPS * x + 1)

`define DOUBLE_S1W1(x) ((`WS / 2) * `NUM_SBE2_PIPS + `NUM_SBE2_PIPS * x + 2)
`define DOUBLE_S1N1(x) ((`WS / 2) * `NUM_SBE2_PIPS + `NUM_SBE2_PIPS * x + 6)
`define DOUBLE_S1E0(x) ((`WS / 2) * `NUM_SBE2_PIPS + `NUM_SBE2_PIPS * x + 9)

`define DOUBLE_W0E0(x) ((`WS / 2) * `NUM_SBE2_PIPS + `NUM_SBE2_PIPS * x + 7)
`define DOUBLE_W0S0(x) ((`WS / 2) * `NUM_SBE2_PIPS + `NUM_SBE2_PIPS * x + 10)
`define DOUBLE_W0N1(x) ((`WS / 2) * `NUM_SBE2_PIPS + `NUM_SBE2_PIPS * x + 3)

`define DOUBLE_W1E1(x) ((`WS / 2) * `NUM_SBE2_PIPS + `NUM_SBE2_PIPS * x + 5)
`define DOUBLE_W1S1(x) ((`WS / 2) * `NUM_SBE2_PIPS + `NUM_SBE2_PIPS * x + 2)
`define DOUBLE_W1N0(x) ((`WS / 2) * `NUM_SBE2_PIPS + `NUM_SBE2_PIPS * x + 11)

