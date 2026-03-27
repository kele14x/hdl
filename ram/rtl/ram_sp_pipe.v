/*
 * Simplified Single Port (SP) Memory with control (enable and reset) signal pipeline.
 *
 * Check ram_sp.v for more details.
 */

`timescale 1 ns / 1 ps
//
`default_nettype none

module ram_sp_pipe #(
    parameter integer                  ADDR_WIDTH = 10,
    parameter integer                  DATA_WIDTH = 32,
    parameter                          WRITE_MODE = "READ_FIRST",
    parameter reg                      OUTPUT_REG = 1'b1,
    parameter reg     [DATA_WIDTH-1:0] INIT_WORD  = 'b0,
    parameter                          INIT_FILE  = "",
    parameter                          RAM_STYLE  = "AUTO"
) (
    input  wire                  clk,
    input  wire                  rst,
    //
    input  wire                  en,
    input  wire                  we,
    input  wire [ADDR_WIDTH-1:0] addr,
    input  wire [DATA_WIDTH-1:0] din,
    output wire [DATA_WIDTH-1:0] dout
);

  // Control signals pipeline
  wire [OUTPUT_REG:0] rst_s;
  wire [OUTPUT_REG:0] en_s;

  generate
    if (OUTPUT_REG == 0) begin : g_no_reg

      assign rst_s = rst;
      assign en_s  = en;

    end else begin : g_reg

      reg rst_d;
      reg en_d;

      always @(posedge clk) begin
        rst_d <= rst;
        en_d  <= en;
      end

      assign rst_s = {rst_d, rst};
      assign en_s  = {en_d, en};

    end
  endgenerate

  ram_sp #(
      .ADDR_WIDTH(ADDR_WIDTH),
      .DATA_WIDTH(DATA_WIDTH),
      .WRITE_MODE(WRITE_MODE),
      .OUTPUT_REG(OUTPUT_REG),
      .INIT_WORD (INIT_WORD),
      .INIT_FILE (INIT_FILE),
      .RAM_STYLE (RAM_STYLE)
  ) i_ram_sp (
      .clk (clk),
      .rst (rst_s),
      .en  (en_s),
      .we  (we),
      .addr(addr),
      .din (din),
      .dout(dout)
  );

endmodule

`default_nettype wire
