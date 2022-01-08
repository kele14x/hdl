// File: nlf_srl.sv
// Brief: SRL for both index and signal

`timescale 1 ns / 1 ps `default_nettype none

module nlf_srl #(
    parameter int ADDR_WIDTH = 4,
    parameter int DATA_WIDTH = 8
) (
    // Read Interface
    input var                   clk,
    //
    input var  [ADDR_WIDTH-1:0] addr,
    input var  [DATA_WIDTH-1:0] din,
    output var [DATA_WIDTH-1:0] dout
);

  logic [2**ADDR_WIDTH-1:0] dsrl[DATA_WIDTH];

  generate
    for (genvar i = 0; i < DATA_WIDTH; i++) begin : g_srl

      always_ff @(posedge clk) begin
        dsrl[i] <= {dsrl[i][2**ADDR_WIDTH-2:0], din[i]};
      end

      always_ff @(posedge clk) begin
        dout[i] <= dsrl[i][addr];
      end

    end
  endgenerate

endmodule

`default_nettype wire
