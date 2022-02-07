// File: nlf_core.sv
// Brief: Core function for lut and signal complex multiply add chain

`timescale 1 ns / 1 ps `default_nettype none

module nlf_core #(
    parameter int NUM_UNITS      = 16,
    parameter int DATA_WIDTH     = 16,
    parameter int INDEX_WIDTH    = 8,
    parameter int LUT_DATA_WIDTH = 16,
    parameter int SRA_BITS       = 14
) (
    // Read Interface
    input var                                clk,
    input var                                rst,
    //
    input var                                bank_in      [NUM_UNITS],
    input var         [     INDEX_WIDTH-1:0] index_in     [NUM_UNITS],
    //
    input var  signed [      DATA_WIDTH-1:0] data_i_in    [NUM_UNITS],
    input var  signed [      DATA_WIDTH-1:0] data_q_in    [NUM_UNITS],
    //
    output var signed [      DATA_WIDTH-1:0] data_i_out,
    output var signed [      DATA_WIDTH-1:0] data_q_out,
    //
    output var                               ovf,
    //
    input var                                ctrl_clk,
    input var                                ctrl_rst,
    //
    input var         [       INDEX_WIDTH:0] ctrl_lut_addr[NUM_UNITS],
    input var                                ctrl_lut_en  [NUM_UNITS],
    input var                                ctrl_lut_we  [NUM_UNITS],
    input var         [LUT_DATA_WIDTH*2-1:0] ctrl_lut_din [NUM_UNITS],
    output var        [LUT_DATA_WIDTH*2-1:0] ctrl_lut_dout[NUM_UNITS]
);


  localparam int LutWidth = LUT_DATA_WIDTH * 2;

  logic        [      LutWidth-1:0] coe_s  [NUM_UNITS];
  logic signed [LUT_DATA_WIDTH-1:0] coe_i_s[NUM_UNITS];
  logic signed [LUT_DATA_WIDTH-1:0] coe_q_s[NUM_UNITS];

  generate
    for (genvar i = 0; i < NUM_UNITS; i = i + 1) begin : g_luts

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
