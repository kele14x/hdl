// File: ram_shift.sv
// Brief: RAM based shift register.
`default_nettype none
//
`timescale 1 ns / 1 ps

module shift_ram #(
    parameter int DEPTH      = 8192,
    parameter int DATA_WIDTH = 32
) (
    input var                   clk,
    input var                   rst,
    input var  [DATA_WIDTH-1:0] din,
    output var [DATA_WIDTH-1:0] dout
);

  // Check parameters
  //=================

  initial begin
    assert (DEPTH >= 4)
    else begin
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
  localparam int AddrWidth = $clog2(DEPTH - 2);


  // Signals
  //========

  logic [AddrWidth-1:0] addra;
  logic [AddrWidth-1:0] addrb;


  // Write & read address
  //=====================

  always_ff @(posedge clk) begin
    if (rst) begin
      addra <= '0;
    end else begin
      addra <= addra + 1;
    end
  end

  // At minimal depth=4, read address is reset to -1, which is bottom of RAM.
  always_ff @(posedge clk) begin
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
      .INIT_WORD   ('0)
  ) i_ram_sdp (
      // Port A, write port
      .clka (clk),
      .ena  (1'b1),
      .wea  (1'b1),
      .addra(addra),
      .dina (din),
      // Port B, read port
      .clkb (clk),
      .rstb (1'b0),
      .enb  ('1),
      .addrb(addrb),
      .doutb(dout)
  );

endmodule  // ram_shift

`default_nettype wire
