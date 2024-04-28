`timescale 1 ns / 1 ps
//
`default_nettype none

module prach_ditfft2_twiddler #(
    parameter int NUM_FFT_LENGTH = 6
) (
    input var         clk,
    input var         rst_n,
    //
    input var  [17:0] din_dr,
    input var  [17:0] din_di,
    input var         din_dv,
    input var         sync_in,
    input var         din_dv_ahead,
    input var         sync_ahead_in,
    //
    output var [17:0] dout_dr,
    output var [17:0] dout_di,
    output var        dout_dv,
    output var        sync_out,
    output var        dout_dv_ahead,
    output var        sync_ahead_out
);

  // x0, x1 -> x0 + x1, x0 - x1

  localparam int Latency = 4;
  localparam int CounterWidth = $clog2(NUM_FFT_LENGTH);

  logic        [CounterWidth-1:0] cnt;

  logic signed [            17:0] tr;
  logic signed [            17:0] ti;

  logic signed [            17:0] tr_d;
  logic signed [            17:0] ti_d;

  logic signed [            17:0] cos_lut[2 ** (CounterWidth-1)];
  logic signed [            17:0] sin_lut[2 ** (CounterWidth-1)];

  logic        [CounterWidth-1:0] addr;

  initial begin
    for (int i = 0; i < 2 ** (CounterWidth - 1); i++) begin
      if (i < NUM_FFT_LENGTH / 2) begin
        cos_lut[i] = int'($cos(3.1415926535 * 2 * i / NUM_FFT_LENGTH) * 2 ** 16);
        sin_lut[i] = int'($sin(-3.1415926535 * 2 * i / NUM_FFT_LENGTH) * 2 ** 16);
      end else begin
        cos_lut[i] = '0;
        sin_lut[i] = '0;
      end
    end
  end

  always_ff @(posedge clk) begin
    if (~rst_n) begin
      cnt <= 0;
    end else if (sync_ahead_in) begin
      cnt <= 1;
    end else if (din_dv_ahead) begin
      cnt <= cnt == NUM_FFT_LENGTH - 1 ? 0 : cnt + 1;
    end
  end

  always_ff @(posedge clk) begin
    if (cnt < NUM_FFT_LENGTH / 2) begin
      addr <= '0;
    end else begin
      addr <= cnt - NUM_FFT_LENGTH / 2;
    end
  end

  always_ff @(posedge clk) begin
    tr   <= cos_lut[addr];
    ti   <= sin_lut[addr];
    tr_d <= tr;
    ti_d <= ti;
  end

  cmult #(
      .A_WIDTH(18),
      .B_WIDTH(18),
      .P_WIDTH(18),
      .SHIFT  (16)
  ) u_cmult (
      .clk    (clk),
      .rst_n  (rst_n),
      //
      .ar     (din_dr),
      .ai     (din_di),
      //
      .br     (tr_d),
      .bi     (ti_d),
      //
      .pr     (dout_dr),
      .pi     (dout_di),
      //
      .err_ovf()
  );

  delay #(
      .WIDTH(4),
      .DELAY(Latency)
  ) u_delay (
      .clk  (clk),
      .rst_n(1'b1),
      .din  ({sync_ahead_in, din_dv_ahead, sync_in, din_dv}),
      .dout ({sync_ahead_out, dout_dv_ahead, sync_out, dout_dv})
  );

endmodule

`default_nettype wire
