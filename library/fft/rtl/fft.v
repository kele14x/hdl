// File: fft.v
// Brief: Top of FFT module.
`default_nettype none
//
`timescale 1 ns / 1 ps

module fft #(
    // FFT size, must be power of 2
    parameter integer FFT_SIZE          = 4096,
    // Input data width for I and Q
    parameter integer INPUT_DATA_WIDTH  = 16,
    // Phase factor data width
    parameter integer PHASE_WIDTH       = 16,
    // Output data width for I and Q
    parameter integer OUTPUT_DATA_WIDTH = 28
) (
    input  wire                         clk,
    input  wire                         rst,
    // Data input
    input  wire [ INPUT_DATA_WIDTH-1:0] data_i_in,
    input  wire [ INPUT_DATA_WIDTH-1:0] data_q_in,
    input  wire                         data_valid_in,
    input  wire                         data_last_in,
    // Data output
    output wire [OUTPUT_DATA_WIDTH-1:0] data_i_out,
    output wire [OUTPUT_DATA_WIDTH-1:0] data_q_out,
    output wire                         data_valid_out,
    output wire                         data_last_out,
    // Status output
    output reg                          err_input_halt,
    output reg                          err_last_unexpected,
    output reg                          err_ovf
);


`ifdef COCOTB_SIM
  initial begin
    $dumpfile("fft.vcd");
    $dumpvars(0, fft);
  end
`endif


  // Local parameters
  //=================

  localparam integer LogFftSize = $clog2(FFT_SIZE);
  localparam integer Latency = LogFftSize * 9 + FFT_SIZE - 8;


  // Check parameters
  //=================

  initial begin
    // Check FFT size
    if (!(2 <= FFT_SIZE && FFT_SIZE <= 16384)) begin
      $error("[%m]: FFT size (FFT_SIZE) must be within the range 2 to 16384.");
      #1 $finish();
    end
    if (!(FFT_SIZE == 2 ** LogFftSize)) begin
      $error("[%m]: FFT size (FFT_SIZE) must be power of 2.");
      #1 $finish();
    end

    // Check input data width
    if (!(8 <= INPUT_DATA_WIDTH && INPUT_DATA_WIDTH <= 32)) begin
      $error("[%m]: Input data width (INPUT_DATA_WIDTH) must be within the range 8 to 32.");
      #1 $finish();
    end

    // Check output data width
    if (!(INPUT_DATA_WIDTH <= OUTPUT_DATA_WIDTH &&
      OUTPUT_DATA_WIDTH <= INPUT_DATA_WIDTH + LogFftSize)) begin
      $error("[%m]: Output data width (OUTPUT_DATA_WIDTH) must be within the range %d to %d.",
             INPUT_DATA_WIDTH, INPUT_DATA_WIDTH + LogFftSize);
      #1 $finish();
    end
  end


  // Signals
  //========

  // state = 0: idle, 1: synced with data
  reg                                 state;
  // Counter count from 0 to FFT_SIZE - 1
  reg         [       LogFftSize-1:0] counter;

  wire signed [OUTPUT_DATA_WIDTH-1:0] data_i_s[  0:LogFftSize];
  wire signed [OUTPUT_DATA_WIDTH-1:0] data_q_s[  0:LogFftSize];

  wire        [                  1:0] sync_s  [  0:LogFftSize];

  wire                                ovf     [0:LogFftSize-1];


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

  always @(posedge clk) begin
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

  // Loop generate each stage

  generate
    genvar i;
    for (i = 0; i <= LogFftSize - 1; i = i + 1) begin : g_stage

      // Data width increases by 1 after each stage, (caused by the adder).
      // But should not exceeds output data width.
      localparam integer StageDataWidth = ((INPUT_DATA_WIDTH + i) <= OUTPUT_DATA_WIDTH) ?
        (INPUT_DATA_WIDTH + i) : OUTPUT_DATA_WIDTH;

      wire signed [StageDataWidth-1:0] data_i_stage_in;
      wire signed [StageDataWidth-1:0] data_q_stage_in;

      wire signed [  StageDataWidth:0] data_i_stage_out;
      wire signed [  StageDataWidth:0] data_q_stage_out;

      assign data_i_stage_in = data_i_s[i][StageDataWidth-1:0];
      assign data_q_stage_in = data_q_s[i][StageDataWidth-1:0];

      assign data_i_s[i+1] = {
        {OUTPUT_DATA_WIDTH - StageDataWidth - 1{data_i_stage_out[StageDataWidth]}}, data_i_stage_out
      };
      assign data_q_s[i+1] = {
        {OUTPUT_DATA_WIDTH - StageDataWidth - 1{data_q_stage_out[StageDataWidth]}}, data_q_stage_out
      };

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
      .din ({data_last_in, data_valid_in}),
      .dout({data_last_out, data_valid_out})
  );

  always @(posedge clk) begin : p_err_ovf
    integer i;
    err_ovf <= 1'b0;
    for (i = 0; i < LogFftSize; i = i + 1) begin
      if (ovf[i]) begin
        err_ovf <= 1'b1;
      end
    end
  end

  always @(posedge clk) begin
    err_last_unexpected <= (data_last_in && ~&counter);
  end

  always @(posedge clk) begin
    err_input_halt <= (!data_valid_in && |counter);
  end

endmodule

`default_nettype wire
