// File: tb_symbol_timer.sv
// Brief: Testbench from symbol_timer module
`timescale 1 ns / 100 ps
//
`default_nettype none

module tb_symbol_timer;

  bit       clk;
  bit       rst;
  //
  bit       radio_frame_start_10ms_in;
  //
  bit       radio_frame_start;
  bit       subframe_start;
  bit       slot_start;
  bit       symbol_start;
  bit       symbol_long_cp;
  //
  bit [2:0] ctrl_numerology = 1;
  bit       ctrl_extended_cp;

  initial begin
    clk = 0;
    forever begin
      #1 clk = ~clk;
    end
  end

  initial begin
    rst = 1;
    #100;
    @(posedge clk);
    rst <= 0;
  end

  initial begin
    wait (rst == 0);
    @(posedge clk);
    radio_frame_start_10ms_in <= 1;
    @(posedge clk);
    radio_frame_start_10ms_in <= 0;
  end

  symbol_timer DUT (
      .clk(clk),  // Assume 491.52 MHz clock
      .rst(rst),
      //
      .radio_frame_start_10ms_in(radio_frame_start_10ms_in),
      //
      .radio_frame_start(radio_frame_start),
      .subframe_start(subframe_start),
      .slot_start(slot_start),
      .symbol_start(symbol_start),
      .symbol_long_cp(symbol_long_cp),
      // Control information
      .ctrl_numerology(ctrl_numerology),  // 0 ~ 4
      .ctrl_extended_cp(ctrl_extended_cp)  // 0 or 1, only applicable to numerology 2
  );

endmodule

`default_nettype wire
