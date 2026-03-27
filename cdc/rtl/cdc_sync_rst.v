`timescale 1 ns / 1 ps
//
`default_nettype none
//
(* KEEP_HIERARCHY="yes" *)
module cdc_sync_rst #(
    parameter integer DEST_SYNC_FF = 4,
    parameter reg     INIT         = 1'b1,
    parameter reg     INIT_SYNC_FF = 1'b0
) (
    input  wire src_rst,
    input  wire dest_clk,
    output wire dest_rst
);

  localparam reg DEF_VAL = (INIT == 1) ? 1'b1 : 1'b0;

  (* ASYNC_REG="true" *)
  reg  [DEST_SYNC_FF-1:0] syncstages_ff;

  wire                    async_path_bit;

  // verilog_format: off
  initial begin
    if ((DEST_SYNC_FF < 2) || (DEST_SYNC_FF > 10)) begin
      $display("ERROR: DEST_SYNC_FF (%0d) is outside of valid range 2-10. [%m]", DEST_SYNC_FF);
      #1 $finish();
    end
  end
  // verilog_format: on

  initial begin
    if (INIT_SYNC_FF) begin
      syncstages_ff <= {DEST_SYNC_FF{DEF_VAL}};
    end
  end

  assign async_path_bit = src_rst;

  always @(posedge dest_clk) begin
    syncstages_ff <= {syncstages_ff[DEST_SYNC_FF-2:0], async_path_bit};
  end

  assign dest_rst = syncstages_ff[DEST_SYNC_FF-1];

endmodule

`default_nettype wire
