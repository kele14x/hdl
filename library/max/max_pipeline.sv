// File: max_pipeline.sv
// Brief: One stage for max_parallel

`timescale 1ns / 1ps `default_nettype none

module max_pipeline #(
    parameter int NUM_INPUT  = 4,
    parameter int IDX_WIDTH  = 1,
    //
    parameter int DATA_WIDTH = 16,
    parameter int CTRL_WIDTH = 4
) (
    input var  logic                         clk,
    input var  logic                         rst,
    //
    input var  logic signed [DATA_WIDTH-1:0] data_in [  NUM_INPUT],
    input var  logic        [CTRL_WIDTH-1:0] ctrl_in [  NUM_INPUT],
    input var  logic        [ IDX_WIDTH-1:0] idx_in  [  NUM_INPUT],
    //
    output var logic signed [DATA_WIDTH-1:0] data_out[NUM_INPUT/2],
    output var logic        [CTRL_WIDTH-1:0] ctrl_out[NUM_INPUT/2],
    output var logic        [   IDX_WIDTH:0] idx_out [NUM_INPUT/2]
);


  localparam int Latency = 1;

  generate
    for (genvar ii = 0; ii < NUM_INPUT / 2; ii++) begin : g_cmp

      always_ff @(posedge clk) begin
        if (data_in[2*ii+1] > data_in[2*ii]) begin
          data_out[ii] <= data_in[2*ii+1];
          ctrl_out[ii] <= ctrl_in[2*ii+1];
          idx_out[ii]  <= {idx_in[2*ii+1], 1'b1};
        end else begin
          data_out[ii] <= data_in[2*ii];
          ctrl_out[ii] <= ctrl_in[2*ii];
          idx_out[ii]  <= {idx_in[2*ii], 1'b0};
        end
      end

    end
  endgenerate

endmodule  // max_pipeline

`default_nettype wire
