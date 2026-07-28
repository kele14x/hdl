// File: fir2.sv
// Brief:  Semi-Parallel Systolic transposed architecture FIR Filter. It accepts
//         input at lower sample rate than system clock frequency, and use MACC
//         structure to perform resource share.
`timescale 1 ns / 1 ps
//
`default_nettype none

module fir2 #(
    // Clock frequency to sample rate ratio, must be larger or equal to 2
    parameter int CSR_SUPPORT    = 16,
    // Number of process stages, M
    parameter int NUM_STAGES     = 4,
    // Bit width of input and output data
    parameter int DATA_WIDTH     = 16,
    // Bit width of coefficients
    parameter int COE_DATA_WIDTH = 16,
    // Shift bits at output
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


  // Check parameters
  //=================

  initial begin
    assert (CSR_SUPPORT >= 2)
    else begin
      $fatal(1,
          "[%m]: Clock frequency to sample rate ratio (CSR_SUPPORT) should be larger or equal to 2, got %d",
          CSR_SUPPORT);
    end
  end


  // Local parameters
  //=================

  localparam int CoeAddrWidth = $clog2(NUM_STAGES) + $clog2(CSR_SUPPORT);
  localparam int MacDataWidth = DATA_WIDTH + COE_DATA_WIDTH + CoeAddrWidth;

  localparam int StageAddrWidth = $clog2(CSR_SUPPORT);


  // Signals
  //========

  // Input register
  logic signed [        DATA_WIDTH-1:0] data_r;
  logic                                 data_valid_r;

  // Sync delay line
  logic                                 sync_s          [NUM_STAGES+1];

  // Forward data delay line
  logic signed [        DATA_WIDTH-1:0] forward_data_s  [NUM_STAGES+1];

  // Backward data delay line
  logic signed [        DATA_WIDTH-1:0] backward_data_s [NUM_STAGES+1];

  // MAC cascade
  logic signed [      MacDataWidth-1:0] mac_data_s      [NUM_STAGES+1];

  logic                                 data_valid_d;

  // Per stage ctrl_coe_* signals
  logic        [    StageAddrWidth-1:0] ctrl_coe_addr_l;
  logic        [$clog2(NUM_STAGES)-1:0] ctrl_coe_addr_h;
  logic                                 ctrl_coe_en_s   [  NUM_STAGES];
  logic        [    COE_DATA_WIDTH-1:0] ctrl_coe_dout_s [  NUM_STAGES];


  // Main
  //=====

  // Input register
  always_ff @(posedge clk) begin
    data_valid_r <= data_valid_in;
    data_r       <= data_in;
  end

  // Sync line
  assign sync_s[0] = data_valid_r;

  // Forward delay line
  assign forward_data_s[0] = data_r;

  // Backward delay line
  assign backward_data_s[NUM_STAGES] = '0;

  // Cascade MAC data
  assign mac_data_s[NUM_STAGES] = (1 <<< (SRA_BITS - 1));

  // Stages

  generate
    for (genvar i = 0; i < NUM_STAGES; i++) begin : g_stage

      assign ctrl_coe_en_s[i] = ctrl_coe_en && (ctrl_coe_addr_h == i);

      fir2_stage #(
          .ADDR_WIDTH    (StageAddrWidth),
          .DATA_WIDTH    (DATA_WIDTH),
          .COE_DATA_WIDTH(COE_DATA_WIDTH),
          .MAC_DATA_WIDTH(MacDataWidth)
      ) i_stage (
          .clk              (clk),
          .rst              (rst),
          //
          .sync_in          (sync_s[i]),
          .sync_out         (sync_s[i+1]),
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
          .ctrl_loop_back   (i == NUM_STAGES - 1),
          .ctrl_odd_tap     (1'b0),
          //
          .ctrl_coe_en      (ctrl_coe_en_s[i]),
          .ctrl_coe_we      (ctrl_coe_we),
          .ctrl_coe_addr    (ctrl_coe_addr_l),
          .ctrl_coe_din     (ctrl_coe_din),
          .ctrl_coe_dout    (ctrl_coe_dout_s[i])
      );

    end
  endgenerate

  // Output

  delay #(
      .WIDTH(1),
      .DEPTH(6)
  ) i_sync_delay (
      .clk (clk),
      .rst (rst),
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
      data_out <= mac_data_s[0][DATA_WIDTH+SRA_BITS-1:SRA_BITS];
    end
  end

  generate
    if (DATA_WIDTH + SRA_BITS >= MacDataWidth) begin : g_no_ovf

      // Output is full width, no overflow will happen
      assign ovf = 'b0;

    end else begin : g_ovf

      always_ff @(posedge clk) begin
        ovf <= ~(&mac_data_s[0][MacDataWidth-1:DATA_WIDTH+SRA_BITS-1] ||
                 &(~mac_data_s[0][MacDataWidth-1:DATA_WIDTH+SRA_BITS-1]));
      end

    end
  endgenerate

  // Coefficients configuration

  assign ctrl_coe_addr_l = ctrl_coe_addr[StageAddrWidth-1:0];
  assign ctrl_coe_addr_h = ctrl_coe_addr[CoeAddrWidth-1:StageAddrWidth];
  assign ctrl_coe_dout   = ctrl_coe_dout_s[ctrl_coe_addr_h];

endmodule

`default_nettype wire
