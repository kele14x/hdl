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

// File: pc_cfr_pd.sv
// Brief: pc_cfr_pd Peak Detector for `pc_cfr` module

`timescale 1ns / 1ps `default_nettype none

module pc_cfr_pd #(
    parameter int ITERATIONS = 7,
    parameter int DATA_WIDTH = 16
) (
    input var  logic                clk,
    input var  logic                rst,
    //
    input var  logic [DATA_WIDTH:0] data_r_p0,
    input var  logic [DATA_WIDTH:0] data_r_p1,
    input var  logic [ITERATIONS:0] data_theta_p0,
    input var  logic [ITERATIONS:0] data_theta_p1,
    //
    output var logic [DATA_WIDTH:0] peak_r,
    output var logic [ITERATIONS:0] peak_theta,
    output var logic                peak_phase,
    output var logic                peak_valid,
    //
    input var  logic                ctrl_enable,
    input var  logic [DATA_WIDTH:0] ctrl_pd_threshold,
    input var  logic [DATA_WIDTH:0] ctrl_clipping_threshold
);

  enum logic {
    S_NEG,
    S_POS
  } state_det;

  logic [DATA_WIDTH:0] state_max;
  logic [ITERATIONS:0] state_theta;
  logic state_phase;

  logic g1, g2, g3;

  logic [DATA_WIDTH:0] peak_r_pre;
  logic [ITERATIONS:0] peak_theta_pre;
  logic                peak_phase_pre;
  logic                peak_valid_pre;

  logic                peak_lt_threshold;

  assign g1 = data_r_p0 >= state_max;
  assign g2 = data_r_p1 >= state_max;
  assign g3 = data_r_p1 >= data_r_p0;

  always_ff @(posedge clk) begin
    if (rst) begin
      state_det <= S_NEG;
    end else begin
      case (state_det)
        S_POS:   state_det <= (g1 || g2) ? S_POS : S_NEG;
        S_NEG:   state_det <= (g1 || g2) ? S_POS : S_NEG;
        default: state_det <= S_NEG;
      endcase
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      state_max <= 'd0;
    end else begin
      state_max <= g3 ? data_r_p1 : data_r_p0;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      state_phase <= 'd0;
    end else begin
      state_phase <= g3 ? 1'b1 : 1'b0;
    end
  end


  always_ff @(posedge clk) begin
    if (rst) begin
      state_theta <= 'd0;
    end else begin
      state_theta <= g3 ? data_theta_p1 : data_theta_p0;
    end
  end

  always_ff @(posedge clk) begin
    peak_valid_pre <= (state_det == S_POS) && ~(g1 || g2);
  end

  always_ff @(posedge clk) begin
    if ((state_det == S_POS) && ~(g1 || g2)) begin
      peak_r_pre     <= state_max;
      peak_phase_pre <= state_phase;
      peak_theta_pre <= state_theta;
    end else begin
      peak_r_pre     <= 'd0;
      peak_phase_pre <= 1'b0;
      peak_theta_pre <= 'd0;
    end
  end

  assign peak_lt_threshold = (peak_valid_pre && peak_r_pre > ctrl_pd_threshold);

  always_ff @(posedge clk) begin
    peak_valid <= peak_lt_threshold ? 1'b1 : 1'b0;
    peak_r     <= peak_lt_threshold ? (peak_r_pre - ctrl_clipping_threshold) : 'd0;
    peak_phase <= peak_lt_threshold ? peak_phase_pre : 'd0;
    peak_theta <= peak_lt_threshold ? peak_theta_pre : 'd0;
  end

endmodule

`default_nettype wire
