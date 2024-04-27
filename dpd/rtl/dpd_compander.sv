// File: dpd_compander.sv
// Brief: The compander compressing the IQ signal magnitude squared into
//        8/9-bit resolution to drive the LUT.
//        - For 8-bit resolution, use 12-bit magnitude input, with 3 Exponent
//          bits and 5 Mantissa bits.
//        - For 9-bit resolution, use 13-bit magnitude input, with 3 Exponent
//          bits and 6 Mantissa bits.
`timescale 1 ns / 1 ps
//
`default_nettype none

module dpd_compander #(
    parameter int EXPONENT_WIDTH = 3,
    parameter int MANTISSA_WIDTH = 5
) (
    input var                                               clk,
    input var                                               rst,
    //
    input var  [2 ** EXPONENT_WIDTH + MANTISSA_WIDTH - 2:0] data_magsq_in,
    input var                                               data_ovf_in,
    //
    output var [         EXPONENT_WIDTH+MANTISSA_WIDTH-1:0] index_out
);


  logic [EXPONENT_WIDTH-1:0] exponent;
  logic [MANTISSA_WIDTH-1:0] mantissa;


  // The compression logic
  always_comb begin
    // This is default result if there is no bit 1
    // If not bit 1 is found, set exponent value to 0 and put LSB bits to mantissa
    exponent = 0;
    mantissa = data_magsq_in[MANTISSA_WIDTH-1:0];
    // Loop search data_magsq_in[2**EXPONENT_WIDTH+MANTISSA_WIDTH-2:MANTISSA_WIDTH]
    // (total 2 ** EXPONENT_WIDTH - 1 bits) to check if there is bit 1
    // If so set the exponent value and put left bits to mantissa
    for (int i = 2 ** EXPONENT_WIDTH - 2; i >= 0; i--) begin
      if (data_magsq_in[i+MANTISSA_WIDTH]) begin
        exponent = i + 1;
        if (i == 0) begin
          mantissa = data_magsq_in[MANTISSA_WIDTH-1:0];
        end else begin
          mantissa = data_magsq_in[i+MANTISSA_WIDTH-2-:MANTISSA_WIDTH];
        end
        break;
      end
    end
  end

  always_ff @(posedge clk) begin
    if (data_ovf_in) begin
      index_out <= '1;
    end else begin
      index_out <= {exponent, mantissa};
    end
  end

endmodule

`default_nettype wire
