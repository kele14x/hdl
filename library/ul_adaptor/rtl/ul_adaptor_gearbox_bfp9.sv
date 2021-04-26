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
    for (genvar i = 0; i < NUM_CC; i++) begin: g_addr_gen

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
  logic [ 2:0] rd_cnt;

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
    .PIPELINE_STAGES(5)
  ) i_reg_pipeline_cnt (
    .clk (clk),
    .din (re_pair_cnt),
    .dout(rd_cnt)
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

  // BFP9 Compression
  //-----------------

  logic [63:0] rd_data_d [8];
  logic [ 2:0] rd_cnt_d  [8];
  logic        rd_valid_d[8];
  logic        rd_done_d [8];

  logic [3:0] exp_0, exp_1, exp_2, exp_3, exp_mt, exp_ma;
  logic [3:0] comp_exp_pre;
  
  logic [ 3:0] comp_exp; // actually 0 ~ 7, but 4-bit is specified in std.
  logic [35:0] comp_mantissa;
  logic [ 3:0] comp_cnt; // 0 ~ 11, 12-state
  logic        comp_valid;
  logic        comp_done;

  // Get the BFP9 exponent value based on the 16-bit data, for example
  // 16'b0000000_000000001_ => exp = 0
  // 16'b0000_010000000_000 => exp = 3
  // 16'b_010000000_0000000 => exp = 7
  function automatic [3:0] get_exp(input logic [15:0] data);
    int i;
    for (i = 15; i >= 9; i--) begin
      if (data[i] != data[i-1]) begin
        return (i - 8);
      end
    end
    return 0;
  endfunction

  assign exp_0 = get_exp(rd_data[15: 0]);
  assign exp_1 = get_exp(rd_data[31:16]);
  assign exp_2 = get_exp(rd_data[47:32]);
  assign exp_3 = get_exp(rd_data[63:48]);

  // exp_mt is largest of exp_0 ~ exp_3
  always_ff @ (posedge clk) begin
    automatic logic [3:0] temp;
    temp = (exp_0 > exp_1) ? exp_0 : exp_1;
    temp = temp > exp_2 ? temp : exp_2;
    temp = temp > exp_3 ? temp : exp_3;
    exp_mt <= temp;
  end

  // Delay line
  
  always_ff @ (posedge clk) begin
    rd_cnt_d[0] <= rd_cnt;
    for (int i = 1; i < 8; i++) begin
      rd_cnt_d[i] <= rd_cnt_d[i-1];
    end
  end

  always_ff @(posedge clk) begin
    rd_data_d[0] <= rd_data;
    for (int i = 1; i < 8; i++) begin
      rd_data_d[i] <= rd_data_d[i-1];
    end
  end

  always_ff @(posedge clk) begin
    rd_valid_d[0] <= rd_valid;
    for (int i = 1; i < 8; i++) begin
      rd_valid_d[i] <= rd_valid_d[i-1];
    end
  end

  always_ff @(posedge clk) begin
    rd_done_d[0] <= rd_done;
    for (int i = 1; i < 8; i++) begin
      rd_done_d[i] <= rd_done_d[i-1];
    end
  end

  always_ff @ (posedge clk) begin
    if (rd_cnt_d[0] == 0) begin
      exp_ma <= exp_mt;
    end else begin
      exp_ma <= exp_ma > exp_mt ? exp_ma : exp_mt;
    end
  end


  always_ff @ (posedge clk) begin
    if (rd_cnt_d[1] == 5) begin
      comp_exp_pre <= exp_ma;
    end
  end

  always_ff @ (posedge clk) begin
    comp_exp <= comp_exp_pre;
  end

  always_ff @ (posedge clk) begin
    comp_mantissa[35:27] <= rd_data_d[7][15: 0] >> comp_exp_pre; // re0_i
    comp_mantissa[26:18] <= rd_data_d[7][31:16] >> comp_exp_pre; // re0_q
    comp_mantissa[17: 9] <= rd_data_d[7][47:32] >> comp_exp_pre; // re1_i
    comp_mantissa[ 8: 0] <= rd_data_d[7][63:48] >> comp_exp_pre; // re1_q
  end

  always_ff @(posedge clk) begin
    comp_valid <= rd_valid_d[7];
  end
  
  always_ff @(posedge clk) begin
    comp_done <= rd_done_d[7];
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      comp_cnt <= '1;
    end else if (rd_valid_d[7]) begin
      comp_cnt <= ((comp_cnt == 11) ? 0 : (comp_cnt + 1));
    end else begin
      comp_cnt <= '1;
    end
  end


  // AXIS FSM
  //---------
  // Write 7-word (24 REs) or 3.5-word (12 REs) to AXI-Stream interface

  logic [35:0] comp_mantissa_d;
  logic [35:0] comp_mantissa_dd;

  logic comp_done_odd;

  always_ff @ (posedge clk) begin
    comp_mantissa_d  <= comp_mantissa;
    comp_mantissa_dd <= comp_mantissa_d;
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      m_axis_tdata <= '0;
    end else if (comp_cnt == 1) begin
      m_axis_tdata <= {4'b0, comp_exp, comp_mantissa_d, comp_mantissa[35:16]};
    end else if (comp_cnt == 3) begin
      m_axis_tdata <= {comp_mantissa_dd[15:0], comp_mantissa_d, comp_mantissa[35:24]};
    end else if (comp_cnt == 5) begin
      m_axis_tdata <= {comp_mantissa_dd[23:0], comp_mantissa_d, comp_mantissa[35:32]};
    end else if (comp_cnt == 6 || comp_done_odd) begin
      m_axis_tdata <= {comp_mantissa_d[31:0], 4'b0, comp_exp, comp_mantissa[35:12]};
    end else if (comp_cnt == 8) begin
      m_axis_tdata <= {comp_mantissa_dd[11:0], comp_mantissa_d, comp_mantissa[35:20]};
    end else if (comp_cnt == 10) begin
      m_axis_tdata <= {comp_mantissa_dd[19:0], comp_mantissa_d, comp_mantissa[35:28]};
    end else if (comp_cnt == 11) begin
      m_axis_tdata <= {comp_mantissa_d[27:0], comp_mantissa};
    end else begin
      m_axis_tdata <= m_axis_tdata;
    end 
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      m_axis_tkeep <= '0;

    end else begin
      m_axis_tkeep <= comp_done_odd ? 8'h0F : 8'hFF;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      m_axis_tvalid <= '0;
    end else begin
      m_axis_tvalid <= ((comp_cnt == 1) || (comp_cnt == 3) || 
        (comp_cnt == 5) || (comp_cnt == 6) || (comp_cnt == 8) ||
        (comp_cnt == 10) || (comp_cnt == 11) || comp_done_odd) && comp_valid;
    end
  end

  always_ff @ (posedge clk) begin
    comp_done_odd <= (comp_cnt == 5 && comp_done);
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      m_axis_tlast <= '0;

    end else begin
      m_axis_tlast <= comp_done_odd || (comp_cnt == 11 && comp_done);
    end
  end

endmodule

`default_nettype wire