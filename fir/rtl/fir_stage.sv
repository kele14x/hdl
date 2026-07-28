// File: fir_stage.sv
// Brief: Processing stage for fir module.
`timescale 1 ns / 1 ps
//
`default_nettype none

module fir_stage #(
    parameter int FORWARD_DELAY  = 15,
    parameter int BACKWARD_DELAY = 17,
    parameter bit LOOPBACK       = 0,
    //
    parameter int DATA_WIDTH     = 16,
    //
    parameter int COE_ADDR_WIDTH = 4,
    parameter int COE_DATA_WIDTH = 16,
    //
    parameter int MAC_DATA_WIDTH = 33
) (
    input var                              clk,
    input var                              rst,
    //
    input var         [COE_ADDR_WIDTH-1:0] coe_addr,
    //
    input var  signed [    DATA_WIDTH-1:0] forward_data_in,
    output var signed [    DATA_WIDTH-1:0] forward_data_out,
    //
    input var  signed [    DATA_WIDTH-1:0] backward_data_in,
    output var signed [    DATA_WIDTH-1:0] backward_data_out,
    //
    input var  signed [MAC_DATA_WIDTH-1:0] mac_data_in,
    output var signed [MAC_DATA_WIDTH-1:0] mac_data_out,
    // Control interface
    //==================
    input var                              ctrl_clk,
    input var                              ctrl_rst,
    //
    input var                              ctrl_coe_en,
    input var                              ctrl_coe_we,
    input var         [COE_ADDR_WIDTH-1:0] ctrl_coe_addr,
    input var         [COE_DATA_WIDTH-1:0] ctrl_coe_din,
    output var        [COE_DATA_WIDTH-1:0] ctrl_coe_dout
);


  // Signals
  //========

  logic signed [    DATA_WIDTH-1:0] backward_data_s;

  logic signed [COE_DATA_WIDTH-1:0] coe_data;


  // Main
  //=====

  delay #(
      .WIDTH(DATA_WIDTH),
      .DEPTH(FORWARD_DELAY)
  ) i_forward_delay (
      .clk (clk),
      .rst (rst),
      .cen (1'b1),
      //
      .din (forward_data_in),
      .dout(forward_data_out)
  );

  assign backward_data_s = LOOPBACK ? forward_data_out : backward_data_in;

  delay #(
      .WIDTH(DATA_WIDTH),
      .DEPTH(BACKWARD_DELAY)
  ) i_backward_delay (
      .clk (clk),
      .rst (rst),
      .cen (1'b1),
      //
      .din (backward_data_s),
      .dout(backward_data_out)
  );

  ram_sdp #(
      .ADDR_WIDTH  (COE_ADDR_WIDTH),
      .DATA_WIDTH  (COE_DATA_WIDTH),
      .READ_LATENCY(1),
      .INIT_WORD   ('0)
  ) i_coe_store (
      .clka (ctrl_clk),
      .ena  (ctrl_coe_en),
      .wea  (ctrl_coe_we),
      .addra(ctrl_coe_addr),
      .dina (ctrl_coe_din),
      //
      .clkb (clk),
      .rstb (rst),
      .enb  (1'b1),
      .addrb(coe_addr),
      .doutb(coe_data)
  );

  fir_mac #(
      .A_WIDTH(DATA_WIDTH),
      .B_WIDTH(COE_DATA_WIDTH),
      .D_WIDTH(DATA_WIDTH),
      .P_WIDTH(MAC_DATA_WIDTH)
  ) i_mac (
      .clk (clk),
      .a   (forward_data_in),
      .b   (coe_data),
      .d   (backward_data_out),
      .pin (mac_data_in),
      .pout(mac_data_out)
  );

  assign ctrl_coe_dout = {COE_DATA_WIDTH{ctrl_rst & 1'b0}};

endmodule

`default_nettype wire
