// File: nlf.sv
// Brief: Nonlinear Filter

`timescale 1 ns / 1 ps `default_nettype none

module nlf #(
    parameter int NUM_UNITS      = 16,
    parameter int DATA_WIDTH     = 16,
    parameter int INDEX_WIDTH    = 8,
    parameter int LUT_DATA_WIDTH = 16,
    parameter int SRA_BITS       = 15
) (
    input var                                           clk,
    input var                                           rst,
    //
    input var  signed [                 DATA_WIDTH-1:0] data_i_in,
    input var  signed [                 DATA_WIDTH-1:0] data_q_in,
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
    input var         [          $clog2(NUM_UNITS)-1:0] ctrl_index_delay [NUM_UNITS],
    input var         [          $clog2(NUM_UNITS)-1:0] ctrl_signal_delay[NUM_UNITS],
    //
    input var         [$clog2(NUM_UNITS)+INDEX_WIDTH:0] ctrl_lut_addr,
    input var                                           ctrl_lut_en,
    input var                                           ctrl_lut_we,
    input var         [           LUT_DATA_WIDTH*2-1:0] ctrl_lut_din,
    output var        [           LUT_DATA_WIDTH*2-1:0] ctrl_lut_dout
);


  localparam int DelayWidth = $clog2(NUM_UNITS);


  logic                                bank_s;
  logic                                bank_dly           [NUM_UNITS];

  logic        [       DATA_WIDTH+1:0] data_abs;

  logic        [      INDEX_WIDTH-1:0] index;
  logic        [      INDEX_WIDTH-1:0] index_s            [NUM_UNITS];

  logic        [     DATA_WIDTH*2-1:0] signal_in;
  logic        [     DATA_WIDTH*2-1:0] signal_d;
  logic        [     DATA_WIDTH*2-1:0] signal_d_s         [NUM_UNITS];

  logic signed [       DATA_WIDTH-1:0] data_i_s           [NUM_UNITS];
  logic signed [       DATA_WIDTH-1:0] data_q_s           [NUM_UNITS];

  logic        [$clog2(NUM_UNITS)-1:0] ctrl_lut_addr_unit;

  logic        [        INDEX_WIDTH:0] ctrl_lut_addr_s    [NUM_UNITS];
  logic                                ctrl_lut_en_s      [NUM_UNITS];
  logic                                ctrl_lut_we_s      [NUM_UNITS];
  logic        [ LUT_DATA_WIDTH*2-1:0] ctrl_lut_din_s     [NUM_UNITS];
  logic        [ LUT_DATA_WIDTH*2-1:0] ctrl_lut_dout_s    [NUM_UNITS];


  // LUT Bank Selector
  //==================

  xpm_cdc_single #(
      .DEST_SYNC_FF  (4),
      .INIT_SYNC_FF  (0),
      .SIM_ASSERT_CHK(0),
      .SRC_INPUT_REG (0)
  ) xpm_cdc_single_ctrl_bank (
      .src_clk (ctrl_clk),
      .src_in  (ctrl_bank),
      .dest_clk(clk),
      .dest_out(bank_s)
  );

  always_ff @(posedge clk) begin
    bank_dly[0] <= bank_s;
    for (int i = 1; i < NUM_UNITS; i++) begin
      bank_dly[i] <= bank_dly[i-1];
    end
  end


  // Index Generation
  //=================

  assign signal_in = {data_q_in, data_i_in};

  cordic_cart2pol #(
      .DATA_WIDTH          (DATA_WIDTH),
      .CTRL_WIDTH          (DATA_WIDTH * 2),
      .ITERATIONS          (10),
      .COMPENSATION_SCALING(1)
  ) i_cordic_cart2pol (
      .clk     (clk),
      .rst     (rst),
      //
      .xin     (data_i_in),
      .yin     (data_q_in),
      .ctrl_in (signal_in),
      //
      .theta   (  /* not used */),
      .r       (data_abs),
      .ctrl_out(signal_d)
  );

  // TODO: Add compound module
  assign index = data_abs[DATA_WIDTH-1-:INDEX_WIDTH];

  nlf_delay_line #(
      .NUM_UNITS  (NUM_UNITS),
      .DELAY_WIDTH(DelayWidth),
      .DATA_WIDTH (INDEX_WIDTH)
  ) i_index_delay_line (
      // Read Interface
      .clk     (clk),
      //
      .data_in (index),
      .data_out(index_s),
      //
      .delay   (ctrl_index_delay)
  );


  // Signal Delay
  //=============

  nlf_delay_line #(
      .NUM_UNITS  (NUM_UNITS),
      .DELAY_WIDTH(DelayWidth),
      .DATA_WIDTH (DATA_WIDTH * 2)
  ) i_signal_delay_line (
      // Read Interface
      .clk     (clk),
      //
      .data_in (signal_d),
      .data_out(signal_d_s),
      //
      .delay   (ctrl_signal_delay)
  );

  generate
    for (genvar i = 0; i < NUM_UNITS; i++) begin : g_signal

      assign {data_q_s[i], data_i_s[i]} = signal_d_s[i];

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
      .index_in     (index_s),
      //
      .data_i_in    (data_i_s),
      .data_q_in    (data_q_s),
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
    for (genvar i = 0; i < NUM_UNITS; i++) begin : g_lut_mux

      // ctrl_lut_addr is composed by {unit, bank, index}
      // ctrl_lut_addr_s is composed by {bank, index}
      assign ctrl_lut_addr_s[i] = ctrl_lut_addr[INDEX_WIDTH:0];

      assign ctrl_lut_en_s[i]   = (ctrl_lut_addr_unit == i) && ctrl_lut_en;
      assign ctrl_lut_we_s[i]   = (ctrl_lut_addr_unit == i) && ctrl_lut_we;
      assign ctrl_lut_din_s[i]  = ctrl_lut_din;

    end
  endgenerate

  assign ctrl_lut_dout = ctrl_lut_dout_s[ctrl_lut_addr_unit];

endmodule

`default_nettype wire
