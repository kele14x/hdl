// File: shift_regs.v
// Brief: Shift registers to delay a signal for specific number of clocks. It
//        let synthesizer select result automatically.
`timescale 1 ns / 1 ps
//
`default_nettype none

module shift_regs #(
    parameter         SIM_INIT   = 1,
    parameter integer DATA_WIDTH = 8,
    parameter integer DEPTH      = 8
) (
    input  wire                  clk,
    input  wire [DATA_WIDTH-1:0] din,
    output wire [DATA_WIDTH-1:0] dout
);

  generate
    if (DEPTH == 0) begin : g_zero_depth

      assign dout = din;

    end else begin : g_regs

      reg [DATA_WIDTH-1:0] dregs[0:DEPTH-1];

      initial begin : p_init
        integer i;
        if (SIM_INIT) begin
          for (i = 0; i < DEPTH; i = i + 1) begin
            dregs[i] <= 'd0;
          end
        end
      end

      always @(posedge clk) begin : p_shift
        integer i;
        dregs[0] <= din;
        for (i = 1; i < DEPTH; i = i + 1) begin
          dregs[i] <= dregs[i-1];
        end
      end

      assign dout = dregs[DEPTH-1];

    end
  endgenerate

endmodule

`default_nettype wire
