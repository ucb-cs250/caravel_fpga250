module transmission_gate_oneway(output a, input b, input c);
   assign a = c? b: 1'bz;
endmodule
