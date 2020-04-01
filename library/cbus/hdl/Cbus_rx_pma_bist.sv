/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

(* keep_hierarchy="yes" *)
module Cbus_rx_pma_bist (
    input  wire        clk                ,
    input  wire        rst                ,
    //
    input  wire        din                ,
    //
    input  wire        ctrl_rxprbscntreset,
    input  wire [ 2:0] ctrl_rxprbssel     ,
    //
    output wire        stat_rxprbserr     ,
    output wire [15:0] stat_rxprbserrcnt
);

    wire prbs7 ;
    wire prbs15;
    wire prbs23;
    wire prbs31;

    reg mux;

    reg [15:0] rxprbserrcnt;

    Cbus_rx_pma_prbs_chk #(
        .N  (7),
        .TAP(6)
    ) i_prbs7 (
        .clk (clk  ),
        .rst (rst  ),
        .ce  (1'b1 ),
        .din (din  ),
        .dout(prbs7)
    );

    Cbus_rx_pma_prbs_chk #(
        .N  (15),
        .TAP(14)
    ) i_prbs15 (
        .clk (clk   ),
        .rst (rst   ),
        .ce  (1'b1  ),
        .din (din   ),
        .dout(prbs15)
    );

    Cbus_rx_pma_prbs_chk #(
        .N  (23),
        .TAP(18)
    ) i_prbs23 (
        .clk (clk   ),
        .rst (rst   ),
        .ce  (1'b1  ),
        .din (din   ),
        .dout(prbs23)
    );

    Cbus_rx_pma_prbs_chk #(
        .N  (31),
        .TAP(28)
    ) i_prbs31 (
        .clk (clk   ),
        .rst (rst   ),
        .ce  (1'b1  ),
        .din (din   ),
        .dout(prbs31)
    );

    always_ff @ (posedge clk) begin
        mux <= ctrl_rxprbssel == 3'b001 ? prbs7  :
               ctrl_rxprbssel == 3'b010 ? prbs15 :
               ctrl_rxprbssel == 3'b011 ? prbs23 :
               ctrl_rxprbssel == 3'b100 ? prbs31 : 0;
    end

    always_ff @ (posedge clk) begin
        if (rst || ctrl_rxprbscntreset) begin
            rxprbserrcnt <= 0;
        end else if (rxprbserrcnt != 16'hFFFF && mux) begin
            rxprbserrcnt <= rxprbserrcnt + 1;
        end
    end

    assign stat_rxprbserrcnt = rxprbserrcnt;
    assign stat_rxprbserr = mux;

endmodule
