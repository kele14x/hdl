`timescale 1 ns / 1 ps
//
`default_nettype none

module prach_fft #(
    parameter int HDR_WIDTH = 120
) (
    input var                  clk,
    input var                  rst_n,
    //
    input var  [         15:0] din_dr,
    input var  [         15:0] din_di,
    input var                  din_dv,
    input var                  sync_in,
    input var  [HDR_WIDTH-1:0] hdr_in,
    //
    output var [         15:0] dout_dr,
    output var [         15:0] dout_di,
    output var                 dout_dv,
    output var                 sync_out,
    output var [HDR_WIDTH-1:0] hdr_out
);

  localparam int NumFftStage = 10;
  localparam int NumFftPoints = 3 * 2 ** (NumFftStage - 1);

  localparam int Latency = 1588;
  // 9, 8, 11, 17, 29, 53, 101, 197, 389, 773, 1

  logic signed [         17:0] s0_dr        [NumFftStage+1];
  logic signed [         17:0] s0_di        [NumFftStage+1];
  logic                        s0_dv        [NumFftStage+1];
  logic                        s0_sync      [NumFftStage+1];

  logic                        s0_dv_ahead  [NumFftStage+1];
  logic                        s0_sync_ahead[NumFftStage+1];

  logic        [HDR_WIDTH-1:0] hdr_out_s;


  assign s0_dr[0]         = $signed(din_dr);
  assign s0_di[0]         = $signed(din_di);
  assign s0_dv[0]         = din_dv;
  assign s0_sync[0]       = sync_in;

  assign s0_dv_ahead[0]   = din_dv;
  assign s0_sync_ahead[0] = sync_in;

  prach_ditfft3 u_ditfft3 (
      .clk     (clk),
      .rst_n   (rst_n),
      //
      .din_dr  (s0_dr[0]),
      .din_di  (s0_di[0]),
      .din_dv  (s0_dv[0]),
      .sync_in (s0_sync[0]),
      //
      .dout_dr (s0_dr[1]),
      .dout_di (s0_di[1]),
      .dout_dv (s0_dv[1]),
      .sync_out(s0_sync[1])
  );

  delay #(
      .WIDTH(2),
      .DELAY(6)
  ) u_delay_sync_ahead (
      .clk  (clk),
      .rst_n(1'b1),
      .din  ({s0_sync_ahead[0], s0_dv_ahead[0]}),
      .dout ({s0_sync_ahead[1], s0_dv_ahead[1]})
  );

  generate
    for (genvar i = 0; i < NumFftStage - 1; i++) begin : g_dit2

      prach_ditfft2 #(
          .NUM_FFT_LENGTH(3 * 2 ** (i + 1)),
          .SCALE         (i % 2 == 0)
      ) u_ditfft2 (
          .clk           (clk),
          .rst_n         (rst_n),
          //
          .din_dr        (s0_dr[i+1]),
          .din_di        (s0_di[i+1]),
          .din_dv        (s0_dv[i+1]),
          .sync_in       (s0_sync[i+1]),
          //
          .din_dv_ahead  (s0_dv_ahead[i+1]),
          .sync_ahead_in (s0_sync_ahead[i+1]),
          //
          .dout_dr       (s0_dr[i+2]),
          .dout_di       (s0_di[i+2]),
          .dout_dv       (s0_dv[i+2]),
          .sync_out      (s0_sync[i+2]),
          //
          .dout_dv_ahead (s0_dv_ahead[i+2]),
          .sync_ahead_out(s0_sync_ahead[i+2])
      );

    end
  endgenerate


  // Assume header FIFO will never full

  scfifo #(
      .lpm_width    (HDR_WIDTH),
      .lpm_numwords (16),
      .lpm_showahead("ON"),
      .lpm_widthu   (4)
  ) u_scfifo (
      .clock       (clk),
      .aclr        (~rst_n),
      .sclr        (~rst_n),
      .eccstatus   (  /* not used */),
      .usedw       (  /* not used */),
      // Write
      .wrreq       (sync_in),
      .data        (hdr_in),
      .full        (  /* assume never full */),
      .almost_full (  /* not used */),
      // Read
      .rdreq       (s0_sync[NumFftStage]),
      .q           (hdr_out_s),
      .empty       (  /* not used */),
      .almost_empty(  /* not used */)
  );

  always_ff @(posedge clk) begin
    dout_dr  <= s0_dr[NumFftStage];
    dout_di  <= s0_di[NumFftStage];
    dout_dv  <= s0_dv[NumFftStage];
    sync_out <= s0_sync[NumFftStage];
  end

  always_ff @(posedge clk) begin
    if (s0_sync[NumFftStage]) begin
      hdr_out <= hdr_out_s;
    end
  end

endmodule

`default_nettype wire
