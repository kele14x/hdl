`timescale 1 ns / 1 ps
//
`default_nettype none

module util_clk_fwd_10 (
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 i_clk CLK" *)
    (* X_INTERFACE_PARAMETER = "FREQ_HZ 10000000, FREQ_TOLERANCE_HZ 0" *)
    input  wire i_clk,
    output wire o_clk
);

  ODDRE1 #(
      .IS_C_INVERTED (1'b0),
      .IS_D1_INVERTED(1'b0),
      .IS_D2_INVERTED(1'b0),
      .SIM_DEVICE    ("ULTRASCALE_PLUS"),
      .SRVAL         (1'b0)
  ) ODDRE1_inst (
      .Q (o_clk),
      .C (i_clk),
      .D1(1'b1),
      .D2(1'b0),
      .SR(1'b0)
  );

endmodule

`default_nettype wire
