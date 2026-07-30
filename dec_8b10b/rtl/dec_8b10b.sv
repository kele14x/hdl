// References:
// https://ieeexplore.ieee.org/document/5390392
// https://en.wikipedia.org/wiki/8b10b_encoding
// https://www.xilinx.com/support/documentation/application_notes/xapp1112.pdf
// https://www.xilinx.com/support/documentation/ip_documentation/decode_8b10b.pdf

`timescale 1 ns / 1 ps
`default_nettype none

module dec_8b10b #(
    parameter int C_USE_LUT = 0,
    parameter string C_LUT_FILE = "dec_8b10b.mif"
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       cen,
    //
    input  wire [9:0] din,
    input  wire       dispin,
    //
    output logic  [7:0] dout,
    output logic        charisk,
    output logic        dispout,
    output logic        disperr,
    output logic        notintable,
    output logic        valid
);

  wire [11:0] dec_result;

  generate
    if (C_USE_LUT == 0) begin : g_logic_decoder
      dec_8b10b_logic i_dec_8b10b_logic (
          .din       (din),
          .dispin    (dispin),
          .dec_result(dec_result)
      );
    end else begin : g_lut_decoder
      dec_8b10b_lut #(
          .C_LUT_FILE(C_LUT_FILE)
      ) i_dec_8b10b_lut (
          .din       (din),
          .dispin    (dispin),
          .dec_result(dec_result)
      );
    end
  endgenerate

  always_ff @(posedge clk) begin : p_decoder_output
    if (rst) begin
      dout       <= 8'd0;
      charisk    <= 1'b0;
      dispout    <= 1'b0;
      disperr    <= 1'b0;
      notintable <= 1'b0;
    end else if (cen) begin
      {disperr, dispout, notintable, charisk, dout} <= dec_result;
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
