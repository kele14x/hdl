// File: lfsr.v
// Brief: Linear Feedback Shift Register module.
`timescale 1 ns / 1 ps
//
`default_nettype none

module lfsr #(
    parameter integer                 BIT_WIDTH       = 8,
    parameter reg     [BIT_WIDTH-1:0] INITIAL         = 8'b11111111,
    parameter reg     [BIT_WIDTH-1:0] POLYNOMIALS     = 8'b01101001,
    parameter                         STRUCTURE       = "FIBONACCI",  // "FIBONACCI" or "GALOIS"
    parameter                         GATE_TYPE       = "XOR",        // "XOR" or "XNOR"
    parameter reg                     PARALLEL_OUTPUT = 1'b0
) (
    input  wire                                         clk,
    input  wire                                         rst,
    input  wire                                         en,
    input  wire                                         load,
    input  wire [                        BIT_WIDTH-1:0] din,
    output wire [(PARALLEL_OUTPUT ? BIT_WIDTH : 1)-1:0] dout
);

  // Check parameters
  //=================

  initial begin
    if (!(STRUCTURE == "FIBONACCI" || STRUCTURE == "GALOIS")) begin
      $error("[%m]: LFSR structure (STRUCTURE) should be one of \"FIBONACCI\" or \"GALOIS\".");
      #1 $finish();
    end
    if (!(GATE_TYPE == "XOR" || GATE_TYPE == "XNOR")) begin
      $error("[%m]: Gate type (GATE_TYPE) should be one of \"XOR\" or \"XNOR\".");
      #1 $finish();
    end
    if (!(POLYNOMIALS[0] == 1)) begin
      $error("[%m]: Feedback polynomial (POLYNOMIALS) should have LSB set to 1.");
      #1 $finish();
    end
  end

  reg [BIT_WIDTH-1:0] lfsr_regs;
  reg [BIT_WIDTH-1:0] lfsr_new;


  always @(posedge clk) begin
    if (rst) begin
      lfsr_regs <= INITIAL;
    end else if (en) begin
      if (load) begin
        lfsr_regs <= din;
      end else begin
        lfsr_regs <= lfsr_new;
      end
    end
  end

  generate
    if (STRUCTURE == "FIBONACCI") begin : g_fibonacci

      reg feedback;

      // Pick taps defined by polynomial and XOR (XNOR) them together as feedback
      always @(*) begin
        if (GATE_TYPE == "XOR") begin
          feedback = ^{lfsr_regs & POLYNOMIALS};
        end else begin
          feedback = ~^{lfsr_regs | ~POLYNOMIALS};
        end
      end

      // Shift right with `feedback` input to MSB
      always @(*) begin
        lfsr_new = {feedback, lfsr_regs[BIT_WIDTH-1:1]};
      end

    end else begin : g_galois

      // LSB to taps defined by polynomial
      always @(*) begin
        if (GATE_TYPE == "XOR") begin
          lfsr_new = {
            lfsr_regs[0],
            lfsr_regs[BIT_WIDTH-1:1] ^ (POLYNOMIALS[BIT_WIDTH-1:1] & {(BIT_WIDTH-1){lfsr_regs[0]}})
          };
        end else begin
          lfsr_new = {
            lfsr_regs[0],
            lfsr_regs[BIT_WIDTH-1:1] ~^ (~POLYNOMIALS[BIT_WIDTH-1:1] | {(BIT_WIDTH-1){lfsr_regs[0]}})
          };
        end
      end

    end
  endgenerate

  generate
    if (PARALLEL_OUTPUT) begin : g_parallel_output
      assign dout = lfsr_regs;
    end else begin : g_serial_output
      assign dout = lfsr_regs[0];
    end
  endgenerate

endmodule

`default_nettype wire
