`timescale 1 ns / 1 ps
//
`default_nettype none

module tb_prach_hb2;

  parameter int DELAY_BASE = 16;
  parameter signed [17:0] UNIQ_COE[2] = '{-18'sd4105, 18'sd36873};

  // Signals
  logic        clk;
  logic        rst;

  logic [15:0] din_dp1;
  logic [15:0] din_dp2;
  logic        din_sf;
  logic        din_sl;
  logic        din_sy;
  logic [ 7:0] din_chn;
  logic        din_dv;
  logic        din_last;

  logic [15:0] dout_dq;
  logic        dout_sf;
  logic        dout_sl;
  logic        dout_sy;
  logic [ 7:0] dout_chn;
  logic        dout_dv;
  logic        dout_last;

  logic        ctrl_bypass;

  // Clock & Reset

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    rst = 1;
    repeat (10) @(posedge clk);
    rst <= 0;
  end

  // Stimulus

  initial begin
    $display("Start of simulation");
    ctrl_bypass = 1;

    // Initialize signals
    din_dp1 = 0;
    din_dp2 = 0;
    din_sf = 0;
    din_sl = 0;
    din_sy = 0;
    din_chn = 0;
    din_dv = 0;
    din_last = 0;

    wait (!rst);

    for (int i = 0; i < 16384; i++) begin
      @(posedge clk);
      din_dp1  <= i == 256 ? 10000 : 0;
      din_dp2  <= i == 256 ? 10000 : 0;
      din_sf   <= i == 0;
      din_sl   <= i == 0;
      din_sy   <= i == 0;
      din_chn  <= i % 256;
      din_dv   <= i % 8 == 0;
      din_last <= i == 16383;
    end

    // Apply stimulus
    repeat (1000) @(posedge clk);
    $finish;
  end

  final begin
    $display("End of simulation");
  end

  // DUT

  prach_hb2 #(
      .DELAY_BASE(DELAY_BASE),
      .UNIQ_COE  (UNIQ_COE)
  ) DUT (
      .*
  );

endmodule

`default_nettype wire
