`timescale 1 ns / 1 ps
//
`default_nettype none

module xpm_cdc_handshake #(
    parameter int DEST_EXT_HSK   = 1,
    parameter int DEST_SYNC_FF   = 4,
    parameter int INIT_SYNC_FF   = 0,
    parameter int SIM_ASSERT_CHK = 0,
    parameter int SRC_SYNC_FF    = 4,
    parameter int WIDTH          = 1
) (
    input  wire             src_clk,
    input  wire [WIDTH-1:0] src_in,
    input  wire             src_send,
    output wire             src_rcv,
    input  wire             dest_clk,
    output wire [WIDTH-1:0] dest_out,
    output wire             dest_req,
    input  wire             dest_ack
);

  cdc_handshake_f #(
      .DEST_EXT_HSK(DEST_EXT_HSK != 0),
      .DEST_SYNC_FF(DEST_SYNC_FF),
      .INIT_SYNC_FF(INIT_SYNC_FF != 0),
      .SRC_SYNC_FF (SRC_SYNC_FF),
      .WIDTH       (WIDTH)
  ) i_cdc_handshake (
      .src_clk   (src_clk),
      .src_in    (src_in),
      .src_valid (src_send),
      .src_ready (src_rcv),
      .dest_clk  (dest_clk),
      .dest_out  (dest_out),
      .dest_valid(dest_req),
      .dest_ready(dest_ack)
  );

  wire unused_sim_assert_chk = SIM_ASSERT_CHK[0];

endmodule

`default_nettype wire
