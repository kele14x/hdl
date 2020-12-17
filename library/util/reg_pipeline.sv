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

// File: reg_pipeline.sv
// Brief: Register pipeline to delay a signal for specific number of clocks

`timescale 1 ns / 1 ps `default_nettype none

module reg_pipeline #(
    parameter int DATA_WIDTH      = 8,
    parameter int PIPELINE_STAGES = 8
) (
    input var  logic                  clk,
    input var  logic [DATA_WIDTH-1:0] din,
    output var logic [DATA_WIDTH-1:0] dout
);

  generate
    if (PIPELINE_STAGES == 0) begin : g_no_pipeline

      assign dout = din;

    end else begin : g_reg_pipeline

      logic [DATA_WIDTH-1:0] din_srl[PIPELINE_STAGES];

      always_ff @(posedge clk) begin
        din_srl[0] <= din;
        for (int i = 1; i < PIPELINE_STAGES; i++) begin
          din_srl[i] <= din_srl[i-1];
        end
      end

      assign dout = din_srl[PIPELINE_STAGES-1];

    end

  endgenerate

endmodule
