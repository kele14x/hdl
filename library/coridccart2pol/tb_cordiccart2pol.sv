`timescale 1ns / 1ps

module tb_cordiccart2pol ();

  parameter integer ITERATIONS = 7;
  parameter integer DATA_WIDTH = 16;
  
  parameter integer TEST_LENGTH = 1;
  parameter integer LATENCY = 8;

  logic                         clk;
  logic                         rst;

  logic signed [DATA_WIDTH-1:0] xin;
  logic signed [DATA_WIDTH-1:0] yin;

  logic        [  ITERATIONS:0] theta;
  logic        [  DATA_WIDTH:0] r;

  logic [15:0] xin_mem [TEST_LENGTH];
  logic [15:0] yin_mem [TEST_LENGTH];
  logic [ 7:0] theta_mem [TEST_LENGTH];
  logic [16:0] r_mem [TEST_LENGTH];

  initial begin
     $readmemh ("test_cordic_translate_input_xin.txt", xin_mem, 0, TEST_LENGTH-1);
     $readmemh ("test_cordic_translate_input_yin.txt", yin_mem, 0, TEST_LENGTH-1);
     $readmemh ("test_cordic_translate_output_thetab.txt", theta_mem, 0, TEST_LENGTH-1);
     $readmemh ("test_cordic_translate_output_r.txt", r_mem, 0, TEST_LENGTH-1);
  end

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

  initial begin
    // Wait reset done
    wait(rst == 0);
    @(posedge clk);
    
    fork
      // Stimulation
      begin
        for (int i = 0; i < TEST_LENGTH; i++) begin
          @(posedge clk);
          xin <= xin_mem[i];
          yin <= yin_mem[i];
        end
        @(posedge clk);
        xin <= 0;
        yin <= 0;
      end

      // Checker
      begin
        repeat(LATENCY+1) @(posedge clk);
        for (int i = 0; i < TEST_LENGTH; i++) begin
          @(posedge clk);
          if (theta != theta_mem[i]) begin
            $warning("\"Theta\" output mismatch with gold result. Time=%t, i=%d, expect=%x, got=%x", $time, i, theta_mem[i], theta);
          end
          if (r != r_mem[i]) begin
            $warning("\"R\" output mismatch with gold result. Time=%t, i=%d, expect=%x, got=%x", $time, i, r_mem[i], r);
          end
        end
      end

    join
    

   
  end

  cordiccart2pol #(
      .ITERATIONS(ITERATIONS),
      .DATA_WIDTH(DATA_WIDTH)
  ) i_cordiccart2pol (
      .clk  (clk),
      .rst  (rst),
      .xin  (xin),
      .yin  (yin),
      .theta(theta),
      .r    (r)
  );

endmodule
