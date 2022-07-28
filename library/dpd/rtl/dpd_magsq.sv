// File: dpd_compander_magsq.sv
// Brief: Get the magnitude square of complex signal.
`timescale 1 ns / 1 ps
//
`default_nettype none

module dpd_compander_magsq #(
    parameter int INPUT_DATA_WIDTH  = 16,
    parameter int OUTPUT_DATA_WIDTH = 12,
    parameter int SRA_BITS          = 18
) (
    input var                                 clk,
    input var                                 rst,
    //
    input var  signed [ INPUT_DATA_WIDTH-1:0] data_i_in,
    input var  signed [ INPUT_DATA_WIDTH-1:0] data_q_in,
    //
    output var        [OUTPUT_DATA_WIDTH-1:0] data_magsq_out,
    output var                                ovf
);


  localparam int RoundConstant = (1 << (SRA_BITS - 1));

  logic signed [  INPUT_DATA_WIDTH-1:0] ar;
  logic signed [INPUT_DATA_WIDTH*2-1:0] am;
  logic signed [  INPUT_DATA_WIDTH*2:0] ap;

  logic signed [  INPUT_DATA_WIDTH-1:0] br;
  logic signed [  INPUT_DATA_WIDTH-1:0] brr;
  logic signed [INPUT_DATA_WIDTH*2-1:0] bm;
  logic signed [  INPUT_DATA_WIDTH*2:0] bp;

  always_ff @(posedge clk) begin
    ar <= data_i_in;
    am <= ar * ar;
    ap <= am + RoundConstant;
  end

  always_ff @(posedge clk) begin
    br  <= data_q_in;
    brr <= br;
    bm  <= brr * brr;
    bp  <= ap + bm;
  end

  always_ff @(posedge clk) begin
    data_magsq_out <= bp >>> SRA_BITS;
  end

  generate
    if (OUTPUT_DATA_WIDTH + SRA_BITS >= INPUT_DATA_WIDTH * 2 + 1) begin : g_no_ovf
      initial begin
        ovf = 1'b0;
      end
    end else begin : g_ovf
      always_ff @(posedge clk) begin
        if (bp[INPUT_DATA_WIDTH*2:OUTPUT_DATA_WIDTH+SRA_BITS-1] != '1 &&
            bp[INPUT_DATA_WIDTH*2:OUTPUT_DATA_WIDTH+SRA_BITS-1] != '0) begin
          ovf <= 1'b1;
        end else begin
          ovf <= 1'b0;
        end
      end
    end
  endgenerate

endmodule

`default_nettype wire
