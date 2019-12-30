/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module axi_ads868x_regs #(
    parameter [31:0] C_VERSION = "20191230"
) (
    // User Ports
    //------------
    input  wire        up_clk         ,
    input  wire        up_rstn        ,
    //
    input  wire [ 9:0] up_wr_addr     ,
    input  wire        up_wr_req      ,
    input  wire [ 3:0] up_wr_be       ,
    input  wire [31:0] up_wr_data     ,
    output reg         up_wr_ack      ,
    //
    input  wire [ 9:0] up_rd_addr     ,
    input  wire        up_rd_req      ,
    output reg  [31:0] up_rd_data     ,
    output reg         up_rd_ack      ,
    // Core Ports
    //------------
    input  wire        clk            ,
    input  wire        rst            ,
    //
    output wire        ctrl_soft_reset,
    //
    output wire [3:0]  ctrl_ext_mux_en  
);

    // Write
    //=======

    reg ctrl_soft_reset_int;
    
    reg [3:0] ctrl_ext_mux_en_int;
    
    // ctrl_soft_reset_int on reg[0] on address = 0
    always_ff @ (posedge up_clk) begin
        if (!up_rstn) begin
            ctrl_soft_reset_int <= 'd0;
        end else if (up_wr_req && up_wr_addr == 'd1 && up_wr_be[0]) begin
            ctrl_soft_reset_int <= up_wr_data[0];
        end
    end

    cdc_bits #(
        .C_BIT_WIDTH(1),
        .C_NUM_STAGE(2)
    ) i_cdc_soft_reset (
        .din    (ctrl_soft_reset_int),
        .out_clk(clk),
        .dout   (ctrl_soft_reset)
    );

    cdc_bits #(
        .C_BIT_WIDTH(1),
        .C_NUM_STAGE(2)
    ) i_cdc_ctrl_extmuxen (
        .din    (ctrl_ext_mux_en_int),
        .out_clk(clk),
        .dout   (ctrl_ext_mux_en)
    );

    // Read
    //======

    // Read decode
    always_ff @ (posedge up_clk) begin
        if (!up_rstn) begin
            up_rd_data <= 32'd0;
        end else if (up_rd_req) begin
            // Address decode
            case (up_rd_addr)
                'd0    : up_rd_data <= C_VERSION;
                default: up_rd_data <= 32'hDEADBEEF;
            endcase
        end
    end

    always_ff @ (posedge up_clk) begin
        if (!up_rstn) begin
            up_rd_ack  <= 1'b0;
        end else begin
            up_rd_ack <= up_rd_req;
        end
    end

endmodule

`default_nettype wire
