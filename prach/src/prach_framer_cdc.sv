`timescale 1 ns / 1 ps
//
`default_nettype none

module prach_framer_cdc (
    input var          clk_dsp,
    input var          rst_dsp_n,
    //
    input var  [ 63:0] avst_sink_data,
    input var          avst_sink_valid,
    input var          avst_sink_startofpacket,
    input var          avst_sink_endofpacket,
    output var         avst_sink_ready,
    // ORAN
    //-----
    input var          clk_eth_xran,
    input var          rst_eth_xran_n,
    //
    output var [127:0] avst_source_u_data,
    output var         avst_source_u_valid,
    output var         avst_source_u_startofpacket,
    output var         avst_source_u_endofpacket,
    input var          avst_source_u_ready,
    // ORAN sideband
    output var [ 15:0] tx_u_size,
    //
    output var [ 15:0] tx_u_pc_id,
    output var [ 15:0] tx_u_seq_id,
    //
    output var         tx_u_dataDirection,
    output var [  2:0] tx_u_payloadVersion,
    output var [  3:0] tx_u_filterIndex,
    output var [  7:0] tx_u_frameId,
    output var [  3:0] tx_u_subframeId,
    output var [  5:0] tx_u_slotID,
    output var [  5:0] tx_u_symbolid,
    //
    output var [ 11:0] tx_u_sectionId,
    output var         tx_u_rb,
    output var         tx_u_symInc,
    output var [  9:0] tx_u_startPrb,
    output var [  7:0] tx_u_numPrb,
    //
    output var [  7:0] tx_u_udCompHdr
);

  localparam int FifoWidth = 66;
  localparam int FifoDepth = 2048;

  // FIFO

  logic [FifoWidth-1:0] fifo_wr_data;
  logic                 fifo_wr_req;
  logic                 fifo_wr_full;

  logic [FifoWidth-1:0] fifo_rd_data;
  logic                 fifo_rd_empty;
  logic                 fifo_rd_req;

  assign fifo_wr_data = {6'b0, avst_sink_endofpacket, avst_sink_startofpacket, avst_sink_data};

  assign fifo_wr_req = avst_sink_valid;
  assign avst_sink_ready = ~fifo_wr_full;

  // 2k x 64
  dcfifo #(
      .lpm_width    (FifoWidth),
      .lpm_numwords (FifoDepth),
      .lpm_showahead("ON"),
      .lpm_widthu   (11)
  ) u_data_fifo (
      .aclr     (1'b0),
      .eccstatus(  /* not used */),
      // Write
      .wrclk    (clk_dsp),
      .wrreq    (fifo_wr_req),
      .data     (fifo_wr_data),
      .wrempty  (  /* not used */),
      .wrfull   (fifo_wr_full),
      .wrusedw  (  /* not used */),
      // Read
      .rdclk    (clk_eth_xran),
      .rdreq    (fifo_rd_req),
      .q        (fifo_rd_data),
      .rdempty  (fifo_rd_empty),
      .rdfull   (),
      .rdusedw  ()
  );


  // Move header data to side band

  typedef enum int {
    S_RST,
    S_HEAD1,
    S_HEAD2,
    S_HEAD3,
    S_DATA
  } state_t;

  state_t state, state_next;

  logic [63:0] header_r1;
  logic [63:0] header_r2;
  logic [63:0] header_r3;

  always_ff @(posedge clk_eth_xran) begin
    if (~rst_eth_xran_n) begin
      state <= S_RST;
    end else begin
      state <= state_next;
    end
  end

  always_comb begin
    state_next = state;
    case (state)
      S_RST: state_next = S_HEAD1;

      S_HEAD1: if (~fifo_rd_empty) state_next = S_HEAD2;

      S_HEAD2: if (~fifo_rd_empty) state_next = S_HEAD3;

      S_HEAD2: if (~fifo_rd_empty) state_next = S_DATA;

      S_DATA: begin
        if (~fifo_rd_empty && avst_source_u_ready && avst_source_u_endofpacket)
          state_next = S_HEAD1;
      end

      default: state_next = S_RST;
    endcase
  end

  assign fifo_rd_req = state == S_RST   ? 1'b0 :
                       state == S_HEAD1 ? 1'b1 :
                       state == S_HEAD2 ? 1'b1 :
                       state == S_HEAD3 ? 1'b1 : avst_source_u_ready;

  always_ff @(posedge clk_dsp) begin
    if (state == S_HEAD1 && ~fifo_rd_empty) begin
      header_r1 <= fifo_rd_data[63:0];
    end
  end

  always_ff @(posedge clk_dsp) begin
    if (state == S_HEAD2 && ~fifo_rd_empty) begin
      header_r2 <= fifo_rd_data[63:0];
    end
  end

  always_ff @(posedge clk_dsp) begin
    if (state == S_HEAD3 && ~fifo_rd_empty) begin
      header_r3 <= fifo_rd_data[63:0];
    end
  end

  assign {tx_u_size, tx_u_pc_id, tx_u_seq_id} = header_r1[47:0];

  assign {
      tx_u_dataDirection,
      tx_u_payloadVersion,
      tx_u_filterIndex,
      tx_u_frameId,
      tx_u_subframeId,
      tx_u_slotID,
      tx_u_symbolid
  } = header_r2[31:0];

  assign {
      tx_u_sectionId,
      tx_u_rb,
      tx_u_symInc,
      tx_u_startPrb,
      tx_u_numPrb,
      tx_u_udCompHdr
  } = header_r3[39:0];

  // TODO: this may not be correct
  generate
    for (genvar i = 0; i < 4; i++) begin : g_u_data
      assign avst_source_u_data[i*32+31-:32] = {
        {16{fifo_rd_data[i*16+15]}}, fifo_rd_data[i*16+15-:16]
      };
    end
  endgenerate

  assign avst_source_u_valid = (state == S_DATA) && ~fifo_rd_empty;

  assign avst_source_u_startofpacket = fifo_rd_data[64];

  assign avst_source_u_endofpacket = fifo_rd_data[65];

endmodule

`default_nettype wire
