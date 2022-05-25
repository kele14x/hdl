// File: shift_regs.sv
// Brief: Shift registers to delay a signal for specific number of clocks. It
//        let synthesizer select result automatically.
`timescale 1 ns / 1 ps
//
`default_nettype none

module shift_regs #(
    parameter int DATA_WIDTH = 8,
    parameter int DEPTH      = 8
) (
    input var  logic                  clk,
    input var  logic [DATA_WIDTH-1:0] din,
    output var logic [DATA_WIDTH-1:0] dout
);

  generate
    if (DEPTH == 0) begin : g_zero_depth

      assign dout = din;

    end else begin : g_regs

      logic [DATA_WIDTH-1:0] dregs[DEPTH];

      always_ff @(posedge clk) begin
        dregs[0] <= din;
        for (int i = 1; i < DEPTH; i++) begin
          dregs[i] <= dregs[i-1];
        end
      end

      assign dout = dregs[DEPTH-1];

    end
  endgenerate

endmodule

`default_nettype wire
