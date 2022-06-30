// File: tb_fft.v
// Brief: Test bench for module fft.
`default_nettype none
//
`timescale 1 ns / 1ps

module tb_fft;

  parameter integer TEST_LENGTH = 16;

  parameter integer FFT_SIZE = TEST_LENGTH;
  parameter integer INPUT_DATA_WIDTH = 16;
  parameter integer OUTPUT_DATA_WIDTH = 21;


  // DUT signals
  //============

  reg                                clk;
  reg                                rst;
  //
  reg        [ INPUT_DATA_WIDTH-1:0] data_i_in;
  reg        [ INPUT_DATA_WIDTH-1:0] data_q_in;
  reg                                data_valid_in;
  reg                                data_last_in;
  //
  wire       [OUTPUT_DATA_WIDTH-1:0] data_i_out;
  wire       [OUTPUT_DATA_WIDTH-1:0] data_q_out;
  wire                               data_valid_out;
  wire                               data_last_out;

  wire                               err_input_halt;
  wire                               err_last_unexpected;
  wire                               err_ovf;


  // Testbench signals
  //==================

  reg        [ INPUT_DATA_WIDTH-1:0] xin_real_mem        [0:TEST_LENGTH-1];
  reg        [ INPUT_DATA_WIDTH-1:0] xin_imag_mem        [0:TEST_LENGTH-1];
  reg        [OUTPUT_DATA_WIDTH-1:0] yout_real_mem       [0:TEST_LENGTH-1];
  reg        [OUTPUT_DATA_WIDTH-1:0] yout_imag_mem       [0:TEST_LENGTH-1];

  reg        [OUTPUT_DATA_WIDTH-1:0] data_i_out_ref;
  reg        [OUTPUT_DATA_WIDTH-1:0] data_q_out_ref;

  reg signed [OUTPUT_DATA_WIDTH-1:0] data_i_out_err;
  reg signed [OUTPUT_DATA_WIDTH-1:0] data_q_out_err;


  // Initial memory
  //===============

  initial begin
    $readmemh("test_fft_dit2_xin_real.txt", xin_real_mem);
    $readmemh("test_fft_dit2_xin_imag.txt", xin_imag_mem);
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
    #160;
    rst = 0;
  end

  initial begin
    data_i_in = 0;
    data_q_in = 0;
    data_valid_in = 0;
    data_last_in = 0;

    wait (rst == 0);

    fork

      begin : p_feed_input
        integer i;
        for (i = 0; i < FFT_SIZE; i = i + 1) begin
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
        integer i;
        repeat ($clog2(FFT_SIZE) * 9 + FFT_SIZE - 8) @(posedge clk);
        for (i = 0; i < FFT_SIZE; i = i + 1) begin
          @(posedge clk);
          data_i_out_ref <= yout_real_mem[i];
          data_q_out_ref <= yout_imag_mem[i];
        end
        @(posedge clk);
        data_i_out_ref <= 0;
        data_q_out_ref <= 0;
      end

      begin : p_checker
        integer i;
        repeat ($clog2(FFT_SIZE) * 9 + FFT_SIZE - 8) @(posedge clk);
        for (i = 0; i < FFT_SIZE; i = i + 1) begin
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
      .FFT_SIZE         (FFT_SIZE),
      .INPUT_DATA_WIDTH (INPUT_DATA_WIDTH),
      .OUTPUT_DATA_WIDTH(OUTPUT_DATA_WIDTH)
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
      .data_last_out      (data_last_out),
      // Status otuput
      .err_input_halt     (err_input_halt),
      .err_last_unexpected(err_last_unexpected),
      .err_ovf            (err_ovf)
  );

endmodule

`default_nettype wire
