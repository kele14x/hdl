`timescale 1 ns / 1 ps
//
`default_nettype none

module prach_stream2block #(
    parameter int NUM_ANT = 4
) (
    input  wire                clk,
    input  wire                rst,
    //
    input  wire  [       15:0] din_dr,
    input  wire  [       15:0] din_di,
    input  wire                din_sf,
    input  wire                din_sl,
    input  wire                din_sy,
    input  wire  [        7:0] din_chn,
    input  wire                din_dv,
    input  wire                din_last,
    //
    output logic [       15:0] dout_dr,
    output logic [       15:0] dout_di,
    output wire                dout_sf,
    output wire                dout_sl,
    output wire                dout_sy,
    output wire  [        1:0] dout_chn,
    output wire                dout_dv,
    output wire                dout_last,
    //
    input  wire  [NUM_ANT-1:0] rd_channel_req,
    output logic [NUM_ANT-1:0] rd_channel_ack,
    // CSR
    //----
    input  wire  [        8:0] ctrl_start_symbol0,
    input  wire  [        8:0] ctrl_start_symbol1,
    input  wire  [       18:0] ctrl_start_sample,
    input  wire  [        3:0] ctrl_num_symbol
);

  // Notes

  // din_*  ->                          -> wr_data
  // din_dv -> symbol_cnt -> wr_state   -> wr_addr
  //                      -> sample_cnt -> wr_we   -> ap_req
  //                                    -> wr_bank -> ap_bank

  // Parameters

  localparam int NumPrb = 1536;
  localparam int AddrWidth = $clog2(NumPrb) + 1;  // 12

  // Signals

  typedef enum int {
    WR_RST,
    WR_IDLE,
    WR_CP,
    WR_SEQ0,
    WR_SEQ1
  } wr_state_t;

  wr_state_t wr_state, wr_state_next;

  logic [          8:0] symbol_cnt;
  logic                 symbol_cnt_valid;

  logic                 sample_cnt_inc;
  logic [         15:0] sample_cnt;

  logic [         15:0] din_dr_d;
  logic [         15:0] din_di_d;
  logic                 din_sf_d;
  logic                 din_sl_d;
  logic                 din_sy_d;
  logic [          7:0] din_chn_d;
  logic                 din_dv_d;
  logic                 din_last_d;

  logic                 wr_bank;
  logic [         10:0] wr_cnt;

  logic [AddrWidth-1:0] wr_addr;
  logic [  NUM_ANT-1:0] wr_we;
  logic [         31:0] wr_data;

  logic                 busy;
  logic                 done;

  logic [  NUM_ANT-1:0] ap_bank;
  logic [  NUM_ANT-1:0] ap_req;
  logic                 ap_req_any;
  logic [  NUM_ANT-1:0] ap_ack;

  logic                 rd_bank;
  logic [         10:0] rd_cnt;
  logic [         10:0] rd_cnt_rev;

  logic [AddrWidth-1:0] rd_addr;
  logic [  NUM_ANT-1:0] rd_en;
  logic [  NUM_ANT-1:0] rd_en_d;
  logic [  NUM_ANT-1:0] rd_en_dd;
  logic [         31:0] rd_data          [NUM_ANT];
  logic [         31:0] rd_data_c;

  logic [          1:0] chn;
  logic                 sync;

  // Symbol counter

  always_ff @(posedge clk) begin
    if (din_sf && (din_chn == '0)) begin
      symbol_cnt <= '0;
    end else if (din_sy && (din_chn == '0)) begin
      symbol_cnt <= symbol_cnt + 1'b1;
    end
  end

  always_ff @(posedge clk) begin
    if (din_sf && (din_chn == '0)) begin
      symbol_cnt_valid <= 1'b1;
    end else if (din_sy && (din_chn == '0)) begin
      symbol_cnt_valid <= 1'b1;
    end else begin
      symbol_cnt_valid <= 1'b0;
    end
  end

  // Sample counter

  always_ff @(posedge clk) begin
    sample_cnt_inc <= (din_chn == '0);
  end

  always_ff @(posedge clk) begin
    if ((wr_state == WR_IDLE) && symbol_cnt_valid &&
       ((symbol_cnt == ctrl_start_symbol0) || (symbol_cnt == ctrl_start_symbol1))) begin
      sample_cnt <= '0;
    end else if (sample_cnt_inc) begin
      sample_cnt <= sample_cnt + 1'b1;
    end
  end

  // Write state FSM

  always_ff @(posedge clk) begin
    if (rst) begin
      wr_state <= WR_RST;
    end else begin
      wr_state <= wr_state_next;
    end
  end

  always_comb begin
    wr_state_next = wr_state;

    case (wr_state)
      WR_RST: begin
        wr_state_next = WR_IDLE;
      end

      WR_IDLE: begin
        if (symbol_cnt_valid && ((symbol_cnt == ctrl_start_symbol0) || (symbol_cnt == ctrl_start_symbol1))) begin
          wr_state_next = WR_CP;
        end
      end

      WR_CP: begin
        if (sample_cnt_inc && (sample_cnt == (ctrl_start_sample[18:4] - 1))) begin
          wr_state_next = WR_SEQ0;
        end
      end

      WR_SEQ0: begin
        if (sample_cnt_inc && (sample_cnt == (ctrl_start_sample[18:4] + 1535))) begin
          if (ctrl_num_symbol <= 1) begin
            wr_state_next = WR_IDLE;
          end else begin
            wr_state_next = WR_SEQ1;
          end
        end
      end

      WR_SEQ1: begin
        if (sample_cnt_inc && (sample_cnt == (ctrl_start_sample[18:4] + 3071))) begin
          wr_state_next = WR_IDLE;
        end
      end

      default: begin
        wr_state_next = WR_RST;
      end
    endcase
  end

  // Write buffer

  delay #(
      .WIDTH(45),
      .DEPTH(2),
      .INIT (1'b1)
  ) u_delay_signals (
      .clk (clk),
      .rst (1'b0),
      .cen (1'b1),
      .din ({din_last, din_dv, din_chn, din_sy, din_sl, din_sf, din_di, din_dr}),
      .dout({din_last_d, din_dv_d, din_chn_d, din_sy_d, din_sl_d, din_sf_d, din_di_d, din_dr_d})
  );

  // Write data

  always_ff @(posedge clk) begin
    wr_bank <= (wr_state == WR_SEQ1);
  end

  always_ff @(posedge clk) begin
    if (wr_state == WR_SEQ0) begin
      wr_cnt <= 11'(sample_cnt - {1'b0, ctrl_start_sample[18:4]});
    end else if (wr_state == WR_SEQ1) begin
      wr_cnt <= 11'(sample_cnt - {1'b0, ctrl_start_sample[18:4]} - 16'd1536);
    end else begin
      wr_cnt <= '0;
    end
  end

  // Map {wr_bank, wr_cnt} to wr_addr
  assign wr_addr[11:9] = {wr_bank, wr_cnt[10:9]} == 3'b000 ? 3'b000 :
                         {wr_bank, wr_cnt[10:9]} == 3'b001 ? 3'b001 :
                         {wr_bank, wr_cnt[10:9]} == 3'b010 ? 3'b010 :
                         {wr_bank, wr_cnt[10:9]} == 3'b100 ? 3'b011 :
                         {wr_bank, wr_cnt[10:9]} == 3'b101 ? 3'b100 :
                         {wr_bank, wr_cnt[10:9]} == 3'b110 ? 3'b101 :
                         '0;

  assign wr_addr[8:0] = wr_cnt[8:0];

  generate
    for (genvar i = 0; i < NUM_ANT; i++) begin : g_wr_we

      always_ff @(posedge clk) begin
        wr_we[i] <= din_dv_d && (din_chn_d == i) && (wr_state == WR_SEQ0 || wr_state == WR_SEQ1);
      end

    end
  endgenerate

  always_ff @(posedge clk) begin
    wr_data <= {din_di_d, din_dr_d};
  end

  // Reader FSM

  generate
    for (genvar i = 0; i < NUM_ANT; i++) begin : g_ack

      always_ff @(posedge clk) begin
        // This is start symbol ID of RACH sequence
        if ((wr_cnt == 1535) && wr_we[i]) begin
          ap_bank[i] <= wr_bank;
        end
      end

      // After buffer filled with required samples, send request
      always_ff @(posedge clk) begin
        if (rst) begin
          ap_req[i] <= 1'b0;
        end else if ((wr_cnt == 1535) && wr_we[i] && rd_channel_req[i]) begin  // 1536
          ap_req[i] <= 1'b1;
        end else if (ap_ack[i]) begin
          ap_req[i] <= 1'b0;
        end
      end

      // First channel first arbiter
      always_comb begin
        ap_ack[i] = ap_req[i] && ~busy;
        for (int j = 0; j < i; j++) begin
          if (ap_req[j]) ap_ack[i] = 1'b0;
        end
      end

      always_ff @(posedge clk) begin
        if (rst) begin
          rd_en[i] <= 1'b0;
        end else if (ap_ack[i]) begin
          rd_en[i] <= 1'b1;
        end else if (done) begin
          rd_en[i] <= 1'b0;
        end
      end

      always_ff @(posedge clk) begin
        rd_channel_ack[i] <= ((wr_cnt == 1535) && wr_we[i] && rd_channel_req[i]);
      end

    end
  endgenerate

  always_ff @(posedge clk) begin
    rd_en_d  <= rd_en;
    rd_en_dd <= rd_en_d;
  end

  assign ap_req_any = |ap_req;

  always_ff @(posedge clk) begin
    if (rst) begin
      busy <= 1'b0;
    end else if (done) begin
      busy <= 1'b0;
    end else if (ap_req_any) begin
      busy <= 1'b1;
    end
  end

  assign done = rd_cnt == 11'b11111111110;

  // Read

  always_ff @(posedge clk) begin
    for (int i = 0; i < 4; i++) begin
      if (ap_ack[i]) begin
        rd_bank <= ap_bank[i];
      end
    end
  end

  always_ff @(posedge clk) begin
    if (~busy) begin
      rd_cnt <= '0;
    end else begin
      rd_cnt <= (rd_cnt[1:0] == 2'b10) ? (rd_cnt + 11'd2) : (rd_cnt + 11'd1);
    end
  end

  // Bit reverse for 1536-pts FFT: {[1:0], [2:10]}
  always_comb begin
    for (int i = 0; i < 9; i++) begin
      rd_cnt_rev[i] = rd_cnt[10-i];
    end
    rd_cnt_rev[10:9] = rd_cnt[1:0];
  end

  // Map {rd_bank, rd_cnt} to rd_addr
  assign rd_addr[11:9] = {rd_bank, rd_cnt_rev[10:9]} == 3'b000 ? 3'b000 :
                         {rd_bank, rd_cnt_rev[10:9]} == 3'b001 ? 3'b001 :
                         {rd_bank, rd_cnt_rev[10:9]} == 3'b010 ? 3'b010 :
                         {rd_bank, rd_cnt_rev[10:9]} == 3'b100 ? 3'b011 :
                         {rd_bank, rd_cnt_rev[10:9]} == 3'b101 ? 3'b100 :
                         {rd_bank, rd_cnt_rev[10:9]} == 3'b110 ? 3'b101 :
                         '0;

  assign rd_addr[8:0] = rd_cnt_rev[8:0];

  always_comb begin
    rd_data_c = '0;
    for (int i = 0; i < 4; i++) begin
      if (rd_en_dd[i]) begin
        rd_data_c = rd_data[i];
      end
    end
  end

  always_ff @(posedge clk) begin
    dout_dr <= rd_data_c[15:0];
    dout_di <= rd_data_c[31:16];
  end

  // Sideband message

  always_ff @(posedge clk) begin
    if (rst) begin
      chn <= '0;
    end else begin
      for (int i = 0; i < 4; i++) begin
        if (ap_ack[i]) begin
          chn <= 2'(i);
        end
      end
    end
  end

  always_ff @(posedge clk) begin
    sync <= 1'b0;
    for (int i = 0; i < 4; i++) begin
      if (ap_ack[i]) begin
        sync <= 1'b1;
      end
    end
  end

  generate
    for (genvar i = 0; i < NUM_ANT; i++) begin : g_ant

      ram_sdp #(
          .ADDR_WIDTH  (AddrWidth),
          .DATA_WIDTH  (32),
          .READ_LATENCY(2),
          .INIT_FILE   ("NONE")
      ) u_ram (
          // Port A
          .clka (clk),
          .ena  (wr_we[i]),
          .wea  (wr_we[i]),
          .addra(wr_addr),
          .dina (wr_data),
          // Port B
          .clkb (clk),
          .rstb ({2{~rd_en_d[i]}}),
          .enb  ({rd_en_d[i], rd_en[i]}),
          .addrb(rd_addr),
          .doutb(rd_data[i])
      );

    end
  endgenerate

  delay #(
      .WIDTH(5),
      .DEPTH(3),
      .INIT (1'b0)
  ) u_delay_ctrl (
      .clk (clk),
      .rst (1'b0),
      .cen (1'b1),
      .din ({done, busy, chn, sync}),
      .dout({dout_last, dout_dv, dout_chn, dout_sy})
  );

  assign dout_sf = 1'b0;
  assign dout_sl = 1'b0;

  wire unused_stream2block = &{1'b0, ctrl_start_sample[3:0], din_sf_d, din_sl_d, din_sy_d, din_last_d};

endmodule

`default_nettype wire
