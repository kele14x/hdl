// file: ul_traffic_gen.sv
// brief: UL Traffic generator for test
`timescale 1 ns / 1 ps `default_nettype none

module tb_ul_traffic_gen ();


  logic        clk;
  logic        rst;
  logic        ul_radio_start_10ms;
  logic        ul_sof_ahead_3;
  logic        ul_sop_ahead_3;
  logic [15:0] ul_data_i;
  logic [15:0] ul_data_q;
  logic [ 1:0] ctrl_numerology = 0;

  ul_traffic_gen UUT (.*);


  initial begin
    clk = 0;
    forever begin
      #(1.017) clk = ~clk;
    end
  end

  initial begin
    rst = 1;
    #100;
    rst = 0;
    #100;
    @(posedge clk);
    ul_radio_start_10ms <= 1'b1;
    @(posedge clk);
    ul_radio_start_10ms <= 1'b0;
  end

endmodule

`default_nettype wire
