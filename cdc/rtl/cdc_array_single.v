`timescale 1 ns / 1 ps
//
`default_nettype none
//
(* KEEP_HIERARCHY="yes" *)
module cdc_array_single #(
    parameter integer DEST_SYNC_FF  = 4,
    parameter reg     INIT_SYNC_FF  = 1'b0,
    parameter reg     SRC_INPUT_REG = 1'b1,
    parameter integer WIDTH         = 2
) (
    input  wire             src_clk,
    input  wire [WIDTH-1:0] src_in,
    //
    input  wire             dest_clk,
    output wire [WIDTH-1:0] dest_out
);

  // verilog_format: off
  initial begin
    if ((DEST_SYNC_FF < 2) || (DEST_SYNC_FF > 10)) begin
      $display("ERROR: DEST_SYNC_FF (%0d) value is outside of valid range of 2-10. [%m]", DEST_SYNC_FF);
      #1 $finish();
    end
    if ((WIDTH < 1) || (WIDTH > 1024)) begin
      $display("ERROR: WIDTH (%0d) value is outside of valid range of 1-1024. [%m]", WIDTH);
      #1 $finish();
    end
  end
  // verilog_format: on

  reg  [WIDTH-1:0] src_ff;
  wire [WIDTH-1:0] src_inqual;
  wire [WIDTH-1:0] async_path_bit;

  (* ASYNC_REG="true" *)
  reg  [WIDTH-1:0] syncstages_ff  [DEST_SYNC_FF-1:0];

  initial begin : p_init
    integer i;
    if (INIT_SYNC_FF) begin
      src_ff = {WIDTH{1'b0}};
      for (i = 0; i < DEST_SYNC_FF; i = i + 1) begin
        syncstages_ff[i] = {WIDTH{1'b0}};
      end
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
  always @(posedge dest_clk) begin : p_syncstages_ff
    integer syncstage;
    syncstages_ff[0] <= async_path_bit;
    for (syncstage = 1; syncstage < DEST_SYNC_FF; syncstage = syncstage + 1) begin
      syncstages_ff[syncstage] <= syncstages_ff[syncstage-1];
    end
  end

  assign dest_out = syncstages_ff[DEST_SYNC_FF-1];

endmodule

`default_nettype wire
