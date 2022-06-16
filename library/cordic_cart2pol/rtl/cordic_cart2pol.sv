// File: cordic_cart2pol.sv
// Breif: CORDIC-based approximation of cartesian-to-polar conversion

`timescale 1 ns / 1 ps `default_nettype none

module cordic_cart2pol #(
    parameter int DATA_WIDTH           = 16,
    parameter int CTRL_WIDTH           = 1,
    parameter int ITERATIONS           = 7,
    parameter int COMPENSATION_SCALING = 1
) (
    input var  logic                  clk,
    input var  logic                  rst,
    //
    input var  logic [DATA_WIDTH-1:0] xin,
    input var  logic [DATA_WIDTH-1:0] yin,
    input var  logic [CTRL_WIDTH-1:0] ctrl_in,
    //
    output var logic [  ITERATIONS:0] theta,
    output var logic [DATA_WIDTH+1:0] r,
    output var logic [CTRL_WIDTH-1:0] ctrl_out
);

  localparam int Latency = ITERATIONS + 2 * COMPENSATION_SCALING + 1;

  // During iteration, x need 2 more bits, one for magnitude, one for CORDIC
  // growth factor.
  logic signed [DATA_WIDTH+1:0] x            [ITERATIONS+1];
  logic signed [DATA_WIDTH-1:0] y            [ITERATIONS+1];
  logic        [  ITERATIONS:0] z            [ITERATIONS+1];
  // Rotation direction, 0 = clockwise, 1 = counterclockwise
  logic                         d            [  ITERATIONS];

  // CORDIC interactions output
  logic        [ITERATIONS+1:0] theta_cordic;
  logic signed [DATA_WIDTH+1:0] r_cordic;

  // Iteration initialization
  assign x[0] = {xin[DATA_WIDTH-1], xin[DATA_WIDTH-1], xin};
  assign y[0] = yin;
  assign z[0] = {{ITERATIONS{1'b0}}, x[0][DATA_WIDTH+1]};

  // Pseudo rotation iterations
  generate
    for (genvar i = 0; i < ITERATIONS; i++) begin : g_pseudo_rotation

      assign d[i] = y[i][DATA_WIDTH-1] ^ x[i][DATA_WIDTH+1];

      always_ff @(posedge clk) begin
        x[i+1] <= d[i] ? (x[i] - (y[i] >>> i)) : (x[i] + (y[i] >>> i));
        y[i+1] <= d[i] ? (y[i] + (x[i] >>> i)) : (y[i] - (x[i] >>> i));
        z[i+1] <= {z[i], ~d[i]};
      end

    end
  endgenerate

  // CORDIC output
  always_ff @(posedge clk) begin
    theta_cordic <= z[ITERATIONS];
    r_cordic     <= z[ITERATIONS][ITERATIONS] ? -x[ITERATIONS] : x[ITERATIONS];
  end

  // Scale growth compensation
  generate

    if (COMPENSATION_SCALING) begin : g_comp_scaling

      // Compensation is done by r = r * (1/2 + 1/8) * (1 - 1/32)
      logic        [ITERATIONS+1:0] theta_compensation[2];
      logic signed [DATA_WIDTH+1:0] r_compensation    [2];

      always_ff @(posedge clk) begin
        theta_compensation[0] <= theta_cordic;
        theta_compensation[1] <= theta_compensation[0];
      end

      always_ff @(posedge clk) begin
        r_compensation[0] <= (r_cordic >>> 1) + (r_cordic >>> 3);
        r_compensation[1] <= r_compensation[0] - (r_compensation[0] >>> 5);
      end

      assign theta = theta_compensation[1];
      assign r     = r_compensation[1];

    end else begin : g_no_comp_scaling

      // No compensation, directly output
      assign theta = theta_cordic;
      assign r     = r_cordic;

    end

  endgenerate

  // CTRL path, the module itself does not use it
  reg_pipeline #(
      .DATA_WIDTH     (CTRL_WIDTH),
      .PIPELINE_STAGES(Latency)
  ) i_delay (
      .clk (clk),
      .din (ctrl_in),
      .dout(ctrl_out)
  );

endmodule

`default_nettype wire
