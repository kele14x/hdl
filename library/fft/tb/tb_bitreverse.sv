`timescale 1 ns / 1 ps
`default_nettype none

module tb_fft_bitreverse();

  localparam int FftSize = 8;
  localparam int DataWidth = 32;
  
  logic clk;
  logic rst;
  
  logic [DataWidth-1:0] data_in;
  logic                 data_valid_in;
  logic                 data_last_in;
  
  logic [DataWidth-1:0] data_out;
  logic                 data_valid_out;
  logic                 data_last_out;


  initial begin
    clk = 0;
    forever begin
      #5 clk = ~clk;
    end
  end
  
  initial begin
    rst = 1;
    repeat(10) @(posedge clk);
    rst <= 0;
  end
  
  initial begin
    data_in = 0;
    data_valid_in = 0;
    data_last_in = 0;
    wait (rst == 0);
    @(posedge clk);

    for (int i = 0; i < 10; i++) begin
      int cnt = 0;
      while (cnt < FftSize) begin
        logic v = $random();
        @(posedge clk);
        data_in <= 100 + cnt;
        if (v) begin
          data_valid_in <= v;
          data_last_in <= (cnt == FftSize - 1);
          cnt++;
        end else begin
          data_valid_in <= 0;
          data_last_in <= 0;
        end
      end
      @(posedge clk);
      data_in <= 0;
      data_valid_in <= 0;
      data_last_in <= 0;
    end
    
    #1000;
    $finish();
  end

  fft_bitreverse #(
    .FFT_SIZE  (FftSize),
    .DATA_WIDTH(DataWidth)
  ) UUT (
    .*
  );

endmodule

`default_nettype wire
