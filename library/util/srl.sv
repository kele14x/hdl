// File: srl.sv
// Brief: Addressable Shift Registers.
//        Latency is 2 + addr
`timescale 1 ns / 1 ps
//
`default_nettype none

module srl #(
    parameter bit SIM_INIT   = 1,
    parameter int ADDR_WIDTH = 4,
    parameter int DATA_WIDTH = 8
) (
    // Read Interface
    input  logic                  clk,
    input  logic                  cen,
    //
    input  logic [ADDR_WIDTH-1:0] addr,
    input  logic [DATA_WIDTH-1:0] din,
    output logic [DATA_WIDTH-1:0] dout
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

      always_ff @(posedge clk) begin
        if (cen) begin
          dsrl[i] <= {dsrl[i][2**ADDR_WIDTH-2:0], din[i]};
        end
      end

      always_ff @(posedge clk) begin
        if (cen) begin
          dout[i] <= dsrl[i][addr];
        end
      end

    end
  endgenerate

endmodule

`default_nettype wire
