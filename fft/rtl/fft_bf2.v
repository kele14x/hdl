// Radix-2 Butterfly operator for FFT.
// Latency: 2 * (LOG_FFT_SIZE - 1) + 1
`timescale 1 ns / 1 ps
//
`default_nettype none

module fft_bf2 #(
    parameter integer NUM_ANT      = 4,
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
    output wire signed [DATA_WIDTH-1:0] dout_dr,
    output wire signed [DATA_WIDTH-1:0] dout_di,
    output wire                         dout_dv,
    //
    input  wire        [           1:0] ctrl_itlv,
    input  wire                         ctrl_bypass,
    //
    output wire                         stat_ovf
);

  // Parameters

  localparam integer DelayWidth = DATA_WIDTH * 2;
  localparam integer DelayDepth = (1 << (LOG_FFT_SIZE + $clog2(NUM_ANT) - 1));
  localparam integer Latency = DelayDepth + 1;

  // Signals

  // Counter count from 0 to LOG_FFT_SIZE - 1
  reg         [             3:0] counter_ch;
  wire        [             3:0] counter_ch_max;
  reg         [LOG_FFT_SIZE-1:0] counter;
  reg                            state;

  wire                           first_half_last;

  reg         [             3:0] counter_ch2;
  reg         [LOG_FFT_SIZE-1:0] counter2;
  reg                            state2;

  wire                           sel;
  wire                           shift;
  reg                            dv;
  reg                            ovf_r;

  reg signed  [    DATA_WIDTH:0] x1r_s;
  reg signed  [    DATA_WIDTH:0] x1i_s;

  wire signed [  DATA_WIDTH-1:0] x1r;
  wire signed [  DATA_WIDTH-1:0] x1i;

  reg signed  [    DATA_WIDTH:0] x2r_s;
  reg signed  [    DATA_WIDTH:0] x2i_s;

  reg signed  [  DATA_WIDTH-1:0] x2r;
  reg signed  [  DATA_WIDTH-1:0] x2i;

  wire        [  DelayWidth-1:0] delay_in;
  wire        [  DelayWidth-1:0] delay_out;

  // Main

  // Keep a state counter for each channel

  assign counter_ch_max = (ctrl_itlv == 2'b00) ? 4'd15 : (ctrl_itlv == 2'b01) ? 4'd7 : 4'd3;

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

  assign first_half_last = (counter_ch == 'd0) && (counter == (1 << (LOG_FFT_SIZE - 1)));

  always @(posedge clk) begin
    if (rst) begin
      counter_ch2 <= 'd0;
    end else if (first_half_last || state2) begin
      counter_ch2 <= (counter_ch2 == counter_ch_max) ? 'd0 : (counter_ch2 + 1'b1);
    end else begin
      counter_ch2 <= 'd0;
    end
  end

  always @(posedge clk) begin
    if (rst) begin
      counter2 <= 'd0;
    end else if (state2) begin
      counter2 <= (counter_ch2 == counter_ch_max) ? (counter2 + 1'b1) : counter2;
    end else begin
      counter2 <= 'd0;
    end
  end

  always @(posedge clk) begin
    if (rst) begin
      state2 <= 1'b0;
    end else if (first_half_last) begin
      state2 <= 1'b1;
    end else if ((counter_ch2 == counter_ch_max) && &counter2) begin
      state2 <= 1'b0;
    end
  end

  // Indicate first half and second half
  assign sel = counter[LOG_FFT_SIZE-1];

  always @(posedge clk) begin
    if (ctrl_bypass) begin
      dv <= din_dv;
    end else begin
      dv <= (first_half_last || state2) && (counter_ch2 < NUM_ANT);
    end
  end

  // Butterfly Operation

  // Output to delay path
  always @(*) begin
    if (sel) begin
      // Second half
      x1r_s = x1r - din_dr;
      x1i_s = x1i - din_di;
    end else begin
      x1r_s = din_dr;
      x1i_s = din_di;
    end
  end

  // To (next) BF or output
  always @(*) begin
    if (sel) begin
      // First half
      x2r_s = x1r + din_dr;
      x2i_s = x1i + din_di;
    end else begin
      x2r_s = x1r;
      x2i_s = x1i;
    end
  end

  always @(posedge clk) begin
    if (ctrl_bypass) begin
      if (din_dv) begin
        x2r <= din_dr;
        x2i <= din_di;
      end
    end else begin
      if ((first_half_last || state2) && (counter_ch2 < NUM_ANT)) begin
        x2r <= x2r_s[DATA_WIDTH-1:0];
        x2i <= x2i_s[DATA_WIDTH-1:0];
      end
    end
  end

  // Delay

  assign delay_in = {x1i_s[DATA_WIDTH-1:0], x1r_s[DATA_WIDTH-1:0]};
  assign {x1i, x1r} = delay_out;

  // For smaller FFT size, choose register based delay for optimized resource
  // and lower latency. For big FFT size, choose RAMs based implementation

  assign shift = ctrl_bypass ? 1'b0 : ((counter_ch < NUM_ANT) && (counter_ch2 < NUM_ANT));

  if (DelayDepth <= 128) begin : g_srl

    delay #(
        .WIDTH(DelayWidth),
        .DEPTH(DelayDepth),
        .INIT (1'b0)
    ) i_delay (
        .clk (clk),
        .rst (1'b0),
        .cen (shift),
        .din (delay_in),
        .dout(delay_out)
    );

  end else begin : g_shift_ram

    shift_ram #(
        .WIDTH    (DelayWidth),
        .DEPTH    (DelayDepth),
        .INPUT_REG(1)
    ) i_delay (
        .clk (clk),
        .rst (1'b0),
        .cen (shift),
        .din (delay_in),
        .dout(delay_out)
    );

  end

  always @(posedge clk) begin
    ovf_r <= ~(x1r_s[DATA_WIDTH-:2] == 2'b00 || x1r_s[DATA_WIDTH-:2] == 2'b11) ||
             ~(x1i_s[DATA_WIDTH-:2] == 2'b00 || x1i_s[DATA_WIDTH-:2] == 2'b11) ||
             ~(x2r_s[DATA_WIDTH-:2] == 2'b00 || x2r_s[DATA_WIDTH-:2] == 2'b11) ||
             ~(x2i_s[DATA_WIDTH-:2] == 2'b00 || x2i_s[DATA_WIDTH-:2] == 2'b11);
  end

  // Output register

  assign dout_dr  = x2r;
  assign dout_di  = x2i;
  assign dout_dv  = dv;

  assign stat_ovf = ovf_r;

endmodule

`default_nettype wire
