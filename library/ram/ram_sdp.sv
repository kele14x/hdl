// File: ram_sdp.sv
// Brief: Simplified Simple Dual Port (SDP) memory. Port A is the
//        write port, port B is the read port. Each port has dedicated address
//        port.
`timescale 1ns / 1ps 
//
`default_nettype none

module ram_sdp #(
    parameter int    ADDR_WIDTH   = 10,
    parameter int    DATA_WIDTH   = 32,
    parameter int    READ_LATENCY = 3,  // 1 ~ 3
    parameter int    INIT_WORD    = '0,
    parameter string INIT_FILE    = ""
) (
    // Port A, write port
    input var                     clka,
    input var                     ena,
    input var                     wea,
    input var  [  ADDR_WIDTH-1:0] addra,
    input var  [  DATA_WIDTH-1:0] dina,
    // Port B, read port
    input var                     clkb,
    input var  [READ_LATENCY-1:0] rstb,
    input var  [READ_LATENCY-1:0] enb,
    input var  [  ADDR_WIDTH-1:0] addrb,
    output var [  DATA_WIDTH-1:0] doutb
);


  initial begin
    assert (1 <= READ_LATENCY && READ_LATENCY <= 3)
    else $error("READ_LATENCY should be within range 1 to 3.");
  end


  // The Memory
  logic [DATA_WIDTH-1:0] MEM [2**ADDR_WIDTH];

  // Port B output pipeline
  logic [DATA_WIDTH-1:0] regb[ READ_LATENCY] = '{READ_LATENCY{'0}};

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

  always_ff @(posedge clka) begin
    if (ena && wea) begin
      MEM[addra] <= dina;
    end
  end

  // Memory read

  always_ff @(posedge clkb) begin
    if (rstb[0]) begin
      regb[0] <= '0;
    end else if (enb[0]) begin
      regb[0] <= MEM[addrb];
    end
  end

  // Additional clock cycle read latency improves clock-to-out timing
  generate
    for (genvar i = 1; i < READ_LATENCY; i++) begin : g_output_reg
      always_ff @(posedge clkb) begin
        if (rstb[i]) begin
          regb[i] <= '0;
        end else if (enb[i]) begin
          regb[i] <= regb[i-1];
        end
      end
    end
  endgenerate

  assign doutb = regb[READ_LATENCY-1];

endmodule

`default_nettype wire
