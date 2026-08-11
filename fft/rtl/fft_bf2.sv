// Radix-2 Butterfly operator for FFT.
// Latency: 2 * (LOG_FFT_SIZE - 1) + 1
`timescale 1 ns / 1 ps
//
`default_nettype none

module fft_bf2 #(
    parameter integer NUM_ANT      = 4,
    parameter integer LOG_FFT_SIZE = 4,
    parameter integer DATA_WIDTH   = 18,
    parameter logic   SCALE        = 1'b0
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
    input  wire                         ctrl_scale,
    //
    output wire                         stat_ovf
);

  // Parameters

  localparam integer DelayWidth = DATA_WIDTH * 2;
  localparam integer DelayDepth = (1 << (LOG_FFT_SIZE + $clog2(NUM_ANT) - 1));

  // Signals

  // Counter count from 0 to LOG_FFT_SIZE - 1
  logic        [             3:0] counter_ch;
  wire         [             3:0] counter_ch_max;
  logic        [LOG_FFT_SIZE-1:0] counter;
  logic                           state;

  wire                            first_half_last;

  logic        [             3:0] counter_ch2;
  logic        [LOG_FFT_SIZE-1:0] counter2;
  logic                           state2;

  wire                            sel;
  wire                            shift;
  logic                           dv;
  logic                           ovf_r;

  logic signed [    DATA_WIDTH:0] x1r_s;
  logic signed [    DATA_WIDTH:0] x1i_s;

  wire signed  [  DATA_WIDTH-1:0] x1r;
  wire signed  [  DATA_WIDTH-1:0] x1i;

  wire signed  [  DATA_WIDTH-1:0] x1r_store;
  wire signed  [  DATA_WIDTH-1:0] x1i_store;

  logic signed [    DATA_WIDTH:0] x2r_s;
  logic signed [    DATA_WIDTH:0] x2i_s;

  logic signed [  DATA_WIDTH-1:0] x2r;
  logic signed [  DATA_WIDTH-1:0] x2i;

  wire signed  [  DATA_WIDTH-1:0] x2r_store;
  wire signed  [  DATA_WIDTH-1:0] x2i_store;

  wire         [  DelayWidth-1:0] delay_in;
  wire         [  DelayWidth-1:0] delay_out;

  function automatic signed [DATA_WIDTH-1:0] round_convergent_shift1(
      input logic signed [DATA_WIDTH:0] value);
    logic signed [DATA_WIDTH:0] shifted;
    begin
      shifted = value >>> 1;
      if (value[0] && shifted[0]) begin
        shifted = shifted + 1'b1;
      end
      round_convergent_shift1 = shifted[DATA_WIDTH-1:0];
    end
  endfunction

  // Main

  // Keep a state counter for each channel

  assign counter_ch_max = (ctrl_itlv == 2'b00) ? 4'd15 : (ctrl_itlv == 2'b01) ? 4'd7 : 4'd3;

  always_ff @(posedge clk) begin
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

  always_ff @(posedge clk) begin
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

  always_ff @(posedge clk) begin
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

  assign first_half_last = (counter_ch == 'd0) && (counter == LOG_FFT_SIZE'(1 << (LOG_FFT_SIZE - 1)));

  always_ff @(posedge clk) begin
    if (rst) begin
      counter_ch2 <= 'd0;
    end else if (first_half_last || state2) begin
      counter_ch2 <= (counter_ch2 == counter_ch_max) ? 'd0 : (counter_ch2 + 1'b1);
    end else begin
      counter_ch2 <= 'd0;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      counter2 <= 'd0;
    end else if (state2) begin
      counter2 <= (counter_ch2 == counter_ch_max) ? (counter2 + 1'b1) : counter2;
    end else begin
      counter2 <= 'd0;
    end
  end

  always_ff @(posedge clk) begin
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

  always_ff @(posedge clk) begin
    if (ctrl_bypass) begin
      dv <= din_dv;
    end else begin
      dv <= (first_half_last || state2) && (counter_ch2 < 4'(NUM_ANT));
    end
  end

  // Butterfly Operation

  // Output to delay path
  always_comb begin
    if (sel) begin
      // Second half
      x1r_s = {x1r[DATA_WIDTH-1], x1r} - {din_dr[DATA_WIDTH-1], din_dr};
      x1i_s = {x1i[DATA_WIDTH-1], x1i} - {din_di[DATA_WIDTH-1], din_di};
    end else begin
      x1r_s = {din_dr[DATA_WIDTH-1], din_dr};
      x1i_s = {din_di[DATA_WIDTH-1], din_di};
    end
  end

  // To (next) BF or output
  always_comb begin
    if (sel) begin
      // First half
      x2r_s = {x1r[DATA_WIDTH-1], x1r} + {din_dr[DATA_WIDTH-1], din_dr};
      x2i_s = {x1i[DATA_WIDTH-1], x1i} + {din_di[DATA_WIDTH-1], din_di};
    end else begin
      x2r_s = {x1r[DATA_WIDTH-1], x1r};
      x2i_s = {x1i[DATA_WIDTH-1], x1i};
    end
  end

  assign x1r_store = (SCALE && ctrl_scale && sel) ? round_convergent_shift1(
      x1r_s
  ) : x1r_s[DATA_WIDTH-1:0];
  assign x1i_store = (SCALE && ctrl_scale && sel) ? round_convergent_shift1(
      x1i_s
  ) : x1i_s[DATA_WIDTH-1:0];

  assign x2r_store = (SCALE && ctrl_scale && sel) ? round_convergent_shift1(
      x2r_s
  ) : x2r_s[DATA_WIDTH-1:0];
  assign x2i_store = (SCALE && ctrl_scale && sel) ? round_convergent_shift1(
      x2i_s
  ) : x2i_s[DATA_WIDTH-1:0];

  always_ff @(posedge clk) begin
    if (ctrl_bypass) begin
      if (din_dv) begin
        x2r <= din_dr;
        x2i <= din_di;
      end
    end else begin
      if ((first_half_last || state2) && (counter_ch2 < 4'(NUM_ANT))) begin
        x2r <= x2r_store;
        x2i <= x2i_store;
      end
    end
  end

  // Delay

  assign delay_in = {x1i_store, x1r_store};
  assign {x1i, x1r} = delay_out;

  // For smaller FFT size, choose register based delay for optimized resource
  // and lower latency. For big FFT size, choose RAMs based implementation

  assign shift = ctrl_bypass ? 1'b0 : ((counter_ch < 4'(NUM_ANT)) && (counter_ch2 < 4'(NUM_ANT)));

  if (DelayDepth <= 128) begin : g_srl

    delay #(
        .WIDTH(DelayWidth),
        .DEPTH(DelayDepth),
        .INIT (1'b0)
    ) i_delay (
        .clk (clk),
        .rst (rst),
        .cen (shift),
        .din (delay_in),
        .dout(delay_out)
    );

  end else begin : g_shift_ram

    shift_ram #(
        .WIDTH      (DelayWidth),
        .DEPTH      (DelayDepth),
        .INPUT_REG  (1),
        .PACKED_URAM(DelayDepth == 8192 && DelayWidth == 36),
        .RAM_STYLE  (DelayDepth >= 8192 ? "ULTRA" : (DelayDepth >= 1024 ? "BLOCK" : "AUTO"))
    ) i_delay (
        .clk (clk),
        .rst (rst),
        .cen (shift),
        .din (delay_in),
        .dout(delay_out)
    );

  end

  always_ff @(posedge clk) begin
    if (SCALE && ctrl_scale && sel) begin
      ovf_r <= 1'b0;
    end else begin
      ovf_r <= ~(x1r_s[DATA_WIDTH-:2] == 2'b00 || x1r_s[DATA_WIDTH-:2] == 2'b11) ||
               ~(x1i_s[DATA_WIDTH-:2] == 2'b00 || x1i_s[DATA_WIDTH-:2] == 2'b11) ||
               ~(x2r_s[DATA_WIDTH-:2] == 2'b00 || x2r_s[DATA_WIDTH-:2] == 2'b11) ||
               ~(x2i_s[DATA_WIDTH-:2] == 2'b00 || x2i_s[DATA_WIDTH-:2] == 2'b11);
    end
  end

  // Output register

  assign dout_dr  = x2r;
  assign dout_di  = x2i;
  assign dout_dv  = dv;

  assign stat_ovf = ovf_r;

endmodule

`default_nettype wire
