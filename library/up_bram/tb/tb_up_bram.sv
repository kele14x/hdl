/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module tb_up_bram();


    parameter C_ADDR_WIDTH = 10;
    parameter C_DATA_WIDTH = 32;


    var logic                         clk       ;
    var logic                         rst       ;
    //
    var logic [  C_ADDR_WIDTH-1:0] up_wr_addr = 0;
    var logic [C_DATA_WIDTH/8-1:0] up_wr_be   = 0;
    var logic                      up_wr_req  = 0;
    var logic [  C_DATA_WIDTH-1:0] up_wr_din  = 0;
    var logic                      up_wr_ack  = 0;
    //
    var logic    [  C_ADDR_WIDTH-1:0] up_rd_addr = 0;
    var logic                         up_rd_req  = 0;
    var logic    [  C_DATA_WIDTH-1:0] up_rd_dout = 0;
    var logic                         up_rd_ack  = 0;


    up_bram #(
        .C_ADDR_WIDTH(C_ADDR_WIDTH),
        .C_DATA_WIDTH(C_DATA_WIDTH)
    ) UUT (.*);


    always begin
        clk = 0;
        #5 clk = 1;
        #5;
    end


    initial begin
        $display("Simulation starts.");
        rst = 1;
        #100;
        rst = 0;
        $display("Reset done.");
        @(posedge clk);
        up_wr_addr <= 10'h55;
        up_wr_be <= 4'b1111;
        up_wr_req <= 1'b1;
        up_wr_din <= 32'h1234ABCD;
        @(posedge clk);
        up_wr_req <= 1'b0;
        up_rd_addr <= 10'h55;
        up_rd_req <= 1'b1;
        @(posedge clk);
        up_rd_req <= 1'b0;
    end

endmodule
