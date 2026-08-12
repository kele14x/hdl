`timescale 1 ns / 1 ps
//
`default_nettype none

module rts_cap_buffer #(
    parameter ADDR_WIDTH = 17,
    parameter DATA_WIDTH = 32
) (
    input var                   clka,
    input var                   clka_l,
    input var                   rsta,
    input var                   wea,
    input var  [ADDR_WIDTH-1:0] addra,
    input var  [DATA_WIDTH-1:0] dina,
    //
    input var                   clkb,
    input var                   rstb,
    input var                   enb,
    input var  [ADDR_WIDTH-1:0] addrb,
    output var [DATA_WIDTH-1:0] doutb
);

  logic                  cnt;

  logic                  ram_wea;
  logic [ADDR_WIDTH-1:0] ram_addra;
  logic [DATA_WIDTH-1:0] ram_dina;

  logic                  ram_wea_s;
  logic [ADDR_WIDTH-1:0] ram_addra_s;
  logic [DATA_WIDTH-1:0] ram_dina_s;


  always_ff @(posedge clka) begin
    if (rsta) begin
      ram_wea <= 1'b0;
    end else if (wea) begin
      ram_wea <= 1'b1;
    end else if (cnt == 0) begin
      ram_wea <= 1'b0;
    end
  end

  always_ff @(posedge clka) begin
    if (rsta) begin
      cnt <= 1'b0;
    end else if (wea) begin
      cnt <= 1'b1;
    end else if (cnt != 0) begin
      cnt <= cnt - 1'b1;
    end
  end

  always_ff @(posedge clka) begin
    if (wea) begin
      ram_addra <= addra;
      ram_dina  <= dina;
    end
  end

  always_ff @(posedge clka_l) begin
    ram_wea_s   <= ram_wea;
    ram_addra_s <= ram_addra;
    ram_dina_s  <= ram_dina;
  end

  // The RAM

  ram_sdp_pipe #(
      .ADDR_WIDTH  (ADDR_WIDTH),
      .DATA_WIDTH  (DATA_WIDTH),
      .READ_LATENCY(2),
      .INIT_FILE   ("NONE")
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
