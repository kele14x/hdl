// File: ram_sdp_pipe.sv
// Brief: Simplified Simple Dual Port (SDP) memory, but with control (enable and
//        reset) signal pipelined.

`timescale 1ns / 1ps `default_nettype none

module ram_sdp_pipe #(
    parameter integer ADDR_WIDTH   = 10,
    parameter integer DATA_WIDTH   = 32,
    parameter integer READ_LATENCY = 2 ,
    parameter integer INIT_WORD    = 'd0,
    parameter string  INIT_FILE    = ""
) (
    // Port A
    input var                   clka,
    input var                   ena,
    input var                   wea,
    input var  [ADDR_WIDTH-1:0] addra,
    input var  [DATA_WIDTH-1:0] dina,
    // Port B
    input var                   clkb,
    input var                   rstb,
    input var                   enb,
    input var  [ADDR_WIDTH-1:0] addrb,
    output var [DATA_WIDTH-1:0] doutb
);


  // Control signals pipeline
  logic [READ_LATENCY-1:0] rstb_d;
  logic [READ_LATENCY-1:0] enb_d;

  assign rstb_d[0] = rstb;
  assign enb_d[0]  = enb;

  generate
    for (genvar i = 1; i < READ_LATENCY; i = i + 1) begin : g_pipe_b
      always @(posedge clkb) begin
        rstb_d[i] <= rstb_d[i-1];
        enb_d[i]  <= enb_d[i-1];
      end
    end
  endgenerate


  ram_sdp #(
      .ADDR_WIDTH  (ADDR_WIDTH),
      .DATA_WIDTH  (DATA_WIDTH),
      .READ_LATENCY(READ_LATENCY),
      .INIT_WORD   (INIT_WORD),
      .INIT_FILE   (INIT_FILE)
  ) i_ram_sdp (
      // Port A
      .clka (clka),
      .ena  (ena),
      .wea  (wea),
      .addra(addra),
      .dina (dina),
      // Port B
      .clkb (clkb),
      .rstb (rstb_d),
      .enb  (enb_d),
      .addrb(addrb),
      .doutb(doutb)
  );

endmodule

`default_nettype wire
