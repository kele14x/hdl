// File: dl_adaptor_gearbox_mod4.sv
// Brief: Downlink PDxCH (DL U-Plane data) adaptor gearbox, for Modulation
//        Compression 4 format.
`timescale 1 ns / 1 ps `default_nettype none

module dl_adaptor_gearbox_mod4 #(
    parameter int NUM_CC = 2
) (
    // Interface with DFE
    //===================
    input var         clk,
    input var         rst,
    //
    input var  [63:0] s_axis_tdata,
    input var  [ 7:0] s_axis_tkeep,
    input var         s_axis_tvalid,
    input var         s_axis_tlast,
    output var        s_axis_tready,
    input var  [89:0] s_axis_tuser,
    //
    output var [63:0] gb_data      [NUM_CC],  // {8'b0, csf, scalar, Q, I, 8'b0, csf, scalar, Q, I}
    output var        gb_valid     [NUM_CC],
    output var [11:0] gb_re        [NUM_CC]   // RE number, 0 ~ 3275
);


  // Immediate data
  logic        gb_data_csf;
  logic [14:0] gb_data_scalar;
  logic [ 3:0] gb_data_q1;
  logic [ 3:0] gb_data_i1;
  logic [ 3:0] gb_data_q0;
  logic [ 3:0] gb_data_i0;

  logic [ 2:0] gb_cc_r;
  logic        gb_valid_r;
  logic [11:0] gb_re_r;

  logic [11:0] tuser_mod_remask2;  // Not used
  logic        tuser_mod_csf2;  // Not used
  logic [14:0] tuser_mod_scalar2;  // Not used
  logic [11:0] tuser_mod_remask1;  // Not used
  logic        tuser_mod_csf1;
  logic [14:0] tuser_mod_scalar1;
  logic [ 1:0] tuser_modulation_compression;  // Not used
  logic        tuser_mod_param_valid;
  logic [ 2:0] tuser_component_carrier;
  logic        tuser_start_of_section;  // Used to indicate the start of a symbol of RB sections.
  logic        tuser_every_other_rb;  // Not used
  logic [ 3:0] tuser_bit_width;  // Not used
  logic [ 3:0] tuser_compression_type;  // Not used
  logic [ 7:0] tuser_num_rb;  // Not used
  logic [ 9:0] tuser_start_rb;

  logic [63:0] s_axis_tdata_reversed;

  logic [63:0] tdata0;
  logic [63:0] tdata1;
  logic [63:0] tdata2;

  logic even_rb, odd_rb;


  // Modulation compression 4:
  // The AXIS 3 words contains 2 RBs (24 REs), or 1.5 words contain 1 RB (only when
  // number of RB within the section is odd).
  // 3 * 64 = 192-bit
  //        = 8 * 24
  // For most of the time, during 12 clock cycles, 3 words are read from the
  // input stream, and 24 REs are output. In case that there are odd REs, only
  // 1.5 words is provided by AXIS (with tlast assert at 2nd word), so 12 REs
  // are output.

  typedef enum int {
    S_RD_RST,    // Under reset
    S_RD_INIT0,  // Read first word in packet
    S_RD_WORD0,  // Read word 0, this is not first word in packet
    S_RD_WORD1,  // Read word 1, if `tlast` assert here, indicates odd number RE
    S_RD_WORD2,  // Read word 2, if `tlast` assert here, indicates even number of RE
    S_RD_WAIT0,  // Wait for writer done, this is not last word in packet
    S_RD_WAIT1   // Wait for writer done, this is last word in packet
  } rd_state_t;

  rd_state_t rd_state, rd_state_next;

  // 0 ~ 12
  logic [3:0] wr_cnt, wr_cnt_max;

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


  // Xilinx PG370, Page 57, Chapter 3, Section x Downlink U-Plane Data Ports
  assign {
    tuser_mod_remask2,
    tuser_mod_csf2,
    tuser_mod_scalar2,
    tuser_mod_remask1,
    tuser_mod_csf1,
    tuser_mod_scalar1,
    tuser_modulation_compression,
    tuser_mod_param_valid,
    tuser_component_carrier,
    tuser_start_of_section,
    tuser_every_other_rb,
    tuser_bit_width,
    tuser_compression_type,
    tuser_num_rb,
    tuser_start_rb
  } = s_axis_tuser;

  // AXIS require byte reverse
  assign s_axis_tdata_reversed = byte_reverse(s_axis_tdata);


  // AXIS Reader State Machine
  //==========================

  always_ff @(posedge clk) begin
    if (rst) begin
      rd_state <= S_RD_RST;
    end else begin
      rd_state <= rd_state_next;
    end
  end

  always_comb begin
    case (rd_state)
      S_RD_RST:   rd_state_next = S_RD_INIT0;
      S_RD_INIT0: rd_state_next = ~s_axis_tvalid ? S_RD_INIT0 : s_axis_tlast ? S_RD_INIT0 : S_RD_WORD1;
      S_RD_WORD0: rd_state_next = ~s_axis_tvalid ? S_RD_WORD0 : s_axis_tlast ? S_RD_INIT0 : S_RD_WORD1;
      S_RD_WORD1: rd_state_next = ~s_axis_tvalid ? S_RD_WORD1 : s_axis_tlast ? S_RD_WAIT1 : S_RD_WORD2;
      S_RD_WORD2: rd_state_next = ~s_axis_tvalid ? S_RD_WORD2 : s_axis_tlast ? S_RD_WAIT1 : S_RD_WAIT0;
      S_RD_WAIT0: rd_state_next = ~(wr_cnt_max - wr_cnt == 3) ? S_RD_WAIT0 : S_RD_WORD0;
      S_RD_WAIT1: rd_state_next = ~(wr_cnt_max - wr_cnt == 0) ? S_RD_WAIT1 : S_RD_INIT0;
      default: rd_state_next = S_RD_RST;
    endcase
  end

  // even number of RB
  assign even_rb = (rd_state == S_RD_WORD2 && s_axis_tvalid);

  // odd number of RB
  assign odd_rb  = (rd_state == S_RD_WORD1 && s_axis_tvalid && s_axis_tlast);

  // AXIS interface is ready when we are reading words
  always_ff @(posedge clk) begin
    s_axis_tready <= (rd_state_next == S_RD_INIT0 || rd_state_next == S_RD_WORD0
      || rd_state_next == S_RD_WORD1 || rd_state_next == S_RD_WORD2);
  end

  // register some data for later use

  always_ff @(posedge clk) begin
    if ((rd_state == S_RD_WORD0 || rd_state == S_RD_INIT0) && s_axis_tvalid) begin
      tdata0 <= s_axis_tdata_reversed;
    end
  end

  always_ff @(posedge clk) begin
    if ((rd_state == S_RD_WORD1) && s_axis_tvalid) begin
      tdata1 <= s_axis_tdata_reversed;
    end
  end

  always_ff @(posedge clk) begin
    if ((rd_state == S_RD_WORD2) && s_axis_tvalid) begin
      tdata2 <= s_axis_tdata_reversed;
    end
  end

  always_ff @(posedge clk) begin
    if ((rd_state == S_RD_INIT0) && s_axis_tvalid) begin
      gb_cc_r <= tuser_component_carrier;
    end
  end

  // Assume mod_param_valid is at first 3 ticks of the packet
  always_ff @(posedge clk) begin
    if (tuser_mod_param_valid) begin
      gb_data_csf    <= tuser_mod_csf1;
      gb_data_scalar <= tuser_mod_scalar1;
    end
  end


  // RE Writer State Machine
  //========================

  // `wr_cnt` goes from 1 to 6 when odd RB, from 0 to 11 when even RB
  always_ff @(posedge clk) begin
    if (rst) begin
      wr_cnt <= 0;
    end else if (even_rb || odd_rb) begin
      wr_cnt <= 1;
    end else if (wr_cnt > 0 && wr_cnt != wr_cnt_max) begin
      wr_cnt <= wr_cnt + 1;
    end else begin
      wr_cnt <= 0;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      wr_cnt_max <= 0;
    end else if (even_rb) begin
      wr_cnt_max <= 12;
    end else if (odd_rb) begin
      wr_cnt_max <= 6;
    end else begin
      wr_cnt_max <= wr_cnt_max;
    end
  end

  // data mux, select 16-bit data from `tdatax`
  always_ff @(posedge clk) begin
    if (wr_cnt == 1) begin
      {gb_data_q1, gb_data_i1, gb_data_q0, gb_data_i0} <= {
        tdata0[51:48], tdata0[55:52], tdata0[59:56], tdata0[63:60]
      };
    end else if (wr_cnt == 2) begin
      {gb_data_q1, gb_data_i1, gb_data_q0, gb_data_i0} <= {
        tdata0[35:32], tdata0[39:36], tdata0[43:40], tdata0[47:44]
      };
    end else if (wr_cnt == 3) begin
      {gb_data_q1, gb_data_i1, gb_data_q0, gb_data_i0} <= {
        tdata0[19:16], tdata0[23:20], tdata0[27:24], tdata0[31:28]
      };
    end else if (wr_cnt == 4) begin
      {gb_data_q1, gb_data_i1, gb_data_q0, gb_data_i0} <= {
        tdata0[3:0], tdata0[7:4], tdata0[11:8], tdata0[15:12]
      };
    end else if (wr_cnt == 5) begin
      {gb_data_q1, gb_data_i1, gb_data_q0, gb_data_i0} <= {
        tdata1[51:48], tdata1[55:52], tdata1[59:56], tdata1[63:60]
      };
    end else if (wr_cnt == 6) begin
      {gb_data_q1, gb_data_i1, gb_data_q0, gb_data_i0} <= {
        tdata1[35:32], tdata1[39:36], tdata1[43:40], tdata1[47:44]
      };
    end else if (wr_cnt == 7) begin
      {gb_data_q1, gb_data_i1, gb_data_q0, gb_data_i0} <= {
        tdata1[19:16], tdata1[23:20], tdata1[27:24], tdata1[31:28]
      };
    end else if (wr_cnt == 8) begin
      {gb_data_q1, gb_data_i1, gb_data_q0, gb_data_i0} <= {
        tdata1[3:0], tdata1[7:4], tdata1[11:8], tdata1[15:12]
      };
    end else if (wr_cnt == 9) begin
      {gb_data_q1, gb_data_i1, gb_data_q0, gb_data_i0} <= {
        tdata2[51:48], tdata2[55:52], tdata2[59:56], tdata2[63:60]
      };
    end else if (wr_cnt == 10) begin
      {gb_data_q1, gb_data_i1, gb_data_q0, gb_data_i0} <= {
        tdata2[35:32], tdata2[39:36], tdata2[43:40], tdata2[47:44]
      };
    end else if (wr_cnt == 11) begin
      {gb_data_q1, gb_data_i1, gb_data_q0, gb_data_i0} <= {
        tdata2[19:16], tdata2[23:20], tdata2[27:24], tdata2[31:28]
      };
    end else if (wr_cnt == 12) begin
      {gb_data_q1, gb_data_i1, gb_data_q0, gb_data_i0} <= {
        tdata2[3:0], tdata2[7:4], tdata2[11:8], tdata2[15:12]
      };
    end
  end

  always_ff @(posedge clk) begin
    gb_valid_r <= (1 <= wr_cnt && wr_cnt <= wr_cnt_max);
  end

  // If incoming packets does not come in order, this will fail.
  always_ff @(posedge clk) begin
    if ((rd_state == S_RD_INIT0) && s_axis_tvalid) begin
      gb_re_r <= tuser_start_rb * 12;
    end else if (gb_valid_r) begin
      gb_re_r <= gb_re_r + 2;
    end
  end


  // CC mutex
  //=========

  generate
    for (genvar i = 0; i < NUM_CC; i++) begin

      always_ff @(posedge clk) begin
        gb_data[i] <= {
          8'b0,
          gb_data_csf,
          gb_data_scalar,
          gb_data_q1,
          gb_data_i1,
          8'b0,
          gb_data_csf,
          gb_data_scalar,
          gb_data_q0,
          gb_data_i0
        };
      end

      always_ff @(posedge clk) begin
        gb_re[i] <= gb_re_r;
      end

      always_ff @(posedge clk) begin
        gb_valid[i] <= (gb_valid_r && gb_cc_r == i);
      end

    end
  endgenerate

endmodule

`default_nettype wire
