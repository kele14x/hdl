`timescale 1ns / 1ps
//
`default_nettype none

module fh_deframer_64to32 #(
    parameter integer FIFO_DEPTH   = 4096,
    parameter integer FIFO_LATENCY = 3,
    parameter integer USER_WIDTH   = 80
) (
    input  wire        clk,
    input  wire        rst,
    //
    input  wire [63:0] s_axis_tdata,
    input  wire [ 7:0] s_axis_tkeep,
    input  wire        s_axis_tlast,
    input  wire [79:0] s_axis_tuser,
    input  wire        s_axis_tvalid,
    //
    output wire [31:0] m_axis_tdata,
    output wire [ 3:0] m_axis_tkeep,
    output wire        m_axis_tlast,
    output wire [79:0] m_axis_tuser,
    output wire        m_axis_tvalid,
    input  wire        m_axis_tready
);

  reg         sync_n;

  wire [63:0] s0_axis_tdata;
  wire [ 7:0] s0_axis_tkeep;
  wire        s0_axis_tlast;
  wire        s0_axis_tvalid;
  wire        s0_axis_tready;

  always @(posedge clk) begin
    if (rst) begin
      sync_n <= 1'b0;
    end else if (s_axis_tvalid && s_axis_tlast) begin
      sync_n <= 1'b0;
    end else if (s_axis_tvalid) begin
      sync_n <= 1'b1;
    end
  end

  axis_fifo_alt #(
      .ASYNC_MODE  (0),
      .FIFO_DEPTH  (FIFO_DEPTH),
      .FIFO_LATENCY(FIFO_LATENCY),
      .DATA_WIDTH  (64),
      .USER_WIDTH  (1'b0)
  ) i_axis_fifo (
      .s_axis_aclk   (clk),
      .s_axis_aresetn(!rst),
      //
      .s_axis_tdata  (s_axis_tdata),
      .s_axis_tkeep  (s_axis_tkeep),
      .s_axis_tlast  (s_axis_tlast),
      .s_axis_tuser  ('b0),
      .s_axis_tvalid (s_axis_tvalid),
      //
      .m_axis_aclk   (clk),
      //
      .m_axis_tdata  (s0_axis_tdata),
      .m_axis_tkeep  (s0_axis_tkeep),
      .m_axis_tlast  (s0_axis_tlast),
      .m_axis_tuser  (  /* not used */),
      .m_axis_tvalid (s0_axis_tvalid),
      .m_axis_tready (s0_axis_tready),
      //
      .err_discard   ()
  );

  fh_deframer_axis_dwc i_dwc (
      .aclk         (clk),
      .aresetn      (!rst),
      //
      .s_axis_tdata (s0_axis_tdata),
      .s_axis_tkeep (s0_axis_tkeep),
      .s_axis_tlast (s0_axis_tlast),
      .s_axis_tvalid(s0_axis_tvalid),
      .s_axis_tready(s0_axis_tready),
      //
      .m_axis_tdata (m_axis_tdata),
      .m_axis_tkeep (m_axis_tkeep),
      .m_axis_tlast (m_axis_tlast),
      .m_axis_tvalid(m_axis_tvalid),
      .m_axis_tready(m_axis_tready)
  );

  fifo_sync #(
      .FIFO_DEPTH  (FIFO_DEPTH / 8),
      .FIFO_LATENCY(2),
      .DATA_WIDTH  (80)
  ) i_fifo_sync (
      .clk  (clk),
      .rst  (rst),
      //
      .wren (~sync_n && s_axis_tvalid),
      .din  (s_axis_tuser),
      .full (  /* assume never full */),
      //
      .rden (m_axis_tvalid && m_axis_tready && m_axis_tlast),
      .dout (m_axis_tuser),
      .empty(  /* not used */)
  );

endmodule

`default_nettype wire
