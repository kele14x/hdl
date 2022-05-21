// File: fft_stage.sv
// Brief: FFT process stage. Each stage includes:
//          - 1 Twiddler (twidder factor ROM and complex multiplier)
//          - 1 Butterfly operator
`default_nettype none
//
`timescale 1 ns / 1 ps

module fft_stage #(
    parameter int STAGE         = 0,
    parameter int LOG_FFT_SIZE  = 4,
    parameter int DATA_WIDTH    = 16
) (
    input var                             clk,
    input var                             rst,
    // Input
    input var  signed [   DATA_WIDTH-1:0] data_i_in,
    input var  signed [   DATA_WIDTH-1:0] data_q_in,
    input var                       [1:0] sync_in,
    // Output
    output var signed [   DATA_WIDTH-1:0] data_i_out,
    output var signed [   DATA_WIDTH-1:0] data_q_out,
    output var                      [1:0] sync_out,
    // Status output
    output var                            ovf
);

  // Local parameter
  //================

  localparam int DelayTaps    = 2 ** (LOG_FFT_SIZE - STAGE - 1);
  localparam int Latency      = (STAGE == 0 ? (DelayTaps + 2) : (DelayTaps + 9));
  localparam int TwiddleWidth = STAGE;


  // Signals
  //========

  // Counter count from 0 to FFT_SIZE - 1
  logic      [LOG_FFT_SIZE-1:0] counter_sel;
  logic      [LOG_FFT_SIZE-1:0] counter_twiddle;

  logic                         sel;
  logic      [TwiddleWidth-1:0] twiddle;

  logic signed [DATA_WIDTH-1:0] data_i_twiddled;
  logic signed [DATA_WIDTH-1:0] data_q_twiddled;

  logic signed [DATA_WIDTH-1:0] delayed_i_in;
  logic signed [DATA_WIDTH-1:0] delayed_q_in;

  logic signed [DATA_WIDTH-1:0] delayed_i_out;
  logic signed [DATA_WIDTH-1:0] delayed_q_out;

  logic signed [DATA_WIDTH-1:0] data_i_s;
  logic signed [DATA_WIDTH-1:0] data_q_s;


  // Main
  //=====

  // Control signal for each stage

  always_ff @(posedge clk) begin
    if (~sync_in[0]) begin
      counter_sel <= '0;
    end else begin
      counter_sel <= counter_sel + 1;
    end 
  end

  always_ff @(posedge clk) begin
    if (~sync_in[1]) begin
      counter_twiddle <= '0;
    end else begin
      counter_twiddle <= counter_twiddle + 1;
    end 
  end

  // `sel` indicates upper half (0) or lower half (1) of each group
  assign sel = counter_sel[LOG_FFT_SIZE-STAGE-1];

  generate
    if (STAGE == 0) begin : g_no_twiddle

      // Twiddle is twiddle factor index
      assign twiddle = '0;

      always_ff @(posedge clk) begin
        data_i_twiddled <= data_i_in;
        data_q_twiddled <= data_q_in;
      end
      
    end else begin : g_twiddle

      logic signed [DATA_WIDTH-1:0] twiddle_i_s;
      logic signed [DATA_WIDTH-1:0] twiddle_q_s;

      always_comb begin
        if (~counter_twiddle[LOG_FFT_SIZE-STAGE-1]) begin
          // Upper half
          twiddle = '0;
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
          .rst          (rst),
          //
          .en           (1'b1),
          .twiddle      (twiddle),
          //
          .twiddle_i_out(twiddle_i_s),
          .twiddle_q_out(twiddle_q_s)
      );

      cmult #(
          .A_WIDTH (DATA_WIDTH),
          .B_WIDTH (DATA_WIDTH),
          .P_WIDTH (DATA_WIDTH),
          .SRA_BITS(DATA_WIDTH - 1)
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
  // TODO: maybe it could be implement in DSP

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

  always_ff @(posedge clk) begin
    data_i_out <= data_i_s;
    data_q_out <= data_q_s;
  end

  // Data delay line

  fft_delay #(
      .DELAY_TAPS(DelayTaps),
      .DATA_WIDTH(DATA_WIDTH)
  ) i_delay (
      .clk       (clk),
      .rst       (rst),
      //
      .data_i_in (delayed_i_out),
      .data_q_in (delayed_q_out),
      //
      .data_i_out(delayed_i_in),
      .data_q_out(delayed_q_in)
  );

  // Control delay line

  reg_pipeline #(
      .DATA_WIDTH     (1),
      .PIPELINE_STAGES(DelayTaps + 9)
  ) i_sync0_pipeline (
      .clk (clk),
      .din (sync_in[0]),
      .dout(sync_out[0])
  );

  reg_pipeline #(
      .DATA_WIDTH     (1),
      .PIPELINE_STAGES(STAGE == 0 ? DelayTaps - 1 : DelayTaps + 9)
  ) i_sync1_pipeline (
      .clk (clk),
      .din (sync_in[1]),
      .dout(sync_out[1])
  );

endmodule

`default_nettype wire
