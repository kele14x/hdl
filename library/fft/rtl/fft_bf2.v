// File: fft_bf2.v
// Brief: Radix-2 Butterfly operator for FFT.
`default_nettype none
//
`timescale 1 ns / 1 ps

module fft_bf2 #(
    parameter integer DATA_WIDTH = 16
) (
    input  wire                         sel,
    //
    input  wire signed [  DATA_WIDTH:0] delayed_i_in,
    input  wire signed [  DATA_WIDTH:0] delayed_q_in,
    //
    input  wire signed [DATA_WIDTH-1:0] data_i_in,
    input  wire signed [DATA_WIDTH-1:0] data_q_in,
    //
    output reg signed  [  DATA_WIDTH:0] delayed_i_out,
    output reg signed  [  DATA_WIDTH:0] delayed_q_out,
    //
    output reg signed  [  DATA_WIDTH:0] data_i_out,
    output reg signed  [  DATA_WIDTH:0] data_q_out
);

  localparam integer Latency = 0;

  // Output to delay path
  always @(*) begin
    if (sel) begin
      delayed_i_out = delayed_i_in - data_i_in;
      delayed_q_out = delayed_q_in - data_q_in;
    end else begin
      delayed_i_out = {data_i_in[DATA_WIDTH-1], data_i_in};
      delayed_q_out = {data_q_in[DATA_WIDTH-1], data_q_in};
    end
  end

  // To (next) BF or output
  always @(*) begin
    if (sel) begin
      data_i_out = delayed_i_in + data_i_in;
      data_q_out = delayed_q_in + data_q_in;
    end else begin
      data_i_out = delayed_i_in;
      data_q_out = delayed_q_in;
    end
  end

endmodule

`default_nettype wire
