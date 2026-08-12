`timescale 1 ns / 1 ps
//
`default_nettype none

module coe_framer_data (
    input var          clk,
    input var          rst,
    //
    input var          sync,
    //
    input var  [767:0] s_axis_tdata,
    input var  [  7:0] s_axis_tuser,
    input var          s_axis_tlast,
    input var          s_axis_tvalid,
    output var         s_axis_tready,
    //
    output var [ 31:0] m_axis_tdata,
    output var [  3:0] m_axis_tkeep,
    output var         m_axis_tlast,
    output var         m_axis_tvalid,
    input var          m_axis_tready,
    //
    output var [ 18:0] m_app_ts,
    //
    output var [  7:0] m_trans_messagetype,
    output var [ 15:0] m_trans_payloadsize,
    output var [ 15:0] m_trans_rtc_pc_id,
    //
    input var          ctrl_en,
    input var  [ 15:0] ctrl_seq_en,
    input var  [ 95:0] ctrl_seq_id,
    input var  [  7:0] ctrl_seq_cnt
);

  // Notes:

  // sync         -> sample_counter
  // sync_posedge -> seq_val_seq
  //              -> seq_counter
  //              -> seq_id_reg
  //              -> seq_valid_reg
  //              -> seq_val        -> s0_seq_sel
  //              -> seq_valid      -> s0_run
  //              -> seq_n_valid
  //              -> seq_last_val

  //              s_axis_tdata      -> s_axis_tdata_d -> s_axis_tdata_dd -> s0_axis_tdata

  // Parameters

  localparam [22:0] SamplePerFrameCount = 23'd4915200;

  // Signals

  wire         ctrl_en_s;
  wire  [15:0] ctrl_seq_en_s;
  wire  [95:0] ctrl_seq_id_s;
  wire  [ 7:0] ctrl_seq_cnt_s;

  logic        sync_d;
  wire         sync_posedge;

  logic [22:0] sample_counter;

  logic [ 3:0] seq_val;
  logic [15:0] seq_counter;

  logic [ 5:0] seq_id_reg        [0:15];
  wire  [ 5:0] seq_id;
  logic [ 5:0] seq_sel;

  logic [15:0] seq_valid_reg;
  wire         seq_valid;

  logic [ 4:0] seq_n_valid_c;
  logic [ 4:0] seq_n_valid;
  logic [ 3:0] seq_last_val;

  wire         seq_first;
  wire         seq_last;

  logic        s0_run;
  logic        s0_valid;
  logic        s0_seq_sel        [0:23];
  logic        s0_last;

  logic [31:0] s_axis_tdata_d    [0:23];
  logic [31:0] s_axis_tdata_dd   [0:23];

  logic [31:0] s0_axis_tdata_rev;
  logic [31:0] s0_axis_tdata;
  wire  [ 3:0] s0_axis_tkeep;
  wire         s0_axis_tlast;
  wire         s0_axis_tvalid;

  logic [18:0] app_ts;
  (* USE_DSP = "NO" *)
  logic [11:0] trans_payloadsize;
  logic [ 7:0] trans_seqid;

  genvar gen_i;

  wire unused_inputs = &{1'b0, s_axis_tuser, s_axis_tlast, s_axis_tvalid};
  wire unused_fifo_tuser;
  wire unused_fifo_err_discard;

  // Main

  // This module is always ready to accept data
  always_ff @(posedge clk) begin
    if (rst) begin
      s_axis_tready <= 1'b0;
    end else begin
      s_axis_tready <= 1'b1;
    end
  end

  // Count the TS

  always_ff @(posedge clk) begin
    sync_d <= sync;
  end

  assign sync_posedge = sync && ~sync_d;

  always_ff @(posedge clk) begin
    if (sync_posedge) begin
      sample_counter <= 'd0;
    end else begin
      sample_counter <= (sample_counter == SamplePerFrameCount - 23'd1) ? 'd0 : sample_counter + 1'd1;
    end
  end

  // Count how many sequence loop we already send
  // `s_axis_tuser[0]` is used to indicate the start of a new sequence

  always_ff @(posedge clk) begin
    if (sync_posedge) begin
      seq_val <= 'd0;
    end else begin
      seq_val <= seq_val + 1'd1;
    end
  end

  always_ff @(posedge clk) begin
    if (sync_posedge) begin
      seq_counter <= 'd0;
    end else if (&seq_val) begin
      seq_counter <= seq_counter == ({8'd0, ctrl_seq_cnt_s} - 16'd1) ? 'd0 : seq_counter + 1'd1;
    end
  end

  // Update the internal sequence ID and valid bit,

  always @(posedge clk) begin : p_seq_id_reg
    integer i;
    if (sync_posedge) begin
      for (i = 0; i < 16; i = i + 1) begin
        seq_id_reg[i] <= ctrl_seq_id_s[i*6+5-:6];
      end
    end
  end

  always_ff @(posedge clk) begin
    if (sync_posedge) begin
      seq_valid_reg <= ctrl_seq_en_s;
    end
  end

  // Track how many valid sequence we have, and which sequence is the last one

  always_comb begin : p_seq_n_valid_c
    integer i;
    seq_n_valid_c = 'd0;
    for (i = 0; i < 16; i = i + 1) begin
      if (ctrl_seq_en_s[i]) begin
        seq_n_valid_c = seq_n_valid_c + 1'd1;
      end
    end
  end

  always_ff @(posedge clk) begin
    if (sync_posedge) begin
      seq_n_valid <= seq_n_valid_c;
    end
  end

  always @(posedge clk) begin : p_seq_last_val
    integer i;
    if (sync_posedge) begin
      for (i = 0; i < 16; i = i + 1) begin
        if (ctrl_seq_en_s[i]) begin
          seq_last_val <= i[3:0];
        end
      end
    end
  end

  assign seq_id = seq_id_reg[seq_val];

  // seq_id = {band[5:4], cc[3:2], ant[1:0]}
  // however, the data streams are sorted by A0C0/A0C1/A0C2/A1C0...
  // so there is mapping here
  always_comb begin
    case (seq_id)
      // Band0 CC0
      6'b00_00_00: seq_sel = 6'd0;
      6'b00_00_01: seq_sel = 6'd3;
      6'b00_00_10: seq_sel = 6'd6;
      6'b00_00_11: seq_sel = 6'd9;
      // Band0 CC1
      6'b00_01_00: seq_sel = 6'd1;
      6'b00_01_01: seq_sel = 6'd4;
      6'b00_01_10: seq_sel = 6'd7;
      6'b00_01_11: seq_sel = 6'd10;
      // Band0 CC2
      6'b00_10_00: seq_sel = 6'd2;
      6'b00_10_01: seq_sel = 6'd5;
      6'b00_10_10: seq_sel = 6'd8;
      6'b00_10_11: seq_sel = 6'd11;
      // Band1 CC0
      6'b01_00_00: seq_sel = 6'd12;
      6'b01_00_01: seq_sel = 6'd15;
      // Band1 CC1
      6'b01_01_00: seq_sel = 6'd13;
      6'b01_01_01: seq_sel = 6'd16;
      // Band1 CC2
      6'b01_10_00: seq_sel = 6'd14;
      6'b01_10_01: seq_sel = 6'd17;
      // Band2 CC0
      6'b10_00_00: seq_sel = 6'd18;
      // Band2 CC1
      6'b10_01_00: seq_sel = 6'd19;
      // Band2 CC2
      6'b10_10_00: seq_sel = 6'd20;
      // Band3 CC0
      6'b11_00_00: seq_sel = 6'd21;
      // Band3 CC1
      6'b11_01_00: seq_sel = 6'd22;
      // Band3 CC2
      6'b11_10_00: seq_sel = 6'd23;
      default:     seq_sel = 6'b111111;
    endcase
  end

  assign seq_valid = seq_valid_reg[seq_val];

  assign seq_first = seq_valid && (seq_counter == 0) && ctrl_en_s && |ctrl_seq_cnt_s;

  assign seq_last  = (seq_counter == ({8'd0, ctrl_seq_cnt_s} - 16'd1)) && (seq_val == seq_last_val);

  //

  generate
    for (gen_i = 0; gen_i < 24; gen_i = gen_i + 1) begin : g_seq_sel_ch

      always_ff @(posedge clk) begin
        s0_seq_sel[gen_i] <= (seq_sel == gen_i) && seq_valid;
      end

    end
  endgenerate

  always_ff @(posedge clk) begin
    if (seq_first) begin
      s0_run <= 1'b1;
    end else if (seq_last) begin
      s0_run <= 1'b0;
    end
  end

  always_ff @(posedge clk) begin
    if (seq_first) begin
      s0_valid <= 1'b1;
    end else if (seq_valid && s0_run) begin
      s0_valid <= 1'b1;
    end else begin
      s0_valid <= 1'b0;
    end
  end

  always_ff @(posedge clk) begin
    if (seq_valid) begin
      s0_last <= seq_last;
    end
  end

  generate
    for (gen_i = 0; gen_i < 24; gen_i = gen_i + 1) begin : g_axis_d

      always_ff @(posedge clk) begin
        s_axis_tdata_d[gen_i] <= s_axis_tdata[gen_i*32+31-:32];
      end

      always_ff @(posedge clk) begin
        if (s0_seq_sel[gen_i]) begin
          s_axis_tdata_dd[gen_i] <= s_axis_tdata_d[gen_i];
        end else begin
          s_axis_tdata_dd[gen_i] <= 'b0;
        end
      end

    end
  endgenerate

  always_comb begin : p_rev
    integer i;
    s0_axis_tdata_rev = 'd0;
    for (i = 0; i < 24; i = i + 1) begin
      s0_axis_tdata_rev = s0_axis_tdata_rev | s_axis_tdata_dd[i];
    end
  end

  always_ff @(posedge clk) begin
    s0_axis_tdata <= {
      s0_axis_tdata_rev[23:16],  // Q lsb
      s0_axis_tdata_rev[31:24],  // Q msb
      s0_axis_tdata_rev[7:0],  // I lsb
      s0_axis_tdata_rev[15:8]  // I msb
    };
  end

  assign s0_axis_tkeep = 4'b1111;

  delay #(
      .DEPTH(2),
      .WIDTH(1),
      .INIT (0)
  ) i_delay_s0_axis_tlast (
      .clk (clk),
      .rst (rst),
      .cen (1'b1),
      .din (s0_last),
      .dout(s0_axis_tlast)
  );

  delay #(
      .DEPTH(2),
      .WIDTH(1),
      .INIT (0)
  ) i_delay_s0_axis_tvalid (
      .clk (clk),
      .rst (rst),
      .cen (1'b1),
      .din (s0_valid),
      .dout(s0_axis_tvalid)
  );

  // OOB signals

  // When the sequence counter is 0, register current TS
  always_ff @(posedge clk) begin
    if ((seq_counter == 0) && (seq_val == 0)) begin
      app_ts <= sample_counter[22:4];
    end
  end

  always_ff @(posedge clk) begin
    if (seq_valid_reg[seq_val] && seq_last) begin
      m_app_ts <= app_ts;
    end
  end

  always_ff @(posedge clk) begin
    if (seq_valid_reg[seq_val] && seq_last) begin
      trans_payloadsize <= (ctrl_seq_cnt_s * seq_n_valid);
    end
  end

  assign m_trans_messagetype = 8'b0;

  assign m_trans_payloadsize = {2'b00, trans_payloadsize, 2'b00};

  always_ff @(posedge clk) begin
    if (seq_valid_reg[seq_val] && seq_last) begin
      m_trans_rtc_pc_id <= seq_valid_reg;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      trans_seqid <= 'd0;
    end else if (seq_valid_reg[seq_val] && seq_last) begin
      trans_seqid <= trans_seqid + 1'd1;
    end
  end

  // CDC for control signals

  cdc_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (0),
      .SRC_INPUT_REG(0)
  ) i_cdc_ctrl_en (
      .src_clk (1'b1),
      .src_in  (ctrl_en),
      //
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
      //
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
      //
      .dest_clk(clk),
      .dest_out(ctrl_seq_id_s)
  );

  cdc_array_single #(
      .DEST_SYNC_FF (2),
      .INIT_SYNC_FF (0),
      .SRC_INPUT_REG(0),
      .WIDTH        (8)
  ) i_cdc_ctrl_seq_cnt (
      .src_clk (1'b1),
      .src_in  (ctrl_seq_cnt),
      //
      .dest_clk(clk),
      .dest_out(ctrl_seq_cnt_s)
  );

  axis_fifo_alt #(
      .ASYNC_MODE  (0),
      .FIFO_DEPTH  (4096),
      .FIFO_LATENCY(3),
      .USER_WIDTH  (1)
  ) i_fifo (
      .s_axis_aclk   (clk),
      .s_axis_aresetn(ctrl_en_s),
      //
      .s_axis_tdata  (s0_axis_tdata),
      .s_axis_tkeep  (s0_axis_tkeep),
      .s_axis_tlast  (s0_axis_tlast),
      .s_axis_tuser  ('b0),
      .s_axis_tvalid (s0_axis_tvalid),
      //
      .m_axis_aclk   (clk),
      //
      .m_axis_tdata  (m_axis_tdata),
      .m_axis_tkeep  (m_axis_tkeep),
      .m_axis_tlast  (m_axis_tlast),
      .m_axis_tuser  (unused_fifo_tuser),
      .m_axis_tvalid (m_axis_tvalid),
      .m_axis_tready (m_axis_tready),
      //
      .err_discard   (unused_fifo_err_discard)
  );

endmodule

`default_nettype wire
