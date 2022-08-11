// File: ch_fir.sv
// Brief: Channel filter
`timescale 1 ns / 1 ps
//
`default_nettype none

module ch_fir #(
    parameter int CSR_SUPPORT       = 4,
    parameter int NUM_STAGES        = 4,
    //
    parameter int INPUT_DATA_WIDTH  = 16,
    parameter int OUTPUT_DATA_WIDTH = 16,
    //
    parameter int COE_DATA_WIDTH    = 16,
    //
    parameter int SRA_BITS          = 15
) (
    input var                                  clk,
    input var                                  rst,
    //
    input var  signed [  INPUT_DATA_WIDTH-1:0] data_in,
    output var signed [ OUTPUT_DATA_WIDTH-1:0] data_out,
    // Control signals
    //----------------
    input var                                  ctrl_clk,
    input var                                  ctrl_rst,
    // Coefficient memory
    input var                                  ctrl_coe_en,
    input var                                  ctrl_coe_we,
    input var         [$clog2(NUM_STAGES)-1:0] ctrl_coe_addr,
    input var         [    COE_DATA_WIDTH-1:0] ctrl_coe_data_in,
    output var        [    COE_DATA_WIDTH-1:0] ctrl_coe_data_out
);

  // Local parameters
  //=================

  localparam int CoeAddrWidth = $clog2(NUM_STAGES);
  localparam int PWidth = INPUT_DATA_WIDTH + COE_DATA_WIDTH + $clog2(NUM_STAGES);
  localparam int DelayTaps = NUM_STAGES * 4 + 1;

  // Signals
  //========

  // Data delay line
  logic signed [INPUT_DATA_WIDTH-1:0] data_s[DelayTaps];

  logic signed [COE_DATA_WIDTH-1:0] coe_s[NUM_STAGES];

  // MAC cascade
  logic signed [PWidth-1:0] mac_s[NUM_STAGES+1];


  // Main
  //=====

  // Data delay line

  always_ff @(posedge clk) begin
    data_s[0] <= data_in;
  end

  always_ff @(posedge clk) begin
    for (int i = 1; i < DelayTaps; i++) begin
      data_s[i] <= data_s[i-1];
    end
  end

  // Coefficients Store

  ch_fir_coe #(
      .COE_ADDR_WIDTH(CoeAddrWidth),
      .COE_DATA_WIDTH(COE_DATA_WIDTH)
  ) i_coe_store (
      .clk              (clk),
      .rst              (rst),
      .coe_out          (coe_s),
      // Control signals
      //----------------
      .ctrl_clk         (ctrl_clk),
      .ctrl_rst         (ctrl_rst),
      // Coefficient memory
      .ctrl_coe_en      (ctrl_coe_en),
      .ctrl_coe_we      (ctrl_coe_we),
      .ctrl_coe_addr    (ctrl_coe_addr),
      .ctrl_coe_data_in (ctrl_coe_data_in),
      .ctrl_coe_data_out(ctrl_coe_data_out)
  );


  // Stages

  assign mac_s[0] = (1 <<< (SRA_BITS - 1));

  generate
    for (genvar i = 0; i < NUM_STAGES; i = i + 1) begin : g_stage


      ch_fir_stage #(
          .A_WIDTH(INPUT_DATA_WIDTH),
          .B_WIDTH(COE_DATA_WIDTH),
          .D_WIDTH(INPUT_DATA_WIDTH),
          .P_WIDTH(PWidth)
      ) i_stage (
          .clk (clk),
          .a   (data_s[4*i]),
          .b   (coe_s[i]),
          .d   (data_s[DelayTaps - 4*i - 1]),
          .pin (mac_s[i]),
          .pout(mac_s[i+1])
      );

    end
  endgenerate

  always_ff @(posedge clk) begin
    data_out <= mac_s[NUM_STAGES][OUTPUT_DATA_WIDTH+SRA_BITS-1:SRA_BITS];
  end

endmodule

`default_nettype wire
