`timescale 1 ns / 1 ps
//
`default_nettype none

module prach_buffer (
    input var          clk,
    input var          rst_n,
    //
    input var  [ 15:0] din_dr,
    input var  [ 15:0] din_di,
    input var  [  7:0] din_chn,
    input var          sync_in,
    //
    output var [ 15:0] dout_dr,
    output var [ 15:0] dout_di,
    output var         dout_dv,
    output var         sync_out,
    output var [119:0] hdr_out,
    // C-Plane
    input var          clk_eth_xran,
    input var          rst_eth_xran_n,
    //
    input var          c_valid       [3][8],
    input var  [119:0] c_header,
    input var  [ 19:0] c_time_offset,
    input var  [  3:0] c_num_symbol
);

  logic [ 15:0] din_dr_d;
  logic [ 15:0] din_di_d;
  logic [  7:0] din_chn_d;

  logic [ 15:0] din_sample_k;

  logic [119:0] ap_hdr       [3][8];
  logic         ap_req       [3][8];
  logic         ap_ack       [3][8];

  logic [ 11:0] rd_addr;
  logic         rd_en        [3][8];
  logic [ 31:0] rd_data      [3][8];

  always_ff @(posedge clk) begin
    din_dr_d  <= din_dr;
    din_di_d  <= din_di;
    din_chn_d <= din_chn;
  end

  always_ff @(posedge clk) begin
    if (sync_in) begin
      din_sample_k <= '0;
    end else if (din_chn == 0) begin
      din_sample_k <= din_sample_k + 1;
    end
  end

  generate
    for (genvar cc = 0; cc < 3; cc++) begin : g_cc
      for (genvar ant = 0; ant < 8; ant++) begin : g_ant

        prach_buffer_ch #(
            .CHANNEL(cc * 16 + ant)
        ) u_ch (
            .clk           (clk),
            .rst_n         (rst_n),
            //
            .din_dr        (din_dr_d),
            .din_di        (din_di_d),
            .din_chn       (din_chn_d),
            .din_sample_k  (din_sample_k),
            //
            .ap_hdr        (ap_hdr[cc][ant]),
            .ap_req        (ap_req[cc][ant]),
            .ap_ack        (ap_ack[cc][ant]),
            //
            .rd_addr       (rd_addr),
            .rd_en         (rd_en[cc][ant]),
            .rd_data       (rd_data[cc][ant]),
            // C-Plane
            .clk_eth_xran  (clk_eth_xran),
            .rst_eth_xran_n(rst_eth_xran_n),
            //
            .c_valid       (c_valid[cc][ant]),
            .c_header      (c_header),
            .c_time_offset (c_time_offset),
            .c_num_symbol  (c_num_symbol)
        );

      end
    end
  endgenerate

  prach_buffer_readout u_readout (
      .clk     (clk),
      .rst_n   (rst_n),
      // Buffer
      .ap_hdr  (ap_hdr),
      .ap_req  (ap_req),
      .ap_ack  (ap_ack),
      //
      .rd_addr (rd_addr),
      .rd_en   (rd_en),
      .rd_data (rd_data),
      // FFT
      .dout_dr (dout_dr),
      .dout_di (dout_di),
      .dout_dv (dout_dv),
      .sync_out(sync_out),
      .hdr_out (hdr_out)
  );

endmodule

`default_nettype wire
