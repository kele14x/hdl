// File: tb_fft.sv
// Brief: Test bench for module fft.
`default_nettype none
//
`timescale 1 ns / 1ps

module tb_fft;

  parameter int FFT_SIZE   = 8;
  parameter int DATA_WIDTH = 16;

  logic                  clk;
  logic                  rst;
  //
  logic [DATA_WIDTH-1:0] data_i_in;
  logic [DATA_WIDTH-1:0] data_q_in;
  logic                  data_valid_in;
  logic                  data_last_in;
  //
  logic [DATA_WIDTH-1:0] data_i_out;
  logic [DATA_WIDTH-1:0] data_q_out;
  logic                  data_valid_out;
  logic                  data_last_out;

  logic                  err_input_halt;
  logic                  err_last_unexpected;
  logic                  err_ovf;


  // Stimulation

  initial begin
    clk = 0;
    forever begin
      #5 clk = ~clk;
    end
  end

  initial begin
    rst = 1;
    #100;
    rst = 0;
  end

  initial begin
    data_i_in = 0;
    data_q_in = 0;

    wait (rst == 0);

    for (int i = 0; i < FFT_SIZE; i++) begin
      @(posedge clk);
      data_i_in     <= 10 + i;
      data_q_in     <= 0;
      data_valid_in <= 1;
      data_last_in  <= (i == FFT_SIZE - 1);
    end

    @(posedge clk);
    data_i_in     <= 0;
    data_q_in     <= 0;
    data_valid_in <= 0;
    data_last_in  <= 0;

    #1000;
    $finish();
  end


  // DUT

  fft #(
      .FFT_SIZE  (FFT_SIZE),
      .DATA_WIDTH(DATA_WIDTH)
  ) DUT (
      .*
  );

endmodule

`default_nettype wire
