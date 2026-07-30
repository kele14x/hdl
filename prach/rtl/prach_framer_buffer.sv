`timescale 1 ns / 1 ps
//
`default_nettype none

module prach_framer_buffer #(
    parameter int CC_ID   = 0,
    parameter int ANT_ID  = 0,
    parameter int NUM_ANT = 4
) (
    input  wire        clk,
    input  wire        rst,
    //
    input  wire [15:0] din_dr,
    input  wire [15:0] din_di,
    input  wire        din_sf,
    input  wire        din_sl,
    input  wire        din_sy,
    input  wire [ 1:0] din_chn,
    input  wire        din_dv,
    input  wire        din_last,
    //
    input  wire [11:0] rd_section_id,
    //
    output logic  [63:0] m_axis_tdata,
    output wire [ 7:0] m_axis_tkeep,
    output wire        m_axis_tlast,
    output logic  [31:0] m_axis_tuser,
    output wire        m_axis_tvalid
);

  // Parameters

  // Write 1536 x 32-bit
  localparam int AddrWidthA = 11;
  localparam int DataWidthA = 32;

  // Read 768 x 64-bit
  localparam int AddrWidthB = 10;
  localparam int DataWidthB = 64;

  // Signals

  logic [  AddrWidthA:0] wr_cnt;
  logic [AddrWidthA-1:0] wr_addr;
  logic [   NUM_ANT-1:0] wr_we;
  logic [DataWidthA-1:0] wr_data;
  logic                  wr_done;
  logic [   NUM_ANT-1:0] wr_done_ch;

  logic [   NUM_ANT-1:0] ap_set;
  logic [   NUM_ANT-1:0] ap_req;
  logic [   NUM_ANT-1:0] ap_ack;

  logic                  rd_busy_n;
  logic [AddrWidthB-1:0] rd_addr;
  logic [   NUM_ANT-1:0] rd_en;
  logic [   NUM_ANT-1:0] rd_en_d;
  logic [   NUM_ANT-1:0] rd_en_dd;
  logic                  rd_en_any;
  logic [DataWidthB-1:0] rd_data           [NUM_ANT];
  logic [DataWidthB-1:0] rd_data_c;
  logic                  rd_done;

  // FSM

  typedef enum int {
    S_IDLE,  // wait for IQ symbol
    S_REQ,   // read c-plane buffer
    S_RUN    // sending u-plane packet
  } state_t;

  state_t state, state_next;

  // Main

  // RAM write @ clk

  always_ff @(posedge clk) begin
    if (din_sy && din_dv) begin
      wr_cnt <= '0;
    end else if (din_dv) begin
      wr_cnt <= wr_cnt + 1'b1;
    end
  end

  assign wr_addr = wr_cnt[AddrWidthA-1:0];

  generate
    for (genvar i = 0; i < NUM_ANT; i++) begin : g_wr_en

      always_ff @(posedge clk) begin
        if (din_sy && din_dv && (din_chn == i)) begin
          wr_we[i] <= 1'b1;
        end else if (wr_we[i] && (wr_cnt == 863)) begin
          wr_we[i] <= 1'b0;
        end
      end

      assign wr_done_ch[i] = wr_we[i] && (wr_cnt == 863);

    end
  endgenerate

  assign wr_done = |wr_done_ch;

  always_ff @(posedge clk) begin
    wr_data <= {din_di, din_dr};
  end

  // Delay the wr_done event for specific time

  generate
    for (genvar i = 0; i < NUM_ANT; i++) begin : g_pulse_delay

      always_ff @(posedge clk) begin
        ap_set[i] <= wr_done_ch[i];
      end

    end
  endgenerate

  // Rise the AP_REQ flag when one channel is written

  generate
    for (genvar i = 0; i < NUM_ANT; i++) begin : g_ap

      always_ff @(posedge clk) begin
        if (rst) begin
          ap_req[i] <= 1'b0;
        end else if (ap_set[i]) begin
          ap_req[i] <= 1'b1;
        end else if (ap_ack[i]) begin
          ap_req[i] <= 1'b0;
        end
      end

      // First channel first arbitor
      always_comb begin
        ap_ack[i] = ap_req[i] && rd_busy_n;
        for (int j = 0; j < i; j++) begin
          if (ap_req[j]) begin
            ap_ack[i] = 1'b0;
          end
        end
      end

    end
  endgenerate

  // The RAM, read latency is 2

  generate
    for (genvar ant = 0; ant < NUM_ANT; ant++) begin : g_ram

      ram_sdp_asym #(
          .ADDR_WIDTH_A (AddrWidthA),
          .DATA_WIDTH_A (DataWidthA),
          .ADDR_WIDTH_B (AddrWidthB),
          .DATA_WIDTH_B (DataWidthB),
          .READ_LATENCY_B(2)
      ) u_ram_sdp (
          .clka (clk),
          .wea  (wr_we[ant]),
          .addra(wr_addr),
          .dina (wr_data),
          //
          .clkb (clk),
          .rstb ({2'b0}),
          .enb  ({rd_en_d[ant], rd_en[ant]}),
          .addrb(rd_addr),
          .doutb(rd_data[ant])
      );

    end
  endgenerate

  // Read FSM

  always_ff @(posedge clk) begin
    if (rst) begin
      state <= S_IDLE;
    end else begin
      state <= state_next;
    end
  end

  always_comb begin
    state_next = state;

    case (state)
      S_IDLE: begin
        if (|ap_req) begin
          state_next = S_RUN;
        end
      end

      S_RUN: begin
        if (rd_done) begin
          state_next = S_IDLE;
        end
      end

      default: begin
        state_next = S_IDLE;
      end
    endcase
  end

  assign rd_busy_n = (state == S_IDLE);

  // Data read

  always_ff @(posedge clk) begin
    if (rst) begin
      rd_addr <= '0;
    end else if (state == S_RUN && rd_done) begin
      rd_addr <= '0;
    end else if (state == S_RUN) begin
      rd_addr <= rd_addr + 1'b1;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      rd_en_any <= 1'b0;
    end else if (|(ap_req & ap_ack)) begin
      rd_en_any <= 1'b1;
    end else if (rd_done) begin
      rd_en_any <= 1'b0;
    end
  end

  assign rd_done = (rd_addr == 431);

  generate
    for (genvar i = 0; i < NUM_ANT; i++) begin : g_rd_en

      always_ff @(posedge clk) begin
        if (rst) begin
          rd_en[i] <= 1'b0;
        end else if (ap_req[i] && ap_ack[i]) begin
          rd_en[i] <= 1'b1;
        end else if (rd_done) begin
          rd_en[i] <= 1'b0;
        end
      end

    end
  endgenerate

  always_ff @(posedge clk) begin
    rd_en_d  <= rd_en;
    rd_en_dd <= rd_en_d;
  end

  always_comb begin
    rd_data_c = '0;
    for (int i = 0; i < NUM_ANT; i++) begin
      rd_data_c = rd_data_c | ({rd_en_dd[i] ? rd_data[i] : 64'h0});
    end
  end

  // Output

  always_ff @(posedge clk) begin
    m_axis_tdata <= {
      rd_data_c[55:48],  //  Q1[7:0]
      rd_data_c[63:56],  //  Q1[15:8]
      rd_data_c[39:32],  //  I1[7:0]
      rd_data_c[47:40],  //  I1[15:8]
      rd_data_c[23:16],  //  Q0[7:0]
      rd_data_c[31:24],  //  Q0[15:8]
      rd_data_c[7:0],  //  I0[7:0]
      rd_data_c[15:8]  //  I0[15:8]
    };
  end

  assign m_axis_tkeep = '1;

  delay #(
      .WIDTH(1),
      .DEPTH(3),
      .INIT (1'b0)
  ) u_delay_tvalid (
      .clk (clk),
      .rst (1'b0),
      .cen (1'b1),
      .din (rd_done),
      .dout(m_axis_tlast)
  );

  delay #(
      .WIDTH(1),
      .DEPTH(3),
      .INIT (1'b0)
  ) u_delay_tlast (
      .clk (clk),
      .rst (1'b0),
      .cen (1'b1),
      .din (rd_en_any),
      .dout(m_axis_tvalid)
  );

  always_ff @(posedge clk) begin
    if (|(ap_req & ap_ack)) begin
      m_axis_tuser <= {8'b0, 4'(CC_ID), 8'(ANT_ID), rd_section_id};
    end
  end

  wire unused_framer_buffer = &{1'b0, din_sf, din_sl, din_last, wr_done};

endmodule

`default_nettype wire
