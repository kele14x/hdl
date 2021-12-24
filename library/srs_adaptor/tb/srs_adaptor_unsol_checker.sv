// file: srs_adaptor_unsol_checker.sv
// brief: s_fram_unsol_t* interface checker
`timescale 1 ns / 1 ps `default_nettype none

module srs_adaptor_unsol_checker (
    // XORIF Clock & Reset
    input var        clk,
    input var        rst,
    // UNSOL Port
    input var [63:0] s_fram_unsol_tdata,
    input var [ 7:0] s_fram_unsol_tkeep,
    input var        s_fram_unsol_tvalid,
    input var        s_fram_unsol_tlast,
    input var        s_fram_unsol_tready,
    input var [31:0] s_fram_unsol_tuser
);

  typedef enum int {
    S_RST,   // under reset
    S_IDLE,  // wait for first word
    S_CHK    // wait left words
  } state_t;

  state_t state;

  logic [63:0] tdata;

  // TUSER signal
  logic [15:0] oran_rtc_pc_id;
  logic [2:0] oran_eth_port;
  logic [12:0] oran_packet_length;

  // Application header
  logic [31:0] oran_application_header;
  //
  logic [0:0] oran_data_direction;  // 0: UL; 1: DL;
  logic [2:0] oran_payload_version;
  logic [3:0] oran_filter_index;
  logic [7:0] oran_frame_id;
  logic [3:0] oran_subframe_id;
  logic [5:0] oran_slot_id;
  logic [5:0] oran_start_symbol_id;

  // Section header
  logic [31:0] oran_section_header;
  //
  logic [11:0] oran_section_id;
  logic [0:0] oran_rb;
  logic [0:0] oran_symbol_inc;
  logic [9:0] oran_start_prb;
  logic [7:0] oran_number_prb;

  logic [447:0] rb_data;
  int rb_cnt, re_pair_cnt;

  function automatic [63:0] byte_reverse(input logic [63:0] data);
    return {
      data[7:0],
      data[15:8],
      data[23:16],
      data[31:24],
      data[39:32],
      data[47:40],
      data[55:48],
      data[63:56]
    };
  endfunction


  assign tdata = byte_reverse(s_fram_unsol_tdata);
  assign {oran_rtc_pc_id, oran_eth_port, oran_packet_length} = s_fram_unsol_tuser;
  assign {oran_application_header, oran_section_header} = tdata;
  assign {
    oran_data_direction,
    oran_payload_version,
    oran_filter_index,
    oran_frame_id,
    oran_subframe_id,
    oran_slot_id,
    oran_start_symbol_id
  } = oran_application_header;
  assign {
    oran_section_id, oran_rb, oran_symbol_inc, oran_start_prb, oran_number_prb
  } = oran_section_header;

  always_ff @(posedge clk) begin
    if (rst) begin
      state <= S_RST;
    end else begin
      case (state)
        S_RST: begin
          state <= S_IDLE;
        end
        S_IDLE: begin
          if (s_fram_unsol_tvalid) begin
            $display("\nOne UNSOL frame received");
            state <= S_CHK;
            rb_cnt <= oran_start_prb;
            re_pair_cnt <= 0;

            // TUSER information
            $display("  TUSER = 0x%h ", s_fram_unsol_tuser, "(eAxC ID = 0x%h, ", oran_rtc_pc_id,
                     "Ethernet port = %d, ", oran_eth_port, "Incoming packet length = %d)",
                     oran_packet_length);

            // Header information
            $display("  Header = 0x%h ", tdata);
            $display("    Application header = 0x%h ", oran_application_header,
                     "(Data direction = %d, ", oran_data_direction, "Payload version = %d, ",
                     oran_payload_version, "Filter index = 0b%b, ", oran_filter_index,
                     "Frame ID = %d, ", oran_frame_id, "Subframe ID = %d, ", oran_subframe_id,
                     "Slot ID = %d, ", oran_slot_id, "Start Symbol ID = %d)", oran_start_symbol_id);
            $display("    Section header = 0x%h ", oran_section_header, "(Section ID = %d, ",
                     oran_section_id, "RB = %d, ", oran_rb, "SymInc = %d, ", oran_symbol_inc,
                     "Start PRB = %d, ", oran_start_prb, "Number PRB = %d)", oran_number_prb);

          end
        end
        S_CHK: begin

          if (s_fram_unsol_tvalid) begin
            rb_data[447-64*re_pair_cnt-:64] = tdata;
            if (re_pair_cnt == 3) begin
              $display("  RB #%d", rb_cnt);
              $display("    exp = %d", rb_data[443:440]);
              for (int i = 0; i < 12; i++) begin
                $display("    #%d: ", i, "I = %d, ", $signed(rb_data[439-i*18-:9]), "Q = %d",
                         $signed(rb_data[430-i*18-:9]));
              end
            end else if (re_pair_cnt == 6) begin
              $display("  RB #%d", rb_cnt + 1);
              $display("    exp = %d", rb_data[219:216]);
              for (int i = 0; i < 12; i++) begin
                $display("    #%d: ", i, "I = %d, ", $signed(rb_data[215-i*18-:9]), "Q = %d",
                         $signed(rb_data[206-i*18-:9]));
              end
            end

            if (re_pair_cnt == 6) begin
              rb_cnt <= (rb_cnt + 2);
            end
            re_pair_cnt <= (re_pair_cnt + 1) % 7;
          end

          if (s_fram_unsol_tvalid && s_fram_unsol_tlast) begin
            $display("UNSOL frame finished\n");
            state <= S_IDLE;
          end

        end
        default: state <= S_RST;
      endcase
    end
  end

  assign s_fram_unsol_tready = (state == S_IDLE) || (state == S_CHK);

endmodule

`default_nettype wire
