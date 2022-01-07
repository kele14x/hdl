// File: tb_cmult.sv
// Brief: Test bench for cmult

`timescale 1 ns / 1 ps `default_nettype none

module tb_cmult ();

  localparam int TestVectorLength = 4096;
  localparam int DutLatency = 8;

  localparam int A_WIDTH  = 16;
  localparam int B_WIDTH  = 16;
  localparam int P_WIDTH  = 16;
  localparam int SRA_BITS = 15;

  logic clk;
  logic rst;

  logic [A_WIDTH-1:0] ar, ai;
  logic [B_WIDTH-1:0] br, bi;
  logic [P_WIDTH-1:0] pr, pi, pr_ref, pi_ref;

  logic ovf, ovf_ref;

  logic [A_WIDTH-1:0] ar_mem [TestVectorLength];
  logic [A_WIDTH-1:0] ai_mem [TestVectorLength];
  logic [B_WIDTH-1:0] br_mem [TestVectorLength];
  logic [B_WIDTH-1:0] bi_mem [TestVectorLength];
  logic [P_WIDTH-1:0] pr_mem [TestVectorLength];
  logic [P_WIDTH-1:0] pi_mem [TestVectorLength];
  logic              ovf_mem[TestVectorLength];

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
    wait(rst == 0);
    #100;
    @(posedge clk);
    fork
      begin : p_feed_input
        for (int i = 0; i < TestVectorLength; i++) begin
          @(posedge clk);
          ar <= ar_mem[i];
          ai <= ai_mem[i];
          br <= br_mem[i];
          bi <= bi_mem[i];
        end
      end

      begin : p_gen_ref
        repeat (DutLatency) @(posedge clk);
        for (int i = 0; i < TestVectorLength; i++) begin
          @(posedge clk);
          pr_ref  <= pr_mem[i];
          pi_ref  <= pi_mem[i];
          ovf_ref <= ovf_mem[i];
        end
      end

      begin : p_checker
        repeat (DutLatency + 1) @(posedge clk);
        for (int i = 0; i < TestVectorLength; i++) begin
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

  cmult #(
      .A_WIDTH (A_WIDTH),
      .B_WIDTH (B_WIDTH),
      .P_WIDTH (P_WIDTH),
      .SRA_BITS(SRA_BITS)
  ) DUT (
      .*
  );

endmodule

`default_nettype wire
