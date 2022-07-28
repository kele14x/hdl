// File: dpd_gmp.sv
// Brief: dpd_gmp module implements the GMP-DPD model.
`timescale 1 ns / 1 ps
//
`default_nettype none

module dpd_gmp #(
    parameter int NUM_UNITS      = 16,
    parameter int DATA_WIDTH     = 16,
    parameter int DELAY_WIDTH    = 5,
    parameter int INDEX_WIDTH    = 8,
    parameter int LUT_DATA_WIDTH = 16,
    parameter int SRA_BITS       = 14
) (
    input var                                           clk,
    input var                                           rst,
    //
    input var  signed [                 DATA_WIDTH-1:0] data_i_in,
    input var  signed [                 DATA_WIDTH-1:0] data_q_in,
    //
    input var  signed [                 DATA_WIDTH-1:0] data_i_out,
    input var  signed [                 DATA_WIDTH-1:0] data_q_out,
    // Control interface
    //==================
    input var                                           ctrl_clk,
    input var                                           ctrl_rst,
    //
    input var                                           ctrl_bank,
    //
    input var         [                DELAY_WIDTH-1:0] ctrl_index_delay [NUM_UNITS],
    input var         [                DELAY_WIDTH-1:0] ctrl_signal_delay[NUM_UNITS],
    //
    input var         [$clog2(NUM_UNITS)+INDEX_WIDTH:0] ctrl_lut_addr,
    input var                                           ctrl_lut_en,
    input var                                           ctrl_lut_we,
    input var         [           LUT_DATA_WIDTH*2-1:0] ctrl_lut_din,
    output var        [           LUT_DATA_WIDTH*2-1:0] ctrl_lut_dout
);

  // Local Parameters
  //=================

  // Magsq
  localparam int PreCompanderWidth = 2 ** EXPONENT_WIDTH + MANTISSA_WIDTH - 1;

  // Compander
  localparam int CompanderExponentWidth = 3;
  localparam int CompanderMantissaWidth = INDEX_WIDTH - CompanderExponentWidth;

  // Nlf
  localparam int NlfLutDataWidth = 16;
  localparam int NlfSraBits = 14;


  // Signals
  //========

  logic [    NlfIndexWidth-1:0] index_s;

  logic [PreCompanderWidth-1:0] data_magsq_s;
  logic                         ovf_magsq_s;

  dpd_magsq #(
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
      .ovf           (ovf_magsq_s)
  );

  dpd_compander #(
      .EXPONENT_WIDTH(CompanderExponentWidth),
      .MANTISSA_WIDTH(CompanderMantissaWidth)
  ) i_compand (
      .clk          (clk),
      .rst          (rst),
      //
      .data_magsq_in(data_magsq_s),
      .data_ovf_in  (ovf_magsq_s),
      //
      .index_out    (index_s)
  );

  nlf #(
      .NUM_UNITS     (NUM_UNITS),
      .DATA_WIDTH    (DATA_WIDTH),
      .INDEX_WIDTH   (INDEX_WIDTH),
      .LUT_DATA_WIDTH(NlfLutDataWidth),
      .SRA_BITS      (NlfSraBits)
  ) i_nlf (
      .clk              (clk),
      .rst              (rst),
      //
      .data_i_in        (data_i_in),
      .data_q_in        (data_q_in),
      //
      .index_in         (index_s),
      //
      .data_i_out       (data_i_out),
      .data_q_out       (data_q_out),
      // Overflow indicator
      .ovf              (ovf),
      // Control Interface
      //==================
      .ctrl_clk         (ctrl_clk),
      .ctrl_rst         (ctrl_rst),
      //
      .ctrl_bank        (ctrl_bank),
      //
      .ctrl_index_delay (ctrl_index_delay),
      .ctrl_signal_delay(ctrl_signal_delay),
      //
      .ctrl_lut_addr    (ctrl_lut_addr),
      .ctrl_lut_en      (ctrl_lut_en),
      .ctrl_lut_we      (ctrl_lut_we),
      .ctrl_lut_din     (ctrl_lut_din),
      .ctrl_lut_dout    (ctrl_lut_dout)
  );

endmodule

`default_nettype wire
