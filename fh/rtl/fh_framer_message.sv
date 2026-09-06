`timescale 1 ns / 1 ps
//
`default_nettype none

module fh_framer_message (
    input var         clk,
    input var         rst,
    //
    input var  [31:0] s_axis_tdata,
    input var  [ 3:0] s_axis_tkeep,
    input var         s_axis_tlast,
    input var         s_axis_tvalid,
    output var        s_axis_tready,
    //
    output var [31:0] m_axis_tdata,
    output var [ 3:0] m_axis_tkeep,
    output var        m_axis_tlast,
    output var        m_axis_tvalid,
    input var         m_axis_tready
);

  import ecpri_pkg::*;

  // State

  localparam int S_RST = 0;
  localparam int S_IDLE = 1;
  localparam int S_CTRL = 2;
  localparam int S_PAYLOAD = 3;

  // Signals

  integer state, state_next;

  wire [31:0] int_tdata;
  wire [ 3:0] int_tkeep;
  wire        int_tvalid;
  wire        int_tlast;
  wire        int_tready;
  /* verilator lint_off UNUSED */
  wire        int_tuser;
  /* verilator lint_on UNUSED */

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
        if (int_tvalid) begin
          state_next = S_CTRL;
        end
      end

      S_CTRL: begin
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
        if (int_tvalid) begin
          // state_next == S_CTRL
          m_axis_tdata <= byte_reverse(32'b0);
          m_axis_tkeep <= 4'b1111;
          m_axis_tlast <= 1'b0;
        end
      end

      S_CTRL: begin
        if (m_axis_tready) begin
          // state_next == S_PAYLOAD
          m_axis_tdata <= int_tdata;
          m_axis_tkeep <= int_tkeep;
          m_axis_tlast <= int_tlast;
        end
      end

      S_PAYLOAD: begin
        if (m_axis_tready) begin
          // state_next == S_IDLE/S_PAYLOAD
          m_axis_tdata <= int_tdata;
          m_axis_tkeep <= int_tkeep;
          m_axis_tlast <= int_tlast;
        end
      end
    endcase
  end

  always_ff @(posedge clk) begin
    case (state)
      S_RST: begin
        // // state_next == S_IDLE
        m_axis_tvalid <= 1'b0;
      end

      S_IDLE: begin
        if (int_tvalid) begin
          // state_next == S_CTRL
          m_axis_tvalid <= 1'b1;
        end
      end

      S_CTRL: begin
        if (m_axis_tready) begin
          // state_next == S_PAYLOAD
          m_axis_tvalid <= int_tvalid;
        end
      end

      S_PAYLOAD: begin
        if (m_axis_tready && m_axis_tlast) begin
          // state_next == S_IDLE
          m_axis_tvalid <= 1'b0;
        end else if (m_axis_tready) begin
          // state_next == S_PAYLOAD
          m_axis_tvalid <= int_tvalid;
        end
      end

      default: begin
        m_axis_tvalid <= 1'b0;
      end
    endcase
  end

  ecpri_framer_reg #(
      .USER_WIDTH(1)
  ) i_reg (
      .clk          (clk),
      .rst          (rst),
      //
      .s_axis_tdata (s_axis_tdata),
      .s_axis_tkeep (s_axis_tkeep),
      .s_axis_tlast (s_axis_tlast),
      .s_axis_tuser (1'b0),
      .s_axis_tvalid(s_axis_tvalid),
      .s_axis_tready(s_axis_tready),
      //
      .m_axis_tdata (int_tdata),
      .m_axis_tkeep (int_tkeep),
      .m_axis_tlast (int_tlast),
      .m_axis_tuser (int_tuser),
      .m_axis_tvalid(int_tvalid),
      .m_axis_tready(int_tready)
  );

  assign int_tready = (state_next == S_PAYLOAD) && m_axis_tready;

endmodule

`default_nettype wire
