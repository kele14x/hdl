`timescale 1 ns / 1 ps
//
`default_nettype none
//
(* KEEP_HIERARCHY = "yes" *)
module cdc_sync_rst #(
    parameter int DEST_SYNC_FF = 4,
    parameter int INIT         = 1,
    parameter int INIT_SYNC_FF = 0
) (
    input  logic src_rst,
    input  logic dest_clk,
    output logic dest_rst
);

  initial begin : drc_check
    assert (DEST_SYNC_FF >= 2 && DEST_SYNC_FF <= 10)
    else begin
      $error("[%m]: DEST_SYNC_FF (%0d) is outside of valid range 2-10.", DEST_SYNC_FF);
    end

    assert (INIT == 0 || INIT == 1)
    else begin
      $error("[%m]: INIT (%0d) value is outside of valid range.", INIT);
    end

    assert (INIT_SYNC_FF == 0 || INIT_SYNC_FF == 1)
    else begin
      $error("[%m]: INIT_SYNC_FF (%0d) value is outside of valid range.", INIT_SYNC_FF);
    end
  end

  localparam logic DefVal = (INIT != 0) ? 1'b1 : 1'b0;

  (* ASYNC_REG = "true" *)
  logic [DEST_SYNC_FF-1:0] syncstages_ff;
  logic                    async_path_bit;

  initial begin : p_init
    if (INIT_SYNC_FF != 0) begin
      syncstages_ff = {DEST_SYNC_FF{DefVal}};
    end
  end

  assign async_path_bit = src_rst;

  always_ff @(posedge dest_clk) begin
    syncstages_ff <= {syncstages_ff[DEST_SYNC_FF-2:0], async_path_bit};
  end

  assign dest_rst = syncstages_ff[DEST_SYNC_FF-1];

endmodule

`default_nettype wire
