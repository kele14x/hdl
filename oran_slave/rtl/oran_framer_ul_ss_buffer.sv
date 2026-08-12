// File: oran_framer_ul_ss_buffer.sv
// Brief: UL packet is write into this buffer, and then write out packet by
//        packet.
// TODO: Using BRAM instread of FIFO to control packet output time
`timescale 1 ns / 1 ps
//
`default_nettype none

module oran_framer_ul_ss_buffer #(
    parameter int BUFFER_SIZE = 1024
) (
    input var         clk,
    input var         rst,
    //
    output var [63:0] m_axis_tdata,
    output var [ 7:0] m_axis_tkeep,
    output var        m_axis_tvalid,
    output var        m_axis_tlast,
    input var         m_axis_tready,
    //
    input var  [63:0] s_axis_tdata,
    input var  [ 7:0] s_axis_tkeep,
    input var         s_axis_tvalid,
    input var         s_axis_tlast
);

  localparam int FifoDepth = BUFFER_SIZE;

  logic [$clog2(FifoDepth):0] fifo_wr_data_count;
  logic [$clog2(FifoDepth):0] fifo_rd_data_count;
  logic fifo_s_axis_tready;
  logic fifo_almost_full;
  logic fifo_prog_full;
  logic fifo_m_axis_tdest;
  logic fifo_m_axis_tid;
  logic [7:0] fifo_m_axis_tstrb;
  logic fifo_m_axis_tuser;
  logic fifo_almost_empty;
  logic fifo_prog_empty;
  logic fifo_sbiterr;
  logic fifo_dbiterr;

  wire unused_fifo_outputs = &{
    1'b0,
    fifo_wr_data_count,
    fifo_rd_data_count,
    fifo_s_axis_tready,
    fifo_almost_full,
    fifo_prog_full,
    fifo_m_axis_tdest,
    fifo_m_axis_tid,
    fifo_m_axis_tstrb,
    fifo_m_axis_tuser,
    fifo_almost_empty,
    fifo_prog_empty,
    fifo_sbiterr,
    fifo_dbiterr
  };

`ifdef XILINX
  xpm_fifo_axis #(
      .CASCADE_HEIGHT     (0),
      .CDC_SYNC_STAGES    (2),
      .CLOCKING_MODE      ("common_clock"),
      .ECC_MODE           ("no_ecc"),
      .FIFO_DEPTH         (FifoDepth),
      .FIFO_MEMORY_TYPE   ("block"),
      .PACKET_FIFO        ("true"),
      .PROG_EMPTY_THRESH  (10),
      .PROG_FULL_THRESH   (10),
      .RD_DATA_COUNT_WIDTH($clog2(FifoDepth) + 1),
      .RELATED_CLOCKS     (0),
      .SIM_ASSERT_CHK     (0),
      .TDATA_WIDTH        (64),
      .TDEST_WIDTH        (1),
      .TID_WIDTH          (1),
      .TUSER_WIDTH        (1),
      .USE_ADV_FEATURES   ("0808"),                 // required by packet FIFO
      .WR_DATA_COUNT_WIDTH($clog2(FifoDepth) + 1)
  ) xpm_fifo_axis_inst (
      .s_aclk            (clk),
      .s_aresetn         (~rst),
      .s_axis_tdata      (s_axis_tdata),
      .s_axis_tdest      ('0),
      .s_axis_tid        ('0),
      .s_axis_tkeep      (s_axis_tkeep),
      .s_axis_tlast      (s_axis_tlast),
      .s_axis_tstrb      (s_axis_tkeep),
      .s_axis_tuser      ('0),
      .s_axis_tvalid     (s_axis_tvalid),
      .s_axis_tready     (fifo_s_axis_tready),
      //
      .injectdbiterr_axis(1'b0),
      .injectsbiterr_axis(1'b0),
      .wr_data_count_axis(fifo_wr_data_count),
      .almost_full_axis  (fifo_almost_full),
      .prog_full_axis    (fifo_prog_full),
      //
      //
      .m_aclk            (clk),
      .m_axis_tdata      (m_axis_tdata),
      .m_axis_tdest      (fifo_m_axis_tdest),
      .m_axis_tid        (fifo_m_axis_tid),
      .m_axis_tkeep      (m_axis_tkeep),
      .m_axis_tlast      (m_axis_tlast),
      .m_axis_tready     (m_axis_tready),
      .m_axis_tstrb      (fifo_m_axis_tstrb),
      .m_axis_tuser      (fifo_m_axis_tuser),
      .m_axis_tvalid     (m_axis_tvalid),
      .rd_data_count_axis(fifo_rd_data_count),
      .almost_empty_axis (fifo_almost_empty),
      .prog_empty_axis   (fifo_prog_empty),
      .sbiterr_axis      (fifo_sbiterr),
      .dbiterr_axis      (fifo_dbiterr)
      //
      //
  );
`else
  axis_fifo #(
      .ASYNC_MODE  (0),
      .PACKET_MODE (1),
      .FIFO_DEPTH  (FifoDepth),
      .FIFO_LATENCY(3),
      .DATA_WIDTH  (64),
      .USER_WIDTH  (0)
  ) axis_fifo_inst (
      .s_axis_aclk   (clk),
      .s_axis_aresetn(~rst),
      .s_axis_tdata  (s_axis_tdata),
      .s_axis_tkeep  (s_axis_tkeep),
      .s_axis_tlast  (s_axis_tlast),
      .s_axis_tuser  ('0),
      .s_axis_tvalid (s_axis_tvalid),
      .s_axis_tready (fifo_s_axis_tready),
      .m_axis_aclk   (clk),
      .m_axis_tdata  (m_axis_tdata),
      .m_axis_tkeep  (m_axis_tkeep),
      .m_axis_tlast  (m_axis_tlast),
      .m_axis_tuser  (fifo_m_axis_tuser),
      .m_axis_tvalid (m_axis_tvalid),
      .m_axis_tready (m_axis_tready)
  );

  assign fifo_wr_data_count = '0;
  assign fifo_rd_data_count = '0;
  assign fifo_almost_full   = 1'b0;
  assign fifo_prog_full     = 1'b0;
  assign fifo_m_axis_tdest  = 1'b0;
  assign fifo_m_axis_tid    = 1'b0;
  assign fifo_m_axis_tstrb  = '0;
  assign fifo_almost_empty  = 1'b1;
  assign fifo_prog_empty    = 1'b1;
  assign fifo_sbiterr       = 1'b0;
  assign fifo_dbiterr       = 1'b0;
`endif

endmodule

`default_nettype wire
