// File: dds_lut_block.v
// Brief: DDS LUT core.
`timescale 1 ns / 1 ps
//
`default_nettype none

module dds_lut_block #(
    parameter string STRUCTURE     = "FULL",
    parameter string USE_DUAL_PORT = "FALSE",
    parameter int    PHASE_WIDTH   = 12,
    parameter int    DATA_WIDTH    = 16,
    parameter bit    NEGATIVE_COS  = 0,
    parameter bit    NEGATIVE_SIN  = 0
) (
    input  wire                           clk,
    input  wire                           rst,
    input  wire                           en,
    //
    input  wire         [PHASE_WIDTH-1:0] phase,
    //
    output logic signed [ DATA_WIDTH-1:0] cos_out,
    output logic signed [ DATA_WIDTH-1:0] sin_out
);

  // Local parameters
  //=================

  localparam int Latency = 4;

  localparam int PhaseWidthInternal = (STRUCTURE == "FULL") ? PHASE_WIDTH :
    (STRUCTURE == "HALF") ? (PHASE_WIDTH - 1): (PHASE_WIDTH - 2);

  // Note:
  //          0 = 0                     = 00_0000...
  // 1 / 2 * pi = 2 ^ (PHASE_WIDTH - 2) = 01_0000...
  //         pi = 2 ^ (PHASE_WIDTH - 1) = 10_0000...
  // 3 / 2 * pi = 1 / 2 * pi + pi       = 11_0000...
  //     2 * pi = 2 ^ PHASE_WIDTH       = 00_0000...
  localparam bit [PHASE_WIDTH-1:0] PhasePi = (1 << (PHASE_WIDTH - 1));
  localparam bit [PHASE_WIDTH-1:0] PhasePi2 = (1 << (PHASE_WIDTH - 2));
  localparam bit [PHASE_WIDTH-1:0] Phase3Pi2 = PhasePi + PhasePi2;


  // Functions
  //==========

  // This function maps `phase` from range [0, 2*pi) to LUT address.
  //   - When STRUCTURE is "FULL", phase could be directly used as address.
  //   - When STRUCTURE is "HALF", phase should be reduce to [0, pi)
  //   - When STRUCTURE is "QUARTER", phase should be reduce to [0, pi/2)

  // phase-cosine look-up table only contains 1/4 of the waveform. Phase in
  // range [1/2*pi, pi) and [3/2*pi, 2*pi) should be sign changed to reflect
  // the trigonometric function.
  function automatic [PhaseWidthInternal-1:0] phase_addr_mapping(
      input logic [PHASE_WIDTH-1:0] phase);
    logic [PHASE_WIDTH-1:0] mapped;
    begin
      mapped = phase;

      if (STRUCTURE == "HALF") begin
        if (phase[PHASE_WIDTH-1] == 1'b1) begin
          mapped = phase - PhasePi;
        end
      end

      if (STRUCTURE == "QUARTER") begin
        if (phase[PHASE_WIDTH-1:PHASE_WIDTH-2] == 2'b01 ||
            phase[PHASE_WIDTH-1:PHASE_WIDTH-2] == 2'b11) begin
          mapped = -phase;
        end
      end

      phase_addr_mapping = mapped[PhaseWidthInternal-1:0];
    end
  endfunction

  // This function tells when look-up the phase-cosine table, which output
  // should be sign changed. (Phase in range [1/2*pi, 3/2*pi)).
  function automatic negative_output(input logic [PHASE_WIDTH-1:0] phase);
    begin
      negative_output = 0;

      if (STRUCTURE == "HALF") begin
        if (phase[PHASE_WIDTH-1] == 1'b1) begin
          negative_output = 1'b1;
        end
      end

      if (STRUCTURE == "HALF") begin
        if (phase[PHASE_WIDTH-1:PHASE_WIDTH-2] == 2'b01 ||
            phase[PHASE_WIDTH-1:PHASE_WIDTH-2] == 2'b10) begin
          negative_output = 1'b1;
        end
      end
    end
  endfunction

  // This function tells when look-up the phase-cosine table, which output
  // should be zero, since the zero point (cos(1/2*pi) and cos(3/2*pi)) is not
  // in table.
  function automatic zero_output(input logic [PHASE_WIDTH-1:0] phase);
    begin
      zero_output = 1'b0;

      if (STRUCTURE == "QUARTER") begin
        if (phase == PhasePi2 || phase == Phase3Pi2) begin
          zero_output = 1'b1;
        end
      end
    end
  endfunction


  // Signals
  //========

  logic [PHASE_WIDTH-1:0] cos_phase;
  logic [PHASE_WIDTH-1:0] sin_phase;

  logic [PhaseWidthInternal-1:0] cos_addr;
  logic [PhaseWidthInternal-1:0] sin_addr;

  logic cos_negative, cos_negative_d, cos_negative_dd;
  logic sin_negative, sin_negative_d, sin_negative_dd;

  logic cos_zero, cos_zero_d, cos_zero_dd;
  logic sin_zero, sin_zero_d, sin_zero_dd;

  wire signed [DATA_WIDTH-1:0] cos_dout;
  wire signed [DATA_WIDTH-1:0] sin_dout;


  // Main
  //=====

  // Reduce ROM usage using equation:
  //    cos(x) = cos(x)
  //   -cos(x) = cos(x + pi)
  //    sin(x) = cos(x - pi / 2)
  //   -sin(x) = cos(x + pi / 2)
  always_comb begin
    cos_phase = phase;
    if (USE_DUAL_PORT == "TRUE") begin
      if (NEGATIVE_COS ^ NEGATIVE_SIN) begin
        sin_phase = phase + PhasePi2;
      end else begin
        sin_phase = phase - PhasePi2;
      end
    end else begin
      sin_phase = phase;
    end
  end

  always_ff @(posedge clk) begin
    cos_addr <= phase_addr_mapping(cos_phase);
    sin_addr <= phase_addr_mapping(sin_phase);
  end

  always_ff @(posedge clk) begin
    cos_negative <= negative_output(cos_phase);
    sin_negative <= negative_output(sin_phase);
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

  generate
    if (USE_DUAL_PORT == "TRUE") begin : g_one_rom

      dds_lut_rom #(
          .DUAL_PORT  (1),
          .COSINE_SINE("COSINE"),
          .STRUCTURE  (STRUCTURE),
          .ADDR_WIDTH (PhaseWidthInternal),
          .DATA_WIDTH (DATA_WIDTH),
          .NEGATIVE   (NEGATIVE_COS)
      ) i_rom (
          .clk  (clk),
          //
          .rsta (1'b0),
          .ena  (1'b1),
          .addra(cos_addr),
          .douta(cos_dout),
          //
          .rstb (1'b0),
          .enb  (1'b1),
          .addrb(sin_addr),
          .doutb(sin_dout)
      );

    end else begin : g_two_rom

      dds_lut_rom #(
          .DUAL_PORT  (0),
          .COSINE_SINE("COSINE"),
          .STRUCTURE  (STRUCTURE),
          .ADDR_WIDTH (PhaseWidthInternal),
          .DATA_WIDTH (DATA_WIDTH),
          .NEGATIVE   (NEGATIVE_COS)
      ) i_cos_rom (
          .clk  (clk),
          //
          .rsta (1'b0),
          .ena  (1'b1),
          .addra(cos_addr),
          .douta(cos_dout),
          //
          .rstb (1'b0),
          .enb  (1'b1),
          .addrb('0),
          .doutb(  /* not used */)
      );

      dds_lut_rom #(
          .DUAL_PORT  (0),
          .COSINE_SINE("SINE"),
          .STRUCTURE  (STRUCTURE),
          .ADDR_WIDTH (PhaseWidthInternal),
          .DATA_WIDTH (DATA_WIDTH),
          .NEGATIVE   (NEGATIVE_SIN)
      ) i_sin_rom (
          .clk  (clk),
          //
          .rsta (1'b0),
          .ena  (1'b1),
          .addra(sin_addr),
          .douta(sin_dout),
          //
          .rstb (1'b0),
          .enb  (1'b1),
          .addrb('0),
          .doutb(  /* not used */)
      );

    end
  endgenerate

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
      if (USE_DUAL_PORT == "TRUE") begin
        sin_out <= 0;
      end else begin
        sin_out <= (2 ** (DATA_WIDTH - 1) - 2);
      end
    end else if (sin_negative_dd) begin
      sin_out <= -sin_dout;
    end else begin
      sin_out <= sin_dout;
    end
  end

endmodule

`default_nettype wire
