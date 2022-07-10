// File: fft_core.v
// Brief: Core of FFT module.
`default_nettype none
//
`timescale 1 ns / 1 ps

module fft_core #(
    // FFT size, must be power of 2
    parameter int FFT_SIZE          = 4096,
    // Input data width for I and Q
    parameter int INPUT_DATA_WIDTH  = 16,
    // Phase factor data width
    parameter int PHASE_WIDTH       = 16,
    // Output data width for I and Q
    parameter int OUTPUT_DATA_WIDTH = 29
) (
    input var                          clk,
    input var                          rst,
    // Data input
    input var  [ INPUT_DATA_WIDTH-1:0] data_i_in,
    input var  [ INPUT_DATA_WIDTH-1:0] data_q_in,
    input var                          data_valid_in,
    input var                          data_last_in,
    // Data output
    output var [OUTPUT_DATA_WIDTH-1:0] data_i_out,
    output var [OUTPUT_DATA_WIDTH-1:0] data_q_out,
    output var                         data_valid_out,
    output var                         data_last_out,
    // Status output
    output var                         err_input_halt,
    output var                         err_last_unexpected,
    output var                         err_ovf
);

  // Local parameters
  //=================

  localparam int LogFftSize = $clog2(FFT_SIZE);
  localparam int Latency = LogFftSize * 9 + FFT_SIZE - 8;


  // Signals
  //========
  // data_i_in =>  stage[0] => stage[1] => ... => stage[log2(N)-1]
  // data_q_in =>
  // state     =>
  // counter   =>

  // state = 0: idle or first data, 1: left data
  logic                                state;
  // Counter count from 0 to FFT_SIZE - 1
  logic        [       LogFftSize-1:0] counter;

  logic signed [OUTPUT_DATA_WIDTH-1:0] data_i_s[LogFftSize+1];
  logic signed [OUTPUT_DATA_WIDTH-1:0] data_q_s[LogFftSize+1];

  logic        [                  1:0] sync_s  [LogFftSize+1];

  logic                                ovf     [  LogFftSize];


  // Main
  //=====

  // Connect input & output

  assign data_i_s[0] = {
    {OUTPUT_DATA_WIDTH - INPUT_DATA_WIDTH{data_i_in[INPUT_DATA_WIDTH-1]}}, data_i_in
  };
  assign data_q_s[0] = {
    {OUTPUT_DATA_WIDTH - INPUT_DATA_WIDTH{data_q_in[INPUT_DATA_WIDTH-1]}}, data_q_in
  };

  assign sync_s[0] = {state, state};

  assign data_i_out = data_i_s[LogFftSize];
  assign data_q_out = data_q_s[LogFftSize];

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
      counter <= 'd0;
    end else if (data_valid_in && data_last_in) begin
      counter <= 'd0;
    end else if (data_valid_in) begin
      counter <= counter + 1;
    end else begin
      counter <= 'd0;
    end
  end

  // Loop generate each stage

  generate
    genvar i;
    for (i = 0; i <= LogFftSize - 1; i = i + 1) begin : g_stage

      // At first stage, we increase input data width by 1, this ensures there
      // is no overflow at twiddle rotation. This only need to be done onece.
      // Data width increases by 1 after each stage, (caused by the adder).
      // But data width should not exceeds output data width.
      localparam integer StageDataWidth = ((INPUT_DATA_WIDTH + i + 1) <= OUTPUT_DATA_WIDTH) ?
        (INPUT_DATA_WIDTH + i + 1) : OUTPUT_DATA_WIDTH;

      wire signed [StageDataWidth-1:0] data_i_stage_in;
      wire signed [StageDataWidth-1:0] data_q_stage_in;

      wire signed [  StageDataWidth:0] data_i_stage_out;
      wire signed [  StageDataWidth:0] data_q_stage_out;

      assign data_i_stage_in = data_i_s[i][StageDataWidth-1:0];
      assign data_q_stage_in = data_q_s[i][StageDataWidth-1:0];

      assign data_i_s[i+1]   = data_i_stage_out;
      assign data_q_s[i+1]   = data_q_stage_out;

      // FFT stage

      fft_stage #(
          .STAGE       (i),
          .LOG_FFT_SIZE(LogFftSize),
          .DATA_WIDTH  (StageDataWidth),
          .PHASE_WIDTH (PHASE_WIDTH)
      ) i_stage (
          .clk       (clk),
          .rst       (rst),
          //
          .data_i_in (data_i_stage_in),
          .data_q_in (data_q_stage_in),
          .sync_in   (sync_s[i]),
          //
          .data_i_out(data_i_stage_out),
          .data_q_out(data_q_stage_out),
          .sync_out  (sync_s[i+1]),
          //
          .ovf       (ovf[i])
      );

    end
  endgenerate

  // Control & status output

  shift_regs #(
      .DATA_WIDTH(2),
      .DEPTH     (Latency)
  ) i_valid_delay (
      .clk (clk),
      .cen (1'b1),
      .din ({data_last_in, data_valid_in}),
      .dout({data_last_out, data_valid_out})
  );

  always_ff @(posedge clk) begin : p_err_ovf
    integer i;
    err_ovf <= 1'b0;
    for (i = 0; i < LogFftSize; i = i + 1) begin
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
