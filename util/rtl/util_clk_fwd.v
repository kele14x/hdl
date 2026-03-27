`timescale 1 ns / 1 ps
//
`default_nettype none

// verilog_format: off
module util_clk_fwd (
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 i_clk CLK" *)
    (* X_INTERFACE_PARAMETER = "FREQ_HZ 156250000, FREQ_TOLERANCE_HZ 0" *)
    input  wire i_clk,
    (* X_INTERFACE_INFO = "xilinx.com:interface:diff_clock:1.0 o_clk CLK_P" *)
    (* X_INTERFACE_PARAMETER = "FREQ_HZ 156250000, FREQ_TOLERANCE_HZ 0" *)
    output wire o_clk_p,
    (* X_INTERFACE_INFO = "xilinx.com:interface:diff_clock:1.0 o_clk CLK_N" *)
    output wire o_clk_n
);
// verilog_format: on

  wire clk_oddr;

  ODDRE1 #(
      .IS_C_INVERTED (1'b0),
      .IS_D1_INVERTED(1'b0),
      .IS_D2_INVERTED(1'b0),
      .SIM_DEVICE    ("ULTRASCALE_PLUS"),
      .SRVAL         (1'b0)
  ) ODDRE1_inst (
      .Q (clk_oddr),
      .C (i_clk),
      .D1(1'b1),
      .D2(1'b0),
      .SR(1'b0)
  );

  OBUFDS OBUFDS_inst (
      .O (o_clk_p),
      .OB(o_clk_n),
      .I (clk_oddr)
  );

endmodule

`default_nettype wire
