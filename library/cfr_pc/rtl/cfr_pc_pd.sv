// File: cfr_pc_pd.sv
// Brief: cfr_pc_pd Peak Detector for `cfr_pc` module

`timescale 1ns / 1ps `default_nettype none

module cfr_pc_pd #(
    // Architecture parameters
    parameter int CSR         = 2,
    parameter int UP_FACTOR   = 2,
    //
    parameter int MAX_SPACING = 16,
    parameter int ITERATIONS  = 7,
    parameter int DATA_WIDTH  = 16
) (
    input var  logic                         clk,
    input var  logic                         rst,
    //
    input var  logic [         DATA_WIDTH:0] data_r_px              [UP_FACTOR],
    input var  logic [         ITERATIONS:0] data_theta_px          [UP_FACTOR],
    //
    output var logic [         DATA_WIDTH:0] peak_r,
    output var logic [         ITERATIONS:0] peak_theta,
    output var logic [$clog2(UP_FACTOR)-1:0] peak_phase,
    output var logic                         peak_valid,
    //
    input var  logic                         ctrl_enable,
    input var  logic [                  3:0] ctrl_spacing,
    input var  logic [         DATA_WIDTH:0] ctrl_pd_threshold,
    input var  logic [         DATA_WIDTH:0] ctrl_clipping_threshold
);

  localparam int PhaseWidth = $clog2(UP_FACTOR);
  localparam int Latency = 1 + 2 + MAX_SPACING * CSR;

  logic [  DATA_WIDTH:0] data_r;
  logic [  ITERATIONS:0] data_theta;
  logic [PhaseWidth-1:0] data_phase;

  logic [           3:0] ctrl_spacing_1;
  logic [           3:0] spacing           [            CSR];

  logic                  h0;

  logic [  DATA_WIDTH:0] state_max         [            CSR];
  logic [  ITERATIONS:0] state_theta       [            CSR];
  logic [PhaseWidth-1:0] state_phase       [            CSR];

  logic [  DATA_WIDTH:0] peak_r_pre        [MAX_SPACING*CSR];
  logic [  ITERATIONS:0] peak_theta_pre    [MAX_SPACING*CSR];
  logic [PhaseWidth-1:0] peak_phase_pre    [MAX_SPACING*CSR];
  logic                  peak_valid_pre    [MAX_SPACING*CSR];

  logic                  peak_lt_threshold;


  // Select the max from multi-phase
  max_parallel #(
      .NUM_INPUT (UP_FACTOR),
      .DATA_WIDTH(DATA_WIDTH + 1),
      .CTRL_WIDTH(ITERATIONS + 1)
  ) i_max_parallel (
      .clk     (clk),
      .rst     (rst),
      //
      .data_in (data_r_px),
      .ctrl_in (data_theta_px),
      //
      .data_out(data_r),
      .ctrl_out(data_theta),
      .idx_out (data_phase)
  );


  // Peak search logic
  // "Peak" is defined as maximum sample among N neighborhood samples
  // where N >= 1. This is to ensure min gap between peaks. So we will
  // handle narrow bandwidth signal well.

  // Ensure ctrl_spacing is not 0, since N should be larger than 0
  assign ctrl_spacing_1 = ((ctrl_spacing == 0) ? 1 : ctrl_spacing);

  // Compare current data with max in state
  assign h0 = (data_r >= state_max[CSR-1]);

  generate
    for (genvar ii = 0; ii < CSR; ii++) begin : g_interleave
      if (ii == 0) begin : g_first

        // `spacing` serves as a counter for how many samples have been after
        // a local peak is seen.
        //
        // If the incoming radius is larger than current logged max (`h0` is set)
        // then we will update the state. Also, we will set `spacing` to zero.
        // This indicates that we are at left edge or top of a local peak. During
        // we climbing on the left edge of the peak, `spacing` will be zero.
        //
        // After we seen `h0` is not set, this indicates that we have passed the
        // local peak and on the right edge. Then we will count for `spacing`. If
        // `spacing` count to the defined threshold, we can tell that the
        // previous local peak seen is a true peak (global peak). Then we will
        // prepare for the next local peak.
        always_ff @(posedge clk) begin
          if (rst) begin
            spacing[ii] <= '0;
          end else begin
            if (h0 || (spacing[CSR-1] == ctrl_spacing_1)) begin
              spacing[ii] <= '0;
            end else begin
              spacing[ii] <= spacing[CSR-1] + 1;
            end
          end
        end

        always_ff @(posedge clk) begin
          if (h0 || (spacing[CSR-1] == ctrl_spacing_1)) begin
            state_max[ii]   <= data_r;
            state_theta[ii] <= data_theta;
            state_phase[ii] <= data_phase;
          end else begin
            state_max[ii]   <= state_max[CSR-1];
            state_theta[ii] <= state_theta[CSR-1];
            state_phase[ii] <= state_phase[CSR-1];
          end
        end

      end else begin : g_left

        // If CSR is larger than 1, we will need to interleave the state. [0]
        // is for current channel. And other states will just be put into "sleep".

        always_ff @(posedge clk) begin
          spacing[ii] <= spacing[ii-1];
        end

        always_ff @(posedge clk) begin
          state_max[ii]   <= state_max[ii-1];
          state_theta[ii] <= state_theta[ii-1];
          state_phase[ii] <= state_phase[ii-1];
        end

      end  // if
    end  // for
  endgenerate

  always_ff @(posedge clk) begin
    peak_r_pre[0]     <= state_max[0];
    peak_theta_pre[0] <= state_theta[0];
    peak_phase_pre[0] <= state_phase[0];
    for (int i = 1; i < MAX_SPACING * CSR; i++) begin
      peak_r_pre[i]     <= peak_r_pre[i-1];
      peak_theta_pre[i] <= peak_theta_pre[i-1];
      peak_phase_pre[i] <= peak_phase_pre[i-1];
    end
  end

  always_ff @(posedge clk) begin
    peak_valid_pre[0] <= 1'b0;
    for (int i = 1; i < MAX_SPACING * CSR; i++) begin
      peak_valid_pre[i] <= peak_valid_pre[i-1];
    end
    // if a peak is found, set valid. The valid could be at any position based
    // on the `ctrl_spacing` parameter. So we need an selector here.
    if ((spacing[CSR-1] == ctrl_spacing_1) && ~h0) begin
      peak_valid_pre[ctrl_spacing_1*CSR+1] <= 1'b1;
    end
  end

  assign peak_lt_threshold = (peak_r_pre[MAX_SPACING*CSR-1] > ctrl_pd_threshold);

  always_ff @(posedge clk) begin
    // Only peak larger than threshold will be marked valid
    peak_valid <= peak_lt_threshold && ctrl_enable && peak_valid_pre[MAX_SPACING*CSR-1];
    peak_r     <= (peak_r_pre[MAX_SPACING*CSR-1] - ctrl_clipping_threshold);
    peak_phase <= peak_phase_pre[MAX_SPACING*CSR-1];
    peak_theta <= peak_theta_pre[MAX_SPACING*CSR-1];
  end

endmodule

`default_nettype wire
