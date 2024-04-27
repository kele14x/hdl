// File: nlf_lut.sv
// Brief: LUT for nlf module
`timescale 1 ns / 1 ps
//
`default_nettype none

module nlf_lut #(
    parameter int INDEX_WIDTH = 8,
    parameter int LUT_WIDTH   = 32
) (
    // Read Interface
    input var                    clk,
    input var                    rst,
    //
    input var                    bank,
    input var  [INDEX_WIDTH-1:0] index,
    output var [ LUT_WIDTH -1:0] dout,
    // Write Interface
    input var                    ctrl_clk,
    input var                    ctrl_rst,
    //
    input var  [  INDEX_WIDTH:0] ctrl_lut_addr,
    input var                    ctrl_lut_en,
    input var                    ctrl_lut_we,
    input var  [ LUT_WIDTH -1:0] ctrl_lut_din,
    output var [ LUT_WIDTH -1:0] ctrl_lut_dout
);

  // LUT
  //====

  ram_tdp_pipe #(
      .ADDR_WIDTH     (INDEX_WIDTH + 1),
      .DATA_WIDTH     (LUT_WIDTH),
      .READ_LATENCY_A (1),
      .READ_LATENCY_B (3),
      .INIT_WORD      ({LUT_WIDTH{1'b0}}),
      .INIT_FILE      ("")
  ) i_lut (
      // Port A
      .clka          (ctrl_clk),
      .rsta          (ctrl_rst),
      .addra         (ctrl_lut_addr), // {bank, index}
      .ena           (ctrl_lut_en),
      .wea           (ctrl_lut_we),
      .dina          (ctrl_lut_din),
      .douta         (ctrl_lut_dout),
      // Port b
      .clkb          (clk),
      .rstb          (rst),
      .addrb         ({bank, index}),
      .enb           (1'b1),
      .web           (1'b0),
      .dinb          ({LUT_WIDTH{1'b0}}),
      .doutb         (dout)
  );

endmodule

`default_nettype wire
