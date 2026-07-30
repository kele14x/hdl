/*
 * This module parse eCPRI packets (assume MAC header removed), write
 * parsed filed to scalar ports, then forward the packet to next stage.
 * Transport (eCPRI IQ) header (4) is removed here.
 */

`timescale 1 ns / 1 ps
//
`default_nettype none

module ecpri_deframer_iq (
    input  wire        clk,
    input  wire        rst,
    //
    input  wire [31:0] s_axis_tdata,
    input  wire [ 3:0] s_axis_tkeep,
    input  wire        s_axis_tlast,
    input  wire        s_axis_tvalid,
    //
    output reg  [31:0] m_axis_tdata,
    output reg  [ 3:0] m_axis_tkeep,
    output reg         m_axis_tlast,
    output reg         m_axis_tvalid,
    // eCPRI IQ Header
    output reg         m_trans_header_valid,
    output reg  [15:0] m_trans_rtc_pc_id,
    output reg  [ 7:0] m_trans_seqid,
    output reg         m_trans_ebit,
    output reg  [ 6:0] m_trans_subseqid
);

  import ecpri_pkg::*;

  // FSM

  localparam integer S_RST = 0;  // Under reset
  localparam integer S_TRANS = 1;  // Transport header (4)
  localparam integer S_PAYLOAD = 2;  // Payload

  integer state, state_next;

  wire [31:0] s_axis_tdata_reversed;

  // IQ Header

  // Transport Header (64-bit)
  wire [15:0] trans_rtc_pc_id;
  wire [ 7:0] trans_seqid;
  wire        trans_ebit;  // eCPRI Layer Fragmentation
  wire [ 6:0] trans_subseqid;

  // Main

  // Header mapping

  assign s_axis_tdata_reversed = byte_reverse(s_axis_tdata);

  assign {trans_rtc_pc_id, trans_seqid, trans_ebit, trans_subseqid} = s_axis_tdata_reversed;

  // TODO: eCPRI seqid is not checked
  // TODO: eCPRI Ebit is not support but not checked

  // FSM

  always @(posedge clk) begin
    if (rst) begin
      state <= S_RST;
    end else begin
      state <= state_next;
    end
  end

  always @(*) begin
    // Stay at current state by default
    state_next = state;

    case (state)
      S_RST: begin
        state_next = S_TRANS;
      end

      S_TRANS: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_TRANS;
        end else if (s_axis_tvalid) begin
          state_next = S_PAYLOAD;
        end
      end

      S_PAYLOAD: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_TRANS;
        end
      end

      default: begin
        state_next = S_RST;
      end
    endcase
  end

  always @(posedge clk) begin
    if ((state == S_TRANS) && s_axis_tvalid) begin
      m_trans_rtc_pc_id <= trans_rtc_pc_id;
      m_trans_seqid     <= trans_seqid;
      m_trans_ebit      <= trans_ebit;
      m_trans_subseqid  <= trans_subseqid;
    end
  end

  always @(posedge clk) begin
    m_trans_header_valid <= ((state == S_TRANS) && s_axis_tvalid);
  end

  // Output

  always @(posedge clk) begin
    if ((state == S_PAYLOAD) && s_axis_tvalid) begin
      m_axis_tdata <= s_axis_tdata;
    end
  end

  always @(posedge clk) begin
    if ((state == S_PAYLOAD) && s_axis_tvalid) begin
      m_axis_tkeep <= s_axis_tkeep;
    end
  end

  always @(posedge clk) begin
    m_axis_tvalid <= (state == S_PAYLOAD) && s_axis_tvalid;
  end

  always @(posedge clk) begin
    if ((state == S_PAYLOAD) && s_axis_tvalid) begin
      m_axis_tlast <= s_axis_tlast;
    end
  end

endmodule

`default_nettype wire
