`timescale 1 ns / 1 ps
//
`default_nettype none

module ecpri_framer (
    // Ethernet I/F
    //-------------
    input  wire        tx_eth_clk,
    input  wire        tx_eth_rst,
    //
    output wire [31:0] m_axis_tdata,
    output wire [ 3:0] m_axis_tkeep,
    output wire        m_axis_tlast,
    output wire        m_axis_tuser,
    output wire        m_axis_tvalid,
    input  wire        m_axis_tready,
    //
    output wire [ 1:0] tx_ptp_1588op,
    output wire [15:0] tx_ptp_tag_field,
    // Internal I/F
    //-------------
    input  wire        clk,
    input  wire        rst,
    // I/Q
    input  wire [31:0] s_axis_tdata,
    input  wire [ 3:0] s_axis_tkeep,
    input  wire        s_axis_tlast,
    input  wire        s_axis_tvalid,
    output wire        s_axis_tready,
    // eCPRI OOB ports
    input  wire [ 7:0] s_trans_messagetype,
    input  wire [15:0] s_trans_payloadsize,
    input  wire [15:0] s_trans_rtc_pc_id,
    // ODM
    input  wire        s_axis_odm_tvalid,
    output wire        s_axis_odm_tready,
    //
    input  wire [ 7:0] s_odm_measurementid,
    input  wire [ 7:0] s_odm_actiontype,
    input  wire [79:0] s_odm_timestamp,
    input  wire [63:0] s_odm_compensation,
    // PTP
    input  wire [31:0] s_ptp_tdata,
    input  wire [ 3:0] s_ptp_tkeep,
    input  wire        s_ptp_tlast,
    input  wire [17:0] s_ptp_tuser,
    input  wire        s_ptp_tvalid,
    output wire        s_ptp_tready,
    //
    input  wire [31:0] s_message_tdata,
    input  wire [ 3:0] s_message_tkeep,
    input  wire        s_message_tlast,
    input  wire        s_message_tvalid,
    output wire        s_message_tready,
    // Control I/F
    //------------
    input  wire [47:0] ctrl_dest_mac,
    input  wire [47:0] ctrl_src_mac,
    input  wire        ctrl_has_vlan,
    input  wire [15:0] ctrl_vlan_tag,
    //
    input  wire [15:0] ctrl_topology_id
);

  wire [47:0] ctrl_dest_mac_s;
  wire [47:0] ctrl_src_mac_s;
  wire        ctrl_has_vlan_s;
  wire [15:0] ctrl_vlan_tag_s;

  wire [15:0] ctrl_topology_id_s;

  wire [31:0] m_trans_axis_tdata;
  wire [ 3:0] m_trans_axis_tkeep;
  wire        m_trans_axis_tlast;
  wire        m_trans_axis_tvalid;
  wire        m_trans_axis_tready;

  wire [31:0] m_odm_axis_tdata;
  wire [ 3:0] m_odm_axis_tkeep;
  wire        m_odm_axis_tlast;
  wire [17:0] m_odm_axis_tuser;
  wire        m_odm_axis_tvalid;
  wire        m_odm_axis_tready;

  wire [31:0] s0_axis_tdata;
  wire [ 3:0] s0_axis_tkeep;
  wire        s0_axis_tlast;
  wire [17:0] s0_axis_tuser;
  wire        s0_axis_tvalid;
  wire        s0_axis_tready;

  wire [31:0] s1_axis_tdata;
  wire [ 3:0] s1_axis_tkeep;
  wire        s1_axis_tlast;
  wire [17:0] s1_axis_tuser;
  wire        s1_axis_tvalid;
  wire        s1_axis_tready;

  wire [31:0] s2_axis_tdata;
  wire [ 3:0] s2_axis_tkeep;
  wire        s2_axis_tlast;
  wire [17:0] s2_axis_tuser;
  wire        s2_axis_tvalid;
  wire        s2_axis_tready;

  wire [31:0] s3_axis_tdata;
  wire [ 3:0] s3_axis_tkeep;
  wire        s3_axis_tlast;
  wire [17:0] s3_axis_tuser;
  wire        s3_axis_tvalid;
  wire        s3_axis_tready;

  wire [31:0] s4_axis_tdata;
  wire [ 3:0] s4_axis_tkeep;
  wire        s4_axis_tlast;
  wire [17:0] s4_axis_tuser;
  wire        s4_axis_tvalid;
  wire        s4_axis_tready;

  // Control CDC

  cdc_array_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (0),
      .SRC_INPUT_REG(0),
      .WIDTH        (48)
  ) i_cdc_ctrl_dest_mac (
      .src_clk (1'b1),
      .src_in  (ctrl_dest_mac),
      //
      .dest_clk(clk),
      .dest_out(ctrl_dest_mac_s)
  );

  cdc_array_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (0),
      .SRC_INPUT_REG(0),
      .WIDTH        (48)
  ) i_cdc_ctrl_src_mac (
      .src_clk (1'b1),
      .src_in  (ctrl_src_mac),
      //
      .dest_clk(clk),
      .dest_out(ctrl_src_mac_s)
  );

  cdc_array_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (0),
      .SRC_INPUT_REG(0),
      .WIDTH        (1)
  ) i_cdc_ctrl_has_vlan (
      .src_clk (1'b1),
      .src_in  (ctrl_has_vlan),
      //
      .dest_clk(clk),
      .dest_out(ctrl_has_vlan_s)
  );

  cdc_array_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (0),
      .SRC_INPUT_REG(0),
      .WIDTH        (16)
  ) i_cdc_ctrl_vlan_tag (
      .src_clk (1'b1),
      .src_in  (ctrl_vlan_tag),
      //
      .dest_clk(clk),
      .dest_out(ctrl_vlan_tag_s)
  );

  cdc_array_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (0),
      .SRC_INPUT_REG(0),
      .WIDTH        (16)
  ) i_cdc_ctrl_topology_id (
      .src_clk (1'b1),
      .src_in  (ctrl_topology_id),
      //
      .dest_clk(clk),
      .dest_out(ctrl_topology_id_s)
  );

  ecpri_framer_trans i_trans (
      .clk                (clk),
      .rst                (rst),
      //
      .s_axis_tdata       (s_axis_tdata),
      .s_axis_tkeep       (s_axis_tkeep),
      .s_axis_tlast       (s_axis_tlast),
      .s_axis_tvalid      (s_axis_tvalid),
      .s_axis_tready      (s_axis_tready),
      //
      .s_trans_messagetype(s_trans_messagetype),
      .s_trans_payloadsize(s_trans_payloadsize),
      .s_trans_rtc_pc_id  (s_trans_rtc_pc_id),
      //
      .m_axis_tdata       (m_trans_axis_tdata),
      .m_axis_tkeep       (m_trans_axis_tkeep),
      .m_axis_tlast       (m_trans_axis_tlast),
      .m_axis_tvalid      (m_trans_axis_tvalid),
      .m_axis_tready      (m_trans_axis_tready),
      //
      .ctrl_dest_mac      (ctrl_dest_mac_s),
      .ctrl_src_mac       (ctrl_src_mac_s),
      .ctrl_has_vlan      (ctrl_has_vlan_s),
      .ctrl_vlan_tag      (ctrl_vlan_tag_s)
  );

  ecpri_framer_buffer #(
      .FIFO_DEPTH(4096),
      .USER_WIDTH(0)
  ) i_trans_buffer (
      .clk          (clk),
      .rst          (rst),
      //
      .s_axis_tdata (m_trans_axis_tdata),
      .s_axis_tkeep (m_trans_axis_tkeep),
      .s_axis_tlast (m_trans_axis_tlast),
      .s_axis_tuser ('d0),
      .s_axis_tvalid(m_trans_axis_tvalid),
      .s_axis_tready(m_trans_axis_tready),
      //
      .tx_eth_clk   (tx_eth_clk),
      .tx_eth_rst   (tx_eth_rst),
      //
      .m_axis_tdata (s0_axis_tdata),
      .m_axis_tkeep (s0_axis_tkeep),
      .m_axis_tlast (s0_axis_tlast),
      .m_axis_tuser (  /* not used */),
      .m_axis_tvalid(s0_axis_tvalid),
      .m_axis_tready(s0_axis_tready)
  );

  assign s0_axis_tuser = 'd0;

  ecpri_framer_odm i_odm (
      .clk                (clk),
      .rst                (rst),
      //
      .s_axis_tvalid      (s_axis_odm_tvalid),
      .s_axis_tready      (s_axis_odm_tready),
      //
      .s_odm_measurementid(s_odm_measurementid),
      .s_odm_actiontype   (s_odm_actiontype),
      .s_odm_timestamp    (s_odm_timestamp),
      .s_odm_compensation (s_odm_compensation),
      //
      .m_axis_tdata       (m_odm_axis_tdata),
      .m_axis_tkeep       (m_odm_axis_tkeep),
      .m_axis_tlast       (m_odm_axis_tlast),
      .m_axis_tuser       (m_odm_axis_tuser),
      .m_axis_tvalid      (m_odm_axis_tvalid),
      .m_axis_tready      (m_odm_axis_tready),
      //
      .ctrl_dest_mac      (ctrl_dest_mac_s),
      .ctrl_src_mac       (ctrl_src_mac_s),
      .ctrl_has_vlan      (ctrl_has_vlan_s),
      .ctrl_vlan_tag      (ctrl_vlan_tag_s),
      //
      .ctrl_topology_id   (ctrl_topology_id_s)
  );

  ecpri_framer_buffer #(
      .FIFO_DEPTH(512),
      .USER_WIDTH(18)
  ) i_odm_buffer (
      .clk          (clk),
      .rst          (rst),
      //
      .s_axis_tdata (m_odm_axis_tdata),
      .s_axis_tkeep (m_odm_axis_tkeep),
      .s_axis_tlast (m_odm_axis_tlast),
      .s_axis_tuser (m_odm_axis_tuser),
      .s_axis_tvalid(m_odm_axis_tvalid),
      .s_axis_tready(m_odm_axis_tready),
      //
      .tx_eth_clk   (tx_eth_clk),
      .tx_eth_rst   (tx_eth_rst),
      //
      .m_axis_tdata (s1_axis_tdata),
      .m_axis_tkeep (s1_axis_tkeep),
      .m_axis_tlast (s1_axis_tlast),
      .m_axis_tuser (s1_axis_tuser),
      .m_axis_tvalid(s1_axis_tvalid),
      .m_axis_tready(s1_axis_tready)
  );

  ecpri_framer_buffer #(
      .FIFO_DEPTH(512),
      .USER_WIDTH(18)
  ) i_ptp_buffer (
      .clk          (clk),
      .rst          (rst),
      //
      .s_axis_tdata (s_ptp_tdata),
      .s_axis_tkeep (s_ptp_tkeep),
      .s_axis_tlast (s_ptp_tlast),
      .s_axis_tuser (s_ptp_tuser),
      .s_axis_tvalid(s_ptp_tvalid),
      .s_axis_tready(s_ptp_tready),
      //
      .tx_eth_clk   (tx_eth_clk),
      .tx_eth_rst   (tx_eth_rst),
      //
      .m_axis_tdata (s2_axis_tdata),
      .m_axis_tkeep (s2_axis_tkeep),
      .m_axis_tlast (s2_axis_tlast),
      .m_axis_tuser (s2_axis_tuser),
      .m_axis_tvalid(s2_axis_tvalid),
      .m_axis_tready(s2_axis_tready)
  );

  ecpri_framer_buffer #(
      .FIFO_DEPTH(512),
      .USER_WIDTH(0)
  ) i_message_buffer (
      .clk          (clk),
      .rst          (rst),
      //
      .s_axis_tdata (s_message_tdata),
      .s_axis_tkeep (s_message_tkeep),
      .s_axis_tlast (s_message_tlast),
      .s_axis_tuser ('d0),
      .s_axis_tvalid(s_message_tvalid),
      .s_axis_tready(s_message_tready),
      //
      .tx_eth_clk   (tx_eth_clk),
      .tx_eth_rst   (tx_eth_rst),
      //
      .m_axis_tdata (s3_axis_tdata),
      .m_axis_tkeep (s3_axis_tkeep),
      .m_axis_tlast (s3_axis_tlast),
      .m_axis_tuser (  /* not used */),
      .m_axis_tvalid(s3_axis_tvalid),
      .m_axis_tready(s3_axis_tready)
  );

  assign s3_axis_tuser = 'd0;

  axis_switch #(
      .NUM_SRC   (4),
      .NUM_DEST  (1),
      .DATA_WIDTH(32),
      .USER_WIDTH(18)
  ) i_switch (
      .clk          (tx_eth_clk),
      .rst          (tx_eth_rst),
      //
      .s_axis_tdata ({s3_axis_tdata, s2_axis_tdata, s1_axis_tdata, s0_axis_tdata}),
      .s_axis_tkeep ({s3_axis_tkeep, s2_axis_tkeep, s1_axis_tkeep, s0_axis_tkeep}),
      .s_axis_tlast ({s3_axis_tlast, s2_axis_tlast, s1_axis_tlast, s0_axis_tlast}),
      .s_axis_tuser ({s3_axis_tuser, s2_axis_tuser, s1_axis_tuser, s0_axis_tuser}),
      .s_axis_tdest ({1'b1, 1'b1, 1'b1, 1'b1}),
      .s_axis_tvalid({s3_axis_tvalid, s2_axis_tvalid, s1_axis_tvalid, s0_axis_tvalid}),
      .s_axis_tready({s3_axis_tready, s2_axis_tready, s1_axis_tready, s0_axis_tready}),
      //
      .m_axis_tdata (s4_axis_tdata),
      .m_axis_tkeep (s4_axis_tkeep),
      .m_axis_tlast (s4_axis_tlast),
      .m_axis_tuser (s4_axis_tuser),
      .m_axis_tvalid(s4_axis_tvalid),
      .m_axis_tready(s4_axis_tready)
  );

  ecpri_framer_padding i_padding (
      .clk             (tx_eth_clk),
      .rst             (tx_eth_rst),
      //
      .s_axis_tdata    (s4_axis_tdata),
      .s_axis_tkeep    (s4_axis_tkeep),
      .s_axis_tlast    (s4_axis_tlast),
      .s_axis_tuser    (s4_axis_tuser),
      .s_axis_tvalid   (s4_axis_tvalid),
      .s_axis_tready   (s4_axis_tready),
      //
      .m_axis_tdata    (m_axis_tdata),
      .m_axis_tkeep    (m_axis_tkeep),
      .m_axis_tlast    (m_axis_tlast),
      .m_axis_tuser    (m_axis_tuser),
      .m_axis_tvalid   (m_axis_tvalid),
      .m_axis_tready   (m_axis_tready),
      //
      .tx_ptp_1588op   (tx_ptp_1588op),
      .tx_ptp_tag_field(tx_ptp_tag_field)
  );

endmodule

`default_nettype wire
