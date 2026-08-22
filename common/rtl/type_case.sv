/**
 * Signed type-case: sign extension, LSB truncation/padding, rounding and
 * saturation.
 *
 * Converts a signed integer of IN_WIDTH bits to a signed integer of OUT_WIDTH
 * bits, optionally dropping TRUNC LSBs (TRUNC > 0) or padding -TRUNC zero LSBs
 * (TRUNC < 0) first. When ROUND is set and TRUNC > 0, the dropped LSBs are
 * rounded to nearest with ties to even (IEEE 754 default) before truncation.
 * The result is sign-extended when the effective input is narrower than
 * OUT_WIDTH, and saturated (or wrapped) to the signed OUT_WIDTH range when it
 * is wider. The ovf output flags overflow/underflow, i.e. an input value that
 * does not fit the signed OUT_WIDTH range.
 *
 * Parameters:
 * - IN_WIDTH:  input width in bits (must be positive)
 * - OUT_WIDTH: output width in bits (must be positive)
 * - TRUNC:     LSBs dropped from the input (>= 0) or zero bits padded to the
 *              LSB side (< 0). Must keep the effective width IN_WIDTH - TRUNC
 *              positive.
 * - ROUND:     1: round the dropped LSBs to nearest, ties to even
 *              0: plain truncation
 * - SATURATE:  1: clamp out-of-range values to the signed OUT_WIDTH range
 *              0: keep the low OUT_WIDTH bits (wraparound), ovf still set
 *
 * Ports (all combinational):
 * - din:  signed input of IN_WIDTH bits
 * - dout: signed output of OUT_WIDTH bits
 * - ovf:  1 when din does not fit the signed OUT_WIDTH range after LSB
 *         truncation/padding and rounding
 */

`timescale 1 ns / 1 ps
//
`default_nettype none

module type_case #(
    parameter int IN_WIDTH  = 16,
    parameter int OUT_WIDTH = 16,
    //
    parameter int TRUNC     = 0,
    //
    parameter int ROUND     = 0,
    parameter int SATURATE  = 1
) (
    /* verilator lint_off UNUSEDSIGNAL */
    input var  signed [ IN_WIDTH-1:0] din,
    /* verilator lint_on UNUSEDSIGNAL */
    //
    output var signed [OUT_WIDTH-1:0] dout,
    output var                        ovf
);

  // Width of the signed value after dropping TRUNC LSBs (TRUNC > 0) or padding
  // (-TRUNC) zero LSBs (TRUNC < 0).
  localparam int EffWidth = IN_WIDTH - TRUNC;

  // One extra bit is kept through the rounding/truncation so that a round-up
  // beyond the effective width is caught by the saturation check instead of
  // wrapping. Diff is the width gap between the kept value and OUT_WIDTH.
  localparam int Diff = EffWidth + 1 - OUT_WIDTH;

  initial begin : drc_check
    assert (IN_WIDTH >= 1)
    else $error("[%m]: IN_WIDTH (%0d) must be positive.", IN_WIDTH);

    assert (OUT_WIDTH >= 1)
    else $error("[%m]: OUT_WIDTH (%0d) must be positive.", OUT_WIDTH);

    assert (EffWidth >= 1)
    else
      $error(
          "[%m]: TRUNC (%0d) leaves an effective width of %0d bits, which is not positive.",
          TRUNC,
          EffWidth
      );

    assert (ROUND == 0 || ROUND == 1)
    else $error("[%m]: ROUND (%0d) value is outside of valid range.", ROUND);

    assert (SATURATE == 0 || SATURATE == 1)
    else $error("[%m]: SATURATE (%0d) value is outside of valid range.", SATURATE);
  end

  // Sign-extended input with one bit of headroom.
  /* verilator lint_off UNUSEDSIGNAL */
  wire signed [IN_WIDTH:0] din_wide;
  /* verilator lint_on UNUSEDSIGNAL */

  assign din_wide = {din[IN_WIDTH-1], din};

  // Effective value after LSB truncation or zero padding, with headroom.
  // ROUND avoids a full-width bias add: the dropped LSBs are truncated first
  // (plain floor for two's complement), then a single 1-bit round_up increment
  // is added to the kept bits. round_up = 1 when the dropped LSBs exceed half
  // an LSB, or land exactly on half with the kept LSB set (ties to even).
  wire signed [EffWidth:0] val;

  generate
    if (TRUNC >= 0) begin : g_trunc
      if (ROUND != 0 && TRUNC > 0) begin : g_rnd
        wire lsb_any;
        if (TRUNC >= 2) begin : g_lsb
          assign lsb_any = |din[TRUNC-2:0];
        end else begin : g_nolsb
          assign lsb_any = 1'b0;
        end

        wire round_up;
        assign round_up = din[TRUNC-1] & (din[TRUNC] | lsb_any);
        /* verilator lint_off WIDTHEXPAND */
        assign val = {din[IN_WIDTH-1], din[IN_WIDTH-1:TRUNC]} + {1'b0, round_up};
        /* verilator lint_on WIDTHEXPAND */
      end else begin : g_nornd
        assign val = din_wide[IN_WIDTH:TRUNC];
      end
    end else begin : g_pad
      assign val = {din_wide, {(-TRUNC) {1'b0}}};
    end
  endgenerate

  generate
    if (Diff > 0) begin : g_chk
      wire in_range;
      assign in_range = &val[EffWidth:OUT_WIDTH-1] || ~|val[EffWidth:OUT_WIDTH-1];
      assign ovf = ~in_range;

      if (SATURATE != 0) begin : g_sat
        assign dout = in_range ? val[OUT_WIDTH-1:0] :
                      val[EffWidth] ? {1'b1, {(OUT_WIDTH-1){1'b0}}} : {1'b0, {(OUT_WIDTH-1){1'b1}}};
      end else begin : g_wrap
        assign dout = val[OUT_WIDTH-1:0];
      end
    end else begin : g_fit
      assign ovf  = 1'b0;
      assign dout = {{(-Diff) {val[EffWidth]}}, val};
    end
  endgenerate

endmodule

`default_nettype wire
