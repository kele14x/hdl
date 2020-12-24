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

// File: tb_cordic_rotate.sv
// Brief: Test bench for module cordic_rotate
`timescale 1ns / 1ps `default_nettype none

module tb_cordic_rotate ();

  // DUT parameters

  localparam int Iterations = 7;
  localparam int DataWidth = 16;
  localparam int CompensationScaling = 1;
  localparam int CtrlWidth = 1;

  // DUT ports

  logic                        clk;
  logic                        rst;

  logic signed [DataWidth-1:0] xin;
  logic signed [DataWidth-1:0] yin;
  logic        [ Iterations:0] theta;
  logic                        ctrl_in;

  logic signed [DataWidth+1:0] xout;
  logic signed [DataWidth+1:0] yout;
  logic                        ctrl_out;

  // Test bench parameters

  localparam int TestVectorLength = 1000;
  localparam int Latency = 10;

  // Test bench signals

  logic signed [DataWidth-1:0] xin_mem  [TestVectorLength];
  logic signed [DataWidth-1:0] yin_mem  [TestVectorLength];
  logic        [ Iterations:0] theta_mem[TestVectorLength];

  logic signed [DataWidth+1:0] xout_mem [TestVectorLength];
  logic signed [DataWidth+1:0] yout_mem [TestVectorLength];


  initial begin
    $readmemh("test_cordic_rotate_input_xin.txt", xin_mem, 0, TestVectorLength - 1);
    $readmemh("test_cordic_rotate_input_yin.txt", yin_mem, 0, TestVectorLength - 1);
    $readmemh("test_cordic_rotate_input_theta.txt", theta_mem, 0, TestVectorLength - 1);
    $readmemh("test_cordic_rotate_output_xout.txt", xout_mem, 0, TestVectorLength - 1);
    $readmemh("test_cordic_rotate_output_yout.txt", yout_mem, 0, TestVectorLength - 1);
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
    $display("*****************");
    $display("Simulation starts");

    // Wait reset done
    wait(rst == 0);
    @(posedge clk);

    fork
      // Stimulation
      begin : p_feed_input
        for (int i = 0; i < TestVectorLength; i++) begin
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
      begin : p_checker
        repeat (Latency + 1) @(posedge clk);
        for (int i = 0; i < TestVectorLength; i++) begin
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
    $finish(2);
  end

  cordic_rotate #(
      .ITERATIONS          (Iterations),
      .DATA_WIDTH          (DataWidth),
      .COMPENSATION_SCALING(CompensationScaling),
      .CTRL_WIDTH          (CtrlWidth)
  ) i_cordic_rotate (
      .*
  );

endmodule

`default_nettype wire
