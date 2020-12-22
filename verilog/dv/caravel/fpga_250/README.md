# FPGA250 tests

1) Basic Configuration test:

	* A quick test to check if the wishbone configuration cores of the user project
  module (fpga250) is able to communicate with the Caravel SoC via the Wishbone transaction.

2) Standalone test:

	* A user project (fpga250) test without the Caravel SoC system. A pre-generated
  bitstream implements some simple circuit on the FPGA. The states of the circuit
  (Flipflops, CLB outputs, and GPIOs) are compared against a set of golden outputs
  to check if the test is passed.

3) Integration test:

  * An integration test of the Caravel and the user project module. It is an extended
  version of the Basic config test, but now the entire bitstream is compiled in
  the software code and is loaded to the user project module via the Wishbone interface.
  The bitstream initializes the states of some FFs and routes them to configured LUTs.
  The final result is routed to an io output pin (`mprj_io[24]`) (TODO: some figure).

The simulation testbenches can be compiled and run with IVerilog. However, if it
is possible, we would like to suggest using Synopsys VCS instead, since it is
generally much faster (especially for the integration test where loading a complete bitstream
of 58,184 bits might take days to finish if using IVerilog, but under 5 minutes
in the case of VCS). A caveat with using VCS is that it is not happy with the
`default_nettype none` in some of the sky130 primitive Verilog files, so those
need to be replaced with `default_nettype wire`.
