`timescale 1 ns / 1 ps `default_nettype none

module srs_adaptor (
  input var          clk_400m,
  input var          rst_400m,
  // Frame request
  input var          fram_req_start_rb,
  input var          fram_req_num_rb,
  input var          fram_req_cc,

  // UNSOL port
  output var [ 63:0] s00_fram_unsol_tdata,
  output var [  7:0] s00_fram_unsol_tkeep,
  output var         s00_fram_unsol_tvalid,
  output var         s00_fram_unsol_tlast,
  input var          s00_fram_unsol_tready,
  output var [ 31:0] s00_fram_unsol_tuser
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

    localparam [ 7:0] ecpri_sequence_id = 8'd0;

    localparam [ 0:0] ecpri_sequence_e_bit = 1'b0;

    localparam [ 6:0] ecpri_subsequence_id = 7'b0;

    localparam [15:0] ecpri_seq_id = {
        ecpri_sequence_id,
        ecpri_sequence_e_bit,
        ecpri_subsequence_id
    };

    localparam [63:0] oran_transport_header = {
        ecpri_common_header,
        ecpri_rtc_pc_id,
        ecpri_seq_id
    };

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
    localparam [0:0]  oran_rb = 1'b0;
    localparam [0:0]  oran_symbol_inc = 1'b0;
    localparam [9:0]  oran_start_prbu = 10'd0;
    localparam [7:0]  oran_number_prbu = 8'd0;

    localparam [31:0] oran_section_header = {
        oran_section_id,
        oran_rb,
        oran_symbol_inc,
        oran_start_prbu,
        oran_number_prbu
    };

endmodule

`default_nettype wire
