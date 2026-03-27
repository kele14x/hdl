`timescale 1 ns / 1 ps
//
`default_nettype none

module fh_framer_32to64 #(
    parameter integer FIFO_DEPTH   = 4096,
    parameter integer FIFO_LATENCY = 3,
    parameter integer USER_WIDTH   = 18
) (
    input  wire                  clk,
    input  wire                  rst,
    //
    input  wire [          31:0] s_axis_tdata,
    input  wire [           3:0] s_axis_tkeep,
    input  wire                  s_axis_tlast,
    input  wire [USER_WIDTH-1:0] s_axis_tuser,
    input  wire                  s_axis_tvalid,
    output wire                  s_axis_tready,
    //
    input  wire                  tx_eth_clk,
    input  wire                  tx_eth_rst,
    //
    output wire [          63:0] m_axis_tdata,
    output wire [           7:0] m_axis_tkeep,
    output wire                  m_axis_tlast,
    output wire [USER_WIDTH-1:0] m_axis_tuser,
    output wire                  m_axis_tvalid,
    input  wire                  m_axis_tready
);

  wire [          63:0] s0_axis_tdata;
  wire [           7:0] s0_axis_tkeep;
  wire                  s0_axis_tlast;
  wire                  s0_axis_tvalid;
  wire                  s0_axis_tready;

  reg                   sync_n;

  fh_framer_axis_dwc i_dwc (
      .aclk         (clk),
      .aresetn      (!rst),
      //
      .s_axis_tdata (s_axis_tdata),
      .s_axis_tkeep (s_axis_tkeep),
      .s_axis_tlast (s_axis_tlast),
      .s_axis_tvalid(s_axis_tvalid),
      .s_axis_tready(s_axis_tready),
      //
      .m_axis_tdata (s0_axis_tdata),
      .m_axis_tkeep (s0_axis_tkeep),
      .m_axis_tlast (s0_axis_tlast),
      .m_axis_tvalid(s0_axis_tvalid),
      .m_axis_tready(s0_axis_tready)
  );

  always @(posedge clk) begin
    if (rst) begin
      sync_n <= 1'b0;
    end else if (s_axis_tvalid && s_axis_tready && s_axis_tlast) begin
      sync_n <= 1'b0;
    end else if (s_axis_tvalid && s_axis_tready) begin
      sync_n <= 1'b1;
    end
  end

  fifo_async #(
      .FIFO_DEPTH  (512),
      .FIFO_LATENCY(3),
      .DATA_WIDTH  (USER_WIDTH)
  ) i_tuser_fifo (
      // Common to write and read domain
      .rst     (rst),
      // Write interface
      .wr_clk  (clk),
      .wr_en   (~sync_n && s_axis_tvalid && s_axis_tready),
      .wr_din  (s_axis_tuser),
      .wr_full (),
      // Read interface
      .rd_clk  (tx_eth_clk),
      .rd_en   (m_axis_tvalid && m_axis_tready && m_axis_tlast),
      .rd_dout (m_axis_tuser),
      .rd_empty()
  );

  axis_fifo #(
      .ASYNC_MODE  (1'b1),
      .PACKET_MODE (1'b1),
      .FIFO_DEPTH  (FIFO_DEPTH),
      .FIFO_LATENCY(FIFO_LATENCY),
      .DATA_WIDTH  (64),
      .USER_WIDTH  (1)
  ) i_axis_fifo (
      .s_axis_aclk   (clk),
      .s_axis_aresetn(!rst),
      //
      .s_axis_tdata  (s0_axis_tdata),
      .s_axis_tkeep  (s0_axis_tkeep),
      .s_axis_tlast  (s0_axis_tlast),
      .s_axis_tuser  (1'b0),
      .s_axis_tvalid (s0_axis_tvalid),
      .s_axis_tready (s0_axis_tready),
      //
      .m_axis_aclk   (tx_eth_clk),
      //
      .m_axis_tdata  (m_axis_tdata),
      .m_axis_tkeep  (m_axis_tkeep),
      .m_axis_tlast  (m_axis_tlast),
      .m_axis_tuser  (  /* not used */),
      .m_axis_tvalid (m_axis_tvalid),
      .m_axis_tready (m_axis_tready)
  );

endmodule

`default_nettype wire
