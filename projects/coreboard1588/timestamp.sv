/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module timestamp (
    input  wire clk_125m    ,
    input  wire rst_125m    ,
    input  wire PTP_TRG_FPGA,
    output wire sync_1pps
);

    timestamp_1pps i_timestamp_1pps (
        .clk_125m    (clk_125m    ),
        .rst_125m    (rst_125m    ),
        .PTP_TRG_FPGA(PTP_TRG_FPGA),
        .sync_1pps   (sync_1pps   )
    );

endmodule
