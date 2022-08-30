// File: fir.sv
// Brief: Multichannel transport systolic architecture FIR filter.
`timescale 1 ns / 1 ps
//
`default_nettype none

module fir #(
    // Number of interleaved channels
    parameter int NUM_CHANNELS   = 16,
    // Number MAC stages
    parameter int NUM_STAGES     = 64,
    //
    parameter bit EVEN_TAPS      = 1,
    // Input and output data width
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
    output var signed [                       DATA_WIDTH-1:0] data_out,
    output var                                                data_sync_out,
    // Control signals
    //----------------
    input var                                                 ctrl_clk,
    input var                                                 ctrl_rst,
    // Coefficient memory
    input var                                                 ctrl_coe_en,
    input var                                                 ctrl_coe_we,
    input var         [$clog2(NUM_STAGES)+COE_ADDR_WIDTH-1:0] ctrl_coe_addr,
    input var         [                   COE_DATA_WIDTH-1:0] ctrl_coe_din,
    output var        [                   COE_DATA_WIDTH-1:0] ctrl_coe_dout
);

  // Local parameters
  //=================

  // From `data_sync_in` to `data_sync_out`, first sample to first sample latency
  localparam int Latency = 7;

  localparam int CoeAddrWidth = COE_ADDR_WIDTH + $clog2(NUM_STAGES);
  localparam int MacDataWidth = DATA_WIDTH + COE_DATA_WIDTH + $clog2(NUM_STAGES);


  // Signals
  //========

  logic signed [          DATA_WIDTH-1:0] data_in_d;
  logic signed [          DATA_WIDTH-1:0] data_in_dd;

  // Data delay line
  logic signed [          DATA_WIDTH-1:0] forward_data_s  [NUM_STAGES+1];
  logic signed [          DATA_WIDTH-1:0] backward_data_s [NUM_STAGES+1];

  // MAC cascade
  logic signed [        MacDataWidth-1:0] mac_data_s      [NUM_STAGES+1];

  // Channel index
  logic        [$clog2(NUM_CHANNELS)-1:0] ch_index;

  // Coefficients set selection
  logic        [      COE_ADDR_WIDTH-1:0] coe_addr        [  NUM_STAGES];

  // Coefficients configuration
  logic        [      COE_ADDR_WIDTH-1:0] ctrl_coe_addr_l;
  logic        [  $clog2(NUM_STAGES)-1:0] ctrl_coe_addr_h;
  logic                                   ctrl_coe_en_s   [  NUM_STAGES];


  // Main
  //=====

  // Forward delay line

  always_ff @(posedge clk) begin
    data_in_d  <= data_in;
    data_in_dd <= data_in_d;
  end

  assign forward_data_s[0] = data_in_dd;

  // Backward delay line

  assign backward_data_s[NUM_STAGES] = '0;

  // Channel index and coefficients set

  always_ff @(posedge clk) begin
    if (data_sync_in) begin
      ch_index <= 0;
    end else begin
      ch_index <= ch_index + 1;
    end
  end

  // TODO: add channel index to coefficients set mapping
  always_ff @(posedge clk) begin
    coe_addr[0] <= ch_index[$clog2(NUM_CHANNELS)-1-:COE_ADDR_WIDTH];
    for (int i = 1; i < NUM_STAGES; i++) begin
      coe_addr[i] <= coe_addr[i-1] - (NUM_CHANNELS - 1) / 2;
    end
  end


  // Stages

  assign mac_data_s[NUM_STAGES] = (1 <<< (SRA_BITS - 1));

  generate
    for (genvar i = 0; i < NUM_STAGES; i++) begin : g_stage

      localparam int StageForwardDelay = NUM_CHANNELS - 1;
      localparam int StageBackwardDelay = (i == NUM_STAGES - 1) ? 1 : NUM_CHANNELS + 1;
      localparam bit StageLoopback = EVEN_TAPS ? (i == NUM_STAGES - 1) : (i == NUM_STAGES - 2);

      fir_stage #(
          .FORWARD_DELAY (StageForwardDelay),
          .BACKWARD_DELAY(StageBackwardDelay),
          .LOOPBACK      (StageLoopback),
          //
          .DATA_WIDTH    (DATA_WIDTH),
          //
          .COE_ADDR_WIDTH(COE_ADDR_WIDTH),
          .COE_DATA_WIDTH(COE_DATA_WIDTH),
          //
          .MAC_DATA_WIDTH(MacDataWidth)
      ) i_stage (
          .clk              (clk),
          .rst              (rst),
          //
          .coe_addr         (coe_addr[i]),
          //
          .forward_data_in  (forward_data_s[i]),
          .forward_data_out (forward_data_s[i+1]),
          //
          .backward_data_in (backward_data_s[i+1]),
          .backward_data_out(backward_data_s[i]),
          //
          .mac_data_in      (mac_data_s[i+1]),
          .mac_data_out     (mac_data_s[i]),
          //
          .ctrl_clk         (ctrl_clk),
          .ctrl_rst         (ctrl_rst),
          //
          .ctrl_coe_en      (ctrl_coe_en_s[i]),
          .ctrl_coe_we      (ctrl_coe_we),
          .ctrl_coe_addr    (ctrl_coe_addr_l),
          .ctrl_coe_din     (ctrl_coe_din),
          .ctrl_coe_dout    (  /* not used */)
      );

      assign ctrl_coe_en_s[i] = ctrl_coe_en && (ctrl_coe_addr_h == i);

    end
  endgenerate


  // Data output

  always_ff @(posedge clk) begin
    data_out <= mac_data_s[0][DATA_WIDTH+SRA_BITS-1:SRA_BITS];
  end

  shift_regs #(
      .DATA_WIDTH(1),
      .DEPTH     (7)
  ) i_sync_delay (
      .clk (clk),
      .cen (1'b1),
      //
      .din (data_sync_in),
      .dout(data_sync_out)
  );


  // Coefficients configuration

  assign ctrl_coe_addr_h = ctrl_coe_addr[CoeAddrWidth-1:COE_ADDR_WIDTH];
  assign ctrl_coe_addr_l = ctrl_coe_addr[COE_ADDR_WIDTH-1:0];

endmodule

`default_nettype wire
