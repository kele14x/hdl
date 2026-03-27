`timescale 1 ns / 1 ps
//
`default_nettype none

module util_gpio_gw #(
    parameter WIDTH = 4
) (
    // verilog_format: off
    (* X_INTERFACE_INFO = "xilinx.com:interface:gpio_rtl:1.0 GPIO TRI_I" *)
    output wire [WIDTH-1:0] gpio_io_i,
    (* X_INTERFACE_INFO = "xilinx.com:interface:gpio_rtl:1.0 GPIO TRI_O" *)
    input  wire [WIDTH-1:0] gpio_io_o,
    (* X_INTERFACE_INFO = "xilinx.com:interface:gpio_rtl:1.0 GPIO TRI_T" *)
    input  wire [WIDTH-1:0] gpio_io_t,
    //
    input  wire [WIDTH-1:0] gpio_in,
    output reg  [WIDTH-1:0] gpio_out
    // verilog_format: on
);

  genvar i;

  generate
    for (i = 0; i < WIDTH; i = i + 1) begin : g_out

      // If GPIO is configured as tri-state, use gpio_in
      always @* begin
        if (gpio_io_t[i] == 1'b0) begin
          gpio_out[i] = gpio_io_o[i];
        end else begin
          gpio_out[i] = gpio_in[i];
        end
      end

      assign gpio_io_i[i] = gpio_out[i];
    end
  endgenerate

endmodule

`default_nettype wire
