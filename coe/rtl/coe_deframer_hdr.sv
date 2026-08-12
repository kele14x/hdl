`timescale 1 ns / 1 ps
//
`default_nettype none

module coe_deframer_hdr (
    // Ethernet
    input var         clk,
    input var         rst,
    //
    input var         sync,
    //
    input var  [31:0] s_axis_tdata,
    input var  [ 3:0] s_axis_tkeep,
    input var         s_axis_tlast,
    input var         s_axis_tvalid,
    // Radio I/F
    output var [31:0] m_axis_tdata,
    output var [ 3:0] m_axis_tkeep,
    output var        m_axis_tlast,
    output var        m_axis_tvalid,
    //
    output var        m_app_valid,
    output var [18:0] m_app_ts
);

  import coe_pkg::*;

  // Parameters

  // Signals

  // Write side signals

  logic        init_n;

  wire  [31:0] s_axis_tdata_reversed;
  wire         unused_inputs = &{1'b0, sync, s_axis_tdata_reversed[31:19]};

  assign s_axis_tdata_reversed = byte_reverse(s_axis_tdata);

  always_ff @(posedge clk) begin
    if (rst) begin
      init_n <= 1'b0;
    end else if (s_axis_tvalid && s_axis_tlast) begin
      init_n <= 1'b0;
    end else if (s_axis_tvalid) begin
      init_n <= 1'b1;
    end
  end

  always_ff @(posedge clk) begin
    m_app_valid <= !init_n && s_axis_tvalid;
  end

  always_ff @(posedge clk) begin
    if (!init_n && s_axis_tvalid) begin
      m_app_ts <= s_axis_tdata_reversed[18:0];
    end
  end

  always_ff @(posedge clk) begin
    if (s_axis_tvalid && init_n) begin
      m_axis_tdata <= s_axis_tdata;
      m_axis_tkeep <= s_axis_tkeep;
      m_axis_tlast <= s_axis_tlast;
    end
  end

  always_ff @(posedge clk) begin
    m_axis_tvalid <= s_axis_tvalid && init_n;
  end

endmodule

`default_nettype wire
