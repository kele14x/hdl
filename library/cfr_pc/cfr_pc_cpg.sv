// File: cfr_pc_cpg.sv
// Brief: cfr_pc_cpg is Canceling Pulse Generator (CPG) for PC-CFR. It' designed
//        as cascade-able.

`timescale 1ns / 1ps `default_nettype none

module cfr_pc_cpg #(
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
    input var  logic        [    DATA_WIDTH-1:0] ctrl_cpw_wr_data_i,
    input var  logic        [    DATA_WIDTH-1:0] ctrl_cpw_wr_data_q
);


  // BRAM read port
  logic                             cpw_rd_en;
  logic        [CPW_ADDR_WIDTH-1:0] cpw_rd_addr;
  logic signed [    DATA_WIDTH-1:0] cpw_rd_data_i;
  logic signed [    DATA_WIDTH-1:0] cpw_rd_data_q;

  logic signed [    DATA_WIDTH-1:0] cpw_rd_data_i_d;
  logic signed [    DATA_WIDTH-1:0] cpw_rd_data_q_d;

  // State of CPG stage

  logic                             state_busy;
  logic        [CPW_ADDR_WIDTH-2:0] state_addr;
  logic                             state_phase = '0;
  logic [DATA_WIDTH-1:0] state_i = '0, state_q = '0;
  logic [DATA_WIDTH-1:0] state_i_d, state_q_d;

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

  // `state_addr` will move from 0 to 'hFF
  always_ff @(posedge clk) begin
    state_addr <= state_busy ? state_addr + 1 : '0;
  end

  // `state_phase` is phase of peak
  always_ff @(posedge clk) begin
    if (peak_valid_in && ~state_busy) begin
      state_phase <=  peak_phase_in;
    end
  end

  // `state_i/q` is i/q value of peak
  always_ff @(posedge clk) begin
    if (peak_valid_in && ~state_busy) begin
      {state_q, state_i} <= {peak_q_in, peak_i_in};
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
    end
  end

  assign cpw_rd_en   = state_busy;
  assign cpw_rd_addr = {state_addr, ~state_phase};

  bram_sdp_pipe #(
      .ADDR_WIDTH  (CPW_ADDR_WIDTH),
      .DATA_WIDTH  (DATA_WIDTH * 2),
      .READ_LATENCY(2),
      .INIT_FILE   ("")
  ) i_bram_sdp_pipe (
      //
      .clka (ctrl_clk),
      .ena  (ctrl_cpw_en),
      .wea  (ctrl_cpw_we),
      .addra(ctrl_cpw_addr),
      .dina ({ctrl_cpw_wr_data_q, ctrl_cpw_wr_data_i}),
      //
      .clkb (clk),
      .rstb (~cpw_rd_en),
      .enb  (cpw_rd_en),
      .addrb(cpw_rd_addr),
      .doutb({cpw_rd_data_q, cpw_rd_data_i})
  );

  reg_pipeline #(
      .DATA_WIDTH     (DATA_WIDTH * 2),
      .PIPELINE_STAGES(3)
  ) i_delay_state_iq (
      .clk (clk),
      .din ({state_q, state_i}),
      .dout({state_q_d, state_i_d})
  );

  reg_pipeline #(
      .DATA_WIDTH     (DATA_WIDTH * 2),
      .PIPELINE_STAGES(1)
  ) i_delay_cpw_rd_data_iq (
      .clk (clk),
      .din ({cpw_rd_data_q, cpw_rd_data_i}),
      .dout({cpw_rd_data_q_d, cpw_rd_data_i_d})
  );

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
      .br (cpw_rd_data_i_d),
      .bi (cpw_rd_data_q_d),
      //
      .pr (delta_i),
      .pi (delta_q),
      //
      .ovf(  /* Not Used */)
  );

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
