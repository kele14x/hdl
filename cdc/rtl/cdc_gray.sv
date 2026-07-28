`timescale 1 ns / 1 ps
//
`default_nettype none
//
(* KEEP_HIERARCHY = "yes" *)
module cdc_gray #(
    parameter int DEST_SYNC_FF = 4,
    parameter bit INIT_SYNC_FF = 1'b0,
    parameter bit REG_OUTPUT   = 1'b0,
    parameter int WIDTH        = 2
) (
    input  logic [WIDTH-1:0] src_in_bin,
    input  logic             src_clk,
    //
    input  logic             dest_clk,
    output logic [WIDTH-1:0] dest_out_bin
);

  initial begin : drc_check
    assert (DEST_SYNC_FF >= 2 && DEST_SYNC_FF <= 10)
    else begin
      $fatal(1, "[%m]: DEST_SYNC_FF (%0d) is outside of valid range of 2-10.", DEST_SYNC_FF);
    end

    assert (INIT_SYNC_FF == 0 || INIT_SYNC_FF == 1)
    else begin
      $fatal(1, "[%m]: INIT_SYNC_FF (%0d) value is outside of valid range.", INIT_SYNC_FF);
    end

    assert (REG_OUTPUT == 0 || REG_OUTPUT == 1)
    else begin
      $fatal(1, "[%m]: REG_OUTPUT (%0d) value is outside of valid range.", REG_OUTPUT);
    end

    assert (WIDTH >= 2 && WIDTH <= 32)
    else begin
      $fatal(1, "[%m]: WIDTH (%0d) is outside of valid range of 2-32.", WIDTH);
    end
  end

  (* ASYNC_REG = "true" *)
  logic [WIDTH-1:0] dest_graysync_ff[DEST_SYNC_FF];

  logic [WIDTH-1:0] gray_enc;
  logic [WIDTH-1:0] src_gray_ff;
  logic [WIDTH-1:0] async_path;
  logic [WIDTH-1:0] synco_gray;
  logic [WIDTH-1:0] binval;

  assign gray_enc = src_in_bin ^ {1'b0, src_in_bin[WIDTH-1:1]};

  always_ff @(posedge src_clk) begin
    src_gray_ff <= gray_enc;
  end

  assign async_path = src_gray_ff;

  always_ff @(posedge dest_clk) begin : p_dest_graysync_ff
    dest_graysync_ff[0] <= async_path;
    for (int syncstage = 1; syncstage < DEST_SYNC_FF; syncstage++) begin
      dest_graysync_ff[syncstage] <= dest_graysync_ff[syncstage-1];
    end
  end

  assign synco_gray = dest_graysync_ff[DEST_SYNC_FF-1];

  always_comb begin : p_binval
    binval[WIDTH-1] = synco_gray[WIDTH-1];
    for (int j = WIDTH - 2; j >= 0; j--) begin
      binval[j] = binval[j+1] ^ synco_gray[j];
    end
  end

  generate
    if (REG_OUTPUT) begin : g_reg_out
      logic [WIDTH-1:0] dest_out_bin_ff;

      always_ff @(posedge dest_clk) begin
        dest_out_bin_ff <= binval;
      end

      assign dest_out_bin = dest_out_bin_ff;
    end else begin : g_comb_out
      assign dest_out_bin = binval;
    end
  endgenerate

endmodule

`default_nettype wire
