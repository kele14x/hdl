// References:
// https://ieeexplore.ieee.org/document/5390392
// https://en.wikipedia.org/wiki/8b10b_encoding
// https://www.xilinx.com/support/documentation/application_notes/xapp1122.pdf
// https://www.xilinx.com/support/documentation/ip_documentation/encode_8b10b.pdf

`timescale 1 ns / 1 ps
`default_nettype none

module enc_8b10b #(
    parameter int C_USE_LUT = 0,
    parameter logic [9:0] C_RST_CODE = 10'b0101010101,
    parameter string C_LUT_FILE = "enc_8b10b.mif"
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       cen,
    //
    input  wire [7:0] din,
    input  wire       charisk,
    input  wire       dispin,
    //
    output logic  [9:0] dout,
    output logic        kerr,
    output logic        dispout,
    output logic        valid
);

  wire [11:0] enc_result;

  generate
    if (C_USE_LUT == 0) begin : g_logic_encoder
      enc_8b10b_logic i_enc_8b10b_logic (
          .din       (din),
          .charisk   (charisk),
          .dispin    (dispin),
          .enc_result(enc_result)
      );
    end else begin : g_lut_encoder
      enc_8b10b_lut #(
          .C_LUT_FILE(C_LUT_FILE)
      ) i_enc_8b10b_lut (
          .din       (din),
          .charisk   (charisk),
          .dispin    (dispin),
          .enc_result(enc_result)
      );
    end
  endgenerate

  always_ff @(posedge clk) begin : p_encoder_output
    if (rst) begin
      dout    <= C_RST_CODE[9:0];
      kerr    <= 1'b0;
      dispout <= 1'b0;
    end else if (cen) begin
      {kerr, dispout, dout} <= enc_result;
    end
  end

  always_ff @(posedge clk) begin : p_en
    if (rst) begin
      valid <= 1'b0;
    end else begin
      valid <= cen;
    end
  end

  initial begin : drc_check
    assert ((C_USE_LUT == 0) || (C_USE_LUT == 1))
    else $error("C_USE_LUT must be 0 (logic) or 1 (lookup RAM)");
  end

endmodule

`default_nettype wire
