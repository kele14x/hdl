`timescale 1 ns / 1 ps
//
`default_nettype none

module oran_framer_ul_ss #(
    parameter bit        HAS_BFPX          = 1,
    parameter int        NUM_ETHERNET_PORT = 1,
    parameter bit [15:0] PC_ID             = 16'h0000,
    parameter int        ADAPTOR_SIZE      = 1024,
    parameter int        BUFFER_SIZE       = 1024
) (
    // Tx Ethernet ports
    //------------------
    input var                          clk,
    input var                          rst,
    // Tx data
    output var [                 63:0] m_axis_tdata,
    output var [                  7:0] m_axis_tkeep,
    output var                         m_axis_tvalid,
    output var                         m_axis_tlast,
    input var                          m_axis_tready,
    output var [NUM_ETHERNET_PORT-1:0] m_axis_tuser,
    //
    input var  [                  7:0] ul_syml_frame,
    input var                          ul_syml_sof,
    input var                          ul_syml_sos,
    input var  [                 31:0] ul_syml_data,
    input var                          ul_syml_valid,
    // Control I/F
    //------------
    input var                          ctrl_clk,
    input var                          ctrl_rst,
    //
    input var                          ctrl_has_udcomphdr,
    input var  [                  3:0] ctrl_ud_comp_meth,
    input var  [                  3:0] ctrl_ud_iq_width,
    input var  [                 11:0] ctrl_syml_rd_shift,
    //
    input var  [                  3:0] ctrl_buf_wr_addr,
    input var                          ctrl_buf_wr_en,
    input var                          ctrl_buf_wr_we,
    input var  [                 31:0] ctrl_buf_wr_din,
    output var [                 31:0] ctrl_buf_wr_dout,
    //
    input var  [                  4:0] ctrl_mask_wr_addr,
    input var                          ctrl_mask_wr_en,
    input var                          ctrl_mask_wr_we,
    input var  [                 31:0] ctrl_mask_wr_din,
    output var [                 31:0] ctrl_mask_wr_dout
);

  logic [ 7:0] req_app_frameid;
  logic [ 3:0] req_app_subframeid;
  logic [ 5:0] req_app_slotid;
  logic [ 5:0] req_app_symbolid;
  //
  logic [ 9:0] req_section_startprbu;
  logic [ 7:0] req_section_numprbu;
  //
  logic        req_valid;
  logic        req_ready;

  logic [ 7:0] ul_ctrl_frame;
  logic        ul_ctrl_sof;
  logic        ul_ctrl_sos;

  logic [63:0] s0_axis_tdata;
  logic [ 7:0] s0_axis_tkeep;
  logic        s0_axis_tvalid;
  logic        s0_axis_tlast;
  logic [63:0] s0_axis_tuser;

  logic [63:0] s1_axis_tdata;
  logic [ 7:0] s1_axis_tkeep;
  logic        s1_axis_tvalid;
  logic        s1_axis_tlast;
  logic [63:0] s1_axis_tuser;

  logic [63:0] s2_axis_tdata;
  logic [ 7:0] s2_axis_tkeep;
  logic        s2_axis_tvalid;
  logic        s2_axis_tlast;
  logic [47:0] s2_axis_tuser;

  logic [63:0] s3_axis_tdata;
  logic [ 7:0] s3_axis_tkeep;
  logic        s3_axis_tvalid;
  logic        s3_axis_tlast;
  logic [15:0] s3_axis_tuser;

  logic [63:0] s4_axis_tdata;
  logic [ 7:0] s4_axis_tkeep;
  logic        s4_axis_tvalid;
  logic        s4_axis_tlast;


  // TODO: Connect to used ethernet number
  assign m_axis_tuser = 1;

  oran_framer_ul_ss_ctrl i_ctrl (
      .clk                  (clk),
      .rst                  (rst),
      //
      .ul_frame             (ul_ctrl_frame),
      .ul_sof               (ul_ctrl_sof),
      .ul_sos               (ul_ctrl_sos),
      //
      .req_app_frameid      (req_app_frameid),
      .req_app_subframeid   (req_app_subframeid),
      .req_app_slotid       (req_app_slotid),
      .req_app_symbolid     (req_app_symbolid),
      //
      .req_section_startprbu(req_section_startprbu),
      .req_section_numprbu  (req_section_numprbu),
      //
      .req_valid            (req_valid),
      .req_ready            (req_ready),
      //
      .ctrl_clk             (ctrl_clk),
      .ctrl_rst             (ctrl_rst),
      //
      .ctrl_buf_wr_addr     (ctrl_buf_wr_addr),
      .ctrl_buf_wr_en       (ctrl_buf_wr_en),
      .ctrl_buf_wr_we       (ctrl_buf_wr_we),
      .ctrl_buf_wr_din      (ctrl_buf_wr_din),
      .ctrl_buf_wr_dout     (ctrl_buf_wr_dout),
      //
      .ctrl_mask_wr_addr    (ctrl_mask_wr_addr),
      .ctrl_mask_wr_en      (ctrl_mask_wr_en),
      .ctrl_mask_wr_we      (ctrl_mask_wr_we),
      .ctrl_mask_wr_din     (ctrl_mask_wr_din),
      .ctrl_mask_wr_dout    (ctrl_mask_wr_dout)
  );

  oran_framer_ul_ss_buffer #(
      .BUFFER_SIZE(BUFFER_SIZE)
  ) i_buffer (
      .clk          (clk),
      .rst          (rst),
      //
      .m_axis_tdata (m_axis_tdata),
      .m_axis_tkeep (m_axis_tkeep),
      .m_axis_tvalid(m_axis_tvalid),
      .m_axis_tlast (m_axis_tlast),
      .m_axis_tready(m_axis_tready),
      //
      .s_axis_tdata (s4_axis_tdata),
      .s_axis_tkeep (s4_axis_tkeep),
      .s_axis_tvalid(s4_axis_tvalid),
      .s_axis_tlast (s4_axis_tlast)
  );

  oran_framer_ul_ss_trans #(
      .PC_ID(PC_ID)
  ) i_trans (
      .clk          (clk),
      .rst          (rst),
      //
      .m_axis_tdata (s4_axis_tdata),
      .m_axis_tkeep (s4_axis_tkeep),
      .m_axis_tvalid(s4_axis_tvalid),
      .m_axis_tlast (s4_axis_tlast),
      //
      .s_axis_tdata (s3_axis_tdata),
      .s_axis_tkeep (s3_axis_tkeep),
      .s_axis_tvalid(s3_axis_tvalid),
      .s_axis_tlast (s3_axis_tlast),
      .s_axis_tuser (s3_axis_tuser)
  );

  oran_framer_ul_ss_app i_app (
      .clk          (clk),
      .rst          (rst),
      //
      .m_axis_tdata (s3_axis_tdata),
      .m_axis_tkeep (s3_axis_tkeep),
      .m_axis_tvalid(s3_axis_tvalid),
      .m_axis_tlast (s3_axis_tlast),
      .m_axis_tuser (s3_axis_tuser),
      //
      .s_axis_tdata (s2_axis_tdata),
      .s_axis_tkeep (s2_axis_tkeep),
      .s_axis_tvalid(s2_axis_tvalid),
      .s_axis_tlast (s2_axis_tlast),
      .s_axis_tuser (s2_axis_tuser)
  );

  oran_framer_ul_ss_section i_sec (
      .clk               (clk),
      .rst               (rst),
      //
      .m_axis_tdata      (s2_axis_tdata),
      .m_axis_tkeep      (s2_axis_tkeep),
      .m_axis_tvalid     (s2_axis_tvalid),
      .m_axis_tlast      (s2_axis_tlast),
      .m_axis_tuser      (s2_axis_tuser),
      //
      .s_axis_tdata      (s1_axis_tdata),
      .s_axis_tkeep      (s1_axis_tkeep),
      .s_axis_tvalid     (s1_axis_tvalid),
      .s_axis_tlast      (s1_axis_tlast),
      .s_axis_tuser      (s1_axis_tuser),
      //
      .ctrl_has_udcomphdr(ctrl_has_udcomphdr),
      .ctrl_ud_comp_meth (ctrl_ud_comp_meth),
      .ctrl_ud_iq_width  (ctrl_ud_iq_width)
  );

  generate
    if (HAS_BFPX) begin : g_comp
      oran_framer_ul_ss_comp i_comp (
          .clk              (clk),
          .rst              (rst),
          //
          .m_axis_tdata     (s1_axis_tdata),
          .m_axis_tkeep     (s1_axis_tkeep),
          .m_axis_tvalid    (s1_axis_tvalid),
          .m_axis_tlast     (s1_axis_tlast),
          .m_axis_tuser     (s1_axis_tuser),
          //
          .s_axis_tdata     (s0_axis_tdata),
          .s_axis_tkeep     (s0_axis_tkeep),
          .s_axis_tvalid    (s0_axis_tvalid),
          .s_axis_tlast     (s0_axis_tlast),
          .s_axis_tuser     (s0_axis_tuser),
          // Control
          .ctrl_ud_comp_meth(ctrl_ud_comp_meth),
          .ctrl_ud_iq_width (ctrl_ud_iq_width)
      );
    end else begin : g_no_comp
      assign s1_axis_tdata  = s0_axis_tdata;
      assign s1_axis_tkeep  = s0_axis_tkeep;
      assign s1_axis_tvalid = s0_axis_tvalid;
      assign s1_axis_tlast  = s0_axis_tlast;
      assign s1_axis_tuser  = s0_axis_tuser;
    end
  endgenerate

  oran_framer_ul_ss_adaptor #(
      .ADAPTOR_SIZE(ADAPTOR_SIZE)
  ) i_adaptor (
      .clk               (clk),
      .rst               (rst),
      //
      .req_frameid       (req_app_frameid),
      .req_subframeid    (req_app_subframeid),
      .req_slotid        (req_app_slotid),
      .req_symbolid      (req_app_symbolid),
      .req_startprb      (req_section_startprbu),
      .req_numprb        (req_section_numprbu),
      .req_valid         (req_valid),
      .req_ready         (req_ready),
      //
      .m_axis_tdata      (s0_axis_tdata),
      .m_axis_tkeep      (s0_axis_tkeep),
      .m_axis_tvalid     (s0_axis_tvalid),
      .m_axis_tlast      (s0_axis_tlast),
      .m_axis_tuser      (s0_axis_tuser),
      //
      .ul_syml_frame     (ul_syml_frame),
      .ul_syml_sof       (ul_syml_sof),
      .ul_syml_sos       (ul_syml_sos),
      .ul_syml_data      (ul_syml_data),
      .ul_syml_valid     (ul_syml_valid),
      //
      .ul_ctrl_frame     (ul_ctrl_frame),
      .ul_ctrl_sof       (ul_ctrl_sof),
      .ul_ctrl_sos       (ul_ctrl_sos),
      // Control I/F
      //------------
      .ctrl_syml_rd_shift(ctrl_syml_rd_shift)
  );

endmodule

`default_nettype wire
