`timescale 1 ns / 1 ps
//
`default_nettype none

module tb_prach_fft;

  parameter int FFT_SIZE = 1536;
  //
  parameter int TEST_FRAME = 3;

  logic               clk;
  logic               rst;
  //
  logic signed [15:0] din_dr;
  logic signed [15:0] din_di;
  logic               din_sf;
  logic               din_sl;
  logic               din_sy;
  logic        [ 1:0] din_chn;
  logic               din_dv;
  logic               din_last;
  //
  logic signed [15:0] dout_dr;
  logic signed [15:0] dout_di;
  logic               dout_sf;
  logic               dout_sl;
  logic               dout_sy;
  logic        [ 1:0] dout_chn;
  logic               dout_dv;
  logic               dout_last;

  logic               ovf;

  logic        [31:0] TEST_INPUT[FFT_SIZE];

  initial begin
    $readmemh("tb_prach_fft_input.txt", TEST_INPUT);
  end

  // Clock generation
  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  // Reset generation
  initial begin
    rst = 1'b1;
    repeat (100) @(posedge clk);
    rst <= 1'b0;
  end

  // Stimulus generation

  initial begin
    $display("*** Start simulation ***");
    // Initialize inputs
    din_dr   = 16'h0000;
    din_di   = 16'h0000;
    din_sf   = 1'b0;
    din_sl   = 1'b0;
    din_sy   = 1'b0;
    din_chn  = 2'b00;
    din_dv   = 1'b0;
    din_last = 1'b0;

    wait (rst == 0);
    @(posedge clk);

    // Flush the buffer
    for (int i = 0; i < FFT_SIZE; i++) begin
      din_dr   <= 16'h0000;
      din_di   <= 16'h0000;
      din_sf   <= 1'b0;
      din_sl   <= 1'b0;
      din_sy   <= 1'b0;
      din_chn  <= 2'b00;
      din_dv   <= 1'b0;
      din_last <= 1'b0;
      @(posedge clk);
    end

    // Apply stimulus
    for (int f = 0; f < TEST_FRAME; f++) begin
      for (int i = 0; i < FFT_SIZE; i++) begin
        din_dr   <= TEST_INPUT[i][15:0];
        din_di   <= TEST_INPUT[i][31:16];
        din_sf   <= (i == 0);
        din_sl   <= (i == 0);
        din_sy   <= (i == 0);
        din_chn  <= 2'b0;
        din_dv   <= 1'b1;
        din_last <= (i == FFT_SIZE - 1);
        @(posedge clk);
      end
      din_dv <= 1'b0;
      // IPG
      repeat(10) @(posedge clk);  
    end

    #10000;
    $finish;
  end

  final begin
    $display("*** End simulation ***");
  end

  // Output data logger

  integer fout;

  initial begin
    // Open file
    fout = $fopen("tb_prach_fft_output.txt");
    if (!fout) begin
      $display("Failed to open file");
      $finish;
    end

    // Wait for sync
    forever begin
      @(posedge clk);
      if (dout_dv) break;
    end

    // Log data
    forever begin
      if (dout_dv) begin
        $fwrite(fout, "%d, %d\n", dout_dr, dout_di);
      end
      @(posedge clk);
    end
  end

  final begin
    $fclose(fout);
  end

  // DUT

  prach_fft #(.FFT_SIZE(FFT_SIZE)) DUT (.*);

endmodule

`default_nettype wire
