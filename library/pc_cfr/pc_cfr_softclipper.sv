//******************************************************************************
// Copyright (C) 2020  kele14x
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
//******************************************************************************

// File: cfr_cpg.sv
// Brief: cfr_cpg is Canceling pulse generator. It' designed as cascade-able.

`timescale 1ns / 1ps `default_nettype none

module pc_cfr_softclipper #(
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
    //
    input var  logic                             ctrl_cpw_wr_en,
    input var  logic        [CPW_ADDR_WIDTH-1:0] ctrl_cpw_wr_addr,
    input var  logic        [    DATA_WIDTH-1:0] ctrl_cpw_wr_data_i,
    input var  logic        [    DATA_WIDTH-1:0] ctrl_cpw_wr_data_q
);

  logic        [DATA_WIDTH-1:0] data_i_s    [NUM_CPG+1];
  logic        [DATA_WIDTH-1:0] data_q_s    [NUM_CPG+1];

  logic signed [DATA_WIDTH-1:0] peak_i_s    [NUM_CPG+1];
  logic signed [DATA_WIDTH-1:0] peak_q_s    [NUM_CPG+1];
  logic                         peak_phase_s[NUM_CPG+1];
  logic                         peak_valid_s[NUM_CPG+1];

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

  (* keep_hierarchy="yes" *)
  reg_pipeline #(
      .DATA_WIDTH     (DATA_WIDTH * 2),
      .PIPELINE_STAGES(136)
  ) i_delay (
      .clk (clk),
      .din ({data_q_in, data_i_in}),
      .dout({data_q_s[0], data_i_s[0]})
  );

  generate
    for (genvar i = 0; i < NUM_CPG; i++) begin : g_cpgs
      (* keep_hierarchy="yes" *)
      pc_cfr_cpg #(
          .DATA_WIDTH    (DATA_WIDTH),
          .CPW_ADDR_WIDTH(CPW_ADDR_WIDTH)
      ) i_pc_cfr_cpg (
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
          .ctrl_cpw_wr_en    (ctrl_cpw_wr_en),
          .ctrl_cpw_wr_addr  (ctrl_cpw_wr_addr),
          .ctrl_cpw_wr_data_i(ctrl_cpw_wr_data_i),
          .ctrl_cpw_wr_data_q(ctrl_cpw_wr_data_q)
      );
    end
  endgenerate

endmodule

`default_nettype wire
