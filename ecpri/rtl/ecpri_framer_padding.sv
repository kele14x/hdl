/*
 * eCPRI Framer Buffer
 *   1. Padding the packet to the minimum length
 *   2. Clock domain crossing
 */

`timescale 1 ns / 1 ps
//
`default_nettype none

module ecpri_framer_padding (
    input var         clk,
    input var         rst,
    //
    input var  [31:0] s_axis_tdata,
    input var  [ 3:0] s_axis_tkeep,
    input var         s_axis_tlast,
    input var  [17:0] s_axis_tuser,
    input var         s_axis_tvalid,
    output var        s_axis_tready,
    //
    output var [31:0] m_axis_tdata,
    output var [ 3:0] m_axis_tkeep,
    output var        m_axis_tlast,
    output var        m_axis_tuser,
    output var        m_axis_tvalid,
    input var         m_axis_tready,
    //
    output var [ 1:0] tx_ptp_1588op,
    output var [15:0] tx_ptp_tag_field
);

  // Signals

  logic        sync_n;
  logic [ 3:0] data_count;
  logic        is_padding;

  wire  [31:0] int_axis_tdata;
  wire  [ 3:0] int_axis_tkeep;
  wire         int_axis_tlast;
  wire  [17:0] int_axis_tuser;
  wire         int_axis_tvalid;
  wire         int_axis_tready;

  function [31:0] tkeep_null(input [31:0] tdata, input [3:0] tkeep);
    integer i;
    begin
      for (i = 0; i < 4; i = i + 1) begin
        tkeep_null[i*8+7-:8] = tkeep[i] ? tdata[i*8+7-:8] : 8'b0;
      end
    end
  endfunction

  // Main

  // TUSER is 1588 op and tag field

  always_ff @(posedge clk) begin
    if (rst) begin
      sync_n <= 1'b0;
    end else if (int_axis_tvalid && int_axis_tready && int_axis_tlast) begin
      sync_n <= 1'b0;
    end else if (int_axis_tvalid && int_axis_tready) begin
      sync_n <= 1'b1;
    end
  end

  always_ff @(posedge clk) begin
    if (~sync_n && int_axis_tvalid && int_axis_tready) begin
      tx_ptp_1588op    <= int_axis_tuser[17:16];
      tx_ptp_tag_field <= int_axis_tuser[15:0];
    end
  end

  // Count how many data words we have outputted
  // 0 ~ 13: requires padding with extra words
  // 14: requires padding with TKEEP pattern changed
  // 15: no padding required
  always_ff @(posedge clk) begin
    if (rst) begin
      data_count <= 'd0;

      // is_padding is not set
    end else if (int_axis_tvalid && int_axis_tready && int_axis_tlast) begin
      if (data_count >= 4'd14) begin
        data_count <= 4'd0;
      end else begin
        data_count <= data_count + 1'd1;
      end
    end else if (int_axis_tvalid && int_axis_tready) begin
      if (data_count >= 4'd14) begin
        data_count <= 4'd15;
      end else begin
        data_count <= data_count + 1'd1;
      end

      // is padding is set
    end else if (is_padding && (~m_axis_tvalid || m_axis_tready)) begin
      if (data_count >= 4'd14) begin
        data_count <= 4'd0;
      end else begin
        data_count <= data_count + 1'd1;
      end
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      is_padding <= 1'b0;
    end else if (int_axis_tvalid && int_axis_tready && int_axis_tlast) begin
      is_padding <= ~(data_count >= 4'd14);
    end else if ((data_count >= 4'd14) && (~m_axis_tvalid || m_axis_tready)) begin
      is_padding <= 1'b0;
    end
  end

  // AXIS Output

  always_ff @(posedge clk) begin
    if (~m_axis_tvalid || m_axis_tready) begin
      if (is_padding) begin
        m_axis_tdata <= 32'd0;
        m_axis_tkeep <= 4'hF;
        m_axis_tlast <= (data_count >= 4'd14);
      end else begin
        m_axis_tdata <= tkeep_null(int_axis_tdata, int_axis_tkeep);
        m_axis_tkeep <= (data_count >= 4'd15) ? int_axis_tkeep : 4'hF;
        m_axis_tlast <= (data_count >= 4'd14) ? int_axis_tlast : 1'b0;
      end
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      m_axis_tvalid <= 1'b0;
    end else if (~m_axis_tvalid || m_axis_tready) begin
      m_axis_tvalid <= is_padding ? 1'b1 : int_axis_tvalid;
    end
  end

  assign m_axis_tuser = 1'b0;

  // Internal signal

  assign int_axis_tready = (~m_axis_tvalid || m_axis_tready) && ~is_padding;

  // The FIFO

  axis_reg #(
      .DATA_WIDTH(32),
      .USER_WIDTH(18)
  ) i_reg (
      .aclk         (clk),
      .aresetn      (!rst),
      //
      .s_axis_tdata (s_axis_tdata),
      .s_axis_tkeep (s_axis_tkeep),
      .s_axis_tlast (s_axis_tlast),
      .s_axis_tuser (s_axis_tuser),
      .s_axis_tvalid(s_axis_tvalid),
      .s_axis_tready(s_axis_tready),
      //
      .m_axis_tdata (int_axis_tdata),
      .m_axis_tkeep (int_axis_tkeep),
      .m_axis_tlast (int_axis_tlast),
      .m_axis_tuser (int_axis_tuser),
      .m_axis_tvalid(int_axis_tvalid),
      .m_axis_tready(int_axis_tready)
  );

endmodule

`default_nettype wire
