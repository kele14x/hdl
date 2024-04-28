`timescale 1 ns / 1 ps
//
`default_nettype none

module prach_buffer_cp_fifo #(
    parameter int WIDTH = 144,
    parameter int DEPTH = 16
) (
    input var              rst_n,
    //
    input var              wr_clk,
    //
    input var              wr_valid,
    input var  [WIDTH-1:0] wr_data,
    output var             wr_ready,
    //
    input var              rd_clk,
    //
    output var [WIDTH-1:0] rd_data,
    output var             rd_valid,
    input var              rd_ready
);

  logic wrfull;
  logic rdempty;

  dcfifo #(
      .lpm_width    (WIDTH),
      .lpm_numwords (DEPTH),
      .lpm_showahead("ON"),
      .lpm_widthu   (4)

  ) u_dcfifo (
      .aclr     (~rst_n),
      .eccstatus(  /* not used */),
      // Write
      .wrclk    (wr_clk),
      .wrreq    (wr_valid),
      .data     (wr_data),
      .wrempty  (  /* not used */),
      .wrfull   (wrfull),
      .wrusedw  (  /* not used */),
      // Read
      .rdclk    (rd_clk),
      .rdreq    (rd_ready),
      .q        (rd_data),
      .rdempty  (rdempty),
      .rdfull   (  /* not used */),
      .rdusedw  (  /* not used */)
  );

  assign wr_ready = ~wrfull;
  assign rd_valid = ~rdempty;

endmodule

`default_nettype wire
