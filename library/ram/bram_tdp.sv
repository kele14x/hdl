// File: bram_tdp.sv
// Brief: Simplified True Dual Port Memory. Which means RAM with two ports, and
//        both ports can be used to write and read. However, each port only has
//        one address port, it's used for both read and write. Which means you
//        can't simultaneously do write and read on different address using only
//        one port.

`timescale 1ns / 1ps `default_nettype none

module bram_tdp #(
    parameter int    ADDR_WIDTH     = 10,
    parameter int    DATA_WIDTH     = 32,
    parameter int    PORTA_LATENCY  = 3,
    parameter int    PORTB_LATENCY  = 3,
    parameter int    INIT_WORD      = '0,
    parameter string INIT_FILE      = ""
) (
    // Port A
    input var                   clka,
    input var                   rsta,
    input var                   ena,
    input var                   wea,
    input var  [ADDR_WIDTH-1:0] addra,
    input var  [DATA_WIDTH-1:0] dina,
    output var [DATA_WIDTH-1:0] douta,
    // Port B
    input var                   clkb,
    input var                   rstb,
    input var                   enb,
    input var                   web,
    input var  [ADDR_WIDTH-1:0] addrb,
    input var  [DATA_WIDTH-1:0] dinb,
    output var [DATA_WIDTH-1:0] doutb
);


  logic [DATA_WIDTH-1:0] MEM             [2**ADDR_WIDTH];

  logic [DATA_WIDTH-1:0] ram_data_a[PORTA_LATENCY];
  logic [DATA_WIDTH-1:0] ram_data_b[PORTB_LATENCY];

  logic                  ena_r[PORTA_LATENCY];
  logic                  enb_r[PORTA_LATENCY];

  logic                  rsta_r[PORTA_LATENCY];
  logic                  rstb_r[PORTA_LATENCY];

  // synthesis translate_off

  initial begin
    assert(1 <= PORTA_LATENCY && PORTA_LATENCY <= 3)
    else $error("PORTA_LATENCY should be with in range 1 to 3");
    assert(1 <= PORTB_LATENCY && PORTB_LATENCY <= 3)
    else $error("PORTB_LATENCY should be with in range 1 to 3");
  end

  // synthesis translate_on

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

  always_ff @(posedge clkb) begin
    if (enb && web) begin
      MEM[addrb] <= dinb;
    end
  end

  // Port A read

  assign ena_r[0] = ena;
  assign rsta_r[0] = rsta;

  always_ff @(posedge clka) begin
    for (int i = 1; i < PORTA_LATENCY; i++) begin
      ena_r[i] <= ena_r[i-1];
    end
  end

  always_ff @(posedge clka) begin
    for (int i = 1; i < PORTA_LATENCY; i++) begin
      rsta_r[i] <= rsta_r[i-1];
    end
  end

  always_ff @(posedge clka) begin
    if (ena_r[0]) begin
      ram_data_a[0] <= MEM[addra];
    end
    for (int i = 1; i < PORTA_LATENCY; i++) begin
      if (rsta_r[i]) begin
        ram_data_a[i] <= '0;
      end else if (ena_r[i]) begin
        ram_data_a[i] <= ram_data_a[i-1];
      end
    end
  end

  // Read B read

  assign enb_r[0] = enb;
  assign rstb_r[0] = rstb;

  always_ff @(posedge clkb) begin
    for (int i = 1; i < PORTB_LATENCY; i++) begin
      enb_r[i] <= enb_r[i-1];
    end
  end

  always_ff @(posedge clkb) begin
    for (int i = 1; i < PORTB_LATENCY; i++) begin
      rstb_r[i] <= rstb_r[i-1];
    end
  end

  always_ff @(posedge clkb) begin
    if (enb_r[0]) begin
      ram_data_b[0] <= MEM[addrb];
    end
    for (int i = 1; i < PORTB_LATENCY; i++) begin
      if (rstb_r[i]) begin
        ram_data_b[i] <= '0;
      end else if (enb_r[i]) begin
        ram_data_b[i] <= ram_data_b[i-1];
      end
    end
  end

  assign douta = ram_data_a[PORTA_LATENCY-1];
  assign doutb = ram_data_b[PORTB_LATENCY-1];

endmodule

`default_nettype wire
