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

// File: cordic_rotation.sv
// Brief: Rotate input using CORDIC-based approximation
`timescale 1ns / 1ps `default_nettype none

module cordic_rotation #(
    parameter int DATA_WIDTH           = 16,
    parameter int ITERATIONS           = 7,
    parameter int COMPENSATION_SCALING = 1
) (
    input  logic                  clk,
    input  logic                  rst,
    //
    input  logic [DATA_WIDTH-1:0] xin,
    input  logic [DATA_WIDTH-1:0] yin,
    input  logic [  ITERATIONS:0] theta,
    //
    output logic [DATA_WIDTH+1:0] xout,
    output logic [DATA_WIDTH+1:0] yout
);

  // During iteration, x & y need 2 more bits, one for magnitude, one for CORDIC
  // growth factor.
  logic signed [DATA_WIDTH+1:0] x        [ITERATIONS+1];
  logic signed [DATA_WIDTH+1:0] y        [ITERATIONS+1];
  logic        [  ITERATIONS:0] z        [ITERATIONS+1];
  // Rotation direction, 0 = clockwise, 1 = counterclockwise
  logic                         d        [  ITERATIONS];

  // CORDIC iterations output
  logic signed [DATA_WIDTH+1:0] x_cordic;
  logic signed [DATA_WIDTH+1:0] y_cordic;

  // Iteration initialization
  assign x[0] = {xin[DATA_WIDTH-1], xin[DATA_WIDTH-1], xin};
  assign y[0] = {yin[DATA_WIDTH-1], yin[DATA_WIDTH-1], yin};
  assign z[0] = theta;

  // Pseudo rotation iterations
  generate
    for (genvar i = 0; i < ITERATIONS; i++) begin : g_pseudo_rotation

      assign d[i] = z[i][ITERATIONS-i-1];

      always_ff @(posedge clk) begin
        x[i+1] <= d[i] ? (x[i] - (y[i] >>> i)) : (x[i] + (y[i] >>> i));
        y[i+1] <= d[i] ? (y[i] + (x[i] >>> i)) : (y[i] - (x[i] >>> i));
        z[i+1] <= z[i];
      end

    end
  endgenerate

  // CORDIC output
  always_ff @(posedge clk) begin
    x_cordic <= z[ITERATIONS][ITERATIONS] ? -x[ITERATIONS] : x[ITERATIONS];
    y_cordic <= z[ITERATIONS][ITERATIONS] ? -y[ITERATIONS] : y[ITERATIONS];
  end

  // Scale growth compensation
  generate

    if (COMPENSATION_SCALING) begin

      // Compensation is done by r = r * (1/2 + 1/8) * (1 - 1/32)
      logic signed [DATA_WIDTH+1:0] x_compensation[2];
      logic signed [DATA_WIDTH+1:0] y_compensation[2];

      always_ff @(posedge clk) begin
        x_compensation[0] <= (x_cordic >>> 1) + (x_cordic >>> 3);
        x_compensation[1] <= x_compensation[0] - (x_compensation[0] >>> 5);
      end

      always_ff @(posedge clk) begin
        y_compensation[0] <= (y_cordic >>> 1) + (y_cordic >>> 3);
        y_compensation[1] <= y_compensation[0] - (y_compensation[0] >>> 5);
      end

      assign xout = x_compensation[1];
      assign yout = y_compensation[1];

    end else begin

      // No compensation, directly output
      assign xout = x_cordic;
      assign yout = y_cordic;

    end

  endgenerate

endmodule

`default_nettype wire
