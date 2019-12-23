/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

(* keep_hierarchy="yes" *)
module axi_ads124x_ctrl #(
    parameter C_CLK_FREQ = 125000
) (
    input  wire       aclk         ,
    input  wire       aresetn      ,
    //
    input  wire       pps          ,
    // SPI send
    output reg  [7:0] spitx_axis_tdata ,
    output reg        spitx_axis_tvalid,
    input  wire       spitx_axis_tready,
    // SPI receive
    input  wire [7:0] spirx_axis_tdata ,
    input  wire       spirx_axis_tvalid,
    output wire       spirx_axis_tready,
    //
    output reg  [31:0] adc_axis_tdata,
    output reg         adc_axis_tvalid,
    input  wire        adc_axis_tready,
    //
    output wire       RESET        ,
    output wire       START        ,
    input  wire       DRDY         ,
    // Control
    //--------
    input  wire       ctrl_op_mod  , // 0 = ctrl i/f control, 1 = auto control 
    // Send SPI
    input  wire [31:0] ctrl_spi_send,
    input  wire [1:0] ctrl_spi_nbytes,
    input  wire       ctrl_spi_valid,
    // Status
    //--------
    output reg  [31:0] stat_spi_recv
);

    import axi_ads124x_pkg::*;

    localparam C_CNT_WIDTH = $clog2(C_CLK_FREQ-1);

    reg [C_CNT_WIDTH-1:0] counter;
    reg sample_tick;

    always_ff @ (posedge aclk) begin
        counter <= (!aresetn || pps || counter == C_CLK_FREQ - 1) ? 0 : counter + 1;
    end

    always_ff @ (posedge aclk) begin
        sample_tick = (counter == 100);
    end

    typedef enum {S_RST, S_IDLE, S_AUTO_NOP0, S_AUTO_NOP1, S_AUTO_NOP2, 
        S_CTRL_CMD0, S_CTRL_CMD1, S_CTRL_CMD2, S_CTRL_CMD3} STATE_T;

    STATE_T state, state_next;

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            state <= S_RST;
        end else begin
            state <= state_next;
        end
    end 

    always_comb begin
        case (state)
            S_RST       : state_next = S_IDLE;
            S_IDLE      : state_next = (ctrl_op_mod && sample_tick) ? S_AUTO_NOP0 : S_IDLE; // TODO: state should change to S_CTRL_* too
            S_AUTO_NOP0 : state_next = (spitx_axis_tready) ? S_AUTO_NOP1 : S_AUTO_NOP0;
            S_AUTO_NOP1 : state_next = (spitx_axis_tready) ? S_AUTO_NOP2 : S_AUTO_NOP1;
            S_AUTO_NOP2 : state_next = (spitx_axis_tready) ? S_IDLE      : S_AUTO_NOP2;
            default     : state_next = S_RST;
        endcase
    end

    always_ff @ (posedge aclk) begin
        if (state_next == S_AUTO_NOP0) begin
            spitx_axis_tdata <= SPI_CMD_NOP;
        end else if (state_next == S_AUTO_NOP1) begin
            spitx_axis_tdata <= SPI_CMD_NOP;
        end else if (state_next == S_AUTO_NOP2) begin
            spitx_axis_tdata <= SPI_CMD_NOP;
        end
    end

    always_ff @ (posedge aclk) begin
        spitx_axis_tvalid <= (state_next == S_AUTO_NOP0 || 
            state_next == S_AUTO_NOP1 || state_next == S_AUTO_NOP2);
    end

    assign spirx_axis_tready = 1'b1;

    always_ff @ (posedge aclk) begin
        if (state == S_AUTO_NOP0 && spirx_axis_tvalid) begin
            adc_axis_tdata[23:16] <= spirx_axis_tdata;
        end
        if (state == S_AUTO_NOP1 && spirx_axis_tvalid) begin
            adc_axis_tdata[15: 8] <= spirx_axis_tdata;
        end
        if (state == S_AUTO_NOP2 && spirx_axis_tvalid) begin
            adc_axis_tdata[ 7: 0] <= spirx_axis_tdata;
        end
    end

endmodule

`default_nettype wire
