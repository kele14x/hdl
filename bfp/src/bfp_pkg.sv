// File: bfp_pkg.sv
// Brief: Package for BFP
`timescale 1 ns / 1 ps
//
`default_nettype none

package bfp_pkg;

  //
  // This function does byte reverse for AXI-Stream TDATA signal
  //
  function static logic [63:0] byte_reverse(input logic [63:0] din);
    for (int i = 0; i < 8; i++) begin
      byte_reverse[63-8*i-:8] = din[8*i+7-:8];
    end
  endfunction

endpackage
