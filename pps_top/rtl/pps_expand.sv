// File: pps_expand.sv
// Brief: Expand the 1PPS output wider for output to PAD
`timescale 1 ns / 1 ps
//
`default_nettype none

module pps_expand (
    input var  clk,
    input var  rst,
    input var  pps_in,
    output var pps_out_pad
);

  localparam int Width = 11;

  logic [Width-1:0] pps_ext;
  (* IOB="true" *)
  logic             pps_reg;

  // Extern the pps pulse longer for output to pad

  always_ff @(posedge clk) begin
    if (pps_in) begin
      pps_ext <= 1;
    end else if (|pps_ext) begin
      pps_ext <= pps_ext + 1;
    end
  end

  always_ff @(posedge clk) begin
    pps_reg <= |pps_ext;
  end

  assign pps_out_pad = pps_reg;

endmodule

`default_nettype wire
