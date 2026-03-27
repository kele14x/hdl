`timescale 1 ns / 1 ps
//
`default_nettype none

module pdxch_top #(
    parameter int NUM_CC     = 3,
    parameter int NUM_ANT    = 4,
    parameter bit HAS_BFP    = 1'b1,
    parameter bit HALF_BLOCK = 1'b0
) (
    // Radio I/F
    //----------
    input  wire        clk,
    input  wire        rst,
    //
    output wire [31:0] m_axis_tdata         [ NUM_CC][NUM_ANT],
    output wire [ 7:0] m_axis_tuser         [ NUM_CC][NUM_ANT],
    output wire        m_axis_tlast         [ NUM_CC][NUM_ANT],
    output wire        m_axis_tvalid        [ NUM_CC][NUM_ANT],
    input  wire        m_axis_tready        [ NUM_CC][NUM_ANT],
    // O-RAN
    //------
    input  wire        clk_eth_xran,
    input  wire        rst_eth_xran,
    //
    input  wire        sync_in,
    //
    output wire        defm_radio_start_10ms[ NUM_CC],
    input  wire [11:0] s_dl_sym_num         [ NUM_CC],
    // U-Plane
    input  wire [63:0] s_defm_data_tdata    [NUM_ANT],
    input  wire [ 7:0] s_defm_data_tkeep    [NUM_ANT],
    input  wire        s_defm_data_tvalid   [NUM_ANT],
    input  wire        s_defm_data_tlast    [NUM_ANT],
    output wire        s_defm_data_tready   [NUM_ANT],
    input  wire [90:0] s_defm_data_tuser    [NUM_ANT],
    input  wire [ 4:0] s_defm_data_tdest    [NUM_ANT],
    // CSR
    //----
    input  wire        ctrl_clk,
    input  wire        ctrl_rst,
    //
    input  wire [ 3:0] ctrl_ud_comp_meth,
    input  wire [ 3:0] ctrl_ud_iq_width,
    input  wire [ 3:0] ctrl_fs_offset,
    // 0 = disable, 1 = enable
    input  wire [ 3:0] ctrl_en              [ NUM_CC],
    // 0 = LTE, 1 = NR 15kHz, 2 = NR 30kHz
    input  wire [ 1:0] ctrl_rat             [ NUM_CC],
    // 0 = disable, 1 = enable
    input  wire [ 3:0] ctrl_bist            [ NUM_CC],
    // 0 = 5, 1 = 10, 2 = 15/20/25, 3 = 30/40/50, 4 = 60/70/80/90/100
    input  wire [ 3:0] ctrl_bw              [ NUM_CC],
    input  wire [ 8:0] ctrl_nprb            [ NUM_CC],
    // 1 = 4.069 ns
    input  wire [22:0] ctrl_rfs_offset      [ NUM_CC],
    // 0x4000 = 0 dB
    input  wire [16:0] ctrl_gain            [ NUM_CC][NUM_ANT],
    // addr = {cc[5:4], symbol[3:0]}
    input  wire [ 5:0] ctrl_phase_comp_addr,
    input  wire        ctrl_phase_comp_en,
    input  wire        ctrl_phase_comp_we,
    input  wire [31:0] ctrl_phase_comp_din,
    output wire [31:0] ctrl_phase_comp_dout,
    output wire        ctrl_phase_comp_valid
);

  // Signals

  logic         ctrl_phase_comp_we_s [ NUM_CC];
  logic         ctrl_phase_comp_en_d;

  logic         s0_cnt               [NUM_ANT];

  logic [127:0] s0_axis_tdata        [NUM_ANT];
  logic [ 15:0] s0_axis_tkeep        [NUM_ANT];
  logic         s0_axis_tvalid       [NUM_ANT];
  logic         s0_axis_tlast        [NUM_ANT];
  logic [ 90:0] s0_axis_tuser        [NUM_ANT];

  logic [ 15:0] fdv_dout_dr          [ NUM_CC];
  logic [ 15:0] fdv_dout_di          [ NUM_CC];
  logic         fdv_dout_sf          [ NUM_CC];
  logic         fdv_dout_sl          [ NUM_CC];
  logic         fdv_dout_sy          [ NUM_CC];
  logic [  3:0] fdv_dout_chn         [ NUM_CC];
  logic         fdv_dout_dv          [ NUM_CC];
  logic         fdv_dout_last        [ NUM_CC];

  // Main

  generate
    for (genvar ant = 0; ant < NUM_ANT; ant++) begin : g_ant
      if (HAS_BFP) begin : g_bfp

        // BFP Decompress, with 128-bit output
        bfp_decomp #(
            .BYTE_REVERSE(1),
            .USER_WIDTH  (91)
        ) u_bfp_decomp (
            .clk                 (clk_eth_xran),
            .rst                 (rst_eth_xran),
            //
            .s_axis_tdata        (s_defm_data_tdata[ant]),
            .s_axis_tkeep        (s_defm_data_tkeep[ant]),
            .s_axis_tvalid       (s_defm_data_tvalid[ant]),
            .s_axis_tlast        (s_defm_data_tlast[ant]),
            .s_axis_tready       (s_defm_data_tready[ant]),
            .s_axis_tuser        (s_defm_data_tuser[ant]),
            //
            .m_axis_tdata        (s0_axis_tdata[ant]),
            .m_axis_tkeep        (s0_axis_tkeep[ant]),
            .m_axis_tvalid       (s0_axis_tvalid[ant]),
            .m_axis_tlast        (s0_axis_tlast[ant]),
            .m_axis_tuser        (s0_axis_tuser[ant]),
            // CSR
            .ctrl_ud_comp_meth   (ctrl_ud_comp_meth),
            .ctrl_ud_iq_width    (ctrl_ud_iq_width),
            .ctrl_fs_offset      (ctrl_fs_offset),
            //
            .err_unexpected_tlast()
        );

      end else begin : g_no_bfp

        // We need to combine two 64-bit into one 128-bit and send to next module

        always_ff @(posedge clk_eth_xran) begin
          if (rst_eth_xran) begin
            s0_cnt[ant] <= 1'b0;
          end else if (s_defm_data_tvalid[ant] && s_defm_data_tlast[ant]) begin
            s0_cnt[ant] <= 1'b0;
          end else if (s_defm_data_tvalid[ant]) begin
            s0_cnt[ant] <= ~s0_cnt[ant];
          end
        end

        always_ff @(posedge clk_eth_xran) begin
          if (s_defm_data_tvalid[ant] && ~s0_cnt[ant]) begin
            s0_axis_tdata[ant][63:0] <= s_defm_data_tdata[ant];
            s0_axis_tkeep[ant][7:0]  <= s_defm_data_tkeep[ant];
          end else if (s_defm_data_tvalid[ant]) begin
            s0_axis_tdata[ant][127:64] <= s_defm_data_tdata[ant];
            s0_axis_tkeep[ant][15:8]   <= s_defm_data_tkeep[ant];
          end
        end

        always_ff @(posedge clk_eth_xran) begin
          if (s_defm_data_tvalid[ant]) begin
            s0_axis_tlast[ant]         <= s_defm_data_tlast[ant];
            s0_axis_tuser[ant]         <= s_defm_data_tuser[ant];
          end
        end

        always_ff @(posedge clk_eth_xran) begin
          s0_axis_tvalid[ant] = s_defm_data_tvalid[ant] && s0_cnt[ant];
        end

        assign s_defm_data_tready[ant] = 1'b1;

      end
    end
  endgenerate

  generate
    for (genvar cc = 0; cc < NUM_CC; cc++) begin : g_cc

      pdxch_fdv_buffer #(
          .CC_ID     (cc),
          .NUM_ANT   (NUM_ANT),
          .HALF_BLOCK(HALF_BLOCK)
      ) u_fdv_buffer (
          // ORAN
          .clk_eth_xran         (clk_eth_xran),
          .rst_eth_xran         (rst_eth_xran),
          //
          .sync_in              (sync_in),
          //
          .defm_radio_start_10ms(defm_radio_start_10ms[cc]),
          .s_dl_sym_num         (s_dl_sym_num[cc]),
          //
          .s_axis_tdata         (s0_axis_tdata),
          .s_axis_tkeep         (s0_axis_tkeep),
          .s_axis_tvalid        (s0_axis_tvalid),
          .s_axis_tlast         (s0_axis_tlast),
          .s_axis_tuser         (s0_axis_tuser),
          // iFFT
          .clk                  (clk),
          .rst                  (rst),
          //
          .dout_dr              (fdv_dout_dr[cc]),
          .dout_di              (fdv_dout_di[cc]),
          .dout_sf              (fdv_dout_sf[cc]),
          .dout_sl              (fdv_dout_sl[cc]),
          .dout_sy              (fdv_dout_sy[cc]),
          .dout_chn             (fdv_dout_chn[cc]),
          .dout_dv              (fdv_dout_dv[cc]),
          .dout_last            (fdv_dout_last[cc]),
          //
          .ctrl_en              (ctrl_en[cc]),
          .ctrl_rat             (ctrl_rat[cc]),
          .ctrl_bist            (ctrl_bist[cc]),
          .ctrl_bw              (ctrl_bw[cc]),
          .ctrl_nprb            (ctrl_nprb[cc]),
          .ctrl_rfs_offset      (ctrl_rfs_offset[cc])
      );

      pdxch_channel #(
          .NUM_ANT   (NUM_ANT),
          .HALF_BLOCK(HALF_BLOCK)
      ) u_channel (
          .clk                 (clk),
          .rst                 (rst),
          //
          .din_dr              (fdv_dout_dr[cc]),
          .din_di              (fdv_dout_di[cc]),
          .din_sf              (fdv_dout_sf[cc]),
          .din_sl              (fdv_dout_sl[cc]),
          .din_sy              (fdv_dout_sy[cc]),
          .din_chn             (fdv_dout_chn[cc]),
          .din_dv              (fdv_dout_dv[cc]),
          .din_last            (fdv_dout_last[cc]),
          //
          .m_axis_tdata        (m_axis_tdata[cc]),
          .m_axis_tuser        (m_axis_tuser[cc]),
          .m_axis_tlast        (m_axis_tlast[cc]),
          .m_axis_tvalid       (m_axis_tvalid[cc]),
          .m_axis_tready       (m_axis_tready[cc]),
          // CSR
          .ctrl_clk            (ctrl_clk),
          .ctrl_rst            (ctrl_rst),
          //
          .ctrl_rat            (ctrl_rat[cc]),
          .ctrl_bw             (ctrl_bw[cc]),
          //
          .ctrl_gain           (ctrl_gain[cc]),
          //
          .ctrl_phase_comp_addr(ctrl_phase_comp_addr[3:0]),
          .ctrl_phase_comp_we  (ctrl_phase_comp_we_s[cc]),
          .ctrl_phase_comp_din (ctrl_phase_comp_din)
      );

      assign ctrl_phase_comp_we_s[cc] = ctrl_phase_comp_we && (ctrl_phase_comp_addr[5:4] == cc);

    end
  endgenerate

  // PhaseComp RAM read back, read latency = 1
  ram_sp #(
      .ADDR_WIDTH(6),
      .DATA_WIDTH(32),
      .WRITE_MODE("READ_FIRST"),
      .OUTPUT_REG(0),
      .INIT_WORD (32'h4000),
      .INIT_FILE (""),
      .RAM_STYLE ("DISTRIBUTED")
  ) u_ram_sp (
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
    ctrl_phase_comp_en_d <= ctrl_phase_comp_en;
  end

  assign ctrl_phase_comp_valid = ctrl_phase_comp_en_d;

endmodule

`default_nettype wire
