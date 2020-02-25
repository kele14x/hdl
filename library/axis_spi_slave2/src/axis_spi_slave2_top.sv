/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module axis_spi_slave2_top #(
    parameter C_DATA_WIDTH = 8 // 8, 16, 24, 32
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
    output reg                     axis_tx_tready
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

    assign IO1_T = SS_I;
    assign IO1_O = SO_r;

    assign SCK_s = SCK_I;
    assign SS_s  = SS_I;
    assign SI_s  = IO0_I;


    // RX Logic
    //----------

    reg [          C_DATA_WIDTH-2:0] rx_shift ;
    reg [$clog2(C_DATA_WIDTH-1)-1:0] rx_bitcnt;

    reg  [C_DATA_WIDTH-1:0] rx_data ;
    reg                     rx_valid;

    // Count how many bits we received, it should be async reset by SS_s
    always_ff @ (negedge SCK_s or posedge SS_s) begin
        if (SS_s) begin
            rx_bitcnt <= 'd0;
        end else begin
            rx_bitcnt <= rx_bitcnt + 1;
        end
    end

    // Shift into rx_shift at LSB
    always_ff @ (negedge SCK_s) begin
        rx_shift <= {rx_shift[C_DATA_WIDTH-3:0], SI_s};
    end

    always_ff @ (negedge SCK_s) begin
        if (rx_bitcnt == C_DATA_WIDTH - 1) begin
            rx_data = {rx_shift, SI_s};
        end
    end

    always_ff @ (negedge SCK_s) begin
        rx_valid <= (rx_bitcnt == C_DATA_WIDTH - 1);
    end


    // RX AXIS
    //--------

    (* ASYNC_REG="true" *)
    reg rx_valid_d = 0, rx_valid_dd = 0;
    reg rx_valid_d3 = 0;

    wire rx_valid_aclk;

    always_ff @ (posedge aclk) begin
        rx_valid_d  <= rx_valid;
        rx_valid_dd <= rx_valid_d;
        rx_valid_d3 <= rx_valid_dd;
    end

    assign rx_valid_aclk = ({rx_valid_dd, rx_valid_d3} == 2'b10);

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            axis_rx_tdata <= 'd0;
        end else if (rx_valid_aclk && !(axis_rx_tvalid && !axis_rx_tready))begin
            axis_rx_tdata <= rx_data;
        end
    end

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            axis_rx_tvalid <= 1'b0;
        end else if (rx_valid_aclk) begin
            axis_rx_tvalid <= 1'b1;
        end else if (axis_rx_tready) begin
            axis_rx_tvalid <= 1'b0;
        end
    end


    // TX Logic
    //---------

    reg [          C_DATA_WIDTH-2:0] tx_shift;
    reg [$clog2(C_DATA_WIDTH-1)-1:0] tx_bitcnt;

    reg                    tx_load = 0;
    reg                    tx_valid;
    reg [C_DATA_WIDTH-1:0] tx_data;

    // Count how many bits we send
    always_ff @ (posedge SCK_s or posedge SS_s) begin
        if (SS_s) begin
            tx_bitcnt <= 'd0;
        end else begin
            tx_bitcnt <= tx_bitcnt + 1;
        end
    end


    always_ff @ (posedge SCK_s) begin
        if (tx_bitcnt == 0) begin
            {SO_r, tx_shift} <= tx_valid ? tx_data : 'd0;
        end else begin
            {SO_r, tx_shift} <= {tx_shift, 1'b0};
        end
    end

    always_ff @ (posedge SCK_s) begin
        tx_load = (tx_bitcnt == 'd0);
    end


    // TX AXIS
    //--------

    typedef enum {S_TX_RST, S_TX_UNLOADED, S_TX_LOADED} TX_STATE_T;

    TX_STATE_T tx_state, tx_state_next;

    (* ASYNC_REG="true" *)
    reg tx_load_d = 0, tx_load_dd = 0;
    reg tx_load_d3 = 0;

    wire tx_load_aclk;

    always_ff @ (posedge aclk) begin
        tx_load_d  <= tx_load;
        tx_load_dd <= tx_load_d;
        tx_load_d3 <= tx_load_dd;
    end

    assign tx_load_aclk = ({tx_load_dd, tx_load_d3} == 2'b01);

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            tx_state <= S_TX_RST;
        end else begin
            tx_state <= tx_state_next;
        end
    end

    always_comb begin
        case(tx_state)
            S_TX_RST     : tx_state_next = S_TX_UNLOADED;
            S_TX_UNLOADED: tx_state_next = (axis_tx_tvalid ? S_TX_LOADED   : S_TX_UNLOADED);
            S_TX_LOADED  : tx_state_next = (tx_load_aclk   ? S_TX_UNLOADED : S_TX_LOADED);
        endcase
    end

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            axis_tx_tready <= 1'b0;
        end else begin
            axis_tx_tready <= (tx_state_next == S_TX_UNLOADED);
        end
    end

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            tx_data <= 'd0;
        end else if ((tx_state == S_TX_UNLOADED) && axis_tx_tvalid) begin
            tx_data <= axis_tx_tdata;
        end
    end

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            tx_valid <= 1'b0;
        end else begin
            tx_valid <= (tx_state == S_TX_LOADED);
        end 
    end

endmodule

`default_nettype wire
