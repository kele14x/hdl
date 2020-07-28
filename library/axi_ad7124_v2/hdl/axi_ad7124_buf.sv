/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 100 ps
`default_nettype none

module axi_ad7124_buf #(parameter NUM_OF_BOARD = 6) (
    // UP interface
    //-------------
    input  wire        aclk                           ,
    input  wire        aresetn                        ,
    // AXIS I/F
    input  wire        tc_sdi_valid[0:NUM_OF_BOARD-1] ,
    output wire        tc_sdi_ready[0:NUM_OF_BOARD-1] ,
    input  wire [ 7:0] tc_sdi_data [0:NUM_OF_BOARD-1] ,
    //
    input  wire        rtd_sdi_valid[0:NUM_OF_BOARD-1],
    output wire        rtd_sdi_ready[0:NUM_OF_BOARD-1],
    input  wire [ 7:0] rtd_sdi_data [0:NUM_OF_BOARD-1],
    // BRAM I/F
    //---------
    output wire        bram_clk                       ,
    output wire        bram_rst                       ,
    output wire        bram_en                        ,
    output wire [ 3:0] bram_we                        ,
    output wire [12:0] bram_addr                      ,
    output wire [31:0] bram_wrdata                    ,
    input  wire [31:0] bram_rddata
);

    assign bram_clk = aclk;
    assign bram_rst = ~aresetn;

    // TODO

    generate
        for (genvar i = 0; i < NUM_OF_BOARD; i++) begin

            assign tc_sdi_ready[i] = 1'b1;

            assign rtd_sdi_ready[i] = 1'b1;
        end
    endgenerate

endmodule

`default_nettype wire
