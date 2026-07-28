// File: fft_radix2_bf2.sv
// Brief: Radix-2 Butterfly operator for FFT.
`default_nettype none
//
`timescale 1 ns / 1 ps

module fft_radix2_bf2 #(
    parameter int LOG_SIZE   = 4,
    parameter bit HAS_NJ     = 0,
    parameter int DATA_WIDTH = 16
) (
    input var                          clk,
    input var                          rst,
    //
    input var  signed [DATA_WIDTH-1:0] data_i_in,
    input var  signed [DATA_WIDTH-1:0] data_q_in,
    input var                          data_valid_in,
    input var                          data_last_in,
    //
    output var signed [  DATA_WIDTH:0] data_i_out,
    output var signed [  DATA_WIDTH:0] data_q_out,
    output var                         data_valid_out,
    output var                         data_last_out
);


  // Signals
  //========

  // state = 0: idle or first data sample;
  //         1: left data sample
  logic                               state;
  // Counter count from 0 to LOG_FFT_SIZE - 1
  logic        [        LOG_SIZE-1:0] counter;

  logic                               shift_en;

  logic                               sel;
  logic                               nj;

  logic signed [        DATA_WIDTH:0] data_i_t;
  logic signed [        DATA_WIDTH:0] data_q_t;
  //
  logic signed [        DATA_WIDTH:0] data_i_s;
  logic signed [        DATA_WIDTH:0] data_q_s;
  //
  logic signed [        DATA_WIDTH:0] delay_i_in;
  logic signed [        DATA_WIDTH:0] delay_q_in;
  logic                               delay_valid_in;
  logic                               delay_last_in;
  logic        [(DATA_WIDTH+1)*2+1:0] delay_in;
  //
  logic signed [        DATA_WIDTH:0] delay_i_out;
  logic signed [        DATA_WIDTH:0] delay_q_out;
  logic                               delay_valid_out;
  logic                               delay_last_out;
  logic        [(DATA_WIDTH+1)*2+1:0] delay_out;

  // State Counter
  //==============

  always_ff @(posedge clk) begin
    if (rst) begin
      state <= 1'b0;
    end else if (data_valid_in && data_last_in) begin
      state <= 1'b0;
    end else if (data_valid_in) begin
      state <= 1'b1;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      counter <= 'd0;
    end else if (data_valid_in && data_last_in) begin
      counter <= 'd0;
    end else if (data_valid_in) begin
      counter <= counter + 1;
    end
  end

  assign shift_en = data_valid_in || ~state;

  assign sel = counter[LOG_SIZE-1];

  generate
    if (HAS_NJ) begin : g_nj
      assign nj = counter[LOG_SIZE-1] && counter[LOG_SIZE-2];
    end else begin : g_no_nj
      assign nj = 1'b0;
    end
  endgenerate


  // Butterfly Operation
  //====================

  // * -j
  always_comb begin
    if (nj) begin
      data_i_t = {data_q_in[DATA_WIDTH-1], data_q_in};
      data_q_t = -{data_i_in[DATA_WIDTH-1], data_i_in};
    end else begin
      data_i_t = {data_i_in[DATA_WIDTH-1], data_i_in};
      data_q_t = {data_q_in[DATA_WIDTH-1], data_q_in};
    end
  end

  // Output to delay path
  always_comb begin
    if (sel) begin
      delay_i_in = delay_i_out - data_i_t;
      delay_q_in = delay_q_out - data_q_t;
    end else begin
      delay_i_in = data_i_t;
      delay_q_in = data_q_t;
    end
  end

  // To (next) BF or output
  always_comb begin
    if (sel) begin
      data_i_s = delay_i_out + data_i_t;
      data_q_s = delay_q_out + data_q_t;
    end else begin
      data_i_s = delay_i_out;
      data_q_s = delay_q_out;
    end
  end

  // Delay

  assign delay_valid_in = data_valid_in;
  assign delay_last_in = data_last_in;

  assign delay_in = {delay_last_in, delay_valid_in, delay_q_in, delay_i_in};
  assign {delay_last_out, delay_valid_out, delay_q_out, delay_i_out} = delay_out;

  generate
    if (2 ** (LOG_SIZE - 1) <= 128) begin : g_srl

      delay #(
          .WIDTH(2 * (DATA_WIDTH + 1) + 2),
          .DEPTH(2 ** (LOG_SIZE - 1)),
          .INIT (1'b0)
      ) i_delay (
          .clk (clk),
          .rst (rst),
          .cen (shift_en),
          .din (delay_in),
          .dout(delay_out)
      );

    end else begin : g_shift_ram

      shift_ram #(
          .WIDTH    (2 * (DATA_WIDTH + 1) + 2),
          .DEPTH    (2 ** (LOG_SIZE - 1)),
          .INPUT_REG(1'b0)
      ) i_delay (
          .clk (clk),
          .rst (rst),
          .cen (shift_en),
          .din (delay_in),
          .dout(delay_out)
      );

    end
  endgenerate

  // Output register

  always_ff @(posedge clk) begin
    data_i_out     <= data_i_s;
    data_q_out     <= data_q_s;
    data_valid_out <= delay_valid_out;
    data_last_out  <= delay_last_out;
  end

endmodule

`default_nettype wire
