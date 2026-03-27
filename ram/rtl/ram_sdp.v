/*
 * Simple Dual Port (SDP) Memory module
 *
 * This module implements a simple dual port memory with configurable address and data widths.
 * It has separate read and write ports, allowing simultaneous read and write operations.
 * The module supports an optional output register for improved timing.
 *
 * Read Latency: 1 or 2 (with OUTPUT_REG) clock cycles
 */

`timescale 1 ns / 1 ps
//
`default_nettype none

module ram_sdp #(
    parameter integer                  ADDR_WIDTH = 10,
    parameter integer                  DATA_WIDTH = 32,
    parameter reg                      OUTPUT_REG = 1'b1,
    parameter reg     [DATA_WIDTH-1:0] INIT_WORD  = 'b0,
    parameter                          INIT_FILE  = "",
    parameter                          RAM_STYLE  = "AUTO"
) (
    // Port A, write port
    input  wire                  clka,
    input  wire                  wea,
    input  wire [ADDR_WIDTH-1:0] addra,
    input  wire [DATA_WIDTH-1:0] dina,
    // Port B, read port
    input  wire                  clkb,
    input  wire [  OUTPUT_REG:0] rstb,
    input  wire [  OUTPUT_REG:0] enb,
    input  wire [ADDR_WIDTH-1:0] addrb,
    output reg  [DATA_WIDTH-1:0] doutb
);

  // Check parameters

  // verilog_format: off
  initial begin //
    if  (RAM_STYLE != "AUTO"  &&  RAM_STYLE != "BLOCK"  &&  RAM_STYLE != "DISTRIBUTED" && RAM_STYLE != "REGISTER" && RAM_STYLE != "ULTRA") begin
      $display("RAM_STYLE should be one of \"AUTO\", \"BLOCK\", \"DISTRIBUTED\", \"REGISTER\", or \"ULTRA\", got \"%s\". [%m]", RAM_STYLE);
      $finish();
    end
  end
  // verilog_format: off

  // The Memory
  (* RAM_STYLE=RAM_STYLE *)
  reg [DATA_WIDTH-1:0] mem[0:2**ADDR_WIDTH-1];

  // Port B output pipeline
  reg [DATA_WIDTH-1:0] regb;

  integer i;

  // Initializes the memory values to a specified file or to all zeros to match
  // hardware
  initial begin
    for (i = 0; i < 2 ** ADDR_WIDTH; i = i + 1) begin
      mem[i] = INIT_WORD;
    end
    if (INIT_FILE != "") begin
      $readmemh(INIT_FILE, mem, 0, 2 ** ADDR_WIDTH - 1);
    end
  end

  // Memory read

  always @(posedge clkb) begin
    if (rstb[0]) begin
      regb <= 0;
    end else if (enb[0]) begin
      regb <= mem[addrb];
    end
  end

  // Memory write

  always @(posedge clka) begin
    if (wea) begin
      mem[addra] <= dina;
    end
  end

  // Additional clock cycle read latency improves clock-to-out timing

  generate
    if (OUTPUT_REG == 0) begin : g_no_reg

      always @(*) begin
        doutb = regb;
      end

    end else begin : g_output_reg

      always @(posedge clkb) begin
        if (rstb[1]) begin
          doutb <= 0;
        end else if (enb[1]) begin
          doutb <= regb;
        end
      end

    end
  endgenerate

endmodule

`default_nettype wire
