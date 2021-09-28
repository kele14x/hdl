// File: bram_sp_pipe.sv
// Brief: Simplified Single Port (SP) Memory, but with control (enable and
//        reset) signal pipelined.

`timescale 1ns / 1ps `default_nettype none

module bram_sp_pipe #(
    parameter int    ADDR_WIDTH   = 10,
    parameter int    DATA_WIDTH   = 32,
    parameter int    READ_LATENCY = 2 ,
    parameter int    INIT_WORD    = '0,
    parameter string INIT_FILE    = ""
) (
    // Port A
    input var                   clk,
    input var                   rst,
    input var                   en,
    input var                   we,
    input var  [ADDR_WIDTH-1:0] addr,
    input var  [DATA_WIDTH-1:0] din,
    output var [DATA_WIDTH-1:0] dout
);


  // Control signals pipeline
  logic [READ_LATENCY-1:0] rst_d;
  logic [READ_LATENCY-1:0] en_d;

  assign rst_d[0] = rst;
  assign en_d[0]  = en;

  generate
    for (genvar i = 1; i < READ_LATENCY; i = i + 1) begin : g_pipe
      always_ff @(posedge clk) begin
        rst_d[i] <= rst_d[i-1];
        en_d[i]  <= en_d[i-1];
      end
    end
  endgenerate


  bram_sp #(
      .ADDR_WIDTH  (ADDR_WIDTH),
      .DATA_WIDTH  (DATA_WIDTH),
      .READ_LATENCY(READ_LATENCY),
      .INIT_WORD   (INIT_WORD),
      .INIT_FILE   (INIT_FILE)
  ) i_bram_sdp (
      // Port A
      .clk (clk),
      .rst (rst_d),
      .en  (en_d),
      .we  (we),
      .addr(addr),
      .din (din),
      .dout(dout)
  );

endmodule

`default_nettype wire
