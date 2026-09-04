`timescale 1 ns / 1 ps
//
`default_nettype none

module prach_fft #(
    parameter int FFT_SIZE   = 1536,
    parameter int DATA_WIDTH = 16
) (
    input var                          clk,
    input var                          rst,
    //
    input var  signed [DATA_WIDTH-1:0] din_dr,
    input var  signed [DATA_WIDTH-1:0] din_di,
    input var                          din_sf,
    input var                          din_sl,
    input var                          din_sy,
    input var         [           1:0] din_chn,
    input var                          din_dv,
    input var                          din_last,
    //
    output var signed [DATA_WIDTH-1:0] dout_dr,
    output var signed [DATA_WIDTH-1:0] dout_di,
    output var                         dout_sf,
    output var                         dout_sl,
    output var                         dout_sy,
    output var        [           1:0] dout_chn,
    output var                         dout_dv,
    output var                         dout_last,
    //
    output var                         ovf
);

  // Parameters

  localparam int NumFftStage = $clog2(FFT_SIZE) - 1;
  localparam int DataWidthInt = DATA_WIDTH + 2;
  localparam int Latency = FFT_SIZE + 9 * NumFftStage - 4;  // 1622

  function automatic logic [DATA_WIDTH-1:0] saturate(input logic [DataWidthInt-1:0] data);
    if (data[DataWidthInt-1:DATA_WIDTH-1] == '1) begin
      saturate = data[DATA_WIDTH-1:0];
    end else if (data[DataWidthInt-1:DATA_WIDTH-1] == '0) begin
      saturate = data[DATA_WIDTH-1:0];
    end else if (data[DataWidthInt-1]) begin
      saturate = 1 << (DATA_WIDTH - 1);
    end else begin
      saturate = (1 << (DATA_WIDTH - 1)) - 1;
    end
  endfunction

  // Signals

  logic signed [  DATA_WIDTH-1:0] din_dr_r;
  logic signed [  DATA_WIDTH-1:0] din_di_r;
  logic                           din_dv_r;

  logic signed [DataWidthInt-1:0] s0_dr    [NumFftStage+1];
  logic signed [DataWidthInt-1:0] s0_di    [NumFftStage+1];
  logic                           s0_dv    [NumFftStage+1];

  logic        [ NumFftStage-1:0] s0_ovf;

  // Main

  // Input register
  always_ff @(posedge clk) begin
    din_dr_r <= $signed(din_dr);
    din_di_r <= $signed(din_di);
    din_dv_r <= din_dv;
  end

  // Connect input
  assign s0_dr[0] = {{(DataWidthInt - DATA_WIDTH) {din_dr_r[DATA_WIDTH-1]}}, din_dr_r};
  assign s0_di[0] = {{(DataWidthInt - DATA_WIDTH) {din_di_r[DATA_WIDTH-1]}}, din_di_r};
  assign s0_dv[0] = din_dv_r;

  generate
    for (genvar i = 0; i < NumFftStage; i++) begin : g_left_dit2

      if (i == 0) begin : g_first

        prach_fft_ditfft3 #(
            .DATA_WIDTH(DataWidthInt)
        ) u_ditfft3 (
            .clk    (clk),
            .rst    (rst),
            //
            .din_dr (s0_dr[i]),
            .din_di (s0_di[i]),
            .din_dv (s0_dv[i]),
            //
            .dout_dr(s0_dr[i+1]),
            .dout_di(s0_di[i+1]),
            .dout_dv(s0_dv[i+1]),
            //
            .ovf    (s0_ovf[i])
        );

      end else begin : g_left

        prach_fft_ditfft2 #(
            .FFT_SIZE  (3 * 2 ** i),
            .DATA_WIDTH(DataWidthInt),
            .SCALE     ((i % 2 == 1) ? 1 : 0)
        ) u_ditfft2 (
            .clk    (clk),
            .rst    (rst),
            //
            .din_dr (s0_dr[i]),
            .din_di (s0_di[i]),
            .din_dv (s0_dv[i]),
            //
            .dout_dr(s0_dr[i+1]),
            .dout_di(s0_di[i+1]),
            .dout_dv(s0_dv[i+1]),
            //
            .ovf    (s0_ovf[i])
        );

      end
    end
  endgenerate

  always_ff @(posedge clk) begin
    dout_dr <= saturate(s0_dr[NumFftStage]);
    dout_di <= saturate(s0_di[NumFftStage]);
    dout_dv <= s0_dv[NumFftStage];
  end

  always_ff @(posedge clk) begin
    ovf <= |s0_ovf;
  end

  delay #(
      .WIDTH(2),
      .DEPTH(Latency)
  ) u_delay_chn (
      .clk (clk),
      .rst (1'b0),
      .cen (1'b1),
      .din (din_chn),
      .dout(dout_chn)
  );

  pulse_delay #(
      .WIDTH(11)
  ) u_delay_last (
      .clk      (clk),
      .rst      (rst),
      .pulse_in (din_last),
      .pulse_out(dout_last),
      .delay    (11'(Latency))
  );

  pulse_delay #(
      .WIDTH(11)
  ) u_delay_sf (
      .clk      (clk),
      .rst      (rst),
      .pulse_in (din_sf),
      .pulse_out(dout_sf),
      .delay    (11'(Latency))
  );

  pulse_delay #(
      .WIDTH(11)
  ) u_delay_sl (
      .clk      (clk),
      .rst      (rst),
      .pulse_in (din_sl),
      .pulse_out(dout_sl),
      .delay    (11'(Latency))
  );

  pulse_delay #(
      .WIDTH(11)
  ) u_delay_sy (
      .clk      (clk),
      .rst      (rst),
      .pulse_in (din_sy),
      .pulse_out(dout_sy),
      .delay    (11'(Latency))
  );

endmodule

`default_nettype wire
