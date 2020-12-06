<!---
# SPDX-FileCopyrightText: 2020 Efabless Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# SPDX-License-Identifier: Apache-2.0
-->
# FPGA250

_CS250 VLSI Systems Design_  
_Fall 2020_  
_The University of California, Berkeley_  

## Authors

FPGA250 is an FPGA designed by [UC Berkeley's CS250](https://inst.eecs.berkeley.edu/~cs250/fa20/) class of Fall 2020:

- Adhiraj Datar
- Aled Cuda
- Jinyue Zhu
- Josh Alexander
- Kareem Ahmad
- Nate Young
- Philip Canoza
- Rohan Lageweg
- Ryan Lund
- Ryan Thornton
- Tan Nguyen
- Yuan Cheng (Anson) Tsai
- Yukio Miyasaka
- Arya Reais-Parsi (TA)
- John Wawrzynek (Professor)

# Overview

The FPGA comprises three basic tile types:

- MAC, a multiply-accumulate unit
- CLB, configurable logic blocks
  - each contain 4x S44 LUTs
- SRAM, a flexibly-shaped SRAM block

The current FPGA design includes a 4x3 grid of CLBs. Larger fabrics, which
include the MAC and SRAM tiles, should be possible with tooling help to improve
layout density.

# CLB

## SLICEL current design:
![SLICEL](doc/images/slicel.png?raw=true "SLICEL")
## SLICEM address mapping:
To reduce strain on the interconnect, as few wires as possible were added to the SLICEM.
* Highest order bits: The $clog2(NUM_LUTS) highest bits should be tied to the higher_order_addr input.  This is the same bits that are used for the mux7/mux8 analogs.
* Since S44 LUTs are used, we have an 7/8-bit "address" input, there is only 2^5 bits of memory within the LUT.  To address the soft-coded S44 structures without adding complex logic, a bank select was added.  This bank select bit acts as the 5th (for S44 LUTs) bit of the address.
* The lowest bits of the address should simply be the inputs to the LUTs.  The lowest bits of the address must be sent to every bank of every LUT, like `{NUM_LUTS*2{addr[3:0]}}`
## Fractured SLICE info:
* The fractured SLICE allows for a larger carry chain.  A standard 4 S44 LUT SLICE allows a 4-bit carry chain.  To add more carry chain functionality for a small-scale reconfigurable fabric, the carry chain is moved to an earlier stage of the LUT.  Fully fracturing an S44 SLICE (such that the carry chain uses the outputs of 2-LUTs) allows for a 16-bit carry chain.
* The carry chain is returned separately from the standard LUT output.

## Testbench
The verilator testbenches for the slicel module can be found in `sim/behavioral` and can be run with `make slicel_tb.vcd`. The slicel tests themselves can be found in `sim/behavioral/slicel_tb.ccp`. 
There are two slicel tests `test_slicel_crand` and `test_slicel_directed`.
* `test_slicel_crand(argc, argv, env, mode, seed, configs, iterations, verbosity)` : A constrained random test that runs `configs` independent tests for `iterations` clock cycles.
* `test_slicel_directed(argc, argv, env, mode, seed, iterations, verbosity)` : A constrained random test that runs a single test for `iterations` clock cycles. (Used for debugging once a failing seed has been found).
Options
* `argc, argv, env` : The arguments to the `main` function should be forwarded to verilator.
* `mode` : The style of test to run
  * `RAND` : Fully random configurations and inputs.
  * `BASIC_S44` : Luts are configured in s44 mode with random look up tables. Higher order muxes and carry chain is disabled. Inputs are random. 
  * `BASIC_FRAC` : Luts are configured as two 4-luts with random look up tables. Higher order muxes and carry chain is disabled. Inputs are random. 
  * `ADDER` : The slicel is configured to add 2 4-bit numbers. Inputs are constrained to add two 4-bit numbers per cycle. 
* `seed` : The random seed from which tests are generated. The `crand` test prints the seed for each individual test for use in `directed`.
* `configs` : `crand` only: The number of test to run. Each run has a different configuration.
* `iterations` : How long to run the test for a single configuration. Ie the number of inputs to pass the slicel. 
* `verbosity` : The level of detail of the output when running a test. (`min = 100`, `max = 400`).

## Running Directed Tests
In directed tests, the dut is manually configured and passed inputs, and the outputs can be read directly. This is useful for verifying cross-communication with other blocks.
The basic options when writing a directed test can be found in the basic skeleton/example: `sim/behavioral/slicel_directed.cpp`. 

This can be run from the `sim/behavioral` directory with `make slicel_directed.vcd`

### Configuration
There are a few ways to configure the slicel module in the testbench framework.
The configuration options available to the slicel module are:
* `lut[0-3]` : A 32-bit truth table for each s44 lut. The highest bit corresponds to the highest bit of the upper 4-lut.
* `soft` : A 4-bit value giving whether a lut is configured as 2 fractured 4-luts or an s44 lut. (0=s44, 1=fractured). The upper bit corresponds to lut3. 
* `cc` : A single bit value giving whether the carry chain should be used to drive slicel outputs. (1=carry_chain enabled)
* `inter_lut_muxes` : A two bit value `{f8_enable, f7_enable}` that determines if the f7 and f8 muxes should be treated as muxes or simply pass their lower input. (0=pass_through, 1=enabled)
* `register_reset`  : An eight bit value giving the reset values of each register. The upper bit corresponds to reg7.
A nonzero value is returned if configuration fails. This should only occur with invalid configurations: (eg. `cc=1 && inter_lut_muxes!=0`)

#### Option 1: Generated
To use an automatically generated configuration, use `test->generate_config(mode)`, where mode is as described in #Testbench. 

#### Option 2: Semi-Manual
You can alternatively generate a specific configuration without having to manually construct a bitstream with this option.

    test->assemble_config(lut0, lut1, lut2, lut3, soft, cc, inter_lut_muxes, register_reset) 

#### Option 3: Fully Manual
Use this option to configure the slicel with a bitstream. The bitstream is given as an argument as an `int cfg[5]` list, where cfg[4] gives the upper bits of the bitstream (and has its upper bits unused).

     int cfg[5] = {0,0,0,0,0};
     // set cfg here
     dut->configure(cfg, 5);

The configuration bitstream is defined as follows (big-endian). 

     {register_reset, cc, f8_enable, f7_enable, lut3_s, lut3, lut2_s, lut2, lut1_s, lut1, lut0_s, lut_0}

### Inputs
There are two ways to generate inputs for the slicel module in the testbench framework.
The inputs are
* `lut_inputs` : A 32 bit value giving the inputs to each s44 lut. `{lut3_in, lut2_in, lut1_in, lut0_in}`
  * Each lut gets 8 bits of input: `{upper_lut_in, lower_lut_in}`. Bit 3 is discarded in S44 mode and replaced with the output of the `upper_lut`. 
* `carry_in` : A 1-bit value giving the carry_in for the carry chain.
* `reg_ce` : A 1-bit value serving as the write_enable for the output registers of the slicel.
* `ho_addr` : A 2-bit value `{f8_select, f7_select}` serving as the select signal for the inter_lut_muxes when they are enabled. 

#### Option 1: Generated
Randomly generates inputs based on the mode. See (Testbench) for details on each mode.

     int lut_inputs; bool carry_in, reg_ce; char ho_addr;
     test->generate_inputs(RAND, lut_inputs, carry_in, reg_ce, ho_addr); // Options: RAND, ADDER;
     dut->input_set(lut_inputs, carry_in, reg_ce, ho_addr);

#### Option 2: Manual
Manually sets inputs. 

     dut->input_set(lut_inputs, carry_in, reg_ce, ho_addr);

### Time
It is recommended to use `ticktock` to progress the simulation, but if you want to check intermediate values, or change inputs at finer resolution you can use `tick` and `tock`. These do not affect the configuration clock `cclk`.

    dut->ticktock(); // @(posedge clk); @(negedge clk);
    dut->tick();     // @(posedge clk);
    dut->tock();     // @(negedge clk);

### Outputs
It is recommended to use `dut->info` for all prints. This behaves exactly as `printf` but with additional simulation information in the beginning.
The slicel has 3 outputs:
* `Co` : the carry out of the carry chain. Get it with `dut->get_carry_out()`
* `out` : the combinational outputs of the slicel as an 8bit word. Get it with `dut->get_out()`
* `sync_out` : the registered output of the slicel as an 8bit word. Get it with `dut->get_sync_out()`

# MAC

This is a width-configurable MAC "block" that can calculate 4-8bit\*8bit, 2-16bit\*16-bit, or 1-32bit\*32bit MAC or multiply operations in a single cycle. The operation and operation bitwidth can be configurated at runtime.

## Basic Block Diagram and IO
Below is a basic block diagram of the inputs and outputs of the MAC from an external point of view. More a closer look at the MAC, please refer to the section [MAC Cluster Block Diagram](#MAC-Cluster-Block-Diagram).

![block_diagram](https://github.com/ucb-cs250/mac_team/raw/master/diagrams/basic-block-diagram.png)

For IO, the whole MAC has 64 bits of total input (32 bits for each input) and 128 bits of total output. As the smallest input bitwidth is 8, the input wires are divided as such. To account for larger input bitwidths (16, 32), the inputs will span more wires. Similarly, the output is divided into 4 32-bit values as there will be 4 different accumulate outputs in the smallest bitwidth case. For larger bitwidths, the output will span more wires. 

Below is a table of the mapping of inputs/outputs to bitwidth configuration. The wires are specified in the above block diagram.

<table>
<thead>
  <tr>
    <th>Input Bitwidth</th>
    <th>Operation ID</th>
    <th>Input A</th>
    <th>Input B</th>
    <th>Output</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td rowspan="4">8</td>
    <td>0</td>
    <td>A0</td>
    <td>B0</td>
    <td>out0</td>
  </tr>
  <tr>
    <td>1</td>
    <td>A1</td>
    <td>B1</td>
    <td>out1</td>
  </tr>
  <tr>
    <td>2</td>
    <td>A2</td>
    <td>B2</td>
    <td>out2</td>
  </tr>
  <tr>
    <td>3</td>
    <td>A3</td>
    <td>B3</td>
    <td>out3</td>
  </tr>
  <tr>
    <td rowspan="2">16</td>
    <td>0</td>
    <td>{A1,A0}</td>
    <td>{B1,B0}</td>
    <td>{out1,out0}</td>
  </tr>
  <tr>
    <td>1</td>
    <td>{A3,A2}</td>
    <td>{B3,B2}</td>
    <td>{out3,out2}</td>
  </tr>
  <tr>
    <td>32</td>
    <td>0</td>
    <td>{A3,A2,A1,A0}</td>
    <td>{B3,B2,B1,B0}</td>
    <td>{out3,out2,out1,out0}</td>
  </tr>
</tbody>
</table>

## Configuration
The whole MAC cluster takes in 132 bits of configuration. The first 128 bits are used for initial accumulator values (4x32) and the last 4 bits are the function configuration that sets the signed operation (unsigned or signed), function (MAC or multiply) and the bitwidth (8-single, 16-dual, 32-quad). The bit layout is as follows:
`{32'acc3_init, 32'acc2_init, 32'acc1_init, 32'acc0_init, 1'signed, 1'function, 2'bitwidth}`
For the signed operation configuration bit, a `0` encodes unsigned while a `1` encodes signed operations. For the function configuration bit, a `0` encodes multiply only and a `1` encodes multiply-accumulate. For the bitwidth, a `00` encodes an operation bitwidth of 8 (single), a `01` encodes an operation bitwidth of 16 (dual), and `10` encodes an operation bitwidth of 32 (quad).

## Testing
We also supply a testbench to verify the functionality of the MAC. 

To build, run:
`make-clean && make`

To run the testbench, run:
`./simulator-mac_test_harness +cfg=<val> +num_tests=<val>`
where cfg is the 3-bit function configuration and num_tests is the number of tests. The different configuration codes are as follows:
```
0 = 4 8x8 mults, multiply  only   (unsigned)
1 = 2 16x16 mults, multiply only  (unsigned)
2 = 1 32x32 mult,  multiply only  (unsigned)
4 = 4 8x8 mults, MAC              (unsigned)
5 = 2 16x16 mults, MAC            (unsigned)
6 = 1 32x32 mult, MAC             (unsigned)

8 = 4 8x8 mults, multiply  only   (signed)
9 = 2 16x16 mults, multiply only  (signed)
10 = 1 32x32 mult,  multiply only (signed)
12 = 4 8x8 mults, MAC             (signed)
13 = 2 16x16 mults, MAC           (signed)
14 = 1 32x32 mult, MAC            (signed)
```

## MAC Cluster Block Diagram
For those who are interested in the design of the MAC, the below diagram briefly details the different components. The MAC "block" is actually designed as a cluster, where the operations are done in a distributed fashion across multiple blocks. This design was chosen as it allows the blocks to be moved around and custom placed to avoid any wire congestion, as the MAC cluster has a large number of inputs and outputs.

![cluster_block_diagram](https://github.com/ucb-cs250/mac_team/raw/master/diagrams/cluster-design.png)

Regarding the main components, the multiply, combiner, and accumulator blocks provide the MAC cluster's core functionality. Each multiply block preforms unsigned 8x8 multiply operations with up to 4 parallel multiplies at a time. For the single width (8-bit) configuration, each multiply block performs their own independent 8x8 multiply. For larger configurations such as the 16 and 32-bit inputs, the multiply blocks perform multiple operations in parallel to compute the cross-products to multiply larger bitwidths. The combiner block then takes those cross-products and assembles them into the correct result. Once the inputs have been properly multiplied, they are then passed into the accumulator which will then accumulate the values or forward the values depending on the configured function.

For the MAC to support signed operations, negator blocks are cleverly used to manipulate the sign of the multiplication inputs and outputs such that we can re-use the unsigned multipliers to avoid extra hardware. The first negator block will take the absolute value of all inputs to allow for unsigned multiplication, while the second negator will assign the correct sign after the multiplication has completed. This double negation layer strategy allows us to properly multiply signed inputs without having the need for signed multipliers.

For more exact block diagrams of each component, you can check out the [diagrams directory](https://github.com/ucb-cs250/mac_team/tree/master/diagrams).

# Interconnect Architecture

**I'm a resident of the looking-glass world!!** (Every figure in this page is mirrored by y-axis)

The modules are in src directory. There is a testbench for each module in testbench directory.

The unidirectional version is in unidir_src directory. Its README is also in that directory.

## parameters
### parameters from modules
 - CLBIN ... number of input-bits to one CLB
 - CLBOUT ... number of output-bits of one CLB
 - CARRY ... number of carry-bits passed between CLBs
 - WW ... unit word width
 - MACDATAIN ... number of input-words to one MAC module (WW*MACDATAIN input bits)
 - MACDATAOUT ... number of output-words of one MAC module
 - MACCONTROLIN ... number of control-bits to one MAC module
 - NCLBMAC ... number of CLB-rows per one MAC-row (MAC/CLB in terms of height)
 - MEMDATAIN
 - MEMDATAOUT
 - MEMCONTROLIN
 - NCLBMEM
### parameters to top module
 - N ... number of big-tiles vertically
 - M ... number of big-tiles horizontally
 - WS ... number of bits (tracks) in each single line
 - WD ... number of bits in each double line. WD must be multiple of 2
 - WG ... number of bits in each global line
 - WN ... number of words in the line around MAC/MEM modules (WN * WW bits)
 - CLBOS ... number of the switches to connect each output of CLB to the single line tracks
 - CLBOD ... number of the switches to connect each output of CLB to the double line tracks
 - CLBIOTYPE ... 0 -> anyside with MUX, 1 -> left to right or right to left with MUX, 2 -> divided (CLBIN and CLBOUT must be multiple of 4)
 - CLBX ... a boolean value to toggle using direct connection between adjacent CLBs
 - CARRYTYPE ... 0 -> anyside with MUX, 1 -> vertical two-way and horizontal one-way only at the top and bottom with MUX, 2 -> one-way meandering (top to bottom -> left to right -> bottom to top -> left to right -> ...)
 - MCLB ... number of CLB-columns in a big-tileset. MCLB must be multiple of 2.
 - NSB ... No horizontal line and SB when ROW%NSB != 0 (except near io block and MAC/MEM). CLBIOTYPE must not be 2 when NSB is not 1. This is for layered interconnect.
 - NSBSB ... number of SBs connected to one DSB. NSBSB must be less than or equal to min(NCLBMAC, NCLBMEM).
 - NMAC ... number of MAC modules in a big-tile
 - NMEM ... number of MEM modules in a big-tile
 - EXTIN ... number of external input-pins in each io block
 - EXTOUT ... number of external output-pins in each io block
 - EXTDATAIN ... number of external input-words in each data io block
 - EXTDATAOUT ... number of external input-words in each data io block

I define a big-tile as a figure below. It has one column for MAC and MEM in the middle. There may be multiple MAC modules and MEM modules in one big-tile, then the MAC modules are placed upper than all of the MEM modules. On the edges of FPGA, there are io blocks, one for each SB on the edges, two for each SB at the corners. There are also data io blocks for DSBs.

fpga.v in fpgatop branch implements this, but it has problems and yet to be simulated. iverilog ran into internal errors (buffer overflaw) when I increased some parameters. verilator seems to have problems in 2D array. Anyway it might help you understand how these parameters should be treated.

![図2](https://user-images.githubusercontent.com/18373300/96973575-07aa4400-1553-11eb-8530-51e3b2d9d46c.png)

## modules
The signals starting with "c" represent configuration bits.
 - transmission_gate.v
 
 ![transmission_gate](https://user-images.githubusercontent.com/18373300/96963877-6916e680-1544-11eb-9ea9-bd1d7e27087b.png)
 
 - transmission_gate_oneway.v
 
 I use this cell when one of the data is not inout. This enables verilator to compile the modules. The cell design of this module would be the same as transmission_gate.v.
 
 ![transmission_gate_oneway](https://user-images.githubusercontent.com/18373300/96965087-88af0e80-1546-11eb-9fac-6c1be11b2027.png)
 
 - switch_box_element_one.v
 
 ![switch_box_element_one](https://user-images.githubusercontent.com/18373300/96963948-8ba8ff80-1544-11eb-9c01-2999a1ba817a.png)

 - switch_box_element_two.v
 
 ![switch_box_element_two](https://user-images.githubusercontent.com/18373300/96964090-cdd24100-1544-11eb-9fa0-d4afc307939f.png)

 - disjoint_switch_box.v
 
 ![disjoint_swtich_box](https://user-images.githubusercontent.com/18373300/96964199-03772a00-1545-11eb-9d46-d5ad477a92df.png)
 
 - universal_switch_box.v
   - When W is even
   
   ![universal_swtich_box](https://user-images.githubusercontent.com/18373300/96964412-5b159580-1545-11eb-838c-4de78d1e9f40.png)
   
   - When W is odd
   
   ![universal_swtich_box_odd](https://user-images.githubusercontent.com/18373300/96964226-0eca5580-1545-11eb-9a7a-5e316d419d48.png)
 
 - clb_switch_box.v
 
 One universal switch box for single lines and the following circuit for double lines.
 
 ![universal_swtich_box_double](https://user-images.githubusercontent.com/18373300/96964553-a16af480-1545-11eb-9dc0-19efc26c21c4.png)
 
 - vertical_disjoint_switch_box.v
 
 This is used as a switch box where there is no horizontal line in layered interconnect.
 
 ![vertical_disjoint_switch_box](https://user-images.githubusercontent.com/18373300/97480049-4185ab00-1996-11eb-9149-67dc0bc53fcd.png)
 
 - connection_block.v
 
 The number of inputs of CLB is CLBIN, but only first  CLBIN0(CLBIN1) bits are connected to the tracks. When CLBX, a boolean parameter, is 1, there are direct connections. The number of switches for each output is limited by a parameter, and the place of switches is shifted per output. The amount of the last shift is passed to the next connection block as a bias. Please notice the places of c31 and c32.
 
 ![connection_block](https://user-images.githubusercontent.com/18373300/99103907-9fb3be80-2623-11eb-97be-50b7ff5bc38a.png)

 - data_connection_block.v
 
 For data input/output for MAC/MEM.
 
 ![data_connection_block](https://user-images.githubusercontent.com/18373300/96966034-12aba700-1548-11eb-9e36-c9936c738c75.png)

 - control_connection_block.v
 
 For control (address) input for MAC/MEM.
 
 ![control_connection_block](https://user-images.githubusercontent.com/18373300/96966636-1ab81680-1549-11eb-916d-e4433f3d66b9.png)

 - io_block.v
 
 ![io_block](https://user-images.githubusercontent.com/18373300/96966388-abdabd80-1548-11eb-8a05-bddb7e26197c.png)
 
 - data_io_block.v
 
 ![data_io_block](https://user-images.githubusercontent.com/18373300/96966742-5bb02b00-1549-11eb-87e3-4a54d98da72f.png)
 
 - switch_box_connector.v
 
 Just connecting wires under modulus. Short circuit should not happen because the other end of wire can be 1'bz in switch boxes.
 
 ![switch_box_connector v](https://user-images.githubusercontent.com/18373300/96971586-4a1e5180-1550-11eb-927b-afd4af3f2a82.png)

# SRAM Architecture

# Configuration Architecture

## Tile Config

The config_tile module holds the configuration bits for every configurable option in a given tile (excluding SRAM bits). The `config_tile` module is designed to be fed from either a hardwired shift chain that spans a column of tiles, or from the fabric, allowing for arbitrarily granular dynamic reconfiguration of tiles.

### Notional Startup and Configuration

1. After a reset the on-chip RISC-V core would feed in a full bitstream of configuration to each column and then deassert a global `shift_enable` signal to freeze the bitstream in place in the chain.
2. The RISC-V cores can then assert the `set` signal on each column which will load the bits into their respective configuration latches
3. On selective tiles destined for dynamic reconfiguration, the first config bit in each tile would be set, this would switch the muxes attached to the `shift_in` and `set` inputs away from the hardwired column inputs, and to inputs that come from the regular device interconnect.
4. Some softcore built into the fabric can then feed new configuration data into the tile at anytime to change its behavior.

## SRAM Data Config

The `config_sram_data` module performs boot-time initilization of the SRAM Blocks with contents, and resides within every SRAM Block tile.

Each block has a shift register with an address segment followed by a data segment. Each segment feeds the appropriate signal of the write port on the SRAM Block. When the `set` signal of the `config_sram_data` module is asserted, the module asserts the `write_enable` signal on its associated SRAM Block which writes the data contained in the shift register at the appropriate address. In order to configure a column, every `config_sram_data` module in a column is linked end to end to create one long shift register. The RISC-V pump in address-data pairs and assert the `set` signal to load data into the every SRAM block.
The config team is building a set of modules to enable the initilization of the device, and to enable dynamic reconfiguration of the device. Behavioral verilog modules are stored in `src/verilog` with testbenches for each in `sim/`. (Hopefully) Up to date diagrams of each module are stored in the `docs/` folder, in both svg and xcircuit Postscript files.

## Tile Config

The config_tile module holds the configuration bits for every configurable option in a given tile (excluding SRAM bits). The `config_tile` module is designed to be fed from either a hardwired shift chain that spans a column of tiles, or from the fabric, allowing for arbitrarily granular dynamic reconfiguration of tiles.

### Notional Startup and Configuration

1. After a reset the on-chip RISC-V core would feed in a full bitstream of configuration to each column and then deassert a global `shift_enable` signal to freeze the bitstream in place in the chain.
2. The RISC-V cores can then assert the `set` signal on each column which will load the bits into their respective configuration latches
3. On selective tiles destined for dynamic reconfiguration, the first config bit in each tile would be set, this would switch the muxes attached to the `shift_in` and `set` inputs away from the hardwired column inputs, and to inputs that come from the regular device interconnect.
4. Some softcore built into the fabric can then feed new configuration data into the tile at anytime to change its behavior.

## SRAM Data Config

The `config_sram_data` module performs boot-time initilization of the SRAM Blocks with contents, and resides within every SRAM Block tile.

Each block has a shift register with an address segment followed by a data segment. Each segment feeds the appropriate signal of the write port on the SRAM Block. When the `set` signal of the `config_sram_data` module is asserted, the module asserts the `write_enable` signal on its associated SRAM Block which writes the data contained in the shift register at the appropriate address. In order to configure a column, every `config_sram_data` module in a column is linked end to end to create one long shift register. The RISC-V pump in address-data pairs and assert the `set` signal to load data into the every SRAM block.

# Custom Cells

## Transmission Gates

