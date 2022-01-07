// File: nlf_delay_line.sv
// Brief: Delay line for index and signal

`timescale 1 ns / 1 ps `default_nettype none

module nlf_delay_line #(
    parameter int NUM_UNITS   = 16,
    parameter int DELAY_WIDTH = 4,
    parameter int DATA_WIDTH  = 32
) (
    // Read Interface
    input var                    clk,
    //
    input var  [DATA_WIDTH -1:0] data_in,
    output var [DATA_WIDTH -1:0] data_out[NUM_UNITS],
    //
    input var  [DELAY_WIDTH-1:0] delay   [NUM_UNITS]
);


  logic [DATA_WIDTH-1:0] data_s[NUM_UNITS];


  // Each stage is 1 tap register plus 1 SRL
  generate
    for (genvar i = 0; i < NUM_UNITS; i++) begin : g_stage

      if (i == 0) begin
        always_ff @(posedge clk) begin
          data_s[i] <= data_in;
        end
      end else begin
        always_ff @(posedge clk) begin
          data_s[i] <= data_s[i-1];
        end
      end

      nlf_srl #(
          .ADDR_WIDTH(DELAY_WIDTH),
          .DATA_WIDTH(DATA_WIDTH)
      ) i_srl (
          // Read Interface
          .clk (clk),
          //
          .addr(delay[i]),
          .din (data_s[i]),
          .dout(data_out[i])
      );

    end
  endgenerate

endmodule

`default_nettype wire
