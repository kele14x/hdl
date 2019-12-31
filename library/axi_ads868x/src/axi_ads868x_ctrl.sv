/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

// Auto SPI Send 32-bit: MAN_Ch_n (16-bit) NOP (16-bit)

module axi_ads868x_ctrl (
    input  wire       aclk         ,
    input  wire       aresetn      ,
    //
    input  wire       pps          ,
    // SPI send
    output reg  [7:0] spi_tx_tdata ,
    output reg        spi_tx_tvalid,
    input  wire       spi_tx_tready,
    // SPI recv
    input  wire [7:0] spi_rx_tdata ,
    input  wire       spi_rx_tvalid,
    output reg        spi_rx_tready,
    // ADC
    output reg [15:0] adc_tdata    ,
    output reg        adc_tvalid   ,
    input  wire       adc_tready   ,
    //
    output wire       CH_SEL_A0    ,
    output wire       CH_SEL_A1    ,
    output wire       CH_SEL_A2
);

    import ads868x_pkg::*;

    // Sample tick counter
    //---------------------

    localparam C_TS_CNT_MAX = 125000-1;
    localparam C_TS_CNT_WIDTH = $clog2(C_TS_CNT_MAX); 

    // [13:11] A[2:0]
    // [10: 9] M[1:0]
    // [ 8: 0] SPI Seq
    reg [C_TS_CNT_WIDTH-1:0] ts_cnt;

    // ts_cnt is tick counter runs from 0 to C_TS_TICK, to generate the sample
    // ticks
    always_ff @ (posedge aclk) begin
        if (!aresetn || pps) begin
            ts_cnt <= {C_TS_CNT_WIDTH{1'b1}};
        end else begin
            ts_cnt <= (ts_cnt == C_TS_CNT_MAX) ? 'd0 : ts_cnt + 1;
        end
    end


    // SPI TX
    //--------
    
    reg [31:0] tx_buffer;
    reg [ 1:0] tx_nbytes;
    reg        tx_valid;

    reg [31:0] rx_buffer;
    reg        rx_valid;

    typedef enum {S_TXRST, S_TXIDLE, S_TXCMD3, S_TXCMD2, S_TXCMD1, S_TXCMD0} TX_STATE_T;

    TX_STATE_T tx_state, tx_state_next;
    
    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            tx_state <= S_TXRST;
        end else begin
            tx_state <= tx_state_next;
        end
    end

    always_comb begin
        case(tx_state)
            S_TXRST : tx_state_next = S_TXIDLE;
            S_TXIDLE: tx_state_next = !tx_valid       ? S_TXIDLE : 
                                       tx_nbytes == 3 ? S_TXCMD3 :
                                       tx_nbytes == 2 ? S_TXCMD2 :
                                       tx_nbytes == 1 ? S_TXCMD1 : S_TXCMD0;
            S_TXCMD3: tx_state_next = !spi_tx_tready ? S_TXCMD3 : S_TXCMD2;
            S_TXCMD2: tx_state_next = !spi_tx_tready ? S_TXCMD2 : S_TXCMD1;
            S_TXCMD1: tx_state_next = !spi_tx_tready ? S_TXCMD1 : S_TXCMD0;
            S_TXCMD0: tx_state_next = !spi_tx_tready ? S_TXCMD0 : S_TXIDLE;
            default : tx_state_next = S_TXRST;
        endcase
    end

    // spi_tx_tdata
    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            spi_tx_tdata <= 'd0;
        end else if (tx_state_next == S_TXCMD3) begin
            spi_tx_tdata <= tx_buffer[31:24];
        end else if (tx_state_next == S_TXCMD2) begin
            spi_tx_tdata <= tx_buffer[23:16];
        end else if (tx_state_next == S_TXCMD1) begin
            spi_tx_tdata <= tx_buffer[15: 8];
        end else if (tx_state_next == S_TXCMD0) begin
            spi_tx_tdata <= tx_buffer[ 7: 0];
        end else begin
            spi_tx_tdata <= 'd0;
        end
    end
    
    // spi_tx_tvalid
    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            spi_tx_tvalid <= 1'b0;
        end else begin
            spi_tx_tvalid <= (tx_state_next == S_TXCMD3 || 
                tx_state_next == S_TXCMD2 || tx_state_next == S_TXCMD1 ||
                tx_state_next == S_TXCMD0);
        end
    end


    // SPI RX
    //---------

    typedef enum {S_RXRST, S_RXIDLE, S_RXCMD3, S_RXCMD2, S_RXCMD1, S_RXCMD0} RX_STATE_T;

    RX_STATE_T rx_state, rx_state_next;

    // Stay ready is not reset 
    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            spi_rx_tready <= 1'b0;
        end else begin
            spi_rx_tready <= 1'b1;
        end
    end

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            rx_state <= S_RXRST;
        end else begin
            rx_state <= rx_state_next;
        end
    end

    always_comb begin
        case(rx_state)
            S_RXRST : rx_state_next = S_RXIDLE;
            S_RXIDLE: rx_state_next = !tx_valid ? S_RXIDLE : S_RXCMD3;
            S_RXCMD3: rx_state_next = !spi_rx_tvalid ? S_RXCMD3 : S_RXCMD2;
            S_RXCMD2: rx_state_next = !spi_rx_tvalid ? S_RXCMD2 : S_RXCMD1;
            S_RXCMD1: rx_state_next = !spi_rx_tvalid ? S_RXCMD1 : S_RXCMD0;
            S_RXCMD0: rx_state_next = !spi_rx_tvalid ? S_RXCMD0 : S_RXIDLE;
            default : rx_state_next = S_RXRST;
        endcase
    end

    always_ff @ (posedge aclk) begin
        if (rx_state == S_RXCMD3 && spi_rx_tvalid) begin
            rx_buffer[31:24] <= spi_rx_tdata;
        end 
        if (rx_state == S_RXCMD2 && spi_rx_tvalid) begin
            rx_buffer[23:16] <= spi_rx_tdata;
        end 
        if (rx_state == S_RXCMD2 && spi_rx_tvalid) begin
            rx_buffer[15: 8] <= spi_rx_tdata;
        end 
        if (rx_state == S_RXCMD0 && spi_rx_tvalid) begin
            rx_buffer[ 7: 0] <= spi_rx_tdata;
        end
    end

    always_ff @ (posedge aclk) begin
        rx_valid <= (rx_state == S_RXCMD0 && spi_rx_tvalid);
    end


    // ADC M AXIS
    //-------------

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            adc_tdata <= 'd0;
        end else if (rx_valid && !(adc_tvalid && !adc_tready)) begin
            adc_tdata <= rx_buffer[15:0];
        end
    end

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            adc_tvalid <= 1'b0;
        end else if (rx_valid) begin
            adc_tvalid <= 1'b1;
        end if (adc_tready) begin
            adc_tvalid <= 1'b0;
        end
    end

    // Sample control
    //----------------

    reg [2:0] ext_mux_ch;

    function [16:0] sample_on_tick(input [16:0] cnt);
        reg [15:0] cmd;
        begin
            for (int i = 0; i < 32; i++) begin
                if (cnt == (i * 64 * 8 + 1)) begin
                    if      (cnt[10:9] == 0) cmd = ADS868X_CMD_MAN_CH1;
                    else if (cnt[10:9] == 1) cmd = ADS868X_CMD_MAN_CH2;
                    else if (cnt[10:9] == 2) cmd = ADS868X_CMD_MAN_CH3;
                    else                     cmd = ADS868X_CMD_MAN_CH0;
                    return {1'b1, cmd};
                end
            end
            return 0;
        end
    endfunction

    function [3:0] ext_mux_on_tick(input [16:0] cnt);
        reg [4:0] temp;
        begin
            for (int i = 0; i < 32; i++)
                if (cnt == (i * 64 * 8 + 16 * 8))
                    temp = cnt[13:9] + 1;
                    return {1'b1, temp[4:2]};
            return 0;
        end
    endfunction

    always_ff @ (posedge aclk) begin
        reg [3:0] temp;
        temp = ext_mux_on_tick(ts_cnt);
        if (temp[3])
            ext_mux_ch <= temp[2:0];
    end



    always_ff @ (posedge aclk) begin
        reg [16:0] temp;
        temp = sample_on_tick(ts_cnt);
        if (temp[16]) begin
            tx_buffer <= {temp[15:0], 16'h0000};
            tx_nbytes <= 2'd3;
            tx_valid  <= 1'b1;
        end else begin
            tx_valid  <= 1'b0;
        end
    end

    // GPIO
    assign {CH_SEL_A2, CH_SEL_A1, CH_SEL_A0} = ext_mux_ch;


endmodule

`default_nettype wire
