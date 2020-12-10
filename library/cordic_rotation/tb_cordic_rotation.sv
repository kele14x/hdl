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

// File: tb_cordic_rotation.sv
// Brief: Testbench for modile cordic_rotation
`timescale 1ns / 1ps

module tb_cordic_rotation ();

  parameter int ITERATIONS = 7;
  parameter int DATA_WIDTH = 16;
  parameter int COMPENSATION_SCALING = 1;

  parameter int TEST_LENGTH = 1000;
  parameter int LATENCY = 10;


  logic                         clk;
  logic                         rst;

  logic signed [DATA_WIDTH-1:0] xin;
  logic signed [DATA_WIDTH-1:0] yin;
  logic        [  ITERATIONS:0] theta;

  logic signed [DATA_WIDTH+1:0] xout;
  logic signed [DATA_WIDTH+1:0] yout;


  logic signed [DATA_WIDTH-1:0] xin_mem  [TEST_LENGTH];
  logic signed [DATA_WIDTH-1:0] yin_mem  [TEST_LENGTH];
  logic        [  ITERATIONS:0] theta_mem[TEST_LENGTH];

  logic signed [DATA_WIDTH+1:0] xout_mem [TEST_LENGTH];
  logic signed [DATA_WIDTH+1:0] yout_mem [TEST_LENGTH];


  initial begin
    $readmemh("test_cordic_rotation_input_xin.txt", xin_mem, 0, TEST_LENGTH - 1);
    $readmemh("test_cordic_rotation_input_yin.txt", yin_mem, 0, TEST_LENGTH - 1);
    $readmemh("test_cordic_rotation_input_theta.txt", theta_mem, 0, TEST_LENGTH - 1);
    $readmemh("test_cordic_rotation_output_xout.txt", xout_mem, 0, TEST_LENGTH - 1);
    $readmemh("test_cordic_rotation_output_yout.txt", yout_mem, 0, TEST_LENGTH - 1);
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
      begin
        for (int i = 0; i < TEST_LENGTH; i++) begin
          @(posedge clk);
          xin   <= xin_mem[i];
          yin   <= yin_mem[i];
          theta <= theta_mem[i];
        end
        @(posedge clk);
        xin   <= 0;
        yin   <= 0;
        theta <= 0;
      end

      // Checker
      begin
        repeat (LATENCY + 1) @(posedge clk);
        for (int i = 0; i < TEST_LENGTH; i++) begin
          @(posedge clk);
          if (xout != xout_mem[i]) begin
            $warning("\"xout\" output mismatch with gold result. Time=%t, i=%d, expect=%x, got=%x",
                     $time, i, xout_mem[i], xout);
          end
          if (yout != yout_mem[i]) begin
            $warning("\"yout\" output mismatch with gold result. Time=%t, i=%d, expect=%x, got=%x",
                     $time, i, yout_mem[i], yout);
          end
        end
      end

    join

    #100;
    $display("Simulation ends");
    $finish();
  end

  cordic_rotation #(
      .ITERATIONS          (ITERATIONS),
      .DATA_WIDTH          (DATA_WIDTH),
      .COMPENSATION_SCALING(COMPENSATION_SCALING)
  ) i_cordic_rotation (
      .clk  (clk),
      .rst  (rst),
      .xin  (xin),
      .yin  (yin),
      .theta(theta),
      .xout (xout),
      .yout (yout)
  );

endmodule
