// File: max_parallel.sv
// Brief: Select MAX over specific signed numbers, output max and index.

`timescale 1ns / 1ps `default_nettype none

module max_parallel #(
    parameter int NUM_INPUT  = 4,
    parameter int DATA_WIDTH = 16,
    parameter int CTRL_WIDTH = 4
) (
    input var  logic                                clk,
    input var  logic                                rst,
    //
    input var  logic signed [       DATA_WIDTH-1:0] data_in [NUM_INPUT],
    input var  logic        [       CTRL_WIDTH-1:0] ctrl_in [NUM_INPUT],
    //
    output var logic signed [       DATA_WIDTH-1:0] data_out,
    output var logic        [       CTRL_WIDTH-1:0] ctrl_out,
    output var logic        [$clog2(NUM_INPUT)-1:0] idx_out
);


  localparam int NumStage = $clog2(NUM_INPUT);

  generate
    for (genvar ii = 0; ii < NumStage; ii++) begin : g_stage

      logic signed [DATA_WIDTH-1:0] data_s[NUM_INPUT / (2**ii) / 2];
      logic        [CTRL_WIDTH-1:0] ctrl_s[NUM_INPUT / (2**ii) / 2];
      logic        [        ii+1:0] idx_s [NUM_INPUT / (2**ii) / 2];

      if (ii == 0) begin : g_first

        max_pipeline #(
            .NUM_INPUT (NUM_INPUT),
            .IDX_WIDTH (ii + 1),
            //
            .DATA_WIDTH(DATA_WIDTH),
            .CTRL_WIDTH(CTRL_WIDTH)
        ) i_m (
            .clk     (clk),
            .rst     (rst),
            //
            .data_in (data_in),
            .ctrl_in (ctrl_in),
            .idx_in  ('{NUM_INPUT{1'b0}}),
            //
            .data_out(data_s),
            .ctrl_out(ctrl_s),
            .idx_out (idx_s)
        );

      end else begin : g_left

        max_pipeline #(
            .NUM_INPUT (NUM_INPUT / 2 ** ii),
            .IDX_WIDTH (ii + 1),
            //
            .DATA_WIDTH(DATA_WIDTH),
            .CTRL_WIDTH(CTRL_WIDTH)
        ) i_m (
            .clk     (clk),
            .rst     (rst),
            //
            .data_in (g_stage[ii-1].data_s),
            .ctrl_in (g_stage[ii-1].ctrl_s),
            .idx_in  (g_stage[ii-1].idx_s),
            //
            .data_out(data_s),
            .ctrl_out(ctrl_s),
            .idx_out (idx_s)
        );

      end  // if

    end  // for
  endgenerate

  assign data_out = g_stage[NumStage-1].data_s[0];
  assign ctrl_out = g_stage[NumStage-1].ctrl_s[0];
  assign idx_out  = g_stage[NumStage-1].idx_s[0];

endmodule  // max_parallel

`default_nettype wire
