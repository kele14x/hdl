// File: fft.sv
// Brief: Top of FFT module.
`default_nettype none
//
`timescale 1 ns / 1 ps

module fft #(
    // FFT size, must be power of 2
    parameter int FFT_SIZE   = 4,
    // Input data width for I and Q
    parameter int DATA_WIDTH = 16
) (
    input var                   clk,
    input var                   rst,
    // Data input
    input var  [DATA_WIDTH-1:0] data_i_in,
    input var  [DATA_WIDTH-1:0] data_q_in,
    input var                   data_valid_in,
    input var                   data_last_in,
    // Data output
    output var [DATA_WIDTH-1:0] data_i_out,
    output var [DATA_WIDTH-1:0] data_q_out,
    output var                  data_valid_out,
    output var                  data_last_out,
    // Status otuput
    output var                  err_input_halt,
    output var                  err_last_unexpected,
    output var                  err_ovf
);

  // Local parameters
  //=================

  localparam int LogFftSize = $clog2(FFT_SIZE);
  localparam int Latency = LogFftSize * 9 + FFT_SIZE - 8;


  // Check parameters
  //=================

  initial begin

    // Check FFT size
    assert (2 <= FFT_SIZE && FFT_SIZE <= 16384)
    else begin
      $error("[%m]: FFT size (FFT_SIZE) must be within the range 2 to 16384.");
      #1 $finish();
    end

    assert (FFT_SIZE == 2 ** LogFftSize)
    else begin
      $error("[%m]: FFT size (FFT_SIZE) must be power of 2.");
      #1 $finish();
    end

    // Check data width
    assert (8 <= DATA_WIDTH && DATA_WIDTH <= 32)
    else begin
      $error("[%m]: Data wdith (DATA_WIDTH) must be within the range 8 to 32.");
      #1 $finish();
    end
  end


  // Signals
  //========

  // state = 0: idle, 1: synced with data
  logic                         state;
  // Counter count from 0 to FFT_SIZE - 1
  logic        [LogFftSize-1:0] counter;

  logic signed [DATA_WIDTH-1:0] data_i_s[LogFftSize + 1];
  logic signed [DATA_WIDTH-1:0] data_q_s[LogFftSize + 1];

  logic        [           1:0] sync_s  [LogFftSize + 1];

  logic                         ovf     [    LogFftSize];


  // Main
  //=====

  // Connect input & output

  assign data_i_s[0] = data_i_in;
  assign data_q_s[0] = data_q_in;

  assign sync_s[0]   = {state, state};

  assign data_i_out  = data_i_s[LogFftSize];
  assign data_q_out  = data_q_s[LogFftSize];

  // FFT State & Counter

  always_ff @(posedge clk) begin
    if (rst) begin
      state <= 1'b0;
    end else if (data_valid_in && data_last_in) begin
      state <= 1'b0;
    end else if (data_valid_in) begin
      state <= 1'b1;
    end else begin
      state <= 1'b0;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      counter <= '0;
    end else if (data_valid_in && data_last_in) begin
      counter <= '0;
    end else if (data_valid_in) begin
      counter <= counter + 1;
    end else begin
      counter <= '0;
    end
  end

  // Loop generate each stage

  generate
    for (genvar i = 0; i <= LogFftSize - 1; i++) begin : g_stage

      // FFT stage

      fft_stage #(
          .STAGE       (i),
          .LOG_FFT_SIZE(LogFftSize),
          .DATA_WIDTH  (DATA_WIDTH)
      ) i_stage (
          .clk       (clk),
          .rst       (rst),
          //
          .data_i_in (data_i_s[i]),
          .data_q_in (data_q_s[i]),
          .sync_in   (sync_s[i]),
          //
          .data_i_out(data_i_s[i+1]),
          .data_q_out(data_q_s[i+1]),
          .sync_out  (sync_s[i+1]),
          //
          .ovf       (ovf[i])
      );

    end
  endgenerate

  // Control & status output

  reg_pipeline #(
      .DATA_WIDTH     (2),
      .PIPELINE_STAGES(Latency)
  ) i_valid_pipeline (
      .clk (clk),
      .din ({data_last_in, data_valid_in}),
      .dout({data_last_out, data_valid_out})
  );

  always_ff @(posedge clk) begin
    err_ovf <= 1'b0;
    for (int i = 0; i < LogFftSize; i++) begin
      if (ovf[i]) begin
        err_ovf <= 1'b1;
      end
    end
  end

  always_ff @(posedge clk) begin
    err_last_unexpected <= (data_last_in && ~&counter);
  end

  always_ff @(posedge clk) begin
    err_input_halt <= (!data_valid_in && |counter);
  end

endmodule

`default_nettype wire
