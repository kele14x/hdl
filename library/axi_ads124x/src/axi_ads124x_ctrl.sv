/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module axi_ads124x_ctrl #(parameter C_CLK_FREQ = 125000000) (
    input  wire        aclk             ,
    input  wire        aresetn          ,
    // SPI send
    output reg  [ 7:0] spitx_axis_tdata ,
    output reg         spitx_axis_tvalid,
    input  wire        spitx_axis_tready,
    // SPI receive
    input  wire [ 7:0] spirx_axis_tdata ,
    input  wire        spirx_axis_tvalid,
    output wire        spirx_axis_tready,
    //
    output reg  [31:0] adc_axis_tdata   ,
    output reg         adc_axis_tvalid  ,
    input  wire        adc_axis_tready  ,
    //
    input  wire        pps              ,
    //
    output wire        RESET            ,
    output wire        START            , // At least 732 ns width
    input  wire        DRDY             ,
    // O&M Interface
    //---------------
    input  wire        ctrl_soft_reset  ,
    //
    input  wire        ctrl_op_mode     , // 0 = ctrl i/f control, 1 = auto control
    //
    input  wire        ctrl_ad_start    ,
    input  wire        ctrl_ad_reset    ,
    output wire        stat_ad_drdy     ,
    //
    input  wire [31:0] ctrl_spi_txdata  ,
    input  wire [ 1:0] ctrl_spi_txbytes ,
    input  wire        ctrl_spi_txvalid ,
    
    //
    output reg         stat_spi_rxvalid ,
    output reg  [31:0] stat_spi_rxdata
);

    import axi_ads124x_pkg::*;

    // PPS Counter
    //============

    localparam C_CNT_MAX   = C_CLK_FREQ - 1;
    localparam C_CNT_WIDTH = $clog2(C_CNT_MAX);

    reg [C_CNT_WIDTH-1:0] counter;


    always_ff @ (posedge aclk) begin
        if (!aresetn || pps) begin
            counter <= {C_CNT_WIDTH{1'b1}};
        end else begin
            counter <= (counter == C_CNT_MAX) ? 0 : counter + 1;
        end
    end

    // Sample on some tick

    reg sample_tick1, sample_tick2;


    always_ff @ (posedge aclk) begin
        sample_tick1 <= (counter == 1);
        sample_tick2 <= (counter == C_CLK_FREQ/2 + 1);
    end

    // SPI TX State Machine
    //=====================

    typedef enum {S_TX_RST, S_TX_IDLE, S_TX_BYTE3, S_TX_BYTE2, S_TX_BYTE1, S_TX_BYTE0} TX_STATE;

    TX_STATE tx_state, tx_state_next;

    typedef enum {S_RX_RST, S_RX_IDLE, S_RX_BYTE3, S_RX_BYTE2, S_RX_BYTE1, S_RX_BYTE0} RX_STATE;

    RX_STATE rx_state, rx_state_next;

    // SPI Send Machine
    //-----------------

    reg [31:0] spi_tx_data;
    reg [ 1:0] spi_tx_nbytes;
    reg        spi_tx_valid;

    reg [31:0] spi_rx_buffer;
    reg        spi_rx_valid;


    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            tx_state <= S_TX_RST;
        end else begin
            tx_state <= tx_state_next;
        end
    end

    always_comb begin
        case (tx_state)
            S_TX_RST   : tx_state_next = S_TX_IDLE;
            S_TX_IDLE  : tx_state_next = !spi_tx_valid       ? S_TX_IDLE  :
                                      spi_tx_nbytes == 2'b11 ? S_TX_BYTE3 :
                                      spi_tx_nbytes == 2'b10 ? S_TX_BYTE2 :
                                      spi_tx_nbytes == 2'b01 ? S_TX_BYTE1 : S_TX_BYTE0;
            S_TX_BYTE3 : tx_state_next = (spitx_axis_tready) ? S_TX_BYTE2 : S_TX_BYTE3;
            S_TX_BYTE2 : tx_state_next = (spitx_axis_tready) ? S_TX_BYTE1 : S_TX_BYTE2;
            S_TX_BYTE1 : tx_state_next = (spitx_axis_tready) ? S_TX_BYTE0 : S_TX_BYTE1;
            S_TX_BYTE0 : tx_state_next = (spitx_axis_tready) ? S_TX_IDLE  : S_TX_BYTE0;
            default    : tx_state_next = S_TX_RST;
        endcase
    end

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            spitx_axis_tdata <= 'd0;
        end else if (tx_state_next == S_TX_BYTE3) begin
            spitx_axis_tdata <= spi_tx_data[31:24];
        end else if (tx_state_next == S_TX_BYTE2) begin
            spitx_axis_tdata <= spi_tx_data[23:16];
        end else if (tx_state_next == S_TX_BYTE1) begin
            spitx_axis_tdata <= spi_tx_data[15: 8];
        end else if (tx_state_next == S_TX_BYTE0) begin
            spitx_axis_tdata <= spi_tx_data[ 7: 0];
        end
    end

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            spitx_axis_tvalid <= 1'b0;
        end else begin
            spitx_axis_tvalid <= (tx_state_next == S_TX_BYTE3 ||
                tx_state_next == S_TX_BYTE2 || tx_state_next == S_TX_BYTE1 || tx_state_next == S_TX_BYTE0);
        end
    end


    // SPI RX Machine
    //---------------

    assign spirx_axis_tready = 1'b1;

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            rx_state <= S_RX_RST;
        end else begin
            rx_state <= rx_state_next;
        end
    end

    always_comb begin
        case (rx_state)
            S_RX_RST   : rx_state_next = S_RX_IDLE;
            S_RX_IDLE  : rx_state_next = !spi_tx_valid       ? S_RX_IDLE : 
                                      spi_tx_nbytes == 2'b11 ? S_RX_BYTE3 :
                                      spi_tx_nbytes == 2'b10 ? S_RX_BYTE2 :
                                      spi_tx_nbytes == 2'b01 ? S_RX_BYTE1 : S_RX_BYTE0;
            S_RX_BYTE3 : rx_state_next = !spirx_axis_tvalid  ? S_RX_BYTE3 : S_RX_BYTE2;
            S_RX_BYTE2 : rx_state_next = !spirx_axis_tvalid  ? S_RX_BYTE2 : S_RX_BYTE1;
            S_RX_BYTE1 : rx_state_next = !spirx_axis_tvalid  ? S_RX_BYTE1 : S_RX_BYTE0;
            S_RX_BYTE0 : rx_state_next = !spirx_axis_tvalid  ? S_RX_BYTE0 : S_RX_IDLE;
            default    : rx_state_next = S_RX_RST;
        endcase
    end

    always_ff @ (posedge aclk) begin
        if (rx_state == S_RX_BYTE3 && spirx_axis_tvalid) begin
            spi_rx_buffer[31:24] <= spirx_axis_tdata;
        end
        if (rx_state == S_RX_BYTE2 && spirx_axis_tvalid) begin
            spi_rx_buffer[23:16] <= spirx_axis_tdata;
        end
        if (rx_state == S_RX_BYTE1 && spirx_axis_tvalid) begin
            spi_rx_buffer[15: 8] <= spirx_axis_tdata;
        end
        if (rx_state == S_RX_BYTE0 && spirx_axis_tvalid) begin
            spi_rx_buffer[ 7: 0] <= spirx_axis_tdata;
        end
    end

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            spi_rx_valid <= 1'b0;
        end else begin
            spi_rx_valid <= (rx_state == S_RX_BYTE0 && spirx_axis_tvalid);
        end
    end


    // Auto mode GPIO control
    //=======================

    reg drdy_cdc, drdy_negedge;
    reg drdy_cdc_d;

    // DRDY PIN CDC
    always_ff @ (posedge aclk) begin
        drdy_cdc   <= DRDY;
        drdy_cdc_d <= drdy_cdc;
    end

    // Falling edge of /DRDY pin
    assign drdy_negedge = !drdy_cdc && drdy_cdc_d;


    // GPIO pins (START/RESET/DRDY) for exteranl control mode:

    // If in external control mode, start pin to AD124x is controlled by
    // external source. This allows external source controls AD124x freely.
    // External can use issue command (read/write/sleep/wakeup/etc.) to
    // control AD124x chip.
    assign START = ctrl_op_mode ? 1'b1 : ctrl_ad_start;

    // If in external control mode, reset pin to AD124x is controlled by
    // external. Else set it high (not reset).
    assign RESET = ctrl_op_mode ? 1'b1 : ctrl_ad_reset;

    assign stat_ad_drdy = drdy_cdc_d;

    // AUTO mode
    //==========

    typedef enum {S_AUTO_RST, S_AUTO_IDLE, S_AUTO_CH0, S_AUTO_WAIT0, 
        S_AUTO_CH1, S_AUTO_WAIT1} AUTO_STATE;

    AUTO_STATE auto_state, auto_state_next;

    var logic [1:0] auto_current_ch;

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            auto_state <= S_AUTO_RST;
        end else begin
            auto_state <= auto_state_next;
        end
    end
    
    always_comb begin
        case (auto_state) 
            S_AUTO_RST  : auto_state_next = S_AUTO_IDLE;
            S_AUTO_IDLE : auto_state_next = !(ctrl_op_mode && sample_tick1) ? S_AUTO_IDLE : S_AUTO_CH0;
            S_AUTO_CH0  : auto_state_next = S_AUTO_WAIT0;
            S_AUTO_WAIT0: auto_state_next = !sample_tick2 ? S_AUTO_WAIT0 : S_AUTO_CH1; 
            S_AUTO_CH1  : auto_state_next = S_AUTO_WAIT1;
            S_AUTO_WAIT1: auto_state_next = !sample_tick1 ? S_AUTO_WAIT1 :
                                            !ctrl_op_mode ? S_AUTO_IDLE  : S_AUTO_CH0;
            default     : auto_state_next = S_AUTO_RST;
        endcase
    end

    // SPI Control
    //============
    
    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            spi_tx_data <= 'd0;
        end else if (auto_state == S_AUTO_CH0) begin
            spi_tx_data <= 24'h400017; // write MUX0 with MUX_SP=AN2/MUX_SN=AN1
        end else if (auto_state == S_AUTO_CH1) begin
            spi_tx_data <= 24'h400008; // write MUX0 with MUX_SP=AN1/MUX_SN=AN0
        end else if (auto_state == S_AUTO_WAIT0 && drdy_negedge) begin
            spi_tx_data <= 24'hFFFFFF; // NOOP
        end else if (auto_state == S_AUTO_WAIT1 && drdy_negedge) begin
            spi_tx_data <= 24'hFFFFFF; // NOOP
        end else if (!ctrl_op_mode && ctrl_spi_txvalid) begin
            spi_tx_data <= ctrl_spi_txdata;
        end
    end

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            spi_tx_nbytes <= 'd0;
        end else if (auto_state == S_AUTO_CH0) begin
            spi_tx_nbytes <= 2'b10;
        end else if (auto_state == S_AUTO_CH1) begin
            spi_tx_nbytes <= 2'b10;
        end else if (auto_state == S_AUTO_WAIT0 && drdy_negedge) begin
            spi_tx_nbytes <= 2'b10;
        end else if (auto_state == S_AUTO_WAIT1 && drdy_negedge) begin
            spi_tx_nbytes <= 2'b10;
        end else if (!ctrl_op_mode && ctrl_spi_txvalid) begin
            spi_tx_nbytes <= ctrl_spi_txbytes;
        end
    end

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            spi_tx_valid <= 1'b0;
        end else if (auto_state == S_AUTO_CH0) begin
            spi_tx_valid <= 1'b1;
        end else if (auto_state == S_AUTO_CH1) begin
            spi_tx_valid <= 1'b1;
        end else if (auto_state == S_AUTO_WAIT0 && drdy_negedge) begin
            spi_tx_valid <= 1'b1;
        end else if (auto_state == S_AUTO_WAIT1 && drdy_negedge) begin
            spi_tx_valid <= 1'b1;
        end else if (!ctrl_op_mode && ctrl_spi_txvalid) begin
            spi_tx_valid <= 1'b1;
        end else begin
            spi_tx_valid <= 1'b0;
        end
    end

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            auto_current_ch <= 2'b11;
        end else if (auto_state == S_AUTO_CH0) begin
            auto_current_ch <= 2'b11;
        end else if (auto_state == S_AUTO_CH1) begin
            auto_current_ch <= 2'b11;
        end else if (auto_state == S_AUTO_WAIT0 && drdy_negedge) begin
            auto_current_ch <= 2'b00;
        end else if (auto_state == S_AUTO_WAIT1 && drdy_negedge) begin
            auto_current_ch <= 2'b01;
        end else if (!ctrl_op_mode && ctrl_spi_txvalid) begin
            auto_current_ch <= 2'b11;
        end
    end

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            stat_spi_rxdata <= 'd0;
        end else if (!ctrl_op_mode && ctrl_spi_txvalid) begin
            stat_spi_rxdata <= 'd0;
        end else if (!ctrl_op_mode && spi_rx_valid) begin
            stat_spi_rxdata <= spi_rx_buffer;
        end
    end

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            stat_spi_rxvalid <= 'd0;
        end else if (!ctrl_op_mode && ctrl_spi_txvalid) begin
            stat_spi_rxvalid <= 'd0;
        end else if (!ctrl_op_mode && spi_rx_valid) begin
            stat_spi_rxvalid <= 1'b1;
        end else if (ctrl_op_mode) begin
            stat_spi_rxvalid <= 1'b0;
        end
    end

    // ADC ports
    //==========

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            adc_axis_tdata <= 'd0;
        end else if (ctrl_op_mode && spi_rx_valid) begin
            if (auto_current_ch == 2'b00) begin
                adc_axis_tdata <= {8'd00, spi_rx_buffer};
            end else if (auto_current_ch == 2'b01) begin
                adc_axis_tdata <= {8'd01, spi_rx_buffer};
            end
        end 
    end

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            adc_axis_tvalid <= 1'b0;
        end else if (ctrl_op_mode && spi_rx_valid && auto_current_ch[1] == 1'b0) begin
            adc_axis_tvalid <= 1'b1;
        end else if (adc_axis_tready) begin
            adc_axis_tvalid <= 1'b0;
        end
    end

endmodule

`default_nettype wire
