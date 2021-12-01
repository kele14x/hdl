// File: cfr_pc.sv
// Brief: cfr_pc performs PC-CFR on input signal.
//        To integrate this module into your design, first select architecture
//        related parameters, including:
//
//          - Clock to sample rate ratio (CSR), it impacts the interface
//            and internal signal processing. Valid value is 1,2. If 1, use
//            clock frequency same as input signal sampling rate. If 2, use 2x
//            clock frequency of input signal sampling rate. Then the interface
//            is 2 channel interleaved. That is CH1/CH2/CH1/CH2...
//          - Up-sampling factor (UP_FACTOR). Valid range is 1, 2, 4. Internal
//            up-sampling factor (if > 1) performed on input signal.
//
//        Do not change other parameters.

`timescale 1ns / 1ps `default_nettype none

module cfr_pc #(
    // Architecture parameters
    parameter int CSR            = 2,
    parameter int UP_FACTOR      = 2,
    // Data path parameters
    parameter int DATA_WIDTH     = 16,
    // Coefficient parameters
    parameter int CPW_ADDR_WIDTH = 8,
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
  // TODO:
  localparam int DataPathLatency = CSR == 1 ? 9 + 10 + 19 + 10 :
                                   16 + 6 + 10 + 4 +10;

  logic                         local_rst;

  logic                         ctrl_enable_s;
  logic        [           3:0] ctrl_spacing_s;
  logic        [  DATA_WIDTH:0] ctrl_clipping_threshold_s;
  logic        [  DATA_WIDTH:0] ctrl_pd_threshold_s;

  logic signed [DATA_WIDTH-1:0] data_up2_i_p0;
  logic signed [DATA_WIDTH-1:0] data_up2_i_p1;
  logic signed [DATA_WIDTH-1:0] data_up2_q_p0;
  logic signed [DATA_WIDTH-1:0] data_up2_q_p1;

  logic signed [DATA_WIDTH-1:0] data_up4_i_p0;
  logic signed [DATA_WIDTH-1:0] data_up4_i_p1;
  logic signed [DATA_WIDTH-1:0] data_up4_i_p2;
  logic signed [DATA_WIDTH-1:0] data_up4_i_p3;
  logic signed [DATA_WIDTH-1:0] data_up4_q_p0;
  logic signed [DATA_WIDTH-1:0] data_up4_q_p1;
  logic signed [DATA_WIDTH-1:0] data_up4_q_p2;
  logic signed [DATA_WIDTH-1:0] data_up4_q_p3;

  logic signed [DATA_WIDTH-1:0] data_up_i_px [UP_FACTOR];
  logic signed [DATA_WIDTH-1:0] data_up_q_px [UP_FACTOR];

  logic signed [DATA_WIDTH+1:0] data_r_px     [UP_FACTOR];
  logic        [  Iterations:0] data_theta_px [UP_FACTOR];

  logic        [DATA_WIDTH:0] peak_r;
  logic        [Iterations:0] peak_theta;
  
  logic signed [DATA_WIDTH+2:0] peak_i;
  logic signed [DATA_WIDTH+2:0] peak_q;

  logic       peak_valid, peak_valid_d;
  logic [1:0] peak_phase, peak_phase_d;

  logic signed [DATA_WIDTH-1:0] data_i_in_d;
  logic signed [DATA_WIDTH-1:0] data_q_in_d;


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
  end


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
      .WIDTH        (4)
  ) i_cdc_array_single_ctrl_spacing (
      .src_clk (1'b0),
      .src_in  (ctrl_spacing),
      .dest_clk(clk),
      .dest_out(ctrl_spacing_s)
  );

  cdc_array_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (0),
      .SRC_INPUT_REG(0),
      .WIDTH        (DATA_WIDTH + 1)
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

  cdc_async_rst_sync #(
      .SYNC_FF        (4),
      .RST_ACTIVE_HIGH(1)
  ) i_cdc_async_rst_sync (
      .clk         (clk),
      .async_rst_in(rst),
      .sync_rst_out(local_rst)
  );


  // TODO: absorb the logic into HB_UP2 module

  // Up-sample original => 2x
  generate
    if (UP_FACTOR >= 2) begin: g_up2
      if (CSR == 1) begin: g_csr1_up2

        // Up-sample by 2
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
            .yout0(data_up2_i_p0),
            .yout1(data_up2_i_p1),
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
            .yout0(data_up2_q_p0),
            .yout1(data_up2_q_p1),
            .ovf  (  /* Not used */)
        );

      end else begin: g_csr2_up2

        // Up-sample by 2
        // 16 clock tick impulse latency

        hb_up2_int2 #(
            .XIN_WIDTH     (DATA_WIDTH),
            .COE_WIDTH     (16),
            .NUM_UNIQUE_COE(5),
            .COE_NUMS      ({952, -1609, 3090, -6260, 20622}),
            .YOUT_WIDTH    (DATA_WIDTH),
            .SRA_BITS      (15)
        ) i_up2_i (
            .clk  (clk),
            .rst  (local_rst),
            .xin  (data_i_in),
            .yout0(data_up2_i_p0),
            .yout1(data_up2_i_p1),
            .ovf  (  /* Not used */)
        );

        hb_up2_int2 #(
            .XIN_WIDTH     (DATA_WIDTH),
            .COE_WIDTH     (16),
            .NUM_UNIQUE_COE(5),
            .COE_NUMS      ({952, -1609, 3090, -6260, 20622}),
            .YOUT_WIDTH    (DATA_WIDTH),
            .SRA_BITS      (15)
        ) i_up2_q (
            .clk  (clk),
            .rst  (local_rst),
            .xin  (data_q_in),
            .yout0(data_up2_q_p0),
            .yout1(data_up2_q_p1),
            .ovf  (  /* Not used */)
        );

      end // CSR switch
    end // UP_FACTOR switch
  endgenerate


  // Up-sample 2x => 4x
  generate
    if (UP_FACTOR >= 4) begin: g_up4

      if (CSR == 1) begin: g_csr1_up4

        // Up-sample by 2 again
        // ?? clock tick impulse latency
        // TODO: may not exist

        hb_up2_p2 #(
            .XIN_WIDTH     (DATA_WIDTH),
            .COE_WIDTH     (16),
            .NUM_UNIQUE_COE(2),
            .COE_NUMS      ({-2788, 19030}),
            .YOUT_WIDTH    (DATA_WIDTH),
            .SRA_BITS      (15)
        ) i_up2_2_i (
            .clk  (clk),
            .rst  (local_rst),
            .xin0 (data_up2_i_p0),
            .xin1 (data_up2_i_p1),
            .yout0(data_up4_i_p0),
            .yout1(data_up4_i_p1),
            .yout2(data_up4_i_p2),
            .yout3(data_up4_i_p3),
            .ovf  (  /* Not used */)
        );

        hb_up2_p2 #(
            .XIN_WIDTH     (DATA_WIDTH),
            .COE_WIDTH     (16),
            .NUM_UNIQUE_COE(2),
            .COE_NUMS      ({-2788, 19030}),
            .YOUT_WIDTH    (DATA_WIDTH),
            .SRA_BITS      (15)
        ) i_up2_2_q (
            .clk  (clk),
            .rst  (local_rst),
            .xin0 (data_up2_q_p0),
            .xin1 (data_up2_q_p1),
            .yout0(data_up4_q_p0),
            .yout1(data_up4_q_p1),
            .yout2(data_up4_q_p2),
            .yout3(data_up4_q_p3),
            .ovf  (  /* Not used */)
        );

      end else begin: g_csr2_up4

        // Up-sample by 2 again
        // 6 clock tick impulse latency

        hb_up2_int2_p2 #(
            .XIN_WIDTH     (DATA_WIDTH),
            .COE_WIDTH     (16),
            .NUM_UNIQUE_COE(2),
            .COE_NUMS      ({-2788, 19030}),
            .YOUT_WIDTH    (DATA_WIDTH),
            .SRA_BITS      (15)
        ) i_up2_2_i (
            .clk  (clk),
            .rst  (local_rst),
            .xin0 (data_up2_i_p0),
            .xin1 (data_up2_i_p1),
            .yout0(data_up4_i_p0),
            .yout1(data_up4_i_p1),
            .yout2(data_up4_i_p2),
            .yout3(data_up4_i_p3),
            .ovf  (  /* Not used */)
        );

        hb_up2_int2_p2 #(
            .XIN_WIDTH     (DATA_WIDTH),
            .COE_WIDTH     (16),
            .NUM_UNIQUE_COE(2),
            .COE_NUMS      ({-2788, 19030}),
            .YOUT_WIDTH    (DATA_WIDTH),
            .SRA_BITS      (15)
        ) i_up2_2_q (
            .clk  (clk),
            .rst  (local_rst),
            .xin0 (data_up2_q_p0),
            .xin1 (data_up2_q_p1),
            .yout0(data_up4_q_p0),
            .yout1(data_up4_q_p1),
            .yout2(data_up4_q_p2),
            .yout3(data_up4_q_p3),
            .ovf  (  /* Not used */)
        );

      end // CSR switch
    end // UP_FACTOR switch
  endgenerate


  // CORDIC
  // Convert input data into "theta and r" format.
  // 10 clock tick latency
  generate
    for (genvar pp = 0; pp < UP_FACTOR; pp++) begin: g_cordic_p

      cordic_cart2pol #(
          .DATA_WIDTH          (DATA_WIDTH),
          .CTRL_WIDTH          (1),
          .ITERATIONS          (Iterations),
          .COMPENSATION_SCALING(1)
      ) i_cordic_cart2pol_p0 (
          .clk     (clk),
          .rst     (local_rst),
          //
          .xin     (data_up_i_px[pp]),
          .yin     (data_up_q_px[pp]),
          .ctrl_in (1'b0),
          //
          .theta   (data_theta_px[pp]),
          .r       (data_r_px[pp]),
          .ctrl_out(  /* Not used */)
      );

    end
  endgenerate


  // Peak detector,
  // 19 clock tick latency

  cfr_pc_pd #(
      .CSR       (CSR),
      .ITERATIONS(Iterations),
      .DATA_WIDTH(DATA_WIDTH)
  ) i_cfr_pc_pd (
      .clk                    (clk),
      .rst                    (local_rst),
      //
      .data_r_px              (data_r_px),
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
      .ctrl_out(  /* Not used */)
  );

  reg_pipeline #(
      .DATA_WIDTH     (3),
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
  // 143 clock tick latency

  cfr_pc_softclipper #(
      .DATA_WIDTH    (DATA_WIDTH),
      .CPW_ADDR_WIDTH(CPW_ADDR_WIDTH),
      .NUM_CPG       (6)
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
      .ctrl_cpw_wr_data_i(ctrl_cpw_wr_data_i),
      .ctrl_cpw_wr_data_q(ctrl_cpw_wr_data_q)
  );

endmodule

`default_nettype wire
