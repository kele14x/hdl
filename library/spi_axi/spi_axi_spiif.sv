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

module spi_axi_spiif (
    // SPI
    //=====
    input  wire        SCK_I   ,
    output wire        SCK_O   ,
    output wire        SCK_T   ,
    input  wire        SS_I    ,
    output wire        SS_O    ,
    output wire        SS_T    ,
    input  wire        IO0_I   , // SI
    output wire        IO0_O   ,
    output wire        IO0_T   ,
    input  wire        IO1_I   , // SO
    output wire        IO1_O   ,
    output wire        IO1_T   ,
    // RAW
    //======
    input  wire        clk     ,
    input  wire        rst     ,
    // AXI4 Stream Master, Rx
    output wire  [7:0] rx_data ,
    output reg         rx_first,
    output wire        rx_valid,
    // AXI4 Stream Slave, Tx
    input  wire  [7:0] tx_data ,
    output reg         tx_load
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

    spi_axi_spi_cdc #(.C_DATA_WIDTH(3)) i_spi_cdc (
        .clk (clk                 ),
        .din ({SCK_I, SS_I, IO0_I}),
        .dout({SCK_s, SS_s, SI_s })
    );

    // SPI Event
    //----------

    logic SCK_d, SS_d;

    logic capture_edge, output_edge;

    always_ff @ (posedge clk ) begin
        SCK_d <= SCK_s;
        SS_d  <= SS_s;
    end

    assign capture_edge = ({SCK_s, SCK_d}  == 2'b01); // failing edge
    assign output_edge  = ({SS_s , SCK_d}  == 2'b10); // rising edge

    // RX Logic
    //----------

    reg  [6:0] rx_shift;
    reg  [2:0] rx_bitcnt;  // 0 ~ 15 bits

    always_ff @ (posedge clk ) begin
        if (SS_s) begin
            rx_bitcnt <= 4'd0;
        end else if (capture_edge) begin
            rx_bitcnt <= rx_bitcnt + 1;
        end
    end

    always_ff @ (posedge clk ) begin
        if (SS_s) begin
            rx_first <= 1'd1;
        end else if (capture_edge && (&rx_bitcnt)) begin
            rx_first <= 1'b0;
        end
    end

    // Shift into rx_shift at LSB
    always_ff @ (posedge clk ) begin
        if (capture_edge) begin
            rx_shift <= {rx_shift[5:0], SI_s};
        end
    end

    assign rx_data = {rx_shift, SI_s};

    assign rx_valid = capture_edge && (&rx_bitcnt);

    // TX Logic
    //---------

    reg [6:0] tx_shift;
    reg [2:0] tx_bitcnt;

    always_ff @ (posedge clk ) begin
        if (SS_s) begin
            tx_bitcnt <= 4'd0;
        end else if (output_edge) begin
            tx_bitcnt <= tx_bitcnt + 1;
        end
    end

    always_ff @ (posedge clk ) begin
        if (SS_s) begin
            tx_load <= 4'd0;
        end else begin
            tx_load <= output_edge && (tx_bitcnt == 3'd0);
        end
    end

    always_ff @ (posedge clk ) begin
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
