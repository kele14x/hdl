`timescale 1 ns / 1 ps
//
`default_nettype none

module pps_checker (
    input var         clk,
    input var         rst,
    //
    input var         pps_in,
    //
    input var  [31:0] sys_timer_ns,
    // CSR
    //----
    input var         ctrl_clk,
    //
    output var [31:0] stat_pps_offset
);

  (* ASYNC_REG="true" *)
  logic [ 3:0] pps_buffer;
  logic [15:0] pps_glitch;
  logic        pps_clr;

  logic        pps_d1;
  logic        pps_d2;

  logic        pps_up;

  logic [31:0] stat_pps_offset_in;
  logic        stat_pps_offset_send;
  logic        stat_pps_offset_rcv;
  wire         unused_stat_pps_offset_req;


  // Clear 1PPS glitch

  always_ff @(posedge clk) begin
    pps_buffer <= {pps_buffer[2:0], pps_in};
  end

  always_ff @(posedge clk) begin
    pps_glitch <= {pps_glitch[14:0], pps_buffer[3]};
  end

  always_ff @(posedge clk) begin
    if (pps_glitch == '1) begin
      pps_clr <= 1'b1;
    end else if (pps_glitch == '0) begin
      pps_clr <= 1'b0;
    end
  end

  // Check 1PPS posedge

  always_ff @(posedge clk) begin
    pps_d1 <= pps_clr;
    pps_d2 <= pps_d1;
  end

  always_ff @(posedge clk) begin
    pps_up <= ({pps_d2, pps_d1} == 2'b01);
  end


  // Phase difference
  //-----------------

  // stat_pps_offset CDC to AXI register

  always_ff @(posedge clk) begin
    if (pps_up) begin
      stat_pps_offset_in <= sys_timer_ns;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      stat_pps_offset_send <= 1'b0;
    end else if (pps_up) begin
      stat_pps_offset_send <= 1'b1;
    end else if (stat_pps_offset_rcv) begin
      stat_pps_offset_send <= 1'b0;
    end
  end

  xpm_cdc_handshake #(
      .DEST_EXT_HSK  (0),
      .DEST_SYNC_FF  (2),
      .INIT_SYNC_FF  (0),
      .SIM_ASSERT_CHK(0),
      .SRC_SYNC_FF   (2),
      .WIDTH         (32)
  ) xpm_cdc_handshake_pps_diff (
      .src_clk (clk),
      .src_in  (stat_pps_offset_in),
      .src_send(stat_pps_offset_send),
      .src_rcv (stat_pps_offset_rcv),
      //
      .dest_clk(ctrl_clk),
      .dest_out(stat_pps_offset),
      .dest_req(unused_stat_pps_offset_req),
      .dest_ack(1'b0)
  );

endmodule

`default_nettype wire
