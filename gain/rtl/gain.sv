// File: gain.sv
// Brief: Gain block for the radio system.
`timescale 1 ns / 1ps
//
`default_nettype none

module gain #(
    parameter int DATA_WIDTH = 16,
    parameter int GAIN_WIDTH = 16,
    parameter int SRA_BITS   = 14
) (
    input var                          clk,
    input var                          rst,
    //
    input var  signed [DATA_WIDTH-1:0] data_in,
    output var signed [DATA_WIDTH-1:0] data_out,
    // gain
    input var  signed [GAIN_WIDTH-1:0] gain
);

  localparam integer Latency = 4;

  mult #(
      .A_WIDTH (DATA_WIDTH),
      .B_WIDTH (GAIN_WIDTH),
      .P_WIDTH (DATA_WIDTH),
      .SRA_BITS(SRA_BITS)
  ) i_mult (
      .clk(clk),
      .rst(rst),
      .a  (data_in),
      .b  (gain),
      .p  (data_out),
      .ovf(  /* not used */)
  );

endmodule

`default_nettype wire
