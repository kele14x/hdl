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
    parameter reg     ASYNC = 1'b1,
    parameter reg     MODE  = 1'b1,  // 0 for UL, 1 for DL
    parameter integer FREQ  = 32,    // 32: 122.88, 64: 245.76, 128: 491.52
    parameter reg     AUTO  = 1'b0,  // 1: Auto roll over, 0: Manual roll over
    parameter reg     INIT  = 1'b0
) (
    input  wire        clk,
    input  wire        rst,
    //
    input  wire        sync,
    //
    output reg         start_of_frame,
    output reg         start_of_slot,
    output reg  [ 1:0] start_of_symbol,  // {mu1, mu0}
    //
    input  wire [22:0] ctrl_delay,
    output reg         stat_resync
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

  // Frome `sync` to `start_of_frame`, not counting the async regs
  localparam integer Latency = 1;

  wire        sync_s0;
  reg         sync_s1;
  wire        sync_posedge;

  reg         delay_state;
  reg  [22:0] delay_counter;

  wire        delayed_pulse;

  wire        restart;
  wire        restart_init;
  wire        restart_ext;
  wire        restart_auto;

  reg         init_n;
  reg         state;

  wire        symbol_wrap;
  reg         slot_wrap;
  wire        frame_wrap;

  reg  [14:0] sample_counter;
  reg  [14:0] sample_counter_max;

  reg  [ 8:0] symbol_id;

  // Pulse posedge detector

  generate
    if (ASYNC) begin : g_async_cdc

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

  always @(posedge clk) begin
    sync_s1 <= sync_s0;
  end

  assign sync_posedge = sync_s0 && ~sync_s1;

  // Delay the pulse

  always @(posedge clk) begin
    if (rst) begin
      delay_counter <= 0;
    end else if (delay_counter == ctrl_delay) begin
      delay_counter <= 0;
    end else if (sync_posedge || delay_state) begin
      delay_counter <= delay_counter + 1'b1;
    end
  end

  always @(posedge clk) begin
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
  assign restart_init = (AUTO && INIT && ~init_n);

  generate
    if (ASYNC && AUTO) begin : g_async_resync

      // Tolerate +-1 clock error caused by CDC

      reg restart_ext_omit;

      always @(posedge clk) begin
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
  assign restart_auto = (AUTO && frame_wrap);

  assign restart = restart_init || restart_ext || restart_auto;

  // FSM

  always @(posedge clk) begin
    if (rst) begin
      init_n <= 1'b0;
    end else begin
      init_n <= 1'b1;
    end
  end

  always @(posedge clk) begin
    if (rst) begin
      state <= 1'b0;
    end else if (restart) begin
      state <= 1'b1;
    end else if (frame_wrap) begin
      state <= 1'b0;
    end
  end

  always @(posedge clk) begin
    if ((MODE == 1'b0 && symbol_id % 14 == 13) || (MODE == 1'b1 && symbol_id % 14 == 0)) begin
      sample_counter_max <= (128 + 11) * FREQ - 1;
    end else begin
      sample_counter_max <= (128 + 9) * FREQ - 1;
    end
  end

  assign symbol_wrap = (sample_counter == sample_counter_max);

  always @(*) begin : p_slot_wrap
    integer s;
    slot_wrap = 1'b0;
    for (s = 0; s < 20; s = s + 1) begin
      if ((symbol_id == s * 14 + 13) && symbol_wrap) begin
        slot_wrap = 1'b1;
      end
    end
  end

  assign frame_wrap = symbol_wrap && (symbol_id == 279);

  // Sample counter
  always @(posedge clk) begin
    if (rst) begin
      sample_counter <= 0;
    end else if (~init_n || restart || symbol_wrap) begin
      sample_counter <= 0;
    end else if (state) begin
      sample_counter <= sample_counter + 1'b1;
    end
  end

  // Symbol counter
  always @(posedge clk) begin
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
  always @(posedge clk) begin
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
  always @(posedge clk) begin
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
  always @(posedge clk) begin
    if (rst) begin
      start_of_frame <= 1'b0;
    end else if (restart) begin
      start_of_frame <= 1'b1;
    end else begin
      start_of_frame <= 1'b0;
    end
  end

  // Status

  always @(posedge clk) begin
    stat_resync <= restart_ext ^ frame_wrap;
  end

endmodule

`default_nettype wire
