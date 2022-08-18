// File: fft_stage.v
// Brief: FFT process stage. Each stage includes:
//          - 1 Twiddler (twidder factor ROM and complex multiplier)
//          - 1 Butterfly operator
`timescale 1 ns / 1 ps
//
`default_nettype none

module fft_stage #(
    parameter int STAGE              = 0,
    parameter int LOG_FFT_SIZE       = 4,
    parameter int DATA_WIDTH         = 16,
    parameter int PHASE_WIDTH        = 16,
    parameter bit BIT_REVERSED_INPUT = 1
) (
    input var                          clk,
    input var                          rst,
    // Input
    input var  signed [DATA_WIDTH-1:0] data_i_in,
    input var  signed [DATA_WIDTH-1:0] data_q_in,
    input var                          data_valid_in,
    input var                          data_last_in,
    input var         [           1:0] sync_in,
    // Output
    output var signed [DATA_WIDTH+1:0] data_i_out,
    output var signed [DATA_WIDTH+1:0] data_q_out,
    output var                         data_valid_out,
    output var                         data_last_out,
    output var        [           1:0] sync_out,
    // Status
    output var                         ovf
);

  // Local parameter
  //================

  localparam int DelayTaps1 = BIT_REVERSED_INPUT ? 2 ** (2 * STAGE) : 2 ** (LOG_FFT_SIZE - 2 * STAGE - 1);

  localparam int DelayTaps2 = BIT_REVERSED_INPUT ? 2 ** (2 * STAGE + 1) : 2 ** (LOG_FFT_SIZE - 2 * STAGE - 2);

  localparam int Latency = (STAGE == 0 ? (DelayTaps1 + DelayTaps2 + 2) : (DelayTaps1 + DelayTaps2 + 9));

  localparam int TwiddleWidth = STAGE == 0 ? 1 : STAGE * 2;


  // Signals
  //========

  // Counter count from 0 to FFT_SIZE - 1
  logic        [LOG_FFT_SIZE-1:0] counter_sel;
  logic        [LOG_FFT_SIZE-1:0] counter_twiddle;

  logic        [TwiddleWidth-1:0] twiddle;

  logic signed [  DATA_WIDTH-1:0] data_i_twiddled;
  logic signed [  DATA_WIDTH-1:0] data_q_twiddled;
  logic                           data_valid_twiddled;
  logic                           data_last_twiddled;

  logic signed [    DATA_WIDTH:0] data_i_s;
  logic signed [    DATA_WIDTH:0] data_q_s;
  logic                           data_valid_s;
  logic                           data_last_s;


  // Main
  //=====

  // Control signal for each stage

  always_ff @(posedge clk) begin
    if (~sync_in[1] || rst) begin
      counter_twiddle <= 'd0;
    end else begin
      counter_twiddle <= counter_twiddle + 1;
    end
  end

  generate
    if (STAGE == 0) begin : g_no_twiddle

      // There is no twiddle at first stage
      assign twiddle             = 1'b0;

      assign data_i_twiddled     = data_i_in;
      assign data_q_twiddled     = data_q_in;
      assign data_valid_twiddled = data_valid_in;
      assign data_last_twiddled  = data_last_in;

      assign ovf                 = 1'b0;

    end else begin : g_twiddle

      wire signed [15:0] twiddle_i_s;
      wire signed [15:0] twiddle_q_s;

      // Twiddle is twiddle factor index
      always_comb begin
        if (~counter_twiddle[LOG_FFT_SIZE-STAGE-1]) begin
          // Upper half
          twiddle = 'd0;
        end else begin
          // Lower half be twiddled by the factor
          twiddle = counter_twiddle[LOG_FFT_SIZE-1:LOG_FFT_SIZE-STAGE];
        end
      end

      fft_twiddle_rom #(
          .TWIDDLE_WIDTH(TwiddleWidth),
          .DATA_WIDTH   (PHASE_WIDTH)
      ) i_twiddle_rom (
          .clk          (clk),
          .rst          (1'b0),
          //
          .en           (1'b1),
          .twiddle      (twiddle),
          //
          .twiddle_i_out(twiddle_i_s),
          .twiddle_q_out(twiddle_q_s)
      );

      cmult #(
          .A_WIDTH (DATA_WIDTH),
          .B_WIDTH (PHASE_WIDTH),
          .P_WIDTH (DATA_WIDTH),
          .SRA_BITS(PHASE_WIDTH - 2)
      ) i_cmult (
          .clk(clk),
          .rst(rst),
          //
          .ar (data_i_in),
          .ai (data_q_in),
          //
          .br (twiddle_i_s),
          .bi (twiddle_q_s),
          //
          .pr (data_i_twiddled),
          .pi (data_q_twiddled),
          //
          .ovf(ovf)
      );

    end
  endgenerate

  // The butterfly operator

  fft_bf2 #(
      .LOG_SIZE  (2 ** STAGE),
      .HAS_NJ    (1'b0),
      .DATA_WIDTH(DATA_WIDTH)
  ) i_bf2i (
      .clk           (clk),
      .rst           (rst),
      //
      .data_i_in     (data_i_twiddled),
      .data_q_in     (data_q_twiddled),
      .data_valid_in (data_valid_twiddled),
      .data_last_in  (data_last_twiddled),
      //
      .data_i_out    (data_i_s),
      .data_q_out    (data_q_s),
      .data_valid_out(data_valid_s),
      .data_last_out (data_last_s)
  );

  fft_bf2 #(
      .LOG_SIZE  (2 ** (STAGE + 1)),
      .HAS_NJ    (1'b1),
      .DATA_WIDTH(DATA_WIDTH + 1)
  ) i_bf2ii (
      .clk           (clk),
      .rst           (rst),
      //
      .data_i_in     (data_i_s),
      .data_q_in     (data_q_s),
      .data_valid_in (data_valid_s),
      .data_last_in  (data_last_s),
      //
      .data_i_out    (data_i_out),
      .data_q_out    (data_q_out),
      .data_valid_out(data_valid_out),
      .data_last_out (data_last_out)
  );

  // Control delay line

  shift_regs #(
      .DATA_WIDTH(1),
      .DEPTH     (DelayTaps1 + DelayTaps2 + 9)
  ) i_sync0_delay (
      .clk (clk),
      .cen (1'b1),
      .din (sync_in[0]),
      .dout(sync_out[0])
  );

  shift_regs #(
      .DATA_WIDTH(1),
      .DEPTH     (STAGE == 0 ? DelayTaps1 + DelayTaps2 - 1 : DelayTaps1 + DelayTaps2 + 9)
  ) i_sync1_delay (
      .clk (clk),
      .cen (1'b1),
      .din (sync_in[1]),
      .dout(sync_out[1])
  );

endmodule

`default_nettype wire
