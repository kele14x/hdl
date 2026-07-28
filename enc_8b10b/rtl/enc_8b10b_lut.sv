// References:
// https://ieeexplore.ieee.org/document/5390392
// https://en.wikipedia.org/wiki/8b10b_encoding
// https://www.xilinx.com/support/documentation/application_notes/xapp1122.pdf
// https://www.xilinx.com/support/documentation/ip_documentation/encode_8b10b.pdf

`timescale 1 ns / 1 ps
`default_nettype none

module enc_8b10b_lut #(
    parameter string C_LUT_FILE = "enc_8b10b.mif"
) (
    input  wire [ 7:0] din,
    input  wire        charisk,
    input  wire        dispin,
    //
    output wire [11:0] enc_result
);

  // Address: {charisk, dispin, din}
  // Data:    {kerr, dispout, dout}
  reg [11:0] enc_table[0:1023];

  initial begin : p_load_enc_table
    $readmemb(C_LUT_FILE, enc_table, 0, 1023);
  end

  assign enc_result = enc_table[{charisk, dispin, din}];

endmodule

`default_nettype wire
