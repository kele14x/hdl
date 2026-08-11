`timescale 1 ns / 1 ps
//
`default_nettype none

// Write-side address generator for the compressed FDV buffer.
//
// The gearbox emits one 36-bit word for two complex REs. Six words form one
// PRB, while the exponent RAM stores the PRB exponent at three addresses;
// each exponent address therefore covers two consecutive IQ RAM words (four
// complex REs).
module pdxch_fdv_buffer_write #(
    parameter int CC_ID      = 0,
    parameter bit HALF_BLOCK = 1'b0
) (
    input wire         clk,
    input wire         rst,
    //
    input wire [ 11:0] s_dl_sym_num,
    // Compressed BFP9 stream
    input wire [ 35:0] s_axis_tdata,
    input wire [  3:0] s_axis_exp,
    input wire         s_axis_tvalid,
    input wire         s_axis_tlast,
    input wire [ 90:0] s_axis_tuser,
    // IQ RAM write port
    output wire [ 11:0] wr_iq_addr,
    output wire         wr_iq_en,
    output wire [ 35:0] wr_iq_data,
    // Exponent RAM write port
    output wire [ 11:0] wr_exp_addr,
    output wire         wr_exp_en,
    output wire [  3:0] wr_exp_data
);

  localparam int IQ_BANK_DEPTH  = HALF_BLOCK ? 1024 : 1792;
  localparam int EXP_BANK_DEPTH = HALF_BLOCK ? 480 : 825;

  logic        packet_active;
  logic        packet_match_r;
  // The bank is folded into the address at packet start; no separate state is needed.
  logic [11:0] iq_addr_r;
  logic [11:0] exp_addr_r;
  logic [11:0] word_count_r;

  wire         packet_first = ~packet_active;
  wire [ 3:0]  rx_u_cc      = s_axis_tuser[30:27];
  wire [ 9:0]  rx_u_startPrb = s_axis_tuser[9:0];
  wire         packet_match = packet_first ? (rx_u_cc == 4'(CC_ID)) : packet_match_r;

  wire [11:0] iq_start_addr =
      (s_dl_sym_num[0] ? 12'(IQ_BANK_DEPTH) : 12'd0) + (rx_u_startPrb * 12'd6);
  wire [11:0] exp_start_addr =
      (s_dl_sym_num[0] ? 12'(EXP_BANK_DEPTH) : 12'd0) + (rx_u_startPrb * 12'd3);

  assign wr_iq_addr = packet_first ? iq_start_addr : iq_addr_r;
  assign wr_iq_en   = s_axis_tvalid && packet_match;
  assign wr_iq_data = s_axis_tdata;

  assign wr_exp_addr = packet_first ? exp_start_addr : exp_addr_r;
  assign wr_exp_en   = wr_iq_en && (packet_first || ~word_count_r[0]);
  assign wr_exp_data = s_axis_exp;

  initial begin : drc_check
    assert (0 <= CC_ID && CC_ID < 16)
    else $error("[%m]: CC_ID (%0d) must fit in the 4-bit TUSER field.", CC_ID);
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      packet_active <= 1'b0;
      packet_match_r <= 1'b0;
      iq_addr_r     <= '0;
      exp_addr_r    <= '0;
      word_count_r  <= '0;
    end else if (s_axis_tvalid) begin
      packet_active <= ~s_axis_tlast;

      if (packet_first) begin
        packet_match_r <= (rx_u_cc == 4'(CC_ID));
        iq_addr_r      <= iq_start_addr + 1'b1;
        exp_addr_r     <= exp_start_addr;
        word_count_r   <= 12'd1;
      end else begin
        iq_addr_r     <= iq_addr_r + 1'b1;
        word_count_r  <= word_count_r + 1'b1;
        if (word_count_r[0]) begin
          exp_addr_r <= exp_addr_r + 1'b1;
        end
      end
    end
  end

endmodule

`default_nettype wire
