/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

(* keep_hierarchy="yes" *)
module Cbus_idle_gen (
    input  wire clk      ,
    input  wire clk_en   ,
    input  wire rst      ,
    input  wire send_idle,
    //
    output wire send_K   ,
    output wire send_A   ,
    output wire send_R
);

    reg send_idle_dlyd, send_K_int, send_A_int, send_R_int;

    reg [6:0] pseudo_gen;
    wire pseudo_gen_bit;

    reg [4:0] down_cnt;
    wire cnt_eq_zero;

    always_ff @ (posedge clk) begin
        if (rst) begin
            send_idle_dlyd <= 1'b0;
        end else if (clk_en) begin
            send_idle_dlyd <= send_idle;
        end
    end

    always_ff @ (posedge clk) begin
        if (rst) begin
            pseudo_gen <= 'h2;
        end else if (clk_en) begin
            // x^7 + x^6 + 1
            pseudo_gen <= {pseudo_gen[6]^pseudo_gen[0], pseudo_gen[6:1]};
        end
    end

    assign pseudo_gen_bit = pseudo_gen[0];

    assign cnt_eq_zero = (down_cnt == 0);

    always_ff @ (posedge clk) begin
        if (rst) begin
            down_cnt <= 'd0;
        end else if (clk_en) begin
            if (cnt_eq_zero) begin
                down_cnt <= pseudo_gen[4:0];
            end else begin
                down_cnt <= down_cnt - 1;
            end
        end
    end

    always_ff @ (posedge clk) begin
        if (rst) begin
            send_K_int <= 1'b0;
            send_A_int <= 1'b0;
            send_R_int <= 1'b0;
        end else if (clk_en) begin
            send_K_int <= send_idle & (!send_idle_dlyd | send_idle_dlyd & !cnt_eq_zero & pseudo_gen_bit);
            send_A_int <= send_idle & send_idle_dlyd & cnt_eq_zero;
            send_R_int <= send_idle & send_idle_dlyd & !cnt_eq_zero & !pseudo_gen_bit;
        end
    end

    assign send_K = send_K_int;
    assign send_A = send_A_int;
    assign send_R = send_R_int;

`define DEBUG
`ifdef DEBUG

    assert property (@(posedge clk) rst |=> (send_K == 1'b0));

    assert property (@(posedge clk) rst |=> (send_A == 1'b0));

    assert property (@(posedge clk) rst |=> (send_R == 1'b0));

    assert property (@(posedge clk) (!rst && clk_en && send_idle)  |=> (send_K || send_A || send_R));

    assert property (@(posedge clk) (!rst && clk_en && !send_idle)  |=> (!send_K && !send_A && !send_R));

`endif

endmodule
