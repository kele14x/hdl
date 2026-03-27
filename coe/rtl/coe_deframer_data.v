`timescale 1 ns / 1 ps
//
`default_nettype none

module coe_deframer_data (
    // Ethernet
    input  wire         clk,
    input  wire         rst,
    //
    input  wire         sync,
    //
    input  wire [ 31:0] s_axis_tdata,
    input  wire [  3:0] s_axis_tkeep,
    input  wire         s_axis_tlast,
    input  wire         s_axis_tvalid,
    //
    input  wire         s_trans_header_valid,
    input  wire [ 15:0] s_trans_rtc_pc_id,
    input  wire [  7:0] s_trans_seqid,
    input  wire         s_trans_ebit,
    input  wire [  6:0] s_trans_subseqid,
    //
    input  wire         s_app_valid,
    input  wire [ 18:0] s_app_ts,
    // Radio I/F
    output wire [767:0] m_axis_rx_tdata,
    output wire [  7:0] m_axis_rx_tuser,
    output wire         m_axis_rx_tlast,
    output reg          m_axis_rx_tvalid,
    input  wire         m_axis_rx_tready,
    // CSR
    //----
    input  wire         ctrl_clk,
    input  wire         ctrl_rst,
    //
    input  wire         ctrl_en,
    input  wire [ 15:0] ctrl_seq_en,
    input  wire [ 95:0] ctrl_seq_id,
    //
    input  wire [  8:0] ctrl_ts_offset,
    //
    output wire [ 31:0] stat_conflict_cnt
);

  // Parameters

  localparam integer SamplePerFrame = 4915200;
  localparam integer MaxSeqLen = 16;

  localparam integer NumChannel = 24;

  localparam integer AddrWidth = 13;
  localparam integer DataWidth = 32;

  // Helpers

  // This function returns how many 1 (valid sequence) are in the seq_en.
  function automatic [4:0] get_seq_n_valid(input reg [15:0] seq_en);
    integer i;
    begin
      get_seq_n_valid = 0;
      for (i = 0; i < 16; i = i + 1) begin
        if (seq_en[i]) begin
          get_seq_n_valid = get_seq_n_valid + 1;
        end
      end
    end
  endfunction

  // This function returns the channel delay for the given sequence ID.
  function automatic [3:0] get_ch_delay(input integer id, input reg [15:0] seq_en,
                                        input reg [95:0] seq_id);
    integer i;
    reg found;
    begin
      found = 0;
      get_ch_delay = 0;
      for (i = 0; i < MaxSeqLen; i = i + 1) begin
        if (!found && seq_en[i] && id_sel_map(seq_id[i*6+5-:6]) == id) begin
          found = 1;
          get_ch_delay = 15 - i;
        end
      end
    end
  endfunction

  // This function maps the 6-bit ID to 0~23 channel selection
  function automatic [5:0] id_sel_map(input reg [5:0] id);
    begin
      case (id)
        // Band0 CC0
        6'b00_00_00: id_sel_map = 6'd0;
        6'b00_00_01: id_sel_map = 6'd3;
        6'b00_00_10: id_sel_map = 6'd6;
        6'b00_00_11: id_sel_map = 6'd9;
        // Band0 CC1
        6'b00_01_00: id_sel_map = 6'd1;
        6'b00_01_01: id_sel_map = 6'd4;
        6'b00_01_10: id_sel_map = 6'd7;
        6'b00_01_11: id_sel_map = 6'd10;
        // Band0 CC2
        6'b00_10_00: id_sel_map = 6'd2;
        6'b00_10_01: id_sel_map = 6'd5;
        6'b00_10_10: id_sel_map = 6'd8;
        6'b00_10_11: id_sel_map = 6'd11;
        // Band1 CC0
        6'b01_00_00: id_sel_map = 6'd12;
        6'b01_00_01: id_sel_map = 6'd15;
        // Band1 CC1
        6'b01_01_00: id_sel_map = 6'd13;
        6'b01_01_01: id_sel_map = 6'd16;
        // Band1 CC2
        6'b01_10_00: id_sel_map = 6'd14;
        6'b01_10_01: id_sel_map = 6'd17;
        // Band2 CC0
        6'b10_00_00: id_sel_map = 6'd18;
        // Band2 CC1
        6'b10_01_00: id_sel_map = 6'd19;
        // Band2 CC2
        6'b10_10_00: id_sel_map = 6'd20;
        // Band3 CC0
        6'b11_00_00: id_sel_map = 6'd21;
        // Band3 CC1
        6'b11_01_00: id_sel_map = 6'd22;
        // Band3 CC2
        6'b11_10_00: id_sel_map = 6'd23;
        default:     id_sel_map = 6'b111111;
      endcase
    end
  endfunction

  // Signals

  wire                 ctrl_en_s;
  wire [         15:0] ctrl_seq_en_s;
  wire [         95:0] ctrl_seq_id_s;
  wire [          5:0] ctrl_seq_id_ch      [ 0:MaxSeqLen-1];
  wire [          5:0] ctrl_seq_sel_ch     [ 0:MaxSeqLen-1];

  reg  [          4:0] ctrl_seq_n_valid;
  reg  [          3:0] ctrl_ch_delay       [0:NumChannel-1];

  wire [          8:0] ctrl_ts_offset_s;

  // Write side signals

  wire                 wr_we;
  reg  [          3:0] wr_seq;
  reg  [AddrWidth-5:0] wr_cnt;
  wire [AddrWidth-1:0] wr_addr;
  wire [DataWidth-1:0] wr_din;

  // Read side signals

  reg                  sync_d;
  wire                 sync_posedge;

  reg                  rd_en;
  wire                 rd_en_d;
  reg  [          5:0] rd_id;
  wire [          5:0] rd_sel;
  wire [          5:0] rd_sel_d;

  reg  [AddrWidth-5:0] rd_addr_msb;
  reg  [          3:0] rd_addr_lsb;
  wire [AddrWidth-1:0] rd_addr;
  wire [DataWidth-1:0] rd_dout;

  reg  [         31:0] dout_reg            [0:NumChannel-1];

  reg  [         22:0] sample_counter;
  wire [          3:0] seq_counter;

  // Status

  reg                  conflict;
  reg                  conflict_d;
  reg  [         31:0] stat_conflict_cnt_r;

  // Control signal CDC & signal mapping

  cdc_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (0),
      .SRC_INPUT_REG(0)
  ) i_cdc_ctrl_en (
      .src_clk (1'b1),
      .src_in  (ctrl_en),
      .dest_clk(clk),
      .dest_out(ctrl_en_s)
  );

  cdc_array_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (0),
      .SRC_INPUT_REG(0),
      .WIDTH        (16)
  ) i_cdc_ctrl_seq_en (
      .src_clk (1'b1),
      .src_in  (ctrl_seq_en),
      .dest_clk(clk),
      .dest_out(ctrl_seq_en_s)
  );

  cdc_array_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (0),
      .SRC_INPUT_REG(0),
      .WIDTH        (96)
  ) i_cdc_ctrl_seq_id (
      .src_clk (1'b1),
      .src_in  (ctrl_seq_id),
      .dest_clk(clk),
      .dest_out(ctrl_seq_id_s)
  );

  cdc_array_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (0),
      .SRC_INPUT_REG(0),
      .WIDTH        (9)
  ) i_cdc_ctrl_rd_offset (
      .src_clk (1'b1),
      .src_in  (ctrl_ts_offset),
      .dest_clk(clk),
      .dest_out(ctrl_ts_offset_s)
  );

  generate
    genvar i;
    for (i = 0; i < MaxSeqLen; i = i + 1) begin : g_seq

      assign ctrl_seq_id_ch[i] = ctrl_seq_id_s[i*6+5-:6];

    end
  endgenerate

  always @(posedge clk) begin
    ctrl_seq_n_valid <= get_seq_n_valid(ctrl_seq_en_s);
  end

  // The data is stored in a simple dual port RAM.

  ram_sdp_pipe #(
      .ADDR_WIDTH(AddrWidth),
      .DATA_WIDTH(DataWidth),
      .OUTPUT_REG(1),
      .INIT_WORD (0),
      .INIT_FILE ("")
  ) i_ram_sdp (
      // Port A
      .clka (clk),
      .wea  (wr_we),
      .addra(wr_addr),
      .dina (wr_din),
      // Port B
      .clkb (clk),
      .rstb (1'b0),
      .enb  (rd_en),
      .addrb(rd_addr),
      .doutb(rd_dout)
  );

  // Write side

  assign wr_we = s_axis_tvalid;

  // `s_app_valid` is always 1 clock tick ahead of data, so we can safely reset
  // the sequence counter when it's asserted.
  always @(posedge clk) begin
    if (s_app_valid) begin
      wr_seq <= 'd0;
    end else if (wr_we && (wr_seq == ctrl_seq_n_valid - 1)) begin
      wr_seq <= 'd0;
    end else if (wr_we) begin
      wr_seq <= wr_seq + 1'd1;
    end
  end

  always @(posedge clk) begin
    if (s_app_valid) begin
      wr_cnt <= s_app_ts[AddrWidth-5:0];
    end else if (wr_we && (wr_seq == ctrl_seq_n_valid - 1)) begin
      wr_cnt <= wr_cnt + 1'd1;
    end
  end

  assign wr_addr = {wr_cnt, wr_seq};

  assign wr_din = {
    s_axis_tdata[23:16],  // Q msb
    s_axis_tdata[31:24],  // Q lsb
    s_axis_tdata[7:0],  // I msb
    s_axis_tdata[15:8]  // I lsb
  };

  // Sample & sequence counter

  always @(posedge clk) begin
    sync_d <= sync;
  end

  assign sync_posedge = sync & ~sync_d;

  always @(posedge clk) begin
    if (rst) begin
      sample_counter <= 'd0;
    end else if (sync_posedge) begin
      sample_counter <= 'd0;
    end else begin
      sample_counter <= (sample_counter == SamplePerFrame - 1) ? 'd0 : sample_counter + 1'd1;
    end
  end

  assign seq_counter = sample_counter[3:0];

  // Read side
  // synq
  // sync_posedge -> sample_counter -> rd_addr
  //                 seq_counter    -> rd_en   -> rd_data ->

  // The read sequence is controlled by the ctrl_seq_en signal.
  always @(posedge clk) begin
    rd_en <= ctrl_seq_en_s[seq_counter] && ctrl_en_s;
  end

  delay #(
      .WIDTH(1),
      .DEPTH(2)
  ) i_delay_rd_en (
      .clk (clk),
      .rst (1'b0),
      .cen (1'b1),
      .din (rd_en),
      .dout(rd_en_d)
  );

  always @(posedge clk) begin
    rd_id <= ctrl_seq_id_ch[seq_counter];
  end

  assign rd_sel = id_sel_map(rd_id);

  delay #(
      .WIDTH(6),
      .DEPTH(2)
  ) i_delay_rd_sel (
      .clk (clk),
      .rst (1'b0),
      .cen (1'b1),
      .din (rd_sel),
      .dout(rd_sel_d)
  );

  // The MSB part of read address is the Ts counter
  always @(posedge clk) begin
    rd_addr_msb <= sample_counter[12:4] - ctrl_ts_offset_s;
  end

  // Read sequentially from the RAM
  always @(posedge clk) begin
    if (seq_counter == 'd0) begin
      rd_addr_lsb <= 'd0;
    end else if (rd_en) begin
      rd_addr_lsb <= rd_addr_lsb + 1'b1;
    end
  end

  assign rd_addr = {rd_addr_msb, rd_addr_lsb};

  // Output AXIS

  always @(posedge clk) begin : p_m_axis_rx_tdata
    integer i;
    for (i = 0; i < NumChannel; i = i + 1) begin
      if (rd_en_d && rd_sel_d == i) begin
        dout_reg[i] <= rd_dout;
      end
    end
  end

  generate
    genvar j;
    for (j = 0; j < NumChannel; j = j + 1) begin : g_ch

      always @(posedge clk) begin
        ctrl_ch_delay[j] <= get_ch_delay(j, ctrl_seq_en_s, ctrl_seq_id_s);
      end

      srl #(
          .ADDR_WIDTH(4),
          .DATA_WIDTH(32),
          .OUTPUT_REG(1)
      ) i_srl (
          // Read Interface
          .clk (clk),
          .rst (1'b0),
          .cen (1'b1),
          //
          .addr(ctrl_ch_delay[j]),
          .din (dout_reg[j]),
          .dout(m_axis_rx_tdata[j*32+31-:32])
      );

    end
  endgenerate

  delay #(
      .WIDTH(1),
      .DEPTH(5)
  ) i_delay_tuser (
      .clk (clk),
      .rst (1'b0),
      .cen (1'b1),
      .din (sync_posedge || &seq_counter),
      .dout(m_axis_rx_tuser[0])
  );

  assign m_axis_rx_tuser[7:1] = 7'b0000000;

  assign m_axis_rx_tlast = 1'b0;

  always @(posedge clk) begin
    if (rst) begin
      m_axis_rx_tvalid <= 1'b0;
    end else begin
      m_axis_rx_tvalid <= 1'b1;
    end
  end

  // ignore m_axis_rx_tready

  // Status

  // Read/write conflict detection

  always @(posedge clk) begin
    // Rauh read/write conflict detection by compare address point MSB part
    conflict <= (wr_addr[AddrWidth-1:6] == rd_addr[AddrWidth-1:6]);
  end

  always @(posedge clk) begin
    conflict_d <= conflict;
  end

  always @(posedge clk) begin
    if (rst) begin
      stat_conflict_cnt_r <= 'd0;
    end else if (conflict && ~conflict_d) begin
      stat_conflict_cnt_r <= stat_conflict_cnt_r + 1'd1;
    end
  end

  cdc_array_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (0),
      .SRC_INPUT_REG(0),
      .WIDTH        (32)
  ) i_cdc_stat_conflict_cnt (
      .src_clk (1'b1),
      .src_in  (stat_conflict_cnt_r),
      .dest_clk(ctrl_clk),
      .dest_out(stat_conflict_cnt)
  );

endmodule

`default_nettype wire
