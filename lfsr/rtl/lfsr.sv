// File: lfsr.v
// Brief: LFSR implements a Linear Feedback Shift Register module (LFSR).
//
//        Features:
//
//          - Supports both the Fibonacci and Galois structure
//          - Using either the XOR or XNOR gate type
//          - Reload from input
//          - Configured as either serial or parallel output
//
//        For 4-bit LFSR with polynomial x^4 + x^1 + 1
//
//          - Fibonacci LFSR:
//
//          +----------------------------------XOR---------+
//          |                                   |          |
//          |  +-----+     +-----+     +-----+  |  +-----+ |
//          |  |     |     |     |     |     |  |  |     | |
//          +-->  3  +----->  2  +----->  1  +--+-->  0  +-+----->
//             |     |     |     |     |     |     |     |    s(n)
//             +-----+     +-----+     +-----+     +-----+
//
//          - Galois LFSR:
//
//             +-----+     +-----+     +-----+     +-----+
//             |     |     |     |     |     |     |     |
//          +-->  3  +----->  2  +----->  1  +-XOR->  0  +-+----->
//          |  |     |     |     |     |     |  ^  |     | |  s(n)
//          |  +-----+     +-----+     +-----+  |  +-----+ |
//          |                                   |          |
//          +-----------------------------------+----------+
//
//
`timescale 1 ns / 1 ps
//
`default_nettype none

module lfsr #(
    parameter int                    BIT_WIDTH       = 8,
    parameter bit    [BIT_WIDTH-1:0] INITIAL         = 8'b11111111,
    parameter bit    [  BIT_WIDTH:0] POLYNOMIAL      = {{(BIT_WIDTH-8){1'b0}}, 9'b100000011},
    parameter string                 STRUCTURE       = "FIBONACCI",  // "FIBONACCI" or "GALOIS"
    parameter string                 GATE_TYPE       = "XOR",        // "XOR" or "XNOR"
    parameter bit                    PARALLEL_OUTPUT = 1'b0
) (
    input var                                          clk,
    input var                                          rst,
    input var                                          en,
    input var                                          load,
    input var  [                        BIT_WIDTH-1:0] din,
    output var [(PARALLEL_OUTPUT ? BIT_WIDTH : 1)-1:0] dout
);

  // Check parameters
  //=================

  initial begin
    assert(STRUCTURE == "FIBONACCI" || STRUCTURE == "GALOIS")
    else begin
      $fatal(1, "[%m]: LFSR structure (STRUCTURE) should be one of \"FIBONACCI\" or \"GALOIS\".");
    end

    assert(GATE_TYPE == "XOR" || GATE_TYPE == "XNOR")
    else begin
      $fatal(1, "[%m]: Gate type (GATE_TYPE) should be one of \"XOR\" or \"XNOR\".");
    end

    assert(POLYNOMIAL[0] == 1'b1 && POLYNOMIAL[BIT_WIDTH] == 1'b1)
    else begin
      $fatal(1, "[%m]: Feedback polynomial (POLYNOMIAL) should have MSB & LSB both set to 1.");
    end
  end


  // Signals
  //========

  logic [BIT_WIDTH-1:0] lfsr_regs;
  logic [BIT_WIDTH-1:0] lfsr_new;


  // Main
  //=====

  always_ff @(posedge clk) begin
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

  // Both Fibonacci and Galois LFSR are designed as shift right with feedback
  // input to MSB.
  // Fibonacci XOR (XNOR) output of some taps as the only feedback to MSB.
  // Galois directly use LSB as feedback, but send it to many taps

  generate
    if (STRUCTURE == "FIBONACCI") begin : g_fibonacci

      reg feedback;

      // Pick taps defined by polynomial and XOR (XNOR) them together as feedback
      always_comb begin
        if (GATE_TYPE == "XOR") begin
          feedback = ^{lfsr_regs & POLYNOMIAL[BIT_WIDTH-1:0]};
        end else begin
          feedback = ~^{lfsr_regs | ~POLYNOMIAL[BIT_WIDTH-1:0]};
        end
      end

      // Shift right with `feedback` input to MSB
      always_comb begin
        lfsr_new = {feedback, lfsr_regs[BIT_WIDTH-1:1]};
      end

    end else begin : g_galois

      // LSB feedback to taps defined by polynomial, then shift by 1
      always_comb begin
        if (GATE_TYPE == "XOR") begin
          lfsr_new = {
            lfsr_regs[0],
            lfsr_regs[BIT_WIDTH-1:1] ^ (POLYNOMIAL[BIT_WIDTH-1:1] & {(BIT_WIDTH-1){lfsr_regs[0]}})
          };
        end else begin
          lfsr_new = {
            lfsr_regs[0],
            lfsr_regs[BIT_WIDTH-1:1] ~^ (~POLYNOMIAL[BIT_WIDTH-1:1] | {(BIT_WIDTH-1){lfsr_regs[0]}})
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
