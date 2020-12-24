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

// File: tb_cordic_cart2pol.sv
// Brief: Test bench for module cordic_cart2pol
`timescale 1ns / 1ps

module tb_cordic_cart2pol ();

  localparam int DataWidth = 16;
  localparam int CtrlWidth = 1;
  localparam int Iterations = 7;
  localparam int CompensationScaling = 1;

  logic                        clk;
  logic                        rst;

  logic signed [DataWidth-1:0] xin;
  logic signed [DataWidth-1:0] yin;
  logic                        ctrl_in;

  logic        [ Iterations:0] theta;
  logic signed [DataWidth+1:0] r;
  logic                        ctrl_out;


  localparam int TestVectorLength = 1000;
  localparam int Latency = 10;

  logic signed [15:0] xin_mem  [TestVectorLength];
  logic signed [15:0] yin_mem  [TestVectorLength];
  logic        [ 7:0] theta_mem[TestVectorLength];
  logic signed [17:0] r_mem    [TestVectorLength];

  initial begin
    $readmemh("test_cordic_cart2pol_input_xin.txt", xin_mem, 0, TestVectorLength - 1);
    $readmemh("test_cordic_cart2pol_input_yin.txt", yin_mem, 0, TestVectorLength - 1);
    $readmemh("test_cordic_cart2pol_output_theta.txt", theta_mem, 0, TestVectorLength - 1);
    $readmemh("test_cordic_cart2pol_output_r.txt", r_mem, 0, TestVectorLength - 1);
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
    $display("**********");
    $display("Simulation starts");

    // Wait reset done
    wait(rst == 0);
    @(posedge clk);

    fork
      // Stimulation
      begin : p_feed_input
        for (int i = 0; i < TestVectorLength; i++) begin
          @(posedge clk);
          xin <= xin_mem[i];
          yin <= yin_mem[i];
        end
        @(posedge clk);
        xin <= 0;
        yin <= 0;
      end

      // Checker
      begin : p_checker
        repeat (Latency + 1) @(posedge clk);
        for (int i = 0; i < TestVectorLength; i++) begin
          @(posedge clk);
          if (theta != theta_mem[i]) begin
            $warning("\"Theta\" output mismatch with gold result. Time=%t, i=%d, expect=%x, got=%x",
                     $time, i, theta_mem[i], theta);
          end
          if (r != r_mem[i]) begin
            $warning("\"R\" output mismatch with gold result. Time=%t, i=%d, expect=%x, got=%x",
                     $time, i, r_mem[i], r);
          end
        end
      end

    join

    #100;
    $display("Simulation ends");
    $finish();
  end

  cordic_cart2pol #(
      .ITERATIONS          (Iterations),
      .DATA_WIDTH          (DataWidth),
      .COMPENSATION_SCALING(CompensationScaling)
  ) i_cordic_cart2pol (
      .*
  );

endmodule
