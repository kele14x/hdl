// File: tb_fft.sv
// Brief: Test bench for module fft.
`default_nettype none
//
`timescale 1 ns / 1ps

module tb_fft;

  parameter int TEST_LENGTH = 4096;

  parameter int FFT_SIZE   = TEST_LENGTH;
  parameter int DATA_WIDTH = 16;


  // DUT signals
  //============

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


  // Testbench signals
  //==================

  logic [DATA_WIDTH-1:0] xin_real_mem [TEST_LENGTH];
  logic [DATA_WIDTH-1:0] xin_imag_mem [TEST_LENGTH];
  logic [DATA_WIDTH-1:0] yout_real_mem [TEST_LENGTH];
  logic [DATA_WIDTH-1:0] yout_imag_mem [TEST_LENGTH];

  logic [DATA_WIDTH-1:0] data_i_out_ref;
  logic [DATA_WIDTH-1:0] data_q_out_ref;

  logic signed [DATA_WIDTH-1:0] data_i_out_err;
  logic signed [DATA_WIDTH-1:0] data_q_out_err;


  // Initial memory
  //===============

  initial begin
    $readmemh("test_fft_dit2_xin_real.txt",  xin_real_mem );
    $readmemh("test_fft_dit2_xin_imag.txt",  xin_imag_mem );
    $readmemh("test_fft_dit2_yout_real.txt", yout_real_mem);
    $readmemh("test_fft_dit2_yout_imag.txt", yout_imag_mem);
  end


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
    #100;
    rst = 0;
  end

  initial begin
    data_i_in = 0;
    data_q_in = 0;

    wait (rst == 0);

    fork

      begin : p_feed_input
        for (int i = 0; i < FFT_SIZE; i++) begin
          @(posedge clk);
          data_i_in     <= xin_real_mem[i];
          data_q_in     <= xin_imag_mem[i];
          data_valid_in <= 1;
          data_last_in  <= (i == FFT_SIZE - 1);
        end
        @(posedge clk);
        data_i_in     <= 0;
        data_q_in     <= 0;
        data_valid_in <= 0;
        data_last_in  <= 0;
      end

      begin : p_ref_out
        repeat($clog2(FFT_SIZE) * 9 + FFT_SIZE - 8) @(posedge clk);
        for (int i = 0; i < FFT_SIZE; i++) begin
          @(posedge clk);
          data_i_out_ref <= yout_real_mem[i];
          data_q_out_ref <= yout_imag_mem[i];
        end
        @(posedge clk);
        data_i_out_ref <= 0;
        data_q_out_ref <= 0;
      end

      begin : p_checker
        repeat($clog2(FFT_SIZE) * 9 + FFT_SIZE - 8) @(posedge clk);
        for (int i = 0; i < FFT_SIZE; i++) begin
          @(posedge clk);
          data_i_out_err <= $signed(data_i_out_ref) - $signed(data_i_out);
          data_q_out_err <= $signed(data_q_out_ref) - $signed(data_q_out);
        end
      end

    join

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
