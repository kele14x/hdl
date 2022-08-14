// File: ch_fir.sv
// Brief: Channel filter
`timescale 1 ns / 1 ps
//
`default_nettype none

module ch_fir #(
    parameter int CHANNEL_SUPPORT = 4,
    parameter int NUM_STAGES      = 64,
    parameter int DATA_WIDTH      = 16,
    parameter int COE_DATA_WIDTH  = 16,
    parameter int SRA_BITS        = 15
) (
    input var                                                          clk,
    input var                                                          rst,
    //
    input var  signed [                                DATA_WIDTH-1:0] data_in,
    input var                                                          data_sync_in,
    //
    output var signed [                                DATA_WIDTH-1:0] data_out,
    output var                                                         data_sync_out,
    // Control signals
    //----------------
    input var                                                          ctrl_clk,
    input var                                                          ctrl_rst,
    // Coefficient memory
    input var                                                          ctrl_coe_en,
    input var                                                          ctrl_coe_we,
    input var         [$clog2(NUM_STAGES)+$clog2(CHANNEL_SUPPORT)-1:0] ctrl_coe_addr,
    input var         [                            COE_DATA_WIDTH-1:0] ctrl_coe_din,
    output var        [                            COE_DATA_WIDTH-1:0] ctrl_coe_dout
);

  // Local parameters
  //=================

  localparam int CoeAddrWidth = $clog2(NUM_STAGES) + $clog2(CHANNEL_SUPPORT);
  localparam int MacDataWidth = DATA_WIDTH + COE_DATA_WIDTH + $clog2(NUM_STAGES);

  localparam int CoeAddrWidthStage = $clog2(CHANNEL_SUPPORT);

  // Signals
  //========

  logic signed [        DATA_WIDTH-1:0] data_in_reg;
  logic        [ CoeAddrWidthStage-1:0] coe_addr        [  NUM_STAGES];

  logic        [ CoeAddrWidthStage-1:0] ctrl_coe_addr_l;
  logic        [$clog2(NUM_STAGES)-1:0] ctrl_coe_addr_h;
  logic                                 ctrl_coe_en_s   [  NUM_STAGES];

  // Data delay line
  logic signed [        DATA_WIDTH-1:0] forward_data_s  [NUM_STAGES+1];
  logic signed [        DATA_WIDTH-1:0] backward_data_s [NUM_STAGES+1];

  // Coefficients
  logic signed [    COE_DATA_WIDTH-1:0] coe_s           [  NUM_STAGES];

  // MAC cascade
  logic signed [      MacDataWidth-1:0] mac_s           [NUM_STAGES+1];


  // Main
  //=====

  // Reverse delay line

  always_ff @(posedge clk) begin
    data_in_reg <= data_in;
  end

  always_ff @(posedge clk) begin
    if (data_sync_in) begin
      coe_addr[0] <= 0;
    end else begin
      coe_addr[0] <= coe_addr[0] + 1;
    end
    for (int i = 1; i < NUM_STAGES; i++) begin
      coe_addr[i] <= coe_addr[i-1];
    end
  end

  // Stages

  assign forward_data_s[0] = data_in_reg;

  assign mac_s[0] = (1 <<< (SRA_BITS - 1));

  assign ctrl_coe_addr_l = ctrl_coe_addr[CoeAddrWidthStage-1:0];
  assign ctrl_coe_addr_h = ctrl_coe_addr[CoeAddrWidth-1:CoeAddrWidthStage];

  generate
    for (genvar i = 0; i < NUM_STAGES; i++) begin : g_stage

      assign ctrl_coe_en_s[i] = ctrl_coe_en && (ctrl_coe_addr_h == i);

      ch_fir_stage #(
          .COE_ADDR_WIDTH(CoeAddrWidthStage),
          .COE_DATA_WIDTH(COE_DATA_WIDTH),
          .DATA_WIDTH    (DATA_WIDTH),
          .MAC_DATA_WIDTH(MacDataWidth)
      ) i_stage (
          .clk                (clk),
          .rst                (rst),
          //
          .coe_addr           (coe_addr[i]),
          //
          .data_forward_in    (forward_data_s[i]),
          .data_forward_out   (forward_data_s[i+1]),
          //
          .data_backward_in   (backward_data_s[i+1]),
          .data_backward_out  (backward_data_s[i]),
          //
          .data_mac_in        (mac_s[i]),
          .data_mac_out       (mac_s[i+1]),
          //
          .ctrl_clk           (ctrl_clk),
          .ctrl_rst           (ctrl_rst),
          //
          .ctrl_forward_delay (4'd3),
          .ctrl_backward_delay(4'd1),
          .ctrl_loopback      (i == NUM_STAGES - 1),
          //
          .ctrl_coe_en        (ctrl_coe_en_s[i]),
          .ctrl_coe_we        (ctrl_coe_we),
          .ctrl_coe_addr      (ctrl_coe_addr_l),
          .ctrl_coe_din       (ctrl_coe_din),
          .ctrl_coe_dout      (  /* not used */)
      );

    end
  endgenerate

  always_ff @(posedge clk) begin
    data_out <= mac_s[NUM_STAGES][DATA_WIDTH+SRA_BITS-1:SRA_BITS];
  end

endmodule

`default_nettype wire
