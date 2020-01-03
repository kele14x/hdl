/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module spi_master_top #(parameter CLK_RATIO   = 8) (
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

    localparam C_STATE_MAX   = CLK_RATIO / 2 * 17;

    localparam C_STATE_WIDTH = $clog2(C_STATE_MAX);


    // Variables
    //-----------

    var logic SCK, SS, MOSI, MISO;

    var logic [C_STATE_WIDTH-1:0] state, state_next;

    var logic s_idle, s_load, s_pre, s_sck1, s_out, s_in, s_rxv;

    var logic [7:0] tx_buffer;

    var logic [6:0] rx_buffer;

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
            state <= C_STATE_MAX;
        end else begin
            state <= state_next;
        end
    end

    assign s_idle = (state == C_STATE_MAX);
    assign s_load = (state == C_STATE_MAX - 1);
    assign s_out  = (state % CLK_RATIO == CLK_RATIO / 2) && !s_idle;
    assign s_pre  = (state < CLK_RATIO / 2);
    assign s_sck1 = ((state / (CLK_RATIO/2)) % 2) && !s_idle;

    // Sample MISO at state_cnt = m * CLK_RATIO; where m = 1,2,3...8
    assign s_in  = (state % CLK_RATIO == 0) && (state != 0);
    // We already sample one byte
    assign s_rxv = (state == 8 * CLK_RATIO);

    always_comb begin
        if (s_idle && spi_tx_valid) begin
            state_next = 'd0;
        end else if (s_load && spi_tx_valid) begin
            state_next = CLK_RATIO / 2;
        end else if (s_idle) begin
            state_next = state;
        end else begin
            state_next = state + 1;
        end
    end


    // TX Interface
    //==============

    // assert `spi_tx_ready` at the same time with S_IDLE and S_LOAD
    always_ff @ (posedge clk) begin
        if (rst) begin
            spi_tx_ready <= 1'b0;
        end else begin
            spi_tx_ready <= (state_next == C_STATE_MAX || state_next == C_STATE_MAX - 1);
        end
    end

    // When there is a valid transfer on tx interface, move the data into tx_data
    always_ff @ (posedge clk) begin
        if ((s_idle || s_load) && spi_tx_valid) begin
            tx_buffer <= spi_tx_data;
        end
    end


    // RX Interface
    //==============


    always_ff @ (posedge clk) begin
        if (s_in) begin
            rx_buffer <= {rx_buffer[5:0], MISO};
        end
    end

    always_ff @ (posedge clk) begin
        if (rst) begin
            spi_rx_valid <= 1'b0;
        end else begin
            spi_rx_valid <= s_rxv;
        end
    end

    always_ff @ (posedge clk) begin
        if (s_rxv) begin
            spi_rx_data <= {rx_buffer, MISO};
        end
    end


    // SPI SS & SCK
    //==============

    always_ff @ (posedge clk) begin
        SS <= s_idle;
    end

    always_ff @ (posedge clk) begin
        SCK <= s_sck1;
    end

    always_ff @ (posedge clk) begin
        if (s_idle || s_pre) begin
            MOSI <= 1'b0;
        end else begin
            MOSI <= tx_buffer[7 - (state - CLK_RATIO/2)/CLK_RATIO];
        end
    end

endmodule

`default_nettype wire
