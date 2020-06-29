/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module dummy_adc_regs #(
    parameter C_MODUEL_ID  = 32'hABCD,
    parameter C_ADDR_WIDTH = 8
) (
    input  var logic                    clk         ,
    input  var logic                    rst         ,
    //========
    input  var logic [C_ADDR_WIDTH-1:0] up_wr_addr  ,
    input  var logic                    up_wr_req   ,
    input  var logic [            31:0] up_wr_din   ,
    output var logic                    up_wr_ack   ,
    //
    input  var logic [C_ADDR_WIDTH-1:0] up_rd_addr  ,
    input  var logic                    up_rd_req   ,
    output var logic [            31:0] up_rd_dout  ,
    output var logic                    up_rd_ack   ,
    //========
    // SCRATCH
    output var logic [            31:0] ctrl_scratch
    // RTC
);

    localparam C_VERSION = 32'h0001;

    // | Address | Regsiter
    //------------------------------
    // |   1     | MODULE_ID
    // |   2     | VERSION
    //
    // |   4     | ctrl_scratch
    //
    // |   8     | ctrl_rtc_mode


    // Write
    //======

    // ctrl_scratch at address = 4, bit[31:0]
    always_ff @ (posedge clk) begin
        if (rst) begin
            ctrl_scratch <= 'd0;
        end else if (up_wr_req && up_wr_addr == 'd8) begin
            ctrl_scratch <= up_wr_din;
        end
    end




    // Read
    //=====

    always_ff @ (posedge clk) begin
        if (rst) begin
            up_rd_dout <= 'd0;
        end else if (up_rd_req) begin
            case (up_rd_addr)
                'd1     : up_rd_dout <= C_MODUEL_ID;
                'd2     : up_rd_dout <= C_VERSION;
                'd4     : up_rd_dout <= ctrl_scratch;
                default : up_rd_dout <= 32'hDEADBEEF;
            endcase
        end
    end

    // HS Signals
    //===========

    // It takes 1 clock for read response
    always_ff @ (posedge clk) begin
        if (rst) begin
            up_wr_ack <= 1'b0;
        end else begin
            up_wr_ack <= up_wr_req;
        end
    end

    // It takes 1 clock for read response
    always_ff @ (posedge clk) begin
        if (rst) begin
            up_rd_ack <= 1'b0;
        end else begin
            up_rd_ack <= up_rd_req;
        end
    end

endmodule

`default_nettype wire
