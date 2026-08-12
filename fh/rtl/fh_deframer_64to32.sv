`timescale 1ns / 1ps
//
`default_nettype none

module fh_deframer_64to32 #(
    parameter int FIFO_DEPTH   = 4096,
    parameter int FIFO_LATENCY = 3,
    parameter int USER_WIDTH   = 80
) (
    input var                   clk,
    input var                   rst,
    //
    input var  [          63:0] s_axis_tdata,
    input var  [           7:0] s_axis_tkeep,
    input var                   s_axis_tlast,
    input var  [USER_WIDTH-1:0] s_axis_tuser,
    input var                   s_axis_tvalid,
    //
    output var [          31:0] m_axis_tdata,
    output var [           3:0] m_axis_tkeep,
    output var                  m_axis_tlast,
    output var [USER_WIDTH-1:0] m_axis_tuser,
    output var                  m_axis_tvalid,
    input var                   m_axis_tready
);

  logic sync_n;

  wire axis_fifo_tuser;
  wire axis_fifo_err_discard;
  wire tuser_fifo_full;
  wire tuser_fifo_empty;
  wire        unused_fifo_status = &{1'b0, axis_fifo_tuser, axis_fifo_err_discard, tuser_fifo_full, tuser_fifo_empty};

  wire [63:0] s0_axis_tdata;
  wire [7:0] s0_axis_tkeep;
  wire s0_axis_tlast;
  wire s0_axis_tvalid;
  wire s0_axis_tready;

  always_ff @(posedge clk) begin
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
      .USER_WIDTH  (0)
  ) i_axis_fifo (
      .s_axis_aclk   (clk),
      .s_axis_aresetn(!rst),
      //
      .s_axis_tdata  (s_axis_tdata),
      .s_axis_tkeep  (s_axis_tkeep),
      .s_axis_tlast  (s_axis_tlast),
      .s_axis_tuser  (1'b0),
      .s_axis_tvalid (s_axis_tvalid),
      //
      .m_axis_aclk   (clk),
      //
      .m_axis_tdata  (s0_axis_tdata),
      .m_axis_tkeep  (s0_axis_tkeep),
      .m_axis_tlast  (s0_axis_tlast),
      .m_axis_tuser  (axis_fifo_tuser),
      .m_axis_tvalid (s0_axis_tvalid),
      .m_axis_tready (s0_axis_tready),
      //
      .err_discard   (axis_fifo_err_discard)
  );

  assign s0_axis_tready = m_axis_tready;
  assign m_axis_tdata   = s0_axis_tdata[31:0];
  assign m_axis_tkeep   = s0_axis_tkeep[3:0];
  assign m_axis_tlast   = s0_axis_tlast;
  assign m_axis_tvalid  = s0_axis_tvalid;

  wire [35:0] unused_upper_axis = {s0_axis_tdata[63:32], s0_axis_tkeep[7:4]};

  fifo_sync #(
      .FIFO_DEPTH  (FIFO_DEPTH / 8),
      .FIFO_LATENCY(2),
      .DATA_WIDTH  (USER_WIDTH)
  ) i_fifo_sync (
      .clk  (clk),
      .rst  (rst),
      //
      .wren (~sync_n && s_axis_tvalid),
      .din  (s_axis_tuser),
      .full (tuser_fifo_full),
      //
      .rden (m_axis_tvalid && m_axis_tready && m_axis_tlast),
      .dout (m_axis_tuser),
      .empty(tuser_fifo_empty)
  );

endmodule

`default_nettype wire
