/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

(* keep_hierarchy="yes" *)
module Cbus_tx_pcs (
    input  wire       pcs_txclk    ,
    input  wire       pcs_txrst    ,
    input  wire [7:0] pcs_txdata   , // Tx Data
    input  wire       pcs_txcharisk, // Tx Char is Key
    input  wire [3:0] pcs_txseq    , // Tx Sequence
    //
    output wire       pma_txclk    ,
    output wire       pma_txrst    ,
    output wire [9:0] pma_txdata   ,
    output wire [3:0] pma_txseq
);

    wire clk_en;

    reg [3:0] seq_d;

    // 8b10b encoder

    assign clk_en = (pcs_txseq == 0);

    always_ff @ (posedge pcs_txclk)
        seq_d <= pcs_txseq;

    (* keep_hierarchy="yes" *)
    encode_8b10b_top #(
        .C_ENCODE_TYPE      (0           ),
        .C_FORCE_CODE_DISP  (0           ),
        .C_FORCE_CODE_DISP_B(0           ),
        .C_FORCE_CODE_VAL   ("1010101010"),
        .C_FORCE_CODE_VAL_B ("1010101010"),
        .C_HAS_BPORTS       (0           ),
        .C_HAS_CE           (1           ),
        .C_HAS_DISP_OUT     (1           ),
        .C_HAS_DISP_IN      (1           ),
        .C_HAS_FORCE_CODE   (1           ),
        .C_HAS_KERR         (1           ),
        .C_HAS_ND           (1           )
    ) i_encode_8b10b_top (
        .CLK       (pcs_txclk    ),
        .DIN       (pcs_txdata   ),
        .KIN       (pcs_txcharisk),
        .DOUT      (pma_txdata   ),
        .CE        (clk_en       ),
        .FORCE_CODE(pcs_txrst    ),
        .FORCE_DISP(pcs_txrst    ),
        .DISP_IN   (1'b0         ),
        .DISP_OUT  (             ),
        .ND        (             ),
        .KERR      (             )
    );

    assign pma_txclk = pcs_txclk;
    assign pma_txrst = pcs_txrst;

    assign pma_txseq = seq_d;

endmodule
