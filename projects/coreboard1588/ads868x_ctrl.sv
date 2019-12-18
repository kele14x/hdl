/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

(* keep_hierarchy="yes" *)
module ads868x_ctrl (
    input  wire        clk_125m    ,
    input  wire        rst_125m    ,
    //
    input  wire        sync_1pps   ,
    // SPI send
    output reg  [31:0] spi_tx_data ,
    output reg  [ 4:0] spi_tx_bits ,
    output reg         spi_tx_valid,
    // SPI recv
    input  wire [31:0] spi_rx_data ,
    input  wire [ 4:0] spi_rx_bits ,
    input  wire        spi_rx_valid,
    //
    output wire        CH_SEL_A0   ,
    output wire        CH_SEL_A1   ,
    output wire        CH_SEL_A2
);

    import ads868x_pkg::*;

    parameter C_TS_TICK = 125000-1;

    reg [2:0] ext_mux_ch;
    reg [1:0] ad868x_mux_ch;

    // $clog2(C_TS_TICK) = 17
    // [13:11] A[2:0]
    // [10: 9] M[1:0]
    // [ 8: 0] SPI Seq
    reg [16:0] ts_cnt;

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

    always_ff @ (posedge clk_125m) begin
        reg [3:0] temp;
        temp = ext_mux_on_tick(ts_cnt);
        if (temp[3])
            ext_mux_ch <= temp[2:0];
    end

    // ts_cnt is tick counter runs from 0 to C_TS_TICK, to generate the sample
    // ticks
    always_ff @ (posedge clk_125m)
        if (rst_125m || sync_1pps)
            ts_cnt <= {17{1'b1}};
        else
            ts_cnt <= (ts_cnt == C_TS_TICK) ? 'd0 : ts_cnt + 1;

    always_ff @ (posedge clk_125m) begin
        reg [16:0] temp;
        temp = sample_on_tick(ts_cnt);
        if (temp[16]) begin
            spi_tx_data <= {temp[15:0], 16'h0000};
            spi_tx_bits <= 5'd31;
            spi_tx_valid <= 1'b1;
        end else begin
            spi_tx_valid <= 1'b0;
        end
    end

    assign {CH_SEL_A2, CH_SEL_A1, CH_SEL_A0} = ext_mux_ch;

endmodule
