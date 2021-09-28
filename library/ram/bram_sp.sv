// File: bram_sp.sv
// Brief: Simplified abstract signle port (SP) memory.

`timescale 1ns / 1ps `default_nettype none

module bram_sp #(
    parameter int    ADDR_WIDTH   = 10,
    parameter int    DATA_WIDTH   = 32,
    parameter int    READ_LATENCY = 2 ,  // 1 ~ 3
    parameter int    INIT_WORD    = '0,
    parameter string INIT_FILE    = ""
) (
    input var                     clk,
    input var  [READ_LATENCY-1:0] rst,
    input var  [READ_LATENCY-1:0] en,
    input var                     we,
    input var  [  ADDR_WIDTH-1:0] addr,
    input var  [  DATA_WIDTH-1:0] din,
    output var [  DATA_WIDTH-1:0] dout
);


  initial begin
    assert (1 <= READ_LATENCY && READ_LATENCY <= 3)
    else $error("READ_LATENCY should be within range 1 to 3.");
  end


  // The Memory
  logic [DATA_WIDTH-1:0] MEM [2**ADDR_WIDTH];

  // Port B output pipeline
  logic [DATA_WIDTH-1:0] rega[ READ_LATENCY] = '{READ_LATENCY{'0}};

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

  always_ff @(posedge clk) begin
    if (en && we) begin
      MEM[addr] <= din;
    end
  end

  // Memory read

  always_ff @(posedge clk) begin
    if (rst[0]) begin
      rega[0] <= '0;
    end else if (en[0]) begin
      rega[0] <= MEM[addr];
    end
  end

  // Additional clock cycle read latency improves clock-to-out timing
  generate
    for (genvar i = 1; i < READ_LATENCY; i++) begin : g_output_reg
      always_ff @(posedge clk) begin
        if (rst[i]) begin
          rega[i] <= '0;
        end else if (en[i]) begin
          rega[i] <= rega[i-1];
        end
      end
    end
  endgenerate

  assign dout = rega[READ_LATENCY-1];

endmodule

`default_nettype wire
