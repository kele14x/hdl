// File: ram_tdp.sv
// Brief: Simplified True Dual Port Memory. Which means RAM with two ports, and
//        both ports can be used to write and read. However, each port only has
//        one address port, it's used for both read and write. Which means you
//        can't simultaneously do write and read on different address using only
//        one port.
`timescale 1 ns / 1 ps 
//
`default_nettype none

module ram_tdp #(
    parameter integer ADDR_WIDTH     = 10,
    parameter integer DATA_WIDTH     = 32,
    parameter integer READ_LATENCY_A = 3,
    parameter integer READ_LATENCY_B = 3,
    parameter integer INIT_WORD      = 'b0,
    parameter         INIT_FILE      = ""
) (
    // Port A
    input wire                       clka,
    input wire  [READ_LATENCY_A-1:0] rsta,
    input wire  [READ_LATENCY_A-1:0] ena,
    input wire                       wea,
    input wire  [    ADDR_WIDTH-1:0] addra,
    input wire  [    DATA_WIDTH-1:0] dina,
    output wire [    DATA_WIDTH-1:0] douta,
    // Port B
    input wire                       clkb,
    input wire  [READ_LATENCY_B-1:0] rstb,
    input wire  [READ_LATENCY_B-1:0] enb,
    input wire                       web,
    input wire  [    ADDR_WIDTH-1:0] addrb,
    input wire  [    DATA_WIDTH-1:0] dinb,
    output wire [    DATA_WIDTH-1:0] doutb
);


  initial begin
    if (!(1 <= READ_LATENCY_A && READ_LATENCY_A <= 3)) begin
      $error("READ_LATENCY_A should be within range 1 to 3.");
      #1 $finish();
    end
    if (!(1 <= READ_LATENCY_B && READ_LATENCY_B <= 3)) begin
      $error("READ_LATENCY_B should be within range 1 to 3.");
      #1 $finish();
    end
  end

  // The Memory
  reg [DATA_WIDTH-1:0] MEM [ 2**ADDR_WIDTH];

  // Port A output pipeline
  reg [DATA_WIDTH-1:0] rega[READ_LATENCY_A];
  // Port B output pipeline
  reg [DATA_WIDTH-1:0] regb[READ_LATENCY_B];


  initial begin
    integer i;
    for (i = 0; i < READ_LATENCY_A; i = i + 1) begin
      rega[i] = 'b0;
    end
    for (i = 0; i < READ_LATENCY_B; i = i + 1) begin
      regb[i] = 'b0;
    end
  end

  // Initializes the memory values to a specified file or to all zeros to match
  // hardware
  initial begin
    for (int i = 0; i < 2 ** ADDR_WIDTH; i = i + 1) begin
      MEM[i] = INIT_WORD;
    end
    if (INIT_FILE != "") begin : g_file_init
      $readmemh(INIT_FILE, MEM, 0, 2 ** ADDR_WIDTH - 1);
    end
  end

  // Memory write

  always @(posedge clka) begin
    if (ena[0] && wea) begin
      MEM[addra] <= dina;
    end
  end

  always @(posedge clkb) begin
    if (enb[0] && web) begin
      MEM[addrb] <= dinb;
    end
  end

  // Port A read

  always @(posedge clka) begin
    if (rsta[0]) begin
      rega[0] <= 'b0;
    end else if (ena[0]) begin
      rega[0] <= MEM[addra];
    end
  end

  // Read B read

  always @(posedge clkb) begin
    if (rstb[0]) begin
      regb[0] <= 'b0;
    end else if (enb[0]) begin
      regb[0] <= MEM[addrb];
    end
  end

  // Additional clock cycle read latency improves clock-to-out timing
  generate
    genvar i;
    for (i = 1; i < READ_LATENCY_A; i = i + 1) begin : g_pipeline_a
      always @(posedge clka) begin
        if (rsta[i]) begin
          rega[i] <= 'b0;
        end else if (ena[i]) begin
          rega[i] <= rega[i-1];
        end
      end
    end

    for (i = 1; i < READ_LATENCY_B; i = i + 1) begin : g_pipeline_b
      always @(posedge clkb) begin
        if (rstb[i]) begin
          regb[i] <= 'b0;
        end else if (enb[i]) begin
          regb[i] <= regb[i-1];
        end
      end
    end
  endgenerate

  assign douta = rega[READ_LATENCY_A-1];
  assign doutb = regb[READ_LATENCY_B-1];

endmodule

`default_nettype wire
