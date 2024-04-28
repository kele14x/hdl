`timescale 1 ns / 1 ps
//
`default_nettype none

module prach_buffer_readout (
    input var          clk,
    input var          rst_n,
    // Buffer
    input var  [119:0] ap_hdr  [3][8],
    input var          ap_req  [3][8],
    output var         ap_ack  [3][8],
    //
    output var [ 11:0] rd_addr,
    output var         rd_en   [3][8],
    input var  [ 31:0] rd_data [3][8],
    // FFT
    output var [ 15:0] dout_dr,
    output var [ 15:0] dout_di,
    output var         dout_dv,
    output var         sync_out,
    output var [119:0] hdr_out
);

  logic         busy;
  logic         done;
  logic [119:0] hdr_r;

  logic [119:0] hdr         [24];
  logic         req         [24];
  logic         ack         [24];


  logic [ 10:0] rd_cnt;
  logic [ 10:0] rd_cnt_next;

  logic [ 31:0] rd_data_or;

  // First channel first arbiter
  generate
    for (genvar i = 0; i < 24; i++) begin : g_arb

      always_ff @(posedge clk) begin
        if (~rst_n) begin
          ack[i] <= 1'b0;
        end else if (busy && done) begin
          ack[i] <= 1'b0;
        end else if (busy) begin
          ack[i] <= ack[i];
        end else begin
          ack[i] <= 1'b1;
          for (int ii = 0; ii < i; ii++) begin
            if (req[ii]) ack[i] <= 1'b0;
          end
          if (~req[i]) ack[i] <= 1'b0;
        end
      end

    end
  endgenerate

  always_ff @(posedge clk) begin
    for (int i = 0; i < 24; i++) begin
      if (req[i] && ~busy) begin
        hdr_r <= hdr[i];
      end
    end
  end

  always_ff @(posedge clk) begin
    if (~rst_n) begin
      busy <= 1'b0;
    end else if (busy) begin
      busy <= ~done;
    end else begin
      busy <= 1'b0;
      for (int i = 0; i < 24; i++) begin
        if (req[i]) busy <= 1'b1;
      end
    end
  end

  // Read

  always_ff @(posedge clk) begin
    if (~busy) begin
      rd_cnt <= '0;
    end else begin
      rd_cnt <= rd_cnt_next;
    end
  end

  always_comb begin
    if (rd_cnt[1:0] == 2'b10) begin
      rd_cnt_next = {rd_cnt[10:2] + 1, 2'b00};
    end else begin
      rd_cnt_next = rd_cnt + 1;
    end
  end

  assign done = (rd_cnt == 2046);

  always_comb begin
    rd_addr[10:9] = rd_cnt[1:0];
    for (int i = 0; i < 9; i++) begin
      rd_addr[i] = rd_cnt[10-i];
    end
  end

  // TODO: fix rd_en logic
  generate
    for (genvar cc = 0; cc < 3; cc++) begin : g_cc
      for (genvar ant = 0; ant < 8; ant++) begin : g_ant

        assign req[cc*8+ant]   = ap_req[cc][ant];
        assign hdr[cc*8+ant]   = ap_hdr[cc][ant];

        assign ap_ack[cc][ant] = ack[cc*8+ant];
        assign rd_en[cc][ant]  = ack[cc*8+ant];

      end
    end
  endgenerate

  always_comb begin
    rd_data_or = '0;
    for (int cc = 0; cc < 3; cc++) begin
      for (int ant = 0; ant < 8; ant++) begin
        rd_data_or = rd_data_or | rd_data[cc][ant];
      end
    end
  end

  always_ff @(posedge clk) begin
    dout_dr <= rd_data_or[15:0];
    dout_di <= rd_data_or[31:16];
  end

  delay #(
      .WIDTH(1),
      .DELAY(4)
  ) u_delay (
      .clk  (clk),
      .rst_n(1'b1),
      .din  (busy),
      .dout (dout_dv)
  );

  delay #(
      .WIDTH(1),
      .DELAY(4)
  ) u_delay_sync (
      .clk  (clk),
      .rst_n(1'b1),
      .din  (rd_addr == 0 && busy),
      .dout (sync_out)
  );

endmodule

`default_nettype wire
