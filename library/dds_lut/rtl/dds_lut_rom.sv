// File: dds_lut_rom.v
// Brief: The stored in memory part of DDS LUT.
`timescale 1 ns / 1 ps
//
`default_nettype none

module dds_lut_rom #(
    parameter bit    DUAL_PORT   = 1,
    parameter string COSINE_SINE = "COSINE",
    parameter string STRUCTURE   = "FULL",
    parameter int    ADDR_WIDTH  = 12,
    parameter int    DATA_WIDTH  = 16,
    parameter int    NEGATIVE    = 0
) (
    input var                          clk,
    //
    input var                          rsta,
    input var                          ena,
    input var         [ADDR_WIDTH-1:0] addra,
    output var signed [DATA_WIDTH-1:0] douta,
    //
    input var                          rstb,
    input var                          enb,
    input var         [ADDR_WIDTH-1:0] addrb,
    output var signed [DATA_WIDTH-1:0] doutb
);


  // Local parameters
  //=================

  localparam int Latency = 2;
  localparam real PI = 3.14159265359;


  // Signals
  //========

  logic                         ena_d;
  logic                         enb_d;

  // The Memory
  logic signed [DATA_WIDTH-1:0] MEM     [2**ADDR_WIDTH];

  logic signed [DATA_WIDTH-1:0] douta_s;
  logic signed [DATA_WIDTH-1:0] doutb_s;


  initial begin
    automatic int factor;
    automatic int a;
    case (STRUCTURE)
      "FULL":  factor = 1;
      "HALF":  factor = 2;
      default: factor = 4;
    endcase

    if (NEGATIVE) begin
      a = -1;
    end else begin
      a = 1;
    end

    // Initialize the memory using the system function $cos
    if (COSINE_SINE == "COSINE") begin
      for (int i = 0; i < 2 ** ADDR_WIDTH; i++) begin
        MEM[i] = a * (2 ** (DATA_WIDTH - 1) - 2) * $cos(2 * PI * i / 2 ** ADDR_WIDTH / factor);
      end
    end else begin
      for (int i = 0; i < 2 ** ADDR_WIDTH; i++) begin
        MEM[i] = a * (2 ** (DATA_WIDTH - 1) - 2) * $sin(2 * PI * i / 2 ** ADDR_WIDTH / factor);
      end
    end
  end


  // Memory port A
  //==============

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
    if (ena_d) begin
      douta <= douta_s;
    end
  end


  // Memory port B
  //==============

  generate
    if (DUAL_PORT) begin : g_dual_port

      always @(posedge clk) begin
        if (enb) begin
          doutb_s <= MEM[addrb];
        end
      end

      always @(posedge clk) begin
        if (enb_d) begin
          doutb <= doutb_s;
        end
      end

    end else begin : g_no_dual_port

      assign doutb = '0;

    end
  endgenerate

endmodule

`default_nettype wire
