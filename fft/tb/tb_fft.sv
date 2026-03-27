`timescale 1 ns / 1 ps
//
`default_nettype none

module tb_fft;

  parameter int NUM_ANT = 4;
  parameter bit INV_FFT = 0;
  parameter int LOG_FFT_SIZE = 12;
  parameter int DATA_WIDTH = 16;
  parameter bit BIT_REVERSED_INPUT = 0;

  parameter int NUM_FRAMES = 3;
  parameter int NUM_CHNS = 4;
  parameter int FFT_SIZE = 4096;

  // Valid combinations of NUM_CHNS/FFT_SIZE:
  //   NUM_CHNS = 4,  FFT_SIZE =                           4096 (30/122.88), 33.33 us
  //   NUM_CHNS = 8,  FFT_SIZE = 4096 (15/61.44) 66.67 us, 2048 (30/61.44), 33.33 us
  //   NUM_CHNS = 16, FFT_SIZE = 2048 (15/30.72) 66.67 us, 1024 (30/30.72), 33.33 us

  logic                         clk;
  logic                         rst;
  // Data input
  logic signed [DATA_WIDTH-1:0] din_dr;
  logic signed [DATA_WIDTH-1:0] din_di;
  logic                         din_sf;
  logic                         din_sl;
  logic                         din_sy;
  logic        [           3:0] din_chn;
  logic                         din_dv;
  logic                         din_last;
  // Data output
  logic signed [DATA_WIDTH-1:0] dout_dr;
  logic signed [DATA_WIDTH-1:0] dout_di;
  logic                         dout_sf;
  logic                         dout_sl;
  logic                         dout_sy;
  logic        [           3:0] dout_chn;
  logic                         dout_dv;
  logic                         dout_last;
  // Status output
  logic        [           1:0] ctrl_size;
  logic        [           1:0] ctrl_itlv;
  //
  logic                         stat_ovf;

  // Clock & Reset

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    rst = 1;
    repeat (100) @(posedge clk);
    rst <= 0;
  end

  // Stimulus

  initial begin
    $display("*** Simulation start ***");
    din_dr = 0;
    din_di = 0;
    din_sf = 0;
    din_sl = 0;
    din_sy = 0;
    din_chn = 0;
    din_dv = 0;
    din_last = 0;

    ctrl_size = (FFT_SIZE == 1024) ? 2'b00 : (FFT_SIZE == 2048) ? 2'b01 : 2'b10;
    ctrl_itlv = (NUM_CHNS == 16) ? 2'b00 : (NUM_CHNS == 8) ? 2'b01 : 2'b10;
    wait (rst == 0);
    @(posedge clk);

    // Flush the buffer
    for (int i = 0; i < 2 ** LOG_FFT_SIZE; i++) begin
      for (int chn = 0; chn < NUM_CHNS; chn++) begin
        din_chn <= chn;
        @(posedge clk);
      end
    end

    // Data input
    for (int frm = 0; frm < NUM_FRAMES; frm++) begin
      for (int i = 0; i < FFT_SIZE; i++) begin
        for (int chn = 0; chn < NUM_CHNS; chn++) begin
          din_dr   <= (chn < NUM_ANT) ? $urandom_range(2000) - 1000 : 0;
          din_di   <= (chn < NUM_ANT) ? $urandom_range(2000) - 1000 : 0;
          din_sf   <= (i == 0 && chn < NUM_ANT);
          din_sl   <= (i == 0 && chn < NUM_ANT);
          din_sy   <= (i == 0 && chn < NUM_ANT);
          din_chn  <= chn;
          din_dv   <= (chn < NUM_ANT);
          din_last <= (i == FFT_SIZE - 1 && chn < NUM_ANT);
          @(posedge clk);
        end
      end

      // Insert some gap
      for (int i = 0; i < 11; i++) begin
        for (int chn = 0; chn < NUM_CHNS; chn++) begin
          din_dr   <= 0;
          din_di   <= 0;
          din_sf   <= 0;
          din_sl   <= 0;
          din_sy   <= 0;
          din_chn  <= chn;
          din_dv   <= 0;
          din_last <= 0;
          @(posedge clk);
        end
      end
    end
    din_dv <= 0;

    // Keep CHN pattern
    for (int i = 0; i < 2 * FFT_SIZE; i++) begin
      for (int chn = 0; chn < NUM_CHNS; chn++) begin
        din_chn <= chn;
        @(posedge clk);
      end
    end

    #(1000);
    $finish();
  end

  final begin
    $display("*** Simulation end ***");
  end

  // Input data Logger

  integer fin;

  initial begin
    // Open the file
    fin = $fopen("din.txt", "w");
    if (!fin) begin
      $display("Failed to open din.txt");
      $finish();
    end

    // Wait for the first data
    forever begin
      @(posedge clk);
      if (din_dv && din_chn == 0) break;
    end

    // Log the data
    forever begin
      if (din_dv && din_chn == NUM_ANT - 1) begin
        $fwrite(fin, "%d, %d\n", din_dr, din_di);
      end
      @(posedge clk);
    end
  end

  final begin
    $fclose(fin);
  end

  // Output data Logger

  integer fout;

  initial begin
    // Open the file
    fout = $fopen("dout.txt", "w");
    if (!fout) begin
      $display("Failed to open dout.txt");
      $finish();
    end

    // Wait for the first data
    forever begin
      @(posedge clk);
      if (dout_dv && dout_chn == 0) break;
    end

    // Log the data
    forever begin
      if (dout_dv && dout_chn == NUM_ANT - 1) begin
        $fwrite(fout, "%d, %d\n", dout_dr, dout_di);
      end
      @(posedge clk);
    end
  end

  final begin
    $fclose(fout);
  end

  // DUT

  fft #(
      .NUM_ANT           (NUM_ANT),
      .INV_FFT           (INV_FFT),
      .LOG_FFT_SIZE      (LOG_FFT_SIZE),
      .DATA_WIDTH        (DATA_WIDTH),
      .BIT_REVERSED_INPUT(BIT_REVERSED_INPUT)
  ) DUT (
      .*
  );

endmodule

`default_nettype wire
