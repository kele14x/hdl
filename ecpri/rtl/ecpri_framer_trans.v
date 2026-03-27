/*
 * Insert eCPRI Transport Header (IQ header) at the beginning of Ethernet Packet
 */

`timescale 1 ns / 1 ps
//
`default_nettype none

module ecpri_framer_trans (
    input  wire        clk,
    input  wire        rst,
    //
    input  wire [31:0] s_axis_tdata,
    input  wire [ 3:0] s_axis_tkeep,
    input  wire        s_axis_tlast,
    input  wire        s_axis_tvalid,
    output wire        s_axis_tready,
    //
    input  wire [ 7:0] s_trans_messagetype,
    input  wire [15:0] s_trans_payloadsize,
    input  wire [15:0] s_trans_rtc_pc_id,
    //
    output reg  [31:0] m_axis_tdata,
    output reg  [ 3:0] m_axis_tkeep,
    output reg         m_axis_tlast,
    output reg         m_axis_tvalid,
    input  wire        m_axis_tready,
    //
    input  wire [47:0] ctrl_dest_mac,
    input  wire [47:0] ctrl_src_mac,
    input  wire        ctrl_has_vlan,
    input  wire [15:0] ctrl_vlan_tag
);

  `include "ecpri_pkg.vh"

  // State

  // verilog_format: off
  localparam reg [ 3:0] Version     = 4'b0001;
  localparam reg [ 2:0] Reserved    = 3'b000;
  localparam reg        Concat      = 1'b0;

  localparam integer S_RST             = 0;
  localparam integer S_IDLE            = 1;
  localparam integer S_DMACH           = 2;
  localparam integer S_DMACL_SMACH     = 3;
  localparam integer S_SMACL           = 4;
  localparam integer S_VLAN            = 5;
  localparam integer S_ETYPE_COMMH     = 6;
  localparam integer S_COMML_TRANH     = 7;
  localparam integer S_TRANSL_PAYLOAD0 = 8;
  localparam integer S_PAYLOAD         = 9;
  localparam integer S_LAST            = 10;
  // verilog_format: on

  // Signals

  integer state, state_next;

  reg         extra_last;

  wire [31:0] int_tdata;
  wire [ 3:0] int_tkeep;
  wire        int_tlast;
  wire        int_tlast_extra;
  wire        int_tvalid;
  wire        int_tready;

  wire [ 7:0] int_trans_messagetype;
  wire [15:0] int_trans_payloadsize;
  wire [15:0] int_trans_rtc_pc_id;

  wire [ 7:0] int_trans_seqid;
  wire        int_trans_ebit;
  wire [ 6:0] int_trans_subseqid;

  wire [ 7:0] int_ecpri_messagetype;
  wire [15:0] int_ecpri_payloadsize;

  // Common Header (4)
  wire [31:0] common_header;

  // Transport Heder (4)
  wire [31:0] trans_header;

  reg  [ 7:0] seqid_reg [0:15];

  // Main

  assign int_ecpri_messagetype = int_trans_messagetype;

  assign int_ecpri_payloadsize = int_trans_payloadsize + 16'd4;

  assign common_header = {Version, Reserved, Concat, int_ecpri_messagetype, int_ecpri_payloadsize};

  assign trans_header = {int_trans_rtc_pc_id, int_trans_seqid, int_trans_ebit, int_trans_subseqid};

  assign int_trans_seqid = seqid_reg[int_trans_rtc_pc_id[3:0]];
  assign int_trans_ebit = 1'b0;
  assign int_trans_subseqid = 7'b0;

  // Sequence ID counter

  initial begin : p_init
    integer i;
    for(i = 0; i < 16; i = i + 1) begin
      seqid_reg[i] = 8'b0;
    end
  end

  always @(posedge clk) begin
    if (int_tvalid && int_tready) begin
      seqid_reg[int_trans_rtc_pc_id[3:0]] <= int_trans_seqid + 1'b1;
    end
  end

  // FSM

  always @(posedge clk) begin
    if (rst) begin
      state <= S_RST;
    end else begin
      state <= state_next;
    end
  end

  always @(*) begin
    // By default, state at current state
    state_next = state;

    case (state)
      S_RST: begin
        state_next = S_IDLE;
      end

      S_IDLE: begin
        if (int_tvalid) begin
          state_next = S_DMACH;
        end
      end

      S_DMACH: begin
        if (m_axis_tready) begin
          state_next = S_DMACL_SMACH;
        end
      end

      S_DMACL_SMACH: begin
        if (m_axis_tready) begin
          state_next = S_SMACL;
        end
      end

      S_SMACL: begin
        if (m_axis_tready) begin
          if (ctrl_has_vlan) begin
            state_next = S_VLAN;
          end else begin
            state_next = S_ETYPE_COMMH;
          end
        end
      end

      S_VLAN: begin
        if (m_axis_tready) begin
          state_next = S_ETYPE_COMMH;
        end
      end

      S_ETYPE_COMMH: begin
        if (m_axis_tready) begin
          state_next = S_COMML_TRANH;
        end
      end

      S_COMML_TRANH: begin
        if (m_axis_tready) begin
          state_next = S_TRANSL_PAYLOAD0;
        end
      end

      S_TRANSL_PAYLOAD0: begin
        if (m_axis_tready && extra_last) begin
          state_next = S_LAST;
        end else if (m_axis_tready && m_axis_tlast) begin
          state_next = S_IDLE;
        end else if (m_axis_tready) begin
          state_next = S_PAYLOAD;
        end
      end

      S_PAYLOAD: begin
        if (m_axis_tready && extra_last) begin
          state_next = S_LAST;
        end else if (m_axis_tready && m_axis_tlast) begin
          state_next = S_IDLE;
        end
      end

      S_LAST: begin
        if (m_axis_tready) begin
          state_next = S_IDLE;
        end
      end

      default: begin
        state_next = S_RST;
      end
    endcase
  end

  // Master AXIS

  // TDATA/TKEEP/TLAST/EXTRA_LAST changes their value at the "edge" of state
  // transfer
  always @(posedge clk) begin
    case (state)
      S_IDLE: begin
        if (int_tvalid) begin
          // state_next == S_DMACH
          m_axis_tdata <= byte_reverse(ctrl_dest_mac[47:16]);
          m_axis_tkeep <= 4'b1111;
          m_axis_tlast <= 1'b0;
          extra_last   <= 1'b0;
        end
      end

      S_DMACH: begin
        if (m_axis_tready) begin
          // state_next == S_DMACL_SMACH
          m_axis_tdata <= byte_reverse({ctrl_dest_mac[15:0], ctrl_src_mac[47:32]});
          m_axis_tkeep <= 4'b1111;
          m_axis_tlast <= 1'b0;
          extra_last   <= 1'b0;
        end
      end

      S_DMACL_SMACH: begin
        if (m_axis_tready) begin
          // state_next == S_SMACL
          m_axis_tdata <= byte_reverse({ctrl_src_mac[31:0]});
          m_axis_tkeep <= 4'b1111;
          m_axis_tlast <= 1'b0;
          extra_last   <= 1'b0;
        end
      end

      S_SMACL: begin
        if (m_axis_tready) begin
          if (ctrl_has_vlan) begin
            // state_next == S_VLAN
            m_axis_tdata <= byte_reverse({EtherTypeVlan, ctrl_vlan_tag});
            m_axis_tkeep <= 4'b1111;
            m_axis_tlast <= 1'b0;
            extra_last   <= 1'b0;
          end else begin
            // state_next == S_ETYPE_COMMH
            m_axis_tdata <= byte_reverse({EtherTypeEcpri, common_header[31:16]});
            m_axis_tkeep <= 4'b1111;
            m_axis_tlast <= 1'b0;
            extra_last   <= 1'b0;
          end
        end
      end

      S_VLAN: begin
        if (m_axis_tready) begin
          // state_next == S_ETYPE_COMMH
          m_axis_tdata <= byte_reverse({EtherTypeEcpri, common_header[31:16]});
          m_axis_tkeep <= 4'b1111;
          m_axis_tlast <= 1'b0;
          extra_last   <= 1'b0;
        end
      end

      S_ETYPE_COMMH: begin
        if (m_axis_tready) begin
          // state_next == S_COMML_TRANH
          m_axis_tdata <= byte_reverse({common_header[15:0], trans_header[31:16]});
          m_axis_tkeep <= 4'b1111;
          m_axis_tlast <= 1'b0;
          extra_last   <= 1'b0;
        end
      end

      S_COMML_TRANH: begin
        if (m_axis_tready) begin
          // state_next == S_TRANSL_PAYLOAD0
          m_axis_tdata <= byte_reverse({trans_header[15:0], int_tdata[15:0]});
          m_axis_tkeep <= {int_tkeep[3:2], 2'b11};
          m_axis_tlast <= int_tlast;
          extra_last   <= int_tlast_extra;
        end
      end

      S_TRANSL_PAYLOAD0: begin
        if (m_axis_tready && extra_last) begin
          // state_next == S_LAST
          m_axis_tdata <= byte_reverse(int_tdata);
          m_axis_tkeep <= {2'b00, int_tkeep[1:0]};
          m_axis_tlast <= 1'b1;
          extra_last   <= 1'b0;
        end else if (m_axis_tready) begin
          // state_next == S_PAYLOAD
          m_axis_tdata <= byte_reverse(int_tdata);
          m_axis_tkeep <= int_tkeep;
          m_axis_tlast <= int_tlast;
          extra_last   <= int_tlast_extra;
        end
      end

      S_PAYLOAD: begin
        if (m_axis_tready && extra_last) begin
          // state_next == S_LAST
          m_axis_tdata <= byte_reverse(int_tdata);
          m_axis_tkeep <= {2'b00, int_tkeep[1:0]};
          m_axis_tlast <= 1'b1;
          extra_last   <= 1'b0;
        end else if (m_axis_tready) begin
          // state_next == S_PAYLOAD
          m_axis_tdata <= byte_reverse(int_tdata);
          m_axis_tkeep <= int_tkeep;
          m_axis_tlast <= int_tlast;
          extra_last   <= int_tlast_extra;
        end
      end
    endcase
  end

  always @(posedge clk) begin
    case (state)
      S_RST: begin
        // state_next == S_IDLE
        m_axis_tvalid <= 1'b0;
      end

      S_IDLE: begin
        if (int_tvalid) begin
          // state_next == S_DMACH
          m_axis_tvalid <= 1'b1;
        end
      end

      S_DMACH: begin
        if (m_axis_tready) begin
          // state_next == S_DMACL_SMACH
          m_axis_tvalid <= 1'b1;
        end
      end

      S_DMACL_SMACH: begin
        if (m_axis_tready) begin
          // state_next == S_SMACL
          m_axis_tvalid <= 1'b1;
        end
      end

      S_SMACL: begin
        if (m_axis_tready) begin
          // state_next == S_VLAN/S_ETYPE_COMMH
          m_axis_tvalid <= 1'b1;
        end
      end

      S_VLAN: begin
        if (m_axis_tready) begin
          // state_next == S_ETYPE_COMMH
          m_axis_tvalid <= 1'b1;
        end
      end

      S_ETYPE_COMMH: begin
        if (m_axis_tready) begin
          // state_next == S_COMML_TRANH
          m_axis_tvalid <= 1'b1;
        end
      end

      S_COMML_TRANH: begin
        if (m_axis_tready) begin
          // state_next == S_TRANSL_PAYLOAD0
          m_axis_tvalid <= 1'b1;
        end
      end

      S_TRANSL_PAYLOAD0: begin
        if (m_axis_tready && extra_last) begin
          // state_next == S_LAST
          m_axis_tvalid <= 1'b1;
        end else if (m_axis_tready && m_axis_tlast) begin
          // state_next == S_IDLE
          m_axis_tvalid <= 1'b0;
        end else if (m_axis_tready) begin
          // state_next == S_PAYLOAD
          m_axis_tvalid <= int_tvalid;
        end
      end

      S_PAYLOAD: begin
        if (m_axis_tready && extra_last) begin
          // state_next == S_LAST
          m_axis_tvalid <= 1'b1;
        end else if (m_axis_tready && m_axis_tlast) begin
          // state_next == S_IDLE
          m_axis_tvalid <= 1'b0;
        end else if (m_axis_tready) begin
          // state_next == S_PAYLOAD
          m_axis_tvalid <= int_tvalid;
        end
      end

      S_LAST: begin
        if (m_axis_tready) begin
          // state_next == S_IDLE
          m_axis_tvalid <= 1'b0;
        end
      end

      default: begin
        m_axis_tvalid <= 1'b0;
      end
    endcase
  end

  // AXI Register

  ecpri_framer_trans_reg i_reg (
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
      .m_axis_tdata       (int_tdata),
      .m_axis_tkeep       (int_tkeep),
      .m_axis_tvalid      (int_tvalid),
      .m_axis_tlast       (int_tlast),
      .m_axis_tlast_extra (int_tlast_extra),
      .m_axis_tready      (int_tready),
      //
      .m_trans_messagetype(int_trans_messagetype),
      .m_trans_payloadsize(int_trans_payloadsize),
      .m_trans_rtc_pc_id  (int_trans_rtc_pc_id)
  );

  assign int_tready = (state_next == S_TRANSL_PAYLOAD0 || state_next == S_PAYLOAD) && m_axis_tready;

endmodule

`default_nettype wire
