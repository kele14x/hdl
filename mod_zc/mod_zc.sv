`timescale 1ns / 1ps
//
`default_nettype none

module mod_zc (
    input var        clk,
    //
    input var  [2:0] block_size_ils,
    input var  [2:0] block_size_zj,
    input var  [8:0] shift_in,
    //
    output var [2:0] subblock_size_ils,
    output var [2:0] subblock_size_zj,
    output var [2:0] num_subblock,
    output var [5:0] shift_out
);


  // Signals
  //========

  logic [ 2:0] t_ils, t_ils_d;
  logic [ 2:0] t_zj, t_zj_d;
  logic [ 2:0] t_num, t_num_d;

  logic [ 8:0] shift_in_d;

  // quotient and remainder after division of shift and block_size_ils
  (* ram_style="block" *)
  logic [11:0] quot_rem_table[2**3 * 2**9];
  logic [11:0] table_addr;
  logic [11:0] table_data;

  logic [ 3:0] rem1;
  logic [ 7:0] quot1;


  // Functions
  //==========

  function automatic [3:0] ils_map(input logic [2:0] ils);
    if (ils == 0) begin
      return 4'b0010;
    end else begin
      return {ils, 1'b1};
    end
  endfunction

  function automatic [2:0] get_subblock_ils(input logic [2:0] ils, input logic [2:0] zj);
    logic [2:0] ils_table[64] = {
      0, 0, 0, 0, 0, 0, 0, 0,  // ils = 0
      1, 1, 1, 1, 1, 1, 0, 0,  // ils = 1
      2, 2, 2, 2, 2, 2, 0, 0,  // ils = 2
      3, 3, 3, 3, 3, 3, 0, 0,  // ils = 3
      4, 4, 4, 4, 1, 1, 0, 0,  // ils = 4
      5, 5, 5, 5, 5, 5, 0, 0,  // ils = 5
      6, 6, 6, 6, 6, 0, 0, 0,  // ils = 6
      7, 7, 7, 7, 7, 0, 0, 0   // ils = 7
    };
    return ils_table[{ils, zj}];
  endfunction

  function automatic [2:0] get_subblock_zj(input logic [2:0] ils, input logic [2:0] zj);
    logic [2:0] zj_table[64] = {
      0, 1, 2, 3, 4, 5, 5, 5,  // ils = 0
      0, 1, 2, 3, 4, 4, 5, 5,  // ils = 1
      0, 1, 2, 3, 3, 3, 5, 0,  // ils = 2
      0, 1, 2, 3, 3, 3, 0, 0,  // ils = 3
      0, 1, 2, 2, 4, 4, 0, 0,  // ils = 4
      0, 1, 2, 2, 2, 2, 0, 0,  // ils = 5
      0, 1, 2, 2, 2, 0, 0, 0,  // ils = 6
      0, 1, 2, 2, 2, 0, 0, 0   // ils = 7
    };
    return zj_table[{ils, zj}];
  endfunction

  function automatic [2:0] get_num_subblock(input logic [2:0] ils, input logic [2:0] zj);
    logic [2:0] n_table[64] = {
      0, 0, 0, 0, 0, 0, 1, 3,  // ils = 0
      0, 0, 0, 0, 0, 1, 2, 5,  // ils = 1
      0, 0, 0, 0, 1, 3, 4, 0,  // ils = 2
      0, 0, 0, 0, 1, 3, 0, 0,  // ils = 3
      0, 0, 0, 1, 2, 5, 0, 0,  // ils = 4
      0, 0, 0, 1, 3, 7, 0, 0,  // ils = 5
      0, 0, 0, 1, 3, 0, 0, 0,  // ils = 6
      0, 0, 0, 1, 3, 0, 0, 0   // ils = 7
    };
    return n_table[{ils, zj}];
  endfunction


  // Main
  //=====

  // Find the sub-block size, still in a * 2 ^ zj format

  always_ff @(posedge clk) begin
    t_ils <= get_subblock_ils(block_size_ils, block_size_zj);
    t_zj  <= get_subblock_zj(block_size_ils, block_size_zj);
    t_num <= get_num_subblock(block_size_ils, block_size_zj);
  end

  always_ff @(posedge clk) begin
    t_ils_d <= t_ils;
    t_zj_d <= t_zj;
    t_num_d <= t_num;
    subblock_size_ils <= t_ils_d;
    subblock_size_zj <= t_zj_d;
    num_subblock <= t_num_d;
  end

  // Get the rem(shift_in, sub-block_size)

  initial begin
    for (int a = 0; a < 8; a++) begin
      for (int i = 0; i < 512; i++) begin
        logic [3:0] rem;
        logic [7:0] quot;
        rem = i % ils_map(a);
        quot = i / ils_map(a);
        quot_rem_table[a*512+i] = {rem, quot};
      end
    end
  end

  always_ff @(posedge clk) begin
    shift_in_d <= shift_in;
  end

  assign table_addr = {t_ils, shift_in_d};

  always_ff @(posedge clk) begin
    table_data <= quot_rem_table[table_addr];
  end

  assign {rem1, quot1} = table_data;

  always_ff @(posedge clk) begin
    shift_out <= rem1 + ils_map(t_ils_d) * (quot1 % 2 ** t_zj);
  end

endmodule

`default_nettype wire
