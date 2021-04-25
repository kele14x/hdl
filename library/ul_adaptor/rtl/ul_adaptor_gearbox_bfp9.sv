`timescale 1 ns / 1 ps `default_nettype none
module ul_adaptor_gearbox_bfp9 #(
    parameter int NUM_CC = 2
) (
    input var         clk,
    input var         rst,
    //
    input var         ul_radio_start_10ms,
    input var         ul_update            [NUM_CC],
    // AXIS
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
    output var        uram_bank            [NUM_CC],
    output var [11:0] uram_addr            [NUM_CC],
    output var        uram_rden            [NUM_CC],
    input var  [63:0] uram_data            [NUM_CC]
);

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
    if (rst) begin
      rb_cnt <= '0;
    end else if (req_accept) begin
      rb_cnt <= fram_req_start_rb;
    end else if (busy_next && (re_pair_cnt == 5)) begin
      rb_cnt <= rb_cnt + 1;
    end else if (busy_next) begin
      rb_cnt <= rb_cnt;
    end else begin
      rb_cnt <= '0;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      rb_end <= '0;
    end else if (req_accept) begin
      rb_end <= fram_req_start_rb + fram_req_num_rb;
    end else if (busy_next) begin
      rb_end <= rb_end;
    end else begin
      rb_end <= '0;
    end
  end

  always_ff @ (posedge clk) begin
    if (rst) begin
      re_pair_cnt <= '0;
    end else if (req_accept) begin
      re_pair_cnt <= '0;
    end else if (busy_next) begin
      re_pair_cnt <= ((re_pair_cnt == 5) ? 0 : re_pair_cnt + 1);
    end else begin
      re_pair_cnt <= '0;
    end
  end

  always_ff @ (posedge clk) begin
    if (rst) begin
      rb_cc <= 0;
    end else if (req_accept) begin
      rb_cc <= fram_req_cc;
    end
  end


  // URAM read address generation
  //-----------------------------
  // we need to be care which CC and which band to read

  logic wait_for_sync [NUM_CC];

  generate
    for (genvar i = 0; i < NUM_CC; i++) begin

      // we need to handle the case that up_radio_start arrives few clock ticks
      // earlier than ul_update (UL symbol number update).
      always_ff @ (posedge clk) begin
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

      always_ff @ (posedge clk) begin
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

      always_ff @ (posedge clk) begin
        if (rst) begin
          uram_addr[i] <= '0;
        end else if (busy && (rb_cc == i)) begin
          uram_addr[i] <= (rb_cnt << 2) + (rb_cnt << 1) + re_pair_cnt;
          // rb_cnt * 6 + re_pari_cnt
        end else begin
          uram_addr[i] <= '0;
        end
      end

      always_ff @ (posedge clk) begin
        if (rst) begin
          uram_rden[i] <= '0;
        end else begin
          uram_rden[i] <= (busy && (rb_cc == i));
        end
      end

    end
  endgenerate


  // Match URAM delay
  //----------------

  logic [63:0] rd_data;
  logic        rd_valid;
  logic        rd_done;

  logic [ 2:0] rd_cc_pre;

  reg_pipeline #(
    .DATA_WIDTH     (1),
    .PIPELINE_STAGES(5)
  ) i_reg_pipeline_valid (
    .clk (clk),
    .din (busy),
    .dout(rd_valid)
  );

  reg_pipeline #(
    .DATA_WIDTH     (1),
    .PIPELINE_STAGES(5)
  ) i_reg_pipeline_last (
    .clk (clk),
    .din (req_done),
    .dout(rd_done)
  );

  reg_pipeline #(
    .DATA_WIDTH     (3),
    .PIPELINE_STAGES(4)
  ) i_reg_pipeline_cc (
    .clk (clk),
    .din (rb_cc),
    .dout(rd_cc_pre)
  );

  always_ff @(posedge clk) begin
    rd_data <= uram_data[rd_cc_pre];
  end

  // AXIS FSM
  //---------
  // Write 7-word (24 REs) or 3.5-word (12 REs) to AXI-Stream interface

  // Two RBs data
  logic [ 7:0] rb0_exp;
  logic [17:0] rb0_re [12]; // {i[8:0], q[8:0]}
  //
  logic [ 7:0] rb1_exp;
  logic [17:0] rb1_re [12];

  logic axis_rb_valid;
  logic axis_rb_cnt;

  logic [3:0] axis_state, axis_state_next; // 0 ~ 6

  always_ff @(posedge clk) begin
    if (rst) begin
      axis_state <= '1;
    end else begin
      axis_state <= axis_state_next;
    end
  end

  always_comb begin
    case (axis_state)
      0      : axis_state_next = m_axis_tready ? 1 : 0;
      1      : axis_state_next = m_axis_tready ? 2 : 1;
      2      : axis_state_next = m_axis_tready ? 3 : 2;
      3      : axis_state_next = m_axis_tready ? ((axis_rb_cnt == 1) ? 15 : 4) : 3;
      4      : axis_state_next = m_axis_tready ? 5 : 4;
      5      : axis_state_next = m_axis_tready ? 6 : 5;
      6      : axis_state_next = m_axis_tready ? ((axis_rb_cnt == 2) ? 15 : 0) : 6;
      15     : axis_state_next = axis_rb_valid ? 0 : 15;
      default: axis_state_next = 15;
    endcase
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      m_axis_tdata <= '0;
    end else if (axis_state_next == 0) begin
      m_axis_tdata <= {rb0_exp, rb0_re[0], rb0_re[1], rb0_re[2], rb0_re[3][17:16]};
    end else if (axis_state_next == 1) begin
      m_axis_tdata <= {rb0_re[3][15:0], rb0_re[4], rb0_re[5], rb0_re[6][17:6]};
    end else if (axis_state_next == 2) begin
      m_axis_tdata <= {rb0_re[6][5:0], rb0_re[7], rb0_re[8], rb0_re[9], rb0_re[10][17:14]};
    end else if (axis_state_next == 3) begin
      m_axis_tdata <= {rb0_re[10][13:0], rb0_re[11], rb1_exp, rb1_re[0], rb1_re[1][17:12]};
    end else if (axis_state_next == 4) begin
      m_axis_tdata <= {rb1_re[1][11:0], rb1_re[2],rb1_re[3], rb1_re[4][17:2]};
    end else if (axis_state_next == 5) begin
      m_axis_tdata <= {rb1_re[4][1:0], rb1_re[5], rb1_re[6], rb1_re[7], rb1_re[8][17:10]};
    end else begin // 6
      m_axis_tdata <= {rb1_re[8][9:0], rb1_re[9], rb1_re[10], rb1_re[11]};
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      m_axis_tkeep <= '0;
    end else if (axis_state_next == 0) begin
      m_axis_tkeep <= '1;
    end else if (axis_state_next == 1) begin
      m_axis_tkeep <= '1;
    end else if (axis_state_next == 2) begin
      m_axis_tkeep <= '1;
    end else if (axis_state_next == 3) begin
      m_axis_tkeep <= '1;
    end else if (axis_state_next == 4) begin
      m_axis_tkeep <= '1;
    end else if (axis_state_next == 5) begin
      m_axis_tkeep <= '1;
    end else if (axis_state_next == 6) begin
      m_axis_tkeep <= '1;
    end else begin
      m_axis_tkeep <= '0;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      m_axis_tvalid <= '0;
    end else if (axis_state_next == 0) begin
      m_axis_tvalid <= '1;
    end else if (axis_state_next == 1) begin
      m_axis_tvalid <= '1;
    end else if (axis_state_next == 2) begin
      m_axis_tvalid <= '1;
    end else if (axis_state_next == 3) begin
      m_axis_tvalid <= '1;
    end else if (axis_state_next == 4) begin
      m_axis_tvalid <= '1;
    end else if (axis_state_next == 5) begin
      m_axis_tvalid <= '1;
    end else if (axis_state_next == 6) begin
      m_axis_tvalid <= '1;
    end else begin
      m_axis_tvalid <= '0;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      m_axis_tlast <= '0;
    end else if (axis_state_next == 0) begin
      m_axis_tlast <= '0;
    end else if (axis_state_next == 1) begin
      m_axis_tlast <= '0;
    end else if (axis_state_next == 2) begin
      m_axis_tlast <= '0;
    end else if (axis_state_next == 3) begin
      m_axis_tlast <= '0;
    end else if (axis_state_next == 4) begin
      m_axis_tlast <= '0;
    end else if (axis_state_next == 5) begin
      m_axis_tlast <= '0;
    end else if (axis_state_next == 6) begin
      m_axis_tlast <= '0;
    end else begin
      m_axis_tlast <= '0;
    end
  end

endmodule

`default_nettype wire
