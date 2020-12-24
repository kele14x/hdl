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

// File: cordic_pol2cart.sv
// Brief: CORDIC-based approximation of polar-to-Cartesian conversion
`timescale 1ns / 1ps `default_nettype none

module cordic_pol2cart #(
    parameter int DATA_WIDTH           = 16,
    parameter int ITERATIONS           = 7,
    parameter int COMPENSATION_SCALING = 1
) (
    input var  logic                  clk,
    input var  logic                  rst,
    //
    input var  logic [DATA_WIDTH-1:0] r,
    input var  logic [  ITERATIONS:0] theta,
    //
    output var logic [DATA_WIDTH+1:0] xout,
    output var logic [DATA_WIDTH+1:0] yout
);

  cordic_rotation #(
      .DATA_WIDTH          (DATA_WIDTH),
      .ITERATIONS          (ITERATIONS),
      .COMPENSATION_SCALING(COMPENSATION_SCALING)
  ) i_cordic_rotation (
      .clk  (clk),
      .rst  (rst),
      //
      .xin  (r),
      .yin  ({DATA_WIDTH{1'b0}}),
      .theta(theta),
      //
      .xout (xout),
      .yout (yout)
  );

endmodule

`default_nettype wire
