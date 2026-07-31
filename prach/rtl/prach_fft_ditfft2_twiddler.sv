`timescale 1 ns / 1 ps
//
`default_nettype none

module prach_fft_ditfft2_twiddler #(
    parameter int FFT_SIZE   = 4,
    parameter int DATA_WIDTH = 18,
    parameter bit SCALE      = 0
) (
    input  wire                  clk,
    input  wire                  rst,
    //
    input  wire [DATA_WIDTH-1:0] din_dr,
    input  wire [DATA_WIDTH-1:0] din_di,
    input  wire                  din_dv,
    //
    output wire [DATA_WIDTH-1:0] dout_dr,
    output wire [DATA_WIDTH-1:0] dout_di,
    output wire                  dout_dv,
    //
    output wire                  ovf
);

  // x0, x1 -> x0 + x1, x0 - x1

  localparam int Latency = 8;
  localparam int CounterWidth = $clog2(FFT_SIZE);
  localparam int PhaseWidth = 18;
  localparam logic [CounterWidth-1:0] LastCount = CounterWidth'(FFT_SIZE - 1);
  localparam logic [CounterWidth-1:0] HalfCount = CounterWidth'(FFT_SIZE / 2);
  localparam RamStyle = CounterWidth >= 9 ? "BLOCK" : "DISTRIBUTED";

  // Signals

  logic        [CounterWidth-1:0] cnt;
  logic                           state;

  logic                           sel;

  logic        [CounterWidth-2:0] addr;

  logic signed [  PhaseWidth-1:0] tr;
  logic signed [  PhaseWidth-1:0] ti;

  logic signed [  DATA_WIDTH-1:0] din_dr_d;
  logic signed [  DATA_WIDTH-1:0] din_di_d;

  logic                           dv;

  // Main

  always_ff @(posedge clk) begin
    if (rst) begin
      cnt <= 0;
    end else if (din_dv || state) begin
      cnt <= (cnt >= LastCount) ? '0 : (cnt + 1'd1);
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      state <= 0;
    end else if (cnt >= LastCount) begin
      state <= 1'b0;
    end else if (din_dv) begin
      state <= 1'b1;
    end
  end

  always_ff @(posedge clk) begin
    dv <= din_dv || state;
  end

  assign sel = !(cnt < HalfCount);

  always_comb begin
    if (sel) begin
      addr = (CounterWidth - 1)'(cnt - HalfCount);
    end else begin
      addr = '0;
    end
  end

  // cos sin lut

  prach_fft_ditfft2_rom #(
      .FFT_SIZE  (FFT_SIZE),
      .ADDR_WIDTH(CounterWidth - 1),
      .DATA_WIDTH(PhaseWidth),
      .RAM_STYLE (RamStyle)
  ) u_rom (
      .clk (clk),
      .rst (rst),
      //
      .addr(addr),
      //
      .tr  (tr),
      .ti  (ti)
  );

  delay #(
      .WIDTH(DATA_WIDTH * 2),
      .DEPTH(3),
      .INIT (1'b0)
  ) u_delay_data (
      .clk (clk),
      .rst (1'b0),
      .cen (1'b1),
      .din ({din_di, din_dr}),
      .dout({din_di_d, din_dr_d})
  );

  cmult #(
      .USE_3_MULT(1'b0),
      .A_WIDTH (DATA_WIDTH),
      .B_WIDTH (PhaseWidth),
      .P_WIDTH (DATA_WIDTH),
      .SHIFT   (SCALE ? PhaseWidth : PhaseWidth - 1),
      //
      .ROUND   (1'b1),
      .SATURATE(1'b0)
  ) u_cmult (
      .clk(clk),
      .rst(rst),
      //
      .ar (din_dr_d),
      .ai (din_di_d),
      //
      .br (tr),
      .bi (ti),
      //
      .pr (dout_dr),
      .pi (dout_di),
      //
      .ovf(ovf)
  );

  delay #(
      .WIDTH(1),
      .DEPTH(Latency - 1),
      .INIT (1'b0)
  ) u_delay (
      .clk (clk),
      .rst (1'b0),
      .cen (1'b1),
      .din (dv),
      .dout(dout_dv)
  );

endmodule

`default_nettype wire
