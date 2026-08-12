`timescale 1 ns / 1 ps
//
`default_nettype none

module coe_framer_hdr (
    input var         clk,
    input var         rst,
    //
    input var  [31:0] s_axis_tdata,
    input var  [ 3:0] s_axis_tkeep,
    input var         s_axis_tlast,
    input var         s_axis_tvalid,
    output var        s_axis_tready,
    //
    input var  [18:0] s_app_ts,
    //
    input var  [ 7:0] s_trans_messagetype,
    input var  [15:0] s_trans_payloadsize,
    input var  [15:0] s_trans_rtc_pc_id,
    //
    output var [31:0] m_axis_tdata,
    output var [ 3:0] m_axis_tkeep,
    output var        m_axis_tlast,
    output var        m_axis_tvalid,
    input var         m_axis_tready,
    //
    output var [ 7:0] m_trans_messagetype,
    output var [15:0] m_trans_payloadsize,
    output var [15:0] m_trans_rtc_pc_id
);

  import coe_pkg::*;

  // State

  localparam int S_RST = 0;
  localparam int S_IDLE = 1;
  localparam int S_HDR = 2;
  localparam int S_PAYLOAD = 3;

  // Signals

  integer state, state_next;

  // Main

  // Master FSM

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
        state_next = S_IDLE;
      end

      S_IDLE: begin
        if (s_axis_tvalid) begin
          state_next = S_HDR;
        end
      end

      S_HDR: begin
        if (m_axis_tready) begin
          state_next = S_PAYLOAD;
        end
      end

      S_PAYLOAD: begin
        if (m_axis_tready && m_axis_tlast) begin
          state_next = S_IDLE;
        end
      end

      default: begin
        state_next = S_RST;
      end
    endcase
  end

  // Master AXIS

  always_ff @(posedge clk) begin
    // TDATA/TKEEP/TLAST changes at the "edge" of FSM
    case (state)
      S_IDLE: begin
        if (s_axis_tvalid) begin
          // state_next == S_HDR
          m_axis_tdata <= byte_reverse({13'b0, s_app_ts});
          m_axis_tkeep <= 4'b1111;
          m_axis_tlast <= 1'b0;
        end
      end

      S_HDR: begin
        if (m_axis_tready) begin
          // state_next == S_PAYLOAD
          m_axis_tdata <= s_axis_tdata;
          m_axis_tkeep <= s_axis_tkeep;
          m_axis_tlast <= s_axis_tlast;
        end
      end

      S_PAYLOAD: begin
        if (m_axis_tready) begin
          // state_next == S_IDLE/S_PAYLOAD
          m_axis_tdata <= s_axis_tdata;
          m_axis_tkeep <= s_axis_tkeep;
          m_axis_tlast <= s_axis_tlast;
        end
      end
    endcase
  end

  always_ff @(posedge clk) begin
    case (state)
      S_RST: begin
        // state_next == S_IDLE
        m_axis_tvalid <= 1'b0;
      end

      S_IDLE: begin
        if (s_axis_tvalid) begin
          // state_next == S_HDR
          m_axis_tvalid <= 1'b1;
        end
      end

      S_HDR: begin
        if (m_axis_tready) begin
          // state_next == S_PAYLOAD
          m_axis_tvalid <= s_axis_tvalid;
        end
      end

      S_PAYLOAD: begin
        if (m_axis_tready && m_axis_tlast) begin
          // state_next == S_IDLE
          m_axis_tvalid <= 1'b0;
        end else if (m_axis_tready) begin
          // state_next == S_PAYLOAD
          m_axis_tvalid <= s_axis_tvalid;
        end
      end

      default: begin
        m_axis_tvalid <= 1'b0;
      end
    endcase
  end

  assign s_axis_tready = (state_next == S_PAYLOAD) && m_axis_tready;

  always_ff @(posedge clk) begin
    if (state == S_IDLE && s_axis_tvalid) begin
      m_trans_messagetype <= s_trans_messagetype;
      m_trans_payloadsize <= s_trans_payloadsize;
      m_trans_rtc_pc_id   <= s_trans_rtc_pc_id;
    end
  end

endmodule

`default_nettype wire
