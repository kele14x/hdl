`timescale 1 ns / 1 ps
//
`default_nettype none

module prach_framer #(
    parameter int CC_ID   = 0,
    parameter int ANT_ID  = 0,
    parameter int NUM_ANT = 4,
    parameter bit HAS_BFP = 1'b1
) (
    input  wire        clk,
    input  wire        rst,
    //
    input  wire [15:0] din_dr,
    input  wire [15:0] din_di,
    input  wire        din_sf,
    input  wire        din_sl,
    input  wire        din_sy,
    input  wire [ 1:0] din_chn,
    input  wire        din_dv,
    input  wire        din_last,
    //
    input  wire [11:0] rd_section_id,
    // ORAN I/F
    //---------
    input  wire        clk_eth_xran,
    input  wire        rst_eth_xran,
    // U-Plane
    output wire [63:0] m_axis_tdata,
    output wire [ 7:0] m_axis_tkeep,
    output wire        m_axis_tlast,
    output wire [31:0] m_axis_tuser,
    output wire        m_axis_tvalid,
    input  wire        m_axis_tready,
    // CSR
    //----
    input  wire [ 3:0] ctrl_ud_comp_meth,
    input  wire [ 3:0] ctrl_ud_iq_width,
    input  wire [ 3:0] ctrl_fs_offset
);

  // Signals

  logic [63:0] s0_axis_tdata;
  logic [ 7:0] s0_axis_tkeep;
  logic        s0_axis_tlast;
  logic [31:0] s0_axis_tuser;
  logic        s0_axis_tvalid;

  logic [63:0] s1_axis_tdata;
  logic [ 7:0] s1_axis_tkeep;
  logic        s1_axis_tlast;
  logic [31:0] s1_axis_tuser;
  logic        s1_axis_tvalid;

  // Main

  prach_framer_buffer #(
      .CC_ID  (CC_ID),
      .ANT_ID (ANT_ID),
      .NUM_ANT(NUM_ANT)
  ) u_buffer (
      .clk            (clk),
      .rst            (rst),
      //
      .din_dr         (din_dr),
      .din_di         (din_di),
      .din_sf         (din_sf),
      .din_sl         (din_sl),
      .din_sy         (din_sy),
      .din_chn        (din_chn),
      .din_dv         (din_dv),
      .din_last       (din_last),
      //
      .rd_section_id  (rd_section_id),
      //
      .m_axis_tdata   (s0_axis_tdata),
      .m_axis_tkeep   (s0_axis_tkeep),
      .m_axis_tlast   (s0_axis_tlast),
      .m_axis_tuser   (s0_axis_tuser),
      .m_axis_tvalid  (s0_axis_tvalid)
  );

  generate
    if (HAS_BFP) begin : g_bfp

      bfp_comp #(
          .BYTE_REVERSE(1'b1)
      ) u_bfp_comp (
          .clk              (clk),
          .rst              (rst),
          //
          .s_axis_tdata     (s0_axis_tdata),
          .s_axis_tkeep     (s0_axis_tkeep),
          .s_axis_tlast     (s0_axis_tlast),
          .s_axis_tvalid    (s0_axis_tvalid),
          //
          .m_axis_tdata     (s1_axis_tdata),
          .m_axis_tkeep     (s1_axis_tkeep),
          .m_axis_tlast     (s1_axis_tlast),
          .m_axis_tvalid    (s1_axis_tvalid),
          // Control
          //--------
          .ctrl_ud_comp_meth(ctrl_ud_comp_meth),
          .ctrl_ud_iq_width (ctrl_ud_iq_width),
          .ctrl_fs_offset   (ctrl_fs_offset)
      );

    end else begin : g_no_bfp

      assign s1_axis_tdata  = s0_axis_tdata;
      assign s1_axis_tkeep  = s0_axis_tkeep;
      assign s1_axis_tlast  = s0_axis_tlast;
      assign s1_axis_tvalid = s0_axis_tvalid;

    end
  endgenerate

  assign s1_axis_tuser = s0_axis_tuser;

  axis_fifo_alt #(
      .ASYNC_MODE  (1'b1),
      .FIFO_DEPTH  (1024),
      .FIFO_LATENCY(3),
      .DATA_WIDTH  (64),
      .USER_WIDTH  (32)
  ) u_fifo (
      .s_axis_aclk   (clk),
      .s_axis_aresetn(~rst),
      //
      .s_axis_tdata  (s1_axis_tdata),
      .s_axis_tkeep  (s1_axis_tkeep),
      .s_axis_tlast  (s1_axis_tlast),
      .s_axis_tuser  (s1_axis_tuser),
      .s_axis_tvalid (s1_axis_tvalid),
      //
      .m_axis_aclk   (clk_eth_xran),
      //
      .m_axis_tdata  (m_axis_tdata),
      .m_axis_tkeep  (m_axis_tkeep),
      .m_axis_tlast  (m_axis_tlast),
      .m_axis_tuser  (m_axis_tuser),
      .m_axis_tvalid (m_axis_tvalid),
      .m_axis_tready (m_axis_tready),
      //
      .err_discard   ()
  );

endmodule

`default_nettype wire
