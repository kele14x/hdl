// References:
// https://ieeexplore.ieee.org/document/5390392
// https://en.wikipedia.org/wiki/8b10b_encoding
// https://www.xilinx.com/support/documentation/application_notes/xapp1112.pdf
// https://www.xilinx.com/support/documentation/ip_documentation/decode_8b10b.pdf

`timescale 1 ns / 1 ps
`default_nettype none

module dec_8b10b_lut #(
    parameter string C_LUT_FILE = "dec_8b10b.mif"
) (
    input  wire [ 9:0] din,
    input  wire        dispin,
    //
    output wire [11:0] dec_result
);

  // Data: {disperr_1, dispout_1, disperr_0, dispout_0, notintable, charisk, dout}
  logic [13:0] dec_table[0:1023];
  wire [13:0] dec_table_data;

  initial begin : p_load_dec_table
    $readmemb(C_LUT_FILE, dec_table, 0, 1023);
  end

  assign dec_table_data = dec_table[din];
  assign dec_result = {
    dec_table_data[dispin?13 : 11], dec_table_data[dispin?12 : 10], dec_table_data[9:0]
  };

endmodule

`default_nettype wire
