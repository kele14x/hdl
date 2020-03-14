`timescale 1 ns / 1 ps
`default_nettype none

module util_cdc_bits #(parameter C_DATA_WIDTH = 1) (
    input  var logic                    clk , // Clock
    input  var logic [C_DATA_WIDTH-1:0] din ,
    output var logic [C_DATA_WIDTH-1:0] dout
);

    (* ASYNC_REG="ture" *)
        var logic[C_DATA_WIDTH-1:0] din_d, din_dd;

    always_ff @ (posedge clk) begin
        din_d  <= din;
        din_dd <= din_d;
    end

    assign dout = din_dd;

endmodule
