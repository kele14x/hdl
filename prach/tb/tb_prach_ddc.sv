`timescale 1 ns / 1 ps
//
`default_nettype none

module tb_prach_ddc;

  parameter integer NUM_ANT = 4;
  parameter integer NUM_STAGE = 6;

  logic        clk;
  logic        rst;
  //
  logic [15:0] din_dr;
  logic [15:0] din_di;
  logic        din_sf;
  logic        din_sl;
  logic        din_sy;
  logic [ 7:0] din_chn;
  logic        din_dv;
  logic        din_last;
  //
  logic [15:0] dout_dr;
  logic [15:0] dout_di;
  logic        dout_sf;
  logic        dout_sl;
  logic        dout_sy;
  logic [ 7:0] dout_chn;
  logic        dout_dv;
  logic        dout_last;
  // CSR
  //----
  logic [17:0] ctrl_fcw;
  logic [ 3:0] ctrl_bw;

  localparam real PI = 3.14159265358979323846;

  integer fout;

  // Clock & Reset

  initial begin
    clk = 0;
    forever #1 clk = ~clk;
  end

  initial begin
    rst = 1;
    repeat (100) @(posedge clk);
    rst <= 0;
  end

  // Configuration

  initial begin
    $display("*** Simulation starts ***");
    ctrl_fcw = 0;
    ctrl_bw = 0;
    #(1000000);
    $finish;
  end

  final begin
    $fclose(fout);
    $display("*** Simulation ends ***");
  end

  // Input driver

  initial begin
    din_dr   = 0;
    din_di   = 0;
    din_sf   = 0;
    din_sl   = 0;
    din_sy   = 0;
    din_chn  = 0;
    din_dv   = 0;
    din_last = 0;
    wait (rst == 0);

    // Flush the pipeline
    for (int i = 0; i < 25600; i++) begin
      @(posedge clk);
      din_dr   <= 0;
      din_di   <= 0;
      din_sf   <= 0;
      din_sl   <= 0;
      din_sy   <= 0;
      din_chn  <= (i % 256);
      din_dv   <= 1;
      din_last <= 0;
    end

    // Feed the sine wave
    for (int i = 0; i < 1000000; i++) begin
      @(posedge clk);
//      din_dr   <= 10000 * $cos(2 * PI * -0.52375e6 * i / 491.52e6);
//      din_di   <= 10000 * $sin(2 * PI * -0.52375e6 * i / 491.52e6);
      din_dr   <= i == 0 ? 10000 : 0;
      din_di   <= i == 0 ? 10000 : 0;
      din_sf   <= (i == 0);
      din_sl   <= (i == 0);
      din_sy   <= (i == 0);
      din_chn  <= (i % 256);
      din_dv   <= 1;
      din_last <= 0;
    end
    @(posedge clk);
    din_dv <= 0;
  end

  // Data logger

  initial begin
    // Open the output file
    fout = $fopen("output.txt", "w");
    if (!fout) begin
      $error("Could not open file");
      $finish();
    end

    // Wait for sync
    forever begin
      @(posedge clk);
      if (DUT.conv_dout_sf) break;
    end

    // Write output to file
    forever begin
      $fwrite(fout, "%d, %d\n", $signed(DUT.conv_dout_dr), $signed(DUT.conv_dout_di));
      @(posedge clk);
    end
  end

  // DUT

  prach_ddc #(
      .NUM_ANT  (NUM_ANT),
      .NUM_STAGE(NUM_STAGE)
  ) DUT (
      .*
  );

endmodule

`default_nettype wire
