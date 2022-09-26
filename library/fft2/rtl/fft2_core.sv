// File: fft_core.v
// Brief: Core of FFT module.
`default_nettype none
//
`timescale 1 ns / 1 ps

module fft_core #(
    parameter int LOG_FFT_SIZE       = 12,
    parameter int INPUT_DATA_WIDTH   = 16,
    parameter int PHASE_WIDTH        = 16,
    parameter int OUTPUT_DATA_WIDTH  = 29,
    parameter bit BIT_REVERSED_INPUT = 1
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
    // Control input
    input var  [                  4:0] ctrl_sra_bits,
    // Status output
    output var                         err_ovf
);

  // Local parameters
  //=================

  // Number of stages,
  //   - If LOG_FFT_SIZE is even, number of stages is LOG_FFT_SIZE / 2.
  //   - If LOG_FFT_SIZE is odd, number of stages is floor(LOG_FFT_SIZE / 2) + 1
  localparam int NumStages = LOG_FFT_SIZE / 2 + (LOG_FFT_SIZE % 2);


  // Signals
  //========
  // data_i_in =>  stage[0] => stage[1] => ... => stage[NumStages-1]
  // data_q_in =>
  // state     =>
  // counter   =>

  // state = 0: idle or first data, 1: left data
  logic                                state;
  // Counter count from 0 to FFT_SIZE - 1
  logic        [     LOG_FFT_SIZE-1:0] counter;

  logic signed [OUTPUT_DATA_WIDTH-1:0] data_i_s    [NumStages+1];
  logic signed [OUTPUT_DATA_WIDTH-1:0] data_q_s    [NumStages+1];
  logic                                data_valid_s[NumStages+1];
  logic                                data_last_s [NumStages+1];

  logic                                ovf         [  NumStages];


  // Main
  //=====

  // Connect input

  assign data_i_s[0] = {
    {OUTPUT_DATA_WIDTH - INPUT_DATA_WIDTH{data_i_in[INPUT_DATA_WIDTH-1]}}, data_i_in
  };
  assign data_q_s[0] = {
    {OUTPUT_DATA_WIDTH - INPUT_DATA_WIDTH{data_q_in[INPUT_DATA_WIDTH-1]}}, data_q_in
  };

  assign data_valid_s[0] = data_valid_in;
  assign data_last_s[0] = data_last_in;

  // Connect output

  assign data_i_out = data_i_s[NumStages];
  assign data_q_out = data_q_s[NumStages];

  assign data_valid_out = data_valid_s[NumStages];
  assign data_last_out = data_last_s[NumStages];

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
    for (genvar i = 0; i < NumStages; i++) begin : g_stage

      // First stage does not need a twiddle multiplier
      localparam bit HasTwiddle = (i > 0);

      // Bigger FFT could be split into multiple small FFTs. One stage process
      // 4 ^ (i + 1) FFT using two radix-2 butterfly operator. If LOG_FFT_SIZE
      // is an odd number, the last stage should be a special stage with only
      // one radix-2 butterfly.
      localparam int StageLogFftSize = BIT_REVERSED_INPUT ? 
        ((2 * i + 2) <= LOG_FFT_SIZE ? (2 * i + 2) : LOG_FFT_SIZE) :
        ((LOG_FFT_SIZE - 2 * i) <= 0 ? 0 : (LOG_FFT_SIZE - 2 * i));

      // At first stage, we increase input data width by 1, this ensures there
      // is no overflow at twiddle rotation. This only need to be done once.
      // Data width increases by 1 after each stage, (caused by the adder).
      // But data width should not exceeds output data width.
      localparam int StageDataWidth = ((INPUT_DATA_WIDTH + 2 * i + 1) <= OUTPUT_DATA_WIDTH) ?
        (INPUT_DATA_WIDTH + 2 * i + 1) : OUTPUT_DATA_WIDTH;


      wire signed [StageDataWidth-1:0] data_i_stage_in;
      wire signed [StageDataWidth-1:0] data_q_stage_in;

      wire signed [StageDataWidth+1:0] data_i_stage_out;
      wire signed [StageDataWidth+1:0] data_q_stage_out;

      assign data_i_stage_in = data_i_s[i][StageDataWidth-1:0];
      assign data_q_stage_in = data_q_s[i][StageDataWidth-1:0];

      assign data_i_s[i+1]   = data_i_stage_out;
      assign data_q_s[i+1]   = data_q_stage_out;

      // FFT stage

      fft_stage #(
          .HAS_TWIDDLE       (HasTwiddle),
          .LOG_FFT_SIZE      (StageLogFftSize),
          .DATA_WIDTH        (StageDataWidth),
          .PHASE_WIDTH       (PHASE_WIDTH),
          .BIT_REVERSED_INPUT(BIT_REVERSED_INPUT)
      ) i_stage (
          .clk           (clk),
          .rst           (rst),
          //
          .data_i_in     (data_i_stage_in),
          .data_q_in     (data_q_stage_in),
          .data_valid_in (data_valid_s[i]),
          .data_last_in  (data_last_s[i]),
          //
          .data_i_out    (data_i_stage_out),
          .data_q_out    (data_q_stage_out),
          .data_valid_out(data_valid_s[i+1]),
          .data_last_out (data_last_s[i+1]),
          //
          .ovf           (ovf[i])
      );

    end
  endgenerate

  always_ff @(posedge clk) begin
    err_ovf <= 1'b0;
    for (int i = 0; i < NumStages; i = i + 1) begin
      if (ovf[i]) begin
        err_ovf <= 1'b1;
      end
    end
  end

endmodule

`default_nettype wire
