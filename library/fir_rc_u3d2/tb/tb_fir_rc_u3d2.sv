// File: tb_fir_rc_u3d2.sv
// Brief: Test bench for fir_rc_u3d2

`timescale 1 ns / 1 ps `default_nettype none

module tb_fir_rc_u3d2 ();

  localparam int ClkPeriod = 10;
  localparam int TestVectorLength = 4096;

  localparam int XinWidth = 16;
  localparam int CoeWidth = 16;
  localparam int NumUniqueCoe = 10;
  localparam signed [CoeWidth-1:0] CoeNums[NumUniqueCoe] = {22, 59, -244,
      -427, 1101, 1665, -3566, -5196, 12690, 26660};
  localparam int YoutWidth = 16;
  localparam int SraBits = 15;

  localparam int ImpulseLatency = DUT.Latency;
  localparam int DutLatency = ImpulseLatency - NumUniqueCoe/2 + 2;


  logic                clk;
  logic                rst;

  logic [XinWidth-1:0] xin0, xin1;

  logic [YoutWidth-1:0] yout0, yout0_ref;
  logic [YoutWidth-1:0] yout1, yout1_ref;
  logic [YoutWidth-1:0] yout2, yout2_ref;
  logic ovf, ovf_ref;

  logic [ XinWidth-1:0] xin_mem [TestVectorLength];
  logic [YoutWidth-1:0] yout_mem[TestVectorLength * 3 / 2];
  logic                 ovf_mem [TestVectorLength * 3 / 2];

  initial begin
    $readmemh("test_fir_rc_input_xin.txt", xin_mem, 0, TestVectorLength - 1);
    $readmemh("test_fir_rc_output_yout.txt", yout_mem, 0, TestVectorLength * 3 / 2 - 1);
    $readmemh("test_fir_rc_output_ovf.txt", ovf_mem, 0, TestVectorLength * 3 / 2 - 1);
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
    xin0 <= 0;
    xin1 <= 0;
    #1000;
    @(posedge clk);
    fork
      begin : p_feed_input
        for (int i = 0; i < TestVectorLength / 2; i++) begin
          @(posedge clk);
//          xin0 <= i == 100 ? 32767 : 0;
//          xin1 <= 0;
          xin0 <= xin_mem[i*2];
          xin1 <= xin_mem[i*2+1];
        end
      end

      begin : g_gen_ref
        repeat (DutLatency) @(posedge clk);
        for (int i = 0; i < TestVectorLength / 2; i++) begin
          @(posedge clk);
          yout0_ref <= yout_mem[i*3];
          yout1_ref <= yout_mem[i*3+1];
          yout2_ref <= yout_mem[i*3+2];
          ovf_ref   <= ovf_mem[i*3] | ovf_mem[i*3+1] | ovf_mem[i*3+2];
        end
      end

    join

    #1000;
    $display("Simulation ends.");
    $finish(2);
  end


  fir_rc_u3d2 #(
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
