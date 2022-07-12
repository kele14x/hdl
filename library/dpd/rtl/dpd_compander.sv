// File: dpd_compander.sv
// Brief: Compand input complex signal into 8/9-bit index.
`timescale 1 ns / 1 ps
//
`default_nettype none

module dpd_compander #(
    parameter int DATA_WIDTH     = 16,
    parameter int EXPONENT_WIDTH = 3,
    parameter int MANTISSA_WIDTH = 5
) (
    input var                                      clk,
    input var                                      rst,
    //
    input var  [                   DATA_WIDTH-1:0] data_i_in,
    input var  [                   DATA_WIDTH-1:0] data_q_in,
    //
    output var [EXPONENT_WIDTH+MANTISSA_WIDTH-1:0] index_out
);

  localparam int PreCompanderWidth = 2 ** EXPONENT_WIDTH + MANTISSA_WIDTH - 1;
  localparam int PostCompanderWidth = EXPONENT_WIDTH + MANTISSA_WIDTH;


  logic [PreCompanderWidth-1:0] data_magsq_s;
  logic                         ovf_s;

  dpd_compander_magsq #(
      .INPUT_DATA_WIDTH (DATA_WIDTH),
      .OUTPUT_DATA_WIDTH(PreCompanderWidth),
      .SRA_BITS         (DATA_WIDTH * 2 - PreCompanderWidth - 2)
  ) i_magsq (
      .clk           (clk),
      .rst           (rst),
      //
      .data_i_in     (data_i_in),
      .data_q_in     (data_q_in),
      //
      .data_magsq_out(data_magsq_s),
      .ovf           (ovf_s)
  );

  dpd_compander_compand #(
      .EXPONENT_WIDTH(EXPONENT_WIDTH),
      .MANTISSA_WIDTH(MANTISSA_WIDTH)
  ) i_compand (
      .clk          (clk),
      .rst          (rst),
      //
      .data_magsq_in(data_magsq_s),
      .data_ovf_in  (ovf_s),
      //
      .index_out    (index_out)
  );

endmodule

`default_nettype wire
