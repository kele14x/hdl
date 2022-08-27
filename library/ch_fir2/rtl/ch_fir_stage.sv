
// File: ch_fir_stage.sv
// Brief: Multiplier at each stage for ch_fir module.
`timescale 1 ns / 1 ps
//
`default_nettype none

module ch_fir_stage #(
    parameter int CSR_SUPPORT    = 4,
    //
    parameter int COE_ADDR_WIDTH = 4,
    parameter int COE_DATA_WIDTH = 16,
    //
    parameter int DATA_WIDTH     = 16,
    parameter int MAC_DATA_WIDTH = 33
) (
    input var                              clk,
    input var                              rst,
    //
    input var  signed [    DATA_WIDTH-1:0] data_forward_in,
    input var                              data_forward_in_valid,
    //
    output var signed [    DATA_WIDTH-1:0] data_forward_out,
    output var                             data_forward_out_valid,
    //
    input var  signed [    DATA_WIDTH-1:0] data_backward_in,
    input var                              data_backward_in_valid,
    //
    output var signed [    DATA_WIDTH-1:0] data_backward_out,
    output var                             data_backward_out_valid,
    //
    input var  signed [MAC_DATA_WIDTH-1:0] data_mac_in,
    output var signed [MAC_DATA_WIDTH-1:0] data_mac_out,
    // Control interface
    //==================
    input var                              ctrl_clk,
    input var                              ctrl_rst,
    //
    input var                              ctrl_loopback,
    //
    input var                              ctrl_coe_en,
    input var                              ctrl_coe_we,
    input var         [COE_ADDR_WIDTH-1:0] ctrl_coe_addr,
    input var         [COE_DATA_WIDTH-1:0] ctrl_coe_din,
    output var        [COE_DATA_WIDTH-1:0] ctrl_coe_dout
);


  // Local parameters
  //=================

  localparam int DataStoreAddrWidth = $clog2(CSR_SUPPORT);


  // Signals
  //========

  logic                                    fds_en;
  logic                                    fds_we;
  logic        [   DataStoreAddrWidth-1:0] fds_addr;
  logic        [           DATA_WIDTH-1:0] fds_din;
  logic        [           DATA_WIDTH-1:0] fds_dout;

  logic        [$clog2(CSR_SUPPORT) - 1:0] state;

  logic        [       COE_ADDR_WIDTH-1:0] coe_addr;
  logic signed [       COE_DATA_WIDTH-1:0] coe_data;

  logic signed [           DATA_WIDTH-1:0] data_backward_s;

  logic                                    op;


  // Main
  //=====

  always_ff @(posedge clk) begin
    if (rst) begin
      state <= '0;
    end else if (data_forward_in_valid) begin
      state <= '0;
    end else begin
      state <= state + 1;
    end
  end


  // Forward data store

  assign fds_en  = 1'b1;
  assign fds_we  = data_forward_in_valid;
  assign fds_din = data_forward_in;

  always_ff @(posedge clk) begin
    if (rst) begin
      fds_addr <= '0;
    end else if (data_forward_in_valid) begin
      if (fds_addr == CSR_SUPPORT - 2) begin
        fds_addr <= '0;
      end else begin
        fds_addr <= fds_addr + 1;
      end
    end
  end

  ram_sp #(
      .ADDR_WIDTH  (DataStoreAddrWidth),
      .DATA_WIDTH  (DATA_WIDTH),
      .READ_LATENCY(1),
      .INIT_WORD   ('0)
  ) i_forward_data_store (
      .clk (clk),
      .rst (rst),
      .en  (fds_en),
      .we  (fds_we),
      .addr(fds_addr),
      .din (fds_din),
      .dout(fds_dout)
  );


  always_ff @(posedge clk) begin
    if (fds_we) begin
      data_forward_out <= fds_dout;
    end
  end

  always_ff @(posedge clk) begin
    data_forward_out_valid <= (state == CSR_SUPPORT - 1);
  end

  // Backward data store

  // TODO:


  // Coefficients store

  always_ff @(posedge clk) begin
    coe_addr <= CSR_SUPPORT - state;
  end

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


  // MAC

  always_ff @(posedge clk) begin
    op <= (state == 0);
  end

  ch_fir_mac #(
      .A_WIDTH(DATA_WIDTH),
      .B_WIDTH(COE_DATA_WIDTH),
      .D_WIDTH(DATA_WIDTH),
      .P_WIDTH(MAC_DATA_WIDTH)
  ) i_mac (
      .clk (clk),
      .a   (fds_dout),
      .b   (coe_data),
      .d   (data_backward_in),
      .op  (op),
      .pin (data_mac_in),
      .pout(data_mac_out)
  );

endmodule

`default_nettype wire
