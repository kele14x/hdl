/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

// AXI Trigger Subsystem
module axi_ts_regs #(parameter ADDR_WIDTH = 10) (
    input  var logic                  up_clk                  ,
    input  var logic                  up_rstn                 ,
    //
    input  var logic                  up_wreq                 ,
    input  var logic [ADDR_WIDTH-1:0] up_waddr                ,
    input  var logic [          31:0] up_wdata                ,
    output var logic                  up_wack                 ,
    //
    input  var logic                  up_rreq                 ,
    input  var logic [ADDR_WIDTH-1:0] up_raddr                ,
    output var logic [          31:0] up_rdata                ,
    output var logic                  up_rack                 ,
    // Overall
    output var logic                  ctrl_abort              ,
    // Idle & Init state control
    output var logic                  ctrl_init_immediate     ,
    output var logic                  ctrl_init_continuous    ,
    // Arm state control
    output var logic                  ctrl_arm_immediate      ,
    output var logic [          31:0] ctrl_arm_source         ,
    output var logic [          31:0] ctrl_arm_count          ,
    // Trigger state control
    output var logic                  ctrl_trigger_immediate  ,
    output var logic [          31:0] ctrl_trigger_source     ,
    output var logic [          31:0] ctrl_trigger_count      ,
    // Measure state control
    input  var logic                  stat_operation_complete ,
    input  var logic                  stat_sweeping           ,
    input  var logic                  stat_waiting_for_arm    ,
    input  var logic                  stat_waiting_for_trigger,
    input  var logic                  stat_measuring
);

    //  addr       reg
    //--------------------------
    //  02    scratch
    //
    //  16    ctrl_abort
    //
    //  32    ctrl_init_immediate
    //  33    ctrl_init_continuous
    //
    //  48    ctrl_arm_immediate
    //  49    ctrl_arm_source
    //  50    ctrl_arm_count
    //
    //  64    ctrl_trigger_immediate
    //  65    ctrl_trigger_source
    //  66    ctrl_trigger_count
    //
    //  80    {stat_measuring, stat_waiting_for_trigger,
    //         stat_waiting_for_arm, stat_sweeping, stat_operation_complete}


    reg [31:0] scratch    = 'h0;


    // Write

    // scratch at 2
    always @(posedge up_clk) begin
        if (~up_rstn) begin
            scratch <= 'h00;
        end else if (up_wreq && up_waddr == 'd2) begin
            scratch <= up_wdata;
        end
    end

    // ctrl_abort at 16
    always @(posedge up_clk) begin
        if (~up_rstn) begin
            ctrl_abort <= 'b0;
        end else if (up_wreq && up_waddr == 'd16) begin
            ctrl_abort <= up_wdata[0];
        end else begin
            ctrl_abort <= 1'b0;
        end
    end

    // ctrl_init_immediate at 32
    always @(posedge up_clk) begin
        if (~up_rstn) begin
            ctrl_init_immediate <= 'b0;
        end else if (up_wreq && up_waddr == 'd32) begin
            ctrl_init_immediate <= up_wdata[0];
        end else begin
            ctrl_init_immediate <= 1'b0;
        end
    end

    // ctrl_init_continuous at 33
    always @(posedge up_clk) begin
        if (~up_rstn) begin
            ctrl_init_continuous <= 'b0;
        end else if (up_wreq && up_waddr == 'd33) begin
            ctrl_init_continuous <= up_wdata[0];
        end
    end

    // ctrl_arm_immediate at 48
    always @(posedge up_clk) begin
        if (~up_rstn) begin
            ctrl_arm_immediate <= 'b0;
        end else if (up_wreq && up_waddr == 'd48) begin
            ctrl_arm_immediate <= up_wdata[0];
        end else begin
            ctrl_arm_immediate <= 1'b0;
        end
    end

    // ctrl_arm_source at 49
    always @(posedge up_clk) begin
        if (~up_rstn) begin
            ctrl_arm_source <= 'b0;
        end else if (up_wreq && up_waddr == 'd49) begin
            ctrl_arm_source <= up_wdata;
        end
    end

    // ctrl_arm_count at 50
    always @(posedge up_clk) begin
        if (~up_rstn) begin
            ctrl_arm_count <= 'd0;
        end else if (up_wreq && up_waddr == 'd50) begin
            ctrl_arm_count <= up_wdata;
        end
    end

    // ctrl_trigger_immediate at 64
    always @(posedge up_clk) begin
        if (~up_rstn) begin
            ctrl_trigger_immediate <= 'b0;
        end else if (up_wreq && up_waddr == 'd64) begin
            ctrl_trigger_immediate <= up_wdata[0];
        end else begin
            ctrl_trigger_immediate <= 1'b0;
        end
    end

    // ctrl_trigger_source at 65
    always @(posedge up_clk) begin
        if (~up_rstn) begin
            ctrl_trigger_source <= 'b0;
        end else if (up_wreq && up_waddr == 'd65) begin
            ctrl_trigger_source <= up_wdata;
        end
    end

    // ctrl_trigger_count at 66
    always @(posedge up_clk) begin
        if (~up_rstn) begin
            ctrl_trigger_count <= 'd0;
        end else if (up_wreq && up_waddr == 'd66) begin
            ctrl_trigger_count <= up_wdata;
        end
    end

    // Read out
    //=========

    always @(posedge up_clk) begin
        if (~up_rstn) begin
            up_rdata <= 'b0;
        end else if (up_rreq) begin
            case (up_raddr)
                'd02    : up_rdata <= scratch;
                'd33    : up_rdata <= {31'b0, ctrl_init_continuous};
                'd49    : up_rdata <= ctrl_arm_source;
                'd50    : up_rdata <= ctrl_arm_count;
                'd65    : up_rdata <= ctrl_trigger_source;
                'd66    : up_rdata <= ctrl_trigger_count;
                'd80    : up_rdata <= {27'b0, stat_measuring,
                    stat_waiting_for_trigger, stat_waiting_for_arm,
                    stat_sweeping, stat_operation_complete};
                default : up_rdata <= 32'h00000000;
            endcase
        end
    end


    // ACK Logic
    //==========

    always @(posedge up_clk) begin
        if (~up_rstn) begin
            up_wack <= 1'b0;
        end else begin
            up_wack <= up_wreq;
        end
    end

    always @(posedge up_clk) begin
        if (~up_rstn) begin
            up_rack <= 1'b0;
        end else begin
            up_rack <= up_rreq;
        end
    end

endmodule

`default_nettype wire
