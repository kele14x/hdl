/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 100 ps
`default_nettype none

module axi_ad7124_rtd_offload #(
    parameter DATA_WIDTH = 8,
    parameter NUM_OF_SDI = 1
)(
    // Control Interface
    //------------------
    input  var logic                               ctrl_clk         ,
    //
    input  var logic                               ctrl_enable      ,
    output var logic                               ctrl_enabled     ,
    // Clock & Reset
    //--------------
    input  var logic                               spi_clk          ,
    input  var logic                               spi_resetn       ,
    // External Event
    //---------------
    input  var logic                               pps              ,
    input  var logic                               trigger          ,
    // SPI Engine Interface
    //---------------------
    output var logic                               cmd_valid        ,
    input  var logic                               cmd_ready        ,
    output var logic [                       15:0] cmd_data         ,
    //
    output var logic                               sdo_valid        ,
    input  var logic                               sdo_ready        ,
    output var logic [           (DATA_WIDTH-1):0] sdo_data         ,
    //
    input  var logic                               sdi_valid        ,
    output var logic                               sdi_ready        ,
    input  var logic [(NUM_OF_SDI*DATA_WIDTH-1):0] sdi_data         ,
    //
    input  var logic                               sync_valid       ,
    output var logic                               sync_ready       ,
    input  var logic [                        7:0] sync_data        ,
    // SDI output
    //-----------
    output var logic                               offload_sdi_valid,
    input  var logic                               offload_sdi_ready,
    output var logic [(NUM_OF_SDI*DATA_WIDTH-1):0] offload_sdi_data
);

    logic [3:0] state_channel = 0;

    //  0 - idle
    //  1 - cmd, chip-select 0xFE
    //  2 - cmd, transfer 10 bytes, write
    //  3 - sdo, 0x03
    //  4 - sdo, 0x00
    //  5 - sdo, 0x18
    //  6 - sdo, 0x00              60              C0
    //
    //  7 - sdo, 0x09
    //  8 - sdo, 0x80  80  80  80  80  81  81  81  81  81
    //  9 - sdo, 0x22  43  64  85  E8  09  2A  4B  AE  CF
    //
    // 10 - sdo, 0x01
    // 11 - sdo, 0x00
    // 12 - sdo, 0x84
    //
    // 13 - cmd, sync 0
    // 14 - wait trigger
    // 15 - cmd, transfer 4 bytes, write/read
    // 16 - sdo, 0x42
    // 17 - sdo, 0x00
    // 18 - sdo, 0x00
    // 19 - sdo, 0x00
    // 20 - cmd, chip-select 0xFF
    // 21 - cmd, sync 1
    //  x - recovery
    logic [4:0] state_tick, state_tick_next;


    always_ff @ (posedge spi_clk) begin
        if (~spi_resetn) begin
            state_channel <= 'd0;
        end else if (state_tick == 22) begin
            state_channel <= ((state_channel >= 9) ? 0 : state_channel + 1);
        end
    end


    always_ff @ (posedge spi_clk) begin
        if (~spi_resetn) begin
            state_tick <= 'd0;
        end else begin
            state_tick <= state_tick_next;
        end
    end


    always_comb begin
        if (state_tick == 0) begin
            state_tick_next = ((ctrl_enable && pps) ? 1 : 0);
        end else if (state_tick == 1 || state_tick == 2 || state_tick == 13 ||
            state_tick == 15 || state_tick == 20 || state_tick == 21) begin
            state_tick_next = cmd_ready ? state_tick + 1 : state_tick;
        end else if ((3 <= state_tick && state_tick <= 12) ||
            (16 <= state_tick && state_tick <= 19)) begin
            state_tick_next = sdo_ready ? state_tick + 1 : state_tick;
        end else if (state_tick == 14) begin
            state_tick_next = trigger ? 15 : 14;
        end else if (state_tick == 22) begin
            state_tick_next = ((state_channel == 9) ? 0 : 1);
        end else begin
            state_tick_next = 0;
        end
    end


    // CMD

    always_ff @ (posedge spi_clk) begin
        if (~spi_resetn) begin
            cmd_valid <= 1'b0;
        end else begin
            cmd_valid <= (state_tick_next == 1 || state_tick_next == 2 ||
                state_tick_next == 13 || state_tick_next == 15 ||
                state_tick_next == 20 || state_tick_next == 21);
        end
    end


    always_ff @ (posedge spi_clk) begin
        if (~spi_resetn) begin
            cmd_data <= 16'h0000;
        end else if (state_tick_next == 1) begin
            cmd_data <= 16'h10FE;
        end else if (state_tick_next == 2) begin
            cmd_data <= 16'h0109;
        end else if (state_tick_next == 13) begin
            cmd_data <= 16'h3000;
        end else if (state_tick_next == 15) begin
            cmd_data <= 16'h0303;
        end else if (state_tick_next == 20) begin
            cmd_data <= 16'h10FF;
        end else if (state_tick_next == 21) begin
            cmd_data <= 16'h3001;
        end else begin
            cmd_data <= 16'h0000;
        end
    end


    // SDO

    always_ff @ (posedge spi_clk) begin
        if (~spi_resetn) begin
            sdo_valid <= 1'b0;
        end else if (state_tick_next == 3) begin
            sdo_valid <= (3 <= state_tick_next && state_tick_next <= 12) ||
                (16 <= state_tick_next && state_tick_next <= 19);
        end
    end


    always_ff @ (posedge spi_clk) begin
        if (~spi_resetn) begin
            sdo_data <= 8'h00;
        end else if (state_tick_next == 3) begin
            sdo_data <= 8'h03;
        end else if (state_tick_next == 5) begin
            sdo_data <= 8'h18;
        end else if (state_tick_next == 6) begin
            sdo_data <= (state_channel <= 3) ? 8'h00 :
                        (state_channel <= 7) ? 8'h60 : 8'hC0;
        end else if (state_tick_next == 7) begin
            sdo_data <= 8'h09;
        end else if (state_tick_next == 8) begin
            sdo_data <= state_channel <= 4 ? 8'h80 : 8'h81;
        end else if (state_tick_next == 9) begin
            sdo_data <= state_channel == 0 ? 8'h22 :
                        state_channel == 1 ? 8'h43 :
                        state_channel == 2 ? 8'h64 :
                        state_channel == 3 ? 8'h85 :
                        state_channel == 4 ? 8'hE8 :
                        state_channel == 5 ? 8'h09 :
                        state_channel == 6 ? 8'h2A :
                        state_channel == 7 ? 8'h4B :
                        state_channel == 8 ? 8'hAE : 8'hCF;
        end else if (state_tick_next == 10) begin
            sdo_data <= 8'h01;
        end else if (state_tick_next == 12) begin
            sdo_data <= 8'h84;
        end else if (state_tick_next == 16) begin
            sdo_data <= 8'h42;
        end else begin
            sdo_data <= 8'h00;
        end
    end

    assign sync_ready = 1'b1;

    // sdi_data axis to offload_sdi axis

    // We don't want to block the SDI interface after disabling the module
    // so just assert the SDI_READY
    assign sdi_ready = (ctrl_enable) ? offload_sdi_ready : 1'b1;

    assign offload_sdi_valid = sdi_valid;
    assign offload_sdi_data = sdi_data;

endmodule

`default_nettype wire
