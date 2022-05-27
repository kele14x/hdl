// File: dds_rom.sv
// Brief: Cosine loop-up table for DDS.
`timescale 1ns / 1ps
//
`default_nettype none

module dds_rom #(
    parameter integer ADDR_WIDTH = 12,
    parameter integer DATA_WIDTH = 16
) (
    input  wire                        clk,
    //
    input  wire                        rsta,
    input  wire                        ena,
    input  wire       [ADDR_WIDTH-1:0] addra,
    output reg signed [DATA_WIDTH-1:0] douta,
    //
    input  wire                        rstb,
    input  wire                        enb,
    input  wire       [ADDR_WIDTH-1:0] addrb,
    output reg signed [DATA_WIDTH-1:0] doutb
);

  // Local parameters
  //=================

  localparam integer Latency = 2;
  localparam real PI = 3.14159265359;


  // Signals
  //========

  reg ena_d;
  reg enb_d;

  // The Memory
  reg signed [DATA_WIDTH-1:0] MEM[0:2**ADDR_WIDTH-1];

  reg signed [   DATA_WIDTH-1:0] douta_s;
  reg signed [   DATA_WIDTH-1:0] doutb_s;


  initial begin : p_init
    integer i;
    for (i = 0; i < 2 ** ADDR_WIDTH; i = i + 1) begin
      MEM[i] = (2 ** (DATA_WIDTH - 1) - 1) * $cos(PI * i / 2 ** (ADDR_WIDTH + 1));
    end
  end


  // Memory read
  //============

  always @(posedge clk) begin
    ena_d <= ena;
    enb_d <= enb;
  end

  always @(posedge clk) begin
    if (ena) begin
      douta_s <= MEM[addra];
    end
  end

  always @(posedge clk) begin
    if (enb) begin
      doutb_s <= MEM[addrb];
    end
  end

  always @(posedge clk) begin
    if (ena_d) begin
      douta <= douta_s;
    end
  end

  always @(posedge clk) begin
    if (enb_d) begin
      doutb <= doutb_s;
    end
  end

endmodule

`default_nettype wire
