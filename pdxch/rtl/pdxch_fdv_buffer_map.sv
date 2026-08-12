`timescale 1 ns / 1 ps
//
`default_nettype none

// Map a logical complex-RE index to the packed IQ and exponent memories.
//
// One IQ RAM word contains two complex REs (36 bits). One exponent word is
// shared by four complex REs, so one PRB occupies three exponent words. The
// two ping-pong banks are placed in consecutive address ranges.
module pdxch_fdv_buffer_map #(
    parameter int HALF_BLOCK = 0
) (
    input var         bank,
    input var  [11:0] logical_re,
    output var [11:0] iq_addr,
    output var [11:0] exp_addr,
    output var        iq_half
);

  localparam int IQ_BANK_DEPTH = (HALF_BLOCK != 0) ? 1024 : 1792;
  localparam int EXP_BANK_DEPTH = (HALF_BLOCK != 0) ? 480 : 825;
  localparam int MAX_PRB = (HALF_BLOCK != 0) ? 160 : 275;

  initial begin : drc_check
    assert (IQ_BANK_DEPTH > 0 && EXP_BANK_DEPTH > 0)
    else $error("[%m]: invalid FDV buffer bank depth");

    assert (EXP_BANK_DEPTH >= MAX_PRB * 3)
    else $error("[%m]: EXP bank depth (%0d) cannot hold MAX_PRB (%0d).", EXP_BANK_DEPTH, MAX_PRB);

    assert (IQ_BANK_DEPTH >= MAX_PRB * 6)
    else $error("[%m]: IQ bank depth (%0d) cannot hold MAX_PRB (%0d).", IQ_BANK_DEPTH, MAX_PRB);
  end

  assign iq_half = logical_re[0];

  always_comb begin
    iq_addr  = logical_re >> 1;
    exp_addr = logical_re >> 2;
    if (bank) begin
      iq_addr  = iq_addr + 12'(IQ_BANK_DEPTH);
      exp_addr = exp_addr + 12'(EXP_BANK_DEPTH);
    end
  end

endmodule

`default_nettype wire
