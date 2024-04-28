`timescale 1 ns / 1 ps
//
`default_nettype none

module cdc_sync #(
    parameter int DATA_WIDTH = 8,
    parameter int SRC_PIPE   = 4,
    parameter int DEST_PIPE  = 2
) (
    input var                   src_clk,
    input var                   src_req,
    input var  [DATA_WIDTH-1:0] src_sig,
    //
    input var                   dst_clk,
    output var                  dst_req,
    output var [DATA_WIDTH-1:0] dst_sig
);

  logic                  src_req_d;
  logic [  SRC_PIPE-1:0] src_req_pipe;
  logic [DATA_WIDTH-1:0] src_sig_cdc;

  logic [ DEST_PIPE-1:0] src_req_cdc;
  logic                  src_req_cdc_d;

  // Source

  always_ff @(posedge src_clk) begin
    src_req_d <= src_req;
  end

  always_ff @(posedge src_clk) begin
    if (src_req && ~src_req_d) begin
      src_req_pipe <= '1;
    end else begin
      src_req_pipe <= {src_req_pipe[SRC_PIPE-2:0], 1'b0};
    end
  end

  always_ff @(posedge src_clk) begin
    if (src_req && ~src_req_d) begin
      src_sig_cdc <= src_sig;
    end
  end

  // Dest

  always_ff @(posedge dst_clk) begin
    src_req_cdc <= {src_req_cdc[DEST_PIPE-2:0], src_req_pipe[SRC_PIPE-1]};
  end

  always_ff @(posedge dst_clk) begin
    src_req_cdc_d <= src_req_cdc[DEST_PIPE-1];
  end

  always_ff @(posedge dst_clk) begin
    if (src_req_cdc[DEST_PIPE-1] && ~src_req_cdc_d) begin
      dst_sig <= src_sig_cdc;
    end
  end

  always_ff @(posedge dst_clk) begin
    dst_req <= (src_req_cdc[DEST_PIPE-1] && ~src_req_cdc_d);
  end

endmodule

`default_nettype wire
