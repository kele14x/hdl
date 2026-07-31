`default_nettype none
//
`timescale 1 ns / 1 ps

module fft #(
    parameter integer NUM_ANT            = 4,
    parameter logic     INV_FFT            = 1'b0,
    parameter integer LOG_FFT_SIZE       = 11,
    parameter integer DATA_WIDTH         = 16,
    parameter logic     BIT_REVERSED_INPUT = 1'b1
) (
    input  wire                         clk,
    input  wire                         rst,
    // Data input
    input  wire signed [DATA_WIDTH-1:0] din_dr,
    input  wire signed [DATA_WIDTH-1:0] din_di,
    input  wire                         din_sf,
    input  wire                         din_sl,
    input  wire                         din_sy,
    input  wire        [           3:0] din_chn,
    input  wire                         din_dv,
    input  wire                         din_last,
    // Data output
    output logic signed  [DATA_WIDTH-1:0] dout_dr,
    output logic signed  [DATA_WIDTH-1:0] dout_di,
    output wire                         dout_sf,
    output wire                         dout_sl,
    output wire                         dout_sy,
    output logic         [           3:0] dout_chn,
    output logic                          dout_dv,
    output wire                         dout_last,
    //
    // 0: 1k, 1: 2k, 2: 4k
    input  wire        [           1:0] ctrl_size,
    // 0: 16 (30.72), 1: 8 (61.44), 2: 4 (122.88)
    input  wire        [           1:0] ctrl_itlv,
    // Status output
    output logic                          stat_ovf
);

  // Local parameters

  // Number of stages,
  //   - If LOG_FFT_SIZE is even, number of stages is LOG_FFT_SIZE / 2.
  //   - If LOG_FFT_SIZE is odd, number of stages is floor(LOG_FFT_SIZE / 2) + 1
  localparam integer NumStages = (LOG_FFT_SIZE + 1) / 2;

  // Number of Butterfly
  localparam integer NumButterfly = LOG_FFT_SIZE;

  // Number of coarse twiddlers
  localparam integer NumCoarseTwiddler = LOG_FFT_SIZE / 2;

  // Number of twiddlers
  localparam integer NumTwiddler = NumStages - 1;

  localparam integer DataWidthInt = DATA_WIDTH + 2;

  // Check parameters

  // verilog_format: off
  initial begin
    // Check number of interleaved channels
    if (NUM_ANT < 1 || NUM_ANT > 16) begin
      $display("Number of interleaved channels (NUM_ANT) must be within the range 1 to 16, got %0d. [%m]", NUM_ANT);
      $finish();
    end

    // Check FFT size
    if (LOG_FFT_SIZE < 1 || LOG_FFT_SIZE > 14) begin
      $display("Log2 FFT size (LOG_FFT_SIZE) must be within the range 1 to 14, got %0d. [%m]", LOG_FFT_SIZE);
      $finish();
    end

    // Check input data width
    if (DATA_WIDTH < 8 || DATA_WIDTH > 32) begin
      $display("Input data width (DATA_WIDTH) must be within the range 8 to 32, got %0d. [%m]", DATA_WIDTH);
      $finish();
    end
  end
  // verilog_format: on

  // Signals

  // din_dr =>  stage[0] => stage[1] => ... => stage[NumStages-1]
  // din_di =>
  // din_dv =>

  logic signed  [  DATA_WIDTH-1:0] data_dr;
  logic signed  [  DATA_WIDTH-1:0] data_di;
  logic                            data_dv;

  wire signed [DataWidthInt-1:0] data_dr_s       [0:NumStages];
  wire signed [DataWidthInt-1:0] data_di_s       [0:NumStages];
  wire                           data_dv_s       [0:NumStages];

  wire        [   NumStages-1:0] ovf;
  wire                           ovf_at_saturate;

  logic                            dv_d;
  wire        [             3:0] counter_max;

  logic         [            16:0] latency;
  logic         [            11:0] bypass;

  genvar i;

  wire unused_din_chn = &{1'b0, din_chn, 1'b0};

  // Helpers

  function automatic [DATA_WIDTH-1:0] saturate(input [DataWidthInt-1:0] din);
    begin
      if (&(~din[DataWidthInt-1:DATA_WIDTH-1])) begin
        saturate = din[DATA_WIDTH-1:0];
      end else if (&din[DataWidthInt-1:DATA_WIDTH-1]) begin
        saturate = din[DATA_WIDTH-1:0];
      end else if (din[DataWidthInt-1]) begin
        saturate = 16'h8000;
      end else begin
        saturate = 16'h7FFF;
      end
    end
  endfunction

  // Main

  // Input register
  always_ff @(posedge clk) begin
    data_dr <= din_dr;
    data_di <= din_di;
    data_dv <= din_dv;
  end

  // Connect input
  assign data_dr_s[0] = {{(DataWidthInt-DATA_WIDTH){data_dr[DATA_WIDTH-1]}}, data_dr};
  assign data_di_s[0] = {{(DataWidthInt-DATA_WIDTH){data_di[DATA_WIDTH-1]}}, data_di};
  assign data_dv_s[0] = data_dv;

  always_ff @(posedge clk) begin
    dout_dr <= saturate(data_dr_s[NumStages]);
    dout_di <= saturate(data_di_s[NumStages]);
    dout_dv <= data_dv_s[NumStages];
  end

  assign ovf_at_saturate = (!(&(~data_dr_s[NumStages][DataWidthInt-1:DATA_WIDTH-1]) ||
                                &data_dr_s[NumStages][DataWidthInt-1:DATA_WIDTH-1])) ||
                           (!(&(~data_di_s[NumStages][DataWidthInt-1:DATA_WIDTH-1]) ||
                                &data_di_s[NumStages][DataWidthInt-1:DATA_WIDTH-1]));

  // Loop generate each stage
  generate
    for (i = 0; i < NumStages; i = i + 1) begin : g_stage

      // Bigger FFT could be split into multiple small FFTs. One stage process
      // 4 ^ (i + 1) FFT using two radix-2 butterfly operator. If LOG_FFT_SIZE
      // is an odd number, the last stage should be a special stage with only
      // one radix-2 butterfly.
      //
      // For bit reversed input, the log2(FFT_SIZE) per each stage is 4, 16, ...
      // For natural input, the log2(FFT_SIZE) per each stage is N, N/4, ...
      localparam integer StageLogFftSize = BIT_REVERSED_INPUT ?
        ((2 * i + 2) <= LOG_FFT_SIZE ? (2 * i + 2) : LOG_FFT_SIZE) :
        ((NumStages - i) * 2 >= LOG_FFT_SIZE ? LOG_FFT_SIZE : (NumStages - i) * 2);

      // FFT stage

      fft_stage #(
          .NUM_ANT           (NUM_ANT),
          .INV_FFT           (INV_FFT),
          .LOG_FFT_SIZE      (StageLogFftSize),
          .DATA_WIDTH        (DataWidthInt),
          .BIT_REVERSED_INPUT(BIT_REVERSED_INPUT)
      ) i_stage (
          .clk        (clk),
          .rst        (rst),
          //
          .din_dr     (data_dr_s[i]),
          .din_di     (data_di_s[i]),
          .din_dv     (data_dv_s[i]),
          //
          .dout_dr    (data_dr_s[i+1]),
          .dout_di    (data_di_s[i+1]),
          .dout_dv    (data_dv_s[i+1]),
          //
          .ctrl_itlv  (ctrl_itlv),
          .ctrl_bypass(bypass[2*i+1-:2]),
          .ctrl_scale (ctrl_size == 2'b10),
          //
          .stat_ovf   (ovf[i])
      );

    end
  endgenerate

  always_ff @(posedge clk) begin
    stat_ovf <= (|ovf) | ovf_at_saturate;
  end

  assign counter_max = (ctrl_itlv == 2'b00) ? 4'd15 : (ctrl_itlv == 2'b01) ? 4'd7 : 4'd3;

  always_ff @(posedge clk) begin
    dv_d <= data_dv_s[NumStages];
  end

  always_ff @(posedge clk) begin
    if (data_dv_s[NumStages] && !dv_d) begin  // posedge
      dout_chn <= 'd0;
    end else begin
      dout_chn <= (dout_chn == counter_max) ? 'd0 : dout_chn + 1'b1;
    end
  end

  // Total core latency in clock ticks
  //   - NUM_ITLV * (2 ** LOG_FFT_SIZE - 1) : FFT delay
  //   - LOG_FFT_SIZE: FFT butterfly
  //   - (NumStages - 1) * 11: FFT twiddler
  //   - 2: Input/output register
  always_ff @(posedge clk) begin
    if (ctrl_size == 2'b00) begin  // 1k
      case (ctrl_itlv)
        2'b00:   latency <= 17'(1023 * 16 + NumButterfly + NumCoarseTwiddler + 9 * NumTwiddler);
        2'b01:   latency <= 17'(1023 * 8 + NumButterfly + NumCoarseTwiddler + 9 * NumTwiddler);
        default: latency <= 17'(1023 * 4 + NumButterfly + NumCoarseTwiddler + 9 * NumTwiddler);
      endcase
    end else if (ctrl_size == 2'b01) begin  // 2k
      case (ctrl_itlv)
        2'b00:   latency <= 17'(2047 * 16 + NumButterfly + NumCoarseTwiddler + 9 * NumTwiddler);
        2'b01:   latency <= 17'(2047 * 8 + NumButterfly + NumCoarseTwiddler + 9 * NumTwiddler);
        default: latency <= 17'(2047 * 4 + NumButterfly + NumCoarseTwiddler + 9 * NumTwiddler);
      endcase
    end else begin  // 4k
      case (ctrl_itlv)
        2'b00:   latency <= 17'(4095 * 16 + NumButterfly + NumCoarseTwiddler + 9 * NumTwiddler);
        2'b01:   latency <= 17'(4095 * 8 + NumButterfly + NumCoarseTwiddler + 9 * NumTwiddler);
        default: latency <= 17'(4095 * 4 + NumButterfly + NumCoarseTwiddler + 9 * NumTwiddler);
      endcase
    end
  end

  always_ff @(posedge clk) begin
    if (ctrl_size == 2'b00) begin
      bypass <= BIT_REVERSED_INPUT ? 12'b110000000000 : 12'b000000000011;
    end else if (ctrl_size == 2'b01) begin
      bypass <= BIT_REVERSED_INPUT ? 12'b100000000000 : 12'b000000000001;
    end else begin
      bypass <= 12'b000000000000;
    end
  end

  pulse_delay #(
      .WIDTH(17)
  ) u_delay_last (
      .clk      (clk),
      .rst      (rst),
      .pulse_in (din_last),
      .pulse_out(dout_last),
      .delay    (latency)
  );

  pulse_delay #(
      .WIDTH(17)
  ) u_delay_sf (
      .clk      (clk),
      .rst      (rst),
      .pulse_in (din_sf),
      .pulse_out(dout_sf),
      .delay    (latency)
  );

  pulse_delay #(
      .WIDTH(17)
  ) u_delay_sl (
      .clk      (clk),
      .rst      (rst),
      .pulse_in (din_sl),
      .pulse_out(dout_sl),
      .delay    (latency)
  );

  pulse_delay #(
      .WIDTH(17)
  ) u_delay_sy (
      .clk      (clk),
      .rst      (rst),
      .pulse_in (din_sy),
      .pulse_out(dout_sy),
      .delay    (latency)
  );

endmodule

`default_nettype wire
