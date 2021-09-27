// File: reg_pipeline.sv
// Brief: Register pipeline to delay a signal for specific number of clocks

`timescale 1 ns / 1 ps `default_nettype none

module reg_pipeline #(
    parameter int DATA_WIDTH      = 8,
    parameter int PIPELINE_STAGES = 8
) (
    input var  logic                  clk,
    input var  logic [DATA_WIDTH-1:0] din,
    output var logic [DATA_WIDTH-1:0] dout
);

  generate
    if (PIPELINE_STAGES == 0) begin : g_no_pipeline

      assign dout = din;

    end else begin : g_reg_pipeline

      logic [DATA_WIDTH-1:0] din_srl[PIPELINE_STAGES];

      always_ff @(posedge clk) begin
        din_srl[0] <= din;
        for (int i = 1; i < PIPELINE_STAGES; i++) begin
          din_srl[i] <= din_srl[i-1];
        end
      end

      assign dout = din_srl[PIPELINE_STAGES-1];

    end

  endgenerate

endmodule
