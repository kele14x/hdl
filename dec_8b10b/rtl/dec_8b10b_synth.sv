`timescale 1 ns / 1 ps
`default_nettype none

module dec_8b10b_synth (
    input  wire       clk,
    input  wire       rst,
    input  wire       cen,
    //
    input  wire [9:0] din,
    input  wire       dispin,
    //
    output wire [7:0] dout,
    output wire       charisk,
    output wire       dispout,
    output wire       disperr,
    output wire       notintable,
    output wire       valid
);

  logic rst_r, cen_r, dispin_r;
  logic [9:0] din_r;

  always_ff @(posedge clk) begin
    rst_r    <= rst;
    cen_r    <= cen;
    din_r    <= din;
    dispin_r <= dispin;
  end

  dec_8b10b i_dec_8b10b (
      .clk       (clk),
      .rst       (rst_r),
      .cen       (cen_r),
      //
      .din       (din_r),
      .dispin    (dispin_r),
      //
      .dout      (dout),
      .charisk   (charisk),
      .dispout   (dispout),
      .notintable(notintable),
      .disperr   (disperr),
      .valid     (valid)
  );

endmodule

`default_nettype wire
