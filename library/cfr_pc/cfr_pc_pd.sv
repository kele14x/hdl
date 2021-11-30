// File: cfr_pc_pd.sv
// Brief: cfr_pc_pd Peak Detector for `cfr_pc` module

`timescale 1ns / 1ps `default_nettype none

module cfr_pc_pd #(
    parameter int MAX_SPACING = 16,
    parameter int ITERATIONS  = 7,
    parameter int DATA_WIDTH  = 16
) (
    input var  logic                clk,
    input var  logic                rst,
    //
    input var  logic [DATA_WIDTH:0] data_r_p0,
    input var  logic [DATA_WIDTH:0] data_r_p1,
    input var  logic [DATA_WIDTH:0] data_r_p2,
    input var  logic [DATA_WIDTH:0] data_r_p3,
    input var  logic [ITERATIONS:0] data_theta_p0,
    input var  logic [ITERATIONS:0] data_theta_p1,
    input var  logic [ITERATIONS:0] data_theta_p2,
    input var  logic [ITERATIONS:0] data_theta_p3,
    //
    output var logic [DATA_WIDTH:0] peak_r,
    output var logic [ITERATIONS:0] peak_theta,
    output var logic [         1:0] peak_phase,
    output var logic                peak_valid,
    //
    input var  logic                ctrl_enable,
    input var  logic [         3:0] ctrl_spacing,
    input var  logic [DATA_WIDTH:0] ctrl_pd_threshold,
    input var  logic [DATA_WIDTH:0] ctrl_clipping_threshold
);


  logic [DATA_WIDTH:0] data_r_p01, data_r_p23, data_r_p0123;
  logic [ITERATIONS:0] data_theta_p01, data_theta_p23, data_theta_p0123;
  logic [         1:0] data_phase;
  logic g01, g23;

  typedef enum int {
    S_NEG,
    S_POS
  } state_t;

  state_t state1_det, state2_det;

  logic gm;

  logic [DATA_WIDTH:0] state1_max, state2_max;
  logic [ITERATIONS:0] state1_theta, state2_theta;
  logic [         1:0] state1_phase, state2_phase;


  logic [DATA_WIDTH:0] peak_r_pre;
  logic [ITERATIONS:0] peak_theta_pre;
  logic [         1:0] peak_phase_pre;
  logic                peak_valid_pre;
  logic                g0;

  logic [DATA_WIDTH:0] data_r;
  logic [ITERATIONS:0] data_theta;
  logic                data_phase;

  logic [         3:0] ctrl_spacing_1;
  logic [         3:0] spacing;

  logic                h0;

  logic [DATA_WIDTH:0] state_max;
  logic [ITERATIONS:0] state_theta;
  logic                state_phase;

  logic [DATA_WIDTH:0] peak_r_pre        [MAX_SPACING];
  logic [ITERATIONS:0] peak_theta_pre    [MAX_SPACING];
  logic                peak_phase_pre    [MAX_SPACING];
  logic                peak_valid_pre    [MAX_SPACING];

  logic                peak_lt_threshold;


  // Select the max from multi-phase

  assign g0 = data_r_p1 >= data_r_p0;

  always_ff @(posedge clk) begin
    data_r     <= g0 ? data_r_p1 : data_r_p0;
    data_phase <= g0 ? 1'b1 : 1'b0;
    data_theta <= g0 ? data_theta_p1 : data_theta_p0;
  end


  // Peak search logic
  // "Peak" is defined as maximum sample among N neighborhood samples
  // where N >= 1. This is to ensure min gap between peaks. So we will
  // handle narrow bandwidth signal well.

  // Ensure ctrl_spacing is not 0, since N should be larger than 0
  assign ctrl_spacing_1 = (ctrl_spacing == 0) ? 1 : ctrl_spacing;
  assign h0 = data_r >= state_max;

  always_ff @(posedge clk) begin
    if (rst) begin
      spacing <= '0;
    end else begin
      if (h0) begin
        spacing <= '0;
      end else begin
        spacing <= spacing == ctrl_spacing_1 ? '0 : spacing + 1;
      end
    end
  end

  always_ff @(posedge clk) begin
    if (h0 || (spacing == ctrl_spacing_1)) begin
      state_max   <= data_r;
      state_phase <= data_phase;
      state_theta <= data_theta;
    end else begin
      state_max   <= state_max;
      state_phase <= state_phase;
      state_theta <= state_theta;
    end
  end

  always_ff @(posedge clk) begin
    peak_valid_pre[0] <= 1'b0;
    for (int i = 1; i < MAX_SPACING; i++) begin
      peak_valid_pre[i] <= peak_valid_pre[i-1];
    end
    // if a peak is found
    if ((spacing == ctrl_spacing_1) && ~h0) begin
      peak_valid_pre[ctrl_spacing_1] <= 1'b1;
    end
  end

  always_ff @(posedge clk) begin
    peak_r_pre[0]     <= state_max;
    peak_phase_pre[0] <= state_phase;
    peak_theta_pre[0] <= state_theta;
    for (int i = 1; i < MAX_SPACING; i++) begin
      peak_r_pre[i]     <= peak_r_pre[i-1];
      peak_phase_pre[i] <= peak_phase_pre[i-1];
      peak_theta_pre[i] <= peak_theta_pre[i-1];
    end
  end


  // Only peak larger than threshold will be marked valid

  assign peak_lt_threshold = ctrl_enable && peak_valid_pre[MAX_SPACING-1] &&
    (peak_r_pre[MAX_SPACING-1] > ctrl_pd_threshold);

  always_ff @(posedge clk) begin
    peak_valid <= peak_lt_threshold ? 1'b1 : 1'b0;
    peak_r     <= (peak_r_pre[MAX_SPACING-1] - ctrl_clipping_threshold);
    peak_phase <= peak_phase_pre[MAX_SPACING-1];
    peak_theta <= peak_theta_pre[MAX_SPACING-1];
  end

endmodule

`default_nettype wire
