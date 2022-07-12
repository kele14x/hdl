// File: dpd_channel.sv
// Brief: One channel of DPD.
`timescale 1 ns / 1 ps
//
`default_nettype none

module dpd_channel #(
    parameter int DATA_WIDTH = 16
) (
    input var clk,
    input var rst,
    //
    input var [DATA_WIDTH-1:0] data_i_in,
    input var [DATA_WIDTH-1:0] data_q_in,
    //
    input var [DATA_WIDTH-1:0] data_i_out,
    input var [DATA_WIDTH-1:0] data_q_out
);

  // Local Parameters
  //=================

  // Compander
  localparam int CompanderExponentWidth = 3;
  localparam int CompanderMantissaWidth = 5;

  // Nlf
  localparam int NlfNumUnits = 16;
  localparam int NlfIndexWidth = CompanderExponentWidth + CompanderMantissaWidth;
  localparam int NlfLutDataWidth = 16;
  localparam int NlfSraBits = 14;

  // Signals
  //========

  logic [NlfIndexWidth-1:0] index_s;

  dpd_compander #(
      .DATA_WIDTH    (DATA_WIDTH),
      .EXPONENT_WIDTH(CompanderExponentWidth),
      .MANTISSA_WIDTH(CompanderMantissaWidth)
  ) i_compander (
      .clk      (clk),
      .rst      (rst),
      //
      .data_i_in(data_i_in),
      .data_q_in(data_q_in),
      //
      .index_out(index_s)
  );


  nlf #(
      .NUM_UNITS     (NlfNumUnits),
      .DATA_WIDTH    (DATA_WIDTH),
      .INDEX_WIDTH   (NlfIndexWidth),
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
