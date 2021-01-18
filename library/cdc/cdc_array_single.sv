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

// File: cdc_array_single.sv
// Brief: Simple array CDC, each bit is treat as separate and has no constrained
//        relationship.

`timescale 1 ns / 1 ps `default_nettype none

module cdc_array_single #(
  parameter int DEST_SYNC_FF  = 2,
  parameter int INIT_SYNC_FF  = 0,
  parameter int SRC_INPUT_REG = 1,
  parameter int WIDTH         = 1
) (
  input  var             src_clk ,
  input  var [WIDTH-1:0] src_in  ,
  input  var             dest_clk,
  output var [WIDTH-1:0] dest_out
);

  initial begin : drc_check

    if ((DEST_SYNC_FF < 2) || (DEST_SYNC_FF > 10)) begin
      $error("[%m]: DEST_SYNC_FF (%0d) is outside of valid range of 2-10. %m", DEST_SYNC_FF);
    end

    if (!(INIT_SYNC_FF==0) && !(INIT_SYNC_FF==1)) begin
      $error("[%m]: INIT_SYNC_FF (%0d) is outside of valid range. %m", INIT_SYNC_FF);
    end

    if (!(SRC_INPUT_REG == 0) && !(SRC_INPUT_REG == 1)) begin
      $error("[%m]: SRC_INPUT_REG (%0d) value is outside of valid range. %m", SRC_INPUT_REG);
    end

    if ((WIDTH < 1) || (WIDTH > 1024)) begin
      $error("[%m]: WIDTH (%0d) is outside of valid range of 1-1024. %m", WIDTH);
    end

  end


  logic [WIDTH-1:0] src_ff;

  (* ASYNC_REG = "TRUE" *) logic  [WIDTH-1:0] sync_ff [DEST_SYNC_FF];


  generate

    if (SRC_INPUT_REG) begin : src_input_reg

      initial begin
        if (INIT_SYNC_FF) begin
          src_ff = '0;
        end
      end

      always_ff @ (posedge src_clk) begin
        src_ff <= src_in;
      end

    end else begin : no_input_reg

      assign src_ff = src_in;

    end

  endgenerate

  initial begin
    if (INIT_SYNC_FF) begin
      for (int i = 0; i < DEST_SYNC_FF; i++) begin
        sync_ff[i] = '0;
      end
    end
  end

  always @(posedge dest_clk) begin
    sync_ff[0] <= src_ff;
    for (int i = 1; i < DEST_SYNC_FF; i++) begin
      sync_ff[i] <= sync_ff[i-1];
    end
  end

  assign dest_out = sync_ff[DEST_SYNC_FF-1];

endmodule

`default_nettype wire
