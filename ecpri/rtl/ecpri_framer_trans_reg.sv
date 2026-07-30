`timescale 1 ns / 1 ps
//
`default_nettype none

module ecpri_framer_trans_reg (
    input  wire        clk,
    input  wire        rst,
    //
    input  wire [31:0] s_axis_tdata,
    input  wire [ 3:0] s_axis_tkeep,
    input  wire        s_axis_tvalid,
    input  wire        s_axis_tlast,
    output logic         s_axis_tready,
    //
    input  wire [ 7:0] s_trans_messagetype,
    input  wire [15:0] s_trans_payloadsize,
    input  wire [15:0] s_trans_rtc_pc_id,
    //
    output wire [31:0] m_axis_tdata,
    output wire [ 3:0] m_axis_tkeep,
    output wire        m_axis_tvalid,
    output wire        m_axis_tlast,
    output wire        m_axis_tlast_extra,
    input  wire        m_axis_tready,
    //
    output logic  [ 7:0] m_trans_messagetype,
    output logic  [15:0] m_trans_payloadsize,
    output logic  [15:0] m_trans_rtc_pc_id
);

  import ecpri_pkg::*;

  // Parameters

  localparam integer S_RST = 0;
  localparam integer S_IDLE = 1;
  localparam integer S_DEPTH0 = 2;
  localparam integer S_DEPTH1 = 3;

  // Signals

  integer state, state_next;

  logic         sync_n;

  wire [31:0] s_axis_tdata_reversed;

  logic  [31:0] s_axis_tdata_d;
  logic  [ 3:0] s_axis_tkeep_d;
  logic         s_axis_tlast_d;

  logic  [15:0] s_axis_tdata_dd;
  logic  [ 3:0] s_axis_tkeep_dd;

  wire        unused_tkeep_dd = &{1'b0, s_axis_tkeep_dd[1:0]};

  // FSM

  always_ff @(posedge clk) begin
    if (rst) begin
      state <= S_RST;
    end else begin
      state <= state_next;
    end
  end

  always_comb begin
    // Stay at current m_state by default
    state_next = state;

    case (state)
      S_RST: begin
        state_next = S_IDLE;
      end

      S_IDLE: begin
        if (s_axis_tvalid) begin
          state_next = S_DEPTH0;
        end
      end

      S_DEPTH0: begin
        if (s_axis_tvalid && s_axis_tlast && m_axis_tready) begin
          state_next = S_IDLE;
        end else if (s_axis_tvalid && m_axis_tready) begin
          state_next = S_DEPTH0;
        end else if (s_axis_tvalid) begin
          state_next = S_DEPTH1;
        end
      end

      S_DEPTH1: begin
        if (s_axis_tlast_d && m_axis_tready) begin
          state_next = S_IDLE;
        end else if (m_axis_tready) begin
          state_next = S_DEPTH0;
        end
      end

      default: begin
        state_next = S_RST;
      end
    endcase
  end

  // Internal buffer

  assign s_axis_tdata_reversed = byte_reverse(s_axis_tdata);

  always_ff @(posedge clk) begin
    if (rst) begin
      s_axis_tdata_d  <= '0;
      s_axis_tdata_dd <= '0;
    end else if (s_axis_tvalid && s_axis_tready) begin
      s_axis_tdata_d  <= s_axis_tdata_reversed;
      s_axis_tdata_dd <= s_axis_tdata_d[15:0];
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      s_axis_tkeep_d  <= '0;
      s_axis_tkeep_dd <= '0;
    end else if (s_axis_tvalid && s_axis_tready) begin
      s_axis_tkeep_d  <= s_axis_tkeep;
      s_axis_tkeep_dd <= s_axis_tkeep_d;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      s_axis_tlast_d <= 1'b0;
    end else if (s_axis_tvalid && s_axis_tready) begin
      s_axis_tlast_d <= s_axis_tlast;
    end
  end

  // AXIS Slave

  always_ff @(posedge clk) begin
    if (rst) begin
      s_axis_tready <= 1'b0;
    end else begin
      s_axis_tready <= (state_next == S_DEPTH0);
    end
  end

  // AXIS Master

  assign m_axis_tdata = (state == S_DEPTH1) ?
    {s_axis_tdata_dd, s_axis_tdata_d[31:16]} :
    {s_axis_tdata_d[15:0], s_axis_tdata_reversed[31:16]};

  assign m_axis_tkeep = (state == S_DEPTH1) ?
    {s_axis_tkeep_d[1:0], s_axis_tkeep_dd[3:2]} :
    {s_axis_tkeep[1:0], s_axis_tkeep_d[3:2]};

  assign m_axis_tlast = (state == S_DEPTH1) ?
      ~s_axis_tkeep_d[2] && s_axis_tlast_d :
      ~s_axis_tkeep[2] && s_axis_tlast;

  assign m_axis_tlast_extra = (state == S_DEPTH1) ?
      s_axis_tkeep_d[2] && s_axis_tlast_d :
      s_axis_tkeep[2] && s_axis_tlast;

  assign m_axis_tvalid = (state == S_DEPTH1) || (s_axis_tvalid && s_axis_tready);

  // OOB signals register

  always @(posedge clk) begin
    if (rst) begin
      sync_n <= 1'b0;
      m_trans_messagetype <= '0;
      m_trans_payloadsize <= '0;
      m_trans_rtc_pc_id   <= '0;
    end else if (s_axis_tvalid && s_axis_tready) begin
      sync_n <= 1'b0;
    end else if (s_axis_tvalid) begin
      sync_n <= 1'b1;
    end
  end

  always @(posedge clk) begin
    if (~sync_n && s_axis_tvalid) begin
      m_trans_messagetype <= s_trans_messagetype;
      m_trans_payloadsize <= s_trans_payloadsize;
      m_trans_rtc_pc_id   <= s_trans_rtc_pc_id;
    end
  end

endmodule

`default_nettype wire
