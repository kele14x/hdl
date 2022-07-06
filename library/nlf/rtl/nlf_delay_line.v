// File: nlf_delay_line.sv
// Brief: Delay line for index and signal
`timescale 1 ns / 1 ps 
//
`default_nettype none

module nlf_delay_line #(
    parameter integer NUM_UNITS   = 16,
    parameter integer DELAY_WIDTH = 4,
    parameter integer DATA_WIDTH  = 32
) (
    // Read Interface
    input wire                    clk,
    //
    input wire  [DATA_WIDTH -1:0] data_in,
    output wire [DATA_WIDTH -1:0] data_out[NUM_UNITS],
    //
    input wire  [DELAY_WIDTH-1:0] delay   [NUM_UNITS]
);


  // This is fixed/minimum latency when `delay` is 0
  localparam integer Latency = 3;

  reg [DATA_WIDTH-1:0] data_s[NUM_UNITS];


  // Each stage is 1 tap register plus 1 SRL
  generate
    genvar i;
    for (i = 0; i < NUM_UNITS; i = i + 1) begin : g_stage

      if (i == 0) begin : g_first
        always @(posedge clk) begin
          data_s[i] <= data_in;
        end
      end else begin : g_left
        always @(posedge clk) begin
          data_s[i] <= data_s[i-1];
        end
      end

      srl #(
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
