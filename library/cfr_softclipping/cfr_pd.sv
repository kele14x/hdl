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

module cfr_pd #(
    parameter int ITERATIONS = 7,
    parameter int DATA_WIDTH = 16
) (
    input var  logic                  clk,
    input var  logic                  rst,
    //
    input var  logic [  DATA_WIDTH:0] data_r_p0,
    input var  logic [  DATA_WIDTH:0] data_r_p1,
    input var  logic [  ITERATIONS:0] data_theta_p0,
    input var  logic [  ITERATIONS:0] data_theta_p1,
    //
    output var logic [  DATA_WIDTH:0] peak_r,
    output var logic [  ITERATIONS:0] peak_theta,
    output var logic                  peak_phase,
    output var logic                  peak_valid,
    //
    input var  logic                  ctrl_enable,
    input var  logic [  DATA_WIDTH:0] ctrl_pd_threshold,
    input var  logic [  DATA_WIDTH:0] ctrl_clipping_threshold
);

  enum {S_POS, S_NEG} state1_det, state2_det;

  logic [DATA_WIDTH:0] state1_max, state2_max;
  logic [ITERATIONS:0] state1_theta, state2_theta;
  logic state1_phase, state2_phase;

  logic l1, l2, l3;

  assign l1 = data_r_p0 >= state1_max;
  assign l2 = data_r_p1 >= state1_max;
  assign l3 = data_r_p1 >= data_r_p0;

  always_ff @(posedge clk) begin
    if (rst) begin
      state1_det <= S_NEG;
      state2_det <= S_NEG;
    end else begin
      state1_det <= state2_det;
      case(state1_det) 
        S_POS : state2_det <= (l1 || l2) ? S_POS : S_NEG;
        S_NEG : state2_det <= (l1 || l2) ? S_POS : S_NEG;
        default: state2_det <= S_NEG;
      endcase
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      state1_max <= 'd0;
      state2_max <= 'd0;
    end else begin
      state1_max <= state2_max;
      state2_max <= l3 ? data_r_p1 : data_r_p0;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      state1_phase <= 'd0;
      state2_phase <= 'd0;
    end else begin
      state1_phase <= state2_phase;
      state2_phase <= l3 ? 1'b1 : 1'b0;
    end
  end


  always_ff @(posedge clk) begin
    if (rst) begin
      state1_theta <= 'd0;
      state2_theta <= 'd0;
    end else begin
      state1_theta <= state2_theta;
      state2_theta <= l3 ? data_theta_p1: data_theta_p0;
    end
  end

  always_ff @(posedge clk) begin
    peak_valid <= (state1_det == S_POS) && ~(l1 || l2);
  end

  always_ff @(posedge clk) begin
    if ((state1_det == S_POS) && ~(l1 || l2)) begin
      peak_r     <= state1_max;
      peak_phase <= state1_phase;
      peak_theta <= state1_theta;
    end else begin
      peak_r     <= 'd0;
      peak_phase <= 1'b0;
      peak_theta <= 'd0;
    end
  end

endmodule

`default_nettype wire
