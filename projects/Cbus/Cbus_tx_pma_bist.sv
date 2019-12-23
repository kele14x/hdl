/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

(* keep_hierarchy="yes" *)
module Cbus_tx_pma_bist (
    input  wire       clk                ,
    input  wire       rst                ,
    //
    input  wire       din                ,
    //
    output reg        dout               ,
    //
    input  wire       ctrl_txpolarity    ,
    input  wire [2:0] ctrl_txprbssel     ,
    input  wire [3:0] ctrl_txprbsforceerr
);

    wire prbs7 ;
    wire prbs15;
    wire prbs23;
    wire prbs31;

    wire mux;

    reg [15:0] inj_err_cnt;
    wire inj_err_c;
    reg inj_err;

    // If n = 0, disable error inject
    // if n = 1, inject error every other clock (50% BER)
    // if n = 2, inject error every 4th clock
    //...
    // if n = 15, inject error every 65536th clock (~0.0015% BER)

    function [15:0] threshold (input [3:0] n);
        threshold = 16'b0;
        for (int i = 0; i < n; i = i + 1) threshold[i] = 1'b1;
    endfunction

    // Inject error logic

    assign inj_err_c = (inj_err_cnt == threshold(ctrl_txprbsforceerr));

    always_ff @ (posedge clk) begin : p_inj_err_cnt;
        if (rst) begin
            inj_err_cnt <= 0;
        end else begin
            inj_err_cnt <= inj_err_c ? 0 : (inj_err_cnt + 1);
        end
    end

    always_ff @ (posedge clk) begin : p_inj_err
        if (rst) begin
            inj_err <= 0;
        end else begin
            inj_err <= inj_err_c && !(ctrl_txprbsforceerr == 0);
        end
    end

    Cbus_tx_pma_prbs_gen #(
        .N  (7),
        .TAP(6)
    ) i_prbs7 (
        .clk (clk    ),
        .rst (rst    ),
        .ce  (1'b1   ),
        .din (inj_err),
        .dout(prbs7  )
    );

    Cbus_tx_pma_prbs_gen #(
        .N  (15),
        .TAP(14)
    ) i_prbs15 (
        .clk (clk    ),
        .rst (rst    ),
        .ce  (1'b1   ),
        .din (inj_err),
        .dout(prbs15 )
    );

    Cbus_tx_pma_prbs_gen #(
        .N  (23),
        .TAP(18)
    ) i_prbs23 (
        .clk (clk    ),
        .rst (rst    ),
        .ce  (1'b1   ),
        .din (inj_err),
        .dout(prbs23 )
    );

    Cbus_tx_pma_prbs_gen #(
        .N  (31),
        .TAP(28)
    ) i_prbs31 (
        .clk (clk    ),
        .rst (rst    ),
        .ce  (1'b1   ),
        .din (inj_err),
        .dout(prbs31 )
    );

    assign mux = ctrl_txprbssel == 3'b000 ? din    :
                 ctrl_txprbssel == 3'b001 ? prbs7  :
                 ctrl_txprbssel == 3'b010 ? prbs15 :
                 ctrl_txprbssel == 3'b011 ? prbs23 :
                 ctrl_txprbssel == 3'b100 ? prbs31 : 0;

    always_ff @ (posedge clk) begin
        dout <= ctrl_txpolarity ^ mux;
    end


endmodule
