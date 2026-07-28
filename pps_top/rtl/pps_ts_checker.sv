`timescale 1 ns / 1 ps
//
`default_nettype none

module pps_ts_checker (
    input var         clk,
    input var         rst,
    //
    input var         pps_in,
    //
    input var  [31:0] ts_t1,
    input var  [31:0] ts_t2,
    input var         ts_valid,
    // Control & Status
    //-----------------
    input var         ctrl_clk,
    //
    output var [31:0] stat_ts_cnt,
    output var [47:0] stat_ts_offset
);

  logic               pps_in_d;

  logic               ts_valid1;
  logic               ts_valid2;

  logic signed [31:0] ts_diff1;
  logic signed [31:0] ts_diff2;

  // Count how many timestamp is accumulated
  logic        [31:0] ts_cnt;
  logic               ts_cnt_send;
  logic               ts_cnt_rcv;

  logic signed [47:0] offset_acc;
  logic               offset_acc_send;
  logic               offset_acc_rcv;

  wire                unused_ts_cnt_req;
  wire                unused_offset_acc_req;


  
  always_ff @(posedge clk) begin
    pps_in_d <= pps_in;
  end


  // TS_DIFF
  //--------
  // Timestamp difference (phase error)

  always_ff @(posedge clk) begin
    ts_valid1 <= ts_valid;
    ts_valid2 <= ts_valid1;
  end

  // We do not care the second field of timestamp, this assumes the timestamp
  // difference will not be larger than 1s
  always_ff @(posedge clk) begin
    if (ts_valid) begin
      ts_diff1 <= $signed(ts_t1) - $signed(ts_t2);
    end
  end

  // Wrap and make sure the timestamp difference between -500000000 ~
  //   A position value: internal timer (1PPS) is late than source
  //   A negative value: internal timer (1PPS) is early than source
  always_ff @(posedge clk) begin
    if (ts_valid1) begin
      if (ts_diff1 >= 500000000) begin
        ts_diff2 <= ts_diff1 - 1000000000;
      end else if (ts_diff1 < -500000000) begin
        ts_diff2 <= ts_diff1 + 1000000000;
      end else begin
        ts_diff2 <= ts_diff1;
      end
    end
  end

  // TS_CNT
  //-------
  // Count how many TS update, this ensures SW know that TS is updated

  always_ff @(posedge clk) begin
    if (pps_in_d) begin
      ts_cnt <= '0;
    end else if (ts_valid) begin
      ts_cnt <= ts_cnt + 1;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      ts_cnt_send <= 1'b0;
    end else if (pps_in) begin
      ts_cnt_send <= 1'b1;
    end else if (ts_cnt_rcv) begin
      ts_cnt_send <= 1'b0;
    end
  end

  xpm_cdc_handshake #(
      .DEST_EXT_HSK  (0),
      .DEST_SYNC_FF  (2),
      .INIT_SYNC_FF  (0),
      .SIM_ASSERT_CHK(0),
      .SRC_SYNC_FF   (2),
      .WIDTH         (32)
  ) xpm_cdc_handshake_ts_cnt (
      .src_clk (clk),
      .src_in  (ts_cnt),
      .src_send(ts_cnt_send),
      .src_rcv (ts_cnt_rcv),
      //
      .dest_clk(ctrl_clk),
      .dest_out(stat_ts_cnt),
      .dest_req(unused_ts_cnt_req),
      .dest_ack(1'b0)
  );

  // Phase Error
  //------------
  // Integration to get averaged phase difference

  always_ff @(posedge clk) begin
    if (pps_in_d) begin
      offset_acc <= '0;
    end else if (ts_valid2) begin
      offset_acc <= offset_acc + {{16{ts_diff2[31]}}, ts_diff2};
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      offset_acc_send <= 1'b0;
    end else if (pps_in) begin
      offset_acc_send <= 1'b1;
    end else if (offset_acc_rcv) begin
      offset_acc_send <= 1'b0;
    end
  end

  xpm_cdc_handshake #(
      .DEST_EXT_HSK  (0),
      .DEST_SYNC_FF  (2),
      .INIT_SYNC_FF  (0),
      .SIM_ASSERT_CHK(0),
      .SRC_SYNC_FF   (2),
      .WIDTH         (48)
  ) xpm_cdc_handshake_stat_ts_offset (
      .src_clk (clk),
      .src_in  (offset_acc),
      .src_send(offset_acc_send),
      .src_rcv (offset_acc_rcv),
      //
      .dest_clk(ctrl_clk),
      .dest_out(stat_ts_offset),
      .dest_req(unused_offset_acc_req),
      .dest_ack(1'b0)
  );

endmodule

`default_nettype wire
