/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module spi_slave_top #(
    parameter WIDTH = 8 // 8, 16, 24, 32
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
    output wire [          WIDTH-1:0] rx_data  ,
    output reg  [$clog2(WIDTH-1)-1:0] rx_bitcnt,
    output wire                       rx_valid ,
    // Tx i/f, beat at each word
    input  wire [          WIDTH-1:0] tx_data  ,
    output reg                        tx_load
);


    initial
        if (!(WIDTH == 8 || WIDTH == 16 || WIDTH == 16 || WIDTH == 32))
            $error("WIDTH must be 8, 16, 32 or 64.");


    // SPI Interface
    //==============

    wire SCK_s, SS_s, SI_s;
    reg  SO_r;

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

    spi_slave_cdc #(.C_DATA_WIDTH(3)) i_spi_cdc (
        .clk (clk                 ),
        .din ({SCK_I, SS_I, IO0_I}),
        .dout({SCK_s, SS_s, SI_s })
    );

    // SPI Event
    //----------

    reg SCK_d;

    wire capture_edge, output_edge;

    always @ (posedge clk) begin
        SCK_d <= SCK_s;
    end

    assign capture_edge = ({SCK_s, SCK_d}  == 2'b01) && !SS_s; // failing edge
    assign output_edge  = ({SCK_s, SCK_d}  == 2'b10) && !SS_s; // rising edge

    // RX Logic
    //----------

    reg  [WIDTH-2:0] rx_shift;

    always @ (posedge clk) begin
        if (SS_s) begin
            rx_bitcnt <= 'd0;
        end else if (capture_edge) begin
            rx_bitcnt <= rx_bitcnt + 1;
        end
    end

    // Shift into rx_shift at LSB
    always @ (posedge clk) begin
        if (capture_edge) begin
            rx_shift <= {rx_shift[WIDTH-3:0], SI_s};
        end
    end

    assign rx_ss = SS_s;

    assign rx_data = {rx_shift, SI_s};

    assign rx_valid = capture_edge;

    // TX Logic
    //---------

    reg [          WIDTH-2:0] tx_shift;
    reg [$clog2(WIDTH-1)-1:0] tx_bitcnt;

    always @ (posedge clk) begin
        if (SS_s) begin
            tx_bitcnt <= 'd0;
        end else if (output_edge) begin
            tx_bitcnt <= tx_bitcnt + 1;
        end
    end

    always @ (posedge clk) begin
        if (SS_s) begin
            tx_load <= 1'd0;
        end else begin
            tx_load <= output_edge && (tx_bitcnt == 'd0);
        end
    end

    always @ (posedge clk) begin
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
