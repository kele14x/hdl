// File: fft_stage.v
// Brief: FFT process stage. Each stage includes:
//          - 1 Twiddler (twidder factor ROM and complex multiplier)
//          - 1 Butterfly operator
`timescale 1 ns / 1 ps
//
`default_nettype none

module fft_stage #(
    parameter integer STAGE        = 0,
    parameter integer LOG_FFT_SIZE = 4,
    parameter integer DATA_WIDTH   = 16
) (
    input  wire                         clk,
    input  wire                         rst,
    // Input
    input  wire signed [DATA_WIDTH-1:0] data_i_in,
    input  wire signed [DATA_WIDTH-1:0] data_q_in,
    input  wire        [           1:0] sync_in,
    // Output
    output reg signed  [  DATA_WIDTH:0] data_i_out,
    output reg signed  [  DATA_WIDTH:0] data_q_out,
    output wire        [           1:0] sync_out,
    // Status output
    output wire                         ovf
);

  // Local parameter
  //================

  localparam integer DelayTaps = 2 ** (LOG_FFT_SIZE - STAGE - 1);
  localparam integer Latency = (STAGE == 0 ? (DelayTaps + 2) : (DelayTaps + 9));
  localparam integer TwiddleWidth = STAGE == 0 ? 1 : STAGE;


  // Signals
  //========

  // Counter count from 0 to FFT_SIZE - 1
  reg         [LOG_FFT_SIZE-1:0] counter_sel;
  reg         [LOG_FFT_SIZE-1:0] counter_twiddle;

  wire                           sel;
  reg         [TwiddleWidth-1:0] twiddle;

  wire signed [  DATA_WIDTH-1:0] data_i_twiddled;
  wire signed [  DATA_WIDTH-1:0] data_q_twiddled;

  wire signed [    DATA_WIDTH:0] delayed_i_in;
  wire signed [    DATA_WIDTH:0] delayed_q_in;

  wire signed [    DATA_WIDTH:0] delayed_i_out;
  wire signed [    DATA_WIDTH:0] delayed_q_out;

  wire signed [    DATA_WIDTH:0] data_i_s;
  wire signed [    DATA_WIDTH:0] data_q_s;


  // Main
  //=====

  // Control signal for each stage

  always @(posedge clk) begin
    if (~sync_in[0] || rst) begin
      counter_sel <= 'd0;
    end else begin
      counter_sel <= counter_sel + 1;
    end
  end

  always @(posedge clk) begin
    if (~sync_in[1] || rst) begin
      counter_twiddle <= 'd0;
    end else begin
      counter_twiddle <= counter_twiddle + 1;
    end
  end

  // `sel` indicates upper half (0) or lower half (1) of each group
  assign sel = counter_sel[LOG_FFT_SIZE-STAGE-1];

  generate
    if (STAGE == 0) begin : g_no_twiddle

      // There is no twiddle at first stage
      initial begin
        twiddle = 'd0;
      end

      shift_regs #(
          .DATA_WIDTH(DATA_WIDTH * 2),
          .DEPTH     (1)
      ) i_sync0_delay (
          .clk (clk),
          .din ({data_q_in, data_i_in}),
          .dout({data_q_twiddled, data_i_twiddled})
      );

      assign ovf = 0;

    end else begin : g_twiddle

      wire signed [15:0] twiddle_i_s;
      wire signed [15:0] twiddle_q_s;

      // Twiddle is twiddle factor index
      always @(*) begin
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
          .DATA_WIDTH   (16)
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
          .B_WIDTH (16),
          .P_WIDTH (DATA_WIDTH),
          .SRA_BITS(15)
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
      .DATA_WIDTH(DATA_WIDTH)
  ) i_bf2 (
      .sel          (sel),
      //
      .delayed_i_in (delayed_i_in),
      .delayed_q_in (delayed_q_in),
      //
      .data_i_in    (data_i_twiddled),
      .data_q_in    (data_q_twiddled),
      //
      .delayed_i_out(delayed_i_out),
      .delayed_q_out(delayed_q_out),
      //
      .data_i_out   (data_i_s),
      .data_q_out   (data_q_s)
  );

  // Add 1 tap register to improve timing

  always @(posedge clk) begin
    data_i_out <= data_i_s;
    data_q_out <= data_q_s;
  end

  // Data delay line

  delay #(
      .DELAY     (DelayTaps),
      .DATA_WIDTH((DATA_WIDTH + 1) * 2)
  ) i_delay (
      .clk (clk),
      .rst (rst),
      .din ({delayed_q_out, delayed_i_out}),
      .dout({delayed_q_in, delayed_i_in})
  );

  // Control delay line

  shift_regs #(
      .DATA_WIDTH(1),
      .DEPTH     (DelayTaps + 9)
  ) i_sync0_delay (
      .clk (clk),
      .din (sync_in[0]),
      .dout(sync_out[0])
  );

  shift_regs #(
      .DATA_WIDTH(1),
      .DEPTH     (STAGE == 0 ? DelayTaps - 1 : DelayTaps + 9)
  ) i_sync1_delay (
      .clk (clk),
      .din (sync_in[1]),
      .dout(sync_out[1])
  );

endmodule

`default_nettype wire
