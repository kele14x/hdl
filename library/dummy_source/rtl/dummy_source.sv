// File: dummy_source.sv
// Brief: Generate random bits to test downlink.
`timescale 1 ns / 1 ps
//
`default_nettype none

module dummy_source #(
    parameter int ADDR_WIDTH = 10,
    parameter int DATA_WIDTH = 16
) (
    input var                     clk,
    input var                     rst,
    input var  [             7:0] data_sync_in,
    output var [       WIDTH-1:0] data,
    // Control interface
    //
    input var                     ctrl_clk,
    input var                     ctrl_rst,
    //
    input var  [             2:0] ctrl_numerology,   // 0 ~ 4
    input var                     ctrl_csr,          // 0 ~ 15
    input var                     ctrl_len,
    //
    input var                     ctrl_modram_en,
    input var                     ctrl_modram_we,
    input var  [  ADDR_WIDTH-1:0] ctrl_modram_addr,
    input var  [DATA_WIDTH*2-1:0] ctrl_modram_din,
    output var [DATA_WIDTH*2-1:0] ctrl_modram_dout
);


  lfsr #(
      .BIT_WIDTH       (BIT_WIDTH),
      .INITIAL         (INITIAL),
      .POLYNOMIAL      (POLYNOMIAL),
      .STRUCTURE       (STRUCTURE),
      .GATE_TYPE       (GATE_TYPE),
      .PARALLEL_OUTPUT (1'b1)
  ) i_lfsr (
      .clk  (clk),
      .rst  (rst),
      .en   (en),
      .load (1'b0),
      .din  ('0),
      .dout (dout)
  );


  ram_tdp_pipe #(
      .ADDR_WIDTH    (ADDR_WIDTH),
      .DATA_WIDTH    (DATA_WIDTH),
      .READ_LATENCY_A(READ_LATENCY_A),
      .READ_LATENCY_B(READ_LATENCY_B),
      .INIT_WORD     ('0)
  ) i_modram (
      // Port A
      .clka (ctrl_clk),
      .rsta (ctrl_rst),
      .ena  (ctrl_modram_en),
      .wea  (ctrl_modram_we),
      .addra(ctrl_modran_addr),
      .dina (ctrl_modram_din),
      .douta(ctrl_modram_dout),
      // Port B
      .clkb (clkb),
      .rstb (rstb),
      .enb  (enb),
      .web  (web),
      .addrb(addrb),
      .dinb (dinb),
      .doutb(doutb)
  );

endmodule
