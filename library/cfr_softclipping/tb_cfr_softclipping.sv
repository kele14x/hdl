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

// File: tb_cfr_softclipping.sv
// Brief: Test bench for module cfr_softclipping

`timescale 1ns / 1ps `default_nettype none

module tb_cfr_softclipping ();

  localparam int TestVectorLength = 4096;
  localparam int DutLatency = 23;

  localparam int DataWidth = 16;
  localparam int CpwAddrWidth = 8;

  logic                           clk;
  logic                           rst;

  logic signed [   DataWidth-1:0] data_i_in;
  logic signed [   DataWidth-1:0] data_q_in;

  logic signed [   DataWidth-1:0] data_i_out;
  logic signed [   DataWidth-1:0] data_q_out;

  logic                           ctrl_enable;
  logic        [     DataWidth:0] ctrl_clipping_threshold;
  logic        [     DataWidth:0] ctrl_pd_threshold;

  logic                           ctrl_cpw_wr_en;
  logic        [CpwAddrWidth-1:0] ctrl_cpw_wr_addr;
  logic        [   DataWidth-1:0] ctrl_cpw_wr_data_i;
  logic        [   DataWidth-1:0] ctrl_cpw_wr_data_q;


  logic signed [   DataWidth-1:0] data_i_out_ref;
  logic signed [   DataWidth-1:0] data_q_out_ref;

  logic signed [   DataWidth-1:0] data_i_in_mem           [TestVectorLength];
  logic signed [   DataWidth-1:0] data_q_in_mem           [TestVectorLength];
  logic signed [   DataWidth-1:0] data_i_out_mem          [TestVectorLength];
  logic signed [   DataWidth-1:0] data_q_out_mem          [TestVectorLength];


  initial begin
    $readmemh("test_cfr_softclipping_data_i_in.txt", data_i_in_mem, 0, TestVectorLength - 1);
    $readmemh("test_cfr_softclipping_data_q_in.txt", data_q_in_mem, 0, TestVectorLength - 1);
    $readmemh("test_cfr_softclipping_data_i_out.txt", data_i_out_mem, 0, TestVectorLength - 1);
    $readmemh("test_cfr_softclipping_data_q_out.txt", data_q_out_mem, 0, TestVectorLength - 1);
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

  cfr_softclipping #(
      .DATA_WIDTH    (DataWidth),
      .CPW_ADDR_WIDTH(CpwAddrWidth)
  ) DUT (
      .*
  );

  initial begin
    $display("**************************");
    $display("Simulation starts.");

    wait(rst == 0);

    #100;
    @(posedge clk);
    ctrl_enable    <= 1;
    ctrl_clipping_threshold <= 13818;
    ctrl_pd_threshold <= 13818;
    #100;

    fork
      begin : feed_input
        for (int i = 0; i < TestVectorLength; i++) begin
          @(posedge clk);
          data_i_in <= data_i_in_mem[i];
          data_q_in <= data_q_in_mem[i];
        end
      end

      begin : gen_ref_output
        repeat (DutLatency) @(posedge clk);
        for (int i = 0; i < TestVectorLength; i++) begin
          @(posedge clk);
          data_i_out_ref <= data_i_out_mem[i];
          data_q_out_ref <= data_q_out_mem[i];
        end
      end

      begin : check_output
        repeat (DutLatency + 1) @(posedge clk);
        for (int i = 0; i < TestVectorLength; i++) begin
          @(posedge clk);
          if (data_i_out != data_i_out_ref) begin
            $warning(
                "\"data_i_out\" mismatch with golden reference, time = %t, expected = %x, got = %x",
                $time, data_i_out_ref, data_i_out);
          end
          if (data_q_out != data_q_out_ref) begin
            $warning(
                "\"data_q_out\" mismatch with golden reference, time = %t, expected = %x, got = %x",
                $time, data_q_out_ref, data_q_out);
          end
        end
      end
    join

    #100;
    $display("Simulation ends.");
    $finish();
  end

endmodule
