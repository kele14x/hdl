// File: fft_twiddle_rom.sv
// Brief: The twiddle factor rom in FFT algorithm.
`timescale 1ns / 1ps
//
`default_nettype none

module dds_lut #(
    parameter integer PHASE_WIDTH  = 12,
    parameter integer DATA_WIDTH   = 16,
    parameter reg     NEGATIVE_SIN = 0
) (
    input  wire                         clk,
    input  wire                         rst,
    input  wire                         en,
    //
    input  wire       [PHASE_WIDTH-1:0] phase,
    //
    output reg signed [ DATA_WIDTH-1:0] cos_out,
    output reg signed [ DATA_WIDTH-1:0] sin_out
);


  // Check parameters
  //=================

  initial begin
    if (!(2 <= PHASE_WIDTH && PHASE_WIDTH <= 23)) begin
      $error("[%m]: Phase word width (PHASE_WIDTH) must be with in the range 2 to 23");
      #1 $finish();
    end
  end


  // Local parameters
  //=================

  localparam integer Latency = 2;

  // Note:
  //     2 * pi = 2 ^ PHASE_WIDTH       = 00_0000
  // 1 / 2 * pi = 2 ^ (PHASE_WIDTH - 2) = 01_0000
  //         pi = 2 ^ (PHASE_WIDTH - 1) = 10_0000
  // 3 / 2 * pi = 1 / 2 * pi + pi       = 11_0000
  localparam reg [PHASE_WIDTH-1:0] PhasePi = (1 << (PHASE_WIDTH - 1));
  localparam reg [PHASE_WIDTH-1:0] PhasePi2 = (1 << (PHASE_WIDTH - 2));
  localparam reg [PHASE_WIDTH-1:0] Phase3Pi2 = PhasePi + PhasePi2;


  // Functions
  //==========

  // This function maps `phase` from range [0, 2*pi) to [0, 1/2*pi), since the
  // phase-cosine look-up table only contains 1/4 of the waveform. Phase in
  // range [1/2*pi, pi) and [3/2*pi, 2*pi) should be sign changed to reflect
  // the trigonometric function.
  function automatic [PHASE_WIDTH-3:0] phase_addr_mapping(input reg [PHASE_WIDTH-1:0] phase);
    reg [PHASE_WIDTH-1:0] mapped;
    begin
      if (phase[PHASE_WIDTH-1:PHASE_WIDTH-2] == 2'b01 ||
          phase[PHASE_WIDTH-1:PHASE_WIDTH-2] == 2'b11) begin
        mapped = -phase;
      end else begin
        mapped = phase;
      end
      phase_addr_mapping = mapped[PHASE_WIDTH-3:0];
    end
  endfunction

  // This function tells when look-up the phase-cosine table, which output
  // should be sign changed. (Phase in range [1/2*pi, 3/2*pi)).
  function automatic negative_output(input reg [PHASE_WIDTH-1:0] phase);
    begin
      if (phase[PHASE_WIDTH-1:PHASE_WIDTH-2] == 2'b01 ||
          phase[PHASE_WIDTH-1:PHASE_WIDTH-2] == 2'b10) begin
        negative_output = 1'b1;
      end else begin
        negative_output = 1'b0;
      end
    end
  endfunction

  // This function tells when look-up the phase-cosine table, which output
  // should be zero, since the zero point (cos(1/2*pi) and cos(3/2*pi)) is not
  // in table.
  function automatic zero_output(input reg [PHASE_WIDTH-1:0] phase);
    begin
      if (phase == PhasePi2 || phase == Phase3Pi2) begin
        zero_output = 1'b1;
      end else begin
        zero_output = 1'b0;
      end
    end
  endfunction


  // Signals
  //========

  reg [PHASE_WIDTH-1:0] cos_phase;
  reg [PHASE_WIDTH-1:0] sin_phase;

  reg [PHASE_WIDTH-3:0] cos_addr;
  reg [PHASE_WIDTH-3:0] sin_addr;

  reg cos_negative, cos_negative_d, cos_negative_dd;
  reg sin_negative, sin_negative_d, sin_negative_dd;

  reg cos_zero, cos_zero_d, cos_zero_dd;
  reg sin_zero, sin_zero_d, sin_zero_dd;

  wire signed [DATA_WIDTH-1:0] cos_dout;
  wire signed [DATA_WIDTH-1:0] sin_dout;


  // Main
  //=====

  // Reduce ROM usage using equation:
  //    sin(x) = cos(x - pi / 2)
  //   -sin(x) = cos(x + pi / 2)
  always @(*) begin
    cos_phase = phase;
    if (NEGATIVE_SIN) begin
      sin_phase = phase + (1 << (PHASE_WIDTH - 2));
    end else begin
      sin_phase = phase - (1 << (PHASE_WIDTH - 2));
    end
  end

  always @(posedge clk) begin
    cos_addr <= phase_addr_mapping(cos_phase);
    sin_addr <= phase_addr_mapping(sin_phase);
  end

  always @(posedge clk) begin
    cos_negative <= negative_output(cos_phase);
    sin_negative <= negative_output(sin_phase);
  end

  always @(posedge clk) begin
    cos_negative_d  <= cos_negative;
    cos_negative_dd <= cos_negative_d;
    sin_negative_d  <= sin_negative;
    sin_negative_dd <= sin_negative_d;
  end

  always @(posedge clk) begin
    cos_zero <= zero_output(cos_phase);
    sin_zero <= zero_output(sin_phase);
  end

  always @(posedge clk) begin
    cos_zero_d  <= cos_zero;
    cos_zero_dd <= cos_zero_d;
    sin_zero_d  <= sin_zero;
    sin_zero_dd <= sin_zero_d;
  end


  // The look-up table

  dds_rom #(
      .ADDR_WIDTH(PHASE_WIDTH - 2),
      .DATA_WIDTH(DATA_WIDTH)
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

  always @(posedge clk) begin
    if (cos_zero_dd) begin
      cos_out <= 0;
    end else if (cos_negative_dd) begin
      cos_out <= -cos_dout;
    end else begin
      cos_out <= cos_dout;
    end
  end

  always @(posedge clk) begin
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
