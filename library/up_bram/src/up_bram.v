/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module up_bram #(
    parameter C_ADDR_WIDTH = 10,
    parameter C_DATA_WIDTH = 32
) (
    (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME clk, ASSOCIATED_RESET rst, ASSOCIATED_BUSIF up_rd:up_wr, FREQ_HZ 100000000, PHASE 0.000" *)
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 clk CLK" *)
    input  wire                      clk       ,
    (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME rst, POLARITY ACTIVE_HIGH" *)
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 rst RST" *)
    input  wire                      rst       ,
    // UP_WR interface
    //================
    (* X_INTERFACE_INFO = "jzhl:user:up_ipif:1.0 up_wr addr" *)
    input  wire [  C_ADDR_WIDTH-1:0] up_wr_addr,
    (* X_INTERFACE_INFO = "jzhl:user:up_ipif:1.0 up_wr be" *)
    input  wire [C_DATA_WIDTH/8-1:0] up_wr_be  ,
    (* X_INTERFACE_INFO = "jzhl:user:up_ipif:1.0 up_wr req" *)
    input  wire                      up_wr_req ,
    (* X_INTERFACE_INFO = "jzhl:user:up_ipif:1.0 up_wr din" *)
    input  wire [  C_DATA_WIDTH-1:0] up_wr_din ,
    (* X_INTERFACE_INFO = "jzhl:user:up_ipif:1.0 up_wr ack" *)
    output wire                      up_wr_ack ,
    // UP_RD interface
    //================
    (* X_INTERFACE_INFO = "jzhl:user:up_ipif:1.0 up_rd addr" *)
    input  wire [  C_ADDR_WIDTH-1:0] up_rd_addr,
    (* X_INTERFACE_INFO = "jzhl:user:up_ipif:1.0 up_rd req" *)
    input  wire                      up_rd_req ,
    (* X_INTERFACE_INFO = "jzhl:user:up_ipif:1.0 up_rd dout" *)
    output wire [  C_DATA_WIDTH-1:0] up_rd_dout,
    (* X_INTERFACE_INFO = "jzhl:user:up_ipif:1.0 up_rd ack" *)
    output wire                      up_rd_ack
);

    up_bram_top #(
        .C_ADDR_WIDTH(C_ADDR_WIDTH),
        .C_DATA_WIDTH(C_DATA_WIDTH)
    ) inst (
        .clk       (clk       ),
        .rst       (rst       ),
        //
        .up_wr_addr(up_wr_addr),
        .up_wr_be  (up_wr_be  ),
        .up_wr_req (up_wr_req ),
        .up_wr_din (up_wr_din ),
        .up_wr_ack (up_wr_ack ),
        //
        .up_rd_addr(up_rd_addr),
        .up_rd_req (up_rd_req ),
        .up_rd_dout(up_rd_dout),
        .up_rd_ack (up_rd_ack )
    );

endmodule
