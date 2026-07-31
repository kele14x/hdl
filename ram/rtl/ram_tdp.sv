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
    parameter int ADDR_WIDTH = 10,
    parameter int DATA_WIDTH = 32,
    parameter string WRITE_MODE_A = "READ_FIRST",  // "WRITE_FIRST", "READ_FIRST", or "NO_CHANGE"
    parameter string WRITE_MODE_B = "READ_FIRST",  // "WRITE_FIRST", "READ_FIRST", or "NO_CHANGE"
    parameter int READ_LATENCY_A = 3,
    parameter int READ_LATENCY_B = 3,
    parameter bit [DATA_WIDTH-1:0] INIT_WORD = '0,
    parameter string INIT_FILE = ""
) (
    // Port A
    input var                       clka,
    input var  [READ_LATENCY_A-1:0] rsta,
    input var  [READ_LATENCY_A-1:0] ena,
    input var                       wea,
    input var  [    ADDR_WIDTH-1:0] addra,
    input var  [    DATA_WIDTH-1:0] dina,
    output var [    DATA_WIDTH-1:0] douta,
    // Port B
    input var                       clkb,
    input var  [READ_LATENCY_B-1:0] rstb,
    input var  [READ_LATENCY_B-1:0] enb,
    input var                       web,
    input var  [    ADDR_WIDTH-1:0] addrb,
    input var  [    DATA_WIDTH-1:0] dinb,
    output var [    DATA_WIDTH-1:0] doutb
);


  initial begin
    assert (1 <= READ_LATENCY_A && READ_LATENCY_A <= 3)
    else begin
      $fatal(1, "READ_LATENCY_A should be within range 1 to 3.");
    end
    assert (1 <= READ_LATENCY_B && READ_LATENCY_B <= 3)
    else begin
      $fatal(1, "READ_LATENCY_B should be within range 1 to 3.");
    end
  end

  // The Memory
  logic [DATA_WIDTH-1:0] MEM [ 2**ADDR_WIDTH];

  // Port A output pipeline
  logic [DATA_WIDTH-1:0] rega[READ_LATENCY_A];
  // Port B output pipeline
  logic [DATA_WIDTH-1:0] regb[READ_LATENCY_B];


  // Initializes the memory values to a specified file or to all zeros to match
  // hardware
  initial begin
    for (int i = 0; i < 2 ** ADDR_WIDTH; i++) begin
      MEM[i] = INIT_WORD;
    end
    if (INIT_FILE != "") begin : g_file_init
      $readmemh(INIT_FILE, MEM, 0, 2 ** ADDR_WIDTH - 1);
    end
  end

  // Memory write

  always_ff @(posedge clka) begin
    if (ena[0] && wea) begin
      MEM[addra] <= dina;
    end
  end

  always_ff @(posedge clkb) begin
    if (enb[0] && web) begin
      MEM[addrb] <= dinb;
    end
  end

  // Port A read

  always_ff @(posedge clka) begin
    if (rsta[0]) begin
      rega[0] <= '0;
    end else if (ena[0]) begin
      if ((wea == 1'b1) && (WRITE_MODE_A == "WRITE_FIRST")) begin
        rega[0] <= dina;
      end else if ((wea == 1'b1) && (WRITE_MODE_A == "NO_CHANGE")) begin
        rega[0] <= rega[0];
      end else begin  // no wea, or write mode is "READ_FIRST"
        rega[0] <= MEM[addra];
      end
    end
  end

  // Read B read

  always_ff @(posedge clkb) begin
    if (rstb[0]) begin
      regb[0] <= '0;
    end else if (enb[0]) begin
      if ((web == 1'b1) && (WRITE_MODE_B == "WRITE_FIRST")) begin
        regb[0] <= dinb;
      end else if ((web == 1'b1) && (WRITE_MODE_B == "NO_CHANGE")) begin
        regb[0] <= regb[0];
      end else begin  // no web, or write mode is "READ_FIRST"
        regb[0] <= MEM[addrb];
      end
    end
  end

  // Additional clock cycle read latency improves clock-to-out timing
  generate
    for (genvar i = 1; i < READ_LATENCY_A; i++) begin : g_pipeline_a
      always_ff @(posedge clka) begin
        if (rsta[i]) begin
          rega[i] <= '0;
        end else if (ena[i]) begin
          rega[i] <= rega[i-1];
        end
      end
    end

    for (genvar i = 1; i < READ_LATENCY_B; i++) begin : g_pipeline_b
      always_ff @(posedge clkb) begin
        if (rstb[i]) begin
          regb[i] <= '0;
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
