`timescale 1 ns / 1 ps `default_nettype none

module symbol_timing #(
    parameter int NUM_CC = 2
) (
    // XORIF Timer
    //============
    input var         clk_400m,
    input var         rst_400m,
    output var        defm_radio_start_10ms,
    output var        fram_radio_start_10ms,
    // Adaptor Timer
    //==============
    input var         clk_491m52,
    input var         rst_491m52,
    // Timing base
    input var         dl_radio_start_10ms,
    input var         ul_radio_start_10ms,
    // adaptor timer
    output var [11:0] dl_sym_num           [NUM_CC],
    output var [11:0] ul_sym_num           [NUM_CC],
    output var        dl_sym_update        [NUM_CC],
    output var        ul_sym_update        [NUM_CC],
    // Control Interface
    //==================
    input var  [ 1:0] ctrl_numerology      [NUM_CC]  // 0 = u0, 1 = u1, 2 = u2, 3 = u2.Ext
);

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
      .dest_pulse(defm_radio_start_10ms)
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
      .dest_pulse(fram_radio_start_10ms)
  );

  generate
    for (genvar i = 0; i < NUM_CC; i++) begin : g_numerology_counter
      numerology_counter i_numerology_counter_dl (
          .clk_491m52      (clk_491m52),
          .rst_491m52      (rst_491m52),
          //
          .radio_start_10ms(dl_radio_start_10ms),
          //
          .sym_num         (dl_sym_num[i]),
          .sym_update      (dl_sym_update[i]),
          //
          .ctrl_numerology (ctrl_numerology[i])
      );

      numerology_counter i_numerology_counter_ul (
          .clk_491m52      (clk_491m52),
          .rst_491m52      (rst_491m52),
          //
          .radio_start_10ms(ul_radio_start_10ms),
          //
          .sym_num         (ul_sym_num[i]),
          .sym_update      (ul_sym_update[i]),
          //
          .ctrl_numerology (ctrl_numerology[i])
      );
    end
  endgenerate

endmodule

module numerology_counter (
    input var         clk_491m52,
    input var         rst_491m52,
    // Timing base
    input var         radio_start_10ms,
    // adaptor timer
    output var [11:0] sym_num,
    output var        sym_update,
    // Control Interface
    //==================
    input var  [ 1:0] ctrl_numerology
);

  localparam DELAY_NUMEROLOGY_0 = (4096 + 320) * 8;
  localparam DELAY_NUMEROLOGY_1 = (4096 + 352) * 4;
  localparam DELAY_NUMEROLOGY_2 = (4096 + 416) * 2;
  localparam DELAY_NUMEROLOGY_2_EXT = (4096 + 1024) * 2;

  // Number of symbols per one radio frame
  // Note there will always be 10 subframe per one frame, but 1/2/4/4 slots
  // per one frame, and 14/14/14/12 symbols per one slot
  localparam int NUM_SYM_NUMEROLOGY_0 = 140;
  localparam int NUM_SYM_NUMEROLOGY_1 = 280;
  localparam int NUM_SYM_NUMEROLOGY_2 = 560;
  localparam int NUM_SYM_NUMEROLOGY_2_EXT = 480;

  localparam int NUM_TICK_NUMEROLOGY_0_7 = (4096 + 320) * 8;  // every 1/7 symbol has this length
  localparam int NUM_TICK_NUMEROLOGY_0 = (4096 + 288) * 8;

  localparam int NUM_TICK_NUMEROLOGY_1_14 = (4096 + 352) * 4;  // every 1/14 symbol has this length
  localparam int NUM_TICK_NUMEROLOGY_1 = (4096 + 288) * 4;

  localparam int NUM_TICK_NUMEROLOGY_2_28 = (4096 + 416) * 2;  // every 1/28 symbol has this length
  localparam int NUM_TICK_NUMEROLOGY_2 = (4096 + 288) * 2;

  localparam int NUM_TICK_NUMEROLOGY_2_EXT = (4096 + 1024) * 2;  // every symbol has this length

  logic [15:0] radio_start_counter;  // $clog2(NUM_TICK_NUMEROLOGY_0_7) = 16

  logic radio_start_delayed;

  logic [11:0] sym_counter;
  logic [11:0] sym_counter_max;

  logic [15:0] tick_counter;  // $clog2(NUM_TICK_NUMEROLOGY_0_7) = 16
  logic [15:0] tick_counter_max;

  logic [1:0] numerology;


  always_ff @(posedge clk_491m52) begin
    if (rst_491m52) begin
      numerology <= '0;
    end else if (radio_start_10ms) begin
      numerology <= ctrl_numerology;
    end else begin
      numerology <= numerology;
    end
  end

  always_ff @(posedge clk_491m52) begin
    if (rst_491m52 || radio_start_10ms) begin
      radio_start_counter <= '0;
    end else if (&radio_start_counter) begin
      radio_start_counter <= radio_start_counter;
    end else begin
      radio_start_counter <= radio_start_counter + 1;
    end
  end

  always_ff @(posedge clk_491m52) begin
    if (rst_491m52) begin
      radio_start_delayed <= '0;
    end else begin
      if (numerology == 0) begin
        radio_start_delayed <= radio_start_counter == DELAY_NUMEROLOGY_0;
      end else if (numerology == 1) begin
        radio_start_delayed <= radio_start_counter == DELAY_NUMEROLOGY_1;
      end else if (numerology == 2) begin
        radio_start_delayed <= radio_start_counter == DELAY_NUMEROLOGY_2;
      end else begin
        radio_start_delayed <= radio_start_counter == DELAY_NUMEROLOGY_2_EXT;
      end
    end
  end

  always_comb begin
    if (numerology == 0) begin
      tick_counter_max = (sym_counter % 7 == 0) ? (NUM_TICK_NUMEROLOGY_0_7 - 1) : (NUM_TICK_NUMEROLOGY_0 - 1);
    end else if (numerology == 1) begin
      tick_counter_max = (sym_counter % 14 == 0) ? (NUM_TICK_NUMEROLOGY_1_14 - 1) : (NUM_TICK_NUMEROLOGY_1 - 1);
    end else if (numerology == 2) begin
      tick_counter_max = (sym_counter % 28 == 0) ? (NUM_TICK_NUMEROLOGY_2_28 - 1) : (NUM_TICK_NUMEROLOGY_2 - 1);
    end else begin
      tick_counter_max = (NUM_TICK_NUMEROLOGY_2_EXT - 1);
    end
  end

  always_comb begin
    if (numerology == 0) begin
      sym_counter_max = NUM_SYM_NUMEROLOGY_0 - 1;
    end else if (numerology == 1) begin
      sym_counter_max = NUM_SYM_NUMEROLOGY_1 - 1;
    end else if (numerology == 2) begin
      sym_counter_max = NUM_SYM_NUMEROLOGY_2 - 1;
    end else begin
      sym_counter_max = NUM_SYM_NUMEROLOGY_2_EXT - 1;
    end
  end

  always_ff @(posedge clk_491m52) begin
    if (rst_491m52 || radio_start_delayed) begin
      tick_counter <= '0;
    end else begin
      tick_counter <= (tick_counter == tick_counter_max) ? 0 : tick_counter + 1;
    end
  end

  always_ff @(posedge clk_491m52) begin
    if (rst_491m52 || radio_start_delayed) begin
      sym_counter <= '0;
    end else if (tick_counter == tick_counter_max) begin
      if (sym_counter == sym_counter_max) begin
        sym_counter <= sym_counter;
      end else begin
        sym_counter <= sym_counter + 1;
      end
    end else begin
      sym_counter <= sym_counter;
    end
  end

  assign sym_num = sym_counter;

  always_ff @(posedge clk_491m52) begin
    if (rst_491m52) begin
      sym_update <= '0;
    end else begin
      sym_update <= radio_start_delayed || ((tick_counter == tick_counter_max) && ~(sym_counter == sym_counter_max));
    end
  end

endmodule

`default_nettype none
