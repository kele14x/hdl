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

module cmult #(
    parameter int AWIDTH  = 16,
    parameter int BWIDTH  = 16,
    parameter int PWIDTH  = 16,
    parameter int SRABITS = 15
) (
    input var  logic              clk,
    input var  logic              rst,
    //
    input var  logic [AWIDTH-1:0] ar,
    input var  logic [AWIDTH-1:0] ai,
    //
    input var  logic [BWIDTH-1:0] br,
    input var  logic [BWIDTH-1:0] bi,
    //
    output var logic [PWIDTH-1:0] pr,
    output var logic [PWIDTH-1:0] pi,
    // Overflow indicator
    output var logic              ovf
);


  logic signed [AWIDTH-1:0] ar_d, ar_dd, ar_ddd, ar_dddd;
  logic signed [AWIDTH-1:0] ai_d, ai_dd, ai_ddd, ai_dddd;

  logic signed [BWIDTH-1:0] bi_d, bi_dd, bi_ddd;
  logic signed [BWIDTH-1:0] br_d, br_dd, br_ddd;

  logic signed [AWIDTH:0] addcommon;
  logic signed [BWIDTH:0] addr, addi;
  logic signed [AWIDTH+BWIDTH:0] mult0, multr, multi, pr_int, pi_int;
  logic signed [AWIDTH+BWIDTH:0] common, commonr1, commonr2;

  // Delay taps, tools will automatically absorb registers into DSP and
  // duplicate if needed
  always @(posedge clk) begin
    ar_d     <= ar;
    ar_dd    <= ar_d;
    ar_ddd   <= ar_dd;
    ar_dddd  <= ar_ddd;
    ai_d     <= ai;
    ai_dd    <= ai_d;
    ai_ddd   <= ai_dd;
    ai_dddd  <= ai_ddd;
    br_d     <= br;
    br_dd    <= br_d;
    br_ddd   <= br_dd;
    bi_d     <= bi;
    bi_dd    <= bi_d;
    bi_ddd   <= bi_dd;
    commonr1 <= common;
    commonr2 <= common;
  end

  // DSP1
  // Common factor (ar - ai) * bi, shared for the calculations of the real and
  // imaginary final products
  always_ff @(posedge clk) begin
    addcommon <= ar_d - ai_d;
    mult0     <= addcommon * bi_dd;
    common    <= mult0 + (1 << (SRABITS - 1));
  end

  // DSP2
  // Real product ar * (br - bi) + (ar - ai) * bi = ar * br - ai * bi
  always_ff @(posedge clk) begin
    addr   <= br_ddd - bi_ddd;
    multr  <= addr * ar_dddd;
    pr_int <= multr + commonr1;
  end

  // DSP3
  // Imaginary product ai * (br + bi) + (ar - ai) * bi = ai * br + ar + bi
  always_ff @(posedge clk) begin
    addi   <= br_ddd + bi_ddd;
    multi  <= addi * ai_dddd;
    pi_int <= multi + commonr2;
  end

  always_ff @(posedge clk) begin
    pr <= pr_int[PWIDTH+SRABITS-1:SRABITS];
    pi <= pi_int[PWIDTH+SRABITS-1:SRABITS];
  end

  generate
    if (PWIDTH + SRABITS >= AWIDTH + BWIDTH + 1) begin : g_no_ovf

      // Output is full width, no overflow will happen
      assign ovf = 'b0;

    end else begin : g_ovf

      always_ff @(posedge clk) begin
        ovf <= ^pr_int[AWIDTH+BWIDTH:PWIDTH+SRABITS-1] || 
          ^pi_int[AWIDTH+BWIDTH:PWIDTH+SRABITS-1];
      end

    end
  endgenerate

endmodule

`default_nettype wire
