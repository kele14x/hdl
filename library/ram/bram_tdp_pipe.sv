// File: bram_tdp_pipe.sv
// Brief: Simplified True Dual Port Memory, but with control (enable and reset)
//        signal pipelined.

`timescale 1 ns / 1 ps `default_nettype none

module bram_tdp_pipe #(
    parameter int    ADDR_WIDTH     = 10,
    parameter int    DATA_WIDTH     = 32,
    parameter int    READ_LATENCY_A = 2,
    parameter int    READ_LATENCY_B = 2,
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


  // Control signals pipeline
  logic [READ_LATENCY_A-1:0] rsta_d;
  logic [READ_LATENCY_A-1:0] ena_d;

  logic [READ_LATENCY_B-1:0] rstb_d;
  logic [READ_LATENCY_B-1:0] enb_d;

  assign rsta_d[0] = rsta;
  assign ena_d[0]  = ena;

  assign rstb_d[0] = rstb;
  assign enb_d[0]  = enb;

  generate
    for (genvar i = 1; i < READ_LATENCY_A; i = i + 1) begin : g_pipe_a
      always_ff @(posedge clka) begin
        rsta_d[i] <= rsta_d[i-1];
        ena_d[i]  <= ena_d[i-1];
      end
    end

    for (genvar i = 1; i < READ_LATENCY_B; i = i + 1) begin : g_pipe_b
      always_ff @(posedge clkb) begin
        rstb_d[i] <= rstb_d[i-1];
        enb_d[i]  <= enb_d[i-1];
      end
    end
  endgenerate


  bram_tdp #(
      .ADDR_WIDTH    (ADDR_WIDTH),
      .DATA_WIDTH    (DATA_WIDTH),
      .READ_LATENCY_A(READ_LATENCY_A),
      .READ_LATENCY_B(READ_LATENCY_B),
      .INIT_WORD     (INIT_WORD),
      .INIT_FILE     (INIT_FILE)
  ) i_bram_tdp (
      // Port A
      .clka (clka),
      .rsta (rsta_d),
      .ena  (ena_d),
      .wea  (wea),
      .addra(addra),
      .dina (dina),
      .douta(douta),
      // Port B
      .clkb (clkb),
      .rstb (rstb_d),
      .enb  (enb_d),
      .web  (web),
      .addrb(addrb),
      .dinb (dinb),
      .doutb(doutb)
  );

endmodule

`default_nettype wire
