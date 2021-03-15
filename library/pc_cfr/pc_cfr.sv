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

// File: pc_cfr.sv
// Brief: pc_cfr performs PC-CFR on input signal. This module is designed with
//        clock to sample rate ratio (CSR) = 2, and interface is 2 channel
//        interleaved. That is CH1/CH2/CH1/CH2...

`timescale 1ns / 1ps `default_nettype none

module pc_cfr #(
    parameter int DATA_WIDTH     = 16,
    //
    parameter int CPW_ADDR_WIDTH = 8 ,
    parameter int CPW_DATA_WIDTH = 16
) (
    // Data Interface
    //---------------
    input var  logic                      clk,
    input var  logic                      rst,
    // Data input
    input var  logic [    DATA_WIDTH-1:0] data_i_in,
    input var  logic [    DATA_WIDTH-1:0] data_q_in,
    // Data output
    output var logic [    DATA_WIDTH-1:0] data_i_out,
    output var logic [    DATA_WIDTH-1:0] data_q_out,
    // Control Interface
    //------------------
    input var  logic                      ctrl_clk,
    input var  logic                      ctrl_rst,
    // Scalar
    input var  logic                      ctrl_enable,  // 1 = enable, 0 = bypass
    input var  logic [      DATA_WIDTH:0] ctrl_clipping_threshold,  // unsigned
    input var  logic [      DATA_WIDTH:0] ctrl_pd_threshold,  // unsigned
    // Cancellation pulse write port
    input var  logic [CPW_ADDR_WIDTH-1:0] ctrl_cpw_addr,
    input var  logic                      ctrl_cpw_en,
    input var  logic                      ctrl_cpw_we,
    output var logic [    DATA_WIDTH-1:0] ctrl_cpw_rd_data_i,
    output var logic [    DATA_WIDTH-1:0] ctrl_cpw_rd_data_q,
    input var  logic [    DATA_WIDTH-1:0] ctrl_cpw_wr_data_i,
    input var  logic [    DATA_WIDTH-1:0] ctrl_cpw_wr_data_q
);


  localparam int Iterations = 7;
  localparam int DataPathLatency = 9 + 10 + 3 + 10;

  logic local_rst;

  logic                      ctrl_enable_s;
  logic [      DATA_WIDTH:0] ctrl_clipping_threshold_s;
  logic [      DATA_WIDTH:0] ctrl_pd_threshold_s;

  logic signed [DATA_WIDTH-1:0] data_i_p0;
  logic signed [DATA_WIDTH-1:0] data_i_p1;
  logic signed [DATA_WIDTH-1:0] data_q_p0;
  logic signed [DATA_WIDTH-1:0] data_q_p1;

  logic        [  Iterations:0] data_theta_p0;
  logic signed [DATA_WIDTH+1:0] data_r_p0;

  logic        [  Iterations:0] data_theta_p1;
  logic signed [DATA_WIDTH+1:0] data_r_p1;

  logic        [  Iterations:0] peak_theta;
  logic signed [  DATA_WIDTH:0] peak_r;

  logic signed [DATA_WIDTH+2:0] peak_i;
  logic signed [DATA_WIDTH+2:0] peak_q;

  logic peak_valid, peak_valid_d;
  logic peak_phase, peak_phase_d;

  logic signed [DATA_WIDTH-1:0] data_i_in_d;
  logic signed [DATA_WIDTH-1:0] data_q_in_d;

  // Ctrl interface CDC

  cdc_array_single #(
    .DEST_SYNC_FF (2),
    .INIT_SYNC_FF (0),
    .SRC_INPUT_REG(0),
    .WIDTH        (1)
  ) i_cdc_array_single_ctrl_enable (
    .src_clk (1'b0),
    .src_in  (ctrl_enable),
    .dest_clk(clk),
    .dest_out(ctrl_enable_s)
  );

  cdc_array_single #(
    .DEST_SYNC_FF (2),
    .INIT_SYNC_FF (0),
    .SRC_INPUT_REG(0),
    .WIDTH        (DATA_WIDTH+1)
  ) i_cdc_array_single_ctrl_clipping_threshold (
    .src_clk (1'b0),
    .src_in  (ctrl_clipping_threshold),
    .dest_clk(clk),
    .dest_out(ctrl_clipping_threshold_s)
  );

  cdc_array_single #(
    .DEST_SYNC_FF (2),
    .INIT_SYNC_FF (0),
    .SRC_INPUT_REG(0),
    .WIDTH        (DATA_WIDTH+1)
  ) i_cdc_array_single_ctrl_pd_threshold (
    .src_clk (1'b0),
    .src_in  (ctrl_pd_threshold),
    .dest_clk(clk),
    .dest_out(ctrl_pd_threshold_s)
  );

  // Reset CDC

  cdc_async_rst_sync #(
      .SYNC_FF(4),
      .RST_ACTIVE_HIGH(1)
  ) i_cdc_async_rst_sync (
      .clk(clk),
      .async_rst_in(rst),
      .sync_rst_out(local_rst)
  );

  // Up-sample by 2?
  // 9 clock tick impulse latency

  hb_up2 #(
      .XIN_WIDTH     (DATA_WIDTH),
      .COE_WIDTH     (16),
      .NUM_UNIQUE_COE(3),
      .COE_NUMS      ({1277, -4710, 20014}),
      .YOUT_WIDTH    (DATA_WIDTH),
      .SRA_BITS      (15)
  ) i_up2_i (
      .clk  (clk),
      .rst  (local_rst),
      .xin  (data_i_in),
      .yout0(data_i_p0),
      .yout1(data_i_p1),
      .ovf  (  /* Not used */)
  );

  hb_up2 #(
      .XIN_WIDTH     (DATA_WIDTH),
      .COE_WIDTH     (16),
      .NUM_UNIQUE_COE(3),
      .COE_NUMS      ({1277, -4710, 20014}),
      .YOUT_WIDTH    (DATA_WIDTH),
      .SRA_BITS      (15)
  ) i_up2_q (
      .clk  (clk),
      .rst  (local_rst),
      .xin  (data_q_in),
      .yout0(data_q_p0),
      .yout1(data_q_p1),
      .ovf  (  /* Not used */)
  );

  // Convert input data into "theta and r" format.
  // 10 clock tick latency

  cordic_cart2pol #(
      .DATA_WIDTH          (DATA_WIDTH),
      .CTRL_WIDTH          (1),
      .ITERATIONS          (Iterations),
      .COMPENSATION_SCALING(1)
  ) i_cordic_cart2pol_p0 (
      .clk     (clk),
      .rst     (local_rst),
      //
      .xin     (data_i_p0),
      .yin     (data_q_p0),
      .ctrl_in (1'b0),
      //
      .theta   (data_theta_p0),
      .r       (data_r_p0),
      .ctrl_out(/* Not used */)
  );

  cordic_cart2pol #(
      .DATA_WIDTH          (DATA_WIDTH),
      .ITERATIONS          (Iterations),
      .COMPENSATION_SCALING(1)
  ) i_cordic_cart2pol_p1 (
      .clk     (clk),
      .rst     (local_rst),
      //
      .xin     (data_i_p1),
      .yin     (data_q_p1),
      .ctrl_in (1'b0),
      //
      .theta   (data_theta_p1),
      .r       (data_r_p1),
      .ctrl_out(/* Not used */)
  );

  // Peak detector,
  // 3 clock tick latency

  pc_cfr_pd #(
      .ITERATIONS(Iterations),
      .DATA_WIDTH(DATA_WIDTH)
  ) i_pc_cfr_pd (
      .clk                    (clk),
      .rst                    (local_rst),
      //
      .data_r_p0              (data_r_p0[DATA_WIDTH:0]),
      .data_r_p1              (data_r_p1[DATA_WIDTH:0]),
      .data_theta_p0          (data_theta_p0),
      .data_theta_p1          (data_theta_p1),
      //
      .peak_theta             (peak_theta),
      .peak_r                 (peak_r),
      .peak_valid             (peak_valid),
      .peak_phase             (peak_phase),
      //
      .ctrl_enable            (ctrl_enable_s),
      .ctrl_pd_threshold      (ctrl_pd_threshold_s),
      .ctrl_clipping_threshold(ctrl_clipping_threshold_s)
  );

  // Rotate the delta vector back to i & q
  // 10 clock tick latency

  cordic_pol2cart #(
      .DATA_WIDTH          (DATA_WIDTH + 1),
      .CTRL_WIDTH          (1),
      .ITERATIONS          (Iterations),
      .COMPENSATION_SCALING(1)
  ) i_cordic_pol2cart (
      .clk     (clk),
      .rst     (local_rst),
      //
      .r       (peak_r),
      .theta   (peak_theta),
      .ctrl_in (1'b0),
      //
      .xout    (peak_i),
      .yout    (peak_q),
      .ctrl_out(/* Not used */)
  );

  reg_pipeline #(
      .DATA_WIDTH     (2),
      .PIPELINE_STAGES(10)
  ) i_delay_peak (
      .clk (clk),
      .din ({peak_phase, peak_valid}),
      .dout({peak_phase_d, peak_valid_d})
  );

  // Delay input data for `DataPathLatency` clocks

  reg_pipeline #(
      .DATA_WIDTH     (DATA_WIDTH * 2),
      .PIPELINE_STAGES(DataPathLatency)
  ) i_delay (
      .clk (clk),
      .din ({data_q_in, data_i_in}),
      .dout({data_q_in_d, data_i_in_d})
  );

  // Soft clipper
  // 142 clock tick latency

  pc_cfr_softclipper #(
      .DATA_WIDTH    (DATA_WIDTH),
      .CPW_ADDR_WIDTH(CPW_ADDR_WIDTH),
      .NUM_CPG       (6)
  ) i_pc_cfr_softclipper (
      .clk               (clk),
      .rst               (local_rst),
      //
      .data_i_in         (data_i_in_d),
      .data_q_in         (data_q_in_d),
      //
      .peak_i_in         (peak_i[DATA_WIDTH-1:0]),
      .peak_q_in         (peak_q[DATA_WIDTH-1:0]),
      .peak_phase_in     (peak_phase_d),
      .peak_valid_in     (peak_valid_d),
      //
      .data_i_out        (data_i_out),
      .data_q_out        (data_q_out),
      //
      .peak_i_out        (  /* Not used */),
      .peak_q_out        (  /* Not used */),
      .peak_phase_out    (  /* Not used */),
      .peak_valid_out    (  /* Not used */),
      //
      .ctrl_clk          (ctrl_clk),
      .ctrl_rst          (ctrl_rst),
      //
      .ctrl_cpw_addr     (ctrl_cpw_addr),
      .ctrl_cpw_en       (ctrl_cpw_en),
      .ctrl_cpw_we       (ctrl_cpw_we),
      .ctrl_cpw_rd_data_i(ctrl_cpw_rd_data_i),
      .ctrl_cpw_rd_data_q(ctrl_cpw_rd_data_q),
      .ctrl_cpw_wr_data_i(ctrl_cpw_wr_data_i),
      .ctrl_cpw_wr_data_q(ctrl_cpw_wr_data_q)
  );

endmodule

`default_nettype wire
