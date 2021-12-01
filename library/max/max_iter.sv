// File: max_pipeline.sv
// Brief: Select MAX over specific signed numbers, output max and index. Use
//        iteration method.

`timescale 1ns / 1ps `default_nettype none

module max_iter #(
    parameter int NUM_INPUT  = 4,
    parameter int IDX_WIDTH  = 1,
    //
    parameter int DATA_WIDTH = 16,
    parameter int CTRL_WIDTH = 4
) (
    input var  logic                                          clk,
    input var  logic                                          rst,
    //
    input var  logic signed [                 DATA_WIDTH-1:0] data_in [NUM_INPUT],
    input var  logic        [                 CTRL_WIDTH-1:0] ctrl_in [NUM_INPUT],
    input var  logic        [                  IDX_WIDTH-1:0] idx_in  [NUM_INPUT],
    //
    output var logic signed [                 DATA_WIDTH-1:0] data_out,
    output var logic        [                 CTRL_WIDTH-1:0] ctrl_out,
    output var logic        [$clog2(NUM_INPUT)+IDX_WIDTH-1:0] idx_out
);


  logic signed [DATA_WIDTH-1:0] data_reg[NUM_INPUT/2];
  logic        [CTRL_WIDTH-1:0] ctrl_reg[NUM_INPUT/2];
  logic        [   IDX_WIDTH:0] idx_reg [NUM_INPUT/2];

  generate
    for (genvar ii = 0; ii < NUM_INPUT / 2; ii++) begin : g_cmp

      always_ff @(posedge clk) begin
        if (data_in[2*ii+1] > data_in[2*ii]) begin
          data_reg[ii] <= data_in[2*ii+1];
          ctrl_reg[ii] <= ctrl_in[2*ii+1];
          idx_reg[ii]  <= {idx_in[2*ii+1], 1'b1};
        end else begin
          data_reg[ii] <= data_in[2*ii];
          ctrl_reg[ii] <= ctrl_in[2*ii];
          idx_reg[ii]  <= {idx_in[2*ii], 1'b0};
        end
      end

    end
  endgenerate

  generate
    if (NUM_INPUT == 2) begin : g_2to1

      assign data_out = data_reg[0];
      assign ctrl_out = ctrl_reg[0];
      assign idx_out  = idx_reg[0];

    end else begin : g_iter

      max_pipeline #(
          .NUM_INPUT(NUM_INPUT / 2),
          .IDX_WIDTH(IDX_WIDTH + 1),

          .DATA_WIDTH(DATA_WIDTH),
          .CTRL_WIDTH(CTRL_WIDTH)
      ) i_m (
          .clk     (clk),
          .rst     (rst),
          //
          .data_in (data_reg),
          .ctrl_in (ctrl_reg),
          .idx_in  (idx_reg),
          //
          .data_out(data_out),
          .ctrl_out(ctrl_out),
          .idx_out (idx_out)
      );

    end
  endgenerate

endmodule  // max_iter

`default_nettype wire
