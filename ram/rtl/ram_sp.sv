// File: ram_sp.sv
// Brief: Simplified Single Port (SP) Memory.
`timescale 1ns / 1ps
//
`default_nettype none

module ram_sp #(
    parameter int ADDR_WIDTH = 10,
    parameter int DATA_WIDTH = 32,
    parameter string WRITE_MODE = "READ_FIRST",  // "WRITE_FIRST", "READ_FIRST", or "NO_CHANGE"
    parameter int READ_LATENCY = 2,  // 1 ~ 3
    parameter bit [DATA_WIDTH-1:0] INIT_WORD = '0,
    parameter string INIT_FILE = ""
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
    else begin
      $fatal(1, "[%m]: Read layency (READ_LATENCY) should be within range 1 to 3, got %d",
             READ_LATENCY);
    end

    assert (WRITE_MODE == "WRITE_FIRST" || WRITE_MODE == "READ_FIRST" || WRITE_MODE == "NO_CHANGE")
    else begin
      $fatal(
          1,
          "[%m]: Write mode (WRITE_MODE) should be one of \"WRITE_FIRST\", \"READ_FIRST\" and \"NO_CHANGE\", got %s",
          WRITE_MODE);
    end
  end


  // The Memory
  logic [DATA_WIDTH-1:0] MEM [2**ADDR_WIDTH];

  // Port B output pipeline
  logic [DATA_WIDTH-1:0] rega[ READ_LATENCY];

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

  always_ff @(posedge clk) begin
    if (en[0] && we) begin
      MEM[addr] <= din;
    end
  end

  // Memory read

  always_ff @(posedge clk) begin
    if (rst[0]) begin
      rega[0] <= '0;
    end else if (en[0]) begin
      if ((we == 1'b1) && (WRITE_MODE == "WRITE_FIRST")) begin
        rega[0] <= din;
      end else if ((we == 1'b1) && (WRITE_MODE == "NO_CHANGE")) begin
        rega[0] <= rega[0];
      end else begin  // no we, or write mode is "READ_FIRST"
        rega[0] <= MEM[addr];
      end
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
