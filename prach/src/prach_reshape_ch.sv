`timescale 1 ns / 1 ps
//
`default_nettype none

module prach_reshape_ch #(
    parameter int SIZE = 8
) (
    input var         clk,
    input var         rst_n,
    //
    input var  [15:0] din_dq1,
    input var  [15:0] din_dq2,
    input var  [ 7:0] din_chn,
    input var         sync_in,
    //
    output var [15:0] dout_dp1,
    output var [15:0] dout_dp2,
    output var [ 7:0] dout_chn,
    output var        sync_out
);

  // x0s0s, x0s1s
  // x1s0s, x1s1s
  // =>
  // x0s0s, x1s0s
  // x0s1s, x1s1s

  localparam int Latency = SIZE / 2 + 1;

  logic        swap_n;

  logic [15:0] din_dq2_d;

  logic [15:0] delay_in;
  logic [15:0] delay_out;

  assign swap_n = din_chn[$clog2(SIZE/2)];

  delay #(
      .WIDTH(16),
      .DELAY(SIZE / 2)
  ) u_delay_dq2 (
      .clk  (clk),
      .rst_n(1'b1),
      .din  ({din_dq2}),
      .dout ({din_dq2_d})
  );

  delay #(
      .WIDTH(16),
      .DELAY(SIZE / 2)
  ) u_delay_dx (
      .clk  (clk),
      .rst_n(1'b1),
      .din  (delay_in),
      .dout (delay_out)
  );

  always_ff @(posedge clk) begin
    dout_dp1 <= delay_out;
  end

  always_ff @(posedge clk) begin
    if (swap_n) begin
      dout_dp2 <= din_dq1;
    end else begin
      dout_dp2 <= din_dq2_d;
    end
  end

  always_comb begin
    if (swap_n) begin
      delay_in = din_dq2_d;
    end else begin
      delay_in = din_dq1;
    end
  end

  always_ff @(posedge clk) begin
    dout_chn <= din_chn - (Latency - 1);
  end

  delay #(
      .WIDTH(1),
      .DELAY(Latency)
  ) u_delay_sync (
      .clk  (clk),
      .rst_n(1'b1),
      .din  (sync_in),
      .dout (sync_out)
  );

endmodule

`default_nettype wire
