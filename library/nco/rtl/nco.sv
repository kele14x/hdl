// File: nco.sv
// Brief: Numerically-controlled oscillator (NCO) module for NR & LTE.
`timescale 1 ns / 1 ps
//
`default_nettype none

module nco #(
    parameter int PHASE_WIDTH   = 32,
    parameter int PHASE_ENTRIES = 3072,
    parameter int DATA_WIDTH    = 16
) (
    input var                           clk,
    input var                           rst,
    //
    input var                           sync,
    //
    output var signed [ DATA_WIDTH-1:0] cos,
    output var signed [ DATA_WIDTH-1:0] sin,
    //
    input var         [PHASE_WIDTH-1:0] ctrl_poff,
    input var         [PHASE_WIDTH-1:0] ctrl_pinc
);


  // Local parameters
  //=================

  localparam int Latency = 3;

  // Integer bit width of phase word
  localparam int PhaseIntegerWidth = $clog2(PHASE_ENTRIES);
  // Fraction bit width of phase word
  localparam int PhaseFractionWidth = PHASE_WIDTH - PhaseIntegerWidth;
  // LUT address with
  localparam int AddrWidth = PhaseIntegerWidth;

  // Notes:
  //
  //     1100_000000  - 2 * PI
  //     1001_000000  - 3 * PI / 2
  //     0110_000000  -     PI
  //     0011_000000  -     PI / 2
  //     0000_000000  -      0
  localparam bit [PhaseIntegerWidth-1:0] Phase2Pi = PHASE_ENTRIES;
  localparam bit [PhaseIntegerWidth-1:0] PhasePi = Phase2Pi / 2;
  localparam bit [PhaseIntegerWidth-1:0] PhasePi2 = Phase2Pi / 4;
  localparam bit [PhaseIntegerWidth-1:0] Phase3Pi2 = Phase2Pi - PhasePi2;

  localparam bit [PHASE_WIDTH-1:0] Modulus = Phase2Pi << PhaseFractionWidth;

  // Check parameters
  //=================

  initial begin
    assert (2 <= PHASE_WIDTH && PHASE_WIDTH <= 32)
    else begin
      $error("[%m]: Phase word width (PHASE_WIDTH) must be within the range 2 to 32, got %d.",
             PHASE_WIDTH);
      #1 $finish;
    end

    assert (PhaseFractionWidth >= 0)
    else begin
      $error("[%m]: Phase word width (PHASE_WIDTH) should be large enough to hold PHASE_ENTRIES");
      #1 $finish;
    end

    assert (PHASE_ENTRIES >= 12)
    else begin
      $error(
          "[%m]: Number of phase LUT entries (PHASE_ENTRIES) must be equal or lager than 12, got %d.",
          PHASE_ENTRIES);
      #1 $finish;
    end

    assert (Phase2Pi[PhaseIntegerWidth-1-:2] == 2'b11 && Phase2Pi[PhaseIntegerWidth-3:0] == '0)
    else begin
      $error(
          "[%m]: Number of phase LUT entries (PHASE_ENTRIES) must be as the form 3 * 2^n, got %d.",
          PHASE_ENTRIES);
      #1 $finish;
    end

    assert (3 <= DATA_WIDTH && DATA_WIDTH <= 26)
    else begin
      $error("[%m]: Data word width (DATA_WIDTH) must be within the range 3 to 26, got %d.",
             DATA_WIDTH);
      #1 $finish;
    end
  end


  // Signals
  //========

  logic [PHASE_WIDTH-1:0] phase_accumulator;
  logic [  PHASE_WIDTH:0] phase_wrapped;
  logic [  PHASE_WIDTH:0] phase_pre_round;
  logic [  PHASE_WIDTH:0] phase_round;

  logic [PhaseFractionWidth-1:0] lfsr;

  logic [PhaseIntegerWidth-1:0] phase_int;
  logic [PhaseIntegerWidth-1:0] phase_cos;
  logic [PhaseIntegerWidth-1:0] phase_sin;

  logic [AddrWidth-1:0] addr_cos;
  logic [AddrWidth-1:0] addr_sin;


  // Main
  //=====

  // Phase accumulator

  always @(posedge clk) begin
    if (rst) begin
      phase_accumulator <= '0;
    end else if (sync) begin
      phase_accumulator <= ctrl_poff;
    end else begin
      phase_accumulator <= phase_wrapped[PHASE_WIDTH-1:0];
    end
  end

  // Phase accumulator increase by ctrl_pinc every tick. It will eventually
  // exceed 2*Pi (Phase2Pi), and need to be wrapped. Unlike 2^N phase case,
  // phase in modulus M mode does not wrap naturally. Wrap could be done
  // by subtract by Phase2Pi.
  always_comb begin
    phase_wrapped = phase_accumulator + ctrl_pinc;
    if (phase_wrapped[PHASE_WIDTH-:3] >= 3'b011) begin
      phase_wrapped = {(phase_wrapped[PHASE_WIDTH-:3] - 3'b011), phase_wrapped[PHASE_WIDTH-3:0]};
    end
  end

  // Random rounding

  lfsr #(
      .BIT_WIDTH      (PhaseFractionWidth),
      .INITIAL        ({PhaseFractionWidth{1'b1}}),
      .POLYNOMIAL     ('b00000000000000001001),
      .STRUCTURE      ("FIBONACCI"),
      .GATE_TYPE      ("XOR"),
      .PARALLEL_OUTPUT(1'b1)
  ) i_lfsr (
      .clk (clk),
      .rst (sync),
      .en  (1'b1),
      .load(1'b0),
      .din ('0),
      .dout(lfsr)
  );

  always_comb begin
    phase_pre_round = phase_accumulator + lfsr;
    if (phase_pre_round[PHASE_WIDTH-:3] >= 3'b011) begin
      phase_pre_round = {(phase_pre_round[PHASE_WIDTH-:3] - 3'b011), phase_pre_round[PHASE_WIDTH-3:0]};
    end
  end

  always_ff @(posedge clk) begin
    phase_round <= phase_pre_round[PHASE_WIDTH-1-:PhaseIntegerWidth];
  end

  // Map sine phase to cosine phase

  always_comb begin
    phase_cos = phase_round;
  end

  // sin(x) = cos(x - pi/2), when x >= pi/2
  // sin(x) = cos(x + 3*pi/2), when x < pi/2
  always_comb begin
    if (phase_round < PhasePi2) begin
      phase_sin = phase_round + Phase3Pi2;
    end else begin
      phase_sin = phase_round - PhasePi2;
    end
  end

  // Use LSBs as LUT address

  always_ff @(posedge clk) begin
    addr_cos <= phase_cos[AddrWidth-1:0];
  end

  always_ff @(posedge clk) begin
    addr_sin <= phase_sin[AddrWidth-1:0];
  end

  // Phase to Cosine/sine LUT

  nco_lut #(
      .PHASE_ENTRIES(PHASE_ENTRIES),
      .DATA_WIDTH   (DATA_WIDTH)
  ) i_lut (
      .clk  (clk),
      //
      .rsta (rst),
      .ena  (1'b1),
      .addra(addr_cos),
      .douta(cos),
      //
      .rstb (rst),
      .enb  (1'b1),
      .addrb(addr_sin),
      .doutb(sin)
  );

endmodule

`default_nettype wire
