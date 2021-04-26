`timescale 1 ns / 1 ps `default_nettype none

module ul_adaptor_gearbox_raw #(
    parameter int NUM_CC = 2
) (
    input var         clk,
    input var         rst,
    // ul timing
    input var         fram_radio_start_10ms,
    // ul data
    output var [63:0] m_axis_tdata,
    output var [ 7:0] m_axis_tkeep,
    output var        m_axis_tvalid,
    output var        m_axis_tlast,
    input var         m_axis_tready,
    // FIFO
    input var  [23:0] fram_req_data,
    input var         fram_req_empty,
    output var        fram_req_rden,
    // URAM
    output var [11:0] ram_addr             [NUM_CC],
    output var        ram_rden             [NUM_CC],
    input var  [63:0] ram_data             [NUM_CC]
);

  // Signals
  //========

  logic [8:0] fram_req_start_rb;
  logic [7:0] fram_req_num_rb;
  logic [2:0] fram_req_cc;

  // Simple state
  logic state_busy, state_busy_next;
  
  // Helper
  logic req_accept;
  logic req_done;

  logic [8:0] rb_index; // 0 ~ 273
  logic [8:0] rb_end; // 0 ~ 273
  logic [3:0] re_pair_cnt; // 0 ~ 11


  // Signal Mapping
  //===============

  assign fram_req_start_rb = fram_req_data[23:15];
  assign fram_req_num_rb   = fram_req_data[14:7];
  assign fram_req_cc       = fram_req_data[6:4];


  // Processes
  //==========

  // Request Accept State Machine
  //------------------------------
  // Try to accept fram_req_data if not busy, at each request, drive the read
  // state machine done a reading loop.

  always_ff @ (posedge clk) begin
    if (rst) begin
      state_busy <= 0;
    end else begin
      state_busy <= state_busy_next;
    end
  end

  always_comb begin
      case (state_busy)
        1'b0: state_busy_next = fram_req_empty ? 1'b0 : 1'b1;
        1'b1: state_busy_next = req_done ? 1'b0 : 1'b1;
        default: state_busy_next = 1'b0;
      endcase
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      fram_req_rden <= 1'b0;
    end else begin
      fram_req_rden <= (state_busy_next == 1'b0);
    end
  end

  assign req_accept = (state_busy == 0 && fram_req_empty == 0);

  // Accepted one request
  //---------------------
  // Upon each accpeted request, drive the reader to run a ciricle

  // Index of last RB that required, for example, if XORIF require 100 RBs 
  // from RB index 0, then the end RB index is 99.
  always_ff @ (posedge clk) begin
    if (rst) begin
      rb_end <= '0;
    end else if (req_accept) begin
      rb_end <= fram_req_start_rb + fram_req_num_rb - 1;
    end
  end

  // Index of RB that to be read out 
  always_ff @ (posedge clk) begin
    if (rst) begin
      rb_index <= '0;
    end else if (req_accept) begin
      rb_index <= fram_req_start_rb;
    end
  end

  always_ff @ (posedge clk) begin
    if (rst) begin
      re_pair_cnt <= '0;
    end
  end

endmodule

`default_nettype wire
