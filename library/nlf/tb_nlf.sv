// File: tb_nlf.sv
// Brief: Test bench for module nlf

`timescale 1 ns / 1 ps `default_nettype none

module tb_nlf #();

  localparam int NUM_UNITS = 16;
  localparam int DATA_WIDTH = 16;
  localparam int INDEX_WIDTH = 8;
  localparam int LUT_DATA_WIDTH = 16;
  localparam int SRA_BITS = 15;

  logic                                     clk;
  logic                                     rst;
  //
  logic [                   DATA_WIDTH-1:0] data_i_in;
  logic [                   DATA_WIDTH-1:0] data_q_in;
  //
  logic [                   DATA_WIDTH-1:0] data_i_out;
  logic [                   DATA_WIDTH-1:0] data_q_out;
  // Overflow indicator
  logic                                     ovf;
  // Control Interface
  logic                                     ctrl_clk;
  logic                                     ctrl_rst;
  //
  logic [            $clog2(NUM_UNITS)-1:0] ctrl_index_delay [NUM_UNITS] = '{NUM_UNITS{'0}};
  logic [            $clog2(NUM_UNITS)-1:0] ctrl_signal_delay[NUM_UNITS] = '{NUM_UNITS{'0}};

  logic [$clog2(NUM_UNITS)+INDEX_WIDTH-1:0] ctrl_lut_addr = '0;
  logic                                     ctrl_lut_en   = '0;
  logic                                     ctrl_lut_we   = '0;
  logic [             LUT_DATA_WIDTH*2-1:0] ctrl_lut_din  = '0;
  logic [             LUT_DATA_WIDTH*2-1:0] ctrl_lut_dout;

  // Clock and reset stimulation
  //============================

  initial begin
    clk = 0;
    forever begin
      #1 clk = ~clk;
    end
  end

  initial begin
    ctrl_clk = 0;
    forever begin
      #5 ctrl_clk = ~ctrl_clk;
    end
  end

  initial begin
    rst = 1;
    repeat (100) @(posedge clk);
    rst <= 0;
  end

  initial begin
    ctrl_rst = 1;
    repeat (100) @(posedge ctrl_clk);
    ctrl_rst <= 0;
  end


  // Simulation
  //===========

  initial begin
    wait (rst == 0);
    wait (ctrl_rst == 0);

    @(posedge clk);
    for (int i = 0; i < 4096; i++) begin
      @(posedge clk);
      data_i_in <= i == 100 ? -32768 : 0;
      data_q_in <= i == 100 ? -32768 : 0;
    end
    
    #1000;
    $finish(2);
  end


  // UUT
  //====

  nlf #(
      .NUM_UNITS     (NUM_UNITS),
      .DATA_WIDTH    (DATA_WIDTH),
      .INDEX_WIDTH   (INDEX_WIDTH),
      .LUT_DATA_WIDTH(LUT_DATA_WIDTH),
      .SRA_BITS      (SRA_BITS)
  ) UUT (
      .*
  );


endmodule

`default_nettype wire
