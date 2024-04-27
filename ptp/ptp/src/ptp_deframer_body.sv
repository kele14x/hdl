// File: ptp_deframer_body.sv
// Brief: This module parse PTP packets (assume common header removed), write
//        parsed body filed to scalar ports. And forward the TLV to next module.
`timescale 1 ns / 1 ps
//
`default_nettype none

module ptp_deframer_body (
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
    output var        m_bdy_body_valid,
    // Common
    output var [79:0] m_bdy_originTimestamp,
    // Announce
    output var [15:0] m_bdy_currentUtcOffset,
    output var [ 7:0] m_bdy_grandmasterPriority1,
    output var [31:0] m_bdy_grandmasterClockQUality,
    output var [ 7:0] m_bdy_grandmasterPriority2,
    output var [63:0] m_bdy_grandmasterIdentity,
    output var [15:0] m_bdy_stepsRemoved,
    output var [ 7:0] m_bdy_timeSource,
    // Delay_Resp
    output var [79:0] m_bdy_requestingPortIdentity
);

  // FSM

  typedef enum int {
    S_RST,        // Under reset
    S_BODY0,      // Wait for message body 0
    S_BODY1,      // Wait for message body 1
    S_BODY2,      // Wait for message body 2
    S_BODY3_TLV,  // Wait for message body 3 and TLV
    S_TLV,        // Wait for payload
    S_LAST        // Last payload bytes
  } state_t;

  state_t state, state_next;

  // PTP Common Header

  logic [79:0] ptp_originTimestamp;
  // Announce
  logic [15:0] ptp_currentUtcOffset;
  logic [ 7:0] ptp_reserved;
  logic [ 7:0] ptp_grandmasterPriority1;
  logic [31:0] ptp_grandmasterClockQUality;
  logic [ 7:0] ptp_grandmasterPriority2;
  logic [63:0] ptp_grandmasterIdentity;
  logic [15:0] ptp_stepsRemoved;
  logic [ 7:0] ptp_timeSource;
  // Delay_Resp
  logic [79:0] ptp_requestingPortIdentity;

  logic [63:0] payload;
  logic [63:0] payload_d;


  // Header mapping

  assign payload = byte_reverse(s_axis_tdata);

  assign {ptp_originTimestamp[79:16]} = payload;

  assign {
    ptp_originTimestamp[15:0],
    ptp_currentUtcOffset,
    ptp_reserved,
    ptp_grandmasterPriority1,
    ptp_grandmasterClockQUality[31:16]
  } = payload;

  assign {
    ptp_grandmasterClockQUality[15:0],
    ptp_grandmasterPriority2,
    ptp_grandmasterIdentity[63:24]
  } = payload;

  assign {ptp_grandmasterIdentity[23:0], ptp_stepsRemoved, ptp_timeSource} = payload[63:16];


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
        state_next = S_BODY0;
      end

      S_BODY0: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_BODY0;
        end else if (s_axis_tvalid) begin
          state_next = S_BODY1;
        end
      end

      S_BODY1: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_BODY0;
        end else if (s_axis_tvalid) begin
          state_next = S_BODY2;
        end
      end

      S_BODY2: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_BODY0;
        end else if (s_axis_tvalid) begin
          state_next = S_BODY3;
        end
      end

      S_BODY3_TLV: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_BODY0;
        end else if (s_axis_tvalid) begin
          state_next = S_TLV;
        end
      end

      S_TLV: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          if (s_axis_tkeep[6]) begin
            state_next = S_LAST;
          end else begin
            state_next = S_BODY0;
          end
        end
      end

      S_LAST: begin
        state_next = S_BODY0;
      end

      default: begin
        state_next = S_RST;
      end
    endcase
  end


  // PTP Parse ports output

  // Common header

  always_ff @(posedge clk) begin
    if (state == S_BODY0 && s_axis_tvalid) begin
      m_hdr_originTimestamp <= ptp_originTimestamp[79:16];
    end
  end

  always_ff @(posedge clk) begin
    if (state == S_BODY1 && s_axis_tvalid) begin
      m_bdy_originTimestamp[15:0]          <= ptp_originTimestamp[15:0];
      m_bdy_currentUtcOffset               <= ptp_currentUtcOffset;
      m_bdy_grandmasterPriority1           <= ptp_grandmasterPriority1;
      m_bdy_grandmasterClockQUality[31:16] <= ptp_grandmasterClockQUality[31:16];
    end
  end

  always_ff @(posedge clk) begin
    if (state == S_BODY2 && s_axis_tvalid) begin
      m_bdy_grandmasterClockQUality[15:0] <= ptp_grandmasterClockQUality[15:0];
      m_bdy_grandmasterPriority2          <= ptp_grandmasterPriority2;
      m_bdy_grandmasterIdentity[63:24]    <= ptp_grandmasterIdentity[63:24];
    end
  end

  always_ff @(posedge clk) begin
    if (state == S_BODY3_TLV && s_axis_tvalid) begin
      m_bdy_grandmasterIdentity[23:0] <= ptp_grandmasterIdentity[23:0];
      m_bdy_stepsRemoved              <= ptp_stepsRemoved;
      m_bdy_timeSource                <= ptp_timeSource;
    end
  end

  always_ff @(posedge clk) begin
    m_trans_header_valid <= (state == S_BODY3_TLV && s_axis_tvalid);
  end

  // Output

  always_ff @(posedge clk) begin
    if (s_axis_tvalid) begin
      payload_d <= payload;
      tkeep_d   <= s_axis_tkeep;
    end
  end

  always_ff @(posedge clk) begin
    if ((state == S_TLV) && s_axis_tvalid) begin
      m_axis_tdata <= byte_reverse({payload_d[15:0], payload[63:16]});
    end else if (state == S_LAST) begin
      m_axis_tdata <= byte_reverse({payload_d[15:0], 48'h0});
    end
  end

  always_ff @(posedge clk) begin
    if ((state == S_TLV) && s_axis_tvalid) begin
      m_axis_tkeep <= {s_axis_tkeep[5:0], tkeep_d[7:6]};
    end else if (state == S_LAST) begin
      m_axis_tkeep <= {6'b0, tkeep_d[7:6]};
    end
  end

  always_ff @(posedge clk) begin
    m_axis_tvalid <= ((state == S_TLV) && s_axis_tvalid) || (state == S_LAST);
  end

  always_ff @(posedge clk) begin
    if ((state == S_TLV) && s_axis_tvalid && s_axis_tlast && s_axis_tkeep[6]) begin
      m_axis_tlast <= s_axis_tlast;
    end else if (state == S_LAST) begin
      m_axis_tlast <= 1'b1;
    end else begin
      m_axis_tlast <= 1'b0;
    end
  end

  // TUSER marks time stamp
  always_ff @(posedge clk) begin
    if ((state == S_BODY0) && s_axis_tvalid) begin
      m_axis_tuser <= s_axis_tuser;
    end
  end


endmodule

`default_nettype wire
