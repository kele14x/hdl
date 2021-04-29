// File: ul_adaptor_buf.sv
// Brief: Uplink PUxCH (UL U-Plane data) buffer
`timescale 1 ns / 1 ps `default_nettype none

module ul_adaptor_buf #(
    parameter int NUM_UL_LAYER = 8
) (
    input var         clk,
    input var         rst,
    //
    input var         ul_sof,
    input var         ul_sos,
    input var  [15:0] ul_data_i            [NUM_UL_LAYER],
    input var  [15:0] ul_data_q            [NUM_UL_LAYER],
    input var         ul_valid,
    //
    output var        fram_radio_start_10ms,
    //
    input var         ram_bank             [NUM_UL_LAYER],
    input var  [11:0] ram_addr             [NUM_UL_LAYER],
    input var         ram_rden             [NUM_UL_LAYER],
    output var [63:0] ram_data             [NUM_UL_LAYER],
    // Control Interface
    //==================
    input var  [ 3:0] ctrl_bandwidth,
    input var  [ 1:0] ctrl_numerology
);

  logic wr_bank;
  logic [12:0] wr_addr;

  ul_adaptor_buf_ctrl #(
      .NUM_UL_LAYER(NUM_UL_LAYER)
  ) i_ctrl (
      .clk                  (clk),
      .rst                  (rst),
      //
      .ul_sof               (ul_sof),
      .ul_sos               (ul_sos),
      .ul_valid             (ul_valid),
      //
      .wr_bank              (wr_bank),
      .wr_addr              (wr_addr),
      //
      .fram_radio_start_10ms(fram_radio_start_10ms),
      //
      .ctrl_bandwidth       (ctrl_bandwidth),
      .ctrl_numerology      (ctrl_numerology)
  );

  generate
    for (genvar i = 0; i < NUM_UL_LAYER; i++) begin

      ul_adaptor_buf_data i_data (
          .clk     (clk),
          .rst     (rst),
          //
          .wr_bank (wr_bank),
          .wr_addr (wr_addr),
          .wr_en   (ul_valid),
          .wr_data ({ul_data_q[i], ul_data_i[i]}),
          //
          .ram_bank(ram_bank),
          .ram_addr(ram_addr),
          .ram_rden(ram_rden),
          .ram_data(ram_data)
      );

    end
  endgenerate

endmodule

`default_nettype wire
