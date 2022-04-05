// File: fir_macc.sv
// Brief: FIR using MACC (Multiply and accumulation) architecture.
//        Supports max 16 channel, 8 coefficient sets, 128 coefficient length
`timescale 1 ns / 1 ps
//
`default_nettype none

module fir_macc #(
    parameter int XIN_WIDTH  = 24,
    parameter int COE_WIDTH  = 16,
    parameter int YOUT_WIDTH = 24,
    parameter int SRA_BITS   = 15
) (
    input var  logic                  aclk,
    input var  logic                  aresetn,
    // Data input
    input var  logic [ XIN_WIDTH-1:0] s_axis_tdata,
    input var  logic                  s_axis_tvalid,
    output var logic                  s_axis_tready,
    // Data output
    output var logic [YOUT_WIDTH-1:0] m_axis_tdata,
    output var logic                  m_axis_tvalid,
    input var  logic                  m_axis_tready,
    // Status
    output var logic                  err_ovf
);

  typedef enum int {
    S_RST,
    S_IDLE,
    S_ACC,
    S_WAIT0,
    S_WAIT1,
    S_OUT
  } state_t;

  state_t state, state_next;


  // FSM
  //====

  always_ff @(posedge aclk) begin
    if (!aresetn) begin
      state <= S_RST;
    end else begin
      state <= state_next;
    end
  end

  always_comb begin
    // stay at current state by default
    state_next = state;
    case(state)
      S_RST: state_next = S_IDLE;
      S_IDLE: begin
        if (s_axis_tvalid) begin
          state_next = S_ACC;
        end
      end
      S_ACC: begin
        if (acc_done) begin
          state_next = S_WAIT0;
        end
      end
      S_WAIT0: state_next = S_WAIT1;
      S_WAIT1: state_next = S_OUT;
      S_OUT: begin
        if (m_axis_tready) begin
          state_next = S_IDLE;
        end
      end
      default: state_next = S_RST;
    endcase
  end


endmodule

`default_nettype wire
