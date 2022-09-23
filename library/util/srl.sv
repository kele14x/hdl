// File: srl.sv
// Brief: Variable Length Shift Register Look-Up Table (LUT).
//        The inputs `addr` select the depth of the shift register. It can be
//        used as fixed, static depth, or be dynamically adjustable.
//        Depth (Latency) is value of `addr` + 2
`timescale 1 ns / 1 ps
//
`default_nettype none

module srl #(
    parameter bit SIM_INIT   = 1,
    parameter bit OUTPU_REG  = 1,
    parameter int ADDR_WIDTH = 4,
    parameter int DATA_WIDTH = 8
) (
    // Read Interface
    input var                   clk,
    input var                   rst,
    input var                   cen,
    //
    input var  [ADDR_WIDTH-1:0] addr,
    input var  [DATA_WIDTH-1:0] din,
    output var [DATA_WIDTH-1:0] dout
);

  // Put the shifting path in first index
  logic [2**ADDR_WIDTH-1:0] dsrl[DATA_WIDTH];

  initial begin : p_init
    if (SIM_INIT) begin
      for (int i = 0; i < DATA_WIDTH; i++) begin
        dsrl[i] = '0;
      end
    end
  end

  generate
    for (genvar i = 0; i < DATA_WIDTH; i++) begin : g_srl
      always @(posedge clk) begin
        if (cen) begin
          dsrl[i] <= {dsrl[i][2**ADDR_WIDTH-2:0], din[i]};
        end
      end
    end
  endgenerate

  generate
    if (OUTPU_REG == 0) begin : g_no_reg
      for (genvar i = 0; i < DATA_WIDTH; i++) begin
        assign dout[i] = dsrl[i][addr];
      end
    end else begin : g_reg
      for (genvar i = 0; i < DATA_WIDTH; i++) begin
        always_ff @(posedge clk) begin
          if (rst) begin
            dout[i] <= '0;
          end else if (cen) begin
            dout[i] <= dsrl[i][addr];
          end
        end
      end
    end
  endgenerate

endmodule

`default_nettype wire
