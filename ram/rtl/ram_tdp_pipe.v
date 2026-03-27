/*
 * True Dual Port (TDP) Memory module with pipeline
 *
 * See ram_tdp.v for more details
 */

`timescale 1 ns / 1 ps
//
`default_nettype none

module ram_tdp_pipe #(
    parameter integer                  ADDR_WIDTH   = 10,
    parameter integer                  DATA_WIDTH   = 32,
    parameter                          WRITE_MODE_A = "READ_FIRST",
    parameter                          WRITE_MODE_B = "READ_FIRST",
    parameter reg                      OUTPUT_REG_A = 1'b1,
    parameter reg                      OUTPUT_REG_B = 1'b1,
    parameter reg     [DATA_WIDTH-1:0] INIT_WORD    = 'b0,
    parameter                          INIT_FILE    = "",
    parameter                          RAM_STYLE    = "AUTO"
) (
    // Port A
    input  wire                  clka,
    input  wire                  rsta,
    input  wire                  ena,
    input  wire                  wea,
    input  wire [ADDR_WIDTH-1:0] addra,
    input  wire [DATA_WIDTH-1:0] dina,
    output wire [DATA_WIDTH-1:0] douta,
    // Port B
    input  wire                  clkb,
    input  wire                  rstb,
    input  wire                  enb,
    input  wire                  web,
    input  wire [ADDR_WIDTH-1:0] addrb,
    input  wire [DATA_WIDTH-1:0] dinb,
    output wire [DATA_WIDTH-1:0] doutb
);

  // Control signals pipeline
  wire [OUTPUT_REG_A:0] rsta_s;
  wire [OUTPUT_REG_A:0] ena_s;

  wire [OUTPUT_REG_B:0] rstb_s;
  wire [OUTPUT_REG_B:0] enb_s;

  generate
    if (OUTPUT_REG_A == 0) begin : g_no_reg_a

      assign rsta_s = rsta;
      assign ena_s  = ena;

    end else begin : g_reg_a

      reg rsta_d;
      reg ena_d;

      always @(posedge clka) begin
        rsta_d <= rsta;
        ena_d  <= ena;
      end

      assign rsta_s = {rsta_d, rsta};
      assign ena_s  = {ena_d, ena};

    end
  endgenerate

  generate
    if (OUTPUT_REG_B == 0) begin : g_no_reg_b

      assign rstb_s = rstb;
      assign enb_s  = enb;

    end else begin : g_reg_b

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

  ram_tdp #(
      .ADDR_WIDTH  (ADDR_WIDTH),
      .DATA_WIDTH  (DATA_WIDTH),
      .WRITE_MODE_A(WRITE_MODE_A),
      .WRITE_MODE_B(WRITE_MODE_B),
      .OUTPUT_REG_A(OUTPUT_REG_A),
      .OUTPUT_REG_B(OUTPUT_REG_B),
      .INIT_WORD   (INIT_WORD),
      .INIT_FILE   (INIT_FILE),
      .RAM_STYLE   (RAM_STYLE)
  ) i_ram_tdp (
      // Port A
      .clka (clka),
      .rsta (rsta_s),
      .ena  (ena_s),
      .wea  (wea),
      .addra(addra),
      .dina (dina),
      .douta(douta),
      // Port B
      .clkb (clkb),
      .rstb (rstb_s),
      .enb  (enb_s),
      .web  (web),
      .addrb(addrb),
      .dinb (dinb),
      .doutb(doutb)
  );

endmodule

`default_nettype wire
