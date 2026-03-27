`timescale 1 ns / 1 ps
//
`default_nettype none

module prach_fft_ditfft2_bf #(
    parameter int FFT_SIZE   = 4,
    parameter int DATA_WIDTH = 18
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
    output wire                         ovf
);

  // x0s, x1s -> x0s + x1s, x0s - x1s

  localparam int CounterWidth = $clog2(FFT_SIZE);

  localparam int DelayWidth = DATA_WIDTH * 2;
  localparam int DelayDepth = FFT_SIZE / 2;

  localparam int Latency = DelayDepth + 1;

  // Signals

  logic        [CounterWidth-1:0] cnt;
  logic        [CounterWidth-1:0] cnt2;
  logic                           state;
  logic                           state2;

  logic                           first_half_last;

  logic                           sel;

  logic                           dv;
  logic                           ovf_r;

  logic signed [    DATA_WIDTH:0] x1r_s;
  logic signed [    DATA_WIDTH:0] x1i_s;

  logic signed [  DATA_WIDTH-1:0] x1r;
  logic signed [  DATA_WIDTH-1:0] x1i;

  logic signed [    DATA_WIDTH:0] x2r_s;
  logic signed [    DATA_WIDTH:0] x2i_s;

  logic signed [  DATA_WIDTH-1:0] x2r;
  logic signed [  DATA_WIDTH-1:0] x2i;

  logic        [  DelayWidth-1:0] delay_in;
  logic        [  DelayWidth-1:0] delay_out;

  // Main

  always_ff @(posedge clk) begin
    if (rst) begin
      cnt <= 0;
    end else if (din_dv || state) begin
      cnt <= (cnt >= FFT_SIZE - 1) ? '0 : (cnt + 1'd1);
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      state <= 0;
    end else if (cnt >= FFT_SIZE - 1) begin
      state <= 1'b0;
    end else if (din_dv) begin
      state <= 1'b1;
    end
  end

  // sel marks the first half and second half of input data
  assign sel = !(cnt < FFT_SIZE / 2);

  assign first_half_last = (cnt == FFT_SIZE / 2);

  always_ff @(posedge clk) begin
    if (rst) begin
      cnt2 <= 0;
    end else if (first_half_last || state2) begin
      cnt2 <= (cnt2 >= FFT_SIZE - 1) ? '0 : cnt2 + 1'd1;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      state2 <= 0;
    end else if (cnt2 >= FFT_SIZE - 1) begin
      state2 <= 1'b0;
    end else if (first_half_last) begin
      state2 <= 1'b1;
    end
  end

  always_ff @(posedge clk) begin
    dv <= first_half_last || state2;
  end

  always_comb begin
    if (sel) begin
      // x0s - x1s
      x1r_s = x1r - din_dr;
      x1i_s = x1i - din_di;
    end else begin
      // x0s, x0s + x1s
      x1r_s = din_dr;
      x1i_s = din_di;
    end
  end

  always_comb begin
    if (sel) begin
      // x0s + x1s
      x2r_s = x1r + din_dr;
      x2i_s = x1i + din_di;
    end else begin
      // x0s - x1s
      x2r_s = x1r;
      x2i_s = x1i;
    end
  end

  always_ff @(posedge clk) begin
    x2r <= x2r_s[DATA_WIDTH-1:0];
    x2i <= x2i_s[DATA_WIDTH-1:0];
  end

  // Delay

  assign delay_in   = {x1i_s[DATA_WIDTH-1:0], x1r_s[DATA_WIDTH-1:0]};
  assign {x1i, x1r} = delay_out;

  generate
    if (DelayDepth <= 128) begin : g_srl

      delay #(
          .WIDTH(DelayWidth),
          .DEPTH(DelayDepth),
          .INIT (1'b0)
      ) u_delay_data (
          .clk (clk),
          .rst (1'b0),
          .cen (1'b1),
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
          .cen (1'b1),
          .din (delay_in),
          .dout(delay_out)
      );

    end
  endgenerate

  always_ff @(posedge clk) begin
    ovf_r <= ~(x2r_s[DATA_WIDTH-:2] == 2'b00 || x2r_s[DATA_WIDTH-:2] == 2'b11) ||
             ~(x2i_s[DATA_WIDTH-:2] == 2'b00 || x2i_s[DATA_WIDTH-:2] == 2'b11) ||
             ~(x2r_s[DATA_WIDTH-:2] == 2'b00 || x2r_s[DATA_WIDTH-:2] == 2'b11) ||
             ~(x2i_s[DATA_WIDTH-:2] == 2'b00 || x2i_s[DATA_WIDTH-:2] == 2'b11);
  end

  assign dout_dr = x2r;
  assign dout_di = x2i;
  assign dout_dv = dv;
  assign ovf     = ovf_r;

endmodule

`default_nettype wire
