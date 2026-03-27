`timescale 1 ns / 1 ps
//
`default_nettype none

module rts_cw (
    input  wire        clk,
    input  wire        rst,
    //
    input  wire        sync,
    //
    output reg  [15:0] cw_cos,
    output reg  [15:0] cw_sin,
    //
    input  wire [19:0] ctrl_cw0_freq,
    input  wire [15:0] ctrl_cw0_pow,
    input  wire [19:0] ctrl_cw1_freq,
    input  wire [15:0] ctrl_cw1_pow
);

  wire        [19:0] ctrl_cw0_freq_s;
  wire        [15:0] ctrl_cw0_pow_s;
  wire        [19:0] ctrl_cw1_freq_s;
  wire        [15:0] ctrl_cw1_pow_s;

  wire signed [15:0] cw0_cos;
  wire signed [15:0] cw0_sin;

  wire signed [15:0] cw1_cos;
  wire signed [15:0] cw1_sin;

  wire signed [15:0] cw0_cos_gain;
  wire signed [15:0] cw0_sin_gain;

  wire signed [15:0] cw1_cos_gain;
  wire signed [15:0] cw1_sin_gain;

  cdc_array_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (0),
      .SRC_INPUT_REG(0),
      .WIDTH        (20)
  ) cdc_array_single_ctrl_cw0_freq (
      .src_clk (1'b0),
      .src_in  (ctrl_cw0_freq),
      .dest_clk(clk),
      .dest_out(ctrl_cw0_freq_s)
  );

  cdc_array_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (0),
      .SRC_INPUT_REG(0),
      .WIDTH        (16)
  ) cdc_array_single_ctrl_cw0_pow (
      .src_clk (1'b0),
      .src_in  (ctrl_cw0_pow),
      .dest_clk(clk),
      .dest_out(ctrl_cw0_pow_s)
  );

  cdc_array_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (0),
      .SRC_INPUT_REG(0),
      .WIDTH        (20)
  ) cdc_array_single_ctrl_cw1_freq (
      .src_clk (1'b0),
      .src_in  (ctrl_cw1_freq),
      .dest_clk(clk),
      .dest_out(ctrl_cw1_freq_s)
  );

  cdc_array_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (0),
      .SRC_INPUT_REG(0),
      .WIDTH        (16)
  ) cdc_array_single_ctrl_cw1_pow (
      .src_clk (1'b0),
      .src_in  (ctrl_cw1_pow),
      .dest_clk(clk),
      .dest_out(ctrl_cw1_pow_s)
  );

  nco #(
      .NUM_PARALLEL        (1),
      .PHASE_INTEGER_WIDTH (12),
      .PHASE_FRACTION_WIDTH(20),
      .LFSR_INITIAL        (20'hFFFFF),
      .LFSR_POLYNOMIAL     (21'h100005)
  ) i_nco_0 (
      .clk      (clk),
      .rst      (rst),
      //
      .sync     (sync),
      //
      .cos      (cw0_cos),
      .sin      (cw0_sin),
      //
      .ctrl_poff('d0),
      .ctrl_pinc({ctrl_cw0_freq_s, 12'b0})
  );

  nco #(
      .NUM_PARALLEL        (1),
      .PHASE_INTEGER_WIDTH (12),
      .PHASE_FRACTION_WIDTH(20),
      .LFSR_INITIAL        (20'hFFFFF),
      .LFSR_POLYNOMIAL     (21'h100005)
  ) i_nco_1 (
      .clk      (clk),
      .rst      (rst),
      //
      .sync     (sync),
      //
      .cos      (cw1_cos),
      .sin      (cw1_sin),
      //
      .ctrl_poff('d0),
      .ctrl_pinc({ctrl_cw1_freq_s, 12'b0})
  );

  mult #(
      .A_WIDTH(16),
      .B_WIDTH(17),
      .P_WIDTH(16),
      .SHIFT  (15)
  ) i_gain0_cos (
      .clk(clk),
      .rst(rst),
      //
      .a  (cw0_cos),
      .b  ({1'b0, ctrl_cw0_pow_s}),
      //
      .p  (cw0_cos_gain),
      .ovf()
  );

  mult #(
      .A_WIDTH(16),
      .B_WIDTH(17),
      .P_WIDTH(16),
      .SHIFT  (15)
  ) i_gain0_sin (
      .clk(clk),
      .rst(rst),
      //
      .a  (cw0_sin),
      .b  ({1'b0, ctrl_cw0_pow_s}),
      //
      .p  (cw0_sin_gain),
      .ovf()
  );

  mult #(
      .A_WIDTH(16),
      .B_WIDTH(17),
      .P_WIDTH(16),
      .SHIFT  (15)
  ) i_gain1_cos (
      .clk(clk),
      .rst(rst),
      //
      .a  (cw1_cos),
      .b  ({1'b0, ctrl_cw1_pow_s}),
      //
      .p  (cw1_cos_gain),
      .ovf()
  );

  mult #(
      .A_WIDTH(16),
      .B_WIDTH(17),
      .P_WIDTH(16),
      .SHIFT  (15)
  ) i_gain1_sin (
      .clk(clk),
      .rst(rst),
      //
      .a  (cw1_sin),
      .b  ({1'b0, ctrl_cw1_pow_s}),
      //
      .p  (cw1_sin_gain),
      .ovf()
  );

  // Add two tones together
  always @(posedge clk) begin
    cw_cos <= cw0_cos_gain + cw1_cos_gain;
    cw_sin <= cw0_sin_gain + cw1_sin_gain;
  end

endmodule

`default_nettype wire
