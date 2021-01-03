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

// File: adder.sv
// Brief: Simple adder, usually you does not need this module unless you want a
//        clear hierarchy to help analyzing the synthesis result.

`timescale 1 ns / 1 ps `default_nettype none

module adder #(
    parameter int A_WIDTH  = 16,
    parameter int B_WIDTH  = 16,
    parameter int P_WIDTH  = 17,
    parameter int SRA_BITS = 0
) (
    input var  logic                      clk,
    input var  logic                      rst,
    input var  logic signed [A_WIDTH-1:0] a,
    input var  logic signed [B_WIDTH-1:0] b,
    input var  logic                      add_sub,
    output var logic signed [P_WIDTH-1:0] p,
    output var logic                      ovf
);

  localparam int FULL_WIDTH = (A_WIDTH >= B_WIDTH) ? A_WIDTH + 1 : B_WIDTH + 1;

  logic signed [FULL_WIDTH-1:0] p_s;

  // Full adder without truncate or sign expansion
  assign p_s = add_sub ? a - b : a + b;

  // Sign expansion and truncate
  generate
    if (P_WIDTH + SRA_BITS > FULL_WIDTH) begin : g_sign_exp
      always_ff @(posedge clk) begin
        p <= {{P_WIDTH + SRA_BITS - FULL_WIDTH{p_s[FULL_WIDTH-1]}}, p_s[FULL_WIDTH-1:SRA_BITS]};
      end
    end else begin : g_no_exp
      always_ff @(posedge clk) begin
        p <= p_s[P_WIDTH+SRA_BITS-1:SRA_BITS];
      end
    end
  endgenerate

  // Overflow indicator
  generate
    if (P_WIDTH + SRA_BITS >= FULL_WIDTH) begin : g_no_ovf
      assign ovf = 1'b0;
    end else begin : g_ovf
      always_ff @(posedge clk) begin
        ovf <= ~(&p_s[FULL_WIDTH-1:P_WIDTH+SRA_BITS-1] || &(~p_s[FULL_WIDTH-1:P_WIDTH+SRA_BITS-1]));
      end
    end
  endgenerate

endmodule

`default_nettype wire
