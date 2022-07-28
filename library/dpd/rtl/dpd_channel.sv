// File: dpd_channel.sv
// Brief: One channel of DPD.
`timescale 1 ns / 1 ps
//
`default_nettype none

module dpd_channel #(
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
    // Control signals
    input var                                           ctrl_clk,
    input var                                           ctrl_rst,
    //   Gain block
    input var  signed [                 DATA_WIDTH-1:0] ctrl_pre_gmp_gain,
    //
    input var                                           ctrl_nlf_bank,
    //
    input var         [                DELAY_WIDTH-1:0] ctrl_nlf_index_delay [NUM_UNITS],
    input var         [                DELAY_WIDTH-1:0] ctrl_nlf_signal_delay[NUM_UNITS],
    //
    input var         [$clog2(NUM_UNITS)+INDEX_WIDTH:0] ctrl_lut_addr,
    input var                                           ctrl_lut_en,
    input var                                           ctrl_lut_we,
    input var         [           LUT_DATA_WIDTH*2-1:0] ctrl_lut_din,
    output var        [           LUT_DATA_WIDTH*2-1:0] ctrl_lut_dout,
    //   QMC
    input var  signed [                 DATA_WIDTH-1:0] ctrl_qmc_i_gain,
    input var  signed [                 DATA_WIDTH-1:0] ctrl_qmc_q_gain,
    input var  signed [                 DATA_WIDTH-1:0] ctrl_qmc_qi_gain,
    input var  signed [                 DATA_WIDTH-1:0] ctrl_qmc_i_offset,
    input var  signed [                 DATA_WIDTH-1:0] ctrl_qmc_q_offset
);


  logic signed [DATA_WIDTH-1:0] data_gain_i_s;
  logic signed [DATA_WIDTH-1:0] data_gain_q_s;

  gain #(
      .DATA_WIDTH(DATA_WIDTH),
      .GAIN_WIDTH(GAIN_WIDTH),
      .SRA_BITS  (SRA_BITS)
  ) i_gain_i (
      .clk     (clk),
      .rst     (rst),
      //
      .data_in (data_i_in),
      .data_out(data_gain_i_s),
      // gain
      .gain    (ctrl_pre_gmp_gain)
  );

  gain #(
      .DATA_WIDTH(DATA_WIDTH),
      .GAIN_WIDTH(GAIN_WIDTH),
      .SRA_BITS  (SRA_BITS)
  ) i_gain_q (
      .clk     (clk),
      .rst     (rst),
      //
      .data_in (data_q_in),
      .data_out(data_gain_q_s),
      // gain
      .gain    (ctrl_pre_gmp_gain)
  );

  dpd_gmp #(
      .NUM_UNITS  (NUM_UNITS),
      .DATA_WIDTH (DATA_WIDTH),
      .INDEX_WIDTH(INDEX_WIDTH)
  ) i_gmp (
      .clk       (clk),
      .rst       (rst),
      //
      .data_i_in (data_i_in),
      .data_q_in (data_q_in),
      //
      .data_i_out(data_i_out),
      .data_q_out(data_q_out)
  );

  qmc #(
      .DATA_WIDTH(DATA_WIDTH),
      .GAIN_WIDTH(GAIN_WIDTH),
      .SRA_BITS  (SRA_BITS)
  ) i_qmc (
      .clk        (clk),
      .rst        (rst),
      //
      .data_i_in  (data_i_in),
      .data_q_in  (data_q_in),
      .data_i_out (data_i_out),
      .data_q_out (data_q_out),
      //
      .gain_i_in  (ctrl_qmc_i_gain),
      .gain_q_in  (ctrl_qmc_q_gain),
      .gain_qi_in (ctrl_qmc_qi_gain),
      .offset_i_in(ctrl_qmc_i_offset),
      .offset_q_in(ctrl_qmc_q_offset)
  );

endmodule

`default_nettype wire
