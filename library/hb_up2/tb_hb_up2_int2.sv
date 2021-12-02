// File: tb_hb_up2.sv
// Brief: Test bench for hb_up2

`timescale 1 ns / 1 ps `default_nettype none

module tb_hb_up2_int2 ();

  localparam int ClkPeriod = 10;
  localparam int TestVectorLength = 4096;

  localparam int XinWidth = 16;
  localparam int CoeWidth = 16;
  localparam int NumUniqueCoe = 3;
  localparam signed [CoeWidth-1:0] CoeNums[NumUniqueCoe] = {1277, -4710, 20014};
  localparam int YoutWidth = 16;
  localparam int SraBits = 15;

  localparam int ImpulseLatency = DUT.Latency;
  localparam int DutLatency = ImpulseLatency - NumUniqueCoe * 2;

  logic                clk;
  logic                rst;

  logic [XinWidth-1:0] xin;

  logic [YoutWidth-1:0] yout0, yout0_ref;
  logic [YoutWidth-1:0] yout1, yout1_ref;
  logic ovf, ovf_ref;

  logic [ XinWidth-1:0] xin_mem [    TestVectorLength];
  logic [YoutWidth-1:0] yout_mem[TestVectorLength * 2];
  logic                 ovf_mem [TestVectorLength * 2];

  initial begin
    $readmemh("test_hb_up2_input_xin.txt", xin_mem, 0, TestVectorLength - 1);
    $readmemh("test_hb_up2_output_yout.txt", yout_mem, 0, TestVectorLength * 2 - 1);
    $readmemh("test_hb_up2_output_ovf.txt", ovf_mem, 0, TestVectorLength * 2 - 1);
  end

  always begin
    clk = 0;
    #(ClkPeriod / 2);
    clk = 1;
    #(ClkPeriod / 2);
  end

  initial begin
    rst = 1;
    #100;
    rst = 0;
  end

  initial begin
    $display("*****************");
    $display("Simulation start.");
    wait (rst == 0);
    xin <= 0;
    #1000;
    @(posedge clk);
    fork
      begin : p_feed_input
        for (int i = 0; i < TestVectorLength; i++) begin
          @(posedge clk);
          xin <= xin_mem[i];
          @(posedge clk);
          xin <= 0;
        end
      end

      begin : g_gen_ref
        repeat (DutLatency) @(posedge clk);
        for (int i = 0; i < TestVectorLength; i++) begin
          @(posedge clk);
          yout0_ref <= (i == 0) ? 0 : yout_mem[2*i-1];
          yout1_ref <= yout_mem[2*i];
          ovf_ref   <= ((i == 0) ? 0 : ovf_mem[2*i-1]) | ovf_mem[2*i];
          @(posedge clk);
          yout0_ref <= 0;
          yout1_ref <= 0;
          ovf_ref   <= 0;
        end
      end

    join

    #1000;
    $display("Simulation ends.");
    $finish(2);
  end


  hb_up2_int2 #(
      .XIN_WIDTH     (XinWidth),
      .COE_WIDTH     (CoeWidth),
      .NUM_UNIQUE_COE(NumUniqueCoe),
      .COE_NUMS      (CoeNums),
      .YOUT_WIDTH    (YoutWidth),
      .SRA_BITS      (SraBits)
  ) DUT (
      .*
  );

endmodule

`default_nettype wire
