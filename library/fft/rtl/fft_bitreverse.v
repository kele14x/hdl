// File: fft_bitreverse.v
// Brief: Bit reverse for FFT.
`default_nettype none
//
`timescale 1 ns / 1 ps

module fft_bitreverse #(
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
    output reg  [DATA_WIDTH-1:0] data_out,
    output reg                   data_valid_out,
    output reg                   data_last_out
);

  localparam integer LogFftSize = $clog2(FFT_SIZE);
  localparam integer NumStage = LogFftSize / 2;
  localparam integer Latency = (LogFftSize % 2 == 0) ?
        (FFT_SIZE - 2 ** (LogFftSize / 2 + 1) + 2) :
        (FFT_SIZE - 2 ** ((LogFftSize + 1) / 2) - 2 ** ((LogFftSize - 1) / 2) + 2);

  wire [DATA_WIDTH-1:0] data_s       [0:NumStage+1];
  wire                  data_valid_s [0:NumStage+1];
  wire                  data_last_s  [0:NumStage+1];


  // Main
  //=====

  // Connect input and output

  assign data_s[0]       = data_in;
  assign data_valid_s[0] = data_valid_in;
  assign data_last_s[0]  = data_last_in;

  always @(posedge clk) begin
    data_out       <= data_s[NumStage];
    data_valid_out <= data_valid_s[NumStage];
    data_last_out  <= data_last_s[NumStage];
  end

  // Loop generate every stage

  generate
    genvar i;
    for (i = 0; i <= NumStage - 1; i = i + 1) begin : g_stage

      fft_bitreverse_stage #(
          .IDX_STAGE  (i),
          .FFT_SIZE   (FFT_SIZE),
          .DATA_WIDTH (DATA_WIDTH)
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
