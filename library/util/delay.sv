// File: delay.sv
// Brief: Delay input for specified clock ticks. The delay line could be
//        implement using either registers, SRL primitive or RAM-Based shifter.
//        This module could select optimized structure based on data width and
//        depth, or you can choose desired structure manually.
`timescale 1 ns / 1 ps
//
`default_nettype none

module delay #(
    parameter int    DELAY      = 8,
    parameter string STRUCTURE  = "AUTO",
    parameter int    DATA_WIDTH = 8
) (
    input var  logic                  clk,
    input var  logic                  rst,
    input var  logic [DATA_WIDTH-1:0] din,
    output var logic [DATA_WIDTH-1:0] dout
);

  // Local parameters
  //=================

  localparam int SRL_RAM_THRESHOLD = 1026;


  // Check parameters
  //=================

  initial begin
      // Check STRUCTURE
      assert(STRUCTURE == "AUTO" || STRUCTURE == "REGISTERS" ||
        STRUCTURE == "SRL" || STRUCTURE == "RAM")
      else begin
        $error("[%m]: Delay implement structure (STRUCTURE) should be one of \"AUTO\", \"REGISTERS\", \"SRL\" or \"RAM\".");
        #1 $finish();
      end
      // Check DELAY
      assert(0<= DELAY && DELAY <= 16384)
      else begin
        $error("[%m]: Delay depth (DELAY) must be within the range 0 to 16384.");
        #1 $finish();
      end
  end


  // Main
  //=====

  generate
    if (DELAY == 0) begin : g_no_delay

      assign dout = din;

    end else if (DELAY <= SRL_RAM_THRESHOLD || STRUCTURE == "REGISTERS" || STRUCTURE == "SRL") begin : g_srl

      shift_regs #(
          .DATA_WIDTH(DATA_WIDTH),
          .DEPTH     (DELAY)
      ) i_shitf_regs (
          .clk (clk),
          .din (din),
          .dout(dout)
      );

    end else if (DELAY > SRL_RAM_THRESHOLD || STRUCTURE == "RAM") begin : g_shift_ram

      shift_ram #(
          .DATA_WIDTH(DATA_WIDTH),
          .DEPTH     (DELAY)
      ) i_shift_ram (
          .clk (clk),
          .rst (rst),
          .din (din),
          .dout(dout)
      );

    end
  endgenerate

endmodule

`default_nettype wire
