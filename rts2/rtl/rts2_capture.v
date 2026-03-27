`timescale 1ns / 1ps
//
`default_nettype none

module rts2_capture #(
    parameter integer ADDR_WIDTH = 40
) (
    input  wire        clk,
    input  wire        rst,
    //
    input  wire        sync_in,
    //
    input  wire        ddr4_clk,
    input  wire        ddr4_rst,
    // Rx CMD
    output wire [79:0] m_axis_s2mm_cmd_tdata,
    output wire        m_axis_s2mm_cmd_tvalid,
    input  wire        m_axis_s2mm_cmd_tready,
    //
    input  wire [31:0] s_axis_s2mm_sts_tdata,
    input  wire [ 3:0] s_axis_s2mm_sts_tkeep,
    input  wire        s_axis_s2mm_sts_tlast,
    input  wire        s_axis_s2mm_sts_tvalid,
    output wire        s_axis_s2mm_sts_tready,
    //
    input  wire        s2mm_err,
    //
    output wire [63:0] m_axis_tdata,
    output wire [ 7:0] m_axis_tkeep,
    output wire        m_axis_tlast,
    output wire        m_axis_tvalid,
    input  wire        m_axis_tready,
    //
    input  wire [63:0] s_rx_axis_tdata,
    input  wire [ 7:0] s_rx_axis_tkeep,
    input  wire        s_rx_axis_tlast,
    input  wire        s_rx_axis_tvalid
);

  assign s_axis_s2mm_sts_tready = 1'b1;

endmodule

`default_nettype wire
