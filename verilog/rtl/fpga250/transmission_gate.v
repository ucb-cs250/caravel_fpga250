module transmission_gate(inout a, inout b, input c);
  transmission_gate_cell impl(.A(a), .B(b), .C(c), .Cnot(~c));
endmodule
