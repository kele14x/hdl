/*
 * Module: dds_lut_rom
 *
 * Description:
 * This module implements a dual-port ROM for Direct Digital Synthesis (DDS)
 * Look-Up Table (LUT). It stores cosine waveform samples and supports different
 * LUT structures (FULL, HALF, QUARTER) and optional rasterization.
 *
 * Parameters:
 * - STRUCTURE:  LUT structure type ("FULL", "HALF", or "QUARTER")
 * - RASTERIZED: Enable rasterized mode (3/4 modulus)
 * - ADDR_WIDTH: Width of address inputs
 * - OUTPUT_REG: Enable output registers
 *
 * Ports:
 * - clk:   Clock input
 * - rsta:  Reset input for port A
 * - ena:   Enable input for port A
 * - addra: Address input for port A
 * - douta: Data output for port A
 * - rstb:  Reset input for port B
 * - enb:   Enable input for port B
 * - addrb: Address input for port B
 * - doutb: Data output for port B
 *
 * The ROM is initialized with pre-calculated cosine values from external
 * memory files, supporting various sizes based on address width and structure.
 */

`timescale 1 ns / 1 ps
//
`default_nettype none
//
(* KEEP_HIERARCHY="yes" *)
module dds_lut_rom #(
    parameter [8*7-1:0] STRUCTURE  = "FULL",
    parameter           RASTERIZED = 1'b0,
    parameter           ADDR_WIDTH = 12,
    parameter           DATA_WIDTH = 16,
    parameter           OUTPUT_REG = 1'b1
) (
    input  wire                        clk,
    //
    input  wire                        rsta,
    input  wire                        ena,
    input  wire       [ADDR_WIDTH-1:0] addra,
    output reg signed [DATA_WIDTH-1:0] douta,
    //
    input  wire                        rstb,
    input  wire                        enb,
    input  wire       [ADDR_WIDTH-1:0] addrb,
    output reg signed [DATA_WIDTH-1:0] doutb
);

  // Local parameters

  localparam [8*7-1:0] StructureFull = "FULL";
  localparam [8*7-1:0] StructureHalf = "HALF";

  localparam Factor = STRUCTURE == StructureFull ? 1 : (STRUCTURE == StructureHalf ? 2 : 4);
  localparam K = (RASTERIZED ? 3 : 4) * (2 ** ADDR_WIDTH) / 4;

  // Signals

  // The Memory
  reg signed [DATA_WIDTH-1:0] mem     [0:K-1];

  reg signed [DATA_WIDTH-1:0] douta_s;
  reg signed [DATA_WIDTH-1:0] doutb_s;

  initial begin : p_init
    integer i;
    for (i = 0; i < K; i = i + 1) begin
      mem[i] = DATA_WIDTH'($rtoi((2 ** (DATA_WIDTH - 1) - 2) * $cos(3.141592653589793 * 2 * i / Factor / K)));
    end
  end

  // Memory port A

  always @(posedge clk) begin
    if (rsta) begin
      douta_s <= '0;
    end else if (ena) begin
      douta_s <= mem[addra];
    end
  end

  // Memory port B

  always @(posedge clk) begin
    if (rstb) begin
      doutb_s <= '0;
    end else if (enb) begin
      doutb_s <= mem[addrb];
    end
  end

  generate
    if (OUTPUT_REG == 0) begin : g_no_reg

      always @(*) begin
        douta = douta_s;
      end

      always @(*) begin
        doutb = doutb_s;
      end

    end else begin : g_reg

      reg ena_d;
      reg enb_d;

      always @(posedge clk) begin
        ena_d <= ena;
        enb_d <= enb;
      end

      always @(posedge clk) begin
        if (rsta) begin
          douta <= '0;
        end else if (ena_d) begin
          douta <= douta_s;
        end
      end

      always @(posedge clk) begin
        if (rstb) begin
          doutb <= '0;
        end else if (enb_d) begin
          doutb <= doutb_s;
        end
      end

    end
  endgenerate

endmodule

`default_nettype wire
