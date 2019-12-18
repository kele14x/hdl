/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

//==============================================================================
//
// SPI Interface timing:
//
//                         ___     ___     ___     ___     ___
//  SCK   CPOL=0  ________/   \___/   \___/   \___/   \___/   \______________
//                ________     ___     ___     ___     ___     ______________
//        CPOL=1          \___/   \___/   \___/   \___/   \___/
//
//                ____                                             __________
//  SS                \___________________________________________/
//
//                     _______ _______ _______ _______ _______
//  MOSI  CPHA=0  zzzzX___0___X___1___X__...__X___6___X___7___X---Xzzzzzzzzzz
//  MISO                   _______ _______ _______ _______ _______
//        CPHA=1  zzzz----X___0___X___1___X__...__X___6___X___7___Xzzzzzzzzzz
//
// This core is fixed CPOL = 0 and CPHA = 1. That is FPGA will drive SO at
// rising edge of SCK, and will sample SI at failing edge of SCK.
//==============================================================================

module spi2raw (
    // SPI
    //=====
    input  wire         SCK_I        ,
    output logic        SCK_O        ,
    output logic        SCK_T        ,
    input  wire         SS_I         ,
    output logic        SS_O         ,
    output logic        SS_T         ,
    input  wire         IO0_I        , // SI
    output logic        IO0_O        ,
    output logic        IO0_T        ,
    input  wire         IO1_I        , // SO
    output logic        IO1_O        ,
    output logic        IO1_T        ,
    // RAW
    //=======
    input  wire         clk ,
    input  wire         rst ,
    // AXI4 Stream Master, Rx
    output logic [7:0] rx_data ,
    output logic       rx_valid,
    // AXI4 Stream Slave, Tx
    input  wire  [7:0] tx_data
);

    // SPI Interface
    //==============

    logic SCK_s, SS_s, SI_s, SO_r;

    // Slave license to SCK, SS, IO0 only

    assign SCK_T = 1;
    assign SCK_O = 0;

    assign SS_T = 1;
    assign SS_O = 0;

    assign IO0_T = 1;
    assign IO0_O = 0;

    // Slave output to IO1 when SS is selected

    assign IO1_O = SO_r;
    assign IO1_T = SS_I;

    // SPI CDC
    //---------

    (* ASYNC_REG="true" *)
    logic SCK_cdc_reg1, SCK_cdc_reg2;
    (* ASYNC_REG="true" *)
    logic SS_cdc_reg1, SS_cdc_reg2;
    (* ASYNC_REG="true" *)
    logic SI_cdc_reg1, SI_cdc_reg2;

    always_ff @ (posedge clk) begin
        SCK_cdc_reg1 <= SCK_I;
        SCK_cdc_reg2 <= SCK_cdc_reg1;
    end

    always_ff @ (posedge clk) begin
        SS_cdc_reg1 <= SS_I;
        SS_cdc_reg2 <= SS_cdc_reg1;
    end

    always_ff @ (posedge clk) begin
        SI_cdc_reg1 <= IO0_I;
        SI_cdc_reg2 <= SI_cdc_reg1;
    end

    assign SCK_s = SCK_cdc_reg2;
    assign SS_s = SS_cdc_reg2;
    assign SI_s = SI_cdc_reg2;


    // SPI Event
    //===========

    logic SCK_d, SS_d;

    logic capture_edge, output_edge;

    always_ff @ (posedge clk) begin
        SCK_d <= SCK_s;
        SS_d  <= SS_s;
    end

    assign capture_edge = ({SCK_cdc_reg2, SCK_d}  == 2'b01); // failing edge
    assign output_edge  = ({SCK_cdc_reg2, SCK_d}  == 2'b10); // rising edge

    // RX Logic
    //----------

    logic [6:0] rx_shift;
    logic [2:0] rx_cnt;

    always_ff @ (posedge clk) begin
        if (SS_s) begin
            rx_cnt <= 8'd0;
        end else if (capture_edge) begin
            rx_cnt <= rx_cnt + 1;
        end
    end

    always_ff @ (posedge clk) begin
        if (capture_edge) begin
            rx_shift <= {rx_shift[5:0], SI_s};
        end
    end

    assign rx_data = {rx_shift, SI_s};

    assign rx_valid = (capture_edge && (rx_cnt == 7));

    // TX Logic
    //---------

    logic [6:0] tx_shift;
    logic [2:0] tx_cnt;

    always_ff @ (posedge clk) begin
        if (SS_s) begin
            tx_cnt <= 3'd0;
        end else if (output_edge) begin
            tx_cnt <= tx_cnt + 1;
        end
    end

    always_ff @ (posedge clk) begin
        if (output_edge) begin
            if (tx_cnt == 0) begin
                {SO_r, tx_shift} <= tx_data;
            end else begin
                {SO_r, tx_shift} <= {tx_shift, 1'b0};
            end
        end
    end

endmodule

`default_nettype wire
