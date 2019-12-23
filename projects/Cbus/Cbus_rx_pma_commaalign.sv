/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

(* keep_hierarchy="yes" *)
module Cbus_rx_pma_commaalign #(
    parameter PCOMMA_VALUE = 10'b0101111100,
    parameter MCOMMA_VALUE = 10'b1010000011
) (
    input  wire       clk              ,
    input  wire       rst              ,
    //
    input  wire       rx_din           ,
    //
    output reg  [9:0] pma_rxdata       , // Rx Data
    output reg        pma_rxvalid      , // Rx Valid
    //
    output wire [3:0] stat_rxalignphase,
    output reg        stat_rxcommadet  ,
    output reg        stat_rxisalign   ,
    output reg        stat_rxrealign
);

    reg [3:0] seq_cnt, alignphase;

    reg [9:0] shifter;

    wire pcomma_det, mcomma_det, comma_det;


    // `seq_cnt` is a free running counter, used to indicate comma align phase
    always_ff @ (posedge clk) begin : p_seq_cnt
        if (rst) begin
            seq_cnt <= 'd0;
        end else begin
            seq_cnt <= (seq_cnt == 9) ? 0 : (seq_cnt + 1);
        end
    end

    // Shift rx data into MSB of `shifter`, since LSB ls received first
    always_ff @ (posedge clk) begin : p_shifter
        if (rst) begin
            shifter <= 0;
        end else begin
            shifter <= {rx_din, shifter[9:1]};
        end
    end

    // Continue to compare the received sequence to COMMA symbol, there are
    // two COMMA symbols (usually K28.5+  and K28.5-)
    assign pcomma_det = (shifter == PCOMMA_VALUE);
    assign mcomma_det = (shifter == MCOMMA_VALUE);
    assign comma_det  = (pcomma_det || mcomma_det);

    // If COMMA is detected, register current seq_cnt phase
    always_ff @ (posedge clk) begin : p_alignphase
        if (rst) begin
            alignphase <= 0;
        end else if (comma_det) begin
            alignphase <= seq_cnt;
        end
    end

    // 10-bit data
    always_ff @ (posedge clk) begin : p_pma_rxdata
        if (rst) begin
            pma_rxdata <= 'b0;
        end else if ((seq_cnt == alignphase) || comma_det) begin
            // COMMA is detected, align at COMMA
            pma_rxdata <= shifter;
        end
    end

    // `pma_rxdata` is valid
    always_ff @ (posedge clk) begin : p_pma_rxvalid
        if (rst) begin
            pma_rxvalid <= 'h0;
        end else begin
            pma_rxvalid <= ((seq_cnt == alignphase) || comma_det);
        end
    end

    // Indicate one COMMA symbol is received
    always_ff @ (posedge clk) begin : p_rxcommdet
        if (rst) begin
            stat_rxcommadet <= 0;
        end else begin
            stat_rxcommadet <= comma_det;
        end
    end

    // At least one COMMA symbol is received since last reset
    always_ff @ (posedge clk) begin : p_rxisalign
        if (rst) begin
            stat_rxisalign <= 0;
        end else if (comma_det) begin
            stat_rxisalign <= 1;
        end
    end

    // `stat_rxreaign` indicate one COMMA is detected, but aligned at other phase
    // which cause a "realign", usually happened when link partner's TX is reset
    always_ff @ (posedge clk) begin : p_rxrealign
        if (rst) begin
            stat_rxrealign <= 1'b0;
        end else begin
            stat_rxrealign <= comma_det && (seq_cnt != alignphase);
        end
    end

    assign stat_rxalignphase = alignphase;

endmodule
