`timescale 1 ns / 1 ps
//
`default_nettype none

module tb_lfsr #(
    parameter integer                 BIT_WIDTH       = 4,
    parameter reg     [BIT_WIDTH-1:0] INITIAL         = 4'b1111,
    parameter reg     [BIT_WIDTH-1:0] POLYNOMIALS     = 4'b0011,
    parameter                         STRUCTURE       = "FIBONACCI",  // "FIBONACCI" or "GALOIS"
    parameter                         GATE_TYPE       = "XOR",        // "XOR" or "XNOR"
    parameter reg                     PARALLEL_OUTPUT = 1'b0
);

  reg                                          clk;
  reg                                          rst;
  reg                                          en;
  reg                                          load;
  reg  [                        BIT_WIDTH-1:0] din;
  wire [(PARALLEL_OUTPUT ? BIT_WIDTH : 1)-1:0] dout;

  initial begin
    clk = 0;
    forever begin
      #5 clk = ~clk;
    end
  end

  initial begin
    rst = 1;
    #100;
    rst = 0;
  end

  initial begin
    en = 1;
  end


  lfsr #(
      .BIT_WIDTH(BIT_WIDTH),
      .INITIAL(INITIAL),
      .POLYNOMIALS(POLYNOMIALS),
      .STRUCTURE(STRUCTURE),
      .GATE_TYPE(GATE_TYPE),
      .PARALLEL_OUTPUT(PARALLEL_OUTPUT)
  ) DUT (
      .clk (clk),
      .rst (rst),
      .en  (en),
      .load(load),
      .din (din),
      .dout(dout)
  );

endmodule

`default_nettype wire
