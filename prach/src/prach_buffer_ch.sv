`timescale 1 ns / 1 ps
//
`default_nettype none

module prach_buffer_ch #(
    parameter int CHANNEL = 0
) (
    input var          clk,
    input var          rst_n,
    //
    input var  [ 15:0] din_dr,
    input var  [ 15:0] din_di,
    input var  [  7:0] din_chn,
    input var  [ 15:0] din_sample_k,
    //
    output var [119:0] ap_hdr,
    output var         ap_req,
    input var          ap_ack,
    //
    input var  [ 11:0] rd_addr,
    input var          rd_en,
    output var [ 31:0] rd_data,
    // C-Plane
    input var          clk_eth_xran,
    input var          rst_eth_xran_n,
    //
    input var          c_valid,
    input var  [119:0] c_header,
    input var  [ 19:0] c_time_offset,
    input var  [  3:0] c_num_symbol
);

  // C-Plane message

  logic         c_valid_s;
  logic         c_ready_s;
  logic [119:0] c_header_s;
  logic [ 19:0] c_time_offset_s;
  logic [  3:0] c_num_symbol_s;

  prach_buffer_cp_fifo u_cp_fifo (
      .rst_n   (rst_eth_xran_n),
      //
      .wr_clk  (clk_eth_xran),
      //
      .wr_valid(c_valid),
      .wr_data ({c_num_symbol, c_time_offset, c_header}),
      .wr_ready( /* assume never full*/),
      //
      .rd_clk  (clk),
      //
      .rd_data ({c_num_symbol_s, c_time_offset_s, c_header_s}),
      .rd_valid(c_valid_s),
      .rd_ready(c_ready_s)
  );

  // RAM

  logic [31:0] mem        [4096];

  logic [11:0] wr_addr;
  logic        wr_en;
  logic [31:0] wr_data;

  logic [31:0] rd_data_r1;
  logic [31:0] rd_data_r2;
  logic [31:0] rd_data_r3;

  always_ff @(posedge clk) begin
    if (wr_en) begin
      mem[wr_addr] <= wr_data;
    end
  end

  always_ff @(posedge clk) begin
    if (rd_en) begin
      rd_data_r1 <= mem[rd_addr];
    end else begin
      rd_data_r1 <= '0;
    end
  end

  always_ff @(posedge clk) begin
    rd_data_r2 <= rd_data_r1;
    rd_data_r3 <= rd_data_r2;
  end

  assign rd_data = rd_data_r3;

  // Write FSM
  // Write 1 or 2 symbols to buffer, the MSB of address is bank number

  logic        wr_run;
  logic        wr_symbol;
  logic [10:0] wr_cnt;

  logic [15:0] r_seq_id;

  logic        wr_start;
  logic        wr_stop;

  assign wr_start = c_valid_s && (din_sample_k == c_time_offset_s[19:4]) && (din_chn == CHANNEL);
  assign wr_stop = (wr_cnt == 1535) && (wr_symbol == c_num_symbol_s > 0) && (din_chn == CHANNEL);

  always_ff @(posedge clk) begin
    if (~rst_n) begin
      wr_run <= 1'b0;
    end else if (wr_start) begin
      wr_run <= 1'b1;
    end else if (wr_stop) begin
      wr_run <= 1'b0;
    end
  end

  assign c_ready_s = wr_stop;

  always_ff @(posedge clk) begin
    if (wr_cnt == 1535 && din_chn == CHANNEL) begin
      wr_cnt <= '0;
    end else if (wr_run && din_chn == CHANNEL) begin
      wr_cnt <= wr_cnt + 1;
    end else if (wr_run) begin
      wr_cnt <= wr_cnt;
    end else begin
      wr_cnt <= '0;
    end
  end

  always_ff @(posedge clk) begin
    if (wr_cnt == 1535 && din_chn == CHANNEL) begin
      wr_symbol <= wr_symbol + 1;
    end else if (wr_run) begin
      wr_symbol <= wr_symbol;
    end else begin
      wr_symbol <= 1'b0;
    end
  end

  // Write

  always_ff @(posedge clk) begin
    wr_addr <= {wr_symbol, wr_cnt};
  end

  always_ff @(posedge clk) begin
    wr_en <= wr_start || (wr_run && (din_chn == CHANNEL));
  end

  always_ff @(posedge clk) begin
    if (wr_start || (wr_run && (din_chn == CHANNEL))) begin
      wr_data <= {din_di, din_dr};
    end
  end

  // After buffer the required samples, send request

  always_ff @(posedge clk) begin
    if (wr_stop) begin
      ap_hdr <= c_header_s;
    end
  end

  always_ff @(posedge clk) begin
    if (~rst_n) begin
      ap_req <= 1'b0;
    end else if (wr_stop) begin
      ap_req <= 1'b1;
    end else if (ap_ack) begin
      ap_req <= 1'b0;
    end
  end

endmodule

`default_nettype wire
