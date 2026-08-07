// File: ram_sdp_pipe.sv
// Brief: Simplified Simple Dual Port (SDP) memory, but with control (enable and
//        reset) signal pipeline.
`timescale 1 ns / 1 ps
//
`default_nettype none

module ram_sdp_pipe #(
    parameter int ADDR_WIDTH   = 10,
    parameter int DATA_WIDTH   = 32,
    parameter int READ_LATENCY = 2,
    //
    parameter int DEPTH        = 1 << ADDR_WIDTH,
    parameter     INIT_FILE    = "NONE",
    parameter     RAM_STYLE    = "AUTO"
) (
    // Port A
    input var                   clka,
    input var                   wea,
    input var  [ADDR_WIDTH-1:0] addra,
    input var  [DATA_WIDTH-1:0] dina,
    // Port B
    input var                   clkb,
    input var                   rstb,
    input var                   enb,
    input var  [ADDR_WIDTH-1:0] addrb,
    output var [DATA_WIDTH-1:0] doutb
);


  // Control signals pipeline. Stage 0 stays combinational so the core's
  // first-stage enable aligns with the unpipelined address inputs.
  logic [READ_LATENCY-1:0] rstb_d;
  logic [READ_LATENCY-1:0] enb_d;

  assign rstb_d[0] = rstb;
  assign enb_d[0]  = enb;

  generate
    if (READ_LATENCY > 1) begin : g_pipe_b
      logic [READ_LATENCY-2:0] rstb_sr;
      logic [READ_LATENCY-2:0] enb_sr;

      always_ff @(posedge clkb) begin
        rstb_sr[0] <= rstb;
        enb_sr[0]  <= enb;
        for (int i = 1; i < READ_LATENCY - 1; i++) begin
          rstb_sr[i] <= rstb_sr[i-1];
          enb_sr[i]  <= enb_sr[i-1];
        end
      end

      for (genvar i = 1; i < READ_LATENCY; i++) begin : g_tap_b
        assign rstb_d[i] = rstb_sr[i-1];
        assign enb_d[i]  = enb_sr[i-1];
      end
    end
  endgenerate


  ram_sdp #(
      .ADDR_WIDTH  (ADDR_WIDTH),
      .DATA_WIDTH  (DATA_WIDTH),
      .READ_LATENCY(READ_LATENCY),
      //
      .DEPTH       (DEPTH),
      .INIT_FILE   (INIT_FILE),
      .RAM_STYLE   (RAM_STYLE)
  ) i_ram_sdp (
      // Port A
      .clka (clka),
      .wea  (wea),
      .addra(addra),
      .dina (dina),
      // Port B
      .clkb (clkb),
      .rstb (rstb_d[READ_LATENCY-1]),
      .enb  (enb_d),
      .addrb(addrb),
      .doutb(doutb)
  );

endmodule

`default_nettype wire
