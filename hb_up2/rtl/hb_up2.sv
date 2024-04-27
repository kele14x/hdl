// File: hb_up2.sv
// Brief: Half band up-sample by 2.
`timescale 1 ns / 1 ps
//
`default_nettype none

module hb_up2 #(
    // Number of interleaved channels
    parameter int NUM_CHANNELS   = 16,
    // Number of MAC stages
    parameter int NUM_STAGES     = 5,
    // Bit width of input and output data
    parameter int DATA_WIDTH     = 16,
    // Bit width of coefficient sets index address
    parameter int COE_ADDR_WIDTH = 3,
    // Bit width of coefficients
    parameter int COE_DATA_WIDTH = 16,
    // Shift bits at output
    parameter int SRA_BITS       = 15
) (
    input var                                                 clk,
    input var                                                 rst,
    //
    input var  signed [                       DATA_WIDTH-1:0] data_in,
    input var                                                 data_sync_in,
    //
    output var signed [                       DATA_WIDTH-1:0] data_p0_out,
    output var signed [                       DATA_WIDTH-1:0] data_p1_out,
    output var                                                data_sync_out,
    //
    output var                                                ovf,
    // Control interface
    //==================
    input var                                                 ctrl_clk,
    input var                                                 ctrl_rst,
    // Coefficient memory
    input var                                                 ctrl_coe_en,
    input var                                                 ctrl_coe_we,
    input var         [$clog2(NUM_STAGES)+COE_ADDR_WIDTH-1:0] ctrl_coe_addr,
    input var         [                   COE_DATA_WIDTH-1:0] ctrl_coe_din,
    output var        [                   COE_DATA_WIDTH-1:0] ctrl_coe_dout
);

  // Local parameter
  //================

  // First sample to first sample latency
  localparam int Latency = 7;

  // Impulse latency
  localparam int ImpulseLatency = NUM_CHANNELS * NUM_STAGES + Latency;


  // Main
  //=====

  shift_regs #(
      .DATA_WIDTH(DATA_WIDTH),
      .DEPTH     (ImpulseLatency)
  ) i_p0_delay (
      .clk (clk),
      .cen (1'b1),
      //
      .din (data_in),
      .dout(data_p0_out)
  );

  fir #(
      .NUM_CHANNELS  (NUM_CHANNELS),
      .NUM_STAGES    (NUM_STAGES),
      .EVEN_TAPS     (1),
      .DATA_WIDTH    (DATA_WIDTH),
      .COE_ADDR_WIDTH(COE_ADDR_WIDTH),
      .COE_DATA_WIDTH(COE_DATA_WIDTH),
      .SRA_BITS      (SRA_BITS)
  ) i_fir (
      .clk          (clk),
      .rst          (rst),
      //
      .data_in      (data_in),
      .data_sync_in (data_sync_in),
      //
      .data_out     (data_p1_out),
      .data_sync_out(data_sync_out),
      //
      .ovf          (ovf),
      // Control signals
      //----------------
      .ctrl_clk     (ctrl_clk),
      .ctrl_rst     (ctrl_rst),
      // Coefficient memory
      .ctrl_coe_en  (ctrl_coe_en),
      .ctrl_coe_we  (ctrl_coe_we),
      .ctrl_coe_addr(ctrl_coe_addr),
      .ctrl_coe_din (ctrl_coe_din),
      .ctrl_coe_dout(ctrl_coe_dout)
  );

endmodule

`default_nettype wire
