// File: shift_ram.v
// Brief: Shift (delay) input for specified clock ticks. The delay line could be
//        implement using either registers, SRL primitive or RAM-Based shifter.
//        This module could select optimized structure based on data width and
//        depth, or you can choose desired structure manually.
`timescale 1 ns / 1 ps
//
`default_nettype none

module shift_ram #(
    parameter integer DEPTH      = 8,
    parameter string  STRUCTURE  = "AUTO",
    parameter integer DATA_WIDTH = 8
) (
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  cen,
    //
    input  wire [DATA_WIDTH-1:0] din,
    output wire [DATA_WIDTH-1:0] dout
);

  // Local parameters
  //=================

  localparam integer SRL_RAM_THRESHOLD = 1026;


  // Check parameters
  //=================

  initial begin
    // Check STRUCTURE
    if (!(STRUCTURE == "AUTO" || STRUCTURE == "REGISTERS" ||
        STRUCTURE == "SRL" || STRUCTURE == "RAM")) begin
      $error(
          "[%m]: Implement structure (STRUCTURE) should be one of \"AUTO\", \"REGISTERS\", \"SRL\" or \"RAM\".");
      #1 $finish();
    end
    // Check DEPTH
    if (!(0 <= DEPTH && DEPTH <= 16384)) begin
      $error("[%m]: Delay depth (DEPTH) must be within the range 0 to 16384.");
      #1 $finish();
    end
  end


  // Main
  //=====

  generate
    if (DEPTH == 0) begin : g_no_DEPTH

      assign dout = din;

    end else if (DEPTH <= SRL_RAM_THRESHOLD || STRUCTURE == "REGISTERS" || STRUCTURE == "SRL") begin : g_srl

      shift_regs #(
          .DATA_WIDTH(DATA_WIDTH),
          .DEPTH     (DEPTH)
      ) i_shift_regs (
          .clk (clk),
          .cen (cen),
          .din (din),
          .dout(dout)
      );

    end else if (DEPTH > SRL_RAM_THRESHOLD || STRUCTURE == "RAM") begin : g_shift_ram

      shift_ram_ram #(
          .DATA_WIDTH(DATA_WIDTH),
          .DEPTH     (DEPTH)
      ) i_shift_ram (
          .clk (clk),
          .rst (rst),
          .cen (cen),
          .din (din),
          .dout(dout)
      );

    end
  endgenerate

endmodule

`default_nettype wire
