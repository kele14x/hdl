// TODO: maybe add axis interface for dummy bytes?
`timescale 1 ns / 1 ps
//
`default_nettype none

module ecpri_framer_odm (
    input var         clk,
    input var         rst,
    //
    input var         s_axis_tvalid,
    output var        s_axis_tready,
    //
    input var  [ 7:0] s_odm_measurementid,
    input var  [ 7:0] s_odm_actiontype,
    input var  [79:0] s_odm_timestamp,
    input var  [63:0] s_odm_compensation,
    //
    output var [31:0] m_axis_tdata,
    output var [ 3:0] m_axis_tkeep,
    output var        m_axis_tlast,
    output var [17:0] m_axis_tuser,
    output var        m_axis_tvalid,
    input var         m_axis_tready,
    //
    input var  [47:0] ctrl_dest_mac,
    input var  [47:0] ctrl_src_mac,
    input var         ctrl_has_vlan,
    input var  [15:0] ctrl_vlan_tag,
    //
    input var  [15:0] ctrl_topology_id
);

  import ecpri_pkg::*;

  // Parameters

  // verilog_format: off
  localparam logic [ 3:0] Version     = 4'b0001;
  localparam logic [ 2:0] Reserved    = 3'b000;
  localparam logic        Concat      = 1'b0;
  localparam logic [ 7:0] MessageType = 8'd5;
  localparam logic [15:0] PayloadSize = 16'd20;

  localparam logic [31:0] EcpriHeader = {Version, Reserved, Concat, MessageType, PayloadSize};

  localparam int S_RST         = 0;
  localparam int S_IDLE        = 1;
  localparam int S_DMACH       = 2;
  localparam int S_DMACL_SMACH = 3;
  localparam int S_SMACL       = 4;
  localparam int S_VLAN        = 5;
  localparam int S_ETYPE_COMMH = 6;
  localparam int S_COMML_DATA0 = 7;
  localparam int S_DATA1       = 8;
  localparam int S_DATA2       = 9;
  localparam int S_DATA3       = 10;
  localparam int S_DATA4       = 11;
  localparam int S_DATA5       = 12;
  // verilog_format: on

  // Signals

  integer state, state_next;

  always_ff @(posedge clk) begin
    if (rst) begin
      state <= S_RST;
    end else begin
      state <= state_next;
    end
  end

  always_comb begin
    state_next = state;
    case (state)
      S_RST: begin
        state_next = S_IDLE;
      end

      S_IDLE: begin
        if (s_axis_tvalid) begin
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
          state_next = S_COMML_DATA0;
        end
      end

      S_COMML_DATA0: begin
        if (m_axis_tready) begin
          state_next = S_DATA1;
        end
      end

      S_DATA1: begin
        if (m_axis_tready) begin
          state_next = S_DATA2;
        end
      end

      S_DATA2: begin
        if (m_axis_tready) begin
          state_next = S_DATA3;
        end
      end

      S_DATA3: begin
        if (m_axis_tready) begin
          state_next = S_DATA4;
        end
      end

      S_DATA4: begin
        if (m_axis_tready) begin
          state_next = S_DATA5;
        end
      end

      S_DATA5: begin
        if (m_axis_tready) begin
          state_next = S_IDLE;
        end
      end

      default: begin
        state_next = S_RST;
      end
    endcase
  end

  // Master AXI

  always_ff @(posedge clk) begin
    case (state)
      S_IDLE: begin
        if (s_axis_tvalid) begin
          // state_next == S_DMACH
          m_axis_tdata <= byte_reverse(ctrl_dest_mac[47:16]);
          m_axis_tkeep <= 4'b1111;
          m_axis_tlast <= 1'b0;
          // The "control filed" is:
          // [15:0] tx_ptp_tag_field = {s_odm_actiontype, s_odm_measurementid}
          // [17:16] tx_ptp_1588op    = 2'd2;
          if (s_odm_actiontype == 8'h01) begin  // REQUEST_WITH_FOLLOW_UP
            m_axis_tuser <= {2'd2, s_odm_actiontype, s_odm_measurementid};
          end else begin
            m_axis_tuser <= 18'd0;
          end
        end
      end

      S_DMACH: begin
        if (m_axis_tready) begin
          // state_next == S_DMACL_SMACH
          m_axis_tdata <= byte_reverse({ctrl_dest_mac[15:0], ctrl_src_mac[47:32]});
          m_axis_tkeep <= 4'b1111;
          m_axis_tlast <= 1'b0;
        end
      end

      S_DMACL_SMACH: begin
        if (m_axis_tready) begin
          // state_next == S_SMACL
          m_axis_tdata <= byte_reverse(ctrl_src_mac[31:0]);
          m_axis_tkeep <= 4'b1111;
          m_axis_tlast <= 1'b0;
        end
      end

      S_SMACL: begin
        if (m_axis_tready) begin
          if (ctrl_has_vlan) begin
            // state_next == S_VLAN
            m_axis_tdata <= byte_reverse({ECPRI_ETHERTYPE_VLAN, ctrl_vlan_tag});
            m_axis_tkeep <= 4'b1111;
            m_axis_tlast <= 1'b0;
          end else begin
            // state_next == S_ETYPE_COMMH
            m_axis_tdata <= byte_reverse({ECPRI_ETHERTYPE_ECPRI, EcpriHeader[31:16]});
            m_axis_tkeep <= 4'b1111;
            m_axis_tlast <= 1'b0;
          end
        end
      end

      S_VLAN: begin
        if (m_axis_tready) begin
          // state_next == S_ETYPE_COMMH
          m_axis_tdata <= byte_reverse({ECPRI_ETHERTYPE_ECPRI, EcpriHeader[31:16]});
          m_axis_tkeep <= 4'b1111;
          m_axis_tlast <= 1'b0;
        end
      end

      S_ETYPE_COMMH: begin
        if (m_axis_tready) begin
          // state_next == S_COMML_DATA0
          m_axis_tdata <= byte_reverse({EcpriHeader[15:0], s_odm_measurementid, s_odm_actiontype});
          m_axis_tkeep <= 4'b1111;
          m_axis_tlast <= 1'b0;
        end
      end

      S_COMML_DATA0: begin
        if (m_axis_tready) begin
          // state_next == S_DATA1
          m_axis_tdata <= byte_reverse(s_odm_timestamp[79:48]);
          m_axis_tkeep <= 4'b1111;
          m_axis_tlast <= 1'b0;
        end
      end

      S_DATA1: begin
        if (m_axis_tready) begin
          // state_next == S_DATA2
          m_axis_tdata <= byte_reverse(s_odm_timestamp[47:16]);
          m_axis_tkeep <= 4'b1111;
          m_axis_tlast <= 1'b0;
        end
      end

      S_DATA2: begin
        if (m_axis_tready) begin
          // state_next == S_DATA3
          m_axis_tdata <= byte_reverse({s_odm_timestamp[15:0], s_odm_compensation[63:48]});
          m_axis_tkeep <= 4'b1111;
          m_axis_tlast <= 1'b0;
        end
      end

      S_DATA3: begin
        if (m_axis_tready) begin
          // state_next == S_DATA4
          m_axis_tdata <= byte_reverse(s_odm_compensation[47:16]);
          m_axis_tkeep <= 4'b1111;
          m_axis_tlast <= 1'b0;
        end
      end

      S_DATA4: begin
        if (m_axis_tready) begin
          // state_next == S_DATA5
          m_axis_tdata <= byte_reverse({s_odm_compensation[15:0], ctrl_topology_id});
          m_axis_tkeep <= 4'b1111;
          m_axis_tlast <= 1'b1;
        end
      end
    endcase
  end

  always_ff @(posedge clk) begin
    m_axis_tvalid <= (
      state_next == S_DMACH || state_next == S_DMACL_SMACH ||
      state_next == S_SMACL || state_next == S_VLAN || state_next == S_ETYPE_COMMH ||
      state_next == S_COMML_DATA0 || state_next == S_DATA1 || state_next == S_DATA2 ||
      state_next == S_DATA3 || state_next == S_DATA4 || state_next == S_DATA5
    );
  end

  // Slave AXI

  assign s_axis_tready = (state == S_IDLE);

endmodule

`default_nettype wire
