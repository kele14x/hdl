`timescale 1 ns / 1 ps
//
`default_nettype none
//
(* KEEP_HIERARCHY = "yes" *)
module cdc_handshake_f #(
    parameter bit DEST_EXT_HSK = 1'b1,
    parameter int DEST_SYNC_FF = 32'd4,
    parameter bit INIT_SYNC_FF = 1'b0,
    parameter int SRC_SYNC_FF  = 32'd4,
    parameter int WIDTH        = 32'd1
) (
    input  wire              src_clk,
    input  wire [WIDTH-1:0]  src_in,
    input  wire              src_valid,
    output wire              src_ready,
    //
    input  wire              dest_clk,
    output wire [WIDTH-1:0]  dest_out,
    output wire              dest_valid,
    input  wire              dest_ready
);

  initial begin : drc_check
    assert (DEST_EXT_HSK == 0 || DEST_EXT_HSK == 1)
    else begin
      $error("[%m]: DEST_EXT_HSK (%0d) value is outside of valid range.", DEST_EXT_HSK);
    end

    assert (DEST_SYNC_FF >= 2 && DEST_SYNC_FF <= 10)
    else begin
      $error("[%m]: DEST_SYNC_FF (%0d) is outside of valid range of 2-10.", DEST_SYNC_FF);
    end

    assert (INIT_SYNC_FF == 0 || INIT_SYNC_FF == 1)
    else begin
      $error("[%m]: INIT_SYNC_FF (%0d) value is outside of valid range.", INIT_SYNC_FF);
    end

    assert (SRC_SYNC_FF >= 2 && SRC_SYNC_FF <= 10)
    else begin
      $error("[%m]: SRC_SYNC_FF (%0d) is outside of valid range of 2-10.", SRC_SYNC_FF);
    end

    assert (WIDTH >= 1 && WIDTH <= 1024)
    else begin
      $fatal(1, "[%m]: WIDTH (%0d) is outside of valid range of 1-1024.", WIDTH);
    end
  end

  logic [WIDTH-1:0] src_hsdata_ff;
  logic             src_valid_nxt;
  logic             src_count_nxt;
  logic             src_count_ff;
  logic             src_count_sync_ff;
  logic             src_count_eq;
  logic             src_ready_nxt;
  logic             src_ready_ext_ff;

  logic [WIDTH-1:0] dest_hsdata_ff;
  logic             dest_hsdata_ff_en;
  logic             dest_valid_ext_ff;
  logic             dest_valid_nxt;
  logic             dest_ready_in;
  logic             dest_ready_nxt;
  logic             dest_count_nxt;
  logic             dest_count_eq;
  logic             dest_count_ff;
  logic             dest_count_sync_ff;

  assign src_valid_nxt = src_valid && src_ready;

  always_ff @(posedge src_clk) begin
    if (src_valid_nxt) begin
      src_hsdata_ff <= src_in;
    end
  end

  assign src_count_nxt = src_valid_nxt ? ~src_count_ff : src_count_ff;

  always_ff @(posedge src_clk) begin
    src_count_ff <= src_count_nxt;
  end

  assign src_count_eq  = (src_count_ff == dest_count_sync_ff);
  assign src_ready_nxt = src_count_eq && !src_valid_nxt;

  always_ff @(posedge src_clk) begin
    src_ready_ext_ff <= src_ready_nxt;
  end

  assign src_ready = src_ready_ext_ff;

  assign dest_ready_in = (DEST_EXT_HSK != 0) ? dest_ready : (dest_ready | 1'b1);

  assign dest_ready_nxt = dest_valid_ext_ff && dest_ready_in;
  assign dest_count_nxt = dest_ready_nxt ? ~dest_count_ff : dest_count_ff;

  always_ff @(posedge dest_clk) begin
    dest_count_ff <= dest_count_nxt;
  end

  assign dest_out = dest_hsdata_ff;
  assign dest_count_eq = (src_count_sync_ff == dest_count_ff);
  assign dest_hsdata_ff_en = !dest_count_eq && !dest_valid_ext_ff;

  always_ff @(posedge dest_clk) begin
    if (dest_hsdata_ff_en) begin
      dest_hsdata_ff <= src_hsdata_ff;
    end
  end

  assign dest_valid_nxt = !dest_count_eq && !dest_ready_nxt;

  always_ff @(posedge dest_clk) begin
    dest_valid_ext_ff <= dest_valid_nxt;
  end

  assign dest_valid = dest_valid_ext_ff;

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
