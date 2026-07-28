`timescale 1 ns / 1 ps
//
`default_nettype none

module xpm_fifo_axis #(
    parameter int    CASCADE_HEIGHT      = 0,
    parameter int    CDC_SYNC_STAGES     = 2,
    parameter string CLOCKING_MODE       = "common_clock",
    parameter string ECC_MODE            = "no_ecc",
    parameter int    FIFO_DEPTH          = 1024,
    parameter string FIFO_MEMORY_TYPE    = "auto",
    parameter string PACKET_FIFO         = "false",
    parameter int    PROG_EMPTY_THRESH   = 10,
    parameter int    PROG_FULL_THRESH    = 10,
    parameter int    RD_DATA_COUNT_WIDTH = 1,
    parameter int    RELATED_CLOCKS      = 0,
    parameter int    SIM_ASSERT_CHK      = 0,
    parameter int    TDATA_WIDTH         = 32,
    parameter int    TDEST_WIDTH         = 1,
    parameter int    TID_WIDTH           = 1,
    parameter int    TUSER_WIDTH         = 1,
    parameter string USE_ADV_FEATURES    = "0000",
    parameter int    WR_DATA_COUNT_WIDTH = 1
) (
    input  wire                           s_aclk,
    input  wire                           s_aresetn,
    input  wire [TDATA_WIDTH-1:0]         s_axis_tdata,
    input  wire [TDEST_WIDTH-1:0]         s_axis_tdest,
    input  wire [TID_WIDTH-1:0]           s_axis_tid,
    input  wire [(TDATA_WIDTH+7)/8-1:0]   s_axis_tkeep,
    input  wire                           s_axis_tlast,
    output wire                           s_axis_tready,
    input  wire [(TDATA_WIDTH+7)/8-1:0]   s_axis_tstrb,
    input  wire [TUSER_WIDTH-1:0]         s_axis_tuser,
    input  wire                           s_axis_tvalid,
    input  wire                           injectdbiterr_axis,
    input  wire                           injectsbiterr_axis,
    output wire [WR_DATA_COUNT_WIDTH-1:0] wr_data_count_axis,
    output wire                           almost_full_axis,
    output wire                           prog_full_axis,
    input  wire                           m_aclk,
    output wire [TDATA_WIDTH-1:0]         m_axis_tdata,
    output wire [TDEST_WIDTH-1:0]         m_axis_tdest,
    output wire [TID_WIDTH-1:0]           m_axis_tid,
    output wire [(TDATA_WIDTH+7)/8-1:0]   m_axis_tkeep,
    output wire                           m_axis_tlast,
    input  wire                           m_axis_tready,
    output wire [(TDATA_WIDTH+7)/8-1:0]   m_axis_tstrb,
    output wire [TUSER_WIDTH-1:0]         m_axis_tuser,
    output wire                           m_axis_tvalid,
    output wire [RD_DATA_COUNT_WIDTH-1:0] rd_data_count_axis,
    output wire                           almost_empty_axis,
    output wire                           prog_empty_axis,
    output wire                           sbiterr_axis,
    output wire                           dbiterr_axis
);

  assign s_axis_tready      = m_axis_tready && s_aresetn;
  assign m_axis_tdata       = s_axis_tdata;
  assign m_axis_tdest       = s_axis_tdest;
  assign m_axis_tid         = s_axis_tid;
  assign m_axis_tkeep       = s_axis_tkeep;
  assign m_axis_tlast       = s_axis_tlast;
  assign m_axis_tstrb       = s_axis_tstrb;
  assign m_axis_tuser       = s_axis_tuser;
  assign m_axis_tvalid      = s_axis_tvalid && s_aresetn;
  assign wr_data_count_axis = '0;
  assign almost_full_axis   = 1'b0;
  assign prog_full_axis     = 1'b0;
  assign rd_data_count_axis = '0;
  assign almost_empty_axis  = 1'b1;
  assign prog_empty_axis    = 1'b1;
  assign sbiterr_axis       = 1'b0;
  assign dbiterr_axis       = 1'b0;

  wire unused_xpm_fifo_axis = &{
    1'b0,
    32'(CASCADE_HEIGHT),
    32'(CDC_SYNC_STAGES),
    (CLOCKING_MODE == "common_clock"),
    (ECC_MODE == "no_ecc"),
    32'(FIFO_DEPTH),
    (FIFO_MEMORY_TYPE == "auto"),
    (PACKET_FIFO == "false"),
    32'(PROG_EMPTY_THRESH),
    32'(PROG_FULL_THRESH),
    32'(RELATED_CLOCKS),
    32'(SIM_ASSERT_CHK),
    (USE_ADV_FEATURES == "0000"),
    s_aclk,
    m_aclk,
    injectdbiterr_axis,
    injectsbiterr_axis
  };

endmodule

`default_nettype wire
