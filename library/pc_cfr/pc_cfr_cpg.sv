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

// File: pc_cfr_cpg.sv
// Brief: pc_cfr_cpg is Canceling Pulse Generator (CPG) for PC-CFR. It' designed
//        as cascade-able.

`timescale 1ns / 1ps `default_nettype none

module pc_cfr_cpg #(
    parameter int DATA_WIDTH     = 16,
    parameter int CPW_ADDR_WIDTH = 8
) (
    input var  logic                             clk,
    input var  logic                             rst,
    //
    input var  logic signed [    DATA_WIDTH-1:0] data_i_in,
    input var  logic signed [    DATA_WIDTH-1:0] data_q_in,
    //
    input var  logic signed [    DATA_WIDTH-1:0] peak_i_in,
    input var  logic signed [    DATA_WIDTH-1:0] peak_q_in,
    input var  logic                             peak_phase_in,
    input var  logic                             peak_valid_in,
    //
    output var logic signed [    DATA_WIDTH-1:0] data_i_out,
    output var logic signed [    DATA_WIDTH-1:0] data_q_out,
    //
    output var logic signed [    DATA_WIDTH-1:0] peak_i_out,
    output var logic signed [    DATA_WIDTH-1:0] peak_q_out,
    output var logic                             peak_phase_out,
    output var logic                             peak_valid_out,
    // Cancellation pulse write port
    input var  logic                             ctrl_clk,
    input var  logic                             ctrl_rst,
    //
    input var  logic        [CPW_ADDR_WIDTH-1:0] ctrl_cpw_addr,
    input var  logic                             ctrl_cpw_en,
    input var  logic                             ctrl_cpw_we,
    output var logic        [    DATA_WIDTH-1:0] ctrl_cpw_rd_data_i,
    output var logic        [    DATA_WIDTH-1:0] ctrl_cpw_rd_data_q,
    input var  logic        [    DATA_WIDTH-1:0] ctrl_cpw_wr_data_i,
    input var  logic        [    DATA_WIDTH-1:0] ctrl_cpw_wr_data_q
);


  // BRAM read port
  logic                             cpw_rd_en;
  logic        [CPW_ADDR_WIDTH-1:0] cpw_rd_addr;
  logic signed [    DATA_WIDTH-1:0] cpw_rd_data_i;
  logic signed [    DATA_WIDTH-1:0] cpw_rd_data_q;

  // State of CPG stage

  logic state_busy;
  logic [CPW_ADDR_WIDTH-2:0] state_addr;
  logic state_phase;
  logic [DATA_WIDTH-1:0] state_i, state_q, state_i_d, state_q_d;

  logic [DATA_WIDTH-1:0] delta_i, delta_q;

  // State transfer, the basic idea is `state1_*` is for current channel, which
  // is aligned with `peak_*_in`.

  always_ff @(posedge clk) begin
    if (rst) begin
      state_busy <= 'd0;
    end else begin
      state_busy <= (peak_valid_in && ~state_busy) ? 1'b1 : &state_addr ? 1'b0 : state_busy;
    end
  end

  // `state*_addr` will move from 0 to 'hFF
  always_ff @(posedge clk) begin
    if (rst) begin
      state_addr <= 'd0;
    end else begin
      state_addr <= state_busy ? state_addr + 1 : &state_addr ? '0 : state_addr;
    end
  end

  // `state*_phase` is phase of peak
  always_ff @(posedge clk) begin
    if (rst) begin
      state_phase <= 'd0;
    end else begin
      state_phase <= (peak_valid_in && ~state_busy) ? peak_phase_in : &state_addr ? '0 : state_phase;;
    end
  end

  // `state*_phase` is phase of peak
  always_ff @(posedge clk) begin
    if (rst) begin
      state_i <= 'd0;
      state_q <= 'd0;
    end else begin
      {state_q, state_i} <= (peak_valid_in && ~state_busy) ? {
        peak_q_in, peak_i_in
      } : &state_addr ? 'd0 : {
        state_q, state_i
      };
    end
  end

  // If current stage's CPG is busy (state's MSB is high), pass this peak to
  // next CPG.

  always_ff @(posedge clk) begin
    if (rst) begin
      peak_valid_out <= 1'b0;
    end else begin
      peak_valid_out <= peak_valid_in && state_busy;
    end
  end

  always_ff @(posedge clk) begin
    if (peak_valid_in && state_busy) begin
      peak_i_out     <= peak_i_in;
      peak_q_out     <= peak_q_in;
      peak_phase_out <= peak_phase_in;
    end else begin
      peak_i_out     <= 'd0;
      peak_q_out     <= 'd0;
      peak_phase_out <= 'd0;
    end
  end

  assign cpw_rd_en   = state_busy;
  assign cpw_rd_addr = {state_addr, ~state_phase};

  (* keep_hierarchy="yes" *)
  bram_tdp #(
      .ADDR_WIDTH    (CPW_ADDR_WIDTH),
      .DATA_WIDTH    (DATA_WIDTH * 2),
      .USE_OUTPUT_REG(1),
      .INIT_FILE     ("")
  ) i_bram_tdp (
      //
      .clka (ctrl_clk),
      .rsta (ctrl_rst),
      .ena  (ctrl_cpw_en),
      .wea  (ctrl_cpw_we),
      .addra(ctrl_cpw_addr),
      .dina ({ctrl_cpw_wr_data_q, ctrl_cpw_wr_data_i}),
      .douta({ctrl_cpw_rd_data_q, ctrl_cpw_rd_data_i}),
      //
      .clkb (clk),
      .rstb (~cpw_rd_en),
      .enb  (cpw_rd_en),
      .web  (1'b0),
      .addrb(cpw_rd_addr),
      .dinb ('0),
      .doutb({cpw_rd_data_q, cpw_rd_data_i})
  );

  (* keep_hierarchy="yes" *)
  reg_pipeline #(
      .DATA_WIDTH     (DATA_WIDTH * 2),
      .PIPELINE_STAGES(2)
  ) i_delay (
      .clk (clk),
      .din ({state_q, state_i}),
      .dout({state_q_d, state_i_d})
  );

  (* keep_hierarchy="yes" *)
  cmult #(
      .AWIDTH (DATA_WIDTH),
      .BWIDTH (DATA_WIDTH),
      .PWIDTH (DATA_WIDTH),
      .SRABITS(14)
  ) i_cmult (
      .clk(clk),
      .rst(rst),
      //
      .ar (state_i_d),
      .ai (state_q_d),
      //
      .br (cpw_rd_data_i),
      .bi (cpw_rd_data_q),
      //
      .pr (delta_i),
      .pi (delta_q),
      //
      .ovf(  /* Not Used */)
  );

  (* keep_hierarchy="yes" *)
  adder #(
      .A_WIDTH (DATA_WIDTH),
      .B_WIDTH (DATA_WIDTH),
      .P_WIDTH (DATA_WIDTH),
      .SRA_BITS(0)
  ) i_adder_i (
      .clk    (clk),
      .rst    (rst),
      .a      (data_i_in),
      .b      (delta_i),
      .add_sub(1'b1),
      .p      (data_i_out),
      .ovf    (  /* Not Used */)
  );

  (* keep_hierarchy="yes" *)
  adder #(
      .A_WIDTH (DATA_WIDTH),
      .B_WIDTH (DATA_WIDTH),
      .P_WIDTH (DATA_WIDTH),
      .SRA_BITS(0)
  ) i_adder_q (
      .clk    (clk),
      .rst    (rst),
      .a      (data_q_in),
      .b      (delta_q),
      .add_sub(1'b1),
      .p      (data_q_out),
      .ovf    (  /* Not Used */)
  );

endmodule

`default_nettype wire
