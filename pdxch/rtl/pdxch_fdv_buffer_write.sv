`timescale 1 ns / 1 ps
//
`default_nettype none

module pdxch_fdv_buffer_write #(
    parameter int CC_ID = 0
) (
    input  wire         clk,
    input  wire         rst,
    //
    input  wire [ 11:0] s_dl_sym_num,
    //
    input  wire [127:0] s_axis_tdata,
    input  wire [ 15:0] s_axis_tkeep,
    input  wire         s_axis_tvalid,
    input  wire         s_axis_tlast,
    input  wire [ 90:0] s_axis_tuser,
    //
    output wire [ 10:0] wr_addr,
    output wire         wr_en,
    output wire [127:0] wr_data
);

  logic [127:0] s_axis_tdata_rev;
  logic [127:0] s_axis_tdata_r2;

  logic         addr_msb;
  logic [  9:0] addr_lsb;

  logic [  9:0] rx_u_startPrb;
  logic [  7:0] rx_u_numPrb;
  logic [  3:0] rx_u_cc;
  logic         rx_u_sos;

  logic         wr_cc_r;
  logic         wr_en_r;
  logic [127:0] wr_data_r;

  assign rx_u_sos      = s_axis_tuser[90];
  assign rx_u_cc       = s_axis_tuser[30:27];
  assign rx_u_numPrb   = s_axis_tuser[17:10];
  assign rx_u_startPrb = s_axis_tuser[9:0];

  function automatic logic [127:0] byte_reverse(input logic [127:0] data);
    for (int i = 0; i < 16; i++) begin
      byte_reverse[8*i+7-:8] = data[127-8*i-:8];
    end
  endfunction

  function automatic logic [127:0] word_reverse(input logic [127:0] data);
    for (int i = 0; i < 8; i++) begin
      word_reverse[16*i+15-:16] = data[127-16*i-:16];
    end
  endfunction

  assign s_axis_tdata_rev = byte_reverse(s_axis_tdata);
  // 4 IQ pairs, every 16-bit is reversed since RAM puts first I0 at lowest address
  assign s_axis_tdata_r2  = word_reverse(s_axis_tdata_rev);

  // There are types of input: 64-bit (2 IQ pairs) / 128-bit (4 IQ pairs)
  always_ff @(posedge clk) begin
    if (rx_u_sos) begin
      wr_data_r <= s_axis_tdata_r2;
    end else if (s_axis_tvalid) begin
      wr_data_r <= s_axis_tdata_r2;
    end
  end

  // wr_data = {Q1, I1, Q0, I0}
  assign wr_data = wr_data_r;

  always_ff @(posedge clk) begin
    if (rx_u_sos) begin
      addr_msb <= s_dl_sym_num[0];
    end
  end

  always_ff @(posedge clk) begin
    if (rx_u_sos) begin
      addr_lsb <= rx_u_startPrb * 3;
    end else if (wr_en_r) begin
      addr_lsb <= addr_lsb + 1'b1;
    end
  end

  assign wr_addr = {addr_msb, addr_lsb};

  always_ff @(posedge clk) begin
    if (rx_u_sos) begin
      wr_cc_r <= (rx_u_cc == CC_ID);
    end
  end

  always_ff @(posedge clk) begin
    wr_en_r <= s_axis_tvalid && (wr_cc_r || (rx_u_sos && (rx_u_cc == CC_ID)));
  end

  assign wr_en = wr_en_r;

endmodule

`default_nettype wire
