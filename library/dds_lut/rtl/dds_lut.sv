// File: dds_lut.sv
// Brief: Phase to cosine/sine look-up table.
`timescale 1 ns / 1 ps
//
`default_nettype none

module dds_lut #(
    // LUT structure, select from: "AUTO", "FULL", "HALF", "QUARTER"
    parameter string STRUCTURE     = "AUTO",
    // Utilize dual port technical of Xilinx Block RAM to save resource
    parameter string USE_DUAL_PORT = "AUTO",
    // Bit width of phase input
    parameter int    PHASE_WIDTH   = 12,
    // Cosine/sine data bit width
    parameter int    DATA_WIDTH    = 16,
    // Output negative cosine data
    parameter bit    NEGATIVE_COS  = 0,
    // Output negative sine da ta
    parameter bit    NEGATIVE_SIN  = 0
) (
    input var                           clk,
    input var                           rst,
    input var                           en,
    //
    input var         [PHASE_WIDTH-1:0] phase,
    //
    output var signed [ DATA_WIDTH-1:0] cos_out,
    output var signed [ DATA_WIDTH-1:0] sin_out
);

  // Check parameters

  initial begin
    // Check STRUCTURE
    assert(STRUCTURE == "AUTO" || STRUCTURE == "FULL" || STRUCTURE == "HALF" || STRUCTURE == "QUARTER")
    else begin
      $error(
          "[%m]: DDS structure (STRUCTURE) should be one of \"AUTO\", \"FULL\", \"HALF\" or \"QUARTER\". Got %s",
          STRUCTURE);
      #1 $finish;
    end

    assert (USE_DUAL_PORT == "AUTO" || USE_DUAL_PORT == "TRUE" || USE_DUAL_PORT == "FALSE")
    else begin
      $error(
          "[%m]: Use dual port (USE_DUAL_PORT) should be one of \"AUTO\", \"TRUE\" or \"FALSE\". Got %s",
          USE_DUAL_PORT);
      #1 $finish;
    end
  end


  // Local parameters

  localparam int Latency = 4;

  // When Phase Word Width (PHASE_WIDTH) is large, it's proper to store the
  // waveform into block memory. To save the block memory, it could only
  // store half or a quarter of the waveform and relies on the trigonometric
  // function to get the correct result.
  // When Phase Word Width is small, directly store the full waveform.
  localparam string StructureInternal = (STRUCTURE == "AUTO") ?
    ((PHASE_WIDTH <= 9) ? "FULL" : (PHASE_WIDTH <= 11) ? "HALF" : "QUARTER") : STRUCTURE;

  // If waveform is stored in a block resource, use the second port to look up
  // sine waveform. This could save block memory source.
  localparam string UseDualPortInternal = (USE_DUAL_PORT == "AUTO") ?
    ((PHASE_WIDTH <= 9) ? "TRUE" : "FALSE") : USE_DUAL_PORT;


  // Main

  dds_lut_core #(
      .STRUCTURE    (StructureInternal),
      .USE_DUAL_PORT(UseDualPortInternal),
      .PHASE_WIDTH  (PHASE_WIDTH),
      .DATA_WIDTH   (DATA_WIDTH),
      .NEGATIVE_COS (NEGATIVE_COS),
      .NEGATIVE_SIN (NEGATIVE_SIN)
  ) i_lut_core (
      .clk    (clk),
      .rst    (rst),
      .en     (en),
      //
      .phase  (phase),
      //
      .cos_out(cos_out),
      .sin_out(sin_out)
  );

endmodule

`default_nettype wire
