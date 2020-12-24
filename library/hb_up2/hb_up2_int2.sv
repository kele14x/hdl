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

// File: hb_up2.sv
// Brief: Half band up-sample by 2. Interleaved 2 channels.
`timescale 1ns / 1ps `default_nettype none

module hb_up2_int2 #(
    parameter int XIN_WIDTH = 16,
    parameter int COE_WIDTH = 16,
    parameter int NUM_UNIQUE_COE = 5,
    parameter signed [COE_WIDTH-1:0] COE_NUMS[NUM_UNIQUE_COE] = {
      16'h01dc, 16'hfcdb, 16'h0609, 16'hf3c6, 16'h2847
    },
    parameter int YOUT_WIDTH = 16,
    parameter int SRA_BITS = 15
) (
    input var  logic                  clk,
    input var  logic                  rst,
    input var  logic [ XIN_WIDTH-1:0] xin,
    output var logic [YOUT_WIDTH-1:0] yout0,
    output var logic [YOUT_WIDTH-1:0] yout1,
    output var logic                  ovf
);

  localparam int RND = (1 <<< (SRA_BITS - 1));

  logic signed [        XIN_WIDTH-1:0] xin_d[NUM_UNIQUE_COE*4];

  logic signed [          XIN_WIDTH:0] adreg[NUM_UNIQUE_COE];
  logic signed [XIN_WIDTH+COE_WIDTH:0] mreg [NUM_UNIQUE_COE];
  logic signed [XIN_WIDTH+COE_WIDTH:0] preg [NUM_UNIQUE_COE];

  // Delay taps, tools can automatically absorb registers into DSP and duplicate
  // registers if needed

  always_ff @(posedge clk) begin
    xin_d[0] <= xin;
    for (int i = 1; i < NUM_UNIQUE_COE*4; i++) begin
      xin_d[i] <= xin_d[i-1];
    end
  end

  generate
    for (genvar i = 0; i < NUM_UNIQUE_COE; i++) begin : g_dsp

      always_ff @(posedge clk) begin
        adreg[i] <= xin_d[i+1] + xin_d[-3*i+NUM_UNIQUE_COE*4-1];
        mreg[i]  <= adreg[i] * COE_NUMS[i];
        preg[i]  <= mreg[i] + ((i < NUM_UNIQUE_COE - 1) ? preg[i+1] : RND);
      end

    end
  endgenerate

  always_ff @ (posedge clk) begin
    yout0 <= xin_d[14];
    yout1 <= preg[0][YOUT_WIDTH+SRA_BITS-1:SRA_BITS];
  end

  generate
    if (YOUT_WIDTH + SRA_BITS >= XIN_WIDTH + COE_WIDTH + 1) begin : g_no_ovf

      // Output is full width, no overflow will happen
      assign ovf = 'b0;

    end else begin : g_ovf

      always_ff @(posedge clk) begin
        ovf <= ~(&preg[0][XIN_WIDTH+COE_WIDTH:YOUT_WIDTH+SRA_BITS-1] ||
                 &(~preg[0][XIN_WIDTH+COE_WIDTH:YOUT_WIDTH+SRA_BITS-1]));
      end

    end
  endgenerate


endmodule

`default_nettype wire
