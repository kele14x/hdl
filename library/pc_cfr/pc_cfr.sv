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
    input var  logic                      ctrl_cpw_wr_en,
    input var  logic [CPW_ADDR_WIDTH-1:0] ctrl_cpw_wr_addr,
    input var  logic [    DATA_WIDTH-1:0] ctrl_cpw_wr_data_i,
    input var  logic [    DATA_WIDTH-1:0] ctrl_cpw_wr_data_q
);


  localparam int Iterations = 7;
  localparam int DataPathLatency = 16 + 10 + 4 + 10;

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

  // Up-sample by 2?
  // 16 clock tick impulse latency

  (* keep_hierarchy="yes" *)
  hb_up2_int2 #(
      .XIN_WIDTH     (DATA_WIDTH),
      .COE_WIDTH     (16),
      .NUM_UNIQUE_COE(5),
      .COE_NUMS      ({952, -1609, 3090, -6260, 20622}),
      .YOUT_WIDTH    (DATA_WIDTH),
      .SRA_BITS      (15)
  ) i_up2_i (
      .clk  (clk),
      .rst  (rst),
      .xin  (data_i_in),
      .yout0(data_i_p0),
      .yout1(data_i_p1),
      .ovf  (  /* Not used */)
  );

  (* keep_hierarchy="yes" *)
  hb_up2_int2 #(
      .XIN_WIDTH     (DATA_WIDTH),
      .COE_WIDTH     (16),
      .NUM_UNIQUE_COE(5),
      .COE_NUMS      ({952, -1609, 3090, -6260, 20622}),
      .YOUT_WIDTH    (DATA_WIDTH),
      .SRA_BITS      (15)
  ) i_up2_q (
      .clk  (clk),
      .rst  (rst),
      .xin  (data_q_in),
      .yout0(data_q_p0),
      .yout1(data_q_p1),
      .ovf  (  /* Not used */)
  );

  // Convert input data into "theta and r" format.
  // 10 clock tick latency

  (* keep_hierarchy="yes" *)
  cordic_cart2pol #(
      .DATA_WIDTH          (DATA_WIDTH),
      .CTRL_WIDTH          (1),
      .ITERATIONS          (Iterations),
      .COMPENSATION_SCALING(1)
  ) i_cordic_cart2pol_p0 (
      .clk     (clk),
      .rst     (rst),
      //
      .xin     (data_i_p0),
      .yin     (data_q_p0),
      .ctrl_in (1'b0),
      //
      .theta   (data_theta_p0),
      .r       (data_r_p0),
      .ctrl_out(/* Not used */)
  );

  (* keep_hierarchy="yes" *)
  cordic_cart2pol #(
      .DATA_WIDTH          (DATA_WIDTH),
      .ITERATIONS          (Iterations),
      .COMPENSATION_SCALING(1)
  ) i_cordic_cart2pol_p1 (
      .clk     (clk),
      .rst     (rst),
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
  // 4 clock tick latency

  (* keep_hierarchy="yes" *)
  pc_cfr_pd #(
      .ITERATIONS(Iterations),
      .DATA_WIDTH(DATA_WIDTH)
  ) i_pc_cfr_pd (
      .clk                    (clk),
      .rst                    (rst),
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
      .ctrl_enable            (ctrl_enable),
      .ctrl_pd_threshold      (ctrl_pd_threshold),
      .ctrl_clipping_threshold(ctrl_clipping_threshold)
  );

  // Rotate the delta vector back to i & q
  // 10 clock tick latency

  (* keep_hierarchy="yes" *)
  cordic_pol2cart #(
      .DATA_WIDTH          (DATA_WIDTH + 1),
      .CTRL_WIDTH          (1),
      .ITERATIONS          (Iterations),
      .COMPENSATION_SCALING(1)
  ) i_cordic_pol2cart (
      .clk     (clk),
      .rst     (rst),
      //
      .r       (peak_r),
      .theta   (peak_theta),
      .ctrl_in (1'b0),
      //
      .xout    (peak_i),
      .yout    (peak_q),
      .ctrl_out(/* Not used */)
  );

  (* keep_hierarchy="yes" *)
  reg_pipeline #(
      .DATA_WIDTH     (2),
      .PIPELINE_STAGES(10)
  ) i_delay_peak (
      .clk (clk),
      .din ({peak_phase, peak_valid}),
      .dout({peak_phase_d, peak_valid_d})
  );

  // Delay input data for `DataPathLatency` clocks

  (* keep_hierarchy="yes" *)
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

  (* keep_hierarchy="yes" *)
  pc_cfr_softclipper #(
      .DATA_WIDTH    (DATA_WIDTH),
      .CPW_ADDR_WIDTH(CPW_ADDR_WIDTH),
      .NUM_CPG       (6)
  ) i_pc_cfr_softclipper (
      .clk               (clk),
      .rst               (rst),
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
      .ctrl_cpw_wr_en    (ctrl_cpw_wr_en),
      .ctrl_cpw_wr_addr  (ctrl_cpw_wr_addr),
      .ctrl_cpw_wr_data_i(ctrl_cpw_wr_data_i),
      .ctrl_cpw_wr_data_q(ctrl_cpw_wr_data_q)
  );

endmodule

`default_nettype wire
