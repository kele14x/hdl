`timescale 1 ns / 1 ps
//
`default_nettype none

module prach_reshape1 (
    input var         clk,
    input var         rst_n,
    //
    input var  [15:0] din_dr  [3],
    input var  [15:0] din_di  [3],
    input var  [ 7:0] din_chn,
    input var         sync_in,
    //
    output var [15:0] dout_dp1[3],
    output var [15:0] dout_dp2[3],
    output var [ 7:0] dout_chn,
    output var        sync_out
);

  logic [7:0] dout_chn_s[3];
  logic       sync_out_s[3];

  generate
    for (genvar i = 0; i < 3; i++) begin : g_ch
      prach_reshape_ch #(
          .SIZE(16)
      ) u_ch (
          .clk     (clk),
          .rst_n   (rst_n),
          //
          .din_dq1 (din_dr[i]),
          .din_dq2 (din_di[i]),
          .din_chn (din_chn),
          .sync_in (sync_in),
          //
          .dout_dp1(dout_dp1[i]),
          .dout_dp2(dout_dp2[i]),
          .dout_chn(dout_chn_s[i]),
          .sync_out(sync_out_s[i])
      );
    end
  endgenerate

  assign dout_chn = dout_chn_s[0];
  assign sync_out = sync_out_s[0];

endmodule

`default_nettype wire
