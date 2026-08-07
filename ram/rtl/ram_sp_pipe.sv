// File: ram_sp_pipe.sv
// Brief: Simplified Single Port (SP) Memory, but with control (enable and
//        reset) signal pipeline.
`timescale 1 ns / 1 ps
//
`default_nettype none

module ram_sp_pipe #(
    parameter int ADDR_WIDTH   = 10,
    parameter int DATA_WIDTH   = 32,
    parameter     WRITE_MODE   = "READ_FIRST",     // "WRITE_FIRST", "READ_FIRST", or "NO_CHANGE"
    parameter int READ_LATENCY = 2,
    //
    parameter int DEPTH        = 1 << ADDR_WIDTH,
    parameter     INIT_FILE    = "NONE",
    parameter     RAM_STYLE    = "AUTO"
) (
    // Port A
    input var                   clk,
    input var                   rst,
    input var                   en,
    input var                   we,
    input var  [ADDR_WIDTH-1:0] addr,
    input var  [DATA_WIDTH-1:0] din,
    output var [DATA_WIDTH-1:0] dout
);

  // Control signals pipeline. Stage 0 stays combinational so the core's
  // first-stage enable aligns with the unpipelined address and data inputs.
  logic [READ_LATENCY-1:0] rst_d;
  logic [READ_LATENCY-1:0] en_d;

  assign rst_d[0] = rst;
  assign en_d[0]  = en;

  generate
    if (READ_LATENCY > 1) begin : g_pipe
      logic [READ_LATENCY-2:0] rst_sr;
      logic [READ_LATENCY-2:0] en_sr;

      always_ff @(posedge clk) begin
        rst_sr[0] <= rst;
        en_sr[0]  <= en;
        for (int i = 1; i < READ_LATENCY - 1; i++) begin
          rst_sr[i] <= rst_sr[i-1];
          en_sr[i]  <= en_sr[i-1];
        end
      end

      for (genvar i = 1; i < READ_LATENCY; i++) begin : g_tap
        assign rst_d[i] = rst_sr[i-1];
        assign en_d[i]  = en_sr[i-1];
      end
    end
  endgenerate


  ram_sp #(
      .ADDR_WIDTH  (ADDR_WIDTH),
      .DATA_WIDTH  (DATA_WIDTH),
      .WRITE_MODE  (WRITE_MODE),
      .READ_LATENCY(READ_LATENCY),
      //
      .DEPTH       (DEPTH),
      .INIT_FILE   (INIT_FILE),
      .RAM_STYLE   (RAM_STYLE)
  ) i_ram_sp (
      // Port A
      .clk (clk),
      .rst (rst_d[READ_LATENCY-1]),
      .en  (en_d),
      .we  (we),
      .addr(addr),
      .din (din),
      .dout(dout)
  );

endmodule

`default_nettype wire
