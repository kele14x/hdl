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

// File: bram_tdp.sv
// Brief: Simplified True Dual Port Memory. Which means RAM with two ports, and
//        both ports can be used to write and read. However, each port only has
//        one address port, it's used for both read and write. Which means you
//        can't simultaneously do write and read on different address using only
//        one port.

`timescale 1ns / 1ps `default_nettype none

module bram_tdp #(
    parameter int    ADDR_WIDTH     = 10,
    parameter int    DATA_WIDTH     = 32,
    parameter int    USE_OUTPUT_REG = 1,
    parameter int    INIT_WORD      = '0,
    parameter string INIT_FILE      = ""
) (
    // Port A
    input var                   clka,
    input var                   rsta,
    input var                   ena,
    input var                   wea,
    input var  [ADDR_WIDTH-1:0] addra,
    input var  [DATA_WIDTH-1:0] dina,
    output var [DATA_WIDTH-1:0] douta,
    // Port B
    input var                   clkb,
    input var                   rstb,
    input var                   enb,
    input var                   web,
    input var  [ADDR_WIDTH-1:0] addrb,
    input var  [DATA_WIDTH-1:0] dinb,
    output var [DATA_WIDTH-1:0] doutb
);

  logic [DATA_WIDTH-1:0] MEM           [2**ADDR_WIDTH];
  logic [DATA_WIDTH-1:0] ram_data_a = '0;
  logic [DATA_WIDTH-1:0] ram_data_b = '0;


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

  // Memory write

  always_ff @(posedge clka) begin
    if (ena && wea) begin
      MEM[addra] <= dina;
    end
  end

  always_ff @(posedge clkb) begin
    if (enb && web) begin
      MEM[addrb] <= dinb;
    end
  end

  // Port A read

  always_ff @(posedge clka) begin
    if (ena) begin
      ram_data_a <= MEM[addra];
    end
  end

  // Read B read

  always_ff @(posedge clkb) begin
    if (enb) begin
      ram_data_b <= MEM[addrb];
    end
  end

  // Output
  generate
    if (USE_OUTPUT_REG) begin : g_output_reg

      // 2 clock cycle read latency with improve clock-to-out timing

      logic [DATA_WIDTH-1:0] douta_reg = '0;
      logic [DATA_WIDTH-1:0] doutb_reg = '0;
      logic                  ena_d = 1'b0;
      logic                  enb_d = 1'b0;
      logic                  rsta_d = 1'b0;
      logic                  rstb_d = 1'b0;

      always_ff @(posedge clka) begin
        ena_d  <= ena;
        rsta_d <= rsta;
      end

      always_ff @(posedge clkb) begin
        enb_d  <= enb;
        rstb_d <= rstb;
      end

      always_ff @(posedge clka) begin
        if (rsta_d) begin
          douta_reg <= '0;
        end else if (ena_d) begin
          douta_reg <= ram_data_a;
        end
      end

      always_ff @(posedge clkb) begin
        if (rstb_d) begin
          doutb_reg <= '0;
        end else if (enb_d) begin
          doutb_reg <= ram_data_b;
        end
      end

      assign douta = douta_reg;
      assign doutb = doutb_reg;

    end else begin : g_no_output_reg

      // 1 clock cycle read latency

      assign douta = ram_data_a;
      assign doutb = ram_data_b;

    end
  endgenerate

endmodule

`default_nettype wire
