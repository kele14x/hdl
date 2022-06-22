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
    output wire                  data_valid_out,
    output wire                  data_last_out
);

  localparam integer LogFftSize = $clog2(FFT_SIZE);
  localparam integer NumStage = LogFftSize / 2;
  localparam integer Latency = (LogFftSize % 2 == 0) ?
        (FFT_SIZE - 2 ** (LogFftSize / 2 + 1) + 2) :
        (FFT_SIZE - 2 ** ((LogFftSize + 1) / 2) - 2 ** ((LogFftSize - 1) / 2) + 2);

  reg  [LogFftSize-1:0] counter;

  wire [DATA_WIDTH-1:0] data_s  [0:NumStage+1];


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
      counter <= 'd0;
    end
  end

  // Conenct input and output

  assign data_s[0] = data_in;

  always @(posedge clk) begin
    data_out <= data_s[NumStage];
  end

  // Loop generate every stage

  generate
    genvar i;
    for (i = 0; i <= NumStage - 1; i = i + 1) begin : g_stage
      // Swap x_j and x_k, where:
      //   j = N - 1 - i
      //   k = i

      // D = 2^j - 2^k
      localparam integer DelayTaps = 2 ** (LogFftSize - 1 - i) - 2 ** i;

      wire switch;

      reg [DATA_WIDTH-1:0] data_m0;
      reg [DATA_WIDTH-1:0] data_m1;
      reg [DATA_WIDTH-1:0] data_delayed;


      // s = /x_j OR x_k
      assign switch = ~counter[LogFftSize-1-i] || counter[i];

      always @(switch, data_delayed, data_s[i]) begin
        if (switch) begin
          data_m0 = data_s[i];
        end else begin
          data_m0 = data_delayed;
        end
      end

      delay #(
          .DELAY     (DelayTaps),
          .DATA_WIDTH(DATA_WIDTH)
      ) i_delay (
          .clk (clk),
          .rst (rst),
          .din (data_m0),
          .dout(data_delayed)
      );

      always @(switch, data_delayed, data_s[i]) begin
        if (switch) begin
          data_m1 = data_delayed;
        end else begin
          data_m1 = data_s[i];
        end
      end

      assign data_s[i+1] = data_m1;

    end
  endgenerate

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
