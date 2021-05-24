`timescale 1 ns / 1 ps `default_nettype none

module srs_adaptor_gearbox (
    // DFE
    //====
    input var         clk_491m52,
    input var         rst_491m52,
    //
    input var  [23:0] srs_data,  // {4'b exponent, 9'b mantissa Q, 9'b mantissa I}
    input var         srs_valid,
    input var         srs_eop,
    // XORIF
    //=======
    input var         clk_400m,
    input var         rst_400m,
    // Frame request
    input var  [ 2:0] fram_req_eth_port,
    input var  [63:0] fram_header,
    input var  [ 8:0] fram_req_start_rb,
    input var  [ 7:0] fram_req_num_rb,
    input var         fram_req_valid,
    output var        fram_req_ready,
    // UNSOL port
    output var [63:0] m_fram_unsol_tdata,
    output var [ 7:0] m_fram_unsol_tkeep,
    output var        m_fram_unsol_tvalid,
    output var        m_fram_unsol_tlast,
    input var         m_fram_unsol_tready,
    output var [31:0] m_fram_unsol_tuser
);

  logic [11:0] wr_addr;
  logic        wr_en;
  logic [23:0] wr_data;

  logic [ 9:0] rd_addr;
  logic        rd_rden;
  logic [95:0] rd_data;


  srs_adaptor_writer i_srs_adaptor_writer (
      // DFE
      //====
      .clk      (clk_491m52),
      .rst      (rst_491m52),
      //
      .srs_data (srs_data),  // {4'b exponent, 9'b mantissa Q, 9'b mantissa I}
      .srs_valid(srs_valid),
      .srs_eop  (srs_eop),
      //
      .wr_addr  (wr_addr),
      .wr_en    (wr_en),
      .wr_data  (wr_data)
  );

  srs_adaptor_bram i_srs_adaptor_bram (
      // Write port
      .clka (clk_491m52),
      .addra(wr_addr),  // 0 ~ 4096
      .ena  (wr_en),
      .wea  (wr_en),  // 1 RE
      .dina (wr_data),
      // Read port
      .clkb (clk_400m),
      .rstb (rst_400m),
      .addrb(rd_addr),  // 0 ~ 1024
      .enb  (rd_rden),  // !connect to all registers in output pipe
      .doutb(rd_data)
  );

  srs_adaptor_framer i_srs_adaptor_framer (
      .clk                (clk_400m),
      .rst                (rst_400m),
      // Frame Request
      //==============
      .fram_req_eth_port  (fram_req_eth_port),
      .fram_header        (fram_header),
      .fram_req_start_rb  (fram_req_start_rb),
      .fram_req_num_rb    (fram_req_num_rb),
      .fram_req_valid     (fram_req_valid),
      .fram_req_ready     (fram_req_ready),
      // BRAM
      //=====
      // Latency = 3
      .bram_addr          (rd_addr),  // 0 ~ 1024
      .bram_rden          (rd_rden),  // !connect to all registers in output pipe
      .bram_data          (rd_data),  // 4 RE
      // UNSOL port
      //===========
      .m_fram_unsol_tdata (m_fram_unsol_tdata),
      .m_fram_unsol_tkeep (m_fram_unsol_tkeep),
      .m_fram_unsol_tvalid(m_fram_unsol_tvalid),
      .m_fram_unsol_tlast (m_fram_unsol_tlast),
      .m_fram_unsol_tready(m_fram_unsol_tready),
      .m_fram_unsol_tuser (m_fram_unsol_tuser)
  );

endmodule

`default_nettype wire
