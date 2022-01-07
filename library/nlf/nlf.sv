// File: nlf.sv
// Brief: Nonlinear Filter

`timescale 1 ns / 1 ps `default_nettype none

module nlf #(
    parameter int NUM_UNITS      = 16,
    parameter int DATA_WIDTH     = 16,
    parameter int INDEX_WIDTH    = 8,
    parameter int LUT_DATA_WIDTH = 16,
    parameter int SRA_BITS       = 15
) (
    input var  logic                         clk,
    input var  logic                         rst,
    //
    input var  logic [       DATA_WIDTH-1:0] data_i_in,
    input var  logic [       DATA_WIDTH-1:0] data_q_in,
    //
    output var logic [       DATA_WIDTH-1:0] data_i_out,
    output var logic [       DATA_WIDTH-1:0] data_q_out,
    // Overflow indicator
    output var logic                         ovf,
    // Control Interface
    input var  logic                         ctrl_clk,
    input var  logic                         ctrl_rst,
    //
    input var  logic [$clog2(NUM_UNITS)-1:0] ctrl_index_delay [NUM_UNITS],
    input var  logic [$clog2(NUM_UNITS)-1:0] ctrl_signal_delay[NUM_UNITS]
);

  localparam DelayWidth = $clog2(NUM_UNITS);
  localparam LutWidth = LUT_DATA_WIDTH * 2;

  logic [DATA_WIDTH+1:0] data_theta;

  logic [DATA_WIDTH-1:0] data_i_d;
  logic [DATA_WIDTH-1:0] data_q_d;

  logic [DATA_WIDTH-1:0] data_i_s[NUM_UNITS];
  logic [DATA_WIDTH-1:0] data_q_s[NUM_UNITS];

  logic [INDEX_WIDTH-1:0] data_index;

  logic [INDEX_WIDTH-1:0] data_index_s[NUM_UNITS];


  cordic_cart2pol #(
      .DATA_WIDTH          (DATA_WIDTH),
      .CTRL_WIDTH          (DATA_WIDTH * 2),
      .ITERATIONS          (10),
      .COMPENSATION_SCALING(1)
  ) i_cordic_cart2pol (
      .clk     (clk),
      .rst     (rst),
      //
      .xin     (data_i_in),
      .yin     (data_q_in),
      .ctrl_in ({data_q_in, data_i_in}),
      //
      .theta   (data_theta),
      .r       (  /* not used */),
      .ctrl_out({data_q_d, data_i_d})
  );

  // TODO: Add compound module

  assign data_index = data_theta[DATA_WIDTH-1-:INDEX_WIDTH];

  nlf_delay_line #(
      .NUM_UNITS  (NUM_UNITS),
      .DELAY_WIDTH(DelayWidth),
      .DATA_WIDTH (INDEX_WIDTH)
  ) i_index_delay_line (
      // Read Interface
      .clk     (clk),
      //
      .data_in (data_index),
      .data_out(data_index_s),
      //
      .delay   (ctrl_index_delay)
  );

  nlf_delay_line #(
      .NUM_UNITS  (NUM_UNITS),
      .DELAY_WIDTH(DelayWidth),
      .DATA_WIDTH (INDEX_WIDTH)
  ) i_index_delay_line (
      // Read Interface
      .clk     (clk),
      //
      .data_in (data_index),
      .data_out(data_index_s),
      //
      .delay   ()
  );

  nlf_delay_line #(
      .NUM_UNITS  (NUM_UNITS),
      .DELAY_WIDTH(DelayWidth),
      .DATA_WIDTH (DATA_WIDTH)
  ) i_signal_i_delay_line (
      // Read Interface
      .clk     (clk),
      //
      .data_in (data_i_d),
      .data_out(data_i_s),
      //
      .delay   (ctrl_signal_delay)
  );

  nlf_delay_line #(
      .NUM_UNITS  (NUM_UNITS),
      .DELAY_WIDTH(DelayWidth),
      .DATA_WIDTH (DATA_WIDTH)
  ) i_signal_q_delay_line (
      // Read Interface
      .clk     (clk),
      //
      .data_in (data_q_d),
      .data_out(data_q_s),
      //
      .delay   (ctrl_signal_delay)
  );

  // TODO: Add core module

endmodule

`default_nettype wire
