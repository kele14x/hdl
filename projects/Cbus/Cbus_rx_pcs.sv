/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

(* keep_hierarchy="yes" *)
module Cbus_rx_pcs #(parameter SYS_W = 1) (
    output wire       pma_arst        , // Async reset
    input  wire       pma_rxclk       ,
    input  wire       pma_rxrst       ,
    input  wire [9:0] pma_rxdata      , // Rx Data
    input  wire       pma_rxvalid     , // Rx Valid
    //
    input  wire       pcs_rxclk       ,
    input  wire       pcs_rxrst       ,
    output wire [7:0] pcs_rxdata      , // Rx Data
    output wire       pcs_rxcharisk   , // Rx Char is Key
    output wire       pcs_rxdisperr   , // Rx Disp Error
    output wire       pcs_rxnotintable, // Rx Not in Table
    output wire       pcs_rxvalid       // Rx Valid
);

    wire run_disp;

    wire [7:0] enc_rxdata;
    wire enc_rxcharisk, enc_rxnotintable, enc_rxdisperr;

    wire [10:0] wr_data;
    wire        wr_en;
    wire [10:0] rd_data;

    assign pma_arst  = pcs_rxrst;

    (* keep_hierarchy="yes" *)
    decode_8b10b_top #(
        .C_DECODE_TYPE (0           ),
        .C_HAS_BPORTS  (0           ),
        .C_HAS_CE      (1           ),
        .C_HAS_CODE_ERR(1           ),
        .C_HAS_DISP_ERR(1           ),
        .C_HAS_DISP_IN (1           ),
        .C_HAS_ND      (1           ),
        .C_HAS_RUN_DISP(1           ),
        .C_HAS_SINIT   (1           ),
        .C_HAS_SYM_DISP(1           ),
        .C_SINIT_VAL   ("0000000000"),
        .C_SINIT_VAL_B ("0000000000")
    ) i_decode_8b10b (
        .CLK     (pma_rxclk       ),
        .SINIT   (pma_rxrst       ),
        .CE      (pma_rxvalid     ),
        //
        .DISP_IN (run_disp        ),
        .DIN     (pma_rxdata      ),
        //
        .RUN_DISP(run_disp        ),
        .DOUT    (enc_rxdata      ),
        .KOUT    (enc_rxcharisk   ),
        .DISP_ERR(enc_rxdisperr   ),
        .CODE_ERR(enc_rxnotintable),
        .ND      (wr_en           ),
        .SYM_DISP(                )
    );

    assign wr_data = {enc_rxnotintable, enc_rxdisperr, enc_rxcharisk, enc_rxdata};

    Cbus_rx_pcs_fifo i_Cbus_rx_pcs_fifo (
        .wr_clk  (pma_rxclk  ),
        .wr_rst  (pma_rxrst  ),
        .wr_din  (wr_data    ),
        .wr_en   (wr_en      ),
        .rd_clk  (pcs_rxclk  ),
        .rd_dout (rd_data    ),
        .rd_valid(pcs_rxvalid)
    );

    assign {pcs_rxnotintable, pcs_rxdisperr, pcs_rxcharisk, pcs_rxdata} = rd_data;


endmodule
