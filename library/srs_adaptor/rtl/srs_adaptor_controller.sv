`timescale 1 ns / 1 ps `default_nettype none

module srs_adaptor_controller #(
    parameter int NUM_ETH_PORT = 2,
    parameter int NUM_CC = 2
) (
    // XORIF
    //======
    input var         clk_400m,
    input var         rst_400m,
    // UL Timing
    input var  [11:0] s_ul_sym_num     [      NUM_CC],
    input var         s_ul_update      [      NUM_CC],
    // SRS Filter
    input var         srs_valid        [NUM_ETH_PORT],
    input var  [15:0] srs_rtc_pc_id    [NUM_ETH_PORT],
    input var  [ 3:0] srs_cc           [NUM_ETH_PORT],
    input var  [ 3:0] srs_subframeid   [NUM_ETH_PORT],
    input var  [ 5:0] srs_slotid       [NUM_ETH_PORT],
    input var  [ 7:0] srs_symbolid     [NUM_ETH_PORT],
    input var  [ 3:0] srs_numsymbol    [NUM_ETH_PORT],
    input var  [ 7:0] srs_numprbc      [NUM_ETH_PORT],
    input var  [ 9:0] srs_startprbc    [NUM_ETH_PORT],
    input var  [11:0] srs_sectionid    [NUM_ETH_PORT],
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
    // SRS Configuration Forward
    output var [ 3:0] srs_cfg_cc,
    output var [11:0] srs_cfg_symbol,
    output var [ 3:0] srs_cfg_numsymbol,
    output var        srs_cfg_valid,
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


  // SRS C-Plane message CDC to clk_491m52
  //======================================

  logic [ 3:0] srs_cfg_cached_cc       [NUM_ETH_PORT];
  logic [11:0] srs_cfg_cached_symbol   [NUM_ETH_PORT];
  logic [ 3:0] srs_cfg_cached_numsymbol[NUM_ETH_PORT];
  logic        srs_cfg_cached_send     [NUM_ETH_PORT];
  logic        srs_cfg_cached_rcv      [NUM_ETH_PORT];
  //
  logic [ 3:0] srs_cfg_synced_cc       [NUM_ETH_PORT];
  logic [11:0] srs_cfg_synced_symbol   [NUM_ETH_PORT];
  logic [ 3:0] srs_cfg_synced_numsymbol[NUM_ETH_PORT];
  logic        srs_cfg_synced_req      [NUM_ETH_PORT];
  logic        srs_cfg_synced_ack      [NUM_ETH_PORT];


  // Put all data into a CDC handshake buffer, assume the incoming SRS message
  // will not come too offen, so we have enough time to forward it to next
  // block. The only issue is 2 (or 4) Ethernet port may assign valid at the
  // same time. In this case, we need to ACK to them one by one.

  generate
    for(genvar i = 0; i < NUM_ETH_PORT; i++) begin: g_cdc

      always_ff @(posedge clk_400m) begin
        if (rst_400m) begin
          srs_cfg_cached_send[i] <= 1'b0;
        end else if (srs_valid[i]) begin
          srs_cfg_cached_send[i] <= 1'b1;
        end else if (srs_cfg_cached_rcv[i]) begin
          srs_cfg_cached_send[i] <= 1'b0;
        end
      end

      always_ff @(posedge clk_400m) begin
        if (srs_valid[i] && (~srs_cfg_cached_send[i] || srs_cfg_cached_rcv[i])) begin
          srs_cfg_cached_cc[i]        <= srs_cc[i];
          srs_cfg_cached_symbol[i]    <= (srs_subframeid[i] * 10 + srs_slotid[i] * 14 + srs_symbolid[i]);
          srs_cfg_cached_numsymbol[i] <= srs_numsymbol[i];
        end
      end

      xpm_cdc_handshake #(
          .DEST_EXT_HSK  (1),
          .DEST_SYNC_FF  (2),
          .INIT_SYNC_FF  (0),
          .SIM_ASSERT_CHK(0),
          .SRC_SYNC_FF   (2),
          .WIDTH         (20)
      ) xpm_cdc_handshake_inst (
          .src_clk (clk_400m),
          .src_in  ({srs_cfg_cached_cc[i], srs_cfg_cached_symbol[i], srs_cfg_cached_numsymbol[i]}),
          .src_send(srs_cfg_cached_send[i]),
          .src_rcv (srs_cfg_cached_rcv[i]),
          //
          .dest_clk(clk_491m52),
          .dest_out({srs_cfg_synced_cc[i], srs_cfg_synced_symbol[i], srs_cfg_synced_numsymbol[i]}),
          .dest_req(srs_cfg_synced_req[i]),
          .dest_ack(srs_cfg_synced_ack[i])
      );
    end
  endgenerate


  always_ff @ (posedge clk_491m52) begin
    for(int i = 0; i < NUM_ETH_PORT; i++) begin
      if (srs_cfg_synced_req[i] && ~srs_cfg_synced_ack[i]) begin
        {srs_cfg_cc, srs_cfg_symbol, srs_cfg_numsymbol} <= {srs_cfg_synced_cc[i], srs_cfg_synced_symbol[i], srs_cfg_synced_numsymbol[i]};
        break;
      end
    end
  end

  always_ff @ (posedge clk_491m52) begin
    srs_cfg_valid <= 1'b0;
    for(int i = 0; i < NUM_ETH_PORT; i++) begin
      if (srs_cfg_synced_req[i] && ~srs_cfg_synced_ack[i]) begin
        srs_cfg_valid <= 1'b1;
        break;
      end
    end
  end

  generate
    for (genvar e = 0; e < NUM_ETH_PORT; e++) begin

      // First channel first arbiter
      always_ff @ (posedge clk_491m52) begin
        if (rst_491m52) begin
          srs_cfg_synced_ack[e] <= 1'b0;
        end else if (srs_cfg_synced_ack[e] == 1'b0) begin
        
          // this channel is free, it can reqesonse to request, but it need to
          // check whether previous channel will accet a request
          srs_cfg_synced_ack[e] <= 1'b0;
          for (int i = 0; i <= e; i++) begin
            if (srs_cfg_synced_req[i] && ~srs_cfg_synced_ack[i]) begin
              srs_cfg_synced_ack[e] <= (e == i);
              break;
            end
          end

        end else begin // srs_cfg_synced_ack[e] == 1'b1
          // this channel already assert ack, seems Xilinx CDC Handshake 
          // requries we assert this high until ack is deassert
          srs_cfg_synced_ack[e] <= srs_cfg_synced_req[e];
        end
      end

    end
  endgenerate

endmodule

`default_nettype wire
