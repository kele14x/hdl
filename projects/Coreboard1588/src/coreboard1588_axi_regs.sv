/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module coreboard1588_axi_regs #(
    parameter C_ADDR_WIDTH = 10,
    parameter C_DATA_WIDTH = 32
) (
    input  var logic                    clk                    ,
    input  var logic                    rst                    ,
    //
    input  var logic [C_ADDR_WIDTH-1:0] up_wr_addr             ,
    input  var logic                    up_wr_req              ,
    input  var logic [C_DATA_WIDTH-1:0] up_wr_din              ,
    output var logic                    up_wr_ack              ,
    //
    input  var logic [C_ADDR_WIDTH-1:0] up_rd_addr             ,
    input  var logic                    up_rd_req              ,
    output var logic [C_DATA_WIDTH-1:0] up_rd_dout             ,
    output var logic                    up_rd_ack              ,
    //
    //===========
    // SCRATCH
    output var logic [            31:0] ctrl_scratch           ,
    // RTC
    output var logic                    ctrl_rtc_mode          , // 0 = Normal mode, 1 = PPS mode
    output var logic [            31:0] ctrl_second            ,
    output var logic [            31:0] ctrl_nanosecond        ,
    output var logic                    ctrl_timeset           ,
    output var logic                    ctrl_timeget           ,
    //
    input  var logic [            31:0] stat_second            ,
    input  var logic [            31:0] stat_nanosecond        ,
    output var logic                    ctrl_second_inc        , // For bug work around
    //
    output var logic                    ctrl_trigger_enable    ,
    output var logic [             1:0] ctrl_trigger_source    , // 00 = MCU, 11 = RTC, reserved other wise
    output var logic [             1:0] ctrl_trigger_type      ,
    output var logic [            31:0] ctrl_trigger_second    ,
    output var logic [            31:0] ctrl_trigger_nanosecond
);


    // | Address | Register
    //------------------------------
    // |   1     | PRODUCT_ID
    // |   2     | VERSION
    // |   3     | BUILD_DATE
    // |   4     | BUILD_TIME
    //
    // |   8     | ctrl_scratch
    //
    // |   16    | ctrl_rtc_mode
    // |   17    | ctrl_second
    // |   18    | ctrl_nanosecond
    // |   19    | ctrl_timeset
    // |   20    | ctrl_timeget
    // |   21    | stat_second
    // |   22    | stat_nanosecond
    // |   23    | ctrl_second_inc
    //
    // |   32    | ctrl_trigger_enable
    // |   33    | ctrl_trigger_source
    // |   34    | ctrl_trigger_second
    // |   35    | ctrl_trigger_nanosecond
    // |   36    | ctrl_trigger_type

`include "version.vh"
`include "build_time.vh"

    // Write
    //======

    // ctrl_scratch at address = 8, bit[0]
    always_ff @ (posedge clk) begin
        if (rst) begin
            ctrl_scratch <= 'd0;
        end else if (up_wr_req && up_wr_addr == 'd8) begin
            ctrl_scratch <= up_wr_din;
        end
    end

    // ctrl_rtc_mode at address = 16, bit[0]
    always_ff @ (posedge clk) begin
        if (rst) begin
            ctrl_rtc_mode <= 'd0;
        end else if (up_wr_req && up_wr_addr == 'd16) begin
            ctrl_rtc_mode <= up_wr_din[0];
        end
    end

    // ctrl_second at address = 17
    always_ff @ (posedge clk) begin
        if (rst) begin
            ctrl_second <= 'd0;
        end else if (up_wr_req && up_wr_addr == 'd17) begin
            ctrl_second <= up_wr_din;
        end
    end

    // ctrl_nanosecond at address = 18
    always_ff @ (posedge clk) begin
        if (rst) begin
            ctrl_nanosecond <= 'd0;
        end else if (up_wr_req && up_wr_addr == 'd18) begin
            ctrl_nanosecond <= up_wr_din;
        end
    end

    // ctrl_timeset at address = 19, bit[0]
    always_ff @ (posedge clk) begin
        if (rst) begin
            ctrl_timeset <= 'd0;
        end else if (up_wr_req && up_wr_addr == 'd19) begin
            ctrl_timeset <= up_wr_din[0];
        end else begin
            ctrl_timeset <= 'd0;
        end
    end

    // ctrl_timeget at address = 20, bit[0]
    always_ff @ (posedge clk) begin
        if (rst) begin
            ctrl_timeget <= 'd0;
        end else if (up_wr_req && up_wr_addr == 'd20) begin
            ctrl_timeget <= up_wr_din[0];
        end else begin
            ctrl_timeget <= 'd0;
        end
    end


    // ctrl_second_inc at address = 23, bit[0]
    always_ff @ (posedge clk) begin
        if (rst) begin
            ctrl_second_inc <= 'd0;
        end else if (up_wr_req && up_wr_addr == 'd23) begin
            ctrl_second_inc <= up_wr_din[0];
        end else begin
            ctrl_second_inc <= 'd0;
        end
    end

    // ctrl_trigger_enable at address = 32, bit[0]
    always_ff @ (posedge clk) begin
        if (rst) begin
            ctrl_trigger_enable <= 'd0;
        end else if (up_wr_req && up_wr_addr == 'd32) begin
            ctrl_trigger_enable <= up_wr_din[0];
        end
    end

    // ctrl_trigger_source at address = 33, bit[1:0]
    always_ff @ (posedge clk) begin
        if (rst) begin
            ctrl_trigger_source <= 'd0;
        end else if (up_wr_req && up_wr_addr == 'd33) begin
            ctrl_trigger_source <= up_wr_din[1:0];
        end
    end

    // ctrl_trigger_second at address = 34
    always_ff @ (posedge clk) begin
        if (rst) begin
            ctrl_trigger_second <= 'd0;
        end else if (up_wr_req && up_wr_addr == 'd34) begin
            ctrl_trigger_second <= up_wr_din;
        end
    end

    // ctrl_trigger_nanosecond at address = 35
    always_ff @ (posedge clk) begin
        if (rst) begin
            ctrl_trigger_nanosecond <= 'd0;
        end else if (up_wr_req && up_wr_addr == 'd35) begin
            ctrl_trigger_nanosecond <= up_wr_din;
        end
    end

    // ctrl_trigger_type at address = 36
    always_ff @ (posedge clk) begin
        if (rst) begin
            ctrl_trigger_type <= 'd0;
        end else if (up_wr_req && up_wr_addr == 'd36) begin
            ctrl_trigger_type <= up_wr_din[1:0];
        end
    end

    // It takes 1 clock for read response
    always_ff @ (posedge clk) begin
        if (rst) begin
            up_wr_ack <= 1'b0;
        end else begin
            up_wr_ack <= up_wr_req;
        end
    end

    // Read
    //=====

    always_ff @ (posedge clk) begin
        if (rst) begin
            up_rd_dout <= 'd0;
        end else if (up_rd_req) begin
            case (up_rd_addr)
                'd1    : up_rd_dout <= PRODUCT_ID;
                'd2    : up_rd_dout <= VERSION;
                'd3    : up_rd_dout <= BUILD_DATE;
                'd4    : up_rd_dout <= BUILD_TIME;
                'd8    : up_rd_dout <= ctrl_scratch;
                'd16   : up_rd_dout <= {31'b0, ctrl_rtc_mode};
                'd17   : up_rd_dout <= ctrl_second;
                'd18   : up_rd_dout <= ctrl_nanosecond;
                'd19   : up_rd_dout <= 32'b0;
                'd20   : up_rd_dout <= 32'b0;
                'd21   : up_rd_dout <= stat_second;
                'd22   : up_rd_dout <= stat_nanosecond;
                'd23   : up_rd_dout <= 32'b0;
                'd32   : up_rd_dout <= {31'b0, ctrl_trigger_enable};
                'd33   : up_rd_dout <= {30'b0, ctrl_trigger_source};
                'd34   : up_rd_dout <= ctrl_trigger_second;
                'd35   : up_rd_dout <= ctrl_trigger_nanosecond;
                'd36   : up_rd_dout <= {30'b0, ctrl_trigger_type};
                default: up_rd_dout <= 32'hDEADBEEF;
            endcase
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
