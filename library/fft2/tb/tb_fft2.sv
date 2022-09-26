// File: tb_fft.v
// Brief: Test bench for module fft.
`default_nettype none
//
`timescale 1 ns / 1ps

module tb_fft2;

  parameter int LOG_FFT_SIZE = 4;
  parameter int INPUT_DATA_WIDTH = 16;
  parameter int PHASE_WIDTH = 16;
  parameter int OUTPUT_DATA_WIDTH = INPUT_DATA_WIDTH + LOG_FFT_SIZE + 1;
  parameter bit BIT_REVERSED_INPUT = 1;


  // DUT signals
  //============

  bit                         clk;
  bit                         rst;
  //
  bit [ INPUT_DATA_WIDTH-1:0] data_i_in;
  bit [ INPUT_DATA_WIDTH-1:0] data_q_in;
  bit                         data_valid_in;
  bit                         data_last_in;
  //
  bit [OUTPUT_DATA_WIDTH-1:0] data_i_out;
  bit [OUTPUT_DATA_WIDTH-1:0] data_q_out;
  bit                         data_valid_out;
  bit                         data_last_out;

  bit [                  4:0] ctrl_sra_bits;

  bit                         err_input_halt;
  bit                         err_last_unexpected;
  bit                         err_ovf;


  // Testbench signals
  //==================


  // Stimulation
  //============

  initial begin
    clk = 0;
    forever begin
      #5 clk = ~clk;
    end
  end

  initial begin
    rst = 1;
    #160;
    rst = 0;
  end

  initial begin
    wait (rst == 0);
    #100;

    for (int i = 0; i < 2 ** LOG_FFT_SIZE; i = i + 1) begin
      @(posedge clk);
      data_i_in     <= i + 1;
      data_q_in     <= 0;
      data_valid_in <= 1;
      data_last_in  <= (i == 2 ** LOG_FFT_SIZE - 1);
    end
    @(posedge clk);
    data_i_in     <= 0;
    data_q_in     <= 0;
    data_valid_in <= 0;
    data_last_in  <= 0;

    #1000;
    $finish;
  end


  // DUT
  //====

  fft2_bf2 #(
      .LOG_FFT_SIZE      (LOG_FFT_SIZE),
      .DATA_WIDTH        (INPUT_DATA_WIDTH)
  ) DUT (
      .clk                (clk),
      .rst                (rst),
      // Data input
      .data_i_in          (data_i_in),
      .data_q_in          (data_q_in),
      .data_valid_in      (data_valid_in),
      .data_last_in       (data_last_in),
      // Data output
      .data_i_out         (data_i_out),
      .data_q_out         (data_q_out),
      .data_valid_out     (data_valid_out),
      .data_last_out      (data_last_out)
  );

endmodule

`default_nettype wire
