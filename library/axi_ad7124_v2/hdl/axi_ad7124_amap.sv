/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 100 ps
`default_nettype none

module axi_ad7124_amap #(parameter NUM_OF_BOARD = 6) (
    input  wire        up_clk                        ,
    input  wire        up_rstn                       ,
    // UP
    input  wire        up_wreq                       ,
    input  wire [13:0] up_waddr                      ,
    input  wire [31:0] up_wdata                      ,
    output wire        up_wack                       ,
    //
    input  wire        up_rreq                       ,
    input  wire [13:0] up_raddr                      ,
    output wire [31:0] up_rdata                      ,
    output wire        up_rack                       ,
    // TC
    output wire        tc_up_wreq [0:NUM_OF_BOARD-1] ,
    output wire [13:0] tc_up_waddr[0:NUM_OF_BOARD-1] ,
    output wire [31:0] tc_up_wdata[0:NUM_OF_BOARD-1] ,
    input  wire        tc_up_wack [0:NUM_OF_BOARD-1] ,
    //
    output wire        tc_up_rreq [0:NUM_OF_BOARD-1] ,
    output wire [13:0] tc_up_raddr[0:NUM_OF_BOARD-1] ,
    input  wire [31:0] tc_up_rdata[0:NUM_OF_BOARD-1] ,
    input  wire        tc_up_rack [0:NUM_OF_BOARD-1] ,
    // RTD
    output wire        rtd_up_wreq [0:NUM_OF_BOARD-1],
    output wire [13:0] rtd_up_waddr[0:NUM_OF_BOARD-1],
    output wire [31:0] rtd_up_wdata[0:NUM_OF_BOARD-1],
    input  wire        rtd_up_wack [0:NUM_OF_BOARD-1],
    //
    output wire        rtd_up_rreq [0:NUM_OF_BOARD-1],
    output wire [13:0] rtd_up_raddr[0:NUM_OF_BOARD-1],
    input  wire [31:0] rtd_up_rdata[0:NUM_OF_BOARD-1],
    input  wire        rtd_up_rack [0:NUM_OF_BOARD-1]
);


    /* Address mapping */

    // The interface is configured as 14-bit width, (16384 word ,or 64K byte)
    // Total 6 channel (ADC Board)
    //
    // Channel N is mapped to N * 512 word (N * 2K byte) address space:
    //   Generic slave is mapped to base
    //   Each SPI Engine need 128 word memory space (7-bit), so:
    //      TC SPI Engine is mapped to 256 word (1K byte)
    //      RTD SPI Engine is mapped to 386 word (1.5K byte)
    //

    // |     13 :  9     |      8 : 7         | 6 : 0 |
    //   N Ch              00 - Generic
    //                     10 - TC SPI
    //                     11 - RTD SPI

    generate
        for (genvar i = 0; i < NUM_OF_BOARD; i++) begin

            // TC Channel N is mapped to N*258 word
            assign tc_up_wreq [i] = (up_waddr[13:9] == i && up_waddr[8:7] == 2'b10) ? up_wreq : 1'b0;
            assign tc_up_waddr[i] = {7'b0, up_waddr[6:0]};
            assign tc_up_wdata[i] = up_wdata;

            // RTD Channel N is mapped to N*256+128 word
            assign rtd_up_wreq [i] = (up_waddr[13:9] == i && up_waddr[8:7] == 2'b11) ? up_wreq : 1'b0;
            assign rtd_up_waddr[i] = {7'b0, up_waddr[6:0]};
            assign rtd_up_wdata[i] = up_wdata;

            // TC Channel N is mapped to N*258 word
            assign tc_up_rreq [i] = (up_raddr[13:9] == i && up_raddr[8:7] == 2'b10) ? up_rreq : 1'b0;
            assign tc_up_raddr[i] = {7'b0, up_raddr[6:0]};

            // RTD Channel N is mapped to N*256+128 word
            assign rtd_up_rreq [i] = (up_raddr[13:9] == i && up_raddr[8:7] == 2'b11) ? up_rreq : 1'b0;
            assign rtd_up_raddr[i] = {7'b0, up_raddr[6:0]};

        end
    endgenerate


    assign up_wack = up_waddr[8:7] == 2'b00 ? 1'b0 :
                                      2'b01 ? 1'b0 :
                                      2'b10 ? tc_up_wack[up_waddr[13:9]] :
                                              rtd_up_wack[up_waddr[13:9]];

    assign up_rack = up_raddr[8:7] == 2'b00 ? 1'b0 :
                                      2'b01 ? 1'b0 :
                                      2'b10 ? tc_up_rack[up_raddr[13:9]] :
                                              rtd_up_rack[up_raddr[13:9]];

    assign up_rdata = up_raddr[8:7] == 2'b00 ? 32'b0 :
                                       2'b00 ? 32'b0 :
                                       2'b10 ? tc_up_rdata[up_raddr[13:9]] :
                                               rtd_up_rdata[up_raddr[13:9]];

endmodule

`default_nettype wire
