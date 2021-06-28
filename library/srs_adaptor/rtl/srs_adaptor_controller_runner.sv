// file: srs_adaptor_controller_req.sv
// brief: Forward necessary SRS C-Plane message to next module as SRS
//        configuration.
`timescale 1 ns / 1 ps `default_nettype none

module srs_adaptor_controller_runner (
    // 400M
    //======
    input var         clk_400m,
    input var         rst_400m,
    // SRS Request
    input var  [15:0] srs_run_rtc_pc_id,
    input var  [ 3:0] srs_run_cc,
    input var  [11:0] srs_run_symbol,
    input var  [ 7:0] srs_run_numprbc,
    input var  [ 9:0] srs_run_startprbc,
    input var  [11:0] srs_run_sectionid,
    input var  [ 3:0] srs_run_ethport,
    input var         srs_run_valid,
    output var        srs_run_ready,
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
  localparam [0:0] oran_rb = 1'b0;
  localparam [0:0] oran_symbol_inc = 1'b0;
  localparam [9:0] oran_start_prbu = 10'd0;
  localparam [7:0] oran_number_prbu = 8'd0;

  localparam [31:0] oran_section_header = {
    oran_section_id, oran_rb, oran_symbol_inc, oran_start_prbu, oran_number_prbu
  };


  //===================================

  // Let do a single thread state machine first
  typedef enum int {
    S_IDLE,  // Nothing doing
    S_REQ,   // Send request to DFE, wait CDC done
    S_DATA,  // Wait data transfer done
    S_FRAM   // Send frame request to framer, wait framer done
  } state_t;

  state_t state, state_next;

  logic [21:0] srs_req_in;
  logic        srs_req_send;
  logic        srs_req_rcv;

  logic [31:0] application_header;
  logic [31:0] section_header;


  // FSM
  //====

  always_ff @(posedge clk_400m) begin
    if (rst_400m) begin
      state <= S_IDLE;
    end else begin
      state <= state_next;
    end
  end

  always_comb begin
    case (state)
      S_IDLE: state_next = srs_run_valid ? S_REQ : S_IDLE;
      S_REQ:  state_next = srs_req_rcv ? S_DATA : S_REQ;
      S_DATA: state_next = (srs_valid && srs_eop) ? S_FRAM : S_DATA;
      S_FRAM: state_next = fram_req_ready ? S_IDLE : S_FRAM;
    endcase
  end

  // Requst data from DFE
  //=====================

  always_ff @(posedge clk_400m) begin
    if (state == S_IDLE && srs_run_valid) begin
      srs_req_in <= {srs_run_cc, srs_run_rtc_pc_id[5:0], srs_run_symbol};
    end
  end

  always_ff @(posedge clk_400m) begin
    srs_req_send <= (state_next == S_REQ);
  end

  xpm_cdc_handshake #(
      .DEST_EXT_HSK  (0),
      .DEST_SYNC_FF  (2),
      .INIT_SYNC_FF  (0),
      .SIM_ASSERT_CHK(0),
      .SRC_SYNC_FF   (2),
      .WIDTH         (22)
  ) xpm_cdc_handshake_inst (
      .src_clk (clk_400m),
      .src_in  (srs_req_in),
      .src_send(srs_req_send),
      .src_rcv (srs_req_rcv),
      //
      .dest_clk(clk_491m52),
      .dest_out({srs_req_cc, srs_req_layer, srs_req_symbol}),
      .dest_req(srs_req_valid),
      .dest_ack(  /* Not used */)
  );


  // Wait framer done
  //=================

  assign application_header = {
    oran_data_direction,
    oran_payload_version,
    oran_filter_index,
    oran_frame_id,
    oran_sub_fram_id,
    oran_slot_id,
    oran_start_symbol_id
  };

  assign section_header = {
    oran_section_id, oran_rb, oran_symbol_inc, oran_start_prbu, oran_number_prbu
  };

  always_ff @(posedge clk_400m) begin
    fram_req_valid <= (state_next == S_FRAM);
  end

  always_ff @(posedge clk_400m) begin
    if (state == S_IDLE && srs_run_valid) begin
      fram_req_eth_port <= srs_run_ethport;
      fram_req_header   <= {application_header, section_header};
      fram_req_start_rb <= srs_run_startprbc;
      fram_req_num_rb   <= srs_run_numprbc;
    end
  end

endmodule

`default_nettype wire
