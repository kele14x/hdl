// File: bit_reverse.sv
// Brief: Bit reverse for FFT. This module permute input data into bit-reversed
//        order, which usually cased by FFT Radix-2 processing.
`default_nettype none
//
`timescale 1 ns / 1 ps

module bit_reverse #(
    parameter int FFT_SIZE   = 4096,
    parameter int DATA_WIDTH = 32
) (
    input var                   clk,
    input var                   rst,
    // Data input
    input var  [DATA_WIDTH-1:0] data_in,
    input var                   data_valid_in,
    input var                   data_last_in,
    // Data output
    output var [DATA_WIDTH-1:0] data_out,
    output var                  data_valid_out,
    output var                  data_last_out
);

  localparam int LogFftSize = $clog2(FFT_SIZE);
  localparam int NumStage = LogFftSize / 2;
  //
  // D = (N - 2*sqrt(N) + 1 + log2(N))              if log2(N) is even
  //   = (N - sqrt(N*2) - sqrt(N/2) + 1 + log2(N))  if log2(N) is odd
  localparam int Latency = (LogFftSize % 2 == 0) ?
        (FFT_SIZE - 2 ** (LogFftSize / 2 + 1) + LogFftSize + 1) :
        (FFT_SIZE - 2 ** ((LogFftSize + 1) / 2) - 2 ** ((LogFftSize - 1) / 2) + LogFftSize + 1);

  wire [DATA_WIDTH-1:0] data_s      [NumStage+1];
  wire                  data_valid_s[NumStage+1];
  wire                  data_last_s [NumStage+1];


  // Main
  //=====

  // Connect input and output

  assign data_s[0]       = data_in;
  assign data_valid_s[0] = data_valid_in;
  assign data_last_s[0]  = data_last_in;

  assign data_out        = data_s[NumStage];
  assign data_valid_out  = data_valid_s[NumStage];
  assign data_last_out   = data_last_s[NumStage];

  // Loop generate every stage

  generate
    for (genvar i = 0; i <= NumStage - 1; i++) begin : g_stage

      bit_reverse_stage #(
          .IDX_STAGE (i),
          .FFT_SIZE  (FFT_SIZE),
          .DATA_WIDTH(DATA_WIDTH)
      ) i_stage (
          .clk           (clk),
          .rst           (rst),
          // Data input
          .data_in       (data_s[i]),
          .data_valid_in (data_valid_s[i]),
          .data_last_in  (data_last_s[i]),
          // Data output
          .data_out      (data_s[i+1]),
          .data_valid_out(data_valid_s[i+1]),
          .data_last_out (data_last_s[i+1])
      );

    end
  endgenerate

endmodule

`default_nettype wire
