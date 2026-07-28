`timescale 1 ns / 1 ps
//
`default_nettype none
//
(* KEEP_HIERARCHY = "yes" *)
module cdc_single #(
    parameter int DEST_SYNC_FF  = 4,
    parameter bit INIT_SYNC_FF  = 1'b0,
    parameter bit SRC_INPUT_REG = 1'b1
) (
    input  wire  src_clk,
    input  wire  src_in,
    //
    input  wire  dest_clk,
    output wire  dest_out
);

  initial begin : drc_check
    assert (DEST_SYNC_FF >= 2 && DEST_SYNC_FF <= 10)
    else begin
      $error("[%m]: DEST_SYNC_FF (%0d) value is outside of valid range of 2-10.", DEST_SYNC_FF);
    end

    assert (INIT_SYNC_FF == 0 || INIT_SYNC_FF == 1)
    else begin
      $error("[%m]: INIT_SYNC_FF (%0d) value is outside of valid range.", INIT_SYNC_FF);
    end

    assert (SRC_INPUT_REG == 0 || SRC_INPUT_REG == 1)
    else begin
      $error("[%m]: SRC_INPUT_REG (%0d) value is outside of valid range.", SRC_INPUT_REG);
    end
  end

  /* verilator lint_off UNUSEDSIGNAL */
  logic src_ff;
  logic src_inqual;
  logic async_path_bit;

  (* ASYNC_REG = "true" *)
  logic [DEST_SYNC_FF-1:0] syncstages_ff;

  always_ff @(posedge src_clk) begin
    src_ff <= src_in;
  end

  generate
    if (SRC_INPUT_REG != 0) begin : g_inreg
      assign src_inqual = src_ff;
    end else begin : g_no_inreg
      assign src_inqual = src_in;
    end
  endgenerate

  assign async_path_bit = src_inqual;

  always_ff @(posedge dest_clk) begin
    syncstages_ff <= {syncstages_ff[DEST_SYNC_FF-2:0], async_path_bit};
  end

  assign dest_out = syncstages_ff[DEST_SYNC_FF-1];

endmodule

`default_nettype wire
