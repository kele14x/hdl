/*
 * Simple Dual Port (SDP) Memory module with pipeline
 *
 * See ram_sdp.v for more details
 */

`timescale 1 ns / 1 ps
//
`default_nettype none

module ram_sdp_pipe #(
    parameter integer                  ADDR_WIDTH = 10,
    parameter integer                  DATA_WIDTH = 32,
    parameter reg                      OUTPUT_REG = 1'b1,
    parameter reg     [DATA_WIDTH-1:0] INIT_WORD  = 'b0,
    parameter                          INIT_FILE  = "",
    parameter                          RAM_STYLE  = "AUTO"
) (
    // Port A
    input  wire                  clka,
    input  wire                  wea,
    input  wire [ADDR_WIDTH-1:0] addra,
    input  wire [DATA_WIDTH-1:0] dina,
    // Port B
    input  wire                  clkb,
    input  wire                  rstb,
    input  wire                  enb,
    input  wire [ADDR_WIDTH-1:0] addrb,
    output wire [DATA_WIDTH-1:0] doutb
);

  // Control signals pipeline
  wire [OUTPUT_REG:0] rstb_s;
  wire [OUTPUT_REG:0] enb_s;

  generate
    if (OUTPUT_REG == 0) begin : g_no_reg

      assign rstb_s = rstb;
      assign enb_s  = enb;

    end else begin : g_reg

      reg rstb_d;
      reg enb_d;

      always @(posedge clkb) begin
        rstb_d <= rstb;
        enb_d  <= enb;
      end

      assign rstb_s = {rstb_d, rstb};
      assign enb_s  = {enb_d, enb};

    end
  endgenerate

  ram_sdp #(
      .ADDR_WIDTH(ADDR_WIDTH),
      .DATA_WIDTH(DATA_WIDTH),
      .OUTPUT_REG(OUTPUT_REG),
      .INIT_WORD (INIT_WORD),
      .INIT_FILE (INIT_FILE),
      .RAM_STYLE (RAM_STYLE)
  ) i_ram_sdp (
      // Port A
      .clka (clka),
      .wea  (wea),
      .addra(addra),
      .dina (dina),
      // Port B
      .clkb (clkb),
      .rstb (rstb_s),
      .enb  (enb_s),
      .addrb(addrb),
      .doutb(doutb)
  );

endmodule

`default_nettype wire
