// File: cfr_pc.sv
// Brief: cfr_pc performs PC-CFR on input signal.
//        Do not change parameters, they will not work.

`timescale 1 ns / 1 ps
`default_nettype none

module cfr_pc #(
    // Architecture parameters:
    // Clock to sample rate ratio (CSR), it impacts the interface
    // and internal signal processing. Valid value is 1,2. If 1, use
    // clock frequency same as input signal sampling rate. If 2, use 2x
    // clock frequency of input signal sampling rate. Then the interface
    // is 2 channel interleaved. That is CH1/CH2/CH1/CH2...
    parameter int CSR            = 2,
    // Up-sampling factor (UP_FACTOR). Valid range is 1, 2, 4. Internal
    // up-sampling factor (if > 1) performed on input signal.
    parameter int UP_FACTOR      = 2,
    // Data path parameters
    parameter int DATA_WIDTH     = 16,
    // Number of CPGs
    parameter int NUM_CPG        = 6,
    // Coefficient parameters
    parameter int CPW_ADDR_WIDTH = 9,
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
    input var  logic                      ctrl_enable,              // 1 = enable, 0 = bypass
    input var  logic [               3:0] ctrl_spacing,             // min spacing between peaks
    input var  logic [      DATA_WIDTH:0] ctrl_clipping_threshold,  // unsigned
    input var  logic [      DATA_WIDTH:0] ctrl_pd_threshold,        // unsigned
    // Cancellation pulse write port
    input var  logic [CPW_ADDR_WIDTH-1:0] ctrl_cpw_addr,
    input var  logic                      ctrl_cpw_en,
    input var  logic                      ctrl_cpw_we,
    input var  logic [    DATA_WIDTH-1:0] ctrl_cpw_wr_data_i,
    input var  logic [    DATA_WIDTH-1:0] ctrl_cpw_wr_data_q
);


  // CORDIC iteration stages
  localparam int Iterations = 7;
  // Data path latency
  // TODO: Calculate delay value based on parameters
  localparam int DataPathLatency = 12 + 10 + 35 + 10;

  localparam int PhaseWidth = $clog2(UP_FACTOR);


  logic                  local_rst;

  logic                  unused_cart2pol_ctrl[UP_FACTOR];
  logic                  unused_pol2cart_ctrl;
  logic [DATA_WIDTH-1:0] unused_peak_i_out;
  logic [DATA_WIDTH-1:0] unused_peak_q_out;
  logic [PhaseWidth-1:0] unused_peak_phase_out;
  logic                  unused_peak_valid_out;

  logic                  ctrl_enable_s;
  logic [           3:0] ctrl_spacing_s;
  logic [  DATA_WIDTH:0] ctrl_clipping_threshold_s;
  logic [  DATA_WIDTH:0] ctrl_pd_threshold_s;

  logic [DATA_WIDTH-1:0] data_up_i_px              [UP_FACTOR];
  logic [DATA_WIDTH-1:0] data_up_q_px              [UP_FACTOR];

  logic [DATA_WIDTH+1:0] data_r_px                 [UP_FACTOR];
  logic [  DATA_WIDTH:0] data_r_px_s               [UP_FACTOR];
  logic [  Iterations:0] data_theta_px             [UP_FACTOR];

  logic [  DATA_WIDTH:0] peak_r;
  logic [  Iterations:0] peak_theta;

  logic [DATA_WIDTH+2:0] peak_i;
  logic [DATA_WIDTH+2:0] peak_q;

  logic peak_valid, peak_valid_d;
  logic [PhaseWidth-1:0] peak_phase, peak_phase_d;

  wire unused_peak_truncated_bits = &{1'b0, peak_i[DATA_WIDTH+2:DATA_WIDTH],
                                     peak_q[DATA_WIDTH+2:DATA_WIDTH], 1'b0};

  logic [DATA_WIDTH-1:0] data_i_in_d;
  logic [DATA_WIDTH-1:0] data_q_in_d;


  // Parameter checking
  initial begin
    if (CSR != 1 && CSR != 2) begin
      $display("ERROR: cfr_pc: Invalid CSR value %d", CSR);
      $finish;
    end
    if (UP_FACTOR != 1 && UP_FACTOR != 2 && UP_FACTOR != 4) begin
      $display("ERROR: cfr_pc: Invalid UP_FACTOR value %d", UP_FACTOR);
      $finish;
    end
    if (CPW_DATA_WIDTH != DATA_WIDTH) begin
      $display("ERROR: cfr_pc: CPW_DATA_WIDTH (%d) must match DATA_WIDTH (%d)", CPW_DATA_WIDTH,
               DATA_WIDTH);
      $finish;
    end
  end


  // Ctrl interface CDC

  cdc_array_single #(
      .DEST_SYNC_FF  (2),
      .INIT_SYNC_FF  (0),
      .SRC_INPUT_REG (0),
      .WIDTH         (1)
  ) i_cdc_array_single_ctrl_enable (
      .src_clk (1'b0),
      .src_in  (ctrl_enable),
      .dest_clk(clk),
      .dest_out(ctrl_enable_s)
  );

  cdc_array_single #(
      .DEST_SYNC_FF  (2),
      .INIT_SYNC_FF  (0),
      .SRC_INPUT_REG (0),
      .WIDTH         (4)
  ) i_cdc_array_single_ctrl_spacing (
      .src_clk (1'b0),
      .src_in  (ctrl_spacing),
      .dest_clk(clk),
      .dest_out(ctrl_spacing_s)
  );

  cdc_array_single #(
      .DEST_SYNC_FF  (2),
      .INIT_SYNC_FF  (0),
      .SRC_INPUT_REG (0),
      .WIDTH         (DATA_WIDTH + 1)
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
      .WIDTH        (DATA_WIDTH + 1)
  ) i_cdc_array_single_ctrl_pd_threshold (
      .src_clk (1'b0),
      .src_in  (ctrl_pd_threshold),
      .dest_clk(clk),
      .dest_out(ctrl_pd_threshold_s)
  );

  // Reset CDC

  cdc_async_rst #(
      .DEST_SYNC_FF   (4),
      .INIT_SYNC_FF   (0),
      .RST_ACTIVE_HIGH(1)
  ) i_cdc_async_rst_sync (
      .dest_clk (clk),
      .src_arst (rst),
      .dest_arst(local_rst)
  );


  // Up-sampler

  cfr_pc_upx #(
      // Architecture parameters
      .CSR       (CSR),
      .UP_FACTOR (UP_FACTOR),
      // Data path parameters
      .DATA_WIDTH(DATA_WIDTH)
  ) i_cfr_pc_upx (
      // Data interface
      .clk       (clk),
      .rst       (rst),
      // Data input
      .data_i_in (data_i_in),
      .data_q_in (data_q_in),
      // Data output
      .data_i_out(data_up_i_px),
      .data_q_out(data_up_q_px)
  );


  // CORDIC
  // Convert input data into "theta and r" format.
  // 10 clock tick latency

  generate
    for (genvar pp = 0; pp < UP_FACTOR; pp++) begin : g_cordic_p

      cordic_cart2pol #(
          .DATA_WIDTH          (DATA_WIDTH),
          .CTRL_WIDTH          (1),
          .ITERATIONS          (Iterations),
          .COMPENSATION_SCALING(1)
      ) i_cordic_cart2pol (
          .clk     (clk),
          .rst     (local_rst),
          //
          .xin     (data_up_i_px[pp]),
          .yin     (data_up_q_px[pp]),
          .ctrl_in (1'b0),
          //
          .r       (data_r_px[pp]),
          .theta   (data_theta_px[pp]),
          .ctrl_out(unused_cart2pol_ctrl[pp])
      );

      // Truncate 1 MSB
      assign data_r_px_s[pp] = data_r_px[pp][DATA_WIDTH:0];

    end
  endgenerate


  // Peak detector,
  // 19 clock tick latency

  cfr_pc_pd #(
      .CSR       (CSR),
      .UP_FACTOR (UP_FACTOR),
      //
      .ITERATIONS(Iterations),
      .DATA_WIDTH(DATA_WIDTH)
  ) i_cfr_pc_pd (
      .clk                    (clk),
      .rst                    (local_rst),
      //
      .data_r_px              (data_r_px_s),
      .data_theta_px          (data_theta_px),
      //
      .peak_r                 (peak_r),
      .peak_theta             (peak_theta),
      .peak_valid             (peak_valid),
      .peak_phase             (peak_phase),
      //
      .ctrl_enable            (ctrl_enable_s),
      .ctrl_spacing           (ctrl_spacing_s),
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
      .ctrl_out(unused_pol2cart_ctrl)
  );

  delay #(
      .WIDTH(PhaseWidth + 1),
      .DEPTH(10),
      .INIT (1'b0)
  ) i_delay_peak (
      .clk (clk),
      .rst (1'b0),
      .cen (1'b1),
      .din ({peak_phase, peak_valid}),
      .dout({peak_phase_d, peak_valid_d})
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

  // Soft clipper
  // 143 clock tick latency

  cfr_pc_softclipper #(
      .CSR           (CSR),
      .PHASE_WIDTH   (PhaseWidth),
      .DATA_WIDTH    (DATA_WIDTH),
      .NUM_CPG       (NUM_CPG),
      .CPW_ADDR_WIDTH(CPW_ADDR_WIDTH)
  ) i_cfr_pc_softclipper (
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
      .peak_i_out        (unused_peak_i_out),
      .peak_q_out        (unused_peak_q_out),
      .peak_phase_out    (unused_peak_phase_out),
      .peak_valid_out    (unused_peak_valid_out),
      //
      .ctrl_clk          (ctrl_clk),
      .ctrl_rst          (ctrl_rst),
      //
      .ctrl_cpw_addr     (ctrl_cpw_addr),
      .ctrl_cpw_en       (ctrl_cpw_en),
      .ctrl_cpw_we       (ctrl_cpw_we),
      .ctrl_cpw_wr_data_i(ctrl_cpw_wr_data_i),
      .ctrl_cpw_wr_data_q(ctrl_cpw_wr_data_q)
  );

endmodule

`default_nettype wire
