/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

(* keep_hierarchy="yes" *)
module spi_axis_sfr (
    input  wire        clk                 ,
    input  wire        rst                 ,
    // Interface
    //-----------
    input  wire [11:0] addr                ,
    input  wire        wren                ,
    input  wire        rden                ,
    input  wire [15:0] din                 ,
    output reg  [15:0] dout                  = 16'd0,
    // Register Space
    //---------------
    // SRR
    output wire        reg_srr_rst         ,
    // SR
    input  wire        reg_sr_axiawoverrun ,
    input  wire        reg_sr_axiwoverrun  ,
    input  wire        reg_sr_axibresperr  ,
    input  wire        reg_sr_axiaroverrun ,
    input  wire        reg_sr_axirresperr  ,
    // HAR0
    output wire [15:0] reg_har0_axihighaddr,
    // HAR1
    output wire [ 3:0] reg_har1_axihighaddr
);

//
// SFR (Special Function Registers) Table
//
// +---------------------------+----------------------------------------------+
// |  Address (range) |        |        Function                              |
// +------------------+--------+----------------------------------------------+
// | 0x000 ~ 0x03F    | MEM    | 64 Memory for W/R test                       |
// +------------------+--------+----------------------------------------------+
// | 0x040            | SRR    | Software Reset Register                      |
// |                  |        | [0]: Write 1 to assert reset, 0 to dessert   |
// |                  |        |      reset.                                  |
// +------------------+--------+----------------------------------------------+
// | 0x064            | SR     | SPI Status Register                          |
// |                  |        | [0]: axiawoverrun                            |
// |                  |        | [1]: axiwoverrun                             |
// |                  |        | [2]: axibresperr                             |
// |                  |        | [3]: axiaroverrun                            |
// |                  |        | [4]: axirresperr                             |
// +------------------+--------+----------------------------------------------+
// | 0x068            | HAR0   | AXI High Address 0 Register                  |
// |                  |        | [15:0]: AXI Address [27:12]                  |
// +------------------+--------+----------------------------------------------+
// | 0x06C            | HAR1   | AXI High Address 1 Register                  |
// |                  |        | [3:0]: AXI Address [31:28]                   |
// +------------------+--------+----------------------------------------------+
//

    localparam C_ADDR_SRR  = 12'h040;
    localparam C_ADDR_SR   = 12'h064;
    localparam C_ADDR_HAR0 = 12'h068;
    localparam C_ADDR_AHR1 = 12'h06C;

    // MEM
    (* ram_style="distributed" *)
    reg [15:0] mem [0:63];

    initial begin
        for (int i = 0; i < 64; i++) begin
            mem[i] <= 16'b0;
        end
    end

    // SSR
    reg srr_rst = 1'b0;

    // SR
    reg sr_axiawoverrun = 1'b0;
    reg sr_axiwoverrun  = 1'b0;
    reg sr_axibresperr  = 1'b0;
    reg sr_axiaroverrun = 1'b0;
    reg sr_axirresperr  = 1'b0;

    // HAR0
    reg [15:0] har0_axihighaddr = 16'd0;

    // HAR1
    reg [3:0] har1_axighighaddr = 4'd0;

    // Write decoding
    //===============

    always_ff @ (posedge clk) begin
        if (wren) begin
            // 256 Memory space at address 0x000 ~ 0x03F
            if (addr[11:6] == 6'd0) begin
                mem[addr[5:0]] <= din;
            end
            if (addr == C_ADDR_SRR) begin
                srr_rst <= din;
            end
            if (addr == C_ADDR_HAR0) begin
                har0_axihighaddr <= din;
            end
            if (addr == C_ADDR_AHR1) begin
                har1_axighighaddr <= din;
            end
        end
    end

    always_ff @ (posedge clk) begin
        if (rden) begin
            if (addr[11:6] == 6'd0) begin
                dout <= mem[addr[5:0]];
            end else if (addr == C_ADDR_SRR) begin
                dout <= {15'b0, srr_rst};
            end else if (addr == C_ADDR_SR) begin
                dout <= {11'd0, sr_axirresperr, sr_axiaroverrun, sr_axibresperr,
                    sr_axiwoverrun, sr_axiawoverrun};
            end else if (addr == C_ADDR_HAR0) begin
                dout <= har0_axihighaddr;
            end else if (addr == C_ADDR_AHR1) begin
                dout <= {12'd0, har1_axighighaddr};
            end
        end
    end

    always_ff @ (posedge clk) begin
        if (rden && (addr == C_ADDR_SR)) begin
            {sr_axirresperr, sr_axiaroverrun, sr_axibresperr,
                sr_axiwoverrun, sr_axiawoverrun} <= 5'd0;
        end else begin
            if (reg_sr_axiawoverrun) sr_axiawoverrun <= 1'b1;
            if (reg_sr_axiwoverrun ) sr_axiwoverrun  <= 1'b1;
            if (reg_sr_axibresperr ) sr_axibresperr  <= 1'b1;
            if (reg_sr_axiaroverrun) sr_axiaroverrun <= 1'b1;
            if (reg_sr_axirresperr ) sr_axirresperr  <= 1'b1;
        end
    end

    assign reg_srr_rst = srr_rst;

    assign reg_har0_axihighaddr = har0_axihighaddr;

    assign reg_har1_axihighaddr = har0_axihighaddr;

endmodule

`default_nettype wire
