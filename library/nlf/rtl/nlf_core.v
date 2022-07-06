// File: nlf_core.sv
// Brief: Core function for LUT and signal complex multiply add chain
`timescale 1 ns / 1 ps
//
`default_nettype none

module nlf_core #(
    parameter integer NUM_UNITS      = 16,
    parameter integer DATA_WIDTH     = 16,
    parameter integer INDEX_WIDTH    = 8,
    parameter integer LUT_DATA_WIDTH = 16,
    parameter integer SRA_BITS       = 14
) (
    // Read Interface
    input wire                                clk,
    input wire                                rst,
    //
    input wire                                bank_in      [NUM_UNITS],
    input wire         [     INDEX_WIDTH-1:0] index_in     [NUM_UNITS],
    //
    input wire  signed [      DATA_WIDTH-1:0] data_i_in    [NUM_UNITS],
    input wire  signed [      DATA_WIDTH-1:0] data_q_in    [NUM_UNITS],
    //
    output wire signed [      DATA_WIDTH-1:0] data_i_out,
    output wire signed [      DATA_WIDTH-1:0] data_q_out,
    //
    output wire                               ovf,
    //
    input wire                                ctrl_clk,
    input wire                                ctrl_rst,
    //
    input wire         [       INDEX_WIDTH:0] ctrl_lut_addr[NUM_UNITS],
    input wire                                ctrl_lut_en  [NUM_UNITS],
    input wire                                ctrl_lut_we  [NUM_UNITS],
    input wire         [LUT_DATA_WIDTH*2-1:0] ctrl_lut_din [NUM_UNITS],
    output wire        [LUT_DATA_WIDTH*2-1:0] ctrl_lut_dout[NUM_UNITS]
);


  localparam integer LutWidth = LUT_DATA_WIDTH * 2;

  reg        [      LutWidth-1:0] coe_s  [NUM_UNITS];
  reg signed [LUT_DATA_WIDTH-1:0] coe_i_s[NUM_UNITS];
  reg signed [LUT_DATA_WIDTH-1:0] coe_q_s[NUM_UNITS];

  generate
    genvar i;
    for (i = 0; i < NUM_UNITS; i = i + 1) begin : g_luts

      nlf_lut #(
          .INDEX_WIDTH(INDEX_WIDTH),
          .LUT_WIDTH  (LutWidth)
      ) i_lut (
          // Read Interface
          .clk          (clk),
          .rst          (rst),
          //
          .bank         (bank_in[i]),
          .index        (index_in[i]),
          .dout         (coe_s[i]),
          // Write Interface
          .ctrl_clk     (ctrl_clk),
          .ctrl_rst     (ctrl_rst),
          //
          .ctrl_lut_addr(ctrl_lut_addr[i]),
          .ctrl_lut_en  (ctrl_lut_en[i]),
          .ctrl_lut_we  (ctrl_lut_we[i]),
          .ctrl_lut_din (ctrl_lut_din[i]),
          .ctrl_lut_dout(ctrl_lut_dout[i])
      );

      assign {coe_q_s[i], coe_i_s[i]} = coe_s[i];

    end
  endgenerate

  cmult_chain #(
      .NUM_TAPS(NUM_UNITS),
      .A_WIDTH (DATA_WIDTH),
      .B_WIDTH (DATA_WIDTH),
      .P_WIDTH (DATA_WIDTH),
      .SRABITS (SRA_BITS)
  ) i_cmult_chain (
      .clk(clk),
      .rst(rst),
      //
      .ar (data_i_in),
      .ai (data_q_in),
      //
      .br (coe_i_s),
      .bi (coe_q_s),
      //
      .pr (data_i_out),
      .pi (data_q_out),
      // Overflow indicator
      .ovf(ovf)
  );

endmodule

`default_nettype wire
