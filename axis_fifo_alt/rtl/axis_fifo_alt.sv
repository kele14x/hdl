/*
 * AXI-Stream FIFO with alternate implementation
 *
 * Unlike normal AXIS FIFO (axis_fifo), this FIFO only supports packet mode,
 * it will store and forward the packet. And this FIFO does not support
 * backward pressure on the slave interface. If the FIFO is full, it will
 * discard the entire packet.
 */

`timescale 1 ns / 1 ps
//
`default_nettype none

module axis_fifo_alt #(
    parameter logic     ASYNC_MODE   = 1'b0,
    parameter integer FIFO_DEPTH   = 4096,
    parameter integer FIFO_LATENCY = 3,
    parameter integer DATA_WIDTH   = 32,
    parameter integer USER_WIDTH   = 1
) (
    input  wire                                         s_axis_aclk,
    input  wire                                         s_axis_aresetn,
    //
    input  wire [                       DATA_WIDTH-1:0] s_axis_tdata,
    input  wire [                     DATA_WIDTH/8-1:0] s_axis_tkeep,
    input  wire                                         s_axis_tlast,
    input  wire [(USER_WIDTH > 0 ? USER_WIDTH : 1)-1:0] s_axis_tuser,
    input  wire                                         s_axis_tvalid,
    //
    input  wire                                         m_axis_aclk,
    //
    output logic  [                       DATA_WIDTH-1:0] m_axis_tdata,
    output logic  [                     DATA_WIDTH/8-1:0] m_axis_tkeep,
    output logic                                          m_axis_tlast,
    output logic  [(USER_WIDTH > 0 ? USER_WIDTH : 1)-1:0] m_axis_tuser,
    output wire                                         m_axis_tvalid,
    input  wire                                         m_axis_tready,
    //
    output wire                                         err_discard
);

  // Parameters

  localparam integer UserWidthInt = (USER_WIDTH > 0) ? USER_WIDTH : 0;
  // Data width = tdata + tkeep + tlast + tuser
  localparam integer DataWidth = DATA_WIDTH + DATA_WIDTH / 8 + 1 + UserWidthInt;
  localparam integer AddrWidth = $clog2(FIFO_DEPTH);

  localparam logic OutputReg = (FIFO_LATENCY >= 2);
  localparam logic FabricReg = (FIFO_LATENCY >= 3);

  initial begin
    // Check FIFO depth
    if ((FIFO_DEPTH < 4) || (32768 < FIFO_DEPTH)) begin
      $display("ERROR: FIFO_DEPTH (%0d) is outside of valid range 4-32768. [%m]", FIFO_DEPTH);
      $finish();
    end

    // Check FIFO depth is a power of 2
    if ((FIFO_DEPTH & (FIFO_DEPTH - 1)) != 0) begin
      $display("ERROR: FIFO_DEPTH (%0d) is not a power of 2. [%m]", FIFO_DEPTH);
      $finish();
    end

    // Check input FIFO latency
    if ((FIFO_LATENCY < 1) || (3 < FIFO_LATENCY)) begin
      $display("ERROR: FIFO_LATENCY (%0d) is outside of valid range 1-3. [%m]", FIFO_LATENCY);
      $finish();
    end

    // Check data width
    if (DataWidth < 0 || DataWidth > 4096) begin
      $display("ERROR: Data width (%0d) is outside of valid range 0-4096. [%m]", DataWidth);
      $finish();
    end

    // Check data width is multiple of 8
    if (DATA_WIDTH % 8 != 0) begin
      $display("ERROR: DATA_WIDTH (%0d) is not a multiple of 8. [%m]", DATA_WIDTH);
      $finish();
    end

    // Check user width
    if (USER_WIDTH < 0 || USER_WIDTH > 4096) begin
      $display("ERROR: User width (%0d) is outside of valid range 0-4096. [%m]", USER_WIDTH);
      $finish();
    end
  end

  // Signals

  wire                    wr_clk;
  logic                     wr_rstn;

  logic                     wr_sync_n;
  logic  [     AddrWidth:0] wr_count;
  wire [     AddrWidth:0] wr_count_rd;
  logic  [     AddrWidth:0] wr_count_next;
  logic  [     AddrWidth:0] wr_count_reg;
  logic  [     AddrWidth:0] wr_count_last;
  logic                     wr_discard;
  logic                     wr_full;

  wire                    wr_en;
  wire [   AddrWidth-1:0] wr_addr;
  wire [   DataWidth-1:0] wr_din;

  wire                    rd_clk;
  wire                    rd_rstn;

  logic  [     AddrWidth:0] rd_count;
  wire [     AddrWidth:0] rd_count_wr;
  wire [     AddrWidth:0] rd_count_next;

  wire [FIFO_LATENCY-1:0] rd_en;
  wire [   AddrWidth-1:0] rd_addr;
  wire [   DataWidth-1:0] rd_dout;

  logic  [  FIFO_LATENCY:0] valid;

  genvar i;

  // Write side

  assign wr_clk = s_axis_aclk;

  always_ff @(posedge wr_clk) begin
    wr_rstn <= s_axis_aresetn;
  end

  // Synchronize the first word of the packet
  always_ff @(posedge wr_clk) begin
    if (!wr_rstn) begin
      wr_sync_n <= 1'b0;
    end else if (s_axis_tvalid && s_axis_tlast) begin
      wr_sync_n <= 1'b0;
    end else if (s_axis_tvalid) begin
      wr_sync_n <= 1'b1;
    end
  end

  // Write pointer

  always_ff @(posedge wr_clk) begin
    if (!wr_rstn) begin
      wr_count <= 'd0;
    end else begin
      wr_count <= wr_count_next;
    end
  end

  // Revert the write pointer if client tries to write to a full FIFO
  always_comb begin
    if (s_axis_tvalid && wr_discard) begin
      wr_count_next = wr_count;
    end else if (s_axis_tvalid && wr_full) begin
      wr_count_next = wr_count_last;
    end else if (s_axis_tvalid) begin
      wr_count_next = wr_count + 1'b1;
    end else begin
      wr_count_next = wr_count;
    end
  end

  // Log the last write pointer
  always_ff @(posedge wr_clk) begin
    if (!wr_rstn) begin
      wr_count_last <= 'd0;
    end else if (s_axis_tvalid && !wr_sync_n) begin
      wr_count_last <= wr_count;
    end
  end

  // Commit the write pointer when a packet is accepted
  always_ff @(posedge wr_clk) begin
    if (!wr_rstn) begin
      wr_count_reg <= 'd0;
    end else if (s_axis_tvalid && s_axis_tlast && !wr_full && !wr_discard) begin
      wr_count_reg <= (wr_count + 1'b1);
    end
  end

  // Discard the packet if the FIFO is full
  always_ff @(posedge wr_clk) begin
    if (!wr_rstn) begin
      wr_discard <= 1'b0;
    end else if (s_axis_tvalid && s_axis_tlast) begin
      wr_discard <= 1'b0;
    end else if (s_axis_tvalid && wr_full) begin
      wr_discard <= 1'b1;
    end
  end

  assign wr_en   = s_axis_tvalid && !wr_full && !wr_discard;

  assign wr_addr = wr_count[AddrWidth-1:0];

  generate
    if (USER_WIDTH > 0) begin : g_wr_din_user
      assign wr_din  = {s_axis_tuser, s_axis_tlast, s_axis_tkeep, s_axis_tdata};
    end else begin : g_wr_din_no_user
      wire unused_s_axis_tuser = &{1'b0, s_axis_tuser};
      assign wr_din  = {s_axis_tlast, s_axis_tkeep, s_axis_tdata};
    end
  endgenerate

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

  assign err_discard = s_axis_tvalid && wr_full;

  // Read side

  assign rd_clk = ASYNC_MODE ? m_axis_aclk : s_axis_aclk;

  // Read pointer

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
    for (i = 0; i < FIFO_LATENCY; i = i + 1) begin : g_rd_en
      assign rd_en[i] = valid[i] && (~&valid[FIFO_LATENCY:i+1] || m_axis_tready);
    end
  endgenerate

  // The valid flags

  generate
    for (i = 0; i <= FIFO_LATENCY; i = i + 1) begin : g_valid

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

  // The buffer RAM

  ram_sdp #(
      .ADDR_WIDTH  (AddrWidth),
      .DATA_WIDTH  (DataWidth),
      .READ_LATENCY(OutputReg + 1),
      .INIT_WORD   (0),
      .INIT_FILE   ("")
  ) i_ram (
      .clka (wr_clk),
      .ena  (wr_en),
      .wea  (wr_en),
      .addra(wr_addr),
      .dina (wr_din),
      //
      .clkb (rd_clk),
      .rstb ({(OutputReg + 1) {!rd_rstn}}),
      .enb  (rd_en[OutputReg:0]),
      .addrb(rd_addr),
      .doutb(rd_dout)
  );

  generate
    if (ASYNC_MODE) begin : g_async_cdc

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
