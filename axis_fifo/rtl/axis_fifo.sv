/*
 * AXI-Stream packet FIFO
 *
 * This FIFO is used to store AXI-Stream packets in the pipeline. This FIFO has
 * backward pressure on the input slave AXI-Stream.
 *
 * Note: `s_axis_aresetn` must be synchronized to `s_axis_aclk` before it
 * enters this core; it is only registered here, not synchronized. In
 * ASYNC_MODE the read-domain reset is derived with an internal reset
 * synchronizer.
 *
 * Note: If the FIFO is configured in packet mode and the input packet exceeds
 * the FIFO depth, the packet is dropped; the remaining beats are absorbed
 * until tlast and already-committed packets are preserved.
 */

`timescale 1 ns / 1 ps
//
`default_nettype none

module axis_fifo #(
    parameter int ASYNC_MODE   = 0,
    parameter int PACKET_MODE  = 0,
    parameter int FIFO_DEPTH   = 4096,
    parameter int FIFO_LATENCY = 3,
    parameter int DATA_WIDTH   = 32,
    parameter int USER_WIDTH   = 1
) (
    input var                                          s_axis_aclk,
    input var                                          s_axis_aresetn,
    //
    input var  [                       DATA_WIDTH-1:0] s_axis_tdata,
    input var  [                     DATA_WIDTH/8-1:0] s_axis_tkeep,
    input var                                          s_axis_tlast,
    input var  [(USER_WIDTH > 0 ? USER_WIDTH : 1)-1:0] s_axis_tuser,
    input var                                          s_axis_tvalid,
    output var                                         s_axis_tready,
    //
    input var                                          m_axis_aclk,
    //
    output var [                       DATA_WIDTH-1:0] m_axis_tdata,
    output var [                     DATA_WIDTH/8-1:0] m_axis_tkeep,
    output var                                         m_axis_tlast,
    output var [(USER_WIDTH > 0 ? USER_WIDTH : 1)-1:0] m_axis_tuser,
    output var                                         m_axis_tvalid,
    input var                                          m_axis_tready
);

  // Parameters

  localparam int UserWidthInt = (USER_WIDTH > 0) ? USER_WIDTH : 0;
  localparam int DataWidth = DATA_WIDTH + DATA_WIDTH / 8 + UserWidthInt + 1;
  localparam int AddrWidth = $clog2(FIFO_DEPTH);

  localparam logic OutputReg = (FIFO_LATENCY >= 2);
  localparam logic FabricReg = (FIFO_LATENCY >= 3);

  initial begin : drc_check
    assert (FIFO_DEPTH >= 4 && FIFO_DEPTH <= 32768)
    else $error("[%m]: FIFO_DEPTH (%0d) is outside of valid range 4-32768.", FIFO_DEPTH);

    assert ((FIFO_DEPTH & (FIFO_DEPTH - 1)) == 0)
    else $error("[%m]: FIFO_DEPTH (%0d) is not a power of 2.", FIFO_DEPTH);

    assert (FIFO_LATENCY >= 1 && FIFO_LATENCY <= 3)
    else $error("[%m]: FIFO_LATENCY (%0d) is outside of valid range 1-3.", FIFO_LATENCY);

    assert (DataWidth <= 4096)
    else $error("[%m]: Data width (%0d) is outside of valid range 0-4096.", DataWidth);

    assert ((DATA_WIDTH % 8) == 0)
    else $error("[%m]: DATA_WIDTH (%0d) is not a multiple of 8.", DATA_WIDTH);

    assert (USER_WIDTH >= 0 && USER_WIDTH <= 4096)
    else $error("[%m]: USER_WIDTH (%0d) is outside of valid range 0-4096.", USER_WIDTH);
  end

  // Signals

  wire                     wr_clk;
  logic                    wr_rstn;

  logic [     AddrWidth:0] wr_count;
  wire  [     AddrWidth:0] wr_count_rd;
  wire  [     AddrWidth:0] wr_count_next;
  logic [     AddrWidth:0] wr_count_reg;
  logic                    wr_full;
  logic                    pkt_drop;
  wire                     pkt_drop_decide;

  wire                     wr_en;
  wire  [   AddrWidth-1:0] wr_addr;
  wire  [   DataWidth-1:0] wr_din;

  wire                     rd_clk;
  wire                     rd_rstn;

  logic [     AddrWidth:0] rd_count;
  wire  [     AddrWidth:0] rd_count_wr;
  wire  [     AddrWidth:0] rd_count_next;

  wire  [FIFO_LATENCY-1:0] rd_en;
  wire  [   AddrWidth-1:0] rd_addr;
  wire  [   DataWidth-1:0] rd_dout;

  logic [  FIFO_LATENCY:0] valid;

  // Write pointer

  assign wr_clk = s_axis_aclk;

  always_ff @(posedge wr_clk) begin
    wr_rstn <= s_axis_aresetn;
  end

  always_ff @(posedge wr_clk) begin
    if (!wr_rstn) begin
      wr_count <= 'd0;
    end else if (pkt_drop_decide) begin
      // Discard the doomed packet's already-written beats.
      wr_count <= wr_count_reg;
    end else begin
      wr_count <= wr_count_next;
    end
  end

  assign wr_count_next = wr_en ? (wr_count + 1'd1) : wr_count;

  generate
    if (PACKET_MODE != 0) begin : g_packet_mode

      // Commit the write pointer when a packet is accepted
      always_ff @(posedge wr_clk) begin
        if (!wr_rstn) begin
          wr_count_reg <= 'd0;
        end else if (wr_en && s_axis_tlast) begin
          wr_count_reg <= wr_count_next;
        end
      end

      // Drop a packet once its uncommitted footprint fills the whole FIFO;
      // accepting more beats would deadlock because the packet can never be
      // committed.  On that cycle the write pointer is rolled back above and
      // the doomed packet's remaining beats are absorbed with tready high and
      // discarded until its tlast is seen.  The presented beat is refused by
      // wr_full here, so the packet is oversized whether or not that beat
      // carries tlast.
      assign pkt_drop_decide = !pkt_drop && s_axis_tvalid &&
                               ((wr_count - wr_count_reg) == FIFO_DEPTH[AddrWidth:0]);

      always_ff @(posedge wr_clk) begin
        if (!wr_rstn) begin
          pkt_drop <= 1'b0;
        end else if (pkt_drop) begin
          pkt_drop <= !(s_axis_tvalid && s_axis_tlast);
        end else begin
          pkt_drop <= pkt_drop_decide;
        end
      end

    end else begin : g_no_packet_mode

      always_comb begin
        wr_count_reg = wr_count;
      end

      assign pkt_drop = 1'b0;
      assign pkt_drop_decide = 1'b0;

    end
  endgenerate

  assign wr_en   = s_axis_tvalid && !wr_full && !pkt_drop;

  assign wr_addr = wr_count[AddrWidth-1:0];

  generate
    if (USER_WIDTH > 0) begin : g_wr_din_user
      assign wr_din = {s_axis_tuser, s_axis_tlast, s_axis_tkeep, s_axis_tdata};
    end else begin : g_wr_din_no_user
      wire unused_s_axis_tuser = &{1'b0, s_axis_tuser};
      assign wr_din = {s_axis_tlast, s_axis_tkeep, s_axis_tdata};
    end
  endgenerate

  assign s_axis_tready = !wr_full || pkt_drop;

  // Overflow guard: a write must never be accepted while the FIFO is really
  // full, otherwise the write pointer would overrun unread data.  Occupancy
  // uses the same (possibly stale) read pointer as the full flag, so this
  // only fires if the full prediction itself is wrong.
  assert property (@(posedge wr_clk) disable iff (!wr_rstn)
                   wr_en |-> ((wr_count - rd_count_wr) != FIFO_DEPTH[AddrWidth:0]))
  else $error("[%m]: overflow, write accepted while FIFO is full.");

  // The full flag `wr_full` is set when the write pointer catches up to the
  // read pointer. It can be computed as:
  //
  //   wr_full = (wr_count[AddrWidth-1:0] == rd_count_wr[AddrWidth-1:0]) &&
  //             (wr_count[AddrWidth] != rd_count_wr[AddrWidth])
  //
  // But we predict the value 1 clock cycle ahead to improve timing.
  always_ff @(posedge wr_clk) begin
    if (!wr_rstn) begin
      wr_full <= 1'b1;
    end else if ((wr_count_next[AddrWidth-1:0] == rd_count_wr[AddrWidth-1:0]) &&
      (wr_count_next[AddrWidth] != rd_count_wr[AddrWidth])) begin
      wr_full <= 1'b1;
    end else begin
      wr_full <= 1'b0;
    end
  end

  // Read pointer

  assign rd_clk = (ASYNC_MODE != 0) ? m_axis_aclk : s_axis_aclk;

  always_ff @(posedge rd_clk) begin
    if (!rd_rstn) begin
      rd_count <= 'd0;
    end else begin
      rd_count <= rd_count_next;
    end
  end

  assign rd_count_next = rd_en[0] ? (rd_count + 1'd1) : rd_count;

  assign rd_addr = rd_count[AddrWidth-1:0];

  assign m_axis_tvalid = valid[FIFO_LATENCY];

  // RAM read

  generate
    for (genvar i = 0; i < FIFO_LATENCY; i = i + 1) begin : g_rd_en
      assign rd_en[i] = valid[i] && (~&valid[FIFO_LATENCY:i+1] || m_axis_tready);
    end
  endgenerate

  // The valid flags

  generate
    for (genvar i = 0; i <= FIFO_LATENCY; i = i + 1) begin : g_valid

      if (i == 0) begin : g_first

        // `Valid[0]` marks there is valid at RAM
        always_ff @(posedge rd_clk) begin
          if (!rd_rstn) begin
            valid[0] <= 1'b0;
          end else if (rd_count_next == wr_count_rd) begin
            valid[0] <= 1'b0;
          end else begin
            valid[0] <= 1'b1;
          end
        end

      end else begin : g_left

        // Left `valid` marks if the data is valid at pipeline
        always_ff @(posedge rd_clk) begin
          if (!rd_rstn) begin
            valid[i] <= 1'b0;
          end else if (~&valid[FIFO_LATENCY:i] || m_axis_tready) begin
            valid[i] <= valid[i-1];
          end else begin
            valid[i] <= valid[i];
          end
        end

      end
    end
  endgenerate

  // Optional output register

  generate
    if (USER_WIDTH > 0) begin : g_unpack_user
      if (FabricReg == 0) begin : g_no_reg

        always_comb begin
          {m_axis_tuser, m_axis_tlast, m_axis_tkeep, m_axis_tdata} = rd_dout;
        end

      end else begin : g_reg

        always_ff @(posedge rd_clk) begin
          if (!rd_rstn) begin
            {m_axis_tuser, m_axis_tlast, m_axis_tkeep, m_axis_tdata} <= 'd0;
          end else if (rd_en[2]) begin
            {m_axis_tuser, m_axis_tlast, m_axis_tkeep, m_axis_tdata} <= rd_dout;
          end
        end

      end
    end else begin : g_unpack_no_user
      if (FabricReg == 0) begin : g_no_reg

        always_comb begin
          m_axis_tuser = 'd0;
          {m_axis_tlast, m_axis_tkeep, m_axis_tdata} = rd_dout;
        end

      end else begin : g_reg

        always_ff @(posedge rd_clk) begin
          if (!rd_rstn) begin
            m_axis_tuser <= 'd0;
            {m_axis_tlast, m_axis_tkeep, m_axis_tdata} <= 'd0;
          end else if (rd_en[2]) begin
            m_axis_tuser <= 'd0;
            {m_axis_tlast, m_axis_tkeep, m_axis_tdata} <= rd_dout;
          end
        end

      end
    end
  endgenerate

  // The Dual-Port RAM

  ram_sdp #(
      .ADDR_WIDTH  (AddrWidth),
      .DATA_WIDTH  (DataWidth),
      .READ_LATENCY(OutputReg + 1),
      .INIT_FILE   ("NONE")
  ) i_ram (
      .clka (wr_clk),
      .wea  (wr_en),
      .addra(wr_addr),
      .dina (wr_din),
      //
      .clkb (rd_clk),
      .rstb (!rd_rstn),
      .enb  (rd_en[OutputReg:0]),
      .addrb(rd_addr),
      .doutb(rd_dout)
  );

  generate
    if (ASYNC_MODE != 0) begin : g_async_cdc

      // Reset synchronization

      cdc_async_rst #(
          .DEST_SYNC_FF   (4),
          .INIT_SYNC_FF   (0),
          .RST_ACTIVE_HIGH(0)
      ) i_rd_rst (
          .src_arst (s_axis_aresetn),
          .dest_clk (rd_clk),
          .dest_arst(rd_rstn)
      );

      // Write / read domain gray code CDC

      cdc_gray #(
          .DEST_SYNC_FF(4),
          .INIT_SYNC_FF(0),
          .REG_OUTPUT  (1),
          .WIDTH       (AddrWidth + 1)
      ) i_wr2rd_gray (
          .src_clk     (wr_clk),
          .src_in_bin  (wr_count_reg),
          //
          .dest_clk    (rd_clk),
          .dest_out_bin(wr_count_rd)
      );

      cdc_gray #(
          .DEST_SYNC_FF(4),
          .INIT_SYNC_FF(0),
          .REG_OUTPUT  (1),
          .WIDTH       (AddrWidth + 1)
      ) i_rd2wr_gray (
          .src_clk     (rd_clk),
          .src_in_bin  (rd_count),
          //
          .dest_clk    (wr_clk),
          .dest_out_bin(rd_count_wr)
      );

    end else begin : g_no_cdc

      assign rd_rstn = wr_rstn;

      assign wr_count_rd = wr_count_reg;

      assign rd_count_wr = rd_count;

    end
  endgenerate

endmodule

`default_nettype wire
