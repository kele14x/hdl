/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

(* keep_hierarchy="yes" *)
module Cbus_tx_mac_axisif (
    // Clock & Reset
    input  wire       tx_clk       ,
    input  wire       tx_rst       ,
    // Tx AXIS
    input  wire [7:0] s_axis_tdata ,
    input  wire       s_axis_tvalid,
    input  wire       s_axis_tlast ,
    output wire       s_axis_tready,
    //
    output reg  [8:0] udata        ,
    output reg        udata_valid  ,
    input  wire       udata_ack
);

    reg tready;

    always_ff @ (posedge tx_clk) begin : p_tready
        if (tx_rst) begin
            tready <= 1'b0;
        end else if (tready && s_axis_tvalid) begin
            tready <= 1'b0;
        end else if (udata_ack) begin
            tready <= 1'b1;
        end else begin
            tready <= !udata_valid;
        end
    end

    always_ff @ (posedge tx_clk) begin : p_udata_valid
        if (tx_rst) begin
            udata_valid <= 1'b0;
        end else if (tready && s_axis_tvalid) begin
            udata_valid <= 1'b1;
        end else if (udata_ack) begin
            udata_valid <= 1'b0;
        end
    end

    always_ff @ (posedge tx_clk) begin : p_udata
        if (tx_rst) begin
            udata <= 0;
        end else if (tready && s_axis_tvalid) begin
            udata <= {s_axis_tlast, s_axis_tdata};
        end
    end

    assign s_axis_tready = tready;

endmodule
