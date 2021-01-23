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

// File: cfr_hardclipping.sv
// Brief: cfr_hardclipping performs brick-wall dynamic range limiting to input.
//        Dynamic range limiting suppresses the signal that cross the given
//        threshold. Those signal are hard clipped without maintains the
//        spectrum.

`timescale 1 ns / 1 ps `default_nettype none

module cfr_hardclipping #(
    parameter int DATA_WIDTH = 16
) (
    input var  logic                  clk,
    input var  logic                  rst,
    // Data input
    input var  logic [DATA_WIDTH-1:0] data_i_in,
    input var  logic [DATA_WIDTH-1:0] data_q_in,
    // Data output
    output var logic [DATA_WIDTH-1:0] data_i_out,
    output var logic [DATA_WIDTH-1:0] data_q_out,
    // Control
    input var  logic                  ctrl_enable,  // 1 = enable, 0 = bypass
    input var  logic [  DATA_WIDTH:0] ctrl_threshold  // unsigned
);


  localparam int Iterations = 7;
  localparam int DataPathLatency = Iterations * 2 + 8;

  logic                         ctrl_enable_s;
  logic        [  DATA_WIDTH:0] ctrl_threshold_s;

  logic signed [DATA_WIDTH-1:0] data_i_in_d;
  logic signed [DATA_WIDTH-1:0] data_q_in_d;

  logic        [  Iterations:0] data_theta;
  logic signed [DATA_WIDTH+1:0] data_r;

  logic        [  Iterations:0] delta_theta_0;
  logic signed [DATA_WIDTH+1:0] delta_r_0;

  logic        [  Iterations:0] delta_theta;
  logic signed [DATA_WIDTH+1:0] delta_r;

  logic signed [DATA_WIDTH+2:0] delta_i;
  logic signed [DATA_WIDTH+2:0] delta_q;


  // CTRL CDC

  cdc_array_single #(
    .DEST_SYNC_FF (2),
    .INIT_SYNC_FF (0),
    .SRC_INPUT_REG(0),
    .WIDTH        (1)
  ) i_cdc_array_single_ctrl_enable (
    .src_clk (1'b0),
    .src_in  (ctrl_enable),
    .dest_clk(clk),
    .dest_out(ctrl_enable_s)
  );

  cdc_array_single #(
    .DEST_SYNC_FF (2),
    .INIT_SYNC_FF (0),
    .SRC_INPUT_REG(0),
    .WIDTH        (DATA_WIDTH + 1)
  ) i_cdc_array_single_ctrl_threshold (
    .src_clk (1'b0),
    .src_in  (ctrl_threshold),
    .dest_clk(clk),
    .dest_out(ctrl_threshold_s)
  );

  // Delay input data for `DataPathLatency` clocks

  reg_pipeline #(
      .DATA_WIDTH     (DATA_WIDTH * 2),
      .PIPELINE_STAGES(DataPathLatency)
  ) i_delay (
      .clk (clk),
      .din ({data_q_in, data_i_in}),
      .dout({data_q_in_d, data_i_in_d})
  );

  // Convert input data into "theta and r" format

  cordic_cart2pol #(
      .DATA_WIDTH          (DATA_WIDTH),
      .ITERATIONS          (Iterations),
      .COMPENSATION_SCALING(1),
      .CTRL_WIDTH          (1)
  ) i_cordic_cart2pol (
      .clk     (clk),
      .rst     (rst),
      //
      .xin     (data_i_in),
      .yin     (data_q_in),
      .ctrl_in (1'b0),
      //
      .theta   (data_theta),
      .r       (data_r),
      .ctrl_out(/* Not used */)
  );

  // Test if amplitude exceeds threshold

  always_ff @(posedge clk) begin
    delta_theta_0 <= data_theta;
    delta_r_0     <= data_r - ctrl_threshold_s;
  end

  always_ff @(posedge clk) begin
    delta_theta <= delta_theta_0;
    if (ctrl_enable_s) begin
      delta_r <= (delta_r_0 >= 0) ? delta_r_0 : 'd0;
    end else begin
      delta_r <= 'd0;
    end
  end

  // Rotate the delta vector back to i & q

  cordic_pol2cart #(
      .DATA_WIDTH          (DATA_WIDTH + 1),
      .ITERATIONS          (Iterations),
      .COMPENSATION_SCALING(1)
  ) i_cordic_pol2cart (
      .clk     (clk),
      .rst     (rst),
      //
      .r       (delta_r[DATA_WIDTH:0]),
      .theta   (delta_theta),
      .ctrl_in (1'b0),
      //
      .xout    (delta_i),
      .yout    (delta_q),
      .ctrl_out(/* Not used */)
  );

  // Output signal is delayed original signal subtract delta

  always_ff @(posedge clk) begin
    data_i_out <= data_i_in_d - delta_i[DATA_WIDTH-1:0];
    data_q_out <= data_q_in_d - delta_q[DATA_WIDTH-1:0];
  end

endmodule

`default_nettype wire
