/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

(* keep_hierarchy="yes" *)
module ads868x_spi (
    /* SPI */
    output wire        SCK          ,
    output wire        SS_N         ,
    inout  wire        MOSI_Z       ,
    input  wire        MISO         ,
    /* Fabric FPGA */
    input  wire        clk_125m     ,
    input  wire        rst_125m     ,
    // SPI Tx Data
    input  wire [31:0] tx_data      ,
    input  wire [ 4:0] tx_bits      ,
    input  wire        tx_valid     ,
    output wire        tx_ready     ,
    // SPI Rx Data
    output wire [31:0] rx_data      ,
    output wire [ 4:0] rx_bits      ,
    output wire        rx_valid
);

    reg [31:0] tx_data_int, rx_data_r, rx_data_int;
    reg [ 4:0] tx_bits_int, rx_bits_r;
    reg tx_ready_int, rx_valid_r;

    // stat_cnt[2:0] - Pha Count
    // stat_cnt[7:3] - Bit Count
    // stat_cnt[9]   - Not running
    reg signed [9:0] stat_cnt, stat_cnt_next;

    wire [4:0] tx_bit_sel;
    wire       tx_not_running;

    assign tx_bit_sel = stat_cnt[7:3];
    assign tx_not_running = stat_cnt[9];

    // tx_ready state machine, like axis_tready
    always_ff @ (posedge clk_125m) begin : p_tx_ready_int
        if (rst_125m)
            tx_ready_int <= 1'b0;
        else if (tx_valid && tx_ready_int)
            tx_ready_int <= 1'b0;
        else if (stat_cnt == -1)
            tx_ready_int <= 1'b1;
    end

    assign tx_ready = tx_ready_int;

    always_ff @ (posedge clk_125m) begin : p_reg_tx_data
        if (tx_valid && tx_ready_int) begin
            tx_data_int <= tx_data;
            tx_bits_int <= tx_bits;
        end
    end

    // `stat_cnt` state machine
    always_ff @ (posedge clk_125m) begin : p_stat_shift
        stat_cnt <= rst_125m ? -1 : stat_cnt_next;
    end

    always_comb begin : c_stat_cnt_next
        if (tx_valid && tx_ready_int)
            stat_cnt_next = tx_bits*8+11;
        else if (stat_cnt >= 0)
            stat_cnt_next = stat_cnt - 1;
        else
            stat_cnt_next = -1;
    end

    (* IOB="true" *)
    reg SCK_iob, SS_iob, MOSI_iob, MISO_iob;

    always_ff @ (posedge clk_125m) begin
        SS_iob <= tx_not_running;
        SCK_iob <= ~tx_not_running && stat_cnt[2];
        MOSI_iob <= tx_data_int[tx_bit_sel]; 
    end

    always_ff @ (posedge clk_125m) begin
        MISO_iob <= MISO;
        if (stat_cnt[2:0] == 2)
            rx_data_int[tx_bit_sel] <= MISO_iob;
    end

    always_ff @ (posedge clk_125m) begin
        if (stat_cnt == 0) begin 
            rx_valid_r <= 1'b1;
            rx_data_r <= rx_data_int;
            rx_bits_r <= tx_bits_int;
        end else begin
            rx_valid_r <= 1'b0;
        end
    end
    
    assign rx_data = rx_data_r;
    assign rx_bits = rx_bits_r;
    assign rx_valid = rx_valid_r;

    assign SCK = SCK_iob;
    assign SS_N = SS_iob;

    OBUFT OBUFT_inst (
        .O(MOSI_Z  ),    
        .I(MOSI_iob),
        .T(SS_N    )
    );

endmodule
