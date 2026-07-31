// File: pps_top.sv
// Brief: Integrated PTP timer and symbol timer. It provides a PTP
//        hardware clock (PHC) with 80-bit second/nanosecond interface, and
//        symbol timer for RU function.
`timescale 1 ns / 1 ps
//
`default_nettype none

module pps_top #(
    parameter int FREQUENCY = 1
) (
    // AXI
    //----
    input var         s_axi_aclk,
    input var         s_axi_aresetn,
    //
    input var  [31:0] s_axi_awaddr,
    input var  [ 2:0] s_axi_awprot,
    input var         s_axi_awvalid,
    output var        s_axi_awready,
    //
    input var  [31:0] s_axi_wdata,
    input var  [ 3:0] s_axi_wstrb,
    input var         s_axi_wvalid,
    output var        s_axi_wready,
    //
    output var [ 1:0] s_axi_bresp,
    output var        s_axi_bvalid,
    input var         s_axi_bready,
    //
    input var  [31:0] s_axi_araddr,
    input var  [ 2:0] s_axi_arprot,
    input var         s_axi_arvalid,
    output var        s_axi_arready,
    //
    output var [31:0] s_axi_rdata,
    output var [ 1:0] s_axi_rresp,
    output var        s_axi_rvalid,
    input var         s_axi_rready,
    // PAD
    //----
    input var         pps_in,
    output var        pps_out_pad,
    // System
    //-------
    input var         clk,
    input var         rst,
    // System Timer
    output var [47:0] sys_timer_s,
    output var [31:0] sys_timer_ns,
    // PPS output
    output var        pps_out,
    // 10ms strobe output
    output var        raw_10ms_strobe,
    output var        dl_10ms_strobe,
    output var        ul_10ms_strobe,
    output var        air_intface_10ms,
    //
    output var        start_of_frame,
    output var        start_of_symbol,
    output var [32:0] start_of_symbol_frac,
    // Ethernet
    //---------
    input var         eth_clk,
    input var         eth_clk2x,
    input var         eth_rst,
    // Timer output
    output var [47:0] timer_s,
    output var [31:0] timer_ns,
    // Timestamp
    input var  [31:0] ts_t1,
    input var  [31:0] ts_t2,
    input var         ts_valid
);

  logic        ctrl_clk;
  logic        ctrl_rst;

  logic        ctrl_soft_reset;

  logic        ctrl_adj_valid;
  logic [31:0] ctrl_adj_ns;

  logic [31:0] ctrl_freq;

  logic        ctrl_get_snap;
  logic [47:0] ctrl_get_s;
  logic [31:0] ctrl_get_ns;

  logic        ctrl_set_valid;
  logic [47:0] ctrl_set_s;
  logic [31:0] ctrl_set_ns;

  logic [22:0] ctrl_dl_offset;
  logic [22:0] ctrl_ul_offset;

  wire         unused_axi_addr = |{s_axi_awaddr[31:7], s_axi_araddr[31:7]};

  logic [31:0] stat_pps_offset;

  logic [31:0] stat_ts_cnt;
  logic [47:0] stat_ts_offset;

  logic        rst_int;
  logic        sync_int;
  logic        sync_from_pps;

  logic [ 1:0] sample_inc;
  logic [32:0] sample_frac;

  logic        pps_out_cdc;

  logic        start_of_frame_s;
  logic        start_of_symbol_s;
  logic [32:0] start_of_symbol_frac_s;


  // Main
  //-----

  assign ctrl_clk = s_axi_aclk;
  assign ctrl_rst = ~s_axi_aresetn;


  pps_top_regs i_regs (
      .s_axi_aclk        (s_axi_aclk),
      .s_axi_aresetn     (s_axi_aresetn),
      //
      .s_axi_awaddr      (s_axi_awaddr[6:0]),
      .s_axi_awprot      (s_axi_awprot),
      .s_axi_awvalid     (s_axi_awvalid),
      .s_axi_awready     (s_axi_awready),
      //
      .s_axi_wdata       (s_axi_wdata),
      .s_axi_wstrb       (s_axi_wstrb),
      .s_axi_wvalid      (s_axi_wvalid),
      .s_axi_wready      (s_axi_wready),
      //
      .s_axi_bresp       (s_axi_bresp),
      .s_axi_bvalid      (s_axi_bvalid),
      .s_axi_bready      (s_axi_bready),
      //
      .s_axi_araddr      (s_axi_araddr[6:0]),
      .s_axi_arprot      (s_axi_arprot),
      .s_axi_arvalid     (s_axi_arvalid),
      .s_axi_arready     (s_axi_arready),
      //
      .s_axi_rdata       (s_axi_rdata),
      .s_axi_rresp       (s_axi_rresp),
      .s_axi_rvalid      (s_axi_rvalid),
      .s_axi_rready      (s_axi_rready),
      // ctrl.rst,
      .ctrl_rst_out      (ctrl_soft_reset),
      // adj_ns.val,
      .adj_ns_val_out    (ctrl_adj_ns),
      // adj_valid.val,
      .adj_valid_val_out (ctrl_adj_valid),
      // freq.val,
      .freq_val_out      (ctrl_freq),
      // gettime.sh.val,
      .gettime_sh_val_in (ctrl_get_s[47:32]),
      // gettime.sl.val,
      .gettime_sl_val_in (ctrl_get_s[31:0]),
      // gettime.ns.val,
      .gettime_ns_val_in (ctrl_get_ns),
      // gettime.v.val,
      .gettime_v_val_out (ctrl_get_snap),
      // settime.sh.val,
      .settime_sh_val_out(ctrl_set_s[47:32]),
      // settime.sl.val,
      .settime_sl_val_out(ctrl_set_s[31:0]),
      // settime.ns.val,
      .settime_ns_val_out(ctrl_set_ns),
      // settime.v.val,
      .settime_v_val_out (ctrl_set_valid),
      // pps_offset.val,
      .pps_offset_val_in (stat_pps_offset),
      // ts_cnt.val,
      .ts_cnt_val_in     (stat_ts_cnt),
      // ts_offset.val,
      .ts_offset_l_val_in(stat_ts_offset[31:0]),
      // ts_offset_h.val,
      .ts_offset_h_val_in(stat_ts_offset[47:32])
  );

  pps_counter i_counter (
      // System
      //-------
      .clk        (clk),
      .rst        (rst | ctrl_soft_reset),
      //
      .rst_int    (rst_int),
      .sync_int   (sync_int),
      //
      .sample_inc (sample_inc),
      .sample_frac(sample_frac),
      // CSR
      //----
      .ctrl_clk   (ctrl_clk),
      .ctrl_rst   (ctrl_rst),
      //
      .ctrl_freq  (ctrl_freq)
  );

  // Second & Nanosecond Timer
  // 80-bit timer should be write to eth_clk2x (312.5 MHz)
  pps_timer i_timer (
      // System
      //-------
      .clk           (clk),
      .rst           (rst_int),
      //
      .sync_in       (sync_int),
      .sync_out      (sync_from_pps),
      //
      .sample_inc    (sample_inc),
      //
      .pps_out       (pps_out),
      //
      .sys_timer_s   (sys_timer_s),
      .sys_timer_ns  (sys_timer_ns),
      // Ethernet
      //---------
      .eth_clk       (eth_clk2x),
      .eth_rst       (eth_rst),
      //
      .timer_s       (timer_s),
      .timer_ns      (timer_ns),
      // CSR
      //----
      .ctrl_clk      (ctrl_clk),
      .ctrl_rst      (ctrl_rst),
      //
      .ctrl_get_snap (ctrl_get_snap),
      .ctrl_get_s    (ctrl_get_s),
      .ctrl_get_ns   (ctrl_get_ns),
      //
      .ctrl_set_valid(ctrl_set_valid),
      .ctrl_set_s    (ctrl_set_s),
      .ctrl_set_ns   (ctrl_set_ns),
      //
      .ctrl_adj_valid(ctrl_adj_valid),
      .ctrl_adj_ns   (ctrl_adj_ns)
  );

  // Symbol Timer
  pps_symbol_timer #(
      .FREQUENCY(FREQUENCY)
  ) i_symbol_timer (
      .clk                 (clk),
      .rst                 (rst_int),
      //
      .sync_in             (sync_int | sync_from_pps),
      //
      .sample_inc          (sample_inc),
      .sample_frac         (sample_frac),
      //
      .start_of_frame      (start_of_frame_s),
      .start_of_symbol     (start_of_symbol_s),
      .start_of_symbol_frac(start_of_symbol_frac_s)
  );

  pps_resync i_resync (
      .clk     (clk),
      .rst     (rst_int),
      //
      .in_sof  (start_of_frame_s),
      .in_sos  (start_of_symbol_s),
      .in_frac (start_of_symbol_frac_s),
      //
      .out_sof (start_of_frame),
      .out_sos (start_of_symbol),
      .out_frac(start_of_symbol_frac)
  );

  pps_expand i_expand (
      .clk        (clk),
      .rst        (rst_int),
      .pps_in     (pps_out),
      .pps_out_pad(pps_out_pad)
  );

  // Check input 1PPS and generate internal 1PPS
  pps_checker i_checker (
      .clk            (clk),
      .rst            (rst_int),
      //
      .pps_in         (pps_in),
      //
      .sys_timer_ns   (sys_timer_ns),
      // CSR
      //----
      .ctrl_clk       (ctrl_clk),
      //
      .stat_pps_offset(stat_pps_offset)
  );

`ifdef XILINX
  xpm_cdc_pulse #(
      .DEST_SYNC_FF  (2),
      .INIT_SYNC_FF  (0),
      .REG_OUTPUT    (1),
      .RST_USED      (1),
      .SIM_ASSERT_CHK(0)
  ) xpm_cdc_pulse_pps (
      .src_clk   (clk),
      .src_rst   (rst_int),
      .src_pulse (pps_out),
      //
      .dest_clk  (eth_clk),
      .dest_rst  (eth_rst),
      .dest_pulse(pps_out_cdc)
  );
`else
  cdc_pulse #(
      .DEST_SYNC_FF(2),
      .INIT_SYNC_FF(1'b0),
      .REG_OUTPUT  (1'b1),
      .RST_USED    (1'b1)
  ) i_cdc_pulse_pps (
      .src_clk   (clk),
      .src_rst   (rst_int),
      .src_pulse (pps_out),
      .dest_clk  (eth_clk),
      .dest_rst  (eth_rst),
      .dest_pulse(pps_out_cdc)
  );
`endif

  pps_ts_checker i_ts_checker (
      .clk           (eth_clk),
      .rst           (eth_rst),
      //
      .pps_in        (pps_out_cdc),
      //
      .ts_t1         (ts_t1),
      .ts_t2         (ts_t2),
      .ts_valid      (ts_valid),
      // CSR
      //----
      .ctrl_clk      (ctrl_clk),
      //
      .stat_ts_cnt   (stat_ts_cnt),
      .stat_ts_offset(stat_ts_offset)
  );

  assign raw_10ms_strobe = start_of_frame;
  assign ctrl_dl_offset  = 23'd0;
  assign ctrl_ul_offset  = 23'd0;

  pps_delay i_dl (
      .clk        (clk),
      .rst        (rst_int),
      .sync_in    (start_of_frame),
      .strobe_10ms(dl_10ms_strobe),
      .ctrl_offset(ctrl_dl_offset)
  );

  pps_delay i_ul (
      .clk        (clk),
      .rst        (rst_int),
      .sync_in    (start_of_frame),
      .strobe_10ms(ul_10ms_strobe),
      .ctrl_offset(ctrl_ul_offset)
  );

  pps_delay i_arp (
      .clk        (clk),
      .rst        (rst_int),
      .sync_in    (start_of_frame),
      .strobe_10ms(air_intface_10ms),
      .ctrl_offset(23'd200)
  );

endmodule

`default_nettype wire
