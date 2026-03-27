/*
 * True Dual Port (TDP) Memory module
 *
 * This module implements a true dual port memory with configurable address and data widths.
 * It supports different write modes and optional output registers for both ports.
 *
 * Read Latency: 1 or 2 (with OUTPUT_REG_A/B) clock cycles
 */

`timescale 1 ns / 1 ps
//
`default_nettype none

module ram_tdp #(
    parameter integer                  ADDR_WIDTH   = 10,
    parameter integer                  DATA_WIDTH   = 32,
    parameter                          WRITE_MODE_A = "READ_FIRST",
    parameter                          WRITE_MODE_B = "READ_FIRST",
    parameter reg                      OUTPUT_REG_A = 1'b1,
    parameter reg                      OUTPUT_REG_B = 1'b1,
    parameter reg     [DATA_WIDTH-1:0] INIT_WORD    = 0,
    parameter                          INIT_FILE    = "",
    parameter                          RAM_STYLE    = "AUTO"
) (
    // Port A
    input  wire                  clka,
    input  wire [OUTPUT_REG_A:0] rsta,
    input  wire [OUTPUT_REG_A:0] ena,
    input  wire                  wea,
    input  wire [ADDR_WIDTH-1:0] addra,
    input  wire [DATA_WIDTH-1:0] dina,
    output reg  [DATA_WIDTH-1:0] douta,
    // Port B
    input  wire                  clkb,
    input  wire [OUTPUT_REG_B:0] rstb,
    input  wire [OUTPUT_REG_B:0] enb,
    input  wire                  web,
    input  wire [ADDR_WIDTH-1:0] addrb,
    input  wire [DATA_WIDTH-1:0] dinb,
    output reg  [DATA_WIDTH-1:0] doutb
);

  // Check parameters

  // verilog_format: off
  initial begin
    if  (WRITE_MODE_A != "WRITE_FIRST" && WRITE_MODE_A != "READ_FIRST" && WRITE_MODE_A != "NO_CHANGE") begin
      $display("Port A write mode (WRITE_MODE_A) should be one of \"WRITE_FIRST\", \"READ_FIRST\", or \"NO_CHANGE\", got \"%s\". [%m]", WRITE_MODE_A);
      $finish();
    end
    if  (WRITE_MODE_B != "WRITE_FIRST" && WRITE_MODE_B != "READ_FIRST" && WRITE_MODE_B != "NO_CHANGE") begin
      $display("Port B write mode (WRITE_MODE_B) should be one of \"WRITE_FIRST\", \"READ_FIRST\", or \"NO_CHANGE\", got \"%s\". [%m]", WRITE_MODE_B);
      $finish();
    end
    if  (RAM_STYLE != "AUTO" && RAM_STYLE != "BLOCK" && RAM_STYLE != "DISTRIBUTED" && RAM_STYLE != "REGISTER" && RAM_STYLE != "ULTRA") begin
      $display("RAM_STYLE should be one of \"AUTO\", \"BLOCK\", \"DISTRIBUTED\", \"REGISTER\", or \"ULTRA\", got \"%s\". [%m]", RAM_STYLE);
      $finish();
    end
  end
  // verilog_format: on

  // Parameters

  localparam integer Size = 2 ** ADDR_WIDTH;

  // The Memory
  (* RAM_STYLE=RAM_STYLE *)
  reg [DATA_WIDTH-1:0] mem[0:Size-1];

  reg [DATA_WIDTH-1:0] rega;
  reg [DATA_WIDTH-1:0] regb;

  integer i;

  // Initialize memory

  initial begin
    for (i = 0; i < Size; i = i + 1) begin
      mem[i] = INIT_WORD;
    end
    if (INIT_FILE != "") begin
      $readmemh(INIT_FILE, mem);
    end
  end

  // Memory port A

  // Port A read
  always @(posedge clka) begin
    if (rsta[0]) begin
      rega <= 0;
    end else if (ena[0]) begin
      if (wea && (WRITE_MODE_A == "WRITE_FIRST")) begin
        rega <= dina;
      end else if (wea && (WRITE_MODE_A == "NO_CHANGE")) begin
        rega <= rega;
      end else begin  // no wea, or write mode is "READ_FIRST"
        rega <= mem[addra];
      end
    end
  end

  // Port A write
  always @(posedge clka) begin
    if (ena[0]) begin
      if (wea) begin
        mem[addra] <= dina;
      end
    end
  end

  // Memory port B

  // Port B read
  always @(posedge clkb) begin
    if (rstb[0]) begin
      regb <= 0;
    end else if (enb[0]) begin
      if ((web == 1'b1) && (WRITE_MODE_B == "WRITE_FIRST")) begin
        regb <= dinb;
      end else if ((web == 1'b1) && (WRITE_MODE_B == "NO_CHANGE")) begin
        regb <= regb;
      end else begin  // no web, or write mode is "READ_FIRST"
        regb <= mem[addrb];
      end
    end
  end

  // Port B write
  always @(posedge clkb) begin
    if (enb[0]) begin
      if (web) begin
        mem[addrb] <= dinb;
      end
    end
  end

  // Optional output pipeline registers

  generate
    if (OUTPUT_REG_A == 0) begin : g_no_reg_a

      always @(*) begin
        douta = rega;
      end

    end else begin : g_reg_a

      always @(posedge clka) begin
        if (rsta[1]) begin
          douta <= 0;
        end else if (ena[1]) begin
          douta <= rega;
        end
      end

    end
  endgenerate

  generate
    if (OUTPUT_REG_B == 0) begin : g_no_reg_b

      always @(*) begin
        doutb = regb;
      end

    end else begin : g_reg_b

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
