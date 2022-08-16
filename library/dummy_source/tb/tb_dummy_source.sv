// File: tb_dummy_source.sv
// Brief: Testbench for dummy source.
`timescale 1 ns / 1 ps
//
`default_nettype none

module tb_dummy_source;

  parameter int DATA_WIDTH = 16;

  bit                  clk;
  bit                  rst;
  // Data input
  bit [           7:0] data_sync_in;
  // Data output
  bit [DATA_WIDTH-1:0] data_out;
  bit [           7:0] data_sync_out;
  // Control interface
  //==================
  bit [           2:0] ctrl_numerology;
  bit [           1:0] ctrl_iq_width;
  bit                  ctrl_shift;
  bit [          15:0] ctrl_scalar;


  initial begin
    clk = 0;
    forever begin
      #5 clk = ~clk;
    end
  end

  initial begin
    rst = 1;
    repeat (16) @(posedge clk);
    rst <= 0;
  end

  initial begin
    ctrl_numerology = 0;
    // QPSK
    ctrl_iq_width = 2'd0;
    ctrl_shift = 1'b1;
    ctrl_scalar = 15'd8241;
  end


  initial begin
    wait (rst == 0);
    @(posedge clk);
    data_sync_in <= 8'b00010000;
    @(posedge clk);
    data_sync_in <= '0;
  end

  dummy_source #(
      .DATA_WIDTH(DATA_WIDTH)
  ) DUT (
      .clk            (clk),
      .rst            (rst),
      //
      .data_sync_in   (data_sync_in),
      //
      .data_out       (data_out),
      .data_sync_out  (data_sync_out),
      //
      .ctrl_numerology(ctrl_numerology),
      .ctrl_iq_width  (ctrl_iq_width),
      .ctrl_shift     (ctrl_shift),
      .ctrl_scalar    (ctrl_scalar)
  );

endmodule

`default_nettype wire
