`timescale 1 ns / 1 ps
//
`default_nettype none
//
(* KEEP_HIERARCHY="yes" *)
module cdc_gray #(
    parameter integer DEST_SYNC_FF = 4,
    parameter reg     INIT_SYNC_FF = 1'b0,
    parameter reg     REG_OUTPUT   = 1'b0,
    parameter integer WIDTH        = 2
) (
    input  wire             src_clk,
    input  wire [WIDTH-1:0] src_in_bin,
    //
    input  wire             dest_clk,
    output wire [WIDTH-1:0] dest_out_bin
);

  // verilog_format: off
  initial begin
    if ((DEST_SYNC_FF < 2) || (DEST_SYNC_FF > 10)) begin
      $display("ERROR: DEST_SYNC_FF (%0d) is outside of valid range of 2-10. [%m]", DEST_SYNC_FF);
      #1 $finish();
    end
    if ((WIDTH < 2) || (WIDTH > 32)) begin
      $display("ERROR: WIDTH (%0d) is outside of valid range of 2-32. [%m]", WIDTH);
      #1 $finish();
    end
  end
  // verilog_format: on

  (* ASYNC_REG="true" *)
  reg  [WIDTH-1:0] dest_graysync_ff[DEST_SYNC_FF-1:0];

  wire [WIDTH-1:0] gray_enc;
  reg  [WIDTH-1:0] src_gray_ff;

  wire [WIDTH-1:0] async_path;
  wire [WIDTH-1:0] synco_gray;

  reg  [WIDTH-1:0] binval;
  reg  [WIDTH-1:0] dest_out_bin_ff;

  // Encode to gray code

  assign gray_enc = src_in_bin ^ {1'b0, src_in_bin[WIDTH-1:1]};

  always @(posedge src_clk) begin
    src_gray_ff <= gray_enc;
  end

  // Asynchronous Register

  assign async_path = src_gray_ff;

  always @(posedge dest_clk) begin : p_dest_graysync_ff
    integer syncstage;
    dest_graysync_ff[0] <= async_path;
    for (syncstage = 1; syncstage < DEST_SYNC_FF; syncstage = syncstage + 1) begin
      dest_graysync_ff[syncstage] <= dest_graysync_ff[syncstage-1];
    end
  end

  assign synco_gray = dest_graysync_ff[DEST_SYNC_FF-1];

  // Convert gray code back to binary
  always @(*) begin : p_binval
    integer j;
    binval[WIDTH-1] = synco_gray[WIDTH-1];
    for (j = WIDTH - 2; j >= 0; j = j - 1) begin
      binval[j] = binval[j+1] ^ synco_gray[j];
    end
  end

  // Optional output register
  always @(posedge dest_clk) begin
    dest_out_bin_ff <= binval;
  end

  // Virtual mux
  generate
    if (REG_OUTPUT) begin : g_reg_out
      assign dest_out_bin = dest_out_bin_ff;
    end else begin : g_comb_out
      assign dest_out_bin = binval;
    end
  endgenerate

endmodule

`default_nettype wire
