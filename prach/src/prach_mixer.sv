`timescale 1 ns / 1 ps
//
`default_nettype none

module prach_mixer (
    input var         clk,
    input var         rst_n,
    //
    input var  [15:0] din_dr   [3],
    input var  [15:0] din_di   [3],
    input var  [ 7:0] din_chn,
    input var         sync_in,
    //
    output var [15:0] dout_dr  [3],
    output var [15:0] dout_di  [3],
    output var [ 7:0] dout_chn,
    output var        sync_out,
    //----
    input var  [16:0] ctrl_fcw [3][8]
);

  logic [7:0] dout_chn_s[3];
  logic       sync_out_s[3];

  generate
    for (genvar i = 0; i < 3; i++) begin : g_ch

      prach_mixer_ch u_ch (
          .clk      (clk),
          .rst_n    (rst_n),
          //
          .din_dr   (din_dr[i]),
          .din_di   (din_di[i]),
          .din_chn  (din_chn),
          .sync_in  (sync_in),
          //
          .dout_dr  (dout_dr[i]),
          .dout_di  (dout_di[i]),
          .dout_chn (dout_chn_s[i]),
          .sync_out (sync_out_s[i]),
          //
          .ctrl_fcw (ctrl_fcw[i])
      );

    end
  endgenerate

  assign dout_chn = dout_chn_s[0];
  assign sync_out = sync_out_s[0];

endmodule

`default_nettype wire
