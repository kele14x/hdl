// File: ul_adaptor_buf.sv
// Brief: Uplink PUxCH (UL U-Plane data) buffer
`timescale 1 ns / 1 ps `default_nettype none

module ul_adaptor_buf_ctrl #(
    parameter int NUM_UL_LAYER = 8
) (
    input var         clk,
    input var         rst,
    //
    input var         ul_sof,
    input var         ul_sos,
    input var         ul_valid,
    //
    output var        wr_bank,
    output var [12:0] wr_addr,
    //
    output var        fram_radio_start_10ms,
    // Control Interface
    //==================
    input var  [ 3:0] ctrl_bandwidth,
    input var  [ 1:0] ctrl_numerology
);


  always_ff @(posedge clk) begin
    if (rst) begin
      wr_bank <= 0;
    end else if (ul_sof) begin
      wr_bank <= 0;
    end else if (ul_sos) begin
      wr_bank <= ~wr_bank;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      wr_addr <= 0;
    end else if (ul_valid) begin
      wr_addr <= wr_addr + 1;
    end
  end

endmodule

`default_nettype wire
