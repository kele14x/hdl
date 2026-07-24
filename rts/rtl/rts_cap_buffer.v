`timescale 1 ns / 1 ps
//
`default_nettype none

module rts_cap_buffer #(
    parameter ADDR_WIDTH = 17,
    parameter DATA_WIDTH = 32
) (
    input  wire                  clka,
    input  wire                  clka_l,
    input  wire                  rsta,
    input  wire                  wea,
    input  wire [ADDR_WIDTH-1:0] addra,
    input  wire [DATA_WIDTH-1:0] dina,
    //
    input  wire                  clkb,
    input  wire                  rstb,
    input  wire                  enb,
    input  wire [ADDR_WIDTH-1:0] addrb,
    output wire [DATA_WIDTH-1:0] doutb
);

  reg                  cnt;

  reg                  ram_wea;
  reg [ADDR_WIDTH-1:0] ram_addra;
  reg [DATA_WIDTH-1:0] ram_dina;

  reg                  ram_wea_s;
  reg [ADDR_WIDTH-1:0] ram_addra_s;
  reg [DATA_WIDTH-1:0] ram_dina_s;


  always @(posedge clka) begin
    if (wea) begin
      ram_wea <= 1'b1;
    end else if (cnt == 0) begin
      ram_wea <= 1'b0;
    end
  end

  always @(posedge clka) begin
    if (wea) begin
      cnt <= 1'b1;
    end else if (cnt != 0) begin
      cnt <= cnt - 1'b1;
    end
  end

  always @(posedge clka) begin
    if (wea) begin
      ram_addra <= addra;
      ram_dina  <= dina;
    end
  end

  always @(posedge clka_l) begin
    ram_wea_s   <= ram_wea;
    ram_addra_s <= ram_addra;
    ram_dina_s  <= ram_dina;
  end

  // The RAM

  ram_sdp_pipe #(
      .ADDR_WIDTH  (ADDR_WIDTH),
      .DATA_WIDTH  (DATA_WIDTH),
      .READ_LATENCY(2),
      .INIT_WORD   (0),
      .INIT_FILE   ("")
  ) i_cap_ram (
      // Port A
      .clka (clka_l),
      .ena  (1'b1),
      .wea  (ram_wea_s),
      .addra(ram_addra_s),
      .dina (ram_dina_s),
      // Port B
      .clkb (clkb),
      .rstb (rstb),
      .enb  (enb),
      .addrb(addrb),
      .doutb(doutb)
  );

endmodule

`default_nettype wire
