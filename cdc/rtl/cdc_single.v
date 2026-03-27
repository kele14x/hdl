`timescale 1 ns / 1 ps
//
`default_nettype none
//
(* KEEP_HIERARCHY="yes" *)
module cdc_single #(
    parameter integer DEST_SYNC_FF  = 4,
    parameter reg     INIT_SYNC_FF  = 1'b0,
    parameter reg     SRC_INPUT_REG = 1'b1
) (
    input  wire src_clk,
    input  wire src_in,
    //
    input  wire dest_clk,
    output wire dest_out
);

  // verilog_format: off
  initial begin
    if ((DEST_SYNC_FF < 2) || (DEST_SYNC_FF > 10)) begin
      $display("ERROR: DEST_SYNC_FF (%0d) value is outside of valid range of 2-10. [%m]", DEST_SYNC_FF);
      #1 $finish();
    end
  end
  // verilog_format: on

  reg                     src_ff;
  wire                    src_inqual;
  wire                    async_path_bit;

  (* ASYNC_REG="true" *)
  reg  [DEST_SYNC_FF-1:0] syncstages_ff;

  initial begin
    if (INIT_SYNC_FF) begin
      src_ff        = 1'b0;
      syncstages_ff = {DEST_SYNC_FF{1'b0}};
    end
  end

  // Optional input register
  always @(posedge src_clk) begin
    src_ff <= src_in;
  end

  // Virtual mux
  generate
    if (SRC_INPUT_REG) begin : g_inreg
      assign src_inqual = src_ff;
    end else begin : g_no_inreg
      assign src_inqual = src_in;
    end
  endgenerate

  assign async_path_bit = src_inqual;

  // Synchronous registers
  always @(posedge dest_clk) begin
    syncstages_ff <= {syncstages_ff[DEST_SYNC_FF-2:0], async_path_bit};
  end

  assign dest_out = syncstages_ff[DEST_SYNC_FF-1];

endmodule

`default_nettype wire
