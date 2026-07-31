`timescale 1ns / 1ps
//
`default_nettype none

module rts2_playback_parser (
    // Timer
    input  wire         clk,
    input  wire         rst,
    //
    input  wire         sync_in,
    // DDR DataMover
    input  wire         ddr4_clk,
    input  wire         ddr4_rst,
    //
    input  wire  [63:0] s_axis_tdata,
    input  wire  [ 7:0] s_axis_tkeep,
    input  wire         s_axis_tlast,
    input  wire         s_axis_tvalid,
    output wire         s_axis_tready,
    //
    output logic [63:0] m_axis_tdata,
    output logic [ 7:0] m_axis_tkeep,
    output logic        m_axis_tlast,
    output logic        m_axis_tvalid,
    // CSR
    input  wire         ctrl_en
);

  // Parameters

  localparam integer S_RST = 0;
  localparam integer S_IDLE = 1;

  localparam integer S_FHEADER0 = 2;
  localparam integer S_FHEADER1 = 3;
  localparam integer S_FHEADER2 = 4;

  localparam integer S_RHEADER0 = 5;
  localparam integer S_RHEADER1 = 6;

  localparam integer S_WAIT = 7;
  localparam integer S_DATA = 8;

  // Byte reverse a 64-bit word, which is suitable for the Ethernet packet
  function [63:0] byte_reverse64;
    input [63:0] data;
    integer i;
    begin
      for (i = 0; i < 8; i = i + 1) begin
        byte_reverse64[i*8+7-:8] = data[63-i*8-:8];
      end
    end
  endfunction

  // Byte reverse a 32-bit word, which is suitable for Timestamp & Length
  function [31:0] byte_reverse32;
    input [31:0] data;
    integer i;
    begin
      for (i = 0; i < 4; i = i + 1) begin
        byte_reverse32[i*8+7-:8] = data[31-i*8-:8];
      end
    end
  endfunction

  // Signals

  wire ctrl_en_s;

  logic sync_in_d;
  logic sync_in_dd;
  wire sync_in_posedge;

  wire [63:0] s_axis_tdata_rev;
  logic [55:0] s_axis_tdata_reg;
  logic [63:0] s_axis_tdata_shift;
  logic [63:0] s_axis_tdata_shift2;

  // Parser status register
  logic [31:0] length_counter;

  wire [2:0] shift;
  wire [2:0] shift_next;

  wire tlast_pre;
  wire tlast_inphase;
  wire tlast_extra;

  logic [63:0] extra_tdata;
  logic [2:0] extra_tkeep;
  logic extra_tlast;

  wire [31:0] record_length;
  wire record_length_valid;
  logic [31:0] record_length_reg;

  wire signed [31:0] record_timestamp;
  wire record_timestamp_valid;
  logic signed [31:0] record_timestamp_reg;
  logic record_timestamp_odd;

  logic [13:0] record_timestamp_wrapped;
  logic record_timestamp_wrapped_swap;
  logic record_timestamp_wrapped_odd;

  logic [8:0] timestamp_counter_lsb;
  logic [13:0] timestamp_counter;
  logic timestamp_counter_odd;
  logic timestamp_counter_valid;

  wire [13:0] timestamp_counter_cdc;
  wire timestamp_counter_cdc_odd;
  wire timestamp_counter_cdc_valid;

  wire [31:0] shift_next_full;
  wire signed [31:0] record_timestamp_plus;
  wire signed [31:0] record_timestamp_minus;
  wire timestamp_counter_src_ready;
  wire unused_axis_inputs = &{1'b0, s_axis_tkeep, shift_next_full[31:3], record_timestamp_plus[31:14], record_timestamp_minus[31:14], timestamp_counter_src_ready, 1'b0};

  integer state, state_next;

  // Main

  // CDC for control signals

  cdc_array_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (1'b0),
      .SRC_INPUT_REG(1'b0),
      .WIDTH        (1)
  ) u_ctrl_en_cdc (
      .src_clk (1'b1),
      .src_in  (ctrl_en),
      //
      .dest_clk(ddr4_clk),
      .dest_out(ctrl_en_s)
  );

  // FSM

  always_ff @(posedge ddr4_clk) begin
    if (ddr4_rst) begin
      state <= S_RST;
    end else begin
      state <= state_next;
    end
  end

  always_comb begin
    state_next = state;

    case (state)
      S_RST: begin
        state_next = S_IDLE;
      end

      S_IDLE: begin
        // When this module is not enable, it will discard all input so it
        // will not blocking the DataMover
        if (ctrl_en_s) begin
          state_next = S_FHEADER0;
        end
      end

      S_FHEADER0: begin
        // We know that `s_axis_tready` is assert at this state
        if (!ctrl_en_s) begin
          state_next = S_IDLE;
        end else if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_FHEADER0;
        end else if (s_axis_tvalid) begin
          state_next = S_FHEADER1;
        end
      end

      S_FHEADER1: begin
        if (!ctrl_en_s) begin
          state_next = S_IDLE;
        end else if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_FHEADER0;
        end else if (s_axis_tvalid) begin
          state_next = S_FHEADER2;
        end
      end

      S_FHEADER2: begin
        if (!ctrl_en_s) begin
          state_next = S_IDLE;
        end else if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_FHEADER0;
        end else if (s_axis_tvalid) begin
          state_next = S_RHEADER0;
        end
      end

      S_RHEADER0: begin
        if (!ctrl_en_s) begin
          state_next = S_IDLE;
        end else if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_FHEADER0;
        end else if (s_axis_tvalid) begin
          state_next = S_RHEADER1;
        end
      end

      S_RHEADER1: begin
        if (!ctrl_en_s) begin
          state_next = S_IDLE;
        end else if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_FHEADER0;
        end else if (s_axis_tvalid) begin
          state_next = S_WAIT;
        end
      end

      S_WAIT: begin
        if (!ctrl_en_s) begin
          state_next = S_IDLE;
        end else if (timestamp_counter_cdc_valid &&
                    ((timestamp_counter_cdc >= record_timestamp_wrapped) ^
                      timestamp_counter_cdc_odd ^ record_timestamp_wrapped_odd ^ record_timestamp_wrapped_swap)) begin
          // We wait until the timestamp counter reaches the record timestamp
          state_next = S_DATA;
        end
      end

      S_DATA: begin
        if (!ctrl_en_s) begin
          // Early terminal the packet
          state_next = S_IDLE;
        end else if (s_axis_tvalid && s_axis_tlast) begin
          state_next = S_FHEADER0;
        end else if (s_axis_tvalid) begin
          if (length_counter + 32'd8 >= record_length_reg) begin
            state_next = S_RHEADER0;
          end else begin
            state_next = S_DATA;
          end
        end
      end

      default: begin
        state_next = S_RST;
      end
    endcase
  end

  assign s_axis_tdata_rev = byte_reverse64(s_axis_tdata);

  always_ff @(posedge ddr4_clk) begin
    if (s_axis_tvalid && s_axis_tready) begin
      s_axis_tdata_reg <= s_axis_tdata_rev[55:0];
    end
  end

  // `shift` marks how many bytes is there at the tail of `s_axis_tdata_reg`
  //
  // | s_axis_tdata_reg | s_axis_tdata_rev | < 8 - shift  > |
  //              | s_axis_data_shift | s_axis_tdata_shift2 |

  always_comb begin
    case (shift)
      3'b000:  s_axis_tdata_shift = s_axis_tdata_rev;
      3'b001:  s_axis_tdata_shift = {s_axis_tdata_reg[7:0], s_axis_tdata_rev[63:8]};
      3'b010:  s_axis_tdata_shift = {s_axis_tdata_reg[15:0], s_axis_tdata_rev[63:16]};
      3'b011:  s_axis_tdata_shift = {s_axis_tdata_reg[23:0], s_axis_tdata_rev[63:24]};
      3'b100:  s_axis_tdata_shift = {s_axis_tdata_reg[31:0], s_axis_tdata_rev[63:32]};
      3'b101:  s_axis_tdata_shift = {s_axis_tdata_reg[39:0], s_axis_tdata_rev[63:40]};
      3'b110:  s_axis_tdata_shift = {s_axis_tdata_reg[47:0], s_axis_tdata_rev[63:48]};
      3'b111:  s_axis_tdata_shift = {s_axis_tdata_reg[55:0], s_axis_tdata_rev[63:56]};
      default: s_axis_tdata_shift = s_axis_tdata_rev;
    endcase
  end

  always_comb begin
    case (shift)
      3'b000:  s_axis_tdata_shift2 = 'd0;
      3'b001:  s_axis_tdata_shift2 = {s_axis_tdata_rev[7:0], 56'b0};
      3'b010:  s_axis_tdata_shift2 = {s_axis_tdata_rev[15:0], 48'b0};
      3'b011:  s_axis_tdata_shift2 = {s_axis_tdata_rev[23:0], 40'b0};
      3'b100:  s_axis_tdata_shift2 = {s_axis_tdata_rev[31:0], 32'b0};
      3'b101:  s_axis_tdata_shift2 = {s_axis_tdata_rev[39:0], 24'b0};
      3'b110:  s_axis_tdata_shift2 = {s_axis_tdata_rev[47:0], 16'b0};
      3'b111:  s_axis_tdata_shift2 = {s_axis_tdata_rev[55:0], 8'b0};
      default: s_axis_tdata_shift2 = 'd0;
    endcase
  end

  assign s_axis_tready = (state == S_IDLE ||
                          state == S_FHEADER0 || state == S_FHEADER1 || state == S_FHEADER2 ||
                          state == S_RHEADER0 || state == S_RHEADER1 ||
                          state == S_DATA);

  // Record length (Captured Packet Length) field is at Record Header 1

  assign record_length_valid = (state == S_RHEADER1 && s_axis_tvalid);

  assign record_length = byte_reverse32(s_axis_tdata_shift[63:32]);

  always_ff @(posedge ddr4_clk) begin
    if (ddr4_rst) begin
      record_length_reg <= 32'd0;
    end else if (s_axis_tvalid && s_axis_tready && s_axis_tlast) begin
      record_length_reg <= 32'd0;
    end else if (record_length_valid) begin
      record_length_reg <= record_length;
    end
  end

  // Local length counter

  always_ff @(posedge ddr4_clk) begin
    if (ddr4_rst) begin
      length_counter <= 32'd0;
    end else if (s_axis_tvalid && s_axis_tready && s_axis_tlast) begin
      length_counter <= 32'd0;
    end else if ((state == S_DATA) && s_axis_tvalid && tlast_pre) begin
      // We have received the last word of record
      length_counter <= (length_counter + 32'd8 - record_length_reg) & 32'h7;
    end else if (state == S_DATA && s_axis_tvalid) begin
      length_counter <= length_counter + 32'd8;
    end
  end

  assign shift                  = length_counter[2:0];

  assign shift_next_full        = length_counter + 32'd8 - record_length_reg;
  assign shift_next             = shift_next_full[2:0];

  // Record timestamp (Microseconds) field is at Record Header 0

  assign record_timestamp_valid = (state == S_RHEADER0 && s_axis_tvalid);

  // This is timestamp (Microseconds) field
  assign record_timestamp       = byte_reverse32(s_axis_tdata_shift[31:0]);

  always_ff @(posedge ddr4_clk) begin
    if (ddr4_rst) begin
      record_timestamp_reg <= 32'd0;
    end else if (record_timestamp_valid) begin
      record_timestamp_reg <= record_timestamp;
    end
  end

  // We also need an even/odd frame counter
  always_ff @(posedge ddr4_clk) begin
    if (ddr4_rst) begin
      record_timestamp_odd <= 1'b0;
    end else if (s_axis_tvalid && s_axis_tready && s_axis_tlast) begin
      record_timestamp_odd <= ~record_timestamp_odd;
    end
  end

  // Instead of using the real modulo operation, we use a simple wrap-around
  // to avoid the complexity of the modulo operation. But this only works
  // when the record timestamp is between -10000 and 20000.
  assign record_timestamp_plus  = record_timestamp_reg + 32'sd10000;
  assign record_timestamp_minus = record_timestamp_reg - 32'sd10000;

  always_ff @(posedge ddr4_clk) begin
    if (record_timestamp_reg < 0) begin
      record_timestamp_wrapped      <= record_timestamp_plus[13:0];
      record_timestamp_wrapped_swap <= 1'b1;
    end else if (record_timestamp_reg >= 32'sd10000) begin
      record_timestamp_wrapped      <= record_timestamp_minus[13:0];
      record_timestamp_wrapped_swap <= 1'b1;
    end else begin
      record_timestamp_wrapped      <= record_timestamp_reg[13:0];
      record_timestamp_wrapped_swap <= 1'b0;
    end
  end

  always_ff @(posedge ddr4_clk) begin
    record_timestamp_wrapped_odd <= record_timestamp_odd;
  end

  // The input packet stream is at end position, since we know that we already
  // enough data. S_AXIS_TLAST is assert to force end the current packet
  assign tlast_pre     = (length_counter + 32'd8 >= record_length_reg) || s_axis_tlast;

  // There are two case when the current packet is end:
  //   1 shift <= shift_next, in-phase TLAST. The packet is end at input and
  //     is also end at output, no extra data is registered in module
  //   1 shift > shift_next, extra TLAST. The packet is end at input but need
  //     one more tick to output.
  assign tlast_inphase = tlast_pre && (shift <= shift_next);
  assign tlast_extra   = tlast_pre && (shift > shift_next);

  // Local time counter @ 400 MHz
  // We need a microseconds counter valud and an even/odd indicator

  always_ff @(posedge clk) begin
    sync_in_d  <= sync_in;
    sync_in_dd <= sync_in_d;
  end

  assign sync_in_posedge = sync_in_d && !sync_in_dd;

  always_ff @(posedge clk) begin
    if (rst) begin
      timestamp_counter_lsb <= 9'd0;
    end else if (sync_in_posedge) begin
      timestamp_counter_lsb <= 9'd0;
    end else if (timestamp_counter_lsb == 9'd399) begin
      timestamp_counter_lsb <= 9'd0;
    end else begin
      timestamp_counter_lsb <= timestamp_counter_lsb + 9'd1;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      timestamp_counter     <= 14'd0;
      timestamp_counter_odd <= 1'b0;
    end else if (sync_in_posedge) begin
      timestamp_counter     <= 14'd0;
      timestamp_counter_odd <= ~timestamp_counter_odd;
    end else if (timestamp_counter_lsb == 9'd399 && timestamp_counter < 14'd9999) begin
      timestamp_counter <= timestamp_counter + 14'd1;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      timestamp_counter_valid <= 1'b0;
    end else if (sync_in_posedge) begin
      timestamp_counter_valid <= 1'b1;
    end else if (timestamp_counter_lsb == 9'd399) begin
      timestamp_counter_valid <= 1'b1;
    end else begin
      timestamp_counter_valid <= 1'b0;
    end
  end

  // CDC the microsecond counter to DDR4 clock domain
  cdc_handshake_f #(
      .DEST_EXT_HSK(1'b0),
      .DEST_SYNC_FF(4),
      .INIT_SYNC_FF(1'b1),
      .SRC_SYNC_FF (4),
      .WIDTH       (15)
  ) i_cdc_handshake_timestamp (
      .src_clk   (clk),
      .src_in    ({timestamp_counter_odd, timestamp_counter}),
      .src_valid (timestamp_counter_valid),
      .src_ready (timestamp_counter_src_ready),
      //
      .dest_clk  (ddr4_clk),
      .dest_out  ({timestamp_counter_cdc_odd, timestamp_counter_cdc}),
      .dest_valid(timestamp_counter_cdc_valid),
      .dest_ready(1'b1)
  );

  // Output

  always_ff @(posedge ddr4_clk) begin
    extra_tlast <= (state == S_DATA) && s_axis_tvalid && tlast_extra;
  end

  always_ff @(posedge ddr4_clk) begin
    if ((state == S_DATA) && s_axis_tvalid && tlast_extra) begin
      extra_tkeep <= shift - shift_next;
    end
  end

  always_ff @(posedge ddr4_clk) begin
    if ((state == S_DATA) && s_axis_tvalid && tlast_extra) begin
      extra_tdata <= s_axis_tdata_shift2;
    end
  end

  always_ff @(posedge ddr4_clk) begin
    if (((state == S_DATA) && s_axis_tvalid)) begin
      m_axis_tdata <= byte_reverse64(s_axis_tdata_shift);
    end else if (extra_tlast) begin
      m_axis_tdata <= byte_reverse64(extra_tdata);
    end
  end

  always_ff @(posedge ddr4_clk) begin
    if ((state == S_DATA) && s_axis_tvalid) begin
      if (tlast_inphase) begin
        // In-phase TLAST
        case (shift - shift_next)
          3'b000:  m_axis_tkeep <= 8'hFF;
          3'b001:  m_axis_tkeep <= 8'h01;
          3'b010:  m_axis_tkeep <= 8'h03;
          3'b011:  m_axis_tkeep <= 8'h07;
          3'b100:  m_axis_tkeep <= 8'h0f;
          3'b101:  m_axis_tkeep <= 8'h1f;
          3'b110:  m_axis_tkeep <= 8'h3f;
          3'b111:  m_axis_tkeep <= 8'h7f;
          default: m_axis_tkeep <= 8'hFF;
        endcase
      end else begin
        m_axis_tkeep <= 8'hFF;
      end
    end else if (extra_tlast) begin
      case (extra_tkeep)
        3'b000:  m_axis_tkeep <= 8'hFF;
        3'b001:  m_axis_tkeep <= 8'h01;
        3'b010:  m_axis_tkeep <= 8'h03;
        3'b011:  m_axis_tkeep <= 8'h07;
        3'b100:  m_axis_tkeep <= 8'h0f;
        3'b101:  m_axis_tkeep <= 8'h1f;
        3'b110:  m_axis_tkeep <= 8'h3f;
        3'b111:  m_axis_tkeep <= 8'h7f;
        default: m_axis_tkeep <= 8'hFF;
      endcase
    end
  end

  always_ff @(posedge ddr4_clk) begin
    if ((state == S_DATA) && s_axis_tvalid) begin
      m_axis_tlast <= tlast_inphase || !ctrl_en_s;
    end else if (extra_tlast) begin
      m_axis_tlast <= 1'b1;
    end
  end

  always_ff @(posedge ddr4_clk) begin
    m_axis_tvalid <= ((state == S_DATA) && s_axis_tvalid) || extra_tlast;
  end

endmodule

`default_nettype wire
