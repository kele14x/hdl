// File: cfr_hardclipping.sv
// Brief: cfr_hardclipping performs brick-wall dynamic range limiting to input.
//        Dynamic range limiting suppresses the signal that cross the given
//        threshold. Those signal are hard clipped without maintains the
//        spectrum.

`timescale 1 ns / 1 ps `default_nettype none

module cfr_hardclipping #(
    parameter int DATA_WIDTH = 16
) (
    input var  logic                  clk,
    input var  logic                  rst,
    // Data input
    input var  logic [DATA_WIDTH-1:0] data_i_in,
    input var  logic [DATA_WIDTH-1:0] data_q_in,
    // Data output
    output var logic [DATA_WIDTH-1:0] data_i_out,
    output var logic [DATA_WIDTH-1:0] data_q_out,
    // Control
    input var  logic                  ctrl_enable,  // 1 = enable, 0 = bypass
    input var  logic [  DATA_WIDTH:0] ctrl_threshold  // unsigned
);


  localparam int Iterations = 7;
  localparam int DataPathLatency = Iterations * 2 + 8;
  localparam int Latency = DataPathLatency + 1;

  logic local_rst;

  logic                         ctrl_enable_s;
  logic        [  DATA_WIDTH:0] ctrl_threshold_s;

  logic signed [DATA_WIDTH-1:0] data_i_in_d;
  logic signed [DATA_WIDTH-1:0] data_q_in_d;

  logic        [  Iterations:0] data_theta;
  logic signed [DATA_WIDTH+1:0] data_r;

  logic        [  Iterations:0] delta_theta_0;
  logic signed [DATA_WIDTH+1:0] delta_r_0;

  logic        [  Iterations:0] delta_theta;
  logic signed [DATA_WIDTH+1:0] delta_r;

  logic signed [DATA_WIDTH+2:0] delta_i;
  logic signed [DATA_WIDTH+2:0] delta_q;


  // CTRL CDC

  xpm_cdc_array_single #(
    .DEST_SYNC_FF  (2),
    .INIT_SYNC_FF  (0),
    .SIM_ASSERT_CHK(0),
    .SRC_INPUT_REG (0),
    .WIDTH         (1)
  ) i_cdc_array_single_ctrl_enable (
    .src_clk (1'b0),
    .src_in  (ctrl_enable),
    .dest_clk(clk),
    .dest_out(ctrl_enable_s)
  );

  xpm_cdc_array_single #(
    .DEST_SYNC_FF  (2),
    .INIT_SYNC_FF  (0),
    .SIM_ASSERT_CHK(0),
    .SRC_INPUT_REG (0),
    .WIDTH         (DATA_WIDTH + 1)
  ) i_cdc_array_single_ctrl_threshold (
    .src_clk (1'b0),
    .src_in  (ctrl_threshold),
    .dest_clk(clk),
    .dest_out(ctrl_threshold_s)
  );

  // Reset CDC

  xpm_cdc_async_rst #(
      .DEST_SYNC_FF   (4),
      .INIT_SYNC_FF   (0),
      .RST_ACTIVE_HIGH(1)
  ) i_cdc_sync_rst (
      .src_arst (rst),
      .dest_clk (clk),
      .dest_arst(local_rst)
  );

  // Delay input data for `DataPathLatency` clocks

  delay #(
      .WIDTH(DATA_WIDTH * 2),
      .DEPTH(DataPathLatency),
      .INIT (1'b0)
  ) i_delay (
      .clk (clk),
      .rst (1'b0),
      .cen (1'b1),
      .din ({data_q_in, data_i_in}),
      .dout({data_q_in_d, data_i_in_d})
  );

  // Convert input data into "theta and r" format

  cordic_cart2pol #(
      .DATA_WIDTH          (DATA_WIDTH),
      .ITERATIONS          (Iterations),
      .COMPENSATION_SCALING(1),
      .CTRL_WIDTH          (1)
  ) i_cordic_cart2pol (
      .clk     (clk),
      .rst     (local_rst),
      //
      .xin     (data_i_in),
      .yin     (data_q_in),
      .ctrl_in (1'b0),
      //
      .theta   (data_theta),
      .r       (data_r),
      .ctrl_out(/* Not used */)
  );

  // Test if amplitude exceeds threshold

  always_ff @(posedge clk) begin
    delta_theta_0 <= data_theta;
    delta_r_0     <= data_r - ctrl_threshold_s;
  end

  always_ff @(posedge clk) begin
    delta_theta <= delta_theta_0;
    if (ctrl_enable_s) begin
      delta_r <= (delta_r_0 >= 0) ? delta_r_0 : 'd0;
    end else begin
      delta_r <= 'd0;
    end
  end

  // Rotate the delta vector back to i & q

  cordic_pol2cart #(
      .DATA_WIDTH          (DATA_WIDTH + 1),
      .ITERATIONS          (Iterations),
      .COMPENSATION_SCALING(1)
  ) i_cordic_pol2cart (
      .clk     (clk),
      .rst     (local_rst),
      //
      .r       (delta_r[DATA_WIDTH:0]),
      .theta   (delta_theta),
      .ctrl_in (1'b0),
      //
      .xout    (delta_i),
      .yout    (delta_q),
      .ctrl_out(/* Not used */)
  );

  // Output signal is delayed original signal subtract delta

  adder #(
      .A_WIDTH (DATA_WIDTH),
      .B_WIDTH (DATA_WIDTH),
      .P_WIDTH (DATA_WIDTH),
      .SRA_BITS(0)
  ) i_adder_i (
      .clk    (clk),
      .rst    (local_rst),
      .a      (data_i_in_d),
      .b      (delta_i[DATA_WIDTH-1:0]),
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
      .rst    (local_rst),
      .a      (data_q_in_d),
      .b      (delta_q[DATA_WIDTH-1:0]),
      .add_sub(1'b1),
      .p      (data_q_out),
      .ovf    (  /* Not Used */)
  );

endmodule

`default_nettype wire
