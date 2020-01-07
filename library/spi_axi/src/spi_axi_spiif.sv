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

//                ____                                             __________
//  SS                \___________________________________________/
//                         ___     ___     ___     ___     ___
//  SCK   CPOL=0  ________/   \___/   \___/   \___/   \___/   \______________
//
//  MOSI                   _______ _______ _______ _______ _______
//  MISO  CPHA=1  zzzzxxxxX___0___X___1___X__...__X___6___X___7___Xzzzzzzzzzz
//
// This core is fixed CPOL = 0 and CPHA = 1. That is FPGA will drive SO at
// rising edge of SCK, and will sample SI at failing edge of SCK.
//==============================================================================

module spi_axi_spiif #(parameter WIDTH = 8 // 8, 16, 24, 32
) (
    // SPI
    //=====
    input  wire                       SS_I     ,
    output wire                       SS_O     ,
    output wire                       SS_T     ,
    input  wire                       SCK_I    ,
    output wire                       SCK_O    ,
    output wire                       SCK_T    ,
    input  wire                       IO0_I    , // SI
    output wire                       IO0_O    ,
    output wire                       IO0_T    ,
    input  wire                       IO1_I    , // SO
    output wire                       IO1_O    ,
    output wire                       IO1_T    ,
    // RAW
    //=====
    input  wire                       clk      ,
    input  wire                       rst      ,
    // Rx i/f, beat at each bit
    output wire                       rx_ss    ,
    output wire [          WIDTH-1:0] rx_byte  ,
    output reg  [$clog2(WIDTH-1)-1:0] rx_bitcnt,
    output wire                       rx_valid ,
    // Tx i/f, beat at each word
    input  wire [          WIDTH-1:0] tx_data  ,
    output reg                        tx_load
);


    initial assert (WIDTH == 8 || WIDTH == 8 || WIDTH == 8 || WIDTH == 8) else
        $error("WIDTH must be 8, 16, 32 or 64.");


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

    spi_axi_spi_cdc #(.C_DATA_WIDTH(3)) i_spi_cdc (
        .clk (clk                 ),
        .din ({SCK_I, SS_I, IO0_I}),
        .dout({SCK_s, SS_s, SI_s })
    );

    // SPI Event
    //----------

    logic SCK_d;

    logic capture_edge, output_edge;

    always_ff @ (posedge clk ) begin
        SCK_d <= SCK_s;
    end

    assign capture_edge = ({SCK_s, SCK_d}  == 2'b01) && !SS_s; // failing edge
    assign output_edge  = ({SCK_s, SCK_d}  == 2'b10) && !SS_s; // rising edge

    // RX Logic
    //----------

    reg  [6:0] rx_shift;

    always_ff @ (posedge clk) begin
        if (SS_s) begin
            rx_bitcnt <= 4'd0;
        end else if (capture_edge) begin
            rx_bitcnt <= rx_bitcnt + 1;
        end
    end

    // Shift into rx_shift at LSB
    always_ff @ (posedge clk) begin
        if (capture_edge) begin
            rx_shift <= {rx_shift[5:0], SI_s};
        end
    end

    assign rx_ss = SS_s;

    assign rx_byte = {rx_shift, SI_s};

    assign rx_valid = capture_edge;

    // TX Logic
    //---------

    reg [6:0] tx_shift;
    reg [2:0] tx_bitcnt;

    always_ff @ (posedge clk) begin
        if (SS_s) begin
            tx_bitcnt <= 'd0;
        end else if (output_edge) begin
            tx_bitcnt <= tx_bitcnt + 1;
        end
    end

    always_ff @ (posedge clk) begin
        if (SS_s) begin
            tx_load <= 1'd0;
        end else begin
            tx_load <= output_edge && (tx_bitcnt == 3'd0);
        end
    end

    always_ff @ (posedge clk) begin
        if (output_edge) begin
            if (tx_bitcnt == 0) begin
                {SO_r, tx_shift} <= tx_data;
            end else begin
                {SO_r, tx_shift} <= {tx_shift, 1'b0};
            end
        end
    end

endmodule

`default_nettype wire
