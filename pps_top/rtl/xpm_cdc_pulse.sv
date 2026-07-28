`timescale 1 ns / 1 ps
//
`default_nettype none

module xpm_cdc_pulse #(
    parameter int DEST_SYNC_FF   = 4,
    parameter int INIT_SYNC_FF   = 0,
    parameter int REG_OUTPUT     = 0,
    parameter int RST_USED       = 1,
    parameter int SIM_ASSERT_CHK = 0
) (
    input  wire src_clk,
    input  wire src_rst,
    input  wire src_pulse,
    input  wire dest_clk,
    input  wire dest_rst,
    output wire dest_pulse
);

  cdc_pulse #(
      .DEST_SYNC_FF(DEST_SYNC_FF),
      .INIT_SYNC_FF(INIT_SYNC_FF != 0),
      .REG_OUTPUT  (REG_OUTPUT != 0),
      .RST_USED    (RST_USED != 0)
  ) i_cdc_pulse (
      .src_clk   (src_clk),
      .src_rst   (src_rst),
      .src_pulse (src_pulse),
      .dest_clk  (dest_clk),
      .dest_rst  (dest_rst),
      .dest_pulse(dest_pulse)
  );

  wire unused_sim_assert_chk = SIM_ASSERT_CHK[0];

endmodule

`default_nettype wire
