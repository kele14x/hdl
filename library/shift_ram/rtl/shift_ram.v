// File: shift_ram.v
// Brief: RAM-Based shift register. It provides multi-bit wide shift registers
//        for use as a delay line. Currently only fixed-length shift registers
//        is supported.
`timescale 1 ns / 1 ps
//
`default_nettype none

module shift_ram #(
    parameter integer DATA_WIDTH = 16,
    parameter integer DEPTH      = 16
) (
    input  wire                  clk,
    input  wire                  rst,
    input  wire [DATA_WIDTH-1:0] din,
    output wire [DATA_WIDTH-1:0] dout
);

  // Check parameters
  //=================

  initial begin
    if (!(4 <= DEPTH && DEPTH <= 4096)) begin
      $error("[%m]: DEPTH must be within the range 4 to 4096");
      #1 $finish();
    end
  end


  // Local parameters
  //=================

  // Memory write and read address has minimal gap of 1 to avoid collision,
  // which means maximum delay taps 2 ** (AddrWidth) - 1. Additional
  // RAM is configured to have latency of 3, result maximum depth is
  // 2 ** (AddrWidth) + 2.
  localparam integer AddrWidth = $clog2(DEPTH - 2);


  // Signals
  //========

  reg [AddrWidth-1:0] addra;
  reg [AddrWidth-1:0] addrb;


  // Write & read address
  //=====================

  always @(posedge clk) begin
    if (rst) begin
      addra <= 'd0;
    end else begin
      addra <= addra + 1;
    end
  end

  // At minimal depth=4, read address is reset to -1, which is bottom of RAM.
  always @(posedge clk) begin
    if (rst) begin
      addrb <= -DEPTH + 3;
    end else begin
      addrb <= addra - DEPTH + 4;
    end
  end


  ram_sdp #(
      .ADDR_WIDTH  (AddrWidth),
      .DATA_WIDTH  (DATA_WIDTH),
      .READ_LATENCY(3),
      .INIT_WORD   ('d0)
  ) i_ram_sdp (
      // Port A, write port
      .clka (clk),
      .ena  (1'b1),
      .wea  (1'b1),
      .addra(addra),
      .dina (din),
      // Port B, read port
      .clkb (clk),
      .rstb ({3{rst}}),
      .enb  (3'b111),
      .addrb(addrb),
      .doutb(dout)
  );

endmodule  // ram_shift

`default_nettype wire
