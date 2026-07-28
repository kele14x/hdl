// File: oran_pkg.sv
// Brief: Package holds useful constants and functions for O-RAN
`timescale 1 ns / 1 ps

package oran_pkg;

  function automatic logic [3:0] tkeep_size(input logic [7:0] tkeep);
    tkeep_size = 4'd0;
    for (int i = 0; i < 8; i++) begin
      if (tkeep[i]) tkeep_size = 4'(i + 1);
    end
  endfunction

  function automatic logic [63:0] byte_reverse(input logic [63:0] data);
    for (int i = 0; i < 8; i++) begin
      byte_reverse[63-i*8-:8] = data[i*8+7-:8];
    end
  endfunction

endpackage
