// File: fir2.sv
// Brief:  Semi-Parallel FIR Filter.
`timescale 1 ns / 1 ps
//
`default_nettype none

module fir2 #(
    parameter int CSR_SUPPORT    = 16,
    parameter int NUM_STAGES     = 4,
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
    //
    output var                                                     ovf,
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
  localparam int MacDataWidth = DATA_WIDTH + COE_DATA_WIDTH + CoeAddrWidth;

  localparam int StageAddrWidth = $clog2(CSR_SUPPORT);


  // Signals
  //========

  // Per stage ctrl_coe_* signals
  logic        [    StageAddrWidth-1:0] ctrl_coe_addr_l;
  logic        [$clog2(NUM_STAGES)-1:0] ctrl_coe_addr_h;
  logic                                 ctrl_coe_en_s        [  NUM_STAGES];

  // Forward data delay line
  logic signed [        DATA_WIDTH-1:0] forward_data_s       [NUM_STAGES+1];
  logic                                 forward_data_valid_s [NUM_STAGES+1];

  // Backward data delay line
  logic signed [        DATA_WIDTH-1:0] backward_data_s      [NUM_STAGES+1];
  logic                                 backward_data_valid_s[NUM_STAGES+1];

  // MAC cascade
  logic signed [      MacDataWidth-1:0] mac_data_s           [NUM_STAGES+1];
  logic                                 data_valid_d;


  // Main
  //=====

  // Forward delay line

  assign forward_data_s[0] = data_in;
  assign forward_data_valid_s[0] = data_valid_in;


  // Backward delay line

  // TODO: Connect backward delay line
  assign backward_data_s[NUM_STAGES] = '0;
  assign backward_data_valid_s[NUM_STAGES] = 1'b0;

  // Cascade MAC data
  assign mac_data_s[0] = (1 <<< (SRA_BITS - 1));

  // Stages

  generate
    for (genvar i = 0; i < NUM_STAGES; i++) begin : g_stage

      assign ctrl_coe_en_s[i] = ctrl_coe_en && (ctrl_coe_addr_h == i);

      fir2_stage #(
          .HAS_OP        (i == NUM_STAGES - 1),
          .ADDR_WIDTH    (StageAddrWidth),
          .DATA_WIDTH    (DATA_WIDTH),
          .COE_DATA_WIDTH(COE_DATA_WIDTH),
          .MAC_DATA_WIDTH(MacDataWidth)
      ) i_stage (
          .clk                    (clk),
          .rst                    (rst),
          //
          .forward_data_in        (forward_data_s[i]),
          .forward_data_valid_in  (forward_data_valid_s[i]),
          //
          .forward_data_out       (forward_data_s[i+1]),
          .forward_data_valid_out (forward_data_valid_s[i+1]),
          //
          .backward_data_in       (backward_data_s[i+1]),
          .backward_data_valid_in (backward_data_valid_s[i+1]),
          //
          .backward_data_out      (backward_data_s[i]),
          .backward_data_valid_out(backward_data_valid_s[i]),
          //
          .mac_data_in            (mac_data_s[i]),
          .mac_data_out           (mac_data_s[i+1]),
          //
          .ctrl_clk               (ctrl_clk),
          .ctrl_rst               (ctrl_rst),
          //
          .ctrl_coe_en            (ctrl_coe_en_s[i]),
          .ctrl_coe_we            (ctrl_coe_we),
          .ctrl_coe_addr          (ctrl_coe_addr_l),
          .ctrl_coe_din           (ctrl_coe_din),
          .ctrl_coe_dout          (  /* not used */)
      );

    end
  endgenerate

  // Output

  shift_regs #(
      .DATA_WIDTH(1),
      .DEPTH     (CSR_SUPPORT + NUM_STAGES + 3)
  ) i_sync_delay (
      .clk (clk),
      .cen (1'b1),
      //
      .din (data_valid_in),
      .dout(data_valid_d)
  );

  always_ff @(posedge clk) begin
    data_valid_out <= data_valid_d;
  end

  always_ff @(posedge clk) begin
    if (data_valid_d) begin
      data_out <= mac_data_s[NUM_STAGES][DATA_WIDTH+SRA_BITS-1:SRA_BITS];
    end
  end

  generate
    if (DATA_WIDTH + SRA_BITS >= MacDataWidth) begin : g_no_ovf

      // Output is full width, no overflow will happen
      assign ovf = 'b0;

    end else begin : g_ovf

      always_ff @(posedge clk) begin
        ovf <= ~(&mac_data_s[NUM_STAGES][MacDataWidth-1:DATA_WIDTH+SRA_BITS-1] ||
                 &(~mac_data_s[NUM_STAGES][MacDataWidth-1:DATA_WIDTH+SRA_BITS-1]));
      end

    end
  endgenerate

  // Coefficients configuration

  assign ctrl_coe_addr_l = ctrl_coe_addr[StageAddrWidth-1:0];
  assign ctrl_coe_addr_h = ctrl_coe_addr[CoeAddrWidth-1:StageAddrWidth];

endmodule

`default_nettype wire
