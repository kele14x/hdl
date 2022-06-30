// File: fft_bitreverse_stage.v
// Brief: Bit reverse stage for FFT.
`default_nettype none
//
`timescale 1 ns / 1 ps

module fft_bitreverse_stage #(
    parameter integer IDX_STAGE  = 0,
    parameter integer FFT_SIZE   = 4096,
    parameter integer DATA_WIDTH = 32
) (
    input  wire                  clk,
    input  wire                  rst,
    // Data input
    input  wire [DATA_WIDTH-1:0] data_in,
    input  wire                  data_valid_in,
    input  wire                  data_last_in,
    // Data output
    output wire [DATA_WIDTH-1:0] data_out,
    output wire                  data_valid_out,
    output wire                  data_last_out
);

  // Swap x_j and x_k, where:
  //   j = N - 1 - i
  //   k = i
  localparam integer LogFftSize = $clog2(FFT_SIZE);
  localparam integer NumStage = LogFftSize / 2;
  localparam integer DelayTaps = 2 ** (LogFftSize - 1 - IDX_STAGE) - 2 ** IDX_STAGE;
  localparam integer Latency = DelayTaps;

  wire switch;

  reg  [DATA_WIDTH-1:0] data_m0;
  reg  [DATA_WIDTH-1:0] data_m1;
  wire [DATA_WIDTH-1:0] data_delayed;

  // Each stage has a local counter, which counts from 0 to FFT_SIZE-1. Counter
  // synchronize with `data_in`.
  reg  [LogFftSize-1:0] counter;


  // Main
  //=====

  always @(posedge clk) begin
    if (rst) begin
      counter <= 'd0;
    end else if (data_valid_in && data_last_in) begin
      counter <= 'd0;
    end else if (data_valid_in) begin
      counter <= counter + 1;
    end else begin
      counter <= counter;
    end
  end

  // s = /x_j OR x_k
  assign switch = ~counter[LogFftSize-1-IDX_STAGE] || counter[IDX_STAGE];

  always @(*) begin
    if (switch) begin
      data_m0 = data_in;
    end else begin
      data_m0 = data_delayed;
    end
  end

  // D = 2^j - 2^k
  delay #(
      .DELAY     (DelayTaps),
      .DATA_WIDTH(DATA_WIDTH)
  ) i_delay (
      .clk (clk),
      .rst (rst),
      .din (data_m0),
      .dout(data_delayed)
  );

  always @(*) begin
    if (switch) begin
      data_m1 = data_delayed;
    end else begin
      data_m1 = data_in;
    end
  end

  assign data_out = data_m1;

  shift_regs #(
      .DATA_WIDTH(2),
      .DEPTH     (Latency)
  ) i_valid_delay (
      .clk (clk),
      .din ({data_last_in, data_valid_in}),
      .dout({data_last_out, data_valid_out})
  );

endmodule

`default_nettype wire
