`timescale 1 ns / 1 ps
//
`default_nettype none (* KEEP_HIERARCHY = "yes" *)
module cdc_async_rst #(
    parameter int DEST_SYNC_FF    = 4,
    parameter int INIT_SYNC_FF    = 0,
    parameter int RST_ACTIVE_HIGH = 0
) (
    input  wire src_arst,
    input  wire dest_clk,
    output wire dest_arst
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

  (* ASYNC_REG = "true" *)
  logic [DEST_SYNC_FF-1:0] arststages_ff;

  generate
    if (RST_ACTIVE_HIGH != 0) begin : g_active_high
      always_ff @(posedge dest_clk) begin
        if (src_arst) begin
          arststages_ff <= '1;
        end else begin
          arststages_ff <= {arststages_ff[DEST_SYNC_FF-2:0], 1'b0};
        end
      end
    end else begin : g_active_low
      always_ff @(posedge dest_clk) begin
        if (!src_arst) begin
          arststages_ff <= '0;
        end else begin
          arststages_ff <= {arststages_ff[DEST_SYNC_FF-2:0], 1'b1};
        end
      end
    end
  endgenerate

  assign dest_arst = arststages_ff[DEST_SYNC_FF-1];

endmodule

`default_nettype wire
