`timescale 1 ns / 1 ps
//
`default_nettype none

module prach_framer_buffer (
    input var          clk,
    input var          rst_n,
    //
    input var  [ 15:0] din_dr,
    input var  [ 15:0] din_di,
    input var          din_dv,
    input var          sync_in,
    input var  [119:0] hdr_in,
    //
    output var [ 63:0] avst_source_data,
    output var         avst_source_valid,
    output var         avst_source_startofpacket,
    output var         avst_source_endofpacket,
    input var          avst_source_ready
);

  // RAM
  // 4k * 32 -> 2k * 64

  logic [11:0]       wr_addr;
  logic              wr_en;
  logic [31:0]       wr_data;

  logic [10:0]       rd_addr;
  logic              rd_en;
  logic [63:0]       rd_data;
  logic [63:0]       rd_data_d1;
  logic [63:0]       rd_data_d2;

  logic [ 1:0][31:0] ram        [2048];

  always_ff @(posedge clk) begin
    if (wr_en) begin
      ram[wr_data/2][wr_data%2] <= wr_data;
    end
  end

  always_ff @(posedge clk) begin
    if (rd_en) begin
      rd_data <= ram[rd_addr];
    end
  end

  always_ff @(posedge clk) begin
    rd_data_d1 <= rd_data;
    rd_data_d2 <= rd_data_d1;
  end

  // Write PING-PONG, assume 1536 IQs
  // TODO: we can reduce the buffer size to 1K per bank, since left 512 IQs are
  //       useless.

  logic [10:0] wr_cnt;
  logic        wr_bank;

  always_ff @(posedge clk) begin
    wr_en <= din_dv;
  end

  always_ff @(posedge clk) begin
    if (~rst_n) begin
      wr_bank <= 1'b0;
    end else if (sync_in) begin
      wr_bank <= ~wr_bank;
    end
  end

  always_ff @(posedge clk) begin
    if (sync_in) begin
      wr_cnt <= '0;
    end else if (din_dv) begin
      wr_cnt <= wr_cnt + 1;
    end
  end

  assign wr_addr = {wr_bank, wr_cnt};

  always_ff @(posedge clk) begin
    wr_data <= {din_di, din_dr};
  end

  // Read 864 IQs

  logic       rd_bank;
  logic [9:0] rd_cnt;
  logic       rd_run;

  logic       start;

  assign start = wr_addr == 1023 && wr_en;

  always_ff @(posedge clk) begin
    if (start) begin
      rd_bank <= wr_bank;
    end
  end

  always_ff @(posedge clk) begin
    if (~rst_n) begin
      rd_run <= 1'b0;
    end else if (start) begin
      rd_run <= 1'b1;
    end else if (rd_cnt == 866) begin
      rd_run <= 1'b0;
    end
  end

  always_ff @(posedge clk) begin
    if (start) begin
      rd_cnt <= '0;
    end else if (rd_cnt == 863) begin
      rd_cnt <= '0;
    end else if (rd_run) begin
      rd_cnt <= rd_cnt + 1;
    end else begin
      rd_cnt <= '0;
    end
  end

  assign rd_addr = {rd_bank, rd_cnt};

  always_ff @(posedge clk) begin
    if (~rst_n) begin
      rd_en <= '0;
    end else if (start) begin
      rd_en <= 1'b1;
    end else if (rd_cnt == 863) begin
      rd_en <= '0;
    end
  end

  // Header

  logic [119:0] hdr_r[2];

  always_ff @(posedge clk) begin
    if (sync_in) begin
      hdr_r[~wr_bank] <= hdr_in;
    end
  end

  always_ff @(posedge clk) begin
    if (rd_cnt == 0) begin
      avst_source_data <= hdr_r[rd_bank][119:72];
    end else if (rd_cnt == 1) begin
      avst_source_data <= hdr_r[rd_bank][71:40];
    end else if (rd_cnt == 2) begin
      avst_source_data <= hdr_r[rd_bank][39:0];
    end else begin
      avst_source_data <= rd_data_d2;
    end
  end

  always_ff @(posedge clk) begin
    avst_source_valid <= rd_run;
  end

  always_ff @(posedge clk) begin
    avst_source_startofpacket <= rd_run && rd_cnt == 0;
  end

  always_ff @(posedge clk) begin
    avst_source_endofpacket <= rd_run && rd_cnt == 866;
  end

endmodule

`default_nettype wire
