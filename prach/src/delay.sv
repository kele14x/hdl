
`timescale 1 ns / 1 ps
//
`default_nettype none

module delay #(
    parameter int    WIDTH = 32,
    parameter int    DELAY = 1,
    parameter string STYLE = "mlab"
) (
    input var              clk,
    input var              rst_n,
    input var  [WIDTH-1:0] din,
    output var [WIDTH-1:0] dout
);

  generate
    if (DELAY > 0) begin : g_delay

      (* ramstyle = STYLE *)
      logic [WIDTH-1:0] delay_pipe[DELAY];

      always_ff @(posedge clk) begin
        if (~rst_n) begin
          for (int i = 0; i < DELAY; i++) begin
            delay_pipe[i] <= '0;
          end
        end else begin
          delay_pipe[0] <= din;
          for (int i = 1; i < DELAY; i++) begin
            delay_pipe[i] <= delay_pipe[i-1];
          end
        end
      end

      assign dout = delay_pipe[DELAY-1];

    end else begin : g_no_delay
      assign dout = din;
    end
  endgenerate

endmodule

`default_nettype wire
