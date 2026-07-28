// File: equalizer.v
// Brief: Equalizer implemented using a complex FIR.
`timescale 1 ns / 1 ps
//
`default_nettype none

module equalizer #(
  parameter integer NUM_TAPS          = 8,
  parameter integer INPUT_DATA_WIDTH  = 16,
  parameter integer COE_WIDTH         = 16,
  parameter integer OUTPUT_DATA_WIDTH = 16,
  parameter integer SRA_BITS          = 15
) (
  input  wire                                clk,
  input  wire                                rst,
  // Data input
  input  wire signed [ INPUT_DATA_WIDTH-1:0] data_i_in,
  input  wire signed [ INPUT_DATA_WIDTH-1:0] data_q_in,
  // Data output
  output wire signed [OUTPUT_DATA_WIDTH-1:0] data_i_out,
  output wire signed [OUTPUT_DATA_WIDTH-1:0] data_q_out,
  output wire                                ovf,
  // Coefficients
  input  wire        [ $clog2(NUM_TAPS)-1:0] ctrl_coe_idx,
  input  wire                                ctrl_coe_valid,
  input  wire signed [        COE_WIDTH-1:0] ctrl_coe_i_in,
  input  wire signed [        COE_WIDTH-1:0] ctrl_coe_q_in
);


  // Internal signals
  //=================

  reg signed [INPUT_DATA_WIDTH-1:0] data_i_d [0:NUM_TAPS*2-2];
  reg signed [INPUT_DATA_WIDTH-1:0] data_q_d [0:NUM_TAPS*2-2];

  reg signed [COE_WIDTH-1:0] coe_i_r [0:NUM_TAPS-1];
  reg signed [COE_WIDTH-1:0] coe_q_r [0:NUM_TAPS-1];

  wire signed [INPUT_DATA_WIDTH-1:0] ar[NUM_TAPS];
  wire signed [INPUT_DATA_WIDTH-1:0] ai[NUM_TAPS];
  wire signed [       COE_WIDTH-1:0] br[NUM_TAPS];
  wire signed [       COE_WIDTH-1:0] bi[NUM_TAPS];


  initial begin : p_init
    integer i;
    for (i = 0; i < NUM_TAPS*2-1; i = i + 1) begin
      data_i_d[i] = 0;
      data_q_d[i] = 0;
    end
  end

  always @(posedge clk) begin : p_data_delay
    integer i;
    data_i_d[0] <= data_i_in;
    data_q_d[0] <= data_q_in;
    for (i = 1; i < NUM_TAPS*2-1; i = i + 1) begin
      data_i_d[i] <= data_i_d[i-1];
      data_q_d[i] <= data_q_d[i-1];
    end
  end

  always @(posedge clk) begin
    if (ctrl_coe_valid) begin
      coe_i_r[ctrl_coe_idx] <= ctrl_coe_i_in;
      coe_q_r[ctrl_coe_idx] <= ctrl_coe_q_in;
    end
  end


  generate
    genvar i;
    for (i = 0; i < NUM_TAPS; i = i + 1) begin
      //
      assign ar[i] = data_i_d[2*i];
      assign ai[i] = data_q_d[2*i];
      //
      assign br[i] = coe_i_r[i];
      assign bi[i] = coe_q_r[i];
    end
  endgenerate


  cmult_chain #(
      .NUM_TAPS(NUM_TAPS),
      .A_WIDTH (INPUT_DATA_WIDTH),
      .B_WIDTH (COE_WIDTH),
      .P_WIDTH (OUTPUT_DATA_WIDTH),
      .SRA_BITS(SRA_BITS)
  ) DUT (
      .clk   (clk),
      .rst   (rst),
      .ar    (ar),
      .ai    (ai),
      .br    (br),
      .bi    (bi),
      .pr    (data_i_out),
      .pi    (data_q_out),
      .ovf   (ovf)
  );

endmodule

`default_nettype wire
