`timescale 1 ns / 1 ps
//
`default_nettype none
//
(* KEEP_HIERARCHY="yes" *)
module cdc_async_rst #(
    parameter integer DEST_SYNC_FF    = 4,
    parameter reg     INIT_SYNC_FF    = 1'b0,
    parameter reg     RST_ACTIVE_HIGH = 1'b0
) (
    input  wire src_arst,
    input  wire dest_clk,
    output wire dest_arst
);

  // verilog_format: off
  initial begin
    if ((DEST_SYNC_FF < 2) || (DEST_SYNC_FF > 10)) begin
      $display("ERROR: DEST_SYNC_FF (%0d) is outside of valid range of 2-10. [%m]", DEST_SYNC_FF);
      #1 $finish();
    end
  end
  // verilog_format: on

  localparam reg DEF_VAL = (RST_ACTIVE_HIGH == 1) ? 1'b0 : 1'b1;
  localparam reg INV_DEF_VAL = (RST_ACTIVE_HIGH == 0) ? 1'b0 : 1'b1;

  (* ASYNC_REG="true" *)
  reg  [DEST_SYNC_FF-1:0] arststages_ff;

  wire                    async_path_bit;
  wire                    reset_pol;

  initial begin
    if (INIT_SYNC_FF) begin
      arststages_ff <= {DEST_SYNC_FF{DEF_VAL}};
    end
  end

  assign reset_pol = src_arst ^ ~RST_ACTIVE_HIGH;
  assign async_path_bit = (RST_ACTIVE_HIGH == 1) ? 1'b0 : 1'b1;

  always @(posedge dest_clk or posedge reset_pol) begin
    if (reset_pol) begin
      arststages_ff <= {DEST_SYNC_FF{INV_DEF_VAL}};
    end else begin
      arststages_ff <= {arststages_ff[DEST_SYNC_FF-2:0], async_path_bit};
    end
  end

  assign dest_arst = arststages_ff[DEST_SYNC_FF-1];

endmodule

`default_nettype wire
