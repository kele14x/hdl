/*
 * Single Port (SP) Memory module
 *
 * This module implements a single port memory with configurable address and data widths.
 * It supports different write modes and optional output register.
 *
 * Read Latency: 1 or 2 (with OUTPUT_REG) clock cycles
 */

`timescale 1 ns / 1 ps
//
`default_nettype none

module ram_sp #(
    parameter integer                  ADDR_WIDTH = 10,
    parameter integer                  DATA_WIDTH = 32,
    parameter                          WRITE_MODE = "READ_FIRST",
    parameter reg                      OUTPUT_REG = 1,
    parameter reg     [DATA_WIDTH-1:0] INIT_WORD  = 'b0,
    parameter                          INIT_FILE  = "",
    parameter                          RAM_STYLE  = "AUTO"
) (
    input  wire                  clk,
    input  wire [  OUTPUT_REG:0] rst,
    //
    input  wire [  OUTPUT_REG:0] en,
    input  wire                  we,
    input  wire [ADDR_WIDTH-1:0] addr,
    input  wire [DATA_WIDTH-1:0] din,
    output reg  [DATA_WIDTH-1:0] dout
);

  // Check parameters

  // verilog_format: off
  initial begin
    if (WRITE_MODE != "WRITE_FIRST" && WRITE_MODE != "READ_FIRST" && WRITE_MODE != "NO_CHANGE") begin
      $display("Write mode (WRITE_MODE) should be one of \"WRITE_FIRST\", \"READ_FIRST\" and \"NO_CHANGE\", got \"%s\". [%m]", WRITE_MODE);
      $finish();
    end
    if  (RAM_STYLE != "AUTO"  &&  RAM_STYLE != "BLOCK"  &&  RAM_STYLE != "DISTRIBUTED" && RAM_STYLE != "REGISTER" && RAM_STYLE != "ULTRA") begin
      $display("RAM_STYLE should be one of \"AUTO\", \"BLOCK\", \"DISTRIBUTED\", \"REGISTER\", or \"ULTRA\", got \"%s\". [%m]", RAM_STYLE);
      $finish();
    end
  end
  // verilog_format: on

  // Parameters

  localparam integer Size = 2 ** ADDR_WIDTH;

  // Signals

  // The Memory
  (* RAM_STYLE=RAM_STYLE *)
  reg [DATA_WIDTH-1:0] mem[0:Size-1];

  reg [DATA_WIDTH-1:0] rega;

  integer i;

  // Initializes the memory values to a specified file or to all zeros to match
  // hardware
  initial begin
    for (i = 0; i < Size; i = i + 1) begin
      mem[i] = INIT_WORD;
    end
    if (INIT_FILE != "") begin
      $readmemh(INIT_FILE, mem, 0, Size - 1);
    end
  end

  // Memory read

  always @(posedge clk) begin
    if (rst[0]) begin
      rega <= 0;
    end else if (en[0]) begin
      if ((we == 1'b1) && (WRITE_MODE == "WRITE_FIRST")) begin
        rega <= din;
      end else if ((we == 1'b1) && (WRITE_MODE == "NO_CHANGE")) begin
        rega <= rega;
      end else begin  // no we, or write mode is "READ_FIRST"
        rega <= mem[addr];
      end
    end
  end

  // Memory write

  always @(posedge clk) begin
    if (en[0] && we) begin
      mem[addr] <= din;
    end
  end

  // Additional clock cycle read latency improves clock-to-out timing
  generate
    if (OUTPUT_REG == 0) begin : g_no_reg

      always @(*) begin
        dout = rega;
      end

    end else begin : g_reg

      always @(posedge clk) begin
        if (rst[1]) begin
          dout <= 0;
        end else if (en[1]) begin
          dout <= rega;
        end
      end

    end
  endgenerate

endmodule

`default_nettype wire
