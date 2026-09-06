`timescale 1 ns / 1 ps
//
`default_nettype none

module oran_deframer_dl_ss #(
    parameter int HAS_BFPX      = 1,
    parameter int ADAPTOR_SIZE  = 1024,
    parameter int BUFFER_SIZE   = 4096,
    parameter int BUFFER_SYMBOL = 10
) (
    input var         clk,
    input var         rst,
    // Timer
    input var  [ 7:0] timer_frame,
    input var         timer_sof,
    input var         timer_sos,
    input var  [32:0] timer_frac,
    // Ethernet
    input var  [63:0] s_axis_tdata,
    input var  [ 7:0] s_axis_tkeep,
    input var         s_axis_tvalid,
    input var         s_axis_tlast,
    // Data to Lowphy
    output var [ 7:0] dl_syml_frame,
    output var        dl_syml_sof,
    output var        dl_syml_sos,
    output var [32:0] dl_syml_frac,
    output var [31:0] dl_syml_data,
    output var        dl_syml_valid,
    // O-RAN Parse ports
    //------------------
    output var        m_app_header_valid,
    output var        m_app_datadirection,
    output var [ 3:0] m_app_filterindex,
    output var [ 7:0] m_app_frameid,
    output var [ 3:0] m_app_subframeid,
    output var [ 5:0] m_app_slotid,
    output var [ 5:0] m_app_symbolid,
    //
    output var        m_app_packet_in_window,
    output var [ 8:0] m_app_offset_in_symbol,
    //
    output var [ 7:0] m_app_numsections,
    output var [ 2:0] m_app_sectiontype,
    output var [ 7:0] m_app_udcomphdr,
    output var [15:0] m_app_timeoffset,
    output var [ 7:0] m_app_framestructure,
    output var [15:0] m_app_cplength,
    //
    output var        m_section_header_valid,
    output var [11:0] m_section_sectionid,
    output var        m_section_rb,
    output var        m_section_syminc,
    output var [ 9:0] m_section_startprb,
    output var [ 7:0] m_section_numprb,
    output var [ 7:0] m_section_udcomphdr,
    //
    output var [11:0] m_section_remask,
    output var [ 3:0] m_section_numsymbol,
    output var        m_section_ef,
    output var [14:0] m_section_beamid,
    output var [23:0] m_section_freqoffset,
    // Control & Status
    //-----------------
    input var         ctrl_has_udcomphdr,
    input var  [ 3:0] ctrl_ud_comp_meth,
    input var  [ 3:0] ctrl_ud_iq_width,
    //
    input var  [11:0] ctrl_syml_rd_shift,
    input var  [15:0] ctrl_buffer_addr_offset[BUFFER_SYMBOL]
);

  logic [                     63:0] s0_axis_tdata;
  logic [                      7:0] s0_axis_tkeep;
  logic                             s0_axis_tvalid;
  logic                             s0_axis_tlast;
  logic [                      8:0] s0_axis_tuser;

  logic [                     63:0] s0_axis_data_tdata;
  logic                             s0_axis_data_tvalid;
  logic                             s0_axis_data_tlast;
  logic [$clog2(BUFFER_SYMBOL)-1:0] s0_axis_data_tuser;

  logic [                     39:0] s0_axis_header_tdata;
  logic                             s0_axis_header_tvalid;
  logic [$clog2(BUFFER_SYMBOL)-1:0] s0_axis_header_tuser;

  logic [$clog2(BUFFER_SYMBOL)-1:0] buffer_rd_bank;

  logic [                     10:0] buffer_rd_addr;
  logic                             buffer_rd_en;
  logic [                     65:0] buffer_rd_dout;

  logic [                      3:0] hdr_buffer_rd_addr;
  logic                             hdr_buffer_rd_en;
  logic [                     40:0] hdr_buffer_rd_dout;

  logic [                     63:0] s1_axis_tdata;
  logic [                      7:0] s1_axis_tkeep;
  logic                             s1_axis_tvalid;
  logic                             s1_axis_tlast;
  logic                             s1_axis_tready;
  /* verilator lint_off UNUSED */
  logic [                     39:0] s1_axis_tuser;
  /* verilator lint_on UNUSED */

  logic [                     63:0] s2_axis_tdata;
  logic [                      7:0] s2_axis_tkeep;
  logic                             s2_axis_tvalid;
  logic                             s2_axis_tlast;
  logic [                     31:0] s2_axis_tuser;


  oran_deframer_dl_ss_symnum i_symnum (
      .clk          (clk),
      .rst          (rst),
      //
      .s_axis_tdata (s_axis_tdata),
      .s_axis_tkeep (s_axis_tkeep),
      .s_axis_tvalid(s_axis_tvalid),
      .s_axis_tlast (s_axis_tlast),
      // Section data
      .m_axis_tdata (s0_axis_tdata),
      .m_axis_tkeep (s0_axis_tkeep),
      .m_axis_tvalid(s0_axis_tvalid),
      .m_axis_tlast (s0_axis_tlast),
      .m_axis_tuser (s0_axis_tuser)
  );

  oran_deframer_dl_ss_mgr #(
      .BUFFER_SYMBOL(BUFFER_SYMBOL)
  ) i_mgr (
      .clk                   (clk),
      .rst                   (rst),
      //
      .timer_sof             (timer_sof),
      .timer_sos             (timer_sos),
      //
      .s_axis_tdata          (s0_axis_tdata),
      .s_axis_tkeep          (s0_axis_tkeep),
      .s_axis_tvalid         (s0_axis_tvalid),
      .s_axis_tlast          (s0_axis_tlast),
      .s_axis_tuser          (s0_axis_tuser),
      //
      .m_axis_data_tdata     (s0_axis_data_tdata),
      .m_axis_data_tvalid    (s0_axis_data_tvalid),
      .m_axis_data_tlast     (s0_axis_data_tlast),
      .m_axis_data_tuser     (s0_axis_data_tuser),
      //
      .m_axis_header_tdata   (s0_axis_header_tdata),
      .m_axis_header_tvalid  (s0_axis_header_tvalid),
      .m_axis_header_tuser   (s0_axis_header_tuser),
      //
      .buffer_rd_bank        (buffer_rd_bank),
      //
      .ctrl_has_udcomphdr    (ctrl_has_udcomphdr),
      .ctrl_ud_comp_meth     (ctrl_ud_comp_meth),
      .ctrl_ud_iq_width      (ctrl_ud_iq_width),
      //
      .m_app_header_valid    (m_app_header_valid),
      .m_app_datadirection   (m_app_datadirection),
      .m_app_filterindex     (m_app_filterindex),
      .m_app_frameid         (m_app_frameid),
      .m_app_subframeid      (m_app_subframeid),
      .m_app_slotid          (m_app_slotid),
      .m_app_symbolid        (m_app_symbolid),
      //
      .m_app_packet_in_window(m_app_packet_in_window),
      .m_app_offset_in_symbol(m_app_offset_in_symbol),
      //
      .m_app_numsections     (m_app_numsections),
      .m_app_sectiontype     (m_app_sectiontype),
      .m_app_udcomphdr       (m_app_udcomphdr),
      .m_app_timeoffset      (m_app_timeoffset),
      .m_app_framestructure  (m_app_framestructure),
      .m_app_cplength        (m_app_cplength),
      //
      .m_section_header_valid(m_section_header_valid),
      .m_section_sectionid   (m_section_sectionid),
      .m_section_rb          (m_section_rb),
      .m_section_syminc      (m_section_syminc),
      .m_section_startprb    (m_section_startprb),
      .m_section_numprb      (m_section_numprb),
      .m_section_udcomphdr   (m_section_udcomphdr),
      //
      .m_section_remask      (m_section_remask),
      .m_section_numsymbol   (m_section_numsymbol),
      .m_section_ef          (m_section_ef),
      .m_section_beamid      (m_section_beamid),
      .m_section_freqoffset  (m_section_freqoffset)
  );

  oran_deframer_dl_ss_buffer #(
      .BUFFER_SIZE  (BUFFER_SIZE),
      .BUFFER_SYMBOL(BUFFER_SYMBOL)
  ) i_buffer (
      .clk                    (clk),
      .rst                    (rst),
      //
      .timer_sos              (timer_sos),
      //
      .s_axis_data_tdata      (s0_axis_data_tdata),
      .s_axis_data_tvalid     (s0_axis_data_tvalid),
      .s_axis_data_tlast      (s0_axis_data_tlast),
      .s_axis_data_tuser      (s0_axis_data_tuser),
      //
      .buffer_rd_bank         (buffer_rd_bank),
      .buffer_rd_addr         (buffer_rd_addr),
      .buffer_rd_en           (buffer_rd_en),
      .buffer_rd_dout         (buffer_rd_dout),
      //
      .ctrl_buffer_addr_offset(ctrl_buffer_addr_offset)
  );

  oran_deframer_dl_ss_hdr_buffer #(
      .BUFFER_SYMBOL(BUFFER_SYMBOL)
  ) i_hdr_buffer (
      .clk                 (clk),
      .rst                 (rst),
      //
      .timer_sos           (timer_sos),
      //
      .s_axis_header_tdata (s0_axis_header_tdata),
      .s_axis_header_tvalid(s0_axis_header_tvalid),
      .s_axis_header_tuser (s0_axis_header_tuser),
      //
      .buffer_rd_bank      (buffer_rd_bank),
      .buffer_rd_addr      (hdr_buffer_rd_addr),
      .buffer_rd_en        (hdr_buffer_rd_en),
      .buffer_rd_dout      (hdr_buffer_rd_dout)
  );

  oran_deframer_dl_ss_readout i_readout (
      .clk               (clk),
      .rst               (rst),
      //
      .timer_sos         (timer_sos),
      // Section Data
      .buffer_rd_addr    (buffer_rd_addr),
      .buffer_rd_en      (buffer_rd_en),
      .buffer_rd_dout    (buffer_rd_dout),
      // Section Header
      .hdr_buffer_rd_addr(hdr_buffer_rd_addr),
      .hdr_buffer_rd_en  (hdr_buffer_rd_en),
      .hdr_buffer_rd_dout(hdr_buffer_rd_dout),
      //
      .m_axis_tdata      (s1_axis_tdata),
      .m_axis_tkeep      (s1_axis_tkeep),
      .m_axis_tvalid     (s1_axis_tvalid),
      .m_axis_tlast      (s1_axis_tlast),
      .m_axis_tready     (s1_axis_tready),
      .m_axis_tuser      (s1_axis_tuser),
      //
      .ctrl_ud_comp_meth (ctrl_ud_comp_meth),
      .ctrl_ud_iq_width  (ctrl_ud_iq_width)
  );

  generate
    if (HAS_BFPX != 0) begin : g_decomp
      oran_deframer_dl_ss_decomp i_decomp (
          .clk              (clk),
          .rst              (rst),
          //
          .s_axis_tdata     (s1_axis_tdata),
          .s_axis_tkeep     (s1_axis_tkeep),
          .s_axis_tvalid    (s1_axis_tvalid),
          .s_axis_tlast     (s1_axis_tlast),
          .s_axis_tready    (s1_axis_tready),
          .s_axis_tuser     (s1_axis_tuser[31:0]),
          //
          .m_axis_tdata     (s2_axis_tdata),
          .m_axis_tkeep     (s2_axis_tkeep),
          .m_axis_tvalid    (s2_axis_tvalid),
          .m_axis_tlast     (s2_axis_tlast),
          .m_axis_tuser     (s2_axis_tuser),
          //
          .ctrl_ud_comp_meth(ctrl_ud_comp_meth),
          .ctrl_ud_iq_width (ctrl_ud_iq_width),
          .ctrl_fs_offset   ('0)
      );
    end else begin : g_no_decomp
      assign s2_axis_tdata  = s1_axis_tdata;
      assign s2_axis_tkeep  = s1_axis_tkeep;
      assign s2_axis_tvalid = s1_axis_tvalid;
      assign s2_axis_tlast  = s1_axis_tlast;
      assign s2_axis_tuser  = s1_axis_tuser[31:0];
    end
  endgenerate

  oran_deframer_dl_ss_adaptor #(
      .ADAPTOR_SIZE(ADAPTOR_SIZE)
  ) i_adaptor (
      .clk               (clk),
      .rst               (rst),
      // Timer
      .timer_frame       (timer_frame),
      .timer_sof         (timer_sof),
      .timer_sos         (timer_sos),
      .timer_frac        (timer_frac),
      //
      .s_axis_tdata      (s2_axis_tdata),
      .s_axis_tkeep      (s2_axis_tkeep),
      .s_axis_tvalid     (s2_axis_tvalid),
      .s_axis_tlast      (s2_axis_tlast),
      .s_axis_tuser      (s2_axis_tuser),
      //
      .dl_syml_frame     (dl_syml_frame),
      .dl_syml_sof       (dl_syml_sof),
      .dl_syml_sos       (dl_syml_sos),
      .dl_syml_frac      (dl_syml_frac),
      .dl_syml_data      (dl_syml_data),
      .dl_syml_valid     (dl_syml_valid),
      //
      .ctrl_syml_rd_shift(ctrl_syml_rd_shift)
  );

endmodule

`default_nettype wire
