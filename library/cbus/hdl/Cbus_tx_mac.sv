/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

(* keep_hierarchy="yes" *)
module Cbus_tx_mac (
    // Clock & Reset
    input  wire               tx_clk       ,
    input  wire               tx_rst       ,
    // Tx AXIS
    input  wire [        7:0] s_axis_tdata ,
    input  wire               s_axis_tvalid,
    input  wire               s_axis_tlast ,
    output wire               s_axis_tready,
    // To TX PCS
    output wire [7:0] pcs_txdata   , // Tx Data
    output wire   pcs_txcharisk, // Tx Char is Key
    output wire [3:0] pcs_txseq      // Tx Sequence
);

    import Cbus_pkg::*;

    // 0 to 9 Sequence Counter
    reg [3:0] seq_cnt;
    wire clk_en, clk_en_d, clk_en_dd;

    reg  [8:0] udata      ;
    wire       udata_valid;
    wire       udata_ack  ;

    typedef enum {S_IDLE, S_SCP1, S_SCP2, S_ECP1, S_ECP2, S_UDATA} STATE_T;
    STATE_T state, next_state;

    reg [7:0] udata_r;
    reg send_idle, send_udata, send_SCP1, send_SCP2, send_ECP1, send_ECP2;

    wire send_K, send_A, send_R;

    reg [7:0] pcs_txdata_int   ;
    reg  pcs_txcharisk_int;
    reg [3:0] pcs_txseq_int    ;

    // s_axis_tdata   -> tdata                              -> pcs_txdata
    // s_axis_tvalid  -> seq_cnt -> send_idle -> send_K/R/A -> pcs_txcharisk
    // s_axis_tlast              -> send_SCP1 -> send_SCP_d -> pcs_txseq
    // s_axis_tready  -> clk_en  -> clk_en_d  -> clk_en_dd
    //                -> state

    Cbus_tx_mac_axisif i_axisif (
        .tx_clk       (tx_clk       ),
        .tx_rst       (tx_rst       ),
        //
        .s_axis_tdata (s_axis_tdata ),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tlast (s_axis_tlast ),
        .s_axis_tready(s_axis_tready),
        //
        .udata        (udata        ),
        .udata_valid  (udata_valid  ),
        .udata_ack    (udata_ack    )
    );

    assign udata_ack = (clk_en && (state == S_UDATA));

    // Step 1, generate a stable 0 to 9 sequence

    always_ff @ (posedge tx_clk) begin
        if (tx_rst) begin
            seq_cnt <= 4'h0;
        end else begin
            seq_cnt <= (seq_cnt == 9) ? 0 : (seq_cnt + 1);
        end
    end

    assign clk_en    = (seq_cnt == 1);
    assign clk_en_d  = (seq_cnt == 2);
    assign clk_en_dd = (seq_cnt == 3);

    // Step 2, state machine

    always_ff @ (posedge tx_clk) begin
        if (tx_rst) begin
            state <= S_IDLE;
        end else begin
            state <= next_state;
        end
    end

    always_comb begin
        case (state)
            S_IDLE  : next_state = !udata_valid ? S_IDLE  : S_SCP1;
            S_SCP1  : next_state = !clk_en      ? S_SCP1  : S_SCP2;
            S_SCP2  : next_state = !clk_en      ? S_SCP2  : S_UDATA;
            S_UDATA : next_state = !clk_en      ? S_UDATA :
                                   !udata_valid ? S_UDATA :
                                   !udata[8]    ? S_UDATA : S_ECP1;
            S_ECP1  : next_state = !clk_en      ? S_ECP1  : S_ECP2;
            S_ECP2  : next_state = !clk_en      ? S_ECP2  : S_IDLE;
            default : next_state = S_IDLE;
        endcase
    end

    //-----------------------------------
    // Step 3, From state -> send char
    //-----------------------------------

    always_ff @ (posedge tx_clk) begin
        if (clk_en) begin
            send_idle  <= ((state == S_IDLE) || (state == S_UDATA && !udata_valid));
            send_SCP1  <= (state == S_SCP1);
            send_SCP2  <= (state == S_SCP2);
            send_ECP1  <= (state == S_ECP1);
            send_ECP2  <= (state == S_ECP2);
            send_udata <= (state == S_UDATA && udata_valid);
            udata_r    <= (state == S_UDATA && udata_valid) ? udata : 'd0;
        end
    end

    Cbus_idle_gen i_idle_gen (
        .clk      (tx_clk   ),
        .clk_en   (clk_en_d ),
        .rst      (tx_rst   ),
        .send_idle(send_idle),
        .send_K   (send_K   ),
        .send_A   (send_A   ),
        .send_R   (send_R   )
    );

    always_ff @ (posedge tx_clk) begin
        if (tx_rst) begin
            {pcs_txcharisk_int, pcs_txdata_int} <= 0;
        end else if (clk_en_dd) begin
            {pcs_txcharisk_int, pcs_txdata_int} <=
                send_SCP1 ? ORDERED_SETS_SCP1 :
                send_SCP2 ? ORDERED_SETS_SCP2 :
                send_ECP1 ? ORDERED_SETS_ECP1 :
                send_ECP2 ? ORDERED_SETS_ECP2 :
                send_K    ? ORDERED_SETS_K :
                send_A    ? ORDERED_SETS_A :
                send_R    ? ORDERED_SETS_R : DChar(udata_r[4:0] ,udata_r[7:5]);
        end
    end

    always_ff @ (posedge tx_clk) begin
        if (clk_en_dd || tx_rst) begin
            pcs_txseq_int <= 0;
        end else begin
            pcs_txseq_int <= (pcs_txseq_int == 9) ? 0 : (pcs_txseq_int + 1);
        end
    end

    assign pcs_txdata    = pcs_txdata_int;
    assign pcs_txcharisk = pcs_txcharisk_int;
    assign pcs_txseq     = pcs_txseq_int;



endmodule
