/*
 * Simple Dual Port (SDP) Memory module with asymmetric port width
 *
 * This module implements a simple dual port memory with configurable address and data widths.
 * It has separate read and write ports, allowing simultaneous read and write operations.
 * The module supports an optional output register for improved timing.
 *
 * Read Latency: 1 or 2 (with OUTPUT_REG_B) clock cycles
 *
 * Note: rst[0] does not work here
 */

`timescale 1 ns / 1 ps
//
`default_nettype none

module ram_sdp_asym #(
    parameter integer ADDR_WIDTH_A = 11,
    parameter integer DATA_WIDTH_A = 16,
    //
    parameter integer ADDR_WIDTH_B = 9,
    parameter integer DATA_WIDTH_B = 64,
    parameter reg     OUTPUT_REG_B = 1'b1,
    //
    parameter         INIT_FILE    = "",
    parameter         RAM_STYLE    = "AUTO"
) (
    // Port A, write port
    input  wire                    clka,
    input  wire                    wea,
    input  wire [ADDR_WIDTH_A-1:0] addra,
    input  wire [DATA_WIDTH_A-1:0] dina,
    // Port B, read port
    input  wire                    clkb,
    input  wire [  OUTPUT_REG_B:0] rstb,
    input  wire [  OUTPUT_REG_B:0] enb,
    input  wire [ADDR_WIDTH_B-1:0] addrb,
    output reg  [DATA_WIDTH_B-1:0] doutb
);

  // Check parameters

  // verilog_format: off
  initial begin //
    if  (RAM_STYLE != "AUTO"  &&  RAM_STYLE != "BLOCK"  &&  RAM_STYLE != "DISTRIBUTED" && RAM_STYLE != "REGISTER" && RAM_STYLE != "ULTRA") begin
      $display("RAM_STYLE should be one of \"AUTO\", \"BLOCK\", \"DISTRIBUTED\", \"REGISTER\", or \"ULTRA\", got %s. [%m]", RAM_STYLE);
      $finish();
    end
  end
  // verilog_format: off

  // Parameters

  localparam integer SizeA = 2 ** ADDR_WIDTH_A;
  localparam integer SizeB = 2 ** ADDR_WIDTH_B;

  localparam integer MaxSize = (SizeA > SizeB) ? SizeA : SizeB;

  localparam integer MaxWidth = (DATA_WIDTH_A > DATA_WIDTH_B) ? DATA_WIDTH_A : DATA_WIDTH_B;
  localparam integer MinWidth = (DATA_WIDTH_A < DATA_WIDTH_B) ? DATA_WIDTH_A : DATA_WIDTH_B;

  localparam integer Ratio = MaxWidth / MinWidth;
  localparam integer Log2Ratio = $clog2(Ratio);

  // Signal

  (* RAM_STYLE=RAM_STYLE *)
  reg [MinWidth-1:0] mem[0:MaxSize-1];

  reg [DATA_WIDTH_B-1:0] regb;

  integer i;

  // Initialize memory

  initial begin
    for (i = 0; i < MaxSize; i = i + 1) begin
      mem[i] = 'd0;
    end
    if (INIT_FILE != "") begin
      $readmemh(INIT_FILE, mem, 0, MaxSize-1);
    end
  end

  // Memory port A

  generate
    if (DATA_WIDTH_A <= DATA_WIDTH_B) begin : g_n_wr

      always @(posedge clka) begin
        if (wea) begin
          mem[addra] <= dina;
        end
      end

    end else begin : g_s_wr

      always @(posedge clka) begin : p_wr
        integer i;
        reg [Log2Ratio-1:0] lsbaddr;
        for (i = 0; i < Ratio; i = i + 1) begin
          lsbaddr = i;
          if (wea) begin
            mem[{addra, lsbaddr}] <= dina[(i+1)*MinWidth-1-:MinWidth];
          end
        end
      end

    end
  endgenerate

  // Memory port B

  generate
    if (DATA_WIDTH_B <= DATA_WIDTH_A) begin : g_n_rd

      always @(posedge clkb) begin
        if (rstb[0]) begin
          regb <= 'b0;
        end else if (enb[0]) begin
          regb <= mem[addrb];
        end
      end

    end else begin : g_s_rd

      always @(posedge clkb) begin : p_rd
        integer i;
        reg [Log2Ratio-1:0] lsbaddr;
        // TODO: rst[0] does not work here
        if (enb[0]) begin
          for (i = 0; i < Ratio; i = i + 1) begin
            lsbaddr = i;
            regb[(i+1)*MinWidth-1-:MinWidth] <= mem[{addrb, lsbaddr}];
          end
        end
      end

    end
  endgenerate

  // Additional clock cycle read latency improves clock-to-out timing

  generate
    if (OUTPUT_REG_B == 0) begin : g_no_reg

      always @(*) begin
        doutb = regb;
      end

    end else begin : g_output_reg

      always @(posedge clkb) begin
        if (rstb[1]) begin
          doutb <= 'b0;
        end else if (enb[1]) begin
          doutb <= regb;
        end
      end

    end
  endgenerate

endmodule
