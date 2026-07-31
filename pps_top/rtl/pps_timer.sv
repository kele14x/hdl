// File: pps_timer.sv
// Brief: 80-bit Real Time Counter, also generate 1PPS output.
//        The latency is 1 clock tick (from sync_in to output).
`timescale 1 ns / 1 ps
//
`default_nettype none

module pps_timer (
    // System
    //-------
    input var         clk,
    input var         rst,
    //
    input var         sync_in,
    output var        sync_out,
    //
    input var  [ 1:0] sample_inc,
    // PPS output
    output var        pps_out,
    // System timer
    output var [47:0] sys_timer_s,
    output var [31:0] sys_timer_ns,
    // Ethernet
    //---------
    input var         eth_clk,
    input var         eth_rst,
    // Timer output
    output var [47:0] timer_s,
    output var [31:0] timer_ns,
    // Control & Status
    //-----------------
    input var         ctrl_clk,
    input var         ctrl_rst,
    // Get time
    input var         ctrl_get_snap,
    output var [47:0] ctrl_get_s,
    output var [31:0] ctrl_get_ns,
    // Set time
    input var         ctrl_set_valid,
    input var  [47:0] ctrl_set_s,
    input var  [31:0] ctrl_set_ns,
    // Adjust time
    input var         ctrl_adj_valid,
    input var  [31:0] ctrl_adj_ns
);

  // When use the 122.88 MHz clock for nanosecond counter, we need to get the
  // precision 1e9 nanosecond during 122.88e6 clock ticks. Since
  //   1e9 / 122.88e6 = 8.13802083333333... [ns]
  // is not a integer number. We need to use a fractional method:
  //   1e9 / 122.88e6 = (1 / 3) * (0x824 / 2^8) + (2 / 3) * (0x823 / 2^8)

  localparam logic [39:0] AdderConst0 = 40'h00000008_24;  // 8.140625
  localparam logic [39:0] AdderConst1 = 40'h00000008_23;  // 8.13671875
  localparam logic [39:0] AdderConst2 = AdderConst1 + AdderConst1;
  localparam logic [39:0] AdderConst3 = AdderConst0 + AdderConst1;

  //   -1e9 = 32'hC4653600
  localparam logic [39:0] AdderWrap = 40'hC4653600_00;
  //   -1e7 = 32'hC4653600
  // localparam logic [39:0] AdderWrap = 40'hFF676980_00;

  //   To ensure the nanosecond counter does not go equal or large than 1e9,
  //   we need wrap it.
  localparam logic [39:0] AdderConst0Wrap = AdderWrap + AdderConst0;
  localparam logic [39:0] AdderConst1Wrap = AdderWrap + AdderConst1;
  localparam logic [39:0] AdderConst2Wrap = AdderWrap + AdderConst2;
  localparam logic [39:0] AdderConst3Wrap = AdderWrap + AdderConst3;


  logic        load_ns;

  logic [ 1:0] ns_frac;

  logic [39:0] counter_ns;
  logic [39:0] counter_ns_pre;
  logic [39:0] counter_ns_adder;
  wire         unused_counter_ns_pre_frac = |counter_ns_pre[7:0];

  // logic        ns_wrap1;
  // logic        ns_wrap2;
  logic        ns_wrap;

  logic        ctrl_get_snap_cdc;
  logic        ctrl_get_send;
  logic        ctrl_get_rcv;

  logic        ctrl_set_valid_cdc;
  logic [47:0] ctrl_set_s_cdc;
  logic [31:0] ctrl_set_ns_cdc;

  logic        ctrl_adj_valid_cdc;
  logic [31:0] ctrl_adj_ns_cdc;

  wire         unused_ctrl_get_req;
  wire         unused_ctrl_set_rcv;
  wire         unused_ctrl_adj_rcv;


  // System Timer
  //-------------

  // The nanosecond counter

  always_ff @(posedge clk) begin
    if (rst || sync_in) begin
      ns_frac <= 0;
    end else if (~sample_inc[0]) begin
      ns_frac <= ns_frac;
    end else if (~sample_inc[1]) begin
      ns_frac <= (ns_frac + 1) % 3;
    end else begin
      ns_frac <= (ns_frac + 2) % 3;
    end
  end

  // Nano second counter @clk
  // Set a positive value advance the timer, set a negative value delay the timer
  always_ff @(posedge clk) begin
    if (rst || sync_in) begin
      counter_ns <= '0;
    end else if (ctrl_set_valid_cdc) begin
      counter_ns <= {ctrl_set_ns_cdc, 8'b0};
    end else if (load_ns && ns_wrap) begin
      counter_ns <= {ctrl_adj_ns_cdc, 8'b0};
    end else begin
      counter_ns <= counter_ns + counter_ns_adder;
    end
  end

  // counter_ns_adder
  always_comb begin
    if (~sample_inc[0]) begin
      counter_ns_adder = '0;
    end else if (~sample_inc[1]) begin
      if (~ns_wrap) begin
        counter_ns_adder = ns_frac == 0 ? AdderConst0 : AdderConst1;
      end else begin
        counter_ns_adder = ns_frac == 0 ? AdderConst0Wrap : AdderConst1Wrap;
      end
    end else begin  // sample_inc[1] == 1
      if (~ns_wrap) begin
        counter_ns_adder = ns_frac == 1 ? AdderConst2 : AdderConst3;
      end else begin
        counter_ns_adder = ns_frac == 1 ? AdderConst2Wrap : AdderConst3Wrap;
      end
    end
  end

  // counter_ns_pre
  always_comb begin
    if (~sample_inc[0]) begin
      counter_ns_pre = counter_ns;
    end else if (~sample_inc[1]) begin
      counter_ns_pre = counter_ns + (ns_frac == 0 ? AdderConst0 : AdderConst1);
    end else begin  // sample_inc[1] == 1
      counter_ns_pre = counter_ns + (ns_frac == 1 ? AdderConst2 : AdderConst3);
    end
  end

  // 1e9 = 32'h3B9ACA00
  assign ns_wrap =
   (counter_ns_pre[39:8] == 32'h3B9ACA00) || (counter_ns_pre[39:8] == 32'h3B9ACA01) ||
   (counter_ns_pre[39:8] == 32'h3B9ACA02) || (counter_ns_pre[39:8] == 32'h3B9ACA03) ||
   (counter_ns_pre[39:8] == 32'h3B9ACA04) || (counter_ns_pre[39:8] == 32'h3B9ACA05) ||
   (counter_ns_pre[39:8] == 32'h3B9ACA06) || (counter_ns_pre[39:8] == 32'h3B9ACA07) ||
   (counter_ns_pre[39:8] == 32'h3B9ACA08) || (counter_ns_pre[39:8] == 32'h3B9ACA09);

  // 1e7 = 32'h00989680
  // assign ns_wrap =
  //   (counter_ns_pre[39:8] == 32'h00989680) || (counter_ns_pre[39:8] == 32'h00989681) ||
  //   (counter_ns_pre[39:8] == 32'h00989682) || (counter_ns_pre[39:8] == 32'h00989683) ||
  //   (counter_ns_pre[39:8] == 32'h00989684) || (counter_ns_pre[39:8] == 32'h00989685) ||
  //   (counter_ns_pre[39:8] == 32'h00989686) || (counter_ns_pre[39:8] == 32'h00989687) ||
  //   (counter_ns_pre[39:8] == 32'h00989688) || (counter_ns_pre[39:8] == 32'h00989689);

  assign sync_out = ns_wrap;

  assign sys_timer_ns = counter_ns[39:8];

  // Second counter

  always_ff @(posedge clk) begin
    if (rst || sync_in) begin
      sys_timer_s <= '0;
    end else if (ctrl_set_valid_cdc) begin
      sys_timer_s <= ctrl_set_s_cdc;
    end else if (ns_wrap) begin
      sys_timer_s <= sys_timer_s + 1;
    end
  end


  // Timer CDC
  //----------

  pps_timer_cdc i_timer_cdc (
      .clk         (clk),
      .rst         (rst),
      // System timer
      .sys_timer_s (sys_timer_s),
      .sys_timer_ns(sys_timer_ns),
      // Ethernet
      //---------
      .eth_clk     (eth_clk),
      .eth_rst     (eth_rst),
      // Timer output
      .timer_s     (timer_s),
      .timer_ns    (timer_ns)
  );


  // PPS output
  //-----------

  always_ff @(posedge clk) begin
    pps_out <= sync_in || ns_wrap;
  end


  // Get Time
  //---------

`ifdef XILINX
  xpm_cdc_pulse #(
      .DEST_SYNC_FF  (2),
      .INIT_SYNC_FF  (0),
      .REG_OUTPUT    (0),
      .RST_USED      (1),
      .SIM_ASSERT_CHK(0)
  ) xpm_cdc_pulse_get (
      .src_clk   (ctrl_clk),
      .src_rst   (ctrl_rst),
      .src_pulse (ctrl_get_snap),
      //
      .dest_clk  (clk),
      .dest_rst  (rst),
      .dest_pulse(ctrl_get_snap_cdc)
  );
`else
  cdc_pulse #(
      .DEST_SYNC_FF(2),
      .INIT_SYNC_FF(1'b0),
      .REG_OUTPUT  (1'b0),
      .RST_USED    (1'b1)
  ) i_cdc_pulse_get (
      .src_clk   (ctrl_clk),
      .src_rst   (ctrl_rst),
      .src_pulse (ctrl_get_snap),
      .dest_clk  (clk),
      .dest_rst  (rst),
      .dest_pulse(ctrl_get_snap_cdc)
  );
`endif

`ifdef XILINX
  xpm_cdc_handshake #(
      .DEST_EXT_HSK  (0),
      .DEST_SYNC_FF  (2),
      .INIT_SYNC_FF  (0),
      .SIM_ASSERT_CHK(0),
      .SRC_SYNC_FF   (2),
      .WIDTH         (80)
  ) xpm_cdc_handshake_get (
      .src_clk (clk),
      .src_in  ({sys_timer_s, sys_timer_ns}),
      .src_send(ctrl_get_send),
      .src_rcv (ctrl_get_rcv),
      //
      .dest_clk(ctrl_clk),
      .dest_out({ctrl_get_s, ctrl_get_ns}),
      .dest_req(unused_ctrl_get_req),
      .dest_ack(1'b1)
  );
`else
  cdc_handshake_f #(
      .DEST_EXT_HSK(1'b0),
      .DEST_SYNC_FF(2),
      .INIT_SYNC_FF(1'b0),
      .SRC_SYNC_FF (2),
      .WIDTH       (80)
  ) i_cdc_handshake_get (
      .src_clk   (clk),
      .src_in    ({sys_timer_s, sys_timer_ns}),
      .src_valid (ctrl_get_send),
      .src_ready (ctrl_get_rcv),
      .dest_clk  (ctrl_clk),
      .dest_out  ({ctrl_get_s, ctrl_get_ns}),
      .dest_valid(unused_ctrl_get_req),
      .dest_ready(1'b1)
  );
`endif

  always_ff @(posedge clk) begin
    if (rst) begin
      ctrl_get_send <= 1'b0;
    end else if (ctrl_get_snap_cdc) begin
      ctrl_get_send <= 1'b1;
    end else if (ctrl_get_rcv) begin
      ctrl_get_send <= 1'b0;
    end
  end


  // Set Time
  //---------

`ifdef XILINX
  xpm_cdc_handshake #(
      .DEST_EXT_HSK  (0),
      .DEST_SYNC_FF  (2),
      .INIT_SYNC_FF  (0),
      .SIM_ASSERT_CHK(0),
      .SRC_SYNC_FF   (2),
      .WIDTH         (80)
  ) xpm_cdc_handshake_set (
      .src_clk (ctrl_clk),
      .src_in  ({ctrl_set_s, ctrl_set_ns}),
      .src_send(ctrl_set_valid),
      .src_rcv (unused_ctrl_set_rcv),
      //
      .dest_clk(clk),
      .dest_out({ctrl_set_s_cdc, ctrl_set_ns_cdc}),
      .dest_req(ctrl_set_valid_cdc),
      .dest_ack(1'b1)
  );
`else
  cdc_handshake_f #(
      .DEST_EXT_HSK(1'b0),
      .DEST_SYNC_FF(2),
      .INIT_SYNC_FF(1'b0),
      .SRC_SYNC_FF (2),
      .WIDTH       (80)
  ) i_cdc_handshake_set (
      .src_clk   (ctrl_clk),
      .src_in    ({ctrl_set_s, ctrl_set_ns}),
      .src_valid (ctrl_set_valid),
      .src_ready (unused_ctrl_set_rcv),
      .dest_clk  (clk),
      .dest_out  ({ctrl_set_s_cdc, ctrl_set_ns_cdc}),
      .dest_valid(ctrl_set_valid_cdc),
      .dest_ready(1'b1)
  );
`endif


  // Adjust Time
  //------------

`ifdef XILINX
  xpm_cdc_handshake #(
      .DEST_EXT_HSK  (0),
      .DEST_SYNC_FF  (2),
      .INIT_SYNC_FF  (0),
      .SIM_ASSERT_CHK(0),
      .SRC_SYNC_FF   (2),
      .WIDTH         (32)
  ) xpm_cdc_handshake_adj (
      .src_clk (ctrl_clk),
      .src_in  (ctrl_adj_ns),
      .src_send(ctrl_adj_valid),
      .src_rcv (unused_ctrl_adj_rcv),
      //
      .dest_clk(clk),
      .dest_out(ctrl_adj_ns_cdc),
      .dest_req(ctrl_adj_valid_cdc),
      .dest_ack(1'b1)
  );
`else
  cdc_handshake_f #(
      .DEST_EXT_HSK(1'b0),
      .DEST_SYNC_FF(2),
      .INIT_SYNC_FF(1'b0),
      .SRC_SYNC_FF (2),
      .WIDTH       (32)
  ) i_cdc_handshake_adj (
      .src_clk   (ctrl_clk),
      .src_in    (ctrl_adj_ns),
      .src_valid (ctrl_adj_valid),
      .src_ready (unused_ctrl_adj_rcv),
      .dest_clk  (clk),
      .dest_out  (ctrl_adj_ns_cdc),
      .dest_valid(ctrl_adj_valid_cdc),
      .dest_ready(1'b1)
  );
`endif

  always_ff @(posedge clk) begin
    if (rst) begin
      load_ns <= 1'b0;
    end else if (ctrl_adj_valid_cdc) begin
      load_ns <= 1'b1;
    end else if (ns_wrap) begin
      load_ns <= 1'b0;
    end
  end

endmodule

`default_nettype wire
