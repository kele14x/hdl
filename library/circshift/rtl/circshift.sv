// File: circshift.sv
// Brief: Circular shift for LDPC
`timescale 1 ns / 1 ns
//
`default_nettype none

module circshift #(
    parameter int DATA_WIDTH = 6
) (
    input var                   clk,
    input var                   rst,
    // Data input
    input var  [DATA_WIDTH-1:0] din       [64],
    input var                   din_valid [64],
    // Data output
    output var [DATA_WIDTH-1:0] dout      [64],
    output var                  dout_valid[64],
    //
    input var  [           5:0] shift,           // circular shift value
    input var  [           5:0] base             // Shift base, number of valid inputs
);

  logic [ 5:0] lshift;
  logic [ 5:0] rshift;

  logic [63:0] valid;
  logic [63:0] lvalid;

  assign lshift = shift;
  assign rshift = base - shift;

  always_comb begin
    for (int i = 0; i < 64; i++) begin
      valid[i] = din_valid[i];
    end
  end

  always_comb begin
    lvalid = valid << lshift;
  end

  generate
    for (genvar i = 0; i < DATA_WIDTH; i++) begin

      logic [63:0] shifter_in;
      logic [63:0] shifter_out;

      always_comb begin
        for (int j = 0; j < 64; j++) begin
          shifter_in[j] = din[j][i];
        end
      end

      circshift_shifter i_shifter (
          .clk   (clk),
          .rst   (rst),
          .din   (shifter_in),
          .lshift(lshift),
          .rshift(rshift),
          .lvalid(lvalid),
          .dout  (shifter_out)
      );

      always_comb begin
        for (int j = 0; j < 64; j++) begin
          dout[j][i] = shifter_out[j];
        end
      end

    end
  endgenerate

  always_ff @(posedge clk) begin
    dout_valid <= din_valid;
  end

endmodule : circshift

//
module circshift_shifter (
    input  var        clk,
    input  var        rst,
    input  var [63:0] din,
    input  var [ 5:0] lshift,
    input  var [ 5:0] rshift,
    input  var [63:0] lvalid,
    output var [63:0] dout
);

  logic [63:0] ldata;
  logic [63:0] rdata;

  always_comb begin
    ldata = din << lshift;
  end

  always_comb begin
    rdata = din >> rshift;
  end

  always_ff @(posedge clk) begin
    for (int j = 0; j < 64; j++) begin
      if (lvalid[j]) begin
        dout[j] <= ldata[j];
      end else begin
        dout[j] <= rdata[j];
      end
    end
  end

endmodule

`default_nettype none
