// File: ptp_deframer_hdr.sv
// Brief: This module parse PTP packets (assume MAC header removed), write
//        parsed header filed to scalar ports, then forward the packet to next
//        stage. Common header (34) is removed here.
`timescale 1 ns / 1 ps
//
`default_nettype none

module ptp_deframer_hdr (
    input var         clk,
    input var         rst,
    //
    input var  [63:0] s_axis_tdata,
    input var  [ 7:0] s_axis_tkeep,
    input var         s_axis_tvalid,
    input var         s_axis_tlast,
    input var  [79:0] s_axis_tuser,
    //
    output var [63:0] m_axis_tdata,
    output var [ 7:0] m_axis_tkeep,
    output var        m_axis_tvalid,
    output var        m_axis_tlast,
    output var [79:0] m_axis_tuser,
    // PTP parse ports
    //----------------
    // Common Header
    output var        m_hdr_header_valid,
    output var [ 3:0] m_hdr_transportSpecific,
    output var [ 3:0] m_hdr_messageType,
    output var [ 3:0] m_hdr_versionPTP,
    output var [15:0] m_hdr_messageLength,
    output var [ 7:0] m_hdr_domainNumber,
    output var [15:0] m_hdr_flagField,
    output var [63:0] m_hdr_correctionField,
    output var [79:0] m_hdr_sourcePortIdentity,
    output var [15:0] m_hdr_sequenceId,
    output var [ 7:0] m_hdr_controlField,
    output var [ 7:0] m_hdr_logMessageInterval
);

  // FSM

  typedef enum int {
    S_RST,           // Under reset
    S_HDR0,          // Wait for common header 0
    S_HDR1,          // Wait for common header 1
    S_HDR2,          // Wait for common header 2
    S_HDR3,          // Wait for common header 3
    S_HDR4_PAYLOAD,  // Wait for common header 4 and payload
    S_PAYLOAD,       // Wait for payload
    S_LAST           // Last payload bytes
  } state_t;

  state_t state, state_next;

  // PTP Common Header

  logic [ 3:0] ptp_transportSpecific;
  logic [ 3:0] ptp_messageType;
  logic [ 3:0] ptp_reserved0;  //! no output
  logic [ 3:0] ptp_versionPTP;
  logic [15:0] ptp_messageLength;
  logic [ 7:0] ptp_domainNumber;
  logic [ 7:0] ptp_reserved1;  //! no output
  logic [15:0] ptp_flagField;
  logic [63:0] ptp_correctionField;
  logic [31:0] ptp_reserved2;  //! no output
  logic [79:0] ptp_sourcePortIdentity;
  logic [15:0] ptp_sequenceId;
  logic [ 7:0] ptp_controlField;
  logic [ 7:0] ptp_logMessageInterval;

  logic [63:0] payload;
  logic [63:0] payload_d;

  logic [15:0] ptp_count;  // Packet size count


  // Header mapping

  assign payload = byte_reverse(s_axis_tdata);

  assign {
    ptp_transportSpecific,
    ptp_messageType,
    ptp_reserved0,
    ptp_versionPTP,
    ptp_messageLength,
    ptp_domainNumber,
    ptp_reserved1,
    ptp_flagField
  } = payload;

  assign {ptp_correctionField} = payload;

  assign {ptp_reserved2, ptp_sourcePortIdentity[79:48]} = payload;

  assign {ptp_sourcePortIdentity[47:0], ptp_sequenceId} = payload;

  assign {ptp_controlField, ptp_logMessageInterval} = payload[63:48];


  // FSM

  always_ff @(posedge clk) begin
    if (rst) begin
      state <= S_RST;
    end else begin
      state <= state_next;
    end
  end

  always_comb begin
    // Stay at current state by default
    state_next = state;

    case (state)
      S_RST: begin
        state_next = S_HDR0;
      end

      S_HDR0: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_HDR0;
        end else if (s_axis_tvalid) begin
          state_next = S_HDR1;
        end
      end

      S_HDR1: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_HDR0;
        end else if (s_axis_tvalid) begin
          state_next = S_HDR2;
        end
      end

      S_HDR2: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_HDR0;
        end else if (s_axis_tvalid) begin
          state_next = S_HDR3;
        end
      end

      S_HDR3: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_HDR0;
        end else if (s_axis_tvalid) begin
          state_next = S_HDR4_PAYLOAD;
        end
      end

      S_HDR4_PAYLOAD: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_HDR0;
        end else if (s_axis_tvalid) begin
          state_next = S_PAYLOAD;
        end
      end

      S_PAYLOAD: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          if (s_axis_tkeep[2]) begin
            state_next = S_LAST;
          end else begin
            state_next = S_HDR0;
          end
        end
      end

      S_LAST: begin
        state_next = S_HDR0;
      end

      default: begin
        state_next = S_RST;
      end
    endcase
  end


  // PTP Parse ports output

  // Common header

  always_ff @(posedge clk) begin
    if (state == S_HDR0 && s_axis_tvalid) begin
      m_hdr_transportSpecific <= ptp_transportSpecific;
      m_hdr_messageType       <= ptp_messageType;
      m_hdr_versionPTP        <= ptp_versionPTP;
      m_hdr_messageLength     <= ptp_messageLength;
      m_hdr_domainNumber      <= ptp_domainNumber;
      m_hdr_flagField         <= ptp_flagField;
    end
  end

  always_ff @(posedge clk) begin
    if (state == S_HDR1 && s_axis_tvalid) begin
      m_hdr_correctionField <= ptp_correctionField;
    end
  end

  always_ff @(posedge clk) begin
    if (state == S_HDR2 && s_axis_tvalid) begin
      m_hdr_sourcePortIdentity[79:48] <= ptp_sourcePortIdentity[79:48];
    end
  end

  always_ff @(posedge clk) begin
    if (state == S_HDR3 && s_axis_tvalid) begin
      m_hdr_sourcePortIdentity[47:0] <= ptp_sourcePortIdentity[47:0];
      m_hdr_ptp_sequenceId           <= ptp_sequenceId;
    end
  end

  always_ff @(posedge clk) begin
    if (state == S_HDR4_PAYLOAD && s_axis_tvalid) begin
      m_hdr_controlField       <= ptp_controlField;
      m_hdr_logMessageInterval <= ptp_logMessageInterval;
    end
  end

  always_ff @(posedge clk) begin
    m_trans_header_valid <= (state == S_HDR4_PAYLOAD && s_axis_tvalid);
  end


  // Packet size counter

  always_ff @(posedge clk) begin
    if (rst) begin
      ptp_count <= '0;
    end else if ((state == S_HDR0) && s_axis_tvalid) begin
      ptp_count <= 'd8;
    end else if ((state == S_HDR0 || state == S_HDR1 || state == S_HDR2 ||
        state == S_HDR3 || state == S_HDR4_PAYLOAD || state == S_PAYLOAD) && s_axis_tvalid) begin
      ptp_count <= ptp_count + tkeep_size(s_axis_tkeep);
    end
  end


  // Output

  always_ff @(posedge clk) begin
    if (s_axis_tvalid) begin
      payload_d <= payload;
    end
  end

  always_ff @(posedge clk) begin
    if ((state == S_PAYLOAD) && s_axis_tvalid) begin
      m_axis_tdata <= byte_reverse({payload_d[47:0], payload[63:48]});
    end else if (state == S_LAST) begin
      m_axis_tdata <= byte_reverse({payload_d[47:0], 16'h0});
    end
  end

  always_ff @(posedge clk) begin
    if ((state == S_PAYLOAD) && s_axis_tvalid) begin
      m_axis_tkeep <= {s_axis_tkeep[1:0], tkeep_d[7:2]};
    end else if (state == S_LAST) begin
      m_axis_tkeep <= {2'b0, tkeep_d[7:2]};
    end
  end

  always_ff @(posedge clk) begin
    m_axis_tvalid <= ((state == S_PAYLOAD) && s_axis_tvalid) || (state == S_LAST);
  end

  always_ff @(posedge clk) begin
    if ((state == S_PAYLOAD) && s_axis_tvalid && s_axis_tlast && s_axis_tkeep[2]) begin
      m_axis_tlast <= s_axis_tlast;
    end else if (state == S_LAST) begin
      m_axis_tlast <= 1'b1;
    end else begin
      m_axis_tlast <= 1'b0;
    end
  end

  // TUSER marks time stamp
  always_ff @(posedge clk) begin
    if ((state == S_HDR0) && s_axis_tvalid) begin
      m_axis_tuser <= s_axis_tuser;
    end
  end


endmodule

`default_nettype wire
