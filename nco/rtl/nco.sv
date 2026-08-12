/**
 * NCO (Numerically Controlled Oscillator)
 *
 * This module implements a Numerically Controlled Oscillator (NCO) with the following features:
 * - Configurable phase control word width (integer and fractional parts)
 * - Supports parallel output (multi-phase) with 1, 2, or 4 phases
 * - Uses a Linear Feedback Shift Register (LFSR) for phase accumulator
 * - Generates both cosine and sine outputs
 * - Synchronization input for resetting the phase accumulator
 * - Configurable phase offset and phase increment inputs
 *
 * Parameters:
 * - NUM_PARALLEL: Number of parallel outputs (1, 2, or 4)
 * - PHASE_INTEGER_WIDTH: Integer bit width of phase control word
 * - PHASE_FRACTION_WIDTH: Fractional bit width of phase control word
 * - LFSR_INITIAL: Initial state of LFSR (non-zero)
 * - LFSR_POLYNOMIAL: Polynomial of LFSR
 *
 * Inputs:
 * - clk: System clock
 * - rst: Reset signal
 * - sync: Synchronization signal to reset phase accumulator
 * - ctrl_poff: Phase offset control
 * - ctrl_pinc: Phase increment control
 *
 * Outputs:
 * - cos: Cosine output(s)
 * - sin: Sine output(s)
 *
 * The NCO uses a look-up table (LUT) approach for generating sine and cosine waveforms,
 * with the phase accumulator implemented using an LFSR for improved spectral purity.
 *
 * Latency: 6 (from `sync` to `cos`/`sin`)
 *
 * TODO:
 * - Add automatic LFSR polynomial selection
 * - Sync the frequency control word with sync signal
 */
`timescale 1 ns / 1 ps
//
`default_nettype none

module nco #(
    parameter                            NUM_PARALLEL         = 1,
    parameter                            PHASE_INTEGER_WIDTH  = 12,
    parameter                            PHASE_FRACTION_WIDTH = 20,
    parameter [PHASE_FRACTION_WIDTH-1:0] LFSR_INITIAL         = 20'hFFFFF,
    parameter [  PHASE_FRACTION_WIDTH:0] LFSR_POLYNOMIAL      = 21'h100005
) (
    input var clk,
    input var rst,
    //
    input var sync,
    //
    output var [NUM_PARALLEL*16-1:0] cos,
    output var [NUM_PARALLEL*16-1:0] sin,
    //
    input var [$clog2(NUM_PARALLEL)+PHASE_INTEGER_WIDTH+PHASE_FRACTION_WIDTH-1:0] ctrl_poff,
    input var [$clog2(NUM_PARALLEL)+PHASE_INTEGER_WIDTH+PHASE_FRACTION_WIDTH-1:0] ctrl_pinc
);

  // Local parameters

  // Integer bit width for multi-phase parallel arch
  localparam int PhaseParallelWidth = $clog2(NUM_PARALLEL);
  // Total bit with of phase control word
  localparam int PhaseWidth = PhaseParallelWidth + PHASE_INTEGER_WIDTH + PHASE_FRACTION_WIDTH;

  // Check parameters

  initial begin : drc_check
    assert (PHASE_INTEGER_WIDTH >= 4 && PHASE_INTEGER_WIDTH <= 12)
    else $error("[%m]: PHASE_INTEGER_WIDTH (%d) must be within the range 4 to 12.",
                PHASE_INTEGER_WIDTH);

    assert (PHASE_FRACTION_WIDTH >= 0 && PHASE_FRACTION_WIDTH <= 20)
    else $error("[%m]: PHASE_FRACTION_WIDTH (%d) must be within the range 0 to 20.",
                PHASE_FRACTION_WIDTH);

    assert (NUM_PARALLEL == 1 || NUM_PARALLEL == 2 || NUM_PARALLEL == 4)
    else $error("[%m]: NUM_PARALLEL (%d) must be 1, 2 or 4.", NUM_PARALLEL);
  end

  // Signals

  logic       [          PhaseWidth-1:0] phase_accumulator;
  wire        [          PhaseWidth-1:0] phase_wrapped;
  wire        [            PhaseWidth:0] phase_pre_round   [0:NUM_PARALLEL-1];

  wire        [PHASE_FRACTION_WIDTH-1:0] lfsr;

  logic       [ PHASE_INTEGER_WIDTH-1:0] phase_int         [0:NUM_PARALLEL-1];

  wire signed [                    15:0] cos_s             [0:NUM_PARALLEL-1];
  wire signed [                    15:0] sin_s             [0:NUM_PARALLEL-1];

  genvar i;

  function [PhaseWidth-1:0] wrap_2pi;
    input [PhaseWidth:0] phase;
    logic [PhaseWidth:0] phase_mod;
    begin
      // equals to wrap_2pi = phase % Phase2Pi;
      phase_mod = phase;
      if (phase_mod[PhaseWidth-:3] >= 3'b011) begin
        phase_mod[PhaseWidth-:3] = phase_mod[PhaseWidth-:3] - 3'b011;
      end
      wrap_2pi = phase_mod[PhaseWidth-1:0];
    end
  endfunction

  function [PhaseWidth:0] wrap_int;
    input [PhaseWidth:0] phase;
    begin
      // equals to wrap_int = phase % (Phase2Pi / NUM_PARALLEL);
      wrap_int = phase;
      wrap_int[PhaseWidth-:(3+PhaseParallelWidth)] = wrap_int[PhaseWidth-:(3+PhaseParallelWidth)] % 3;
    end
  endfunction

  // Main

  // #1, Phase accumulator

  always_ff @(posedge clk) begin
    if (rst) begin
      phase_accumulator <= 0;
    end else if (sync) begin
      phase_accumulator <= ctrl_poff;
    end else begin
      phase_accumulator <= phase_wrapped;
    end
  end

  // Phase accumulator increase by ctrl_pinc every tick. It will eventually
  // exceed 2*Pi (Phase2Pi), and need to be wrapped. Unlike 2^N phase case,
  // phase in modulus M mode does not wrap naturally. Wrap could be done
  // by subtract by Phase2Pi.
  assign phase_wrapped = wrap_2pi({1'b0, phase_accumulator} + {1'b0, ctrl_pinc});

  // #2, Random rounding and wrap again

  generate
    for (i = 0; i < NUM_PARALLEL; i = i + 1) begin : g_phase_int

      assign phase_pre_round[i] = wrap_int(
          {1'b0, phase_accumulator}
          + {{(PhaseWidth + 1 - PHASE_FRACTION_WIDTH) {1'b0}}, lfsr}
          + ({1'b0, ctrl_pinc} * i / NUM_PARALLEL)
      );

      always_ff @(posedge clk) begin
        phase_int[i] <= phase_pre_round[i][PHASE_INTEGER_WIDTH+PHASE_FRACTION_WIDTH-1:PHASE_FRACTION_WIDTH];
      end

    end
  endgenerate

  lfsr #(
      .BIT_WIDTH      (PHASE_FRACTION_WIDTH),
      .INITIAL        (LFSR_INITIAL),
      .POLYNOMIAL     (LFSR_POLYNOMIAL),
      .STRUCTURE      ("FIBONACCI"),
      .GATE_TYPE      ("XOR"),
      .PARALLEL_OUTPUT(1)
  ) i_lfsr (
      .clk (clk),
      .rst (rst || sync),
      .en  (1'b1),
      .load(1'b0),
      .din ({PHASE_FRACTION_WIDTH{1'b1}}),
      .dout(lfsr)
  );

  // Phase to Cosine/sine LUT

  generate
    for (i = 0; i < NUM_PARALLEL; i = i + 1) begin : g_lut

      dds_lut #(
          .STRUCTURE   ("AUTO"),
          .RASTERIZED  (1),
          .PHASE_WIDTH (PHASE_INTEGER_WIDTH),
          .NEGATIVE_COS(0),
          .NEGATIVE_SIN(0)
      ) i_lut (
          .clk    (clk),
          .rst    (rst),
          //
          .phase  (phase_int[i]),
          //
          .cos_out(cos_s[i]),
          .sin_out(sin_s[i])
      );

      assign cos[i*16+15-:16] = cos_s[i];
      assign sin[i*16+15-:16] = sin_s[i];

    end
  endgenerate

endmodule

`default_nettype wire
