// File: fir2_stage.sv
// Brief: Multiplier at each stage for ch_fir module.
`timescale 1 ns / 1 ps
//
`default_nettype none

module fir2_stage #(
    parameter bit HAS_OP         = 0,
    //
    parameter int ADDR_WIDTH     = 4,
    parameter int DATA_WIDTH     = 16,
    //
    parameter int COE_DATA_WIDTH = 16,
    //
    parameter int MAC_DATA_WIDTH = 33
) (
    input var                              clk,
    input var                              rst,
    //
    input var  signed [    DATA_WIDTH-1:0] forward_data_in,
    input var                              forward_data_valid_in,
    //
    output var signed [    DATA_WIDTH-1:0] forward_data_out,
    output var                             forward_data_valid_out,
    //
    input var  signed [    DATA_WIDTH-1:0] backward_data_in,
    input var                              backward_data_valid_in,
    //
    output var signed [    DATA_WIDTH-1:0] backward_data_out,
    output var                             backward_data_valid_out,
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
    input var         [    ADDR_WIDTH-1:0] ctrl_coe_addr,
    input var         [COE_DATA_WIDTH-1:0] ctrl_coe_din,
    output var        [COE_DATA_WIDTH-1:0] ctrl_coe_dout
);


  // Local parameters
  //=================


  // Signals
  //========

  logic                             fds_we;
  logic        [    ADDR_WIDTH-1:0] fds_addr;
  logic        [    DATA_WIDTH-1:0] fds_din;
  logic        [    DATA_WIDTH-1:0] fds_dout;

  logic        [    ADDR_WIDTH-1:0] state;

  logic        [    ADDR_WIDTH-1:0] coe_addr;
  logic signed [COE_DATA_WIDTH-1:0] coe_data;

  logic signed [    DATA_WIDTH-1:0] backward_data_s;

  logic                             op;
  logic                             op_d;
  logic                             op_dd;


  // Main
  //=====

  always_ff @(posedge clk) begin
    if (rst) begin
      state <= '0;
    end else if (forward_data_valid_in) begin
      state <= '0;
    end else begin
      state <= state + 1;
    end
  end

  // Forward data store

  assign fds_we  = forward_data_valid_in;
  assign fds_din = forward_data_in;

  always_ff @(posedge clk) begin
    if (rst) begin
      fds_addr <= '0;
    end else if (fds_addr == 2 ** ADDR_WIDTH - 2) begin
      fds_addr <= '0;
    end else begin
      fds_addr <= fds_addr + 1;
    end
  end

  ram_sp #(
      .ADDR_WIDTH  (ADDR_WIDTH),
      .DATA_WIDTH  (DATA_WIDTH),
      .READ_LATENCY(1),
      .INIT_WORD   ('0)
  ) i_forward_data_store (
      .clk (clk),
      .rst (1'b0),
      .en  (1'b1),
      .we  (fds_we),
      .addr(fds_addr),
      .din (fds_din),
      .dout(fds_dout)
  );

  always_ff @(posedge clk) begin
    if (forward_data_valid_out) begin
      forward_data_out <= fds_dout;
    end
  end

  always_ff @(posedge clk) begin
    forward_data_valid_out <= forward_data_valid_in;
  end

  // Backward data store

  // TODO: add backward data store and output logic

  assign backward_data_out = backward_data_in;
  assign backward_data_valid_out = backward_data_valid_in;

  // Coefficients store

  always_ff @(posedge clk) begin
    if (rst) begin
      coe_addr <= '0;
    end else if (forward_data_valid_in) begin
      coe_addr <= 2 ** ADDR_WIDTH - 1;
    end else begin
      coe_addr <= coe_addr - 1;
    end
  end

  ram_sdp #(
      .ADDR_WIDTH  (ADDR_WIDTH),
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
      .rstb (1'b0),
      .enb  (1'b1),
      .addrb(coe_addr),
      .doutb(coe_data)
  );


  // MAC

  generate
    if (HAS_OP) begin : g_op

      assign op = !(state == 0);

      always_ff @(posedge clk) begin
        op_d <= op;
        op_dd <= op_d;
      end

    end else begin : g_no_op

      assign op = 1'b0;
      assign op_d = 1'b0;
      assign op_dd = 1'b0;

    end
  endgenerate

  fir2_mac #(
      .A_WIDTH(DATA_WIDTH),
      .B_WIDTH(COE_DATA_WIDTH),
      .D_WIDTH(DATA_WIDTH),
      .P_WIDTH(MAC_DATA_WIDTH)
  ) i_mac (
      .clk (clk),
      .a   (fds_dout),
      .b   (coe_data),
      .d   (backward_data_in),
      .op  (op_dd),
      .pin (mac_data_in),
      .pout(mac_data_out)
  );

endmodule

`default_nettype wire
