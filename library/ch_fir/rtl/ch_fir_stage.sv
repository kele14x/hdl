
// File: ch_fir_stage.sv
// Brief: Multiplier at each stage for ch_fir module.
`timescale 1 ns / 1 ps
//
`default_nettype none

module ch_fir_stage #(
    parameter int COE_ADDR_WIDTH = 4,
    parameter int COE_DATA_WIDTH = 16,
    //
    parameter int DATA_WIDTH     = 16,
    parameter int MAC_DATA_WIDTH = 33
) (
    input var                              clk,
    input var                              rst,
    //
    input var         [COE_ADDR_WIDTH-1:0] coe_addr,
    //
    input var  signed [    DATA_WIDTH-1:0] data_forward_in,
    output var signed [    DATA_WIDTH-1:0] data_forward_out,
    //
    input var  signed [    DATA_WIDTH-1:0] data_backward_in,
    output var signed [    DATA_WIDTH-1:0] data_backward_out,
    //
    input var  signed [MAC_DATA_WIDTH-1:0] data_mac_in,
    output var signed [MAC_DATA_WIDTH-1:0] data_mac_out,
    // Control interface
    //==================
    input var                              ctrl_clk,
    input var                              ctrl_rst,
    //
    input var         [               3:0] ctrl_forward_delay,
    input var         [               3:0] ctrl_backward_delay,
    input var                              ctrl_loopback,
    //
    input var                              ctrl_coe_en,
    input var                              ctrl_coe_we,
    input var         [COE_ADDR_WIDTH-1:0] ctrl_coe_addr,
    input var         [COE_DATA_WIDTH-1:0] ctrl_coe_din,
    output var        [COE_DATA_WIDTH-1:0] ctrl_coe_dout
);


  logic signed [COE_DATA_WIDTH-1:0] coe_s;

  logic signed [    DATA_WIDTH-1:0] data_backward_s;

  always_comb begin
    if (ctrl_loopback == 0) begin
      data_backward_s = data_backward_in;
    end else begin
      data_backward_s = data_forward_out;
    end
  end

  srl #(
      .SIM_INIT  (1),
      .ADDR_WIDTH(4),
      .DATA_WIDTH(DATA_WIDTH)
  ) i_forward_delay (
      .clk (clk),
      .rst (1'b0),
      .cen (1'b1),
      //
      .addr(ctrl_forward_delay),
      .din (data_forward_in),
      .dout(data_forward_out)
  );

  srl #(
      .SIM_INIT  (1),
      .ADDR_WIDTH(4),
      .DATA_WIDTH(DATA_WIDTH)
  ) i_backward_delay (
      .clk (clk),
      .rst (1'b0),
      .cen (1'b1),
      //
      .addr(ctrl_backward_delay),
      .din (data_backward_s),
      .dout(data_backward_out)
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
      .doutb(coe_s)
  );

  ch_fir_mac #(
      .A_WIDTH(DATA_WIDTH),
      .B_WIDTH(COE_DATA_WIDTH),
      .D_WIDTH(DATA_WIDTH),
      .P_WIDTH(MAC_DATA_WIDTH)
  ) i_mac (
      .clk (clk),
      .a   (data_forward_in),
      .b   (coe_s),
      .d   (data_backward_in),
      .pin (data_mac_in),
      .pout(data_mac_out)
  );

endmodule

`default_nettype wire
