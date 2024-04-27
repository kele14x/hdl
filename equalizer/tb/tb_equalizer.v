// File: tb_equalizer.sv
// Brief: Test bench for equalizer
`timescale 1 ns / 1 ps
//
`default_nettype none

module tb_equalizer ();

  localparam integer NumTaps         = 8;
  localparam integer InputDataWidth  = 16;
  localparam integer CoeWidth        = 16;
  localparam integer OutputDataWidth = 16;
  localparam integer SraBits         = 15;

  localparam integer TestVectorLength = 1024;
  localparam integer DutLatency       = NumTaps + 3;

  reg clk;
  reg rst;

  reg signed [InputDataWidth-1:0] data_i_in;
  reg signed [InputDataWidth-1:0] data_q_in;

  wire signed [OutputDataWidth-1:0] data_i_out;
  wire signed [OutputDataWidth-1:0] data_q_out;
  wire                              ovf;

  reg [$clog2(NumTaps)-1:0] ctrl_coe_idx;
  reg                       ctrl_coe_valid;
  reg [       CoeWidth-1:0] ctrl_coe_i_in;
  reg [       CoeWidth-1:0] ctrl_coe_q_in;


  // Stimulation
  //============

  always begin
    clk = 0;
    #5;
    clk = 1;
    #5;
  end

  initial begin
    rst = 1;
    #100;
    rst = 0;
  end

  initial begin : p_stium
    integer i;

    $display("************************");
    $display("Simulation starts.");

    // Reset interface
    data_i_in = 0;
    data_q_in = 0;
    ctrl_coe_idx = 0;
    ctrl_coe_valid = 0;
    ctrl_coe_i_in = 0;
    ctrl_coe_q_in = 0;

    wait (rst == 0);
    #100;

    // Config coefficients

    for (i = 0; i < NumTaps; i = i + 1) begin
      @(posedge clk);
      ctrl_coe_idx <= i;
      ctrl_coe_valid <= 1;
      ctrl_coe_i_in <= i*100 + 100;
      ctrl_coe_q_in <= i*200 + 200;
    end
    @(posedge clk);
    ctrl_coe_idx <= 0;
    ctrl_coe_valid <= 0;
    ctrl_coe_i_in <= 0;
    ctrl_coe_q_in <= 0;

    fork
      begin : p_feed_input
        integer i;
        for (i = 0; i < TestVectorLength; i = i + 1) begin
          @(posedge clk);
          data_i_in <= ((i == 0) ? 16384 : 0);
          data_q_in <= ((i == 0) ? 0 : 0);
        end
      end
    join

    #1000;
    $display("Simulation ends.");
    $finish(2);
  end

  equalizer #(
      .NUM_TAPS         (NumTaps),
      .INPUT_DATA_WIDTH (InputDataWidth),
      .COE_WIDTH        (CoeWidth),
      .OUTPUT_DATA_WIDTH(OutputDataWidth),
      .SRA_BITS         (SraBits)
  ) DUT (
      .clk           (clk),
      .rst           (rst),
      //
      .data_i_in     (data_i_in),
      .data_q_in     (data_q_in),
      //
      .data_i_out    (data_i_out),
      .data_q_out    (data_q_out),
      .ovf           (ovf),
      //
      .ctrl_coe_idx  (ctrl_coe_idx),
      .ctrl_coe_valid(ctrl_coe_valid),
      .ctrl_coe_i_in (ctrl_coe_i_in),
      .ctrl_coe_q_in (ctrl_coe_q_in)
  );

endmodule

`default_nettype wire
