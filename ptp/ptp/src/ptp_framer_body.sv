// File: ptp_framer_body.sv
// Brief: This module parse PTP packets (assume common header removed), write
//        parsed body filed to scalar ports. And forward the TLV to next module.
`timescale 1 ns / 1 ps
//
`default_nettype none

module ptp_framer_body (
    input var         clk,
    input var         rst,
    //
    //----------------
    input var         cmd_valid,
    input var  [ 3:0] cmd_messageType,
    input var  [79:0] cmd_originTimestamp,
    input var  [79:0] cmd_requestingPortIdentity,
    //
    output var [63:0] m_axis_tdata,
    output var [ 7:0] m_axis_tkeep,
    output var        m_axis_tvalid,
    output var        m_axis_tlast
);

  // FSM

  typedef enum int {
    S_RST,    // Under reset
    S_DATA0,  // write body 0
    S_DATA1   // write body 1
  } state_t;

  state_t state, state_next;

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


endmodule

`default_nettype wire
