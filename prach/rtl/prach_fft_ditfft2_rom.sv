`timescale 1 ns / 1 ps
//
`default_nettype none

module prach_fft_ditfft2_rom #(
    parameter int FFT_SIZE   = 6,
    parameter int ADDR_WIDTH = 2,
    parameter int DATA_WIDTH = 18,
    parameter     RAM_STYLE  = "BLOCK"
) (
    input var                          clk,
    input var                          rst,
    //
    input var         [ADDR_WIDTH-1:0] addr,
    //
    output var signed [DATA_WIDTH-1:0] tr,
    output var signed [DATA_WIDTH-1:0] ti
);

  // Parameters

  localparam int Latency = 2;
  localparam real Pi = 3.1415926535;
  localparam bit RamStyleKnown = (RAM_STYLE == "BLOCK") || (RAM_STYLE == "DISTRIBUTED");

  // Signals

  (* RAM_STYLE=RAM_STYLE *)
  logic [DATA_WIDTH*2-1:0] mem     [FFT_SIZE / 2];

  logic [DATA_WIDTH*2-1:0] dout;
  logic [DATA_WIDTH*2-1:0] dout_d;
  logic [DATA_WIDTH*2-1:0] dout_dd;

  // Main

  initial begin
    if (FFT_SIZE == 6) begin
      $readmemh("./prach_fft_6.mem", mem);
    end else if (FFT_SIZE == 12) begin
      $readmemh("./prach_fft_12.mem", mem);
    end else if (FFT_SIZE == 24) begin
      $readmemh("./prach_fft_24.mem", mem);
    end else if (FFT_SIZE == 48) begin
      $readmemh("./prach_fft_48.mem", mem);
    end else if (FFT_SIZE == 96) begin
      $readmemh("./prach_fft_96.mem", mem);
    end else if (FFT_SIZE == 192) begin
      $readmemh("./prach_fft_192.mem", mem);
    end else if (FFT_SIZE == 384) begin
      $readmemh("./prach_fft_384.mem", mem);
    end else if (FFT_SIZE == 768) begin
      $readmemh("./prach_fft_768.mem", mem);
    end else if (FFT_SIZE == 1536) begin
      $readmemh("./prach_fft_1536.mem", mem);
    end else begin
      $error("Unsupported FFT_SIZE %0d. [%m] ", FFT_SIZE);
    end
  end

  // cos sin lut

  always_ff @(posedge clk) begin
    dout <= mem[addr];
  end

  always_ff @(posedge clk) begin
    dout_d  <= dout;
    dout_dd <= dout_d;
  end

  assign {ti, tr} = dout_dd;

  wire unused_ditfft2_rom = &{1'b0, rst, 32'(Latency), Pi != 0.0, RamStyleKnown};

endmodule

`default_nettype wire
