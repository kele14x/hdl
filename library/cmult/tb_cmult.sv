//******************************************************************************
// Copyright (C) 2020  kele14x
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
//******************************************************************************

// File: tb_cmult.sv
// Brief: Test bench for cmult
`timescale 1ns / 1ps `default_nettype none

module tb_cmult ();

  localparam int TestVectorLength = 4096;
  localparam int DutLatency = 7;

  localparam int AWidth = 16;
  localparam int BWidth = 16;
  localparam int PWidth = 16;
  localparam int SraBits = 15;

  logic clk;
  logic rst;

  logic [AWidth-1:0] ar, ai;
  logic [BWidth-1:0] br, bi;
  logic [PWidth-1:0] pr, pi, pr_ref, pi_ref;

  logic ovf, ovf_ref;

  logic [AWidth-1:0] ar_mem [TestVectorLength];
  logic [AWidth-1:0] ai_mem [TestVectorLength];
  logic [BWidth-1:0] br_mem [TestVectorLength];
  logic [BWidth-1:0] bi_mem [TestVectorLength];
  logic [PWidth-1:0] pr_mem [TestVectorLength];
  logic [PWidth-1:0] pi_mem [TestVectorLength];
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
      .AWIDTH (AWidth),
      .BWIDTH (BWidth),
      .PWIDTH (PWidth),
      .SRABITS(SraBits)
  ) DUT (
      .*
  );

endmodule

`default_nettype wire
