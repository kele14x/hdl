// Read latency is 5
`timescale 1 ns / 1 ps
//
`default_nettype none

module rts_ram_buffer (
    input  wire        clk,
    // Port A
    input  wire [19:0] addra,
    input  wire        ena,
    input  wire        wea,
    input  wire [31:0] dina,
    output wire [31:0] douta,
    // Port B
    input  wire [19:0] addrb,
    input  wire        enb,
    input  wire        web,
    input  wire [31:0] dinb,
    output wire [31:0] doutb
);

  parameter NumBlocks = 16;

  logic  [         14:0] mem_addra;
  logic                  mem_addra_lsb_d;
  logic                  mem_addra_lsb_dd;
  logic                  mem_addra_lsb_ddd;
  logic  [NumBlocks-1:0] mem_ena;
  logic  [NumBlocks-1:0] mem_ena_d;
  logic  [NumBlocks-1:0] mem_ena_dd;
  logic  [NumBlocks-1:0] mem_ena_ddd;
  logic  [          7:0] mem_wea           [0:NumBlocks-1];
  logic  [         63:0] mem_dina;
  wire [         63:0] mem_douta         [0:NumBlocks-1];
  logic  [         63:0] mem_douta_c;
  logic  [         31:0] mem_douta_d;

  logic  [         14:0] mem_addrb;
  logic                  mem_addrb_lsb_d;
  logic                  mem_addrb_lsb_dd;
  logic                  mem_addrb_lsb_ddd;
  logic  [NumBlocks-1:0] mem_enb;
  logic  [NumBlocks-1:0] mem_enb_d;
  logic  [NumBlocks-1:0] mem_enb_dd;
  logic  [NumBlocks-1:0] mem_enb_ddd;
  logic  [          7:0] mem_web           [0:NumBlocks-1];
  logic  [         63:0] mem_dinb;
  wire [         63:0] mem_doutb         [0:NumBlocks-1];
  logic  [         63:0] mem_doutb_c;
  logic  [         31:0] mem_doutb_d;

  // Port A

  always_ff @(posedge clk) begin
    mem_addra <= addra[15:1];
  end

  always_ff @(posedge clk) begin
    mem_addra_lsb_d   <= addra[0];
    mem_addra_lsb_dd  <= mem_addra_lsb_d;
    mem_addra_lsb_ddd <= mem_addra_lsb_dd;
  end

  always @(posedge clk) begin : p_ena
    integer i;
    for (i = 0; i < NumBlocks; i = i + 1) begin
      mem_ena[i] <= addra[19:16] == i[3:0] ? ena : 1'b0;
    end
  end

  always_ff @(posedge clk) begin
    mem_ena_d   <= mem_ena;
    mem_ena_dd  <= mem_ena_d;
    mem_ena_ddd <= mem_ena_dd;
  end

  always @(posedge clk) begin : p_wea
    integer i;
    for (i = 0; i < NumBlocks; i = i + 1) begin
      mem_wea[i] <= ((addra[19:16] == i[3:0]) && ena && wea) ? (addra[0] ? 8'b11110000 : 8'b00001111) : 8'b0;
    end
  end

  always_ff @(posedge clk) begin
    mem_dina <= {dina, dina};
  end

  always_comb begin : p_douta_c
    integer i;
    mem_douta_c = 'b0;
    for (i = 0; i < NumBlocks; i = i + 1) begin
      if (mem_ena_ddd[i]) begin
        mem_douta_c = mem_douta_c | mem_douta[i];
      end
    end
  end

  always_ff @(posedge clk) begin
    if (|mem_ena_ddd) begin
      mem_douta_d <= mem_addra_lsb_ddd ? mem_douta_c[63:32] : mem_douta_c[31:0];
    end
  end

  assign douta = mem_douta_d;

  // Port B

  always_ff @(posedge clk) begin
    mem_addrb <= addrb[15:1];
  end

  always_ff @(posedge clk) begin
    mem_addrb_lsb_d   <= addrb[0];
    mem_addrb_lsb_dd  <= mem_addrb_lsb_d;
    mem_addrb_lsb_ddd <= mem_addrb_lsb_dd;
  end

  always @(posedge clk) begin : p_enb
    integer i;
    for (i = 0; i < NumBlocks; i = i + 1) begin
      mem_enb[i] <= addrb[19:16] == i[3:0] ? enb : 1'b0;
    end
  end

  always_ff @(posedge clk) begin
    mem_enb_d   <= mem_enb;
    mem_enb_dd  <= mem_enb_d;
    mem_enb_ddd <= mem_enb_dd;
  end

  always @(posedge clk) begin : p_web
    integer i;
    for (i = 0; i < NumBlocks; i = i + 1) begin
      mem_web[i] <= ((addrb[19:16] == i[3:0]) && enb && web) ? (addrb[0] ? 8'b11110000 : 8'b00001111) : 8'b0;
    end
  end

  always_ff @(posedge clk) begin
    mem_dinb <= {dinb, dinb};
  end

  always_comb begin : p_doutb_c
    integer i;
    mem_doutb_c = 'b0;
    for (i = 0; i < NumBlocks; i = i + 1) begin
      if (mem_enb_ddd[i]) begin
        mem_doutb_c = mem_doutb_c | mem_doutb[i];
      end
    end
  end

  always_ff @(posedge clk) begin
    if (|mem_enb_ddd) begin
      mem_doutb_d <= mem_addrb_lsb_ddd ? mem_doutb_c[63:32] : mem_doutb_c[31:0];
    end
  end

  assign doutb = mem_doutb_d;

  generate
    genvar i;
    for (i = 0; i < NumBlocks; i = i + 1) begin : gen_block

      rts_ram_block #(
          .ADDR_WIDTH(15),
          .DATA_WIDTH(64)
      ) i_block (
          .clk  (clk),
          // Port A
          .rsta (1'b0),
          .addra(mem_addra),
          .ena  (mem_ena[i]),
          .wea  (mem_wea[i]),
          .dina (mem_dina),
          .douta(mem_douta[i]),
          // Port B
          .rstb (1'b0),
          .addrb(mem_addrb),
          .enb  (mem_enb[i]),
          .web  (mem_web[i]),
          .dinb (mem_dinb),
          .doutb(mem_doutb[i])
      );

    end
  endgenerate

endmodule

`default_nettype wire
