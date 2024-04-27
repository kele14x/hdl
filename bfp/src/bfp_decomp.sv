`timescale 1 ns / 1 ps
//
`default_nettype none

module bfp_decomp (
    input var         clk,
    input var         rst,
    //
    input var  [63:0] s_axis_tdata,
    input var  [ 7:0] s_axis_tkeep,
    input var         s_axis_tvalid,
    input var         s_axis_tlast,
    output var        s_axis_tready,
    input var  [31:0] s_axis_tuser,
    //
    output var [63:0] m_axis_tdata,
    output var [ 7:0] m_axis_tkeep,
    output var        m_axis_tvalid,
    output var        m_axis_tlast,
    output var [31:0] m_axis_tuser,
    //
    input var  [ 3:0] ctrl_ud_comp_meth,
    input var  [ 3:0] ctrl_ud_iq_width,
    input var  [ 3:0] ctrl_fs_offset
);

  logic [ 3:0] ud_iq_width;

  logic        sync;

  logic [63:0] d0_data;
  logic [ 3:0] d0_state;
  logic        d0_valid;
  logic        d0_sync;
  logic        d0_last;

  logic [31:0] fifo_din;
  logic        fifo_wr;
  logic [31:0] fifo_dout;
  logic        fifo_rd_pre;
  logic        fifo_rd;


  always_ff @(posedge clk) begin
    if (rst) begin
      sync <= 1'b0;
    end else if (s_axis_tvalid && s_axis_tready && s_axis_tlast) begin
      sync <= 1'b0;
    end else if (s_axis_tvalid && s_axis_tready) begin
      sync <= 1'b1;
    end
  end

  // TUSER FIFO

  assign fifo_wr = s_axis_tvalid && s_axis_tready && ~sync;
  assign fifo_din = s_axis_tuser;
  
  always_ff @(posedge clk) begin
    fifo_rd_pre <= d0_valid && ~d0_sync;
    fifo_rd     <= fifo_rd_pre;
  end

  always_ff @(posedge clk) begin
    if (fifo_rd) begin
      m_axis_tuser <= fifo_dout;
    end
  end

  // Control CDC

  always_ff @(posedge clk) begin
    if (ctrl_ud_comp_meth == 1) begin
      ud_iq_width <= ctrl_ud_iq_width;
    end else begin
      ud_iq_width <= '0;
    end
  end

  // Submodules

  bfp_decomp_gearbox i_gearbox (
      .clk          (clk),
      .rst          (rst),
      //
      .s_axis_tdata (s_axis_tdata),
      .s_axis_tkeep (s_axis_tkeep),
      .s_axis_tvalid(s_axis_tvalid),
      .s_axis_tlast (s_axis_tlast),
      .s_axis_tready(s_axis_tready),
      //
      .dout_data    (d0_data),
      .dout_state   (d0_state),
      .dout_valid   (d0_valid),
      .dout_sync    (d0_sync),
      .dout_last    (d0_last),
      //
      .ud_iq_width  (ud_iq_width)
  );

  bfp_decomp_exp i_exp (
      .clk           (clk),
      .rst           (rst),
      //
      .din_data      (d0_data),
      .din_state     (d0_state),
      .din_valid     (d0_valid),
      .din_sync      (d0_sync),
      .din_last      (d0_last),
      //
      .m_axis_tdata  (m_axis_tdata),
      .m_axis_tkeep  (m_axis_tkeep),
      .m_axis_tvalid (m_axis_tvalid),
      .m_axis_tlast  (m_axis_tlast),
      //
      .ud_iq_width   (ud_iq_width),
      .ctrl_fs_offset(ctrl_fs_offset)
  );

  fifo_srl #(
      .DATA_WIDTH(32)
  ) i_user_fifo (
      .clk  (clk),
      .rst  (rst),
      //
      .din  (fifo_din),
      .wr_en(fifo_wr),
      .full (  /* not used */),
      //
      .dout (fifo_dout),
      .empty(  /* not used */),
      .rd_en(fifo_rd)
  );

endmodule

`default_nettype wire
