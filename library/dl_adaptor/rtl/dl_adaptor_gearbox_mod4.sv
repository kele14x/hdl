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
    output var [11:0] gb_re        [NUM_CC]  // RE number, 0 ~ 3275
);


  // Immediate data
  logic [31:0] gb_data_c;
  logic [31:0] gb_data_r;

  logic        gb_data_csf;
  logic [14:0] gb_data_scalar;
  logic [ 3:0] gb_data_i0;
  logic [ 3:0] gb_data_q0;
  logic [ 3:0] gb_data_i1;
  logic [ 3:0] gb_data_q1;

  logic [ 2:0] gb_cc_r;
  logic        gb_valid_r;
  logic [11:0] gb_re_r;

  logic [11:0] tuser_mod_remask2;
  logic        tuser_mod_csf2;
  logic [14:0] tuser_mod_scalar2;
  logic [11:0] tuser_mod_remask1;
  logic        tuser_mod_csf1;
  logic [14:0] tuser_mod_scalar1;
  logic [ 1:0] tuser_modulation_compression;
  logic        tuser_mod_param_valid;
  logic [ 2:0] tuser_component_carrier;
  logic        tuser_start_of_section;  // Used to indicate the start of a symbol of RB sections.
  logic        tuser_every_other_rb;  // Not used
  logic [ 3:0] tuser_bit_width;  // Not used
  logic [ 3:0] tuser_compression_type;  // Not used
  logic [ 7:0] tuser_num_rb;  // Not used
  logic [ 9:0] tuser_start_rb;

  logic [63:0] tdata_current;
  logic [63:0] tdata_last;
  logic [ 3:0] exp_last;

  // 12 states, read 7 words and output 24 re data
  // BFP 9:
  // 7 * 64 = 448-bit
  //        = 18 * 24 + 8 * 2
  logic [3:0] state, state_next;

  logic go_next;

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

  assign tdata_current = byte_reverse(s_axis_tdata);

  assign go_next = (state == 0 && s_axis_tvalid) ||
    (state == 1 && s_axis_tvalid) || (state == 2) ||
    (state == 3 && s_axis_tvalid) || (state == 4) ||
    (state == 5 && s_axis_tvalid) || (state == 6 && s_axis_tvalid) ||
    (state == 7) || (state == 8 && s_axis_tvalid) || (state == 9) ||
    (state == 10 && s_axis_tvalid) || (state == 11);

  // State Machine

  always_ff @(posedge clk) begin
    if (rst) begin
      state <= '0;
    end else begin
      state <= state_next;
    end
  end

  always_comb begin
    if (state >= 11) begin
      state_next = 0;  // failt recovery
    end else if (go_next && (state == 0 || state == 1 || state == 3 ||
      state == 6 || state == 8) && s_axis_tlast) begin
      // Normally we should not see TLAST at those states, but so we need to end
      // the FSM here.
      state_next = 0;
    end else if (go_next && state == 5 && s_axis_tlast) begin
      // The case odd number of RBs.
      state_next = 0;
    end else if (go_next && state == 10 && s_axis_tlast) begin
      // The case even number of RBs.
      state_next = 11;
    end else if (go_next && state == 11) begin
      state_next = 0;
    end else if (go_next) begin
      state_next = state + 1;
    end else begin
      state_next = state;
    end
  end

  // AXI4-Stream

  always_ff @(posedge clk) begin
    if (rst) begin
      s_axis_tready <= '0;
    end else if (state_next == 0 || state_next == 1 || state_next == 3 ||
      state_next == 5 || state_next == 6 || state_next == 8 ||
      state_next == 10) begin
      s_axis_tready <= 1'b1;
    end else begin
      s_axis_tready <= 1'b0;
    end
  end

  // register some old data for later use

  always_ff @(posedge clk) begin
    if (rst) begin
      tdata_last <= '0;
    end else if (s_axis_tready && s_axis_tvalid) begin
      tdata_last <= tdata_current;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      exp_last <= '0;
    end else if (state == 0 && s_axis_tvalid) begin
      exp_last <= tdata_current[59:56];
    end else if (state == 5 && s_axis_tvalid && ~s_axis_tlast) begin
      exp_last <= tdata_current[27:24];
    end else begin
      exp_last <= exp_last;
    end
  end

  // data mux, select 40-bit from tdata_current and tdata_last

  always_comb begin
    if (state == 0) begin
      gb_data_c = tdata_current[59:20];
    end else if (state == 1) begin
      gb_data_c = {exp_last, tdata_last[19:0], tdata_current[63:48]};
    end else if (state == 2) begin
      gb_data_c = {exp_last, tdata_last[47:12]};
    end else if (state == 3) begin
      gb_data_c = {exp_last, tdata_last[11:0], tdata_current[63:40]};
    end else if (state == 4) begin
      gb_data_c = {exp_last, tdata_last[39:4]};
    end else if (state == 5) begin
      gb_data_c = {exp_last, tdata_last[3:0], tdata_current[63:32]};
    end else if (state == 6) begin
      gb_data_c = {exp_last, tdata_last[23:0], tdata_current[63:52]};
    end else if (state == 7) begin
      gb_data_c = {exp_last, tdata_last[51:16]};
    end else if (state == 8) begin
      gb_data_c = {exp_last, tdata_last[15:0], tdata_current[63:44]};
    end else if (state == 9) begin
      gb_data_c = {exp_last, tdata_last[43:8]};
    end else if (state == 10) begin
      gb_data_c = {exp_last, tdata_last[7:0], tdata_current[63:36]};
    end else begin  // state == 11
      gb_data_c = {exp_last, tdata_last[35:0]};
    end
  end

  // 40-bit data out from state machine

  always_ff @(posedge clk) begin
    if (go_next) begin
      gb_data_r <= gb_data_c;
    end
  end

  assign {gb_data_exp, gb_data_i0, gb_data_q0, gb_data_i1, gb_data_q1} = gb_data_r;

  always_ff @(posedge clk) begin
    gb_valid_r <= go_next;
  end

  always_ff @(posedge clk) begin
    gb_cc_r <= tuser_component_carrier;
  end

  // If incoming packets does not come in order, this will fail.
  always_ff @(posedge clk) begin
    if (go_next) begin
      if (tuser_start_of_section) begin
        gb_re_r <= tuser_start_rb * 12;
      end else begin
        gb_re_r <= gb_re_r + 2;
      end
    end
  end

  // CC mutex

  generate
    for (genvar i = 0; i < NUM_CC; i++) begin

      always_ff @(posedge clk) begin
        gb_data[i] <= {
          10'b0, gb_data_exp, gb_data_q1, gb_data_i1, 10'b0, gb_data_exp, gb_data_q0, gb_data_i0
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
