`timescale 1 ns / 1 ps
//
`default_nettype none

module shift_ram_packed_compare (
    input var         clk,
    input var         rst,
    input var         cen,
    input var  [35:0] din,
    output var [35:0] dout_standard,
    output var [35:0] dout_packed
);

  shift_ram #(
      .WIDTH      (36),
      .DEPTH      (8192),
      .INPUT_REG  (1),
      .PACKED_URAM(0),
      .RAM_STYLE  ("BLOCK")
  ) i_standard (
      .clk (clk),
      .rst (rst),
      .cen (cen),
      .din (din),
      .dout(dout_standard)
  );

  shift_ram #(
      .WIDTH      (36),
      .DEPTH      (8192),
      .INPUT_REG  (1),
      .PACKED_URAM(1),
      .RAM_STYLE  ("ULTRA")
  ) i_packed (
      .clk (clk),
      .rst (rst),
      .cen (cen),
      .din (din),
      .dout(dout_packed)
  );

endmodule

`default_nettype wire
