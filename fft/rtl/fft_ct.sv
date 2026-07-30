// Radix-2 Butterfly operator for FFT.
// Latency: 2 * (LOG_FFT_SIZE - 1) + 1
`timescale 1 ns / 1 ps
//
`default_nettype none

module fft_ct #(
    parameter integer NUM_ANT      = 4,
    parameter reg     INV_FFT      = 1'b0,
    parameter integer LOG_FFT_SIZE = 4,
    parameter integer DATA_WIDTH   = 18
) (
    input  wire                         clk,
    input  wire                         rst,
    //
    input  wire signed [DATA_WIDTH-1:0] din_dr,
    input  wire signed [DATA_WIDTH-1:0] din_di,
    input  wire                         din_dv,
    //
    output reg signed  [DATA_WIDTH-1:0] dout_dr,
    output reg signed  [DATA_WIDTH-1:0] dout_di,
    output reg                          dout_dv,
    //
    input  wire        [           1:0] ctrl_itlv,
    input  wire                         ctrl_bypass
);

  // Signals

  // Counter count from 0 to LOG_FFT_SIZE - 1
  reg        [             3:0] counter_ch;
  wire       [             3:0] counter_ch_max;
  reg        [LOG_FFT_SIZE-1:0] counter;
  reg                           state;

  wire                          swap;

  reg signed [  DATA_WIDTH-1:0] data_r_s;
  reg signed [  DATA_WIDTH-1:0] data_i_s;

  // Main

  // Keep a state counter for each channel

  assign counter_ch_max = ((ctrl_itlv == 2'b00) ? 4'd15 : (ctrl_itlv == 2'b01) ? 4'd7 : 4'd3) ^ {4{(NUM_ANT != 0) & 1'b0}};

  always @(posedge clk) begin
    if (rst) begin
      counter_ch <= 'd0;
    end else if (ctrl_bypass) begin
      counter_ch <= 'd0;
    end else if (din_dv || state) begin
      counter_ch <= (counter_ch == counter_ch_max) ? 'd0 : (counter_ch + 1'b1);
    end else begin
      counter_ch <= 'd0;
    end
  end

  always @(posedge clk) begin
    if (rst) begin
      counter <= 'd0;
    end else if (ctrl_bypass) begin
      counter <= 'd0;
    end else if (state) begin
      counter <= (counter_ch == counter_ch_max) ? (counter + 1'b1) : counter;
    end else begin
      counter <= 'd0;
    end
  end

  always @(posedge clk) begin
    if (rst) begin
      state <= 1'b0;
    end else if (ctrl_bypass) begin
      state <= 1'b0;
    end else if ((counter_ch == counter_ch_max) && &counter) begin
      state <= 1'b0;
    end else if (din_dv) begin
      state <= 1'b1;
    end
  end

  // swap is done for coarse twiddle factor
  assign swap = &counter[LOG_FFT_SIZE-1-:2];

  always @(*) begin
    if (swap) begin
      data_r_s = ~INV_FFT ? din_di : -din_di;
      data_i_s = ~INV_FFT ? -din_dr : din_dr;
    end else begin
      data_r_s = din_dr;
      data_i_s = din_di;
    end
  end

  // Output register

  always @(posedge clk) begin
    if (din_dv) begin
      dout_dr <= data_r_s;
      dout_di <= data_i_s;
    end
    dout_dv <= din_dv;
  end

endmodule

`default_nettype wire
