/*
 * Module: dds_lut
 *
 * Description:
 * This module implements a Direct Digital Synthesis (DDS) Look-Up Table (LUT)
 * for generating cosine and sine waveforms. It supports various LUT structures
 * (FULL, HALF, QUARTER) and optional rasterization for efficient implementation.
 *
 * Parameters:
 * - STRUCTURE:    LUT structure type ("AUTO", "FULL", "HALF", or "QUARTER")
 * - PHASE_WIDTH:  Width of the phase input
 * - RASTERIZED:   Enable rasterized mode (3/4 modulus)
 * - NEGATIVE_COS: Output negative cosine data
 * - NEGATIVE_SIN: Output negative sine data
 *
 * Ports:
 * - clk:     Clock input
 * - rst:     Reset input
 * - phase:   Phase input
 * - cos_out: Cosine output
 * - sin_out: Sine output
 *
 * The module uses trigonometric identities and LUT structure optimizations
 * to efficiently generate cosine and sine waveforms based on the input phase.
 *
 * Latency: 4
 *
 * TODO: Optimize the latency for different STRUCTURE
 */

`timescale 1 ns / 1 ps
//
`default_nettype none

module dds_lut #(
    parameter [8*7-1:0] STRUCTURE    = "AUTO",
    parameter logic       RASTERIZED   = 1'b0,
    parameter integer   DATA_WIDTH   = 16,
    parameter integer   PHASE_WIDTH  = 12,
    parameter logic       NEGATIVE_COS = 1'b0,
    parameter logic       NEGATIVE_SIN = 1'b0
) (
    input  wire                         clk,
    input  wire                         rst,
    //
    input  wire       [PHASE_WIDTH-1:0] phase,
    //
    output logic signed [ DATA_WIDTH-1:0] cos_out,
    output logic signed [ DATA_WIDTH-1:0] sin_out
);

  // Notes:
  //    cos(x) = cos(-x)
  //    sin(x) = -sin(-x)
  //   -cos(x) = cos(x + pi)
  //   -sin(x) = sin(x + pi)
  //    sin(x) = cos(x - pi / 2)
  //   -sin(x) = cos(x + pi / 2)

  // Parameters

  localparam MinPhaseWidth = RASTERIZED ? 4 : 2;

  localparam [8*7-1:0] StructureAuto = "AUTO";
  localparam [8*7-1:0] StructureFull = "FULL";
  localparam [8*7-1:0] StructureHalf = "HALF";
  localparam [8*7-1:0] StructureQuarter = "QUARTER";

  // Check parameters

  // verilog_format: off
  initial begin
    // Check STRUCTURE
    if(STRUCTURE != StructureAuto && STRUCTURE != StructureFull && STRUCTURE != StructureHalf && STRUCTURE != StructureQuarter) begin
      $fatal(1, "DDS structure (STRUCTURE) should be one of \"AUTO\", \"FULL\", \"HALF\" or \"QUARTER\", got %s. [%m]", STRUCTURE);
    end

    // Check PHASE_WIDTH
    if (PHASE_WIDTH < MinPhaseWidth || 14 < PHASE_WIDTH) begin
      $fatal(1, "DDS phase width (PHASE_WIDTH) should be with in range %0d to 14, got %0d. [%m]", MinPhaseWidth, PHASE_WIDTH);
    end
  end
  // verilog_format: on

  // When Phase Word Width (PHASE_WIDTH) is large, it's proper to store the
  // waveform into block memory. To save the block memory, it could only
  // store half or a quarter of the waveform and relies on the trigonometric
  // function to get the correct result.
  // When Phase Word Width is small, directly store the full waveform.
  localparam [8*7-1:0] StructureInternal = (STRUCTURE == StructureAuto) ?
    ((PHASE_WIDTH <= 9) ? StructureFull : (PHASE_WIDTH <= 11) ? StructureHalf : StructureQuarter) : STRUCTURE;

  localparam AddressWidth = (StructureInternal == StructureFull) ? PHASE_WIDTH :
    (StructureInternal == StructureHalf) ? (PHASE_WIDTH - 1): (PHASE_WIDTH - 2);

  // Note:
  // |                                    | Normal     | Rasterized   |
  // +------------------------------------+------------+--------------+
  // |          0 = 0                     | 00_0000... | 0000_0000... |
  // | 1 / 2 * pi = 2 ^ (PHASE_WIDTH - 2) | 01_0000... | 0011_0000... |
  // |         pi = 2 ^ (PHASE_WIDTH - 1) | 10_0000... | 0110_0000... |
  // | 3 / 2 * pi = 1 / 2 * pi + pi       | 11_0000... | 1001_0000... |
  // |     2 * pi = 2 ^ PHASE_WIDTH       | 00_0000... | 1100_0000... |
  localparam logic [PHASE_WIDTH-1:0] PhasePi2 = RASTERIZED ?
    ((1 << (PHASE_WIDTH - 3)) + (1 << (PHASE_WIDTH - 4))) : (1 << (PHASE_WIDTH - 2));
  localparam logic [PHASE_WIDTH-1:0] PhasePi = RASTERIZED ?
    ((1 << (PHASE_WIDTH - 2)) + (1 << (PHASE_WIDTH - 3))) : (1 << (PHASE_WIDTH - 1));
  localparam logic [PHASE_WIDTH-1:0] Phase3Pi2 = PhasePi + PhasePi2;
  localparam logic [PHASE_WIDTH-1:0] Phase2Pi = PhasePi << 1;

  // Functions

  // This function maps `phase` from range [0, 2*pi) to LUT address.
  //   - When StructureInternal is "FULL", phase could be directly used as address.
  //   - When StructureInternal is "HALF", phase should be reduce to [0, pi)
  //   - When StructureInternal is "QUARTER", phase should be reduce to [0, pi/2)
  function automatic [AddressWidth-1:0] phase_addr_mapping(input logic [PHASE_WIDTH-1:0] phase_value);
    logic [PHASE_WIDTH-1:0] mapped;
    begin
      mapped = phase_value;

      // phase-cosine look-up table only contains 1/2 of the waveform. Phase in
      // range [pi, 2*pi) could be mapped to [0, pi) with sign changed:
      //   cos(x) = -cos(x - pi),  (pi <= x < 2*pi)
      if (StructureInternal == StructureHalf) begin
        if (RASTERIZED) begin
          case (mapped[PHASE_WIDTH-1:PHASE_WIDTH-4])
            4'b0000: mapped[PHASE_WIDTH-1:PHASE_WIDTH-4] = 4'b0000;  // 0 -> 0
            4'b0001: mapped[PHASE_WIDTH-1:PHASE_WIDTH-4] = 4'b0001;  // 1 -> 1
            4'b0010: mapped[PHASE_WIDTH-1:PHASE_WIDTH-4] = 4'b0010;  // 2 -> 2
            4'b0011: mapped[PHASE_WIDTH-1:PHASE_WIDTH-4] = 4'b0011;  // 3 -> 3
            4'b0100: mapped[PHASE_WIDTH-1:PHASE_WIDTH-4] = 4'b0100;  // 4 -> 4
            4'b0101: mapped[PHASE_WIDTH-1:PHASE_WIDTH-4] = 4'b0101;  // 5 -> 5
            4'b0110: mapped[PHASE_WIDTH-1:PHASE_WIDTH-4] = 4'b0000;  // 6 -> 0
            4'b0111: mapped[PHASE_WIDTH-1:PHASE_WIDTH-4] = 4'b0001;  // 7 -> 1
            4'b1000: mapped[PHASE_WIDTH-1:PHASE_WIDTH-4] = 4'b0010;  // 8 -> 2
            4'b1001: mapped[PHASE_WIDTH-1:PHASE_WIDTH-4] = 4'b0011;  // 9 -> 3
            4'b1010: mapped[PHASE_WIDTH-1:PHASE_WIDTH-4] = 4'b0100;  // 10 -> 4
            4'b1011: mapped[PHASE_WIDTH-1:PHASE_WIDTH-4] = 4'b0101;  // 11 -> 5
            default: mapped[PHASE_WIDTH-1:PHASE_WIDTH-4] = 4'bxxxx;
          endcase
        end else begin
          case (mapped[PHASE_WIDTH-1:PHASE_WIDTH-2])
            2'b00:   mapped[PHASE_WIDTH-1:PHASE_WIDTH-2] = 2'b00;  // 0 -> 0
            2'b01:   mapped[PHASE_WIDTH-1:PHASE_WIDTH-2] = 2'b01;  // 1 -> 1
            2'b10:   mapped[PHASE_WIDTH-1:PHASE_WIDTH-2] = 2'b00;  // 2 -> 0
            2'b11:   mapped[PHASE_WIDTH-1:PHASE_WIDTH-2] = 2'b01;  // 3 -> 1
            default: mapped[PHASE_WIDTH-1:PHASE_WIDTH-2] = 2'bxx;
          endcase
        end
      end

      // phase-cosine look-up table only contains 1/4 of the waveform. Phase in
      // range [1/2*pi, pi) and [3/2*pi, 2*pi) should be sign changed to reflect
      // the trigonometric function.
      //   cos(x) = -cos(pi - x), (pi/2 <= x < pi)
      //   cos(x) = -cos(x - pi), (pi <= x < 3*pi/2)
      //   cos(x) = cos(2*pi - x), (3*pi/2 <= x < pi)
      if (StructureInternal == StructureQuarter) begin
        if (RASTERIZED) begin
          case (mapped[PHASE_WIDTH-1:PHASE_WIDTH-4])
            4'b0000: mapped = mapped;
            4'b0001: mapped = mapped;
            4'b0010: mapped = mapped;
            4'b0011: mapped = PhasePi - mapped;
            4'b0100: mapped = PhasePi - mapped;
            4'b0101: mapped = PhasePi - mapped;
            4'b0110: mapped = mapped - PhasePi;
            4'b0111: mapped = mapped - PhasePi;
            4'b1000: mapped = mapped - PhasePi;
            4'b1001: mapped = Phase2Pi - mapped;
            4'b1010: mapped = Phase2Pi - mapped;
            4'b1011: mapped = Phase2Pi - mapped;
            default: mapped = {PHASE_WIDTH{1'bx}};
          endcase
        end else begin
          case (mapped[PHASE_WIDTH-1:PHASE_WIDTH-2])
            2'b00:   mapped = mapped;
            2'b01:   mapped = PhasePi - mapped;
            2'b10:   mapped = mapped - PhasePi;
            2'b11:   mapped = Phase2Pi - mapped;
            default: mapped = {PHASE_WIDTH{1'bx}};
          endcase
        end
      end

      phase_addr_mapping = mapped[AddressWidth-1:0];
    end
  endfunction

  // This function tells when look-up the phase-cosine table, which output
  // should be sign changed. (Phase in range [1/2*pi, 3/2*pi)).
  function automatic negative_output(input logic [PHASE_WIDTH-1:0] phase_value, input logic negative);
    begin
      negative_output = 1'b0;

      if (StructureInternal == StructureHalf) begin
        negative_output = phase_value >= PhasePi;
      end

      if (StructureInternal == StructureQuarter) begin
        negative_output = (phase_value >= PhasePi2) && (phase_value < Phase3Pi2);
      end

      negative_output = negative ? ~negative_output : negative_output;
    end
  endfunction

  // This function tells when look-up the phase-cosine table, which output
  // should be zero, since the zero point (cos(1/2*pi) and cos(3/2*pi)) is not
  // in table.
  function automatic zero_output(input logic [PHASE_WIDTH-1:0] phase_value);
    begin
      zero_output = 1'b0;

      if (StructureInternal == StructureQuarter) begin
        if (phase_value == PhasePi2 || phase_value == Phase3Pi2) begin
          zero_output = 1'b1;
        end
      end
    end
  endfunction

  // Signals

  logic [ PHASE_WIDTH-1:0] cos_phase;
  logic [ PHASE_WIDTH-1:0] sin_phase;

  logic [AddressWidth-1:0] cos_addr;
  logic [AddressWidth-1:0] sin_addr;

  logic cos_negative, cos_negative_d, cos_negative_dd;
  logic sin_negative, sin_negative_d, sin_negative_dd;

  logic cos_zero, cos_zero_d, cos_zero_dd;
  logic sin_zero, sin_zero_d, sin_zero_dd;

  wire signed [DATA_WIDTH-1:0] cos_dout;
  wire signed [DATA_WIDTH-1:0] sin_dout;

  // Main

  // Reduce ROM usage using equation:
  //   sin(x) = cos(x - pi / 2)
  always_comb begin
    cos_phase = phase;
    sin_phase = phase;
    if (RASTERIZED) begin
      case (sin_phase[PHASE_WIDTH-1:PHASE_WIDTH-4])
        4'b0000: sin_phase[PHASE_WIDTH-1:PHASE_WIDTH-4] = 4'b1001;  // 0 - 3 = 9
        4'b0001: sin_phase[PHASE_WIDTH-1:PHASE_WIDTH-4] = 4'b1010;  // 1 - 3 = 10
        4'b0010: sin_phase[PHASE_WIDTH-1:PHASE_WIDTH-4] = 4'b1011;  // 2 - 3 = 11
        4'b0011: sin_phase[PHASE_WIDTH-1:PHASE_WIDTH-4] = 4'b0000;
        4'b0100: sin_phase[PHASE_WIDTH-1:PHASE_WIDTH-4] = 4'b0001;
        4'b0101: sin_phase[PHASE_WIDTH-1:PHASE_WIDTH-4] = 4'b0010;
        4'b0110: sin_phase[PHASE_WIDTH-1:PHASE_WIDTH-4] = 4'b0011;
        4'b0111: sin_phase[PHASE_WIDTH-1:PHASE_WIDTH-4] = 4'b0100;
        4'b1000: sin_phase[PHASE_WIDTH-1:PHASE_WIDTH-4] = 4'b0101;
        4'b1001: sin_phase[PHASE_WIDTH-1:PHASE_WIDTH-4] = 4'b0110;
        4'b1010: sin_phase[PHASE_WIDTH-1:PHASE_WIDTH-4] = 4'b0111;
        4'b1011: sin_phase[PHASE_WIDTH-1:PHASE_WIDTH-4] = 4'b1000;
        default: sin_phase[PHASE_WIDTH-1:PHASE_WIDTH-4] = 4'bxxxx;
      endcase
    end else begin
      case (sin_phase[PHASE_WIDTH-1:PHASE_WIDTH-2])
        2'b00:   sin_phase[PHASE_WIDTH-1:PHASE_WIDTH-2] = 2'b11;
        2'b01:   sin_phase[PHASE_WIDTH-1:PHASE_WIDTH-2] = 2'b00;
        2'b10:   sin_phase[PHASE_WIDTH-1:PHASE_WIDTH-2] = 2'b01;
        2'b11:   sin_phase[PHASE_WIDTH-1:PHASE_WIDTH-2] = 2'b10;
        default: sin_phase[PHASE_WIDTH-1:PHASE_WIDTH-2] = 2'bxx;
      endcase
    end
  end

  always_ff @(posedge clk) begin
    cos_addr <= phase_addr_mapping(cos_phase);
    sin_addr <= phase_addr_mapping(sin_phase);
  end

  always_ff @(posedge clk) begin
    cos_negative <= negative_output(cos_phase, NEGATIVE_COS);
    sin_negative <= negative_output(sin_phase, NEGATIVE_SIN);
  end

  always_ff @(posedge clk) begin
    cos_negative_d  <= cos_negative;
    cos_negative_dd <= cos_negative_d;
    sin_negative_d  <= sin_negative;
    sin_negative_dd <= sin_negative_d;
  end

  always_ff @(posedge clk) begin
    cos_zero <= zero_output(cos_phase);
    sin_zero <= zero_output(sin_phase);
  end

  always_ff @(posedge clk) begin
    cos_zero_d  <= cos_zero;
    cos_zero_dd <= cos_zero_d;
    sin_zero_d  <= sin_zero;
    sin_zero_dd <= sin_zero_d;
  end

  // The look-up table

  dds_lut_rom #(
      .STRUCTURE (StructureInternal),
      .RASTERIZED(RASTERIZED),
      .ADDR_WIDTH(AddressWidth),
      .DATA_WIDTH(DATA_WIDTH),
      .OUTPUT_REG(1)
  ) i_rom (
      .clk  (clk),
      //
      .rsta (rst),
      .ena  (1'b1),
      .addra(cos_addr),
      .douta(cos_dout),
      //
      .rstb (rst),
      .enb  (1'b1),
      .addrb(sin_addr),
      .doutb(sin_dout)
  );

  always_ff @(posedge clk) begin
    if (cos_zero_dd) begin
      cos_out <= 0;
    end else if (cos_negative_dd) begin
      cos_out <= -cos_dout;
    end else begin
      cos_out <= cos_dout;
    end
  end

  always_ff @(posedge clk) begin
    if (sin_zero_dd) begin
      sin_out <= 0;
    end else if (sin_negative_dd) begin
      sin_out <= -sin_dout;
    end else begin
      sin_out <= sin_dout;
    end
  end

endmodule

`default_nettype wire
