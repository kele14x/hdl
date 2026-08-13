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
    parameter int HALF_BLOCK = 0
) (
    input var         clk,
    input var         rst,
    //
    input var  [11:0] s_dl_sym_num,
    // Compressed BFP9 stream
    input var  [35:0] s_axis_tdata,
    input var  [ 3:0] s_axis_exp,
    input var         s_axis_tvalid,
    input var         s_axis_tlast,
    input var  [90:0] s_axis_tuser,
    // IQ RAM write port
    output var [11:0] wr_iq_addr,
    output var        wr_iq_en,
    output var [35:0] wr_iq_data,
    // Exponent RAM write port
    output var [11:0] wr_exp_addr,
    output var        wr_exp_en,
    output var [ 3:0] wr_exp_data
);

  localparam int IQ_BANK_DEPTH = (HALF_BLOCK != 0) ? 1024 : 1792;
  localparam int EXP_BANK_DEPTH = (HALF_BLOCK != 0) ? 480 : 825;

  logic packet_active;
  logic packet_match_r;
  // The bank is folded into the address at packet start; no separate state is needed.
  logic [11:0] iq_addr_r;
  logic [11:0] exp_addr_r;
  logic [11:0] word_count_r;

  logic [11:0] wr_iq_addr_c;
  logic wr_iq_en_c;
  logic [35:0] wr_iq_data_c;
  logic [11:0] wr_exp_addr_c;
  logic wr_exp_en_c;
  logic [3:0] wr_exp_data_c;

  wire packet_first = ~packet_active;
  wire [3:0] rx_u_cc = s_axis_tuser[30:27];
  wire [9:0] rx_u_startPrb = s_axis_tuser[9:0];
  wire packet_match = packet_first ? (rx_u_cc == 4'(CC_ID)) : packet_match_r;
  wire unused_inputs = &{1'b0, s_dl_sym_num[11:1], s_axis_tuser[90:31], s_axis_tuser[26:10]};

  wire [11:0] iq_start_addr =
      (s_dl_sym_num[0] ? 12'(IQ_BANK_DEPTH) : 12'd0) + (rx_u_startPrb * 12'd6);
  wire [11:0] exp_start_addr =
      (s_dl_sym_num[0] ? 12'(EXP_BANK_DEPTH) : 12'd0) + (rx_u_startPrb * 12'd3);

  wire [11:0] iq_bank_limit = s_dl_sym_num[0] ? 12'(2 * IQ_BANK_DEPTH) : 12'(IQ_BANK_DEPTH);
  wire [11:0] exp_bank_limit = s_dl_sym_num[0] ? 12'(2 * EXP_BANK_DEPTH) : 12'(EXP_BANK_DEPTH);
  wire bank_overflow = (wr_iq_addr_c >= iq_bank_limit) || (wr_exp_addr_c >= exp_bank_limit);

  assign wr_iq_addr_c = packet_first ? iq_start_addr : iq_addr_r;
  assign wr_iq_en_c = s_axis_tvalid && packet_match && ~bank_overflow;
  assign wr_iq_data_c = s_axis_tdata;

  assign wr_exp_addr_c = packet_first ? exp_start_addr : exp_addr_r;
  assign wr_exp_en_c = wr_iq_en_c && (packet_first || ~word_count_r[0]);
  assign wr_exp_data_c = s_axis_exp;

  initial begin : drc_check
    assert (0 <= CC_ID && CC_ID < 16)
    else $error("[%m]: CC_ID (%0d) must fit in the 4-bit TUSER field.", CC_ID);
  end

  // Register the complete RAM write bundle to shorten the path from the
  // U-Plane packet decode and address generators into the FDV memories.
  always_ff @(posedge clk) begin
    if (rst) begin
      wr_iq_addr  <= '0;
      wr_iq_en    <= 1'b0;
      wr_iq_data  <= '0;
      wr_exp_addr <= '0;
      wr_exp_en   <= 1'b0;
      wr_exp_data <= '0;
    end else begin
      wr_iq_addr  <= wr_iq_addr_c;
      wr_iq_en    <= wr_iq_en_c;
      wr_iq_data  <= wr_iq_data_c;
      wr_exp_addr <= wr_exp_addr_c;
      wr_exp_en   <= wr_exp_en_c;
      wr_exp_data <= wr_exp_data_c;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      packet_active  <= 1'b0;
      packet_match_r <= 1'b0;
      iq_addr_r      <= '0;
      exp_addr_r     <= '0;
      word_count_r   <= '0;
    end else if (s_axis_tvalid) begin
      packet_active <= ~s_axis_tlast;

      if (packet_first) begin
        packet_match_r <= (rx_u_cc == 4'(CC_ID));
        if (bank_overflow) begin
          iq_addr_r    <= iq_start_addr;
          exp_addr_r   <= exp_start_addr;
          word_count_r <= '0;
        end else begin
          iq_addr_r    <= iq_start_addr + 1'b1;
          exp_addr_r   <= exp_start_addr;
          word_count_r <= 12'd1;
        end
      end else if (!bank_overflow) begin
        iq_addr_r    <= iq_addr_r + 1'b1;
        word_count_r <= word_count_r + 1'b1;
        if (word_count_r[0]) begin
          exp_addr_r <= exp_addr_r + 1'b1;
        end
      end
    end
  end

endmodule

`default_nettype wire
