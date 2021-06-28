`timescale 1 ns / 1 ps `default_nettype none

module srs_adaptor_controller #(
    parameter int NUM_CC = 2
) (
    // XORIF
    //======
    input var         clk_400m,
    input var         rst_400m,
    // UL Timing
    input var  [11:0] s_ul_sym_num     [NUM_CC],
    input var         s_ul_update      [NUM_CC],
    // SRS Mux
    input var  [15:0] srs_mux_rtc_pc_id,
    input var  [ 3:0] srs_mux_cc,
    input var  [11:0] srs_mux_symbol,             // 0 ~ 559
    input var  [ 3:0] srs_mux_numsymbol,          // 1 ~ 3
    input var  [ 7:0] srs_mux_numprbc,            // 0 ~ 275
    input var  [ 9:0] srs_mux_startprbc,          // 0 ~ 275
    input var  [11:0] srs_mux_sectionid,
    input var  [ 3:0] srs_mux_ethport,            // 0 ~ 3
    input var         srs_mux_valid,
    // Framer
    output var [ 2:0] fram_req_eth_port,
    output var [63:0] fram_req_header,
    output var [ 8:0] fram_req_start_rb,
    output var [ 7:0] fram_req_num_rb,
    output var        fram_req_valid,
    input var         fram_req_ready,
    // DFE
    //====
    input var         clk_491m52,
    input var         rst_491m52,
    //
    input var         srs_valid,
    input var         srs_sop,
    input var         srs_eop,
    // SRS Request
    output var [ 3:0] srs_req_cc,
    output var [ 5:0] srs_req_layer,
    output var [11:0] srs_req_symbol,
    output var        srs_req_valid
);


  // SRS Message Buffer
  //===================

  // SRS messages are buffered in a block memory

  localparam int AddrWidth = 10;
  localparam int DataWidth = 71;

  logic [AddrWidth-1:0] wr_addr;
  logic                 wr_en;
  logic [DataWidth-1:0] wr_data;

  logic [AddrWidth-1:0] rd_addr;
  logic                 rd_en;
  logic                 rd_clr;
  logic [DataWidth-1:0] rd_data;


  logic [         15:0] srs_run_rtc_pc_id;
  logic [          3:0] srs_run_cc;
  logic [         11:0] srs_run_symbol;
  logic [          7:0] srs_run_numprbc;
  logic [          9:0] srs_run_startprbc;
  logic [         11:0] srs_run_sectionid;
  logic [          3:0] srs_run_ethport;
  logic                 srs_run_valid;
  logic                 srs_run_ready;


  assign wr_data = {
    1'b1,
    srs_mux_rtc_pc_id,
    srs_mux_cc,
    srs_mux_symbol,
    srs_mux_numsymbol,
    srs_mux_numprbc,
    srs_mux_startprbc,
    srs_mux_sectionid,
    srs_mux_ethport
  };

  assign wr_en = srs_mux_valid;

  always_ff @(posedge clk_400m) begin
    if (rst_400m) begin
      wr_addr <= 0;
    end else if (wr_en) begin
      wr_addr <= wr_addr + 1;
    end
  end

  srs_adaptor_controller_mem #(
      .ADDR_WIDTH(AddrWidth),
      .DATA_WIDTH(DataWidth)
  ) i_mem (
      .clk    (clk_400m),
      .rst    (rst_400m),
      //
      .wr_addr(wr_addr),
      .wr_en  (wr_en),
      .wr_data(wr_data),
      //
      .rd_addr(rd_addr),
      .rd_en  (rd_en),
      .rd_clr (rd_clr),
      .rd_data(rd_data)
  );


  srs_adaptor_controller_scheduler #(
      .ADDR_WIDTH(AddrWidth),
      .DATA_WIDTH(DataWidth),
      .NUM_CC    (NUM_CC)
  ) i_scheduler (
      // XORIF
      //======
      .clk              (clk_400m),
      .rst              (rst_400m),
      // UL Timing
      .s_ul_sym_num     (s_ul_sym_num),
      .s_ul_update      (s_ul_update),
      // SRS Filter
      .rd_addr          (rd_addr),
      .rd_en            (rd_en),
      .rd_clr           (rd_clr),
      .rd_data          (rd_data),
      // SRS Request
      .srs_run_rtc_pc_id(srs_run_rtc_pc_id),
      .srs_run_cc       (srs_run_cc),
      .srs_run_symbol   (srs_run_symbol),
      .srs_run_numprbc  (srs_run_numprbc),
      .srs_run_startprbc(srs_run_startprbc),
      .srs_run_sectionid(srs_run_sectionid),
      .srs_run_ethport  (srs_run_ethport),
      .srs_run_valid    (srs_run_valid),
      .srs_run_ready    (srs_run_ready)
  );


  srs_adaptor_controller_runner i_runner (
      // 400M
      //======
      .clk_400m         (clk_400m),
      .rst_400m         (rst_400m),
      // SRS Request
      .srs_run_rtc_pc_id(srs_run_rtc_pc_id),
      .srs_run_cc       (srs_run_cc),
      .srs_run_symbol   (srs_run_symbol),
      .srs_run_numprbc  (srs_run_numprbc),
      .srs_run_startprbc(srs_run_startprbc),
      .srs_run_sectionid(srs_run_sectionid),
      .srs_run_ethport  (srs_run_ethport),
      .srs_run_valid    (srs_run_valid),
      .srs_run_ready    (srs_run_ready),
      // Frame Request
      .fram_req_eth_port(fram_req_eth_port),
      .fram_req_header  (fram_req_header),
      .fram_req_start_rb(fram_req_start_rb),
      .fram_req_num_rb  (fram_req_num_rb),
      .fram_req_valid   (fram_req_valid),
      .fram_req_ready   (fram_req_ready),
      // DFE
      //====
      .clk_491m52       (clk_491m52),
      .rst_491m52       (rst_491m52),
      //
      .srs_valid        (srs_valid),
      .srs_sop          (srs_sop),
      .srs_eop          (srs_eop),
      // SRS Request
      .srs_req_cc       (srs_req_cc),
      .srs_req_layer    (srs_req_layer),
      .srs_req_symbol   (srs_req_symbol),
      .srs_req_valid    (srs_req_valid)
  );

endmodule

`default_nettype wire
