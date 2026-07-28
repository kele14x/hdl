`timescale 1 ns / 1 ps
//
`default_nettype none

module puxch_top #(
    parameter int NUM_CC     = 3,
    parameter int NUM_ANT    = 4,
    parameter bit HAS_BFP    = 1'b1,
    parameter bit HALF_BLOCK = 1'b0
) (
    // Clock & Reset
    //--------------
    input  wire        clk,
    input  wire        rst,
    //
    input  wire [31:0] s_axis_tdata         [ NUM_CC][NUM_ANT],
    input  wire [ 7:0] s_axis_tuser         [ NUM_CC][NUM_ANT],
    input  wire        s_axis_tlast         [ NUM_CC][NUM_ANT],
    input  wire        s_axis_tvalid        [ NUM_CC][NUM_ANT],
    output wire        s_axis_tready        [ NUM_CC][NUM_ANT],
    // O-RAN U-Plane
    //--------------
    input  wire        clk_eth_xran,
    input  wire        rst_eth_xran,
    //
    input  wire        sync_in,
    //
    output wire        fram_radio_start_10ms[ NUM_CC],
    input  wire [11:0] s_ul_sym_num         [ NUM_CC],
    //
    output wire [63:0] m_fram_data_tdata    [NUM_ANT],
    output wire [ 7:0] m_fram_data_tkeep    [NUM_ANT],
    output wire        m_fram_data_tvalid   [NUM_ANT],
    output wire        m_fram_data_tlast    [NUM_ANT],
    input  wire        m_fram_data_tready   [NUM_ANT],
    input  wire [32:0] m_fram_data_req      [NUM_ANT],
    // CSR
    //----
    input  wire        ctrl_clk,
    input  wire        ctrl_rst,
    //
    input  wire [ 3:0] ctrl_ud_comp_meth,
    input  wire [ 3:0] ctrl_ud_iq_width,
    input  wire [ 3:0] ctrl_fs_offset,
    // 0 = diable, 1 = enable
    input  wire [ 3:0] ctrl_en              [ NUM_CC],
    // 0 = LTE, 1 = NR 15kHz, 2 = NR 30kHz
    input  wire [ 1:0] ctrl_rat             [ NUM_CC],
    // 0 = diable, 1 = enable
    input  wire [ 3:0] ctrl_bist            [ NUM_CC],
    // 0 = 5, 1 = 10, 2 = 15/20/25, 3 = 30/40/50
    input  wire [ 3:0] ctrl_bw              [ NUM_CC],
    input  wire [ 8:0] ctrl_nprb            [ NUM_CC],
    // 1 = 2.5 ns
    input  wire [22:0] ctrl_rfs_offset      [ NUM_CC],
    // 0x4000 = 0 dB
    input  wire [16:0] ctrl_gain            [ NUM_CC][NUM_ANT],
    // addr = {[5:4]cc, [3:0]symbol}
    input  wire [ 5:0] ctrl_phase_comp_addr,
    input  wire        ctrl_phase_comp_en,
    input  wire        ctrl_phase_comp_we,
    input  wire [31:0] ctrl_phase_comp_din,
    output wire [31:0] ctrl_phase_comp_dout,
    output reg         ctrl_phase_comp_valid
);

  logic [15:0] dout_dr             [ NUM_CC];
  logic [15:0] dout_di             [ NUM_CC];
  logic        dout_sf             [ NUM_CC];
  logic        dout_sl             [ NUM_CC];
  logic        dout_sy             [ NUM_CC];
  logic [ 3:0] dout_chn            [ NUM_CC];
  logic        dout_dv             [ NUM_CC];
  logic        dout_last           [ NUM_CC];

  logic        ctrl_phase_comp_we_s[ NUM_CC];

  wire  [63:0] s0_axis_tdata       [NUM_ANT];
  wire  [ 7:0] s0_axis_tkeep       [NUM_ANT];
  wire         s0_axis_tvalid      [NUM_ANT];
  wire         s0_axis_tlast       [NUM_ANT];
  wire         s0_axis_tready      [NUM_ANT];
  wire  [31:0] bfp_m_axis_tuser    [NUM_ANT];

  generate
    for (genvar cc = 0; cc < NUM_CC; cc++) begin : g_cc

      puxch_channel #(
          .NUM_ANT(NUM_ANT)
      ) u_channel (
          .clk                  (clk),
          .rst                  (rst),
          //
          .s_axis_tdata         (s_axis_tdata[cc]),
          .s_axis_tuser         (s_axis_tuser[cc]),
          .s_axis_tlast         (s_axis_tlast[cc]),
          .s_axis_tvalid        (s_axis_tvalid[cc]),
          .s_axis_tready        (s_axis_tready[cc]),
          //
          .dout_dr              (dout_dr[cc]),
          .dout_di              (dout_di[cc]),
          .dout_sf              (dout_sf[cc]),
          .dout_sl              (dout_sl[cc]),
          .dout_sy              (dout_sy[cc]),
          .dout_chn             (dout_chn[cc]),
          .dout_dv              (dout_dv[cc]),
          .dout_last            (dout_last[cc]),
          //
          .clk_eth_xran         (clk_eth_xran),
          .rst_eth_xran         (rst_eth_xran),
          //
          .sync_in              (sync_in),
          //
          .fram_radio_start_10ms(fram_radio_start_10ms[cc]),
          // CSR
          .ctrl_clk             (ctrl_clk),
          .ctrl_rst             (ctrl_rst),
          //
          .ctrl_en              (ctrl_en[cc]),
          .ctrl_rat             (ctrl_rat[cc]),
          .ctrl_bist            (ctrl_bist[cc]),
          .ctrl_bw              (ctrl_bw[cc]),
          .ctrl_nprb            (ctrl_nprb[cc]),
          .ctrl_rfs_offset      (ctrl_rfs_offset[cc]),
          //
          .ctrl_gain            (ctrl_gain[cc]),
          //
          .ctrl_phase_comp_addr (ctrl_phase_comp_addr[3:0]),
          .ctrl_phase_comp_we   (ctrl_phase_comp_we_s[cc]),
          .ctrl_phase_comp_din  (ctrl_phase_comp_din)
      );

      // addr = {[5:4]cc, [3:0]symbol}
      assign ctrl_phase_comp_we_s[cc] = ctrl_phase_comp_we && (ctrl_phase_comp_addr[5:4] == cc);

    end
  endgenerate

  generate
    for (genvar ant = 0; ant < NUM_ANT; ant++) begin : g_ant

      puxch_buffer #(
          .ID        (ant),
          .NUM_CC    (NUM_CC),
          .HALF_BLOCK(HALF_BLOCK)
      ) u_buffer (
          .clk            (clk),
          .rst            (rst),
          //
          .din_dr         (dout_dr),
          .din_di         (dout_di),
          .din_sf         (dout_sf),
          .din_sl         (dout_sl),
          .din_sy         (dout_sy),
          .din_chn        (dout_chn),
          .din_dv         (dout_dv),
          //
          .clk_eth_xran   (clk_eth_xran),
          .rst_eth_xran   (rst_eth_xran),
          //
          .s_ul_sym_num   (s_ul_sym_num),
          //
          .m_axis_tdata   (s0_axis_tdata[ant]),
          .m_axis_tkeep   (s0_axis_tkeep[ant]),
          .m_axis_tvalid  (s0_axis_tvalid[ant]),
          .m_axis_tlast   (s0_axis_tlast[ant]),
          .m_axis_tready  (s0_axis_tready[ant]),
          //
          .m_fram_data_req(m_fram_data_req[ant]),
          //
          .ctrl_rat       (ctrl_rat),
          .ctrl_bw        (ctrl_bw)
      );

      if (HAS_BFP) begin : g_bfp

        bfp_comp #(
            .BYTE_REVERSE(1'b1)
        ) u_bfp_comp (
            .clk              (clk_eth_xran),
            .rst              (rst_eth_xran),
            //
            .s_axis_tdata     (s0_axis_tdata[ant]),
            .s_axis_tkeep     (s0_axis_tkeep[ant]),
            .s_axis_tvalid    (s0_axis_tvalid[ant]),
            .s_axis_tlast     (s0_axis_tlast[ant]),
            .s_axis_tuser     ('0),
            //
            .m_axis_tdata     (m_fram_data_tdata[ant]),
            .m_axis_tkeep     (m_fram_data_tkeep[ant]),
            .m_axis_tvalid    (m_fram_data_tvalid[ant]),
            .m_axis_tlast     (m_fram_data_tlast[ant]),
            .m_axis_tuser     (bfp_m_axis_tuser[ant]),
            // Control
            //--------
            .ctrl_ud_comp_meth(ctrl_ud_comp_meth),
            .ctrl_ud_iq_width (ctrl_ud_iq_width),
            .ctrl_fs_offset   (ctrl_fs_offset)
        );

        assign s0_axis_tready[ant] = m_fram_data_tready[ant];

      end else begin : g_no_bfp

        assign m_fram_data_tdata[ant] = s0_axis_tdata[ant];
        assign m_fram_data_tkeep[ant] = s0_axis_tkeep[ant];
        assign m_fram_data_tvalid[ant] = s0_axis_tvalid[ant];
        assign m_fram_data_tlast[ant] = s0_axis_tlast[ant];

        assign s0_axis_tready[ant] = m_fram_data_tready[ant];

      end
    end
  endgenerate

  // PhaseComp RAM read back, read latency = 1
  ram_sp #(
      .ADDR_WIDTH  (6),
      .DATA_WIDTH  (32),
      .WRITE_MODE  ("READ_FIRST"),
      .READ_LATENCY(1),
      .INIT_WORD   (32'h4000),
      .INIT_FILE   ("")
  ) u_phase_comp_ram (
      .clk (ctrl_clk),
      .rst (ctrl_rst),
      //
      .en  (ctrl_phase_comp_en),
      .we  (ctrl_phase_comp_we),
      .addr(ctrl_phase_comp_addr),
      .din (ctrl_phase_comp_din),
      .dout(ctrl_phase_comp_dout)
  );

  always_ff @(posedge ctrl_clk) begin
    ctrl_phase_comp_valid <= ctrl_phase_comp_en;
  end

  wire unused_top = &{1'b0, dout_last, bfp_m_axis_tuser};

endmodule

`default_nettype wire
