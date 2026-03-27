`timescale 1 ns / 1 ps
//
`default_nettype none

module ccr_freq #(
    parameter FREQUENCY = 100_000_000
) (
    input  wire        clk,
    input  wire        rst,
    //
    input  wire        ctrl_clk,
    input  wire        ctrl_rst,
    //
    output wire [31:0] stat_freq0
);

  localparam integer CounterWrap = FREQUENCY / 1000 - 1;
  localparam integer CounterWidth = $clog2(CounterWrap);

  reg  [CounterWidth-1:0] counter;
  reg                     counter_warp;

  reg  [            31:0] freq0_counter;
  wire                    freq0_pulse;

  always @(posedge ctrl_clk) begin
    if (ctrl_rst) begin
      counter <= 'd0;
    end else begin
      counter <= counter + 1'd1;
      // Assuming ctrl_clk is 100 MHz, this gives a 1 ms interval
      if (counter == CounterWrap) begin
        counter <= 'd0;
      end
    end
  end

  always @(posedge ctrl_clk) begin
    counter_warp <= (counter == CounterWrap);
  end

  // Per clock frequency tester

  always @(posedge clk) begin
    if (rst || freq0_pulse) begin
      freq0_counter <= 32'd0;
    end else begin
      freq0_counter <= freq0_counter + 1'd1;
    end
  end

  cdc_pulse #(
      .DEST_SYNC_FF(4),
      .INIT_SYNC_FF(1),
      .REG_OUTPUT  (0),
      .RST_USED    (0)
  ) i_cdc_counter_wrap (
      .src_clk   (ctrl_clk),
      .src_rst   (ctrl_rst),
      .src_pulse (counter_warp),
      //
      .dest_clk  (clk),
      .dest_rst  (rst),
      .dest_pulse(freq0_pulse)
  );

  cdc_handshake_f #(
      .DEST_EXT_HSK(1),
      .DEST_SYNC_FF(4),
      .INIT_SYNC_FF(0),
      .SRC_SYNC_FF (4),
      .WIDTH       (32)
  ) i_cdc_freq0_counter (
      .src_clk   (clk),
      .src_in    (freq0_counter),
      .src_valid (freq0_pulse),
      .src_ready (  /* not used */),
      //
      .dest_clk  (ctrl_clk),
      .dest_out  (stat_freq0),
      .dest_valid(  /* not used */),
      .dest_ready(1'b1)
  );

endmodule

`default_nettype wire
