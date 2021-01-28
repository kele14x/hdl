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

// File: tb_hb_up2.sv
// Brief: Test bench for hb_up2

`timescale 1 ns / 1 ps `default_nettype none

module tb_hb_up2 ();

  localparam int ClkPeriod = 10;
  localparam int DutLatency = 6;
  localparam int TestVectorLength = 4096;

  localparam int XinWidth = 16;
  localparam int CoeWidth = 16;
  localparam int NumUniqueCoe = 5;
  localparam signed [CoeWidth-1:0] CoeNums[NumUniqueCoe] = {952, -1609, 3090, -6260, 20622};
  localparam int YoutWidth = 16;
  localparam int SraBits = 15;

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
    $readmemh("test_hb_up2_xin.txt", xin_mem, 0, TestVectorLength - 1);
    $readmemh("test_hb_up2_yout.txt", yout_mem, 0, TestVectorLength * 2 - 1);
    $readmemh("test_hb_up2_ovf.txt", ovf_mem, 0, TestVectorLength * 2 - 1);
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
    wait(rst == 0);
    xin <= 0;
    #1000;
    @(posedge clk);
    fork
      begin : p_feed_input
        for (int i = 0; i < TestVectorLength; i++) begin
          @(posedge clk);
          xin <= xin_mem[i];
        end
      end

      begin : g_gen_ref
        repeat (DutLatency) @(posedge clk);
        for (int i = 0; i < TestVectorLength; i++) begin
          @(posedge clk);
          yout0_ref <= (i == 0) ? 0 : yout_mem[2*i-1];
          yout1_ref <= yout_mem[2*i];
          ovf_ref   <= ((i == 0) ? 0 : ovf_mem[2*i-1]) | ovf_mem[2*i];
        end
      end

    join

    #1000;
    $display("Simulation ends.");
    $finish(2);
  end


  hb_up2 #(
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
