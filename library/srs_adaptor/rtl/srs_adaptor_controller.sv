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
    // SRS Filter
    input var  [15:0] srs_rtc_pc_id,
    input var  [ 3:0] srs_cc,
    input var  [11:0] srs_symbol,  // 0 ~ 559
    input var  [ 3:0] srs_numsymbol,  // 1 ~ 3
    input var  [ 7:0] srs_numprbc,  // 0 ~ 275
    input var  [ 9:0] srs_startprbc,  // 0 ~ 275
    input var  [11:0] srs_sectionid,
    input var  [ 3:0] srs_ethport,  // 0 ~ 3
    input var         srs_valid,
    // Frame Request
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
    // SRS Request
    output var [ 3:0] srs_req_cc,
    output var [ 5:0] srs_req_layer,
    output var [11:0] srs_req_symbol,
    output var        srs_req_valid
);

  // Transparent Header (8-byte)
  //============================
  // XORIF specify eCPRI Common Header and first 4-byte eCPRI payload
  // as Transparent Header. XORIF will add this header, here just list for
  // reference.

  // eCPRI Common Header

  localparam [3:0] ecpri_common_header_protocol_reversion = 4'b0001;

  localparam [2:0] ecpri_common_header_reserved = 3'b000;

  localparam [0:0] ecpri_common_header_c_bit = 1'b0;
  // concatenation indicator (multi eCPRI message in one packet)

  localparam [7:0] ecpri_common_header_message_type = 8'h00;
  // 0: IQ;
  // 2: Real-Time Control Data;
  // 3: Generic Data Transfer;
  // Others refer to eCPRI specification

  localparam [15:0] ecpri_common_header_payload_size = 15'd0;
  // eCPRI payload size, not including header

  localparam [31:0] ecpri_common_header = {
    ecpri_common_header_protocol_reversion,
    ecpri_common_header_reserved,
    ecpri_common_header_c_bit,
    ecpri_common_header_message_type,
    ecpri_common_header_payload_size
  };

  // eCPRI Payload first 4-byte

  localparam [15:0] ecpri_rtc_pc_id = 16'h1;

  localparam [7:0] ecpri_sequence_id = 8'd0;

  localparam [0:0] ecpri_sequence_e_bit = 1'b0;

  localparam [6:0] ecpri_subsequence_id = 7'b0;

  localparam [15:0] ecpri_seq_id = {ecpri_sequence_id, ecpri_sequence_e_bit, ecpri_subsequence_id};

  localparam [63:0] oran_transport_header = {ecpri_common_header, ecpri_rtc_pc_id, ecpri_seq_id};

  // Application Header (8-byte)
  //============================

  localparam [0:0] oran_data_direction = 1'b0;
  // 0: UL; 1: DL;

  localparam [2:0] oran_payload_version = 3'd1;

  localparam [3:0] oran_filter_index = 4'd0;

  localparam [7:0] oran_frame_id = 8'd0;
  // Index of 10ms radio frame

  localparam [3:0] oran_sub_fram_id = 4'd0;

  localparam [5:0] oran_slot_id = 6'd0;

  localparam [5:0] oran_start_symbol_id = 6'd0;

  localparam [31:0] oran_application_header = {
    oran_data_direction,
    oran_payload_version,
    oran_filter_index,
    oran_frame_id,
    oran_sub_fram_id,
    oran_slot_id,
    oran_start_symbol_id
  };

  // Section Header
  //===============

  localparam [11:0] oran_section_id = 12'd2;
  localparam [ 0:0] oran_rb = 1'b0;
  localparam [ 0:0] oran_symbol_inc = 1'b0;
  localparam [ 9:0] oran_start_prbu = 10'd0;
  localparam [ 7:0] oran_number_prbu = 8'd0;

  localparam [31:0] oran_section_header = {
    oran_section_id, oran_rb, oran_symbol_inc, oran_start_prbu, oran_number_prbu
  };

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
  logic [DataWidth-1:0] rd_data;

  assign wr_data = {
    1'b1,
    srs_rtc_pc_id,
    srs_cc,
    srs_symbol,
    srs_numsymbol,
    srs_numprbc,
    srs_startprbc,
    srs_sectionid,
    srs_ethport
  };

  assign wr_en = srs_valid;

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
      .rd_data(rd_data)
  );


  srs_adaptor_controller_req #(
      .NUM_CC(NUM_CC)
  ) i_req (
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
      .rd_data          (rd_data),
      // SRS Request
      .srs_req_rtc_pc_id(srs_req_rtc_pc_id),
      .srs_req_cc       (srs_req_cc),
      .srs_req_symbol   (srs_req_symbol),
      .srs_req_numprbc  (srs_req_numprbc),
      .srs_req_startprbc(srs_req_startprbc),
      .srs_req_sectionid(srs_req_sectionid),
      .srs_req_ethport  (srs_req_ethport),
      .srs_req_valid    (srs_req_valid),
      .srs_req_ready    (srs_req_ready)
  );

endmodule

`default_nettype wire
