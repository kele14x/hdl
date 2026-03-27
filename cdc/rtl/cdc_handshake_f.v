`timescale 1 ns / 1 ps
//
`default_nettype none
//
(* KEEP_HIERARCHY="yes" *)
module cdc_handshake_f #(
    parameter reg     DEST_EXT_HSK = 1'b1,
    parameter integer DEST_SYNC_FF = 4,
    parameter reg     INIT_SYNC_FF = 1'b0,
    parameter integer SRC_SYNC_FF  = 4,
    parameter integer WIDTH        = 1
) (
    input  wire             src_clk,
    input  wire [WIDTH-1:0] src_in,
    input  wire             src_valid,
    output wire             src_ready,
    //
    input  wire             dest_clk,
    output wire [WIDTH-1:0] dest_out,
    output wire             dest_valid,
    input  wire             dest_ready
);

  // verilog_format: off
  initial begin
    if ((DEST_SYNC_FF < 2) || (DEST_SYNC_FF > 10)) begin
      $display("ERROR: DEST_SYNC_FF (%0d) is outside of valid range of 2-10. [%m]", DEST_SYNC_FF);
      #1 $finish();
    end
    if ((WIDTH < 1) || (WIDTH > 1024)) begin
      $display("ERROR: WIDTH (%0d) is outside of valid range of 1-1024. [%m]", WIDTH);
      #1 $finish();
    end
  end
  // verilog_format: on

  reg  [WIDTH-1:0] src_hsdata_ff;
  wire             src_valid_nxt;
  wire             src_count_nxt;
  reg              src_count_ff = 1'b0;
  wire             src_count_sync_ff;
  wire             src_count_eq;
  wire             src_ready_nxt;
  reg              src_ready_ext_ff = 1'b0;

  reg  [WIDTH-1:0] dest_hsdata_ff;
  wire             dest_hsdata_ff_en;
  reg              dest_valid_ext_ff = 1'b0;
  wire             dest_valid_nxt;
  wire             dest_ready_in;
  wire             dest_ready_nxt;
  wire             dest_count_nxt;
  wire             dest_count_eq;
  reg              dest_count_ff = 1'b0;
  wire             dest_count_sync_ff;

  // Source side

  assign src_valid_nxt = src_valid && src_ready;

  always @(posedge src_clk) begin
    if (src_valid_nxt) begin
      src_hsdata_ff <= src_in;
    end
  end

  assign src_count_nxt = (src_valid_nxt == 1'b1) ? (src_count_ff + 1'b1) : src_count_ff;

  always @(posedge src_clk) begin
    src_count_ff <= src_count_nxt;
  end

  assign src_count_eq  = (src_count_ff == dest_count_sync_ff) ? 1'b1 : 1'b0;
  assign src_ready_nxt = src_count_eq && !src_valid_nxt;

  always @(posedge src_clk) begin
    src_ready_ext_ff <= src_ready_nxt;
  end

  assign src_ready = src_ready_ext_ff;

  // Destination side

  // Virtual mux
  generate
    if (DEST_EXT_HSK) begin : g_ext_desthsk
      assign dest_ready_in = dest_ready;
    end else begin : g_internal_desthsk
      assign dest_ready_in = 1'b1;
    end
  endgenerate

  assign dest_ready_nxt = dest_valid_ext_ff && dest_ready_in;

  assign dest_count_nxt = (dest_ready_nxt == 1'b1) ? (dest_count_ff + 1'b1) : dest_count_ff;

  always @(posedge dest_clk) begin
    dest_count_ff <= dest_count_nxt;
  end

  assign dest_out = dest_hsdata_ff;

  assign dest_count_eq = (src_count_sync_ff == dest_count_ff) ? 1'b1 : 1'b0;
  assign dest_hsdata_ff_en = !dest_count_eq && !dest_valid_ext_ff;

  always @(posedge dest_clk) begin
    if (dest_hsdata_ff_en) begin
      dest_hsdata_ff <= src_hsdata_ff;
    end
  end

  assign dest_valid_nxt = !dest_count_eq && !dest_ready_nxt;

  always @(posedge dest_clk) begin
    dest_valid_ext_ff <= dest_valid_nxt;
  end

  assign dest_valid = dest_valid_ext_ff;

  // Sync count value between src and dest

  cdc_single #(
      .DEST_SYNC_FF (DEST_SYNC_FF),
      .INIT_SYNC_FF (INIT_SYNC_FF),
      .SRC_INPUT_REG(0)
  ) cdc_single_src2dest_inst (
      .src_clk (src_clk),
      .dest_clk(dest_clk),
      .src_in  (src_count_ff),
      .dest_out(src_count_sync_ff)
  );

  cdc_single #(
      .DEST_SYNC_FF (SRC_SYNC_FF),
      .INIT_SYNC_FF (INIT_SYNC_FF),
      .SRC_INPUT_REG(0)
  ) cdc_single_dest2src_inst (
      .src_clk (dest_clk),
      .dest_clk(src_clk),
      .src_in  (dest_count_ff),
      .dest_out(dest_count_sync_ff)
  );

endmodule

`default_nettype wire
