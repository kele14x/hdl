/*
 * symbol_timer module
 *
 * This module implements a symbol timer for a communication system.
 * It generates timing signals for symbols based on the provided parameters
 * such as ASYNC, MODE, and FREQ.
 *
 * Parameters:
 *   - ASYNC: 1'b1 (asynchronous operation flag)
 *   - MODE: 1'b1 (0 for UL, 1 for DL)
 *   - FREQ: 32 (frequency setting, where 32: 122.88, 64: 245.76, 128: 491.52)
 *
 * Inputs:
 *   - clk: Clock signal
 *   - rst: Reset signal
 *   - sync: Synchronization signal
 *   - ctrl_delay: 23-bit control delay input
 *
 * Outputs:
 *   - start_of_frame: Indicates the start of a frame
 *   - start_of_slot: Indicates the start of a slot
 *   - start_of_symbol: 2-bit output indicating the start of a symbol
 *   - symbol_id: 9-bit output representing the symbol ID
 *   - stat_resync: Status output for resynchronization
 */

`timescale 1 ns / 1 ps
//
`default_nettype none

module symbol_timer #(
    parameter int     ASYNC = 1,
    parameter int     MODE  = 1,  // 0 for UL, 1 for DL
    parameter integer FREQ  = 32,    // 32: 122.88, 64: 245.76, 128: 491.52
    parameter int     AUTO  = 0,  // 1: Auto roll over, 0: Manual roll over
    parameter int     INIT  = 0
) (
    input  wire         clk,
    input  wire         rst,
    //
    input  wire         sync,
    //
    output logic        start_of_frame,
    output logic        start_of_slot,
    output logic [ 1:0] start_of_symbol,  // {mu1, mu0}
    //
    input  wire  [22:0] ctrl_delay,
    output logic        stat_resync
);

  //------------------------------------------------------------------
  // Numerology (u):                           |        0 |        1 |
  //------------------------------------------------------------------
  // Sub-carrier spacing:                      |       15 |       30 |
  //------------------------------------------------------------------
  // Radio frame time:                         |     10ms |     10ms |
  // Sub-frame time:                           |      1ms |      1ms |
  //------------------------------------------------------------------
  // Number of sub-frame per radio frame:      |       10 |       10 |
  // Number of slot or sub-frame:              |        1 |        2 |
  // Number of slot/sub-frame per radio frame: |       10 |       20 |
  // Number of symbol per slot/sub-frame:      |       14 |       14 |
  // Number of symbol per radio frame:         |      140 |      280 |
  // Number of symbol per CP loop:             |        7 |       14 |
  // Number of CP loop per radio frame:        |       20 |       20 |
  // Number of sample points of first symbol:  | 4096+320 | 2048+176 |
  // Number of sample points of left symbol:   | 4096+288 | 2048+144 |
  //------------------------------------------------------------------
  // 491.52 MHz clock:                                               |
  //------------------------------------------------------------------
  // Clock ticks per radio frame:              |  4915200 |  4915200 |
  // Clock ticks per slot/sub-frame:           |   491520 |   245760 |
  // Clock ticks per symbol (average):         |    35109 |    17554 |
  // Clock ticks of first symbol:              |    35328 |    17792 |
  // Clock ticks of left symbol:               |    35072 |    17536 |
  //------------------------------------------------------------------
  // SIM Speedup (3.84 MHz) clock:                                   |
  //------------------------------------------------------------------
  // Clock ticks per radio frame:              |    38400 |    38400 |
  // Clock ticks per slot/sub-frame:           |     3840 |     1920 |
  // Clock ticks per symbol (average):         |   274.29 |   137.14 |
  // Clock ticks of first symbol:              |      276 |      139 |
  // Clock ticks of left symbol:               |      274 |      137 |
  //------------------------------------------------------------------

  wire         sync_s0;
  logic        sync_s1;
  wire         sync_posedge;

  logic        delay_state;
  logic [22:0] delay_counter;

  wire         delayed_pulse;

  wire         restart;
  wire         restart_init;
  wire         restart_ext;
  wire         restart_auto;

  logic        init_n;
  logic        state;

  wire         symbol_wrap;
  logic        slot_wrap;
  wire         frame_wrap;

  logic [14:0] sample_counter;
  logic [14:0] sample_counter_max;

  logic [ 8:0] symbol_id;

  localparam [31:0] LongSymbolSamplesFull = (128 + 11) * FREQ - 1;
  localparam [31:0] ShortSymbolSamplesFull = (128 + 9) * FREQ - 1;
  localparam [14:0] LongSymbolSamples = LongSymbolSamplesFull[14:0];
  localparam [14:0] ShortSymbolSamples = ShortSymbolSamplesFull[14:0];

  function [8:0] slot_last_symbol;
    input integer slot;
    begin
      case (slot)
        0: slot_last_symbol = 9'd13;
        1: slot_last_symbol = 9'd27;
        2: slot_last_symbol = 9'd41;
        3: slot_last_symbol = 9'd55;
        4: slot_last_symbol = 9'd69;
        5: slot_last_symbol = 9'd83;
        6: slot_last_symbol = 9'd97;
        7: slot_last_symbol = 9'd111;
        8: slot_last_symbol = 9'd125;
        9: slot_last_symbol = 9'd139;
        10: slot_last_symbol = 9'd153;
        11: slot_last_symbol = 9'd167;
        12: slot_last_symbol = 9'd181;
        13: slot_last_symbol = 9'd195;
        14: slot_last_symbol = 9'd209;
        15: slot_last_symbol = 9'd223;
        16: slot_last_symbol = 9'd237;
        17: slot_last_symbol = 9'd251;
        18: slot_last_symbol = 9'd265;
        19: slot_last_symbol = 9'd279;
        default: slot_last_symbol = 9'd0;
      endcase
    end
  endfunction

  // Pulse posedge detector

  generate
    if (ASYNC != 0) begin : g_async_cdc

      async_input_sync #(
          .SYNC_STAGES    (3),
          .PIPELINE_STAGES(1),
          .INIT           (0)
      ) i_async_sync (
          .clk     (clk),
          .async_in(sync),
          .sync_out(sync_s0)
      );

    end else begin : g_no_async_cdc

      assign sync_s0 = sync;

    end
  endgenerate

  always_ff @(posedge clk) begin
    sync_s1 <= sync_s0;
  end

  assign sync_posedge = sync_s0 && ~sync_s1;

  // Delay the pulse

  always_ff @(posedge clk) begin
    if (rst) begin
      delay_counter <= 0;
    end else if (delay_counter == ctrl_delay) begin
      delay_counter <= 0;
    end else if (sync_posedge || delay_state) begin
      delay_counter <= delay_counter + 1'b1;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      delay_state <= 1'b0;
    end else if (delay_counter == ctrl_delay) begin
      delay_state <= 1'b0;
    end else if (sync_posedge) begin
      delay_state <= 1'b1;
    end
  end

  // ctrl_delay = 0: zero delay
  assign delayed_pulse = (sync_posedge && ctrl_delay == 0) ||
    (delay_state && delay_counter == ctrl_delay);

  // Restart to the counters

  // Automatic start the counters after reset is de-assert
  assign restart_init = ((AUTO != 0) && (INIT != 0) && ~init_n);

  generate
    if ((ASYNC != 0) && (AUTO != 0)) begin : g_async_resync

      // Tolerate +-1 clock error caused by CDC

      logic restart_ext_omit;

      always_ff @(posedge clk) begin
        if (rst) begin
          restart_ext_omit <= 1'b0;
        end else if (restart_auto) begin
          restart_ext_omit <= 1'b1;
        end else begin
          restart_ext_omit <= 1'b0;
        end
      end

      assign restart_ext = delayed_pulse && ~restart_ext_omit;

    end else begin : g_sync_resync

      assign restart_ext = delayed_pulse;

    end
  endgenerate

  // Auto restart (roll over) the counters when one frame is over
  assign restart_auto = ((AUTO != 0) && frame_wrap);

  assign restart = restart_init || restart_ext || restart_auto;

  // FSM

  always_ff @(posedge clk) begin
    if (rst) begin
      init_n <= 1'b0;
    end else begin
      init_n <= 1'b1;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      state <= 1'b0;
    end else if (restart) begin
      state <= 1'b1;
    end else if (frame_wrap) begin
      state <= 1'b0;
    end
  end

  always_ff @(posedge clk) begin
        if (((MODE == 0) && symbol_id % 14 == 13) ||
            ((MODE != 0) && symbol_id % 14 == 0)) begin
      sample_counter_max <= LongSymbolSamples;
    end else begin
      sample_counter_max <= ShortSymbolSamples;
    end
  end

  assign symbol_wrap = (sample_counter == sample_counter_max);

  always_comb begin : p_slot_wrap
    integer s;
    slot_wrap = 1'b0;
    for (s = 0; s < 20; s = s + 1) begin
      if ((symbol_id == slot_last_symbol(s)) && symbol_wrap) begin
        slot_wrap = 1'b1;
      end
    end
  end

  assign frame_wrap = symbol_wrap && (symbol_id == 279);

  // Sample counter
  always_ff @(posedge clk) begin
    if (rst) begin
      sample_counter <= 0;
    end else if (~init_n || restart || symbol_wrap) begin
      sample_counter <= 0;
    end else if (state) begin
      sample_counter <= sample_counter + 1'b1;
    end
  end

  // Symbol counter
  always_ff @(posedge clk) begin
    if (rst) begin
      symbol_id <= 0;
    end else if (~init_n || restart || frame_wrap) begin
      symbol_id <= 0;
    end else if (symbol_wrap && state) begin
      symbol_id <= symbol_id + 1'b1;
    end
  end

  // Output

  // Symbol start strobe output
  always_ff @(posedge clk) begin
    if (rst) begin
      start_of_symbol <= 2'b00;
    end else if (restart) begin
      start_of_symbol <= 2'b11;
    end else begin
      start_of_symbol <= 2'b00;
      if (symbol_wrap && symbol_id[0] && ~frame_wrap) begin
        start_of_symbol[0] <= 1'b1;
      end
      if (symbol_wrap && ~frame_wrap) begin
        start_of_symbol[1] <= 1'b1;
      end
    end
  end

  // 500 us strobe output
  always_ff @(posedge clk) begin
    if (rst) begin
      start_of_slot <= 1'b0;
    end else if (restart) begin
      start_of_slot <= 1'b1;
    end else begin
      start_of_slot <= 1'b0;
      if (slot_wrap && ~frame_wrap) begin
        start_of_slot <= 1'b1;
      end
    end
  end

  // 10 ms strobe output
  always_ff @(posedge clk) begin
    if (rst) begin
      start_of_frame <= 1'b0;
    end else if (restart) begin
      start_of_frame <= 1'b1;
    end else begin
      start_of_frame <= 1'b0;
    end
  end

  // Status

  always_ff @(posedge clk) begin
    stat_resync <= restart_ext ^ frame_wrap;
  end

endmodule

`default_nettype wire
