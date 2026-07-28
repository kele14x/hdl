// File: oran_deframer_dl_ss_symnum.sv
// Brief: Calculus the symbol number in aid of timing for mgr.
`timescale 1 ns / 1 ps
//
`default_nettype none

module oran_deframer_dl_ss_symnum (
    input var         clk,
    input var         rst,
    //
    input var  [63:0] s_axis_tdata,
    input var  [ 7:0] s_axis_tkeep,
    input var         s_axis_tvalid,
    input var         s_axis_tlast,
    // Section data
    output var [63:0] m_axis_tdata,
    output var [ 7:0] m_axis_tkeep,
    output var        m_axis_tvalid,
    output var        m_axis_tlast,
    output var [ 8:0] m_axis_tuser
);

  logic        wait_app_header_n;

  logic [63:0] s_axis_tdata_reversed;

  // Application common header (32-bit)

  logic        app_datadirection;
  logic [ 2:0] app_payloadversion;
  logic [ 3:0] app_filterindex;
  logic [ 7:0] app_frameid;
  logic [ 3:0] app_subframeid;
  logic [ 5:0] app_slotid;
  logic [ 5:0] app_symbolid;

  logic [ 8:0] app_symbol_num;

  logic [31:0] app_header;

  //
  // This function reverse byte order of 64-bit data
  //
  function automatic logic [63:0] byte_reverse(input logic [63:0] data);
    for (int i = 0; i < 8; i++) begin
      byte_reverse[64-1-i*8-:8] = data[i*8+8-1-:8];
    end
  endfunction


  // Main
  //-----

  always_ff @(posedge clk) begin
    if (rst) begin
      wait_app_header_n <= 1'b0;
    end else if (s_axis_tvalid && s_axis_tlast) begin
      wait_app_header_n <= 1'b0;
    end else if (s_axis_tvalid) begin
      wait_app_header_n <= 1'b1;
    end
  end

  // Combine two word of TDATA, in case some field may span over two words

  assign s_axis_tdata_reversed = byte_reverse(s_axis_tdata);

  // O-RAN application header parser

  // Application common header
  // It's presents at MSB 32-bit of first word in packet

  assign {
    app_datadirection,
    app_payloadversion,
    app_filterindex,
    app_frameid,
    app_subframeid,
    app_slotid,
    app_symbolid
  } = app_header;

  // TODO: this only for mu = 1
  assign app_symbol_num = (app_subframeid * 28 + app_slotid * 14 + app_symbolid);

  assign app_header = s_axis_tdata_reversed[63:32];

  always_ff @(posedge clk) begin
    m_axis_tdata  <= s_axis_tdata;
    m_axis_tkeep  <= s_axis_tkeep;
    m_axis_tvalid <= s_axis_tvalid;
    m_axis_tlast  <= s_axis_tlast;
  end

  always_ff @(posedge clk) begin
    if (!wait_app_header_n && s_axis_tvalid) begin
      m_axis_tuser <= app_symbol_num;
    end
  end

endmodule

`default_nettype wire
