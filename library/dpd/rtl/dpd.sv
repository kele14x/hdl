// File: dpd.sv
// Brief: DPD top module.
`timescale 1 ns / 1 ps
//
`default_nettype none

module dpd #(
    parameter int NUM_CHANNELS   = 2,
    parameter int NUM_UNITS      = 16,
    parameter int DATA_WIDTH     = 16,
    parameter int DELAY_WIDTH    = 5,
    parameter int INDEX_WIDTH    = 8,
    parameter int LUT_DATA_WIDTH = 16,
    parameter int SRA_BITS       = 14
) (
    input var                  clk,
    input var                  rst,
    //
    input var [DATA_WIDTH-1:0] data_i_in [NUM_CHANNELS],
    input var [DATA_WIDTH-1:0] data_q_in [NUM_CHANNELS],
    //
    input var [DATA_WIDTH-1:0] data_i_out[NUM_CHANNELS],
    input var [DATA_WIDTH-1:0] data_q_out[NUM_CHANNELS]
);


  generate
    for (genvar i = 0; i < NUM_CHANNELS; i++) begin : g_ch
      dpd_channel #(
          .DATA_WIDTH(DATA_WIDTH)
      ) i_channel (
          .clk                  (clk),
          .rst                  (rst),
          //
          .data_i_in            (data_i_in[i]),
          .data_q_in            (data_q_in[i]),
          //
          .data_i_out           (data_i_out[i]),
          .data_q_out           (data_q_out[i]),
          //
          .ctrl_clk             (ctrl_clk),
          .ctrl_rst             (ctrl_rst),
          //   Gain block
          .ctrl_pre_gmp_gain    (ctrl_pre_gmp_gain),
          //
          .ctrl_nlf_bank        (ctrl_nlf_bank),
          //
          .ctrl_nlf_index_delay (ctrl_nlf_index_delay),
          .ctrl_nlf_signal_delay(ctrl_nlf_signal_delay),
          //
          .ctrl_lut_addr        (ctrl_lut_addr),
          .ctrl_lut_en          (ctrl_lut_en),
          .ctrl_lut_we          (ctrl_lut_we),
          .ctrl_lut_din         (ctrl_lut_din),
          .ctrl_lut_dout        (ctrl_lut_dout),
          //   QMC
          .ctrl_qmc_i_gain      (ctrl_qmc_i_gain),
          .ctrl_qmc_q_gain      (ctrl_qmc_q_gain),
          .ctrl_qmc_qi_gain     (ctrl_qmc_qi_gain),
          .ctrl_qmc_i_offset    (ctrl_qmc_i_offset),
          .ctrl_qmc_q_offset    (ctrl_qmc_q_offset)
      );
    end
  endgenerate

endmodule

`default_nettype wire
