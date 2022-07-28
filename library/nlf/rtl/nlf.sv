// File: nlf.sv
// Brief: Nonlinear Filter
`timescale 1 ns / 1 ps
//
`default_nettype none

module nlf #(
    parameter int NUM_UNITS      = 16,
    parameter int DATA_WIDTH     = 16,
    parameter int DELAY_WIDTH    = 5,
    parameter int INDEX_WIDTH    = 8,
    parameter int LUT_DATA_WIDTH = 16,
    parameter int SRA_BITS       = 14
) (
    input var                                           clk,
    input var                                           rst,
    //
    input var  signed [                 DATA_WIDTH-1:0] data_i_in,
    input var  signed [                 DATA_WIDTH-1:0] data_q_in,
    //
    input var         [                INDEX_WIDTH-1:0] index_in,
    //
    output var signed [                 DATA_WIDTH-1:0] data_i_out,
    output var signed [                 DATA_WIDTH-1:0] data_q_out,
    // Overflow indicator
    output var                                          ovf,
    // Control Interface
    //==================
    input var                                           ctrl_clk,
    input var                                           ctrl_rst,
    //
    input var                                           ctrl_bank,
    //
    input var         [                DELAY_WIDTH-1:0] ctrl_index_delay [NUM_UNITS],
    input var         [                DELAY_WIDTH-1:0] ctrl_signal_delay[NUM_UNITS],
    //
    input var         [$clog2(NUM_UNITS)+INDEX_WIDTH:0] ctrl_lut_addr,
    input var                                           ctrl_lut_en,
    input var                                           ctrl_lut_we,
    input var         [           LUT_DATA_WIDTH*2-1:0] ctrl_lut_din,
    output var        [           LUT_DATA_WIDTH*2-1:0] ctrl_lut_dout
);


  logic                                bank_s;
  logic                                bank_dly               [NUM_UNITS];


  logic        [      INDEX_WIDTH-1:0] index_d                [NUM_UNITS];

  logic        [     DATA_WIDTH*2-1:0] signal_in;
  logic        [     DATA_WIDTH*2-1:0] signal_s;

  logic        [     DATA_WIDTH*2-1:0] signal_d               [NUM_UNITS];
  logic signed [       DATA_WIDTH-1:0] data_i_d               [NUM_UNITS];
  logic signed [       DATA_WIDTH-1:0] data_q_d               [NUM_UNITS];

  logic        [$clog2(NUM_UNITS)-1:0] ctrl_lut_addr_unit;
  logic        [$clog2(NUM_UNITS)-1:0] ctrl_lut_addr_unit_mux;

  logic        [        INDEX_WIDTH:0] ctrl_lut_addr_s        [NUM_UNITS];
  logic                                ctrl_lut_en_s          [NUM_UNITS];
  logic                                ctrl_lut_we_s          [NUM_UNITS];
  logic        [ LUT_DATA_WIDTH*2-1:0] ctrl_lut_din_s         [NUM_UNITS];
  logic        [ LUT_DATA_WIDTH*2-1:0] ctrl_lut_dout_s        [NUM_UNITS];


  // LUT Bank Selector
  //==================

  cdc_array_single #(
      .DEST_SYNC_FF  (4),
      .INIT_SYNC_FF  (0),
      .SRC_INPUT_REG (0),
      .WIDTH         (1)
  ) cdc_ctrl_bank (
      .src_clk (ctrl_clk),
      .src_in  (ctrl_bank),
      .dest_clk(clk),
      .dest_out(bank_s)
  );

  always @(posedge clk) begin
    bank_dly[0] <= bank_s;
    for (int i = 1; i < NUM_UNITS; i = i + 1) begin
      bank_dly[i] <= bank_dly[i-1];
    end
  end


  // Index Generation
  //=================

  nlf_delay_line #(
      .NUM_UNITS  (NUM_UNITS),
      .DELAY_WIDTH(DELAY_WIDTH),
      .DATA_WIDTH (INDEX_WIDTH)
  ) i_index_delay_line (
      // Read Interface
      .clk     (clk),
      //
      .data_in (index_in),
      .data_out(index_d),
      //
      .delay   (ctrl_index_delay)
  );


  // Signal Delay
  //=============

  assign signal_in = {data_q_in, data_i_in};

  // Add 3 taps delay since LUT adds 3 ticks latency
  shift_regs #(
      .DATA_WIDTH (DATA_WIDTH * 2),
      .DEPTH      (3)
  ) i_shift_regs (
      .clk (clk),
      .cen (1'b1),
      .din (signal_in),
      .dout(signal_s)
  );

  nlf_delay_line #(
      .NUM_UNITS  (NUM_UNITS),
      .DELAY_WIDTH(DELAY_WIDTH),
      .DATA_WIDTH (DATA_WIDTH * 2)
  ) i_signal_delay_line (
      // Read Interface
      .clk     (clk),
      //
      .data_in (signal_s),
      .data_out(signal_d),
      //
      .delay   (ctrl_signal_delay)
  );

  generate
    for (genvar i = 0; i < NUM_UNITS; i++) begin : g_signal
      assign {data_q_d[i], data_i_d[i]} = signal_d[i];
    end
  endgenerate


  nlf_core #(
      .NUM_UNITS     (NUM_UNITS),
      .DATA_WIDTH    (DATA_WIDTH),
      .INDEX_WIDTH   (INDEX_WIDTH),
      .LUT_DATA_WIDTH(LUT_DATA_WIDTH),
      .SRA_BITS      (SRA_BITS)
  ) i_core (
      // Read Interface
      .clk          (clk),
      .rst          (rst),
      //
      .bank_in      (bank_dly),
      .index_in     (index_d),
      //
      .data_i_in    (data_i_d),
      .data_q_in    (data_q_d),
      //
      .data_i_out   (data_i_out),
      .data_q_out   (data_q_out),
      //
      .ovf          (ovf),
      //
      .ctrl_clk     (ctrl_clk),
      .ctrl_rst     (ctrl_rst),
      //
      .ctrl_lut_addr(ctrl_lut_addr_s),
      .ctrl_lut_en  (ctrl_lut_en_s),
      .ctrl_lut_we  (ctrl_lut_we_s),
      .ctrl_lut_din (ctrl_lut_din_s),
      .ctrl_lut_dout(ctrl_lut_dout_s)
  );

  assign ctrl_lut_addr_unit = ctrl_lut_addr[$clog2(NUM_UNITS)+INDEX_WIDTH:INDEX_WIDTH+1];

  generate
    genvar i;
    for (i = 0; i < NUM_UNITS; i = i + 1) begin : g_lut_mux

      // ctrl_lut_addr is composed by {unit, bank, index}
      // ctrl_lut_addr_s is composed by {bank, index}
      assign ctrl_lut_addr_s[i] = ctrl_lut_addr[INDEX_WIDTH:0];

      assign ctrl_lut_en_s[i]   = (ctrl_lut_addr_unit == i) && ctrl_lut_en;
      assign ctrl_lut_we_s[i]   = (ctrl_lut_addr_unit == i) && ctrl_lut_we;
      assign ctrl_lut_din_s[i]  = ctrl_lut_din;

    end
  endgenerate

  always @(posedge ctrl_clk) begin
    if (ctrl_lut_en) begin
      ctrl_lut_addr_unit_mux <= ctrl_lut_addr_unit;
    end
  end

  assign ctrl_lut_dout = ctrl_lut_dout_s[ctrl_lut_addr_unit_mux];

endmodule

`default_nettype wire
