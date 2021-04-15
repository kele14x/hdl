// File: symbol_timing.sv
// Brief: 10 ms radio start CDC
`timescale 1 ns / 1 ps `default_nettype none

module symbol_timing (
    // Adaptor Timer
    //==============
    input var         clk_491m52,
    input var         rst_491m52,
    // Timing base
    input var         dl_radio_start_10ms,
    input var         ul_radio_start_10ms,
    // XORIF Timer
    //============
    input var         clk_400m,
    input var         rst_400m,
    output var        defm_radio_start_10ms,
    output var        fram_radio_start_10ms
);

  logic dl_radio_start_10ms_sync;
  logic ul_radio_start_10ms_sync;

  logic [21:0] dl_counter;
  logic [21:0] ul_counter;


  xpm_cdc_pulse #(
      .DEST_SYNC_FF(2),
      .INIT_SYNC_FF(0),
      .REG_OUTPUT(1),
      .RST_USED(1),
      .SIM_ASSERT_CHK(0)
  ) i_cdc_dl_radio_start_10ms (
      .src_clk   (clk_491m52),
      .src_rst   (rst_491m52),
      .src_pulse (dl_radio_start_10ms),
      .dest_clk  (clk_400m),
      .dest_rst  (rst_400m),
      .dest_pulse(dl_radio_start_10ms_sync)
  );

  xpm_cdc_pulse #(
      .DEST_SYNC_FF(2),
      .INIT_SYNC_FF(0),
      .REG_OUTPUT(1),
      .RST_USED(1),
      .SIM_ASSERT_CHK(0)
  ) i_cdc_ul_radio_start_10ms (
      .src_clk   (clk_491m52),
      .src_rst   (rst_491m52),
      .src_pulse (ul_radio_start_10ms),
      .dest_clk  (clk_400m),
      .dest_rst  (rst_400m),
      .dest_pulse(ul_radio_start_10ms_sync)
  );

  // We need to tolerate 1 clock jitter caused by CDC buffer, since the 10 ms
  // radio start strobe is generated at 491.52 MHz radio clock. So we have an
  // counter here. The counter should run from 0 to 3999999 (number of 400 MHz x
  // 10 ms ticks). When 10 ms strobe arrived, the counter should be 0 or 3999998
  // or 3999999. If we see other value of counter, reset the counter (resync).
  always_ff @ (posedge clk_400m) begin
    if (rst_400m) begin
      dl_counter <= '0;
    end else if ((dl_radio_start_10ms_sync && dl_counter != 0 &&
      dl_counter != (4000000 - 1) && dl_counter != (4000000 - 2)) ||
      (dl_counter == 4000000 - 1)) begin
      dl_counter <= 0;
    end else begin
      dl_counter <= dl_counter + 1;
    end
  end

  always_ff @ (posedge clk_400m) begin
    if (rst_400m) begin
      ul_counter <= '0;
    end else if ((ul_radio_start_10ms_sync && ul_counter != 0 &&
      ul_counter != (4000000 - 1) && ul_counter != (4000000 - 2)) ||
      (ul_counter == 4000000 - 1)) begin
      ul_counter <= 0;
    end else begin
      ul_counter <= ul_counter + 1;
    end
  end

  // Generate the 10 ms strobe for XORIF, we can't generate it when counter is
  // 0, since the counter maybe reset to 0 often. And we don't want delay it too
  // much, so generate when counter reaches 1.
  always_ff @ (posedge clk_400m) begin
    if (rst_400m) begin
      defm_radio_start_10ms <= '0;
    end else begin
      defm_radio_start_10ms <= (dl_counter == 1);
    end
  end

  always_ff @ (posedge clk_400m) begin
    if (rst_400m) begin
      fram_radio_start_10ms <= '0;
    end else begin
      fram_radio_start_10ms <= (ul_counter == 1);
    end
  end

endmodule

`default_nettype none
