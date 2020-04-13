/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

//------------------------------------------------------------------------------
// All operation to ADS868x is handled by one 4-wire SPI and 1-GPIO. The GPIO
// is is called RST/PD.
//
// * RSTn/PDn:
//   - In normal operation, set it high;
//   - To reset the chip. Unset it for 40~200 ns (5~25 clocks in 125MHz)
//   - To power down the chip. Unset it for 400 ns+ (50+ clocks)
//     (Data sheet Chapter 8.4.1.1.6)
//
// * SPI:
//   The chip will sample SPI data on negative edge (CPHA=1)
//   (Data sheet Chapter 8.4.2.1)
//
//   You can send 32/24/16 bits the chip via SPI:
//   - 32-bit: Command (16 bits) + ADC data read (16 bits)
//     (Data sheet Chapter 8.4.2.6)
//   - 24-bit: Register read / write (7-bits address + 1-bit W/Rn + 8
//     bits write data + 8 bits read data)
//     (Data sheet Chapter 8.5.2.1)
//   - 16-bit: Command without data read
//     (Data sheet Chapter 8.4.2.3)
//
// * ADC data sampling:
//   To loop 4 channels, Auto SPI send 32-bit: MAN_Ch_n (16-bit) + Dummy
//   (16-bit) to chip. Also, there are external MUX controlled by CH_SEL_Ax.
//   So there are 32 effective channels to loop. Named by Channel 1~16 T &
//   Channel 1~16 P.
//
// * Sampling rate:
//   1 kHz
//
// * Clock frequency:
//   Expect 125MHz
//
//------------------------------------------------------------------------------

module axi_ads868x_ctrl #(
    parameter C_CLOCK_FREQUENCY = 125000000
) (
    // Clock & Reset
    //--------------
    input  wire        aclk            ,
    input  wire        aresetn         ,
    // PPS
    //----
    input  wire        pps             ,
    // Interface with SPI module
    //--------------------------
    // SPI send
    output reg  [ 7:0] spi_tx_tdata    ,
    output reg         spi_tx_tvalid   ,
    input  wire        spi_tx_tready   ,
    // SPI recv
    input  wire [ 7:0] spi_rx_tdata    ,
    input  wire        spi_rx_tvalid   ,
    output reg         spi_rx_tready   ,
    // ADC
    //----
    output reg  [55:0] adc_tdata       ,
    output reg         adc_tvalid      ,
    input  wire        adc_tready      ,
    // GPIO
    //-----
    output wire        RST_PD_N        ,
    //
    output wire        CH_SEL_A0       ,
    output wire        CH_SEL_A1       ,
    output wire        CH_SEL_A2       ,
    //
    output wire        EN_TCH_A        ,
    output wire        EN_PCH_A        ,
    output wire        EN_TCH_B        ,
    output wire        EN_PCH_B        ,
    //
    // Control & Status
    //-----------------
    input  wire        ctrl_soft_reset ,
    input  wire        ctrl_power_down ,
    input  wire        ctrl_auto_spi   , // 1 = auto (working) mode, 0 = ctrl mode
    //
    input  wire [ 2:0] ctrl_ext_mux_sel,
    input  wire [ 3:0] ctrl_ext_mux_en ,
    //
    input  wire [ 1:0] ctrl_spi_txbyte ,
    input  wire [31:0] ctrl_spi_txdata ,
    input  wire        ctrl_spi_txvalid,
    //
    output reg  [31:0] stat_spi_rxdata ,
    output reg         stat_spi_rxvalid
    //
);

    import ads868x_pkg::*;


    // Sample tick counter
    //---------------------

    // The expected clock frequency is 125 MHz, and the target sample frequency
    // is 1 kHz. So we have 125000 tick between each loop.
    // During a loop, we need to go though 32 channels. (8 to 1 externel mux
    // and 4 to 1 internal mux inside ads868x). We firstly switch internal mux
    // since it should switch faster.
    //
    // The counter should sync with PPS.

    localparam C_TS_CNT_MAX = C_CLOCK_FREQUENCY / 1000 - 1;
    localparam C_TS_CNT_WIDTH = $clog2(C_TS_CNT_MAX);

    // For each channel, we will spend 1024 clock here. The 32 channels will
    // cost us 1024*32 = 32768 clock ticks. Much smaller than the 125000
    // ticks. In fact we will send 33 SPI commands since last command is used
    // to read the 32th channel and no op.
    //
    // [14:12] A[2:0]
    // [11:10] M[1:0]
    // [ 9: 0] SPI Seq
    reg [C_TS_CNT_WIDTH-1:0] ts_cnt;

    // ts_cnt is tick counter runs from 0 to C_TS_CNT_MAX, to generate the sample
    // ticks
    always_ff @ (posedge aclk) begin
        if (!aresetn || pps) begin
            ts_cnt <= {C_TS_CNT_WIDTH{1'b1}};
        end else begin
            ts_cnt <= (ts_cnt == C_TS_CNT_MAX) ? 'd0 : ts_cnt + 1;
        end
    end

    // PPS counter
    //------------

    localparam C_PPS_CNT_MAX = C_CLOCK_FREQUENCY - 1;
    localparam C_PPS_CNT_WIDTH = $clog2(C_PPS_CNT_MAX);

    reg [C_PPS_CNT_WIDTH-1:0] pps_cnt;

    always_ff @ (posedge aclk) begin
        if (!aresetn || pps) begin
            pps_cnt <= {C_PPS_CNT_WIDTH{1'b1}};
        end else begin
            pps_cnt <= (pps_cnt == C_PPS_CNT_MAX) ? 'd0 : pps_cnt + 1;
        end
    end

    // Mode switch
    //------------
    // between auto (workign mode) and ctrl mode

    reg auto_mode = 0; // 1 = auto, 0 = ctrl

    always_ff @ (posedge aclk) begin
        if (ts_cnt == 'd0) begin
            auto_mode <= ctrl_auto_spi;
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
            S_RXIDLE: rx_state_next = !tx_valid          ? S_RXIDLE :
                                       tx_nbytes == 2'd3 ? S_RXCMD3 :
                                       tx_nbytes == 2'd2 ? S_RXCMD2 :
                                       tx_nbytes == 2'd1 ? S_RXCMD1 : S_RXCMD0;
            S_RXCMD3: rx_state_next = !spi_rx_tvalid ? S_RXCMD3 : S_RXCMD2;
            S_RXCMD2: rx_state_next = !spi_rx_tvalid ? S_RXCMD2 : S_RXCMD1;
            S_RXCMD1: rx_state_next = !spi_rx_tvalid ? S_RXCMD1 : S_RXCMD0;
            S_RXCMD0: rx_state_next = !spi_rx_tvalid ? S_RXCMD0 : S_RXIDLE;
            default : rx_state_next = S_RXRST;
        endcase
    end

    always_ff @ (posedge aclk) begin
        if (tx_valid) begin
            rx_buffer <= 'd0;
        end
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
        end else if (rx_valid && !(adc_tvalid && !adc_tready) && auto_mode) begin
            adc_tdata[15:0]  <= rx_buffer[15:0];
            adc_tdata[23:16] <= ts_cnt[15:10] - 1;
            adc_tdata[55:24] <= pps_cnt;
        end
    end

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            adc_tvalid <= 1'b0;
        end else if (rx_valid && auto_mode) begin
            adc_tvalid <= 1'b1;
        end if (adc_tready) begin
            adc_tvalid <= 1'b0;
        end
    end

    // Sample control
    //----------------

    reg [2:0] auto_ext_mux;

    function [16:0] sample_on_tick(input [16:0] cnt);
        reg [15:0] cmd;
        begin
            for (int i = 0; i < 32; i++) begin
                if (cnt == (i * 64 * 16 + 1)) begin
                    if      (cnt[11:10] == 0) cmd = ADS868X_CMD_MAN_CH0;
                    else if (cnt[11:10] == 1) cmd = ADS868X_CMD_MAN_CH1;
                    else if (cnt[11:10] == 2) cmd = ADS868X_CMD_MAN_CH2;
                    else                      cmd = ADS868X_CMD_MAN_CH3;
                    return {1'b1, cmd};
                end
            end
            if (cnt == 32 * 64 * 16 + 1) begin
                return {1'b1, ADS868X_CMD_NO_OP};
            end
            return 0;
        end
    endfunction

    function [3:0] ext_mux_on_tick(input [16:0] cnt);
        begin
            for (int i = 0; i < 32; i++)
                if (cnt == (i * 64 * 16 + 16 * 16))
                    return {1'b1, cnt[14:12]};
            return 0;
        end
    endfunction

    always_ff @ (posedge aclk) begin
        reg [3:0] temp;
        temp = ext_mux_on_tick(ts_cnt);
        if (temp[3])
            auto_ext_mux <= temp[2:0];
    end



    always_ff @ (posedge aclk) begin
        reg [16:0] temp;
        temp = sample_on_tick(ts_cnt);

        //
        if (auto_mode) begin

            // SPI interface is controlled by AUTO logic
            if (temp[16]) begin
                tx_buffer <= {temp[15:0], 16'h0000};
                tx_nbytes <= 2'd3;
                tx_valid  <= 1'b1;
            end else begin
                tx_valid  <= 1'b0;
            end

        //
        end else begin

            // SPI interface is controlled by ctrl_*
            if (ctrl_spi_txvalid) begin
                tx_buffer <= ctrl_spi_txdata;
                tx_nbytes <= ctrl_spi_txbyte;
            end
            tx_valid  <= ctrl_spi_txvalid;

        end
    end

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            stat_spi_rxdata <= 'd0;
        end else if (ctrl_spi_txvalid) begin
            stat_spi_rxdata <= 'd0;
        end else if (!ctrl_auto_spi && rx_valid) begin
            stat_spi_rxdata <= rx_buffer;
        end
    end

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            stat_spi_rxvalid <= 1'b0;
        end else if (ctrl_spi_txvalid) begin
            stat_spi_rxvalid <= 1'b0;
        end else if (!ctrl_auto_spi && rx_valid) begin
            stat_spi_rxvalid <= 1'b1;
        end
    end

    // ADS868x GPIO Control
    //--------------------

    reg soft_reset_d, soft_reset_dd;
    reg [3:0] reset_ext = 4'b1111;

    always_ff @ (posedge aclk) begin
        soft_reset_d <= ctrl_soft_reset;
        soft_reset_dd <= soft_reset_d;
    end

    always_ff @ (posedge aclk) begin
        // Posedge of ctrl_soft_reset
        if ({soft_reset_d, soft_reset_dd} == 2'b10) begin
            reset_ext <= 4'b0;
        end else begin
            reset_ext <= (reset_ext == 4'b1111) ? 4'b1111 : reset_ext + 1;
        end
    end

    assign RST_PD_N = &reset_ext && !ctrl_power_down;

    // Analog MUX control
    //-------------------

    assign {CH_SEL_A2, CH_SEL_A1, CH_SEL_A0} = ctrl_auto_spi ? auto_ext_mux : ctrl_ext_mux_sel;

    assign {EN_PCH_B, EN_TCH_B, EN_PCH_A, EN_TCH_A} = ctrl_ext_mux_en;

endmodule

`default_nettype wire
