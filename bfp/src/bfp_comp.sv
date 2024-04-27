`timescale 1 ns / 1 ps
//
`default_nettype none

module bfp_comp (
    input var         clk,
    input var         rst,
    //
    input var  [63:0] s_axis_tdata,
    input var  [ 7:0] s_axis_tkeep,
    input var         s_axis_tvalid,
    input var         s_axis_tlast,
    input var  [31:0] s_axis_tuser,
    //
    output var [63:0] m_axis_tdata,
    output var [ 7:0] m_axis_tkeep,
    output var        m_axis_tvalid,
    output var        m_axis_tlast,
    output var [31:0] m_axis_tuser,
    // Control
    //--------
    input var  [ 3:0] ctrl_ud_comp_meth,
    input var  [ 3:0] ctrl_ud_iq_width
);

  import bfp_pkg::*;

  logic [63:0] s_axis_tdata_reversed;

  logic [63:0] data0;
  logic        valid0;
  logic        last0;
  logic [31:0] user0;
  logic        sync0;

  logic [ 3:0] ud_iq_width;

  logic [63:0] d0_data;
  logic [ 2:0] d0_state;
  logic        d0_valid;
  logic        d0_sync;
  logic        d0_last;

  logic [31:0] fifo_din;
  logic        fifo_wr;
  logic [31:0] fifo_dout;
  logic        fifo_rd;


  // Register input

  assign s_axis_tdata_reversed = byte_reverse(s_axis_tdata);

  always_ff @(posedge clk) begin
    data0  <= s_axis_tdata_reversed;
    valid0 <= s_axis_tvalid;
    last0  <= s_axis_tlast;
    user0  <= s_axis_tuser;
  end

  always_ff @(posedge clk) begin
    if (rst || (valid0 && last0)) begin
      sync0 <= 1'b0;
    end else if (valid0) begin
      sync0 <= 1'b1;
    end
  end

  // TUSER FIFO

  assign fifo_din = user0;
  assign fifo_wr  = valid0 && ~sync0;
  assign fifo_rd  = d0_valid & ~d0_sync;

  always_ff @(posedge clk) begin
    if (fifo_rd) begin
      m_axis_tuser <= fifo_dout;
    end
  end

  // Control CDC

  always_ff @(posedge clk) begin
    if (ctrl_ud_comp_meth == 1) begin
      // BFPx
      ud_iq_width <= ctrl_ud_iq_width;
    end else begin
      // Uncompressed, or not supported compression method
      ud_iq_width <= '0;
    end
  end

  // Submodules

  bfp_comp_exp i_exp (
      .clk        (clk),
      .rst        (rst),
      //
      .din_data   (data0),
      .din_valid  (valid0),
      .din_sync   (sync0),
      .din_last   (last0),
      //
      .dout_data  (d0_data),
      .dout_state (d0_state),
      .dout_valid (d0_valid),
      .dout_sync  (d0_sync),
      .dout_last  (d0_last),
      // Control
      //--------
      .ud_iq_width(ud_iq_width)
  );

  bfp_comp_gearbox i_gearbox (
      .clk          (clk),
      .rst          (rst),
      //
      .din_data     (d0_data),
      .din_state    (d0_state),
      .din_valid    (d0_valid),
      .din_sync     (d0_sync),
      .din_last     (d0_last),
      //
      .m_axis_tdata (m_axis_tdata),
      .m_axis_tkeep (m_axis_tkeep),
      .m_axis_tvalid(m_axis_tvalid),
      .m_axis_tlast (m_axis_tlast),
      // Control
      //--------
      .ud_iq_width  (ud_iq_width)
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
