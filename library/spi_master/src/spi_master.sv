/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

//=============================================================================
//
// Filename: axis_spi_master.sv
//
// Purpose: SPI master core with AXI4-Stream interface, this core was designed
//   to interface other cores easily.
//
// Note:
//   SPI Interface timing:
//
//                             ___     ___     ___     ___     ___
//      SCK   CPOL=0  ________/   \___/   \___/   \___/   \___/   \____________
//                    ________     ___     ___     ___     ___     ____________
//            CPOL=1          \___/   \___/   \___/   \___/   \___/
//
//                    ____                                             ________
//      SS                \___________________________________________/
//
//                         _______ _______ _______ _______ _______
//      MOSI/ CPHA=0  zzzzX___0___X___1___X__...__X___6___X___7___X---Xzzzzzzzz
//      MISO                   _______ _______ _______ _______ _______
//            CPHA=1  zzzz----X___0___X___1___X__...__X___6___X___7___Xzzzzzzzz
//
// Limitation:
//   This core is fixed CPOL = 0 and CPHA = 1. That means both master and salve
//   (this core) will drive MOSI/MISO at rising edge of SCK, and should sample
//   MISO/MOSI at falling edge.
//
//=============================================================================

`timescale 1 ns / 1 ps
`default_nettype none

module spi_master #(parameter CLK_RATIO   = 8) (
    // SPI
    //=====
    input  var logic       SCK_I       ,
    output var logic       SCK_O       ,
    output var logic       SCK_T       ,
    input  var logic       SS_I        ,
    output var logic       SS_O        ,
    output var logic       SS_T        ,
    input  var logic       IO0_I       ,
    output var logic       IO0_O       , // MO
    output var logic       IO0_T       ,
    input  var logic       IO1_I       , // MI
    output var logic       IO1_O       ,
    output var logic       IO1_T       ,
    // Fabric
    //=======
    input  var logic       clk         ,
    input  var logic       rst         ,
    // Tx interface
    //--------------
    input  var logic [7:0] spi_tx_data ,
    input  var logic       spi_tx_valid,
    output var logic       spi_tx_ready,
    // Rx interface
    //--------------
    output var logic [7:0] spi_rx_data ,
    output var logic       spi_rx_valid
);


    // Parameter Check
    //------------------

    initial begin
        assert (CLK_RATIO / 2 == 0 && CLK_RATIO >= 2)
            else $error("CLK_RATIO must be an positive even number.");
    end

    localparam C_EDGE_CNT_MAX   = CLK_RATIO / 2 - 1;
    localparam C_EDGE_CNT_WIDTH = $clog2(C_EDGE_CNT_MAX) > 0 ? $clog2(C_EDGE_CNT_MAX) : 1;

    // Variables
    //-----------

    var logic SCK, SS, MOSI, MISO;

    typedef enum {S_RST, S_IDLE, S_PRE, S_TS0, S_TS1, S_TS2, S_TS3, S_TS4, 
        S_TS5, S_TS6, S_TS7, S_TS8, S_TS9, S_TS10, S_TS11, S_TS12, S_TS13, 
        S_TS14, S_TS15} STATE_T;
    STATE_T state_next, state;

    var logic state_next_tsx;

    var logic edge_cnt_max;

    var logic [C_EDGE_CNT_WIDTH-1:0] edge_cnt = 0;


    // SPI Interface
    //---------------

    assign SCK_T = 0;
    assign SCK_O = SCK;

    assign SS_T = 0;
    assign SS_O = SS;

    assign IO0_T = SS;
    assign IO0_O = MOSI;

    assign IO1_T = 1;
    assign IO1_O = 0;
    assign MISO = IO1_I;


    // TX State Machine
    //==================

    // `stat_cnt` state machine
    always_ff @ (posedge clk) begin
        if (rst) begin
            state <= S_RST;
        end else begin
            state <= state_next;
        end
    end

    always_comb begin
        case(state)
            S_RST  : state_next = S_IDLE;
            S_IDLE : state_next = !spi_tx_valid ? S_IDLE : S_PRE;    // Wait for tx data at tx interface
            S_PRE  : state_next = !edge_cnt_max ? S_PRE  : S_TS0;
            S_TS0  : state_next = !edge_cnt_max ? S_TS0  : S_TS1;
            S_TS1  : state_next = !edge_cnt_max ? S_TS1  : S_TS2;
            S_TS2  : state_next = !edge_cnt_max ? S_TS2  : S_TS3;
            S_TS3  : state_next = !edge_cnt_max ? S_TS3  : S_TS4;
            S_TS4  : state_next = !edge_cnt_max ? S_TS4  : S_TS5;
            S_TS5  : state_next = !edge_cnt_max ? S_TS5  : S_TS6;
            S_TS6  : state_next = !edge_cnt_max ? S_TS6  : S_TS7;
            S_TS7  : state_next = !edge_cnt_max ? S_TS7  : S_TS8;
            S_TS8  : state_next = !edge_cnt_max ? S_TS8  : S_TS9;
            S_TS9  : state_next = !edge_cnt_max ? S_TS9  : S_TS10;
            S_TS10 : state_next = !edge_cnt_max ? S_TS10 : S_TS11;
            S_TS11 : state_next = !edge_cnt_max ? S_TS11 : S_TS12;
            S_TS12 : state_next = !edge_cnt_max ? S_TS12 : S_TS13;
            S_TS13 : state_next = !edge_cnt_max ? S_TS13 : S_TS14;
            S_TS14 : state_next = !edge_cnt_max ? S_TS14 : S_TS15;
            S_TS15 : state_next = (spi_tx_valid && edge_cnt_max) ? S_TS0 :
                                   spi_tx_valid                  ? S_PRE :
                                   edge_cnt_max                  ? S_IDLE : S_TS15;
            default: state_next = S_RST;
        endcase
    end

    assign state_next_tsx = (state_next == S_TS0 || state_next == S_TS1 || 
        state_next == S_TS2 || state_next == S_TS3 || state_next == S_TS4 || 
        state_next == S_TS5 || state_next == S_TS6 || state_next == S_TS7 || 
        state_next == S_TS8 || state_next == S_TS9 || state_next == S_TS10 || 
        state_next == S_TS11 || state_next == S_TS12 || state_next == S_TS13 || 
        state_next == S_TS14 || state_next == S_TS15);

    
    // Clock Ratio counter
    //---------------------

    assign edge_cnt_max = (edge_cnt == C_EDGE_CNT_MAX);

    always_ff @ (posedge clk) begin
        if (rst) begin
            edge_cnt <= C_EDGE_CNT_MAX;
        end else if (state_next_tsx || state_next == S_PRE) begin
            edge_cnt <= (edge_cnt == C_EDGE_CNT_MAX) ? 'd0 : edge_cnt + 1;
        end else begin // other states
            edge_cnt <= C_EDGE_CNT_MAX;
        end
    end

    // TX Interface
    //==============

    var logic [7:0] tx_buffer;

    // assert `spi_tx_ready` at the same time with S_IDLE and S_LOAD
    always_ff @ (posedge clk) begin
        if (rst) begin
            spi_tx_ready <= 1'b0;
        end else begin
            spi_tx_ready <= (state_next == S_IDLE || state_next == S_TS15);
        end
    end

    // When there is a valid transfer on tx interface, move the data into tx_data
    always_ff @ (posedge clk) begin
        if ((state == S_IDLE) && spi_tx_valid) begin
            {MOSI, tx_buffer} <= {1'b0, spi_tx_data};
        end else if (state == S_TS15 && spi_tx_valid && !edge_cnt_max) begin
            {MOSI, tx_buffer} <= {MOSI, spi_tx_data};
        end else if (state == S_TS15 && spi_tx_valid && edge_cnt_max) begin
            {MOSI, tx_buffer} <= {spi_tx_data, 1'b0};
        end else if ((state == S_PRE || state == S_TS1 || state == S_TS3 || 
            state == S_TS5 || state == S_TS7 || state == S_TS9 || 
            state == S_TS11 || state == S_TS13 || state == S_TS15) && 
            edge_cnt_max) begin
            {MOSI, tx_buffer} <= {tx_buffer, 1'b0};
        end
    end


    // RX Interface
    //==============

    var logic [6:0] rx_buffer;

    always_ff @ (posedge clk) begin
        if (edge_cnt_max && (state == S_TS0 || state == S_TS2 || 
            state == S_TS4 || state == S_TS6 || state == S_TS8 || 
            state == S_TS10 || state == S_TS12 || state == S_TS14)) begin
            rx_buffer <= {rx_buffer[5:0], MISO};
        end
    end

    always_ff @ (posedge clk) begin
        if (rst) begin
            spi_rx_valid <= 1'b0;
        end else begin
            spi_rx_valid <= (edge_cnt_max && (state == S_TS14));
        end
    end

    always_ff @ (posedge clk) begin
        if (edge_cnt_max && (state == S_TS14)) begin
            spi_rx_data <= {rx_buffer, MISO};
        end
    end


    // SPI SS & SCK
    //==============

    always_ff @ (posedge clk) begin
        SS <= !(state_next_tsx || state_next == S_PRE);
    end

    always_ff @ (posedge clk) begin
        SCK <= (state_next == S_TS0 || state_next == S_TS2 || 
            state_next == S_TS4 || state_next == S_TS6 || 
            state_next == S_TS8 || state_next == S_TS10 || 
            state_next == S_TS12 || state_next == S_TS14);
    end

endmodule

`default_nettype wire
