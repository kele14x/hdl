`timescale 1 ns / 1 ps `default_nettype none

module ul_adaptor_gearbox_raw #(
    parameter int NUM_CC = 2
) (
    input var         clk,
    input var         rst,
    // ul timing
    input var         ul_radio_start_10ms,
    input var         ul_update            [NUM_CC],
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
    output var [11:0] uram_addr             [NUM_CC],
    output var        uram_rden             [NUM_CC],
    input var  [63:0] uram_data             [NUM_CC]
);


  function automatic logic [63:0] byte_reverse(input logic [63:0] data);
    begin
      return {
        data[7:0],
        data[15:8],
        data[23:16],
        data[31:24],
        data[39:32],
        data[47:40],
        data[55:48],
        data[63:56]
      };
    end
  endfunction

  function automatic logic [63:0] byte2_reverse(input logic [63:0] data);
    begin
      return {
        data[15:0],
        data[31:16],
        data[47:32],
        data[63:48]
      };
    end
  endfunction

  // fram_req signal mapping
  //------------------------

  logic [8:0] fram_req_start_rb;
  logic [7:0] fram_req_num_rb;
  logic [2:0] fram_req_cc;

  assign fram_req_start_rb = fram_req_data[23:15];
  assign fram_req_num_rb   = fram_req_data[14:7];
  assign fram_req_cc       = fram_req_data[6:4];


  // fram_req FSM
  //-------------
  // This FSM will try to accept each `fram_req` when possible (not busy). When

  logic busy, busy_next;
  logic req_accept, req_done;

  always_ff @(posedge clk) begin
    if (rst) begin
      busy <= 1'b0;
    end else begin
      busy <= busy_next;
    end
  end

  always_comb begin
    case (busy)
      1'b0: busy_next = fram_req_empty ? 1'b0 : 1'b1;
      1'b1: busy_next = req_done ? 1'b0 : 1'b1;
      default: busy_next = 0;
    endcase
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      fram_req_rden <= 1'b0;
    end else begin
      fram_req_rden <= (busy_next == 1'b0);
    end
  end

  assign req_accept = (busy == 1'b0 && fram_req_empty == 1'b0);


  // Count how many RBs we read
  //---------------------------
  // re_pair_cnt will goes from 0 to 5 (6 RE pair, 12 REs)
  // rb_cnt will goes from rb_start to rb_end - 1
  // rb_end = rb_start + rb_num, which will be 1 larger than index max

  logic [8:0] rb_cnt;
  logic [8:0] rb_end;
  logic [2:0] re_pair_cnt;
  logic [2:0] rb_cc;

  assign req_done = ((rb_cnt == (rb_end - 1)) && (re_pair_cnt == 5));

  always_ff @(posedge clk) begin
    if (req_accept) begin
      rb_cnt <= fram_req_start_rb;
    end else if (busy_next && (re_pair_cnt == 7)) begin
      rb_cnt <= rb_cnt + 1;
    end else if (busy_next) begin
      rb_cnt <= rb_cnt;
    end else begin
      rb_cnt <= '0;
    end
  end

  always_ff @(posedge clk) begin
    if (req_accept) begin
      rb_end <= fram_req_start_rb + (fram_req_num_rb == 0 ? 273 : fram_req_num_rb);
    end else if (busy_next) begin
      rb_end <= rb_end;
    end else begin
      rb_end <= '0;
    end
  end

  always_ff @(posedge clk) begin
    if (req_accept) begin
      re_pair_cnt <= '0;
    end else if (busy_next) begin
      re_pair_cnt <= re_pair_cnt + 1;
    end else begin
      re_pair_cnt <= '0;
    end
  end

  always_ff @(posedge clk) begin
    if (req_accept) begin
      rb_cc <= fram_req_cc;
    end
  end


  // URAM read address generation
  //-----------------------------
  // we need to be care which CC and which band to read

  logic        wait_for_sync[NUM_CC];
  logic        uram_bank    [NUM_CC];
  logic [10:0] uram_addr_r  [NUM_CC];

  generate
    for (genvar i = 0; i < NUM_CC; i++) begin : g_addr_gen

      // we need to handle the case that up_radio_start arrives few clock ticks
      // earlier than ul_update (UL symbol number update).
      always_ff @(posedge clk) begin
        if (rst) begin
          wait_for_sync[i] <= 1'b0;
        end else if (ul_radio_start_10ms && ul_update[i]) begin
          wait_for_sync[i] <= 1'b0;
        end else if (ul_radio_start_10ms) begin
          wait_for_sync[i] <= 1'b1;
        end else if (ul_update[i]) begin
          wait_for_sync[i] <= 1'b0;
        end
      end

      always_ff @(posedge clk) begin
        if (rst) begin
          uram_bank[i] <= 1'b0;
        end else if (ul_radio_start_10ms) begin
          uram_bank[i] <= 1'b0;
        end else if (ul_update[i] && wait_for_sync[i]) begin
          // this the case that ul_update arrives late than up_radio_start_10ms
          // we should not set it to ~uram_bank, which will be 1
          uram_bank[i] <= 1'b0;
        end else if (ul_update[i]) begin
          uram_bank[i] <= ~uram_bank[i];
        end
      end

      always_ff @(posedge clk) begin
        if (busy && (rb_cc == i)) begin
          uram_addr_r[i] <= (rb_cnt << 2) + (rb_cnt << 1) + re_pair_cnt;
          // rb_cnt * 6 + re_pari_cnt
        end else begin
          uram_addr_r[i] <= '0;
        end
      end

      always_ff @(posedge clk) begin
        if (rst) begin
          uram_rden[i] <= '0;
        end else begin
          uram_rden[i] <= (busy && (rb_cc == i) && (re_pair_cnt <= 5));
        end
      end

      assign uram_addr[i] = {uram_bank[i], uram_addr_r[i]};

    end
  endgenerate



  // Match URAM delay
  //-----------------

  logic [2:0] re_cnt_d  [5];
  logic       re_valid_d[5];
  logic       re_done_d [5];
  logic [2:0] re_cc_pre [4];

  always_ff @(posedge clk) begin
    re_cc_pre[0] <= rb_cc;
    for (int i = 1; i < 4; i++) begin
      re_cc_pre[i] <= re_cc_pre[i-1];
    end
  end

  always_ff @(posedge clk) begin
    re_cnt_d[0] <= re_pair_cnt;
    for (int i = 1; i < 5; i++) begin
      re_cnt_d[i] <= re_cnt_d[i-1];
    end
  end

  always_ff @(posedge clk) begin
    re_valid_d[0] <= busy && (re_pair_cnt <= 5);
    for (int i = 1; i < 5; i++) begin
      re_valid_d[i] <= re_valid_d[i-1];
    end
  end

  always_ff @(posedge clk) begin
    re_done_d[0] <= req_done;
    for (int i = 1; i < 5; i++) begin
      re_done_d[i] <= re_done_d[i-1];
    end
  end


  // Output stage
  //-------------

  always_ff @(posedge clk) begin
    m_axis_tdata <= byte_reverse(byte2_reverse(uram_data[re_cc_pre[3]]));
  end

  assign m_axis_tkeep  = '1;
  assign m_axis_tvalid = re_valid_d[4];
  assign m_axis_tlast  = re_done_d[4];

endmodule

`default_nettype wire
