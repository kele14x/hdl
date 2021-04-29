// File: ul_adaptor_buf.sv
// Brief: Uplink PUxCH (UL U-Plane data) buffer
`timescale 1 ns / 1 ps `default_nettype none

module ul_adaptor_buf_data (
    input var         clk,
    input var         rst,
    //
    input var         wr_bank,
    input var  [12:0] wr_addr,
    input var         wr_en,
    input var  [31:0] wr_data,
    //
    input var         rd_bank,
    input var  [11:0] rd_addr,
    input var         rd_rden,
    output var [63:0] rd_data
);

  logic [63:0] ram_data_0;
  logic [63:0] ram_data_1;


  ul_adaptor_buf_uram i_ping (
      .clk    (clk),
      .rst    (rst),
      //
      .wr_addr(wr_addr),
      .wr_data(wr_data),
      .wr_en  (wr_en && wr_bank == 0),
      //
      .rd_addr(rd_addr),
      .rd_en  (rd_rden && rd_bank == 0),
      .rd_data(ram_data_0)
  );

  ul_adaptor_buf_uram i_pong (
      .clk    (clk),
      .rst    (rst),
      //
      .wr_addr(wr_addr),
      .wr_data(wr_data),
      .wr_en  (wr_en && wr_bank == 1),
      //
      .rd_addr(rd_addr),
      .rd_en  (rd_rden && rd_bank == 1),
      .rd_data(ram_data_1)
  );

endmodule

`default_nettype wire
