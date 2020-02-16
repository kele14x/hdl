/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module axis_spi_slave_top #(parameter C_DATA_WIDTH = 8 // 8, 16, 24, 32
) (
    // SPI
    //=====
    input  wire                    SS_I          ,
    output wire                    SS_O          ,
    output wire                    SS_T          ,
    input  wire                    SCK_I         ,
    output wire                    SCK_O         ,
    output wire                    SCK_T         ,
    input  wire                    IO0_I         , // SI
    output wire                    IO0_O         ,
    output wire                    IO0_T         ,
    input  wire                    IO1_I         , // SO
    output wire                    IO1_O         ,
    output wire                    IO1_T         ,
    // RAW
    //=====
    input  wire                    aclk          ,
    input  wire                    aresetn       ,
    // Rx i/f, beat at each bit
    output reg  [C_DATA_WIDTH-1:0] axis_rx_tdata ,
    output reg                     axis_rx_tvalid,
    input  wire                    axis_rx_tready,
    // Tx i/f, beat at each word
    input  wire [C_DATA_WIDTH-1:0] axis_tx_tdata ,
    input  wire                    axis_tx_tvalid,
    output wire                    axis_tx_tready
);


    initial
        assert (C_DATA_WIDTH == 8 || C_DATA_WIDTH == 16 || C_DATA_WIDTH == 16 || C_DATA_WIDTH == 32) else
            $error("C_DATA_WIDTH must be 8, 16, 32 or 64.");


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

    axis_spi_slave_cdc #(.C_DATA_WIDTH(3)) i_spi_cdc (
        .clk (aclk                ),
        .din ({SCK_I, SS_I, IO0_I}),
        .dout({SCK_s, SS_s, SI_s })
    );

    // SPI Event
    //----------

    reg SCK_d;

    wire capture_edge, output_edge;

    always_ff @ (posedge aclk) begin
        SCK_d <= SCK_s;
    end

    assign capture_edge = ({SCK_s, SCK_d}  == 2'b01) && !SS_s; // failing edge
    assign output_edge  = ({SCK_s, SCK_d}  == 2'b10) && !SS_s; // rising edge

    // RX Logic
    //----------

    reg [          C_DATA_WIDTH-2:0] rx_shift ;
    reg [$clog2(C_DATA_WIDTH-1)-1:0] rx_bitcnt;

    wire [C_DATA_WIDTH-1:0] rx_data ;
    wire                    rx_valid;

    always_ff @ (posedge aclk) begin
        if (SS_s) begin
            rx_bitcnt <= 'd0;
        end else if (capture_edge) begin
            rx_bitcnt <= rx_bitcnt + 1;
        end
    end

    // Shift into rx_shift at LSB
    always_ff @ (posedge aclk) begin
        if (capture_edge) begin
            rx_shift <= {rx_shift[C_DATA_WIDTH-3:0], SI_s};
        end
    end

    assign rx_data = {rx_shift, SI_s};

    assign rx_valid = capture_edge && (rx_bitcnt == C_DATA_WIDTH - 1);

    // RX AXIS
    //--------
    
    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            axis_rx_tdata <= 'd0;
        end else if (rx_valid && !(axis_rx_tvalid && !axis_rx_tready))begin
            axis_rx_tdata <= rx_data;
        end
    end

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            axis_rx_tvalid <= 1'b0;
        end else if (rx_valid) begin
            axis_rx_tvalid <= 1'b1;
        end else if (axis_rx_tready) begin
            axis_rx_tvalid <= 1'b0;
        end
    end

    // TX Logic
    //---------

    reg [          C_DATA_WIDTH-2:0] tx_shift;
    reg [$clog2(C_DATA_WIDTH-1)-1:0] tx_bitcnt;

    always_ff @ (posedge aclk) begin
        if (SS_s) begin
            tx_bitcnt <= 'd0;
        end else if (output_edge) begin
            tx_bitcnt <= tx_bitcnt + 1;
        end
    end

    assign axis_tx_tready = output_edge && (tx_bitcnt == 'd0);

    always_ff @ (posedge aclk) begin
        if (output_edge) begin
            if (tx_bitcnt == 0) begin
                {SO_r, tx_shift} <= axis_tx_tvalid ? axis_tx_tdata : 'd0;
            end else begin
                {SO_r, tx_shift} <= {tx_shift, 1'b0};
            end
        end
    end

endmodule

`default_nettype wire
