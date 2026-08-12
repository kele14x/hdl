// File: pps_timer_cdc.sv
// Brief: 80-bit Real Time Counter CDC.
`timescale 1 ns / 1 ps
//
`default_nettype none

module pps_timer_cdc (
    // System
    //-------
    input var         clk,
    input var         rst,
    // System timer
    input var  [47:0] sys_timer_s,
    input var  [31:0] sys_timer_ns,
    // Ethernet
    //---------
    input var         eth_clk,
    input var         eth_rst,
    // Timer output
    output var [47:0] timer_s,
    output var [31:0] timer_ns
);

  // The clock frequency is assumed 312.5 MHz, each clock has period of
  //   1e9 / 312.5e6 = 3.2 [ns]
  // is not a integer number. We need to use a fractional method:
  //   1e9 / 312.5e6 = (1 / 5) * (0x824 / 2^8) + (4 / 5) * (0x823 / 2^8)
  localparam logic [5:0] AdderConst0 = 6'h3_4;  // 3.25
  localparam logic [5:0] AdderConst1 = 6'h3_3;  // 3.1875

  // CDC
  //----

  // Use xpm_cdc_handshake to continue moves the system counter (s + ns) to
  // Ethernet clock domain

  logic [79:0] src_in;
  logic        src_send;
  logic        src_rcv;

  logic [79:0] dest_out;
  logic        dest_req;

  logic [47:0] sys_timer_s_sync;
  logic [31:0] sys_timer_ns_sync;


  assign src_in = {sys_timer_s, sys_timer_ns};

  // This make the xpm_cdc_handshake continues transfer data
  always_ff @(posedge clk) begin
    if (rst) begin
      src_send <= 1'b0;
    end else begin
      src_send <= ~src_rcv;
    end
  end

`ifdef XILINX
  xpm_cdc_handshake #(
      .DEST_EXT_HSK  (0),
      .DEST_SYNC_FF  (2),
      .INIT_SYNC_FF  (0),
      .SIM_ASSERT_CHK(0),
      .SRC_SYNC_FF   (2),
      .WIDTH         (80)
  ) xpm_cdc_handshake_ts (
      .src_clk (clk),
      .src_in  (src_in),
      .src_send(src_send),
      .src_rcv (src_rcv),
      //
      .dest_clk(eth_clk),
      .dest_out(dest_out),
      .dest_ack(1'b1),
      .dest_req(dest_req)
  );
`else
  cdc_handshake_f #(
      .DEST_EXT_HSK(0),
      .DEST_SYNC_FF(2),
      .INIT_SYNC_FF(0),
      .SRC_SYNC_FF (2),
      .WIDTH       (80)
  ) i_cdc_handshake_ts (
      .src_clk   (clk),
      .src_in    (src_in),
      .src_valid (src_send),
      .src_ready (src_rcv),
      .dest_clk  (eth_clk),
      .dest_out  (dest_out),
      .dest_valid(dest_req),
      .dest_ready(1'b1)
  );
`endif

  // Split sync 80-bit to ns and s

  assign {sys_timer_s_sync, sys_timer_ns_sync} = dest_out;


  // Local counter
  //--------------

  logic [ 2:0] counter_ns_frac;
  logic [35:0] counter_ns;
  logic [47:0] counter_s;

  logic        ns_overflow;


  always_ff @(posedge eth_clk) begin
    if (eth_rst) begin
      counter_ns_frac <= '0;
    end else if (counter_ns_frac == 0) begin
      counter_ns_frac <= 1;
    end else if (counter_ns_frac == 1) begin
      counter_ns_frac <= 2;
    end else if (counter_ns_frac == 2) begin
      counter_ns_frac <= 3;
    end else if (counter_ns_frac == 3) begin
      counter_ns_frac <= 4;
    end else begin
      counter_ns_frac <= 0;
    end
  end

  always_ff @(posedge eth_clk) begin
    if (eth_rst) begin
      counter_ns <= '0;
    end else if (dest_req) begin
      counter_ns <= {sys_timer_ns_sync, 4'b0};
    end else if (ns_overflow) begin
      counter_ns <= '0;
    end else if (counter_ns_frac == 0) begin
      counter_ns <= counter_ns + {30'd0, AdderConst0};
    end else begin
      counter_ns <= counter_ns + {30'd0, AdderConst1};
    end
  end

  // The nanosecond counter is about to wrap
  // 1e9 - 3.x
  assign ns_overflow = (counter_ns[35:4] == 32'h3B9AC9FC) ||
    (counter_ns[35:4] == 32'h3B9AC9FD) ||
    (counter_ns[35:4] == 32'h3B9AC9FE) ||
    (counter_ns[35:4] == 32'h3B9AC9FF);

  always_ff @(posedge eth_clk) begin
    if (eth_rst) begin
      counter_s <= '0;
    end else if (dest_req) begin
      counter_s <= sys_timer_s_sync;
    end else if (ns_overflow) begin
      counter_s <= counter_s + 1;
    end
  end

  assign timer_s  = counter_s;
  assign timer_ns = counter_ns[35:4];

endmodule

`default_nettype wire
