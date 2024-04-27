// File: delay.sv
// Brief: Shift registers to delay a signal for specific number of clocks. It
//        let synthesizer select result automatically.
`timescale 1 ns / 1 ps
//
`default_nettype none

module delay #(
    parameter bit SIM_INIT = 1,
    parameter int WIDTH    = 8,
    parameter int DEPTH    = 8
) (
    input var              clk,
    input var              cen,
    //
    input var  [WIDTH-1:0] din,
    output var [WIDTH-1:0] dout
);

  initial begin
    assert (WIDTH > 0)
    else $error("[%m]: WIDTH value (%d) should be large than 0", WIDTH);

    assert (DEPTH >= 0)
    else $error("[%m]: DEPTH value (%d) should be large or equal than 0", DEPTH);
  end

  generate
    if (DEPTH == 0) begin : g_no_reg

      assign dout = din;

    end else begin : g_regs

      logic [WIDTH-1:0] dregs[DEPTH];

      initial begin : p_init
        if (SIM_INIT) begin
          for (int i = 0; i < DEPTH; i++) begin
            dregs[i] <= 'd0;
          end
        end
      end

      always @(posedge clk) begin : p_shift
        if (cen) begin
          dregs[0] <= din;
          for (int i = 1; i < DEPTH; i++) begin
            dregs[i] <= dregs[i-1];
          end
        end
      end

      assign dout = dregs[DEPTH-1];

    end
  endgenerate

endmodule

`default_nettype wire
