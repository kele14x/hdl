`timescale 1 ns / 1 ps
//
`default_nettype none (* KEEP_HIERARCHY = "yes" *)
module cdc_async_rst #(
    parameter int DEST_SYNC_FF    = 4,
    parameter int INIT_SYNC_FF    = 0,
    parameter int RST_ACTIVE_HIGH = 0
) (
    input  logic src_arst,
    input  logic dest_clk,
    output logic dest_arst
);

  initial begin : drc_check
    assert (DEST_SYNC_FF >= 2 && DEST_SYNC_FF <= 10)
    else begin
      $error("[%m]: DEST_SYNC_FF (%0d) is outside of valid range of 2-10.", DEST_SYNC_FF);
    end

    assert (INIT_SYNC_FF == 0 || INIT_SYNC_FF == 1)
    else begin
      $error("[%m]: INIT_SYNC_FF (%0d) is outside of valid range.", INIT_SYNC_FF);
    end

    assert (RST_ACTIVE_HIGH == 0 || RST_ACTIVE_HIGH == 1)
    else begin
      $error("[%m]: RST_ACTIVE_HIGH (%0d) is outside of valid range.", RST_ACTIVE_HIGH);
    end
  end

  localparam logic DefVal = (RST_ACTIVE_HIGH != 0) ? 1'b0 : 1'b1;
  localparam logic InvDefVal = (RST_ACTIVE_HIGH == 0) ? 1'b0 : 1'b1;

  (* ASYNC_REG = "true" *)
  logic [DEST_SYNC_FF-1:0] arststages_ff;
  logic                    async_path_bit;
  logic                    reset_pol;

  initial begin : p_init
    if (INIT_SYNC_FF != 0) begin
      arststages_ff = {DEST_SYNC_FF{DefVal}};
    end
  end

  assign reset_pol = src_arst ^ DefVal;
  assign async_path_bit = DefVal;

  always_ff @(posedge dest_clk or posedge reset_pol) begin
    if (reset_pol) begin
      arststages_ff <= {DEST_SYNC_FF{InvDefVal}};
    end else begin
      arststages_ff <= {arststages_ff[DEST_SYNC_FF-2:0], async_path_bit};
    end
  end

  assign dest_arst = arststages_ff[DEST_SYNC_FF-1];

endmodule

`default_nettype wire
