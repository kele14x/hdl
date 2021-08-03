`timescale 1ps / 1ps `default_nettype none
module fifo_fwft #(
    parameter int DATA_WIDTH = 18,
    parameter int DATA_DEPTH = 1024
) (
    input var                   arst,
    //
    input var                   wr_clk,
    input var  [DATA_WIDTH-1:0] wr_data,
    input var                   wr_en,
    output var                  wr_full,
    //
    input var                   rd_clk,
    input var  [DATA_WIDTH-1:0] rd_data,
    input var                   rd_en,
    output var                  rd_empty
);

  localparam AddrWidth = $clog2(DATA_DEPTH);

  // Writer clock domain
  
  logic wr_rst;

  logic [   AddrWidth:0] wr_cnt;
  logic [DATA_WIDTH-1:0] wr_addr;
  
  // Reader clock domain
  
  logic rd_rst;

  logic [   AddrWidth:0] rd_cnt;
  logic [DATA_WIDTH-1:0] rd_addr;

  // BRAM Signal
  
  logic                   clka;
  logic                   rsta;
  logic                   ena;
  logic                   wea;
  logic  [AddrWidth-1:0]  addra;
  logic  [DATA_WIDTH-1:0] dina;
  
  logic                   clkb;
  logic                   rstb;
  logic                   enb;
  logic  [ AddrWidth-1:0] addrb;
  logic  [DATA_WIDTH-1:0] doutb;

  cdc_sync_rst_sync #(
    .SYNC_FF(2)
  ) i_sync (
    .arst_in(arst),
    .rst_out(wr_rst)
  );

  always_ff @(posedge wr_clk) begin
    if (wr_rst) begin
      wr_cnt <= '0;
    end else if (wr_en && ~wr_full) begin
      wr_cnt <= wr_cnt + 1;
    end
  end


  // BRAM
  //=====
  
  assign clka  = wr_clk;
  assign ena   = wr_en && ~wr_full;
  assign wea   = wr_en && ~wr_full;
  assign addra = wr_addr;
  assign dina  = wr_data;
  
  assign clkb  = rd_clk;
  assign rstb  = rd_rst;
  assign enb   = rd_en;
  assign addrb = rd_addr;

  bram_sdp #(
    .ADDR_WIDTH(AddrWidth),
    .DATA_WIDTH(DATA_WIDTH),
    .USE_OUTPUT_REG(1)
  ) i_bram_sdp (
    //
    .clka(clka),
    .ena (ena),
    .wea (wea),
    .addra(addra),
    .dina(dina),
    //
    .clkb(clkb),
    .rstb(rstb),
    .enb(enb),
    .addrb(addrb),
    .doutb(doutb)
  );

endmodule

`default_nettype wire
