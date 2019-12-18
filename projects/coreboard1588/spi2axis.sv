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
// This core is fixed CPOL = 0 and CPHA = 1. That is FPGA will output MISO at
// rising edge of clock, and will sample MOSI at failing edge.
//==============================================================================

module spi2axis (
    /* SPI */
    input  wire       SCK          ,
    input  wire       SS_N         ,
    input  wire       MOSI         ,
    inout  wire       MISO_Z       ,
    /* RAW */
    input  wire       aclk         ,
    input  wire       aresetn      ,
    // AXI4 Stream Master, Rx
    output wire [7:0] m_axis_tdata ,
    output wire       m_axis_tvalid,
    input  wire       m_axis_tready,
    // AXI4 Stream Slave, Tx
    input  wire [7:0] s_axis_tdata ,
    input  wire       s_axis_tvalid,
    output wire       s_axis_tready
);


    // CDC
    //=====

    (* IOB="true" *)
    reg SCK_iob;
    (* IOB="true" *)
    reg SS_iob;
    (* IOB="true" *)
    reg MOSI_iob; // RX
    (* IOB="true" *)
    reg MISO_iob; // TX

    reg SCK_s;

    // Mute output if module not selected
    IOBUF IOBUF_inst (
        .O (/* Not used */),
        .IO(MISO_Z        ),
        .I (MISO_iob      ),
        .T (SS_N          )
    );

    // Two level registers
    always_ff @ (posedge aclk) begin
        SCK_iob  <= SCK;
        SCK_s    <= SCK_iob;
        SS_iob   <= SS_N;
        MOSI_iob <= MOSI;
    end

    // SPI Event
    //===========

    wire capture_edge, output_edge;
    reg  capture_edge_d;

    assign capture_edge = ({SCK_iob, SCK_s}  == 2'b01); // rising edge
    assign output_edge = ({SCK_iob, SCK_s}  == 2'b10); // failing edge

    always_ff @ (posedge aclk) capture_edge_d <= capture_edge;


    // RX Logic
    //===========

    // SCK   -> SCK_iob      -> rx_cnt
    // MOSI  -> MOSI_iob     -> rx_srl         -> rx_data_r
    //          capture_edge -> capture_edge_d -> rx_valid_r

    reg [7:0] rx_srl;
    reg [2:0] rx_cnt;

    // RX, no reset
    always_ff @ (posedge aclk)
        if (SS_iob)
            rx_srl <= 'b0;
        else if (capture_edge)
            // Shift in to LSB
            rx_srl <= {rx_srl[6:0], MOSI_iob};

    // SPI tanscation bit counter, async reset
    always_ff @ (posedge aclk)
        if (SS_iob)
            rx_cnt <= 'hFF;
        else if (capture_edge)
            rx_cnt <= rx_cnt + 1;


    // AXIS Master
    //=============

    reg [7:0] rx_data_r;
    reg       rx_valid_r;

    always_ff @ (posedge aclk) begin
        if (capture_edge_d && (rx_cnt == 7)) begin
            // we already captured 1 byte data, move to axis i/f
            rx_data_r <= rx_srl;
        end
    end

    always_ff @ (posedge aclk) begin
        if (~aresetn)
            rx_valid_r <= 1'b0;
        else if (capture_edge_d && (rx_cnt == 7)) begin
            // when 1 byte is moved to axis i/f, assert valid at same time
            rx_valid_r <= 1'b1;
        end else if (rx_valid_r && m_axis_tready) begin
            rx_valid_r <= 1'b0;
        end
    end

    assign m_axis_tdata = rx_data_r;
    assign m_axis_tvalid = rx_valid_r;


    // TX Logic
    //==========
    
    wire tx_load_byte;

    reg [7:0] tx_data;
    reg       tx_cached;
    reg [2:0] tx_cnt;
    reg [7:0] tx_srl;

    always_ff @ (posedge aclk)
        if (SS_iob)
            tx_cnt <= 'hF;
        else if (output_edge)
            tx_cnt <= tx_cnt + 1;

    // Output MSB first
    always_ff @ (posedge aclk)
        MISO_iob <= tx_srl[7];

    assign tx_load_byte = output_edge && (tx_cnt == 7);

    // To output one byte, we will load byte 1 time, and shift srl 7 times
    always_ff @ (posedge aclk)
        // When there is no data at Shift Register
        if (tx_load_byte)
            // Load new byte
            tx_srl <= tx_cached ? tx_data : 8'h5;
        else if (output_edge)
            // Shift out 1 bit
            tx_srl <= {tx_srl[6:0], 1'b0};


    // AXIS Slave
    //============

    // s_axis_tdata  -> tx_data   -> tx_srl
    // s_axis_tvalid -> tx_cached ->
    // s_axis_tready -> 

    reg       tx_ready;

    always_ff @ (posedge aclk)
        if (tx_ready && s_axis_tvalid)
            tx_data <= s_axis_tdata;

    always_ff @ (posedge aclk)
        if (~aresetn)
            tx_cached <= 'b0;
        else if (s_axis_tvalid && tx_ready)
            tx_cached <= 1'b1;
        else if (tx_load_byte)
            tx_cached <= 'b0;

    always_ff @ (posedge aclk)
        if (~aresetn)
            tx_ready <= 1'b0;
        else if (s_axis_tvalid && tx_ready)
            tx_ready <= 1'b0;
        else if (tx_load_byte)
            tx_ready <= 1'b1;
        else
            tx_ready <= ~tx_cached;

    assign s_axis_tready = tx_ready;

endmodule
