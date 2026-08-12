// One-Way Delay Measurement (Type 5)
`timescale 1 ns / 1 ps
//
`default_nettype none

module ecpri_deframer_odm (
    input var         clk,
    input var         rst,
    //
    input var  [31:0] s_axis_tdata,
    input var  [ 3:0] s_axis_tkeep,
    input var         s_axis_tlast,
    input var         s_axis_tvalid,
    input var  [79:0] s_axis_tuser,
    // eCPRI O-RAN Delay Measurement Header
    output var        m_odm_header_valid,
    output var [ 7:0] m_odm_measurementid,
    output var [ 7:0] m_odm_actiontype,
    output var [79:0] m_odm_timestamp,
    output var [63:0] m_odm_compensation,
    output var [79:0] m_odm_timestamp2,
    //
    output var [15:0] stat_topology_id
);

  import ecpri_pkg::*;

  // FSM

  localparam int S_RST = 0;  // Under reset
  localparam int S_D0 = 1;  // Measurement ID (1), Action Type (1), Timestamp0 (2)
  localparam int S_D1 = 2;  // Timestamp1 (4)
  localparam int S_D2 = 3;  // Timestamp2 (4)
  localparam int S_D3 = 4;  // Compensation0 (4)
  localparam int S_D4 = 5;  // Compensation1 (4)
  localparam int S_D5 = 6;  // Topology ID (2)
  localparam int S_PAD = 7;  // Pad

  integer state, state_next;

  wire [31:0] s_axis_tdata_reversed;
  wire        unused_tkeep = &{1'b0, s_axis_tkeep};

  wire [ 7:0] odm_measurementid;
  wire [ 7:0] odm_actiontype;
  wire [79:0] odm_timestamp;
  wire [63:0] odm_compensation;

  wire [15:0] topology_id;

  // Main

  assign s_axis_tdata_reversed = byte_reverse(s_axis_tdata);

  // Header mapping

  assign {odm_measurementid, odm_actiontype, odm_timestamp[79:64]} = s_axis_tdata_reversed;

  assign odm_timestamp[63:32] = s_axis_tdata_reversed;

  assign odm_timestamp[31:0] = s_axis_tdata_reversed;

  assign odm_compensation[63:32] = s_axis_tdata_reversed;

  assign odm_compensation[31:0] = s_axis_tdata_reversed;

  assign topology_id = s_axis_tdata_reversed[31:16];

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
        state_next = S_D0;
      end

      S_D0: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_D0;
        end else if (s_axis_tvalid) begin
          state_next = S_D1;
        end
      end

      S_D1: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_D0;
        end else if (s_axis_tvalid) begin
          state_next = S_D2;
        end
      end

      S_D2: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_D0;
        end else if (s_axis_tvalid) begin
          state_next = S_D3;
        end
      end

      S_D3: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_D0;
        end else if (s_axis_tvalid) begin
          state_next = S_D4;
        end
      end

      S_D4: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_D0;
        end else if (s_axis_tvalid) begin
          state_next = S_D5;
        end
      end

      S_D5: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_D0;
        end else if (s_axis_tvalid) begin
          state_next = S_PAD;
        end
      end

      S_PAD: begin
        if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_D0;
        end else if (s_axis_tvalid) begin
          state_next = S_PAD;
        end
      end

      default: begin
        state_next = S_RST;
      end
    endcase
  end

  // Delay Measurement Message Parser

  always_ff @(posedge clk) begin
    m_odm_header_valid <= (state == S_D4) && s_axis_tvalid;
  end

  always_ff @(posedge clk) begin
    if ((state == S_D0) && s_axis_tvalid) begin
      m_odm_measurementid    <= odm_measurementid;
      m_odm_actiontype       <= odm_actiontype;
      m_odm_timestamp[79:64] <= odm_timestamp[79:64];
    end
  end

  always_ff @(posedge clk) begin
    if ((state == S_D1) && s_axis_tvalid) begin
      m_odm_timestamp[63:32] <= odm_timestamp[63:32];
    end
  end

  always_ff @(posedge clk) begin
    if ((state == S_D2) && s_axis_tvalid) begin
      m_odm_timestamp[31:0] <= odm_timestamp[31:0];
    end
  end

  always_ff @(posedge clk) begin
    if ((state == S_D3) && s_axis_tvalid) begin
      m_odm_compensation[63:32] <= odm_compensation[63:32];
    end
  end

  always_ff @(posedge clk) begin
    if ((state == S_D4) && s_axis_tvalid) begin
      m_odm_compensation[31:0] <= odm_compensation[31:0];
    end
  end

  always_ff @(posedge clk) begin
    if ((state == S_D5) && s_axis_tvalid) begin
      stat_topology_id <= topology_id;
    end
  end

  always_ff @(posedge clk) begin
    if ((state == S_D0) && s_axis_tvalid) begin
      m_odm_timestamp2 <= s_axis_tuser;
    end
  end

endmodule

`default_nettype wire
