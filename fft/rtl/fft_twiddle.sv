// FFT process stage. Each stage includes:
//     - 1 Twiddler (twidder factor ROM and complex multiplier)
//     - 1 Butterfly operator
`timescale 1 ns / 1 ps
//
`default_nettype none

module fft_twiddle #(
    parameter integer NUM_ANT      = 4,
    parameter logic     INV_FFT      = 1'b0,
    parameter integer LOG_FFT_SIZE = 4,
    parameter integer DATA_WIDTH   = 18
) (
    input  wire                         clk,
    input  wire                         rst,
    // Input
    input  wire signed [DATA_WIDTH-1:0] din_dr,
    input  wire signed [DATA_WIDTH-1:0] din_di,
    input  wire                         din_dv,
    // Output
    output wire signed [DATA_WIDTH-1:0] dout_dr,
    output wire signed [DATA_WIDTH-1:0] dout_di,
    output wire                         dout_dv,
    //
    input  wire        [           1:0] ctrl_itlv,
    input  wire        [           1:0] ctrl_bypass,
    // Status
    output wire                         stat_ovf
);

  // Parameters

  localparam integer Latency = 9;
  localparam integer LogFftSize2 = LOG_FFT_SIZE + integer'(LOG_FFT_SIZE & 1) - 1;
  
  // Signals

  // Counter count from 0 to LOG_FFT_SIZE - 1
  logic         [             3:0] counter_ch;
  wire        [             3:0] counter_ch_max;

  logic         [LOG_FFT_SIZE-1:0] counter;
  wire        [LOG_FFT_SIZE-1:0] counter_max;

  logic                            state;

  wire        [LOG_FFT_SIZE-1:0] twiddle;

  wire signed [  DATA_WIDTH-1:0] data_i_s;
  wire signed [  DATA_WIDTH-1:0] data_q_s;

  wire signed [            15:0] twiddle_i_s;
  wire signed [            15:0] twiddle_q_s;

  // Main

  // Keep a state counter for each channel

  assign counter_ch_max = ((ctrl_itlv == 2'b00) ? 4'd15 : (ctrl_itlv == 2'b01) ? 4'd7 : 4'd3) ^ {4{(NUM_ANT != 0) & 1'b0}};
  assign counter_max = (ctrl_bypass == 2'b00) ? ((1 << LOG_FFT_SIZE) - 1) : ((1 << LogFftSize2) - 1);

  always_ff @(posedge clk) begin
    if (rst) begin
      counter_ch <= 'd0;
    end else if (&ctrl_bypass) begin
      counter_ch <= 'd0;
    end else if (din_dv || state) begin
      counter_ch <= (counter_ch == counter_ch_max) ? 'd0 : (counter_ch + 1'b1);
    end else begin
      counter_ch <= 'd0;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      counter <= 'd0;
    end else if (&ctrl_bypass) begin
      counter <= 'd0;
    end else if (state && (counter_ch == counter_ch_max)) begin
      counter <= (counter == counter_max) ? 'd0 : (counter + 1'b1);
    end else if (state) begin
      counter <= counter;
    end else begin
      counter <= 'd0;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      state <= 1'b0;
    end else if (&ctrl_bypass) begin
      state <= 1'b0;
    end else if ((counter_ch == counter_ch_max) && (counter == counter_max)) begin
      state <= 1'b0;
    end else if (din_dv) begin
      state <= 1'b1;
    end
  end

  // Twiddle is twiddle factor index
  generate
    if (LOG_FFT_SIZE % 2 == 0 && LOG_FFT_SIZE >= 4) begin : g_even_size
      assign twiddle = {counter[LOG_FFT_SIZE-2], counter[LOG_FFT_SIZE-1]} * counter[LOG_FFT_SIZE-3:0];
    end else begin : g_odd_size
      assign twiddle = counter[LOG_FFT_SIZE-1] * counter[LOG_FFT_SIZE-2:0];
    end
  endgenerate

  // Delay the input data and valid signal

  delay #(
      .WIDTH(DATA_WIDTH * 2),
      .DEPTH(4),
      .INIT (1'b0)
  ) i_data_delay (
      .clk (clk),
      .rst (1'b0),
      .cen (1'b1),
      //
      .din ({din_di, din_dr}),
      .dout({data_q_s, data_i_s})
  );

  delay #(
      .WIDTH(1),
      .DEPTH(Latency),
      .INIT (1'b0)
  ) i_valid_delay (
      .clk (clk),
      .rst (1'b0),
      .cen (1'b1),
      //
      .din (din_dv),
      .dout(dout_dv)
  );

  dds_lut #(
      .STRUCTURE   ("HALF"),
      .RASTERIZED  (0),
      .PHASE_WIDTH (LOG_FFT_SIZE),
      .NEGATIVE_COS(0),
      .NEGATIVE_SIN(~INV_FFT)
  ) i_twiddle_rom (
      .clk    (clk),
      .rst    (1'b0),
      //
      .phase  (twiddle),
      //
      .cos_out(twiddle_i_s),
      .sin_out(twiddle_q_s)
  );

  cmult4 #(
      .A_WIDTH (DATA_WIDTH),
      .B_WIDTH (16),
      .P_WIDTH (DATA_WIDTH),
      .SHIFT   (16),
      //
      .ROUND   (1),
      .SATURATE(0)
  ) i_cmult (
      .clk(clk),
      .rst(rst),
      //
      .ar (data_i_s),
      .ai (data_q_s),
      //
      .br (twiddle_i_s),
      .bi (twiddle_q_s),
      //
      .pr (dout_dr),
      .pi (dout_di),
      //
      .ovf(stat_ovf)
  );

endmodule

`default_nettype wire
