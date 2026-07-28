`timescale 1 ns / 1 ps
//
`default_nettype none

module async_input_sync #(
    parameter SYNC_STAGES = 3,
    parameter PIPELINE_STAGES = 1,
    parameter INIT = 1'b0
) (
    input  wire clk,
    input  wire async_in,
    output wire sync_out
);

  initial begin : drc_check
    assert (INIT == 1'b0 || INIT == 1'b1)
    else begin
      $error("[%m]: INIT value is outside of valid range.");
    end
  end

  (* ASYNC_REG="TRUE" *)
  reg [SYNC_STAGES-1:0] sreg;

  always @(posedge clk) begin
    sreg <= {sreg[SYNC_STAGES-2:0], async_in};
  end

  generate
    if (PIPELINE_STAGES == 0) begin : g_no_pipeline

      assign sync_out = sreg[SYNC_STAGES-1];

    end else if (PIPELINE_STAGES == 1) begin : g_one_pipeline

      reg sreg_pipe;

      always @(posedge clk) begin
        sreg_pipe <= sreg[SYNC_STAGES-1];
      end

      assign sync_out = sreg_pipe;

    end else begin : g_multiple_pipeline

      (* shreg_extract = "no" *)
      reg [PIPELINE_STAGES-1:0] sreg_pipe;

      always @(posedge clk) begin
        sreg_pipe <= {sreg_pipe[PIPELINE_STAGES-2:0], sreg[SYNC_STAGES-1]};
      end

      assign sync_out = sreg_pipe[PIPELINE_STAGES-1];

    end
  endgenerate

endmodule

`default_nettype wire
