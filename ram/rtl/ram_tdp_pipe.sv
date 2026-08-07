// File: ram_tdp_pipe.sv
// Brief: Simplified True Dual Port Memory, but with control (enable and reset)
//        signal pipeline.
`timescale 1 ns / 1 ps
//
`default_nettype none

module ram_tdp_pipe #(
    parameter int ADDR_WIDTH     = 10,
    parameter int DATA_WIDTH     = 32,
    parameter     WRITE_MODE_A   = "READ_FIRST",  // "WRITE_FIRST", "READ_FIRST", or "NO_CHANGE"
    parameter     WRITE_MODE_B   = "READ_FIRST",  // "WRITE_FIRST", "READ_FIRST", or "NO_CHANGE"
    parameter int READ_LATENCY_A = 2,
    parameter int READ_LATENCY_B = 2,
    //
    parameter int DEPTH          = 1 << ADDR_WIDTH,
    parameter     INIT_FILE      = "NONE",
    parameter     RAM_STYLE      = "AUTO"
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


  // Control signals pipeline. Stage 0 stays combinational so each core's
  // first-stage enable aligns with the unpipelined address and data inputs.
  logic [READ_LATENCY_A-1:0] rsta_d;
  logic [READ_LATENCY_A-1:0] ena_d;

  logic [READ_LATENCY_B-1:0] rstb_d;
  logic [READ_LATENCY_B-1:0] enb_d;

  assign rsta_d[0] = rsta;
  assign ena_d[0]  = ena;

  assign rstb_d[0] = rstb;
  assign enb_d[0]  = enb;

  generate
    if (READ_LATENCY_A > 1) begin : g_pipe_a
      logic [READ_LATENCY_A-2:0] rsta_sr;
      logic [READ_LATENCY_A-2:0] ena_sr;

      always_ff @(posedge clka) begin
        rsta_sr[0] <= rsta;
        ena_sr[0]  <= ena;
        for (int i = 1; i < READ_LATENCY_A - 1; i++) begin
          rsta_sr[i] <= rsta_sr[i-1];
          ena_sr[i]  <= ena_sr[i-1];
        end
      end

      for (genvar i = 1; i < READ_LATENCY_A; i++) begin : g_tap_a
        assign rsta_d[i] = rsta_sr[i-1];
        assign ena_d[i]  = ena_sr[i-1];
      end
    end

    if (READ_LATENCY_B > 1) begin : g_pipe_b
      logic [READ_LATENCY_B-2:0] rstb_sr;
      logic [READ_LATENCY_B-2:0] enb_sr;

      always_ff @(posedge clkb) begin
        rstb_sr[0] <= rstb;
        enb_sr[0]  <= enb;
        for (int i = 1; i < READ_LATENCY_B - 1; i++) begin
          rstb_sr[i] <= rstb_sr[i-1];
          enb_sr[i]  <= enb_sr[i-1];
        end
      end

      for (genvar i = 1; i < READ_LATENCY_B; i++) begin : g_tap_b
        assign rstb_d[i] = rstb_sr[i-1];
        assign enb_d[i]  = enb_sr[i-1];
      end
    end
  endgenerate


  ram_tdp #(
      .ADDR_WIDTH    (ADDR_WIDTH),
      .DATA_WIDTH    (DATA_WIDTH),
      .WRITE_MODE_A  (WRITE_MODE_A),
      .WRITE_MODE_B  (WRITE_MODE_B),
      .READ_LATENCY_A(READ_LATENCY_A),
      .READ_LATENCY_B(READ_LATENCY_B),
      //
      .DEPTH         (DEPTH),
      .INIT_FILE     (INIT_FILE),
      .RAM_STYLE     (RAM_STYLE)
  ) i_ram_tdp (
      // Port A
      .clka (clka),
      .rsta (rsta_d[READ_LATENCY_A-1]),
      .ena  (ena_d),
      .wea  (wea),
      .addra(addra),
      .dina (dina),
      .douta(douta),
      // Port B
      .clkb (clkb),
      .rstb (rstb_d[READ_LATENCY_B-1]),
      .enb  (enb_d),
      .web  (web),
      .addrb(addrb),
      .dinb (dinb),
      .doutb(doutb)
  );

endmodule

`default_nettype wire
