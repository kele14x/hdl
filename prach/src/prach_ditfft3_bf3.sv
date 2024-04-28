`timescale 1 ns / 1 ps
//
`default_nettype none

module prach_ditfft3_bf3 (
    input var         clk,
    input var         rst_n,
    //
    input var  [17:0] din_dr,
    input var  [17:0] din_di,
    input var         din_dv,
    input var         sync_in,
    //
    output var [17:0] dout_dr,
    output var [17:0] dout_di,
    output var        dout_dv,
    output var        sync_out
);

  // x0, x1, x2 -> x0, x1 + x2, x1 - x2/

  logic        [ 1:0] cnt;

  logic signed [17:0] x1r;
  logic signed [17:0] x1i;

  always_ff @(posedge clk) begin
    if (~rst_n) begin
      cnt <= 0;
    end else if (sync_in) begin
      cnt <= 1;
    end else if (din_dv) begin
      cnt <= cnt == 2 ? 0 : cnt + 1;
    end
  end

  always_ff @(posedge clk) begin
    if (cnt == 0 || cnt == 1) begin
      x1r <= din_dr;
      x1i <= din_di;
    end else begin
      // x1 - x2
      x1r <= x1r - din_dr;
      x1i <= x1i - din_di;
    end
  end

  always_ff @(posedge clk) begin
    if (cnt == 2) begin
      // x1 + x2
      dout_dr <= x1r + din_dr;
      dout_di <= x1i + din_di;
    end else begin
      dout_dr <= x1r;
      dout_di <= x1i;
    end
  end

  delay #(
      .WIDTH(2),
      .DELAY(2)
  ) u_delay (
      .clk  (clk),
      .rst_n(1'b1),
      .din  ({sync_in, din_dv}),
      .dout ({sync_out, dout_dv})
  );

endmodule

`default_nettype wire
