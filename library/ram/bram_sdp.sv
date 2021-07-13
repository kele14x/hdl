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

// File: bram_sdp.sv
// Brief: Simplified abstract simple dual port (SDP) memory.

`timescale 1ns / 1ps `default_nettype none

module bram_sdp #(
    parameter int    ADDR_WIDTH     = 10,
    parameter int    DATA_WIDTH     = 32,
    parameter int    READ_LATENCY   = 3,  // 1 ~ 3
    parameter int    INIT_WORD      = '0,
    parameter string INIT_FILE      = ""
) (
    // Port A, write port
    input var                     clka,
    input var                     ena,
    input var  [DATA_WIDTH/8-1:0] wea,
    input var  [  ADDR_WIDTH-1:0] addra,
    input var  [  DATA_WIDTH-1:0] dina,
    // Port B, read port
    input var                     clkb,
    input var                     enb  [READ_LATENCY],
    input var                     rstb [READ_LATENCY],
    input var  [  ADDR_WIDTH-1:0] addrb,
    output var [  DATA_WIDTH-1:0] doutb
);


  // The Memory
  logic [DATA_WIDTH-1:0] MEM      [2**ADDR_WIDTH];
  
  // Port B output pipeline
  logic [DATA_WIDTH-1:0] regb [READ_LATENCY]= '{READ_LATENCY{'0}};


  initial begin
    assert(1 <= READ_LATENCY && READ_LATENCY <= 3)
    else $error("READ_LATENCY should be within range 1 to 3.");
  end

  // Initializes the memory values to a specified file or to all zeros to match
  // hardware
  
  initial begin
    for (int i = 0; i < 2 ** ADDR_WIDTH; i = i + 1) begin
      MEM[i] = INIT_WORD;
    end
    if (INIT_FILE != "") begin : g_file_init
      $readmemh(INIT_FILE, MEM, 0, 2 ** ADDR_WIDTH - 1);
    end
  end

  // Write process
  
  always_ff @(posedge clka) begin
    if (ena) begin
      for (int i = 0; i < DATA_WIDTH/8; i++) begin
        if (wea[i]) begin
          MEM[addra][i*8+7-:8] <= dina[i*8+7-:8];
        end
      end
    end
  end

  // Read process
  
  // LATCH stage
  always_ff @(posedge clkb) begin
    if (rstb[0]) begin
      regb[0] <= '0;
    end else if (enb[0]) begin
      regb[0] <= MEM[addrb];
    end
  end

  // Additional clock cycle read latency improves clock-to-out timing
  generate
    for (genvar i = 1; i < READ_LATENCY; i++) begin : g_output_reg

      always_ff @(posedge clkb) begin
        if (rstb[i]) begin
          regb[i] <= '0;
        end else if (enb[i]) begin
          regb[i] <= regb[i-1];
        end
      end

    end
  endgenerate

  assign doutb = regb[READ_LATENCY-1];

endmodule

`default_nettype wire
