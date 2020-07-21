/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module ext_trg (
    input  wire       clk              ,
    input  wire       ext_trg_in       ,
    input  wire [1:0] ctrl_trigger_type, // 00 = rising edge, 01 = failing edge, 10 = both, 11 = reserved
    output reg        ext_trg_out
);

    (* ASYNC_REG="TRUE" *)
    reg [1:0] async_reg;
    reg [3:0] sync_reg ;
    reg stat, stat_d;

    always_ff @ (posedge clk) begin
        async_reg[0] <= ext_trg_in;
        async_reg[1] <= async_reg[0];
    end

    always_ff @ (posedge clk) begin
        sync_reg <= {sync_reg[2:0], async_reg[1]};
    end

    always_ff @ (posedge clk) begin
        if (sync_reg == 4'b1111) stat <= 1'b1;
        if (sync_reg == 4'b0000) stat <= 1'b0;
    end

    always_ff @ (posedge clk) begin
        stat_d <= stat;
    end

    always_ff @ (posedge clk) begin
        ext_trg_out <= (ctrl_trigger_type == 2'b00) ? ({stat, stat_d} == 2'b10) :
                       (ctrl_trigger_type == 2'b01) ? ({stat, stat_d} == 2'b01) :
                       (ctrl_trigger_type == 2'b10) ? (({stat, stat_d} == 2'b10) || ({stat, stat_d} == 2'b01)) : 1'b0;
    end

endmodule

`default_nettype wire
