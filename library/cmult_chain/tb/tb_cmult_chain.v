// File: tb_cmult_chain.sv
// Brief: Test bench for cmult_chain
`timescale 1 ns / 1 ps 
//
`default_nettype none

module tb_cmult_chain ();

  localparam integer TestVectorLength = 4096;
  localparam integer DutLatency = 8;

  localparam integer AWidth = 16;
  localparam integer BWidth = 16;
  localparam integer PWidth = 16;
  localparam integer SraBits = 15;

  reg clk;
  reg rst;

  reg [AWidth-1:0] ar, ai;
  reg [BWidth-1:0] br, bi;
  reg [PWidth-1:0] pr, pi, pr_ref, pi_ref;

  reg ovf, ovf_ref;

  reg [AWidth-1:0] ar_mem [TestVectorLength];
  reg [AWidth-1:0] ai_mem [TestVectorLength];
  reg [BWidth-1:0] br_mem [TestVectorLength];
  reg [BWidth-1:0] bi_mem [TestVectorLength];
  reg [PWidth-1:0] pr_mem [TestVectorLength];
  reg [PWidth-1:0] pi_mem [TestVectorLength];
  reg              ovf_mem[TestVectorLength];

  initial begin
    $readmemh("test_cmult_input_a_real.txt", ar_mem, 0, TestVectorLength - 1);
    $readmemh("test_cmult_input_a_imag.txt", ai_mem, 0, TestVectorLength - 1);
    $readmemh("test_cmult_input_b_real.txt", br_mem, 0, TestVectorLength - 1);
    $readmemh("test_cmult_input_b_imag.txt", bi_mem, 0, TestVectorLength - 1);
    $readmemh("test_cmult_output_p_real.txt", pr_mem, 0, TestVectorLength - 1);
    $readmemh("test_cmult_output_p_imag.txt", pi_mem, 0, TestVectorLength - 1);
    $readmemh("test_cmult_output_ovf.txt", ovf_mem, 0, TestVectorLength - 1);
  end

  always begin
    clk = 0;
    #5;
    clk = 1;
    #5;
  end

  initial begin
    rst = 1;
    #100;
    rst = 0;
  end

  initial begin
    $display("************************");
    $display("Simulation starts.");
    wait (rst == 0);
    #100;
    @(posedge clk);
    fork
      begin : p_feed_input
        for (integer i = 0; i < TestVectorLength; i = i + 1) begin
          @(posedge clk);
          ar <= ar_mem[i];
          ai <= ai_mem[i];
          br <= br_mem[i];
          bi <= bi_mem[i];
        end
      end

      begin : p_gen_ref
        repeat (DutLatency) @(posedge clk);
        for (integer i = 0; i < TestVectorLength; i = i + 1) begin
          @(posedge clk);
          pr_ref  <= pr_mem[i];
          pi_ref  <= pi_mem[i];
          ovf_ref <= ovf_mem[i];
        end
      end

      begin : p_checker
        repeat (DutLatency + 1) @(posedge clk);
        for (integer i = 0; i < TestVectorLength; i = i + 1) begin
          @(posedge clk);
          if (pr_ref != pr) begin
            $warning("\"pr\" does not match golden reference, i = %d, t = %t, \
            expect = %x, got = %x", i, $time, pr_ref, pr);
          end
          if (pi_ref != pi) begin
            $warning("\"pi\" does not match golden reference, i = %d, t = %t, \
            expect = %x, got = %x", i, $time, pi_ref, pi);
          end
          if (ovf_ref != ovf) begin
            $warning("\"ovf\" does not match golden reference, i = %d, t = %t, \
            expect = %x, got = %x", i, $time, ovf_ref, ovf);
          end
        end
      end

    join

    #1000;
    $display("Simulation ends.");
    $finish(2);

  end

  cmult_chain #(
      .AWIDTH (AWidth),
      .BWIDTH (BWidth),
      .PWIDTH (PWidth),
      .SRABITS(SraBits)
  ) DUT (
      .clk   (clk),
      .rst   (rst),
      .ar    (ar),
      .ai    (ai),
      .br    (br),
      .bi    (bi),
      .pi    (pi),
      .pr    (pr),
      .ovf   (ovf)
  );

endmodule

`default_nettype wire
