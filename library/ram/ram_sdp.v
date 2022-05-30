// File: ram_sdp.v
// Brief: Simplified Simple Dual Port (SDP) memory. Port A is the
//        write port, port B is the read port. Each port has dedicated address
//        port.
`timescale 1ns / 1ps
//
`default_nettype none

module ram_sdp #(
    parameter integer ADDR_WIDTH   = 10,
    parameter integer DATA_WIDTH   = 32,
    parameter integer READ_LATENCY = 3,    // 1 ~ 3
    parameter integer INIT_WORD    = 'd0,
    parameter         INIT_FILE    = ""
) (
    // Port A, write port
    input  wire                    clka,
    input  wire                    ena,
    input  wire                    wea,
    input  wire [  ADDR_WIDTH-1:0] addra,
    input  wire [  DATA_WIDTH-1:0] dina,
    // Port B, read port
    input  wire                    clkb,
    input  wire [READ_LATENCY-1:0] rstb,
    input  wire [READ_LATENCY-1:0] enb,
    input  wire [  ADDR_WIDTH-1:0] addrb,
    output wire [  DATA_WIDTH-1:0] doutb
);


  initial begin
    if (!(1 <= READ_LATENCY && READ_LATENCY <= 3)) begin
      $error("READ_LATENCY should be within range 1 to 3.");
      #1 $finish;
    end
  end


  // The Memory
  reg [DATA_WIDTH-1:0] MEM [0:2**ADDR_WIDTH-1];

  // Port B output pipeline
  reg [DATA_WIDTH-1:0] regb[ 0:READ_LATENCY-1];

  // Initializes the memory values to a specified file or to all zeros to match
  // hardware
  initial begin : p_init
    integer i;
    for (i = 0; i < 2 ** ADDR_WIDTH; i = i + 1) begin
      MEM[i] = INIT_WORD;
    end
    if (INIT_FILE != "") begin : g_file_init
      $readmemh(INIT_FILE, MEM, 0, 2 ** ADDR_WIDTH - 1);
    end
  end

  // Memory write

  always @(posedge clka) begin
    if (ena && wea) begin
      MEM[addra] <= dina;
    end
  end

  // Memory read

  always @(posedge clkb) begin
    if (rstb[0]) begin
      regb[0] <= 'd0;
    end else if (enb[0]) begin
      regb[0] <= MEM[addrb];
    end
  end

  // Additional clock cycle read latency improves clock-to-out timing
  generate
    genvar i;
    for (i = 1; i < READ_LATENCY; i = i + 1) begin : g_output_reg
      always @(posedge clkb) begin
        if (rstb[i]) begin
          regb[i] <= 'd0;
        end else if (enb[i]) begin
          regb[i] <= regb[i-1];
        end
      end
    end
  endgenerate

  assign doutb = regb[READ_LATENCY-1];

endmodule

`default_nettype wire
