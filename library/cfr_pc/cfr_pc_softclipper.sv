// File: cfr_cpg.sv
// Brief: cfr_cpg is Canceling pulse generator. It' designed as cascade-able.

`timescale 1ns / 1ps `default_nettype none

module cfr_pc_softclipper #(
    parameter int DATA_WIDTH     = 16,
    parameter int CPW_ADDR_WIDTH = 8,
    parameter int NUM_CPG        = 6
) (
    input var  logic                             clk,
    input var  logic                             rst,
    //
    input var  logic signed [    DATA_WIDTH-1:0] data_i_in,
    input var  logic signed [    DATA_WIDTH-1:0] data_q_in,
    //
    input var  logic signed [    DATA_WIDTH-1:0] peak_i_in,
    input var  logic signed [    DATA_WIDTH-1:0] peak_q_in,
    input var  logic                             peak_phase_in,
    input var  logic                             peak_valid_in,
    //
    output var logic signed [    DATA_WIDTH-1:0] data_i_out,
    output var logic signed [    DATA_WIDTH-1:0] data_q_out,
    //
    output var logic signed [    DATA_WIDTH-1:0] peak_i_out,
    output var logic signed [    DATA_WIDTH-1:0] peak_q_out,
    output var logic                             peak_phase_out,
    output var logic                             peak_valid_out,
    // Cancellation pulse write port
    input var  logic                             ctrl_clk,
    input var  logic                             ctrl_rst,
    //
    input var  logic        [CPW_ADDR_WIDTH-1:0] ctrl_cpw_addr,
    input var  logic                             ctrl_cpw_en,
    input var  logic                             ctrl_cpw_we,
    input var  logic        [    DATA_WIDTH-1:0] ctrl_cpw_wr_data_i,
    input var  logic        [    DATA_WIDTH-1:0] ctrl_cpw_wr_data_q
);

  logic        [DATA_WIDTH-1:0] data_i_s            [NUM_CPG+1];
  logic        [DATA_WIDTH-1:0] data_q_s            [NUM_CPG+1];

  logic signed [DATA_WIDTH-1:0] peak_i_s            [NUM_CPG+1];
  logic signed [DATA_WIDTH-1:0] peak_q_s            [NUM_CPG+1];
  logic                         peak_phase_s        [NUM_CPG+1];
  logic                         peak_valid_s        [NUM_CPG+1];

  logic        [DATA_WIDTH-1:0] ctrl_cpw_rd_data_i_s[  NUM_CPG];
  logic        [DATA_WIDTH-1:0] ctrl_cpw_rd_data_q_s[  NUM_CPG];

  // Connect input

  assign peak_i_s[0]     = peak_i_in;
  assign peak_q_s[0]     = peak_q_in;
  assign peak_phase_s[0] = peak_phase_in;
  assign peak_valid_s[0] = peak_valid_in;

  // Connect output

  assign data_i_out      = data_i_s[NUM_CPG];
  assign data_q_out      = data_q_s[NUM_CPG];

  assign peak_i_out      = peak_i_s[NUM_CPG];
  assign peak_q_out      = peak_q_s[NUM_CPG];
  assign peak_phase_out  = peak_phase_s[NUM_CPG];
  assign peak_valid_out  = peak_valid_s[NUM_CPG];


  reg_pipeline #(
      .DATA_WIDTH     (DATA_WIDTH * 2),
      .PIPELINE_STAGES(75)
  ) i_delay (
      .clk (clk),
      .din ({data_q_in, data_i_in}),
      .dout({data_q_s[0], data_i_s[0]})
  );

  generate
    for (genvar i = 0; i < NUM_CPG; i++) begin : g_cpgs
      cfr_pc_cpg #(
          .DATA_WIDTH    (DATA_WIDTH),
          .CPW_ADDR_WIDTH(CPW_ADDR_WIDTH)
      ) i_cfr_pc_cpg (
          .clk               (clk),
          .rst               (rst),
          //
          .data_i_in         (data_i_s[i]),
          .data_q_in         (data_q_s[i]),
          //
          .peak_i_in         (peak_i_s[i]),
          .peak_q_in         (peak_q_s[i]),
          .peak_phase_in     (peak_phase_s[i]),
          .peak_valid_in     (peak_valid_s[i]),
          //
          .data_i_out        (data_i_s[i+1]),
          .data_q_out        (data_q_s[i+1]),
          //
          .peak_i_out        (peak_i_s[i+1]),
          .peak_q_out        (peak_q_s[i+1]),
          .peak_phase_out    (peak_phase_s[i+1]),
          .peak_valid_out    (peak_valid_s[i+1]),
          //
          .ctrl_clk          (ctrl_clk),
          .ctrl_rst          (ctrl_rst),
          //
          .ctrl_cpw_addr     (ctrl_cpw_addr),
          .ctrl_cpw_en       (ctrl_cpw_en),
          .ctrl_cpw_we       (ctrl_cpw_we),
          .ctrl_cpw_wr_data_i(ctrl_cpw_wr_data_i),
          .ctrl_cpw_wr_data_q(ctrl_cpw_wr_data_q)
      );
    end
  endgenerate

endmodule

`default_nettype wire
