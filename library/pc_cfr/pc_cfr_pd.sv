// File: pc_cfr_pd.sv
// Brief: pc_cfr_pd Peak Detector for `pc_cfr` module

`timescale 1ns / 1ps `default_nettype none

module pc_cfr_pd #(
    parameter int ITERATIONS = 7,
    parameter int DATA_WIDTH = 16
) (
    input var  logic                clk,
    input var  logic                rst,
    //
    input var  logic [DATA_WIDTH:0] data_r_p0,
    input var  logic [DATA_WIDTH:0] data_r_p1,
    input var  logic [ITERATIONS:0] data_theta_p0,
    input var  logic [ITERATIONS:0] data_theta_p1,
    //
    output var logic [DATA_WIDTH:0] peak_r,
    output var logic [ITERATIONS:0] peak_theta,
    output var logic                peak_phase,
    output var logic                peak_valid,
    //
    input var  logic                ctrl_enable,
    input var  logic [DATA_WIDTH:0] ctrl_pd_threshold,
    input var  logic [DATA_WIDTH:0] ctrl_clipping_threshold
);

  typedef enum int {
    S_NEG,
    S_POS
  } state_t;

  state_t state1_det, state2_det;

  logic [DATA_WIDTH:0] state1_max, state2_max;
  logic [ITERATIONS:0] state1_theta, state2_theta;
  logic state1_phase, state2_phase;

  logic g1, g2, g3;

  logic [DATA_WIDTH:0] peak_r_pre;
  logic [ITERATIONS:0] peak_theta_pre;
  logic                peak_phase_pre;
  logic                peak_valid_pre;

  logic                peak_lt_threshold;

  assign g1 = data_r_p0 >= state1_max;
  assign g2 = data_r_p1 >= state1_max;
  assign g3 = data_r_p1 >= data_r_p0;

  always_ff @(posedge clk) begin
    if (rst) begin
      state1_det <= S_NEG;
      state2_det <= S_NEG;
    end else begin
      state1_det <= state2_det;
      case (state1_det)
        S_POS:   state2_det <= (g1 || g2) ? S_POS : S_NEG;
        S_NEG:   state2_det <= (g1 || g2) ? S_POS : S_NEG;
        default: state2_det <= S_NEG;
      endcase
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      state1_max <= 'd0;
      state2_max <= 'd0;
    end else begin
      state1_max <= state2_max;
      state2_max <= g3 ? data_r_p1 : data_r_p0;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      state1_phase <= 'd0;
      state2_phase <= 'd0;
    end else begin
      state1_phase <= state2_phase;
      state2_phase <= g3 ? 1'b1 : 1'b0;
    end
  end


  always_ff @(posedge clk) begin
    if (rst) begin
      state1_theta <= 'd0;
      state2_theta <= 'd0;
    end else begin
      state1_theta <= state2_theta;
      state2_theta <= g3 ? data_theta_p1 : data_theta_p0;
    end
  end

  always_ff @(posedge clk) begin
    peak_valid_pre <= (state1_det == S_POS) && ~(g1 || g2);
  end

  always_ff @(posedge clk) begin
    peak_r_pre     <= state1_max;
    peak_phase_pre <= state1_phase;
    peak_theta_pre <= state1_theta;
  end

  assign peak_lt_threshold = ctrl_enable && peak_valid_pre && (peak_r_pre > ctrl_pd_threshold);

  always_ff @(posedge clk) begin
    peak_valid <= peak_lt_threshold ? 1'b1 : 1'b0;
    peak_r     <= (peak_r_pre - ctrl_clipping_threshold);
    peak_phase <= peak_phase_pre;
    peak_theta <= peak_theta_pre;
  end

endmodule

`default_nettype wire
