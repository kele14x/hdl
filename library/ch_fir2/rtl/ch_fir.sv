// File: ch_fir.sv
// Brief: Channel filter
`timescale 1 ns / 1 ps
//
`default_nettype none

module ch_fir #(
    parameter int CSR_SUPPORT    = 4,
    parameter int NUM_STAGES     = 2,
    parameter int DATA_WIDTH     = 16,
    parameter int COE_DATA_WIDTH = 16,
    parameter int SRA_BITS       = 15
) (
    input var                                                      clk,
    input var                                                      rst,
    //
    input var  signed [                            DATA_WIDTH-1:0] data_in,
    input var                                                      data_valid_in,
    //
    output var signed [                            DATA_WIDTH-1:0] data_out,
    output var                                                     data_valid_out,
    // Control signals
    //----------------
    input var                                                      ctrl_clk,
    input var                                                      ctrl_rst,
    // Coefficient memory
    input var                                                      ctrl_coe_en,
    input var                                                      ctrl_coe_we,
    input var         [$clog2(NUM_STAGES)+$clog2(CSR_SUPPORT)-1:0] ctrl_coe_addr,
    input var         [                        COE_DATA_WIDTH-1:0] ctrl_coe_din,
    output var        [                        COE_DATA_WIDTH-1:0] ctrl_coe_dout
);

  // Local parameters
  //=================

  localparam int CoeAddrWidth = $clog2(NUM_STAGES) + $clog2(CSR_SUPPORT);
  localparam int MacDataWidth = DATA_WIDTH + COE_DATA_WIDTH + $clog2(NUM_STAGES) + $clog2(CSR_SUPPORT);

  localparam int CoeAddrWidthStage = $clog2(CSR_SUPPORT);

  // Signals
  //========

  // Per stage ctrl_coe_* signals
  logic        [ CoeAddrWidthStage-1:0] ctrl_coe_addr_l;
  logic        [$clog2(NUM_STAGES)-1:0] ctrl_coe_addr_h;
  logic                                 ctrl_coe_en_s        [  NUM_STAGES];

  // Data delay line
  logic signed [        DATA_WIDTH-1:0] forward_data_s       [NUM_STAGES+1];
  logic                                 forward_data_valid_s [NUM_STAGES+1];

  logic signed [        DATA_WIDTH-1:0] backward_data_s      [NUM_STAGES+1];
  logic                                 backward_data_valid_s[NUM_STAGES+1];

  // MAC cascade
  logic signed [      MacDataWidth-1:0] mac_s                [NUM_STAGES+1];


  // Main
  //=====

  // Stages

  assign forward_data_s[0] = data_in;
  assign forward_data_valid_s[0] = data_valid_in;


  // TODO:
  assign backward_data_s[NUM_STAGES] = '0;
  assign backward_data_valid_s[NUM_STAGES] = 1'b0;

  assign mac_s[0] = (1 <<< (SRA_BITS - 1));

  assign ctrl_coe_addr_l = ctrl_coe_addr[CoeAddrWidthStage-1:0];
  assign ctrl_coe_addr_h = ctrl_coe_addr[CoeAddrWidth-1:CoeAddrWidthStage];

  generate
    for (genvar i = 0; i < NUM_STAGES; i++) begin : g_stage

      assign ctrl_coe_en_s[i] = ctrl_coe_en && (ctrl_coe_addr_h == i);

      ch_fir_stage #(
          .CSR_SUPPORT   (CSR_SUPPORT),
          .COE_ADDR_WIDTH(CoeAddrWidthStage),
          .COE_DATA_WIDTH(COE_DATA_WIDTH),
          .DATA_WIDTH    (DATA_WIDTH),
          .MAC_DATA_WIDTH(MacDataWidth)
      ) i_stage (
          .clk                    (clk),
          .rst                    (rst),
          //
          .data_forward_in        (forward_data_s[i]),
          .data_forward_in_valid  (forward_data_valid_s[i]),
          //
          .data_forward_out       (forward_data_s[i+1]),
          .data_forward_out_valid (forward_data_valid_s[i+1]),
          //
          .data_backward_in       (backward_data_s[i+1]),
          .data_backward_in_valid (backward_data_valid_s[i+1]),
          //
          .data_backward_out      (backward_data_s[i]),
          .data_backward_out_valid(backward_data_valid_s[i]),
          //
          .data_mac_in            (mac_s[i]),
          .data_mac_out           (mac_s[i+1]),
          //
          .ctrl_clk               (ctrl_clk),
          .ctrl_rst               (ctrl_rst),
          //
          .ctrl_loopback          (i == NUM_STAGES - 1),
          //
          .ctrl_coe_en            (ctrl_coe_en_s[i]),
          .ctrl_coe_we            (ctrl_coe_we),
          .ctrl_coe_addr          (ctrl_coe_addr_l),
          .ctrl_coe_din           (ctrl_coe_din),
          .ctrl_coe_dout          (  /* not used */)
      );

    end
  endgenerate

  always_ff @(posedge clk) begin
    data_out <= mac_s[NUM_STAGES][DATA_WIDTH+SRA_BITS-1:SRA_BITS];
  end

endmodule

`default_nettype wire
