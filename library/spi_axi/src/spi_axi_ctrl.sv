/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module spi_axi_ctrl (
    input  wire        clk         ,
    input  wire        rst         ,
    // SPI
    //=====
    input  wire        spi_rx_ss   ,
    input  wire [ 7:0] spi_rx_byte ,
    input  wire [ 2:0] spi_rx_bitcnt,
    input  wire        spi_rx_valid,
    //
    output reg  [ 7:0] spi_tx_data ,
    input  reg         spi_tx_load ,
    // AXI
    //=====
    output wire [14:0] axi_wr_addr ,
    output wire [31:0] axi_wr_data ,
    output wire        axi_wr_en   ,
    // Read
    output wire [14:0] axi_rd_addr ,
    output wire        axi_rd_en   ,
    input  wire [31:0] axi_rd_data
);

    localparam C_OP_RD = 1'b0;
    localparam C_OP_WR = 1'b1;

    reg [3:0] mode_r;
    reg [3:0] addr_r0;
    reg [7:0] addr_r1;
    reg [7:0] data_temp0, data_temp1, data_temp2;

    typedef enum {
        S_RST, S_IDLE,
        S_RW_ADDR0, S_ADDR1,
        S_RD_BYTE0, S_RD_BYTE1, S_RD_BYTE2, S_RD_BYTE3,
        S_WR_BYTE0, S_WR_BYTE1, S_WR_BYTE2, S_WR_BYTE3
    } STATE_T;

    STATE_T state, state_next;

    always_ff @ (posedge clk) begin
        if (rst) begin
            state <= S_RST;
        end else begin
            state <= state_next;
        end
    end

    always_comb begin
        if (spi_rx_ss) begin
            state_next = S_IDLE;
        end else if (!spi_rx_valid) begin
            // Do not move to next state when rx is not valid
            state_next = state;
        end else if (spi_rx_bitcnt) begin
            state_next = spi_rx_byte[7:4] == C_OP_RDSFR ? S_RD_SFR_ADDR :
                                              spi_rx_byte[7:4] == C_OP_WRSFR ? S_WR_SFR_ADDR :
                                              spi_rx_byte[7:4] == C_OP_RDAXI ? S_RD_AXI_ADDR :
                                              spi_rx_byte[7:4] == C_OP_RDSFR ? S_RD_SFR_ADDR :
                                              S_DISCARD;
        end else begin
            case (state)
                S_RD_SFR_ADDR : state_next = S_RD_SFR_BYTE0;
                S_RD_SFR_BYTE0: state_next = S_RD_SFR_BYTE1;
                S_RD_SFR_BYTE1: state_next = S_DISCARD;
                S_WR_SFR_ADDR : state_next = S_WR_SFR_BYTE0;
                S_WR_SFR_BYTE0: state_next = S_WR_SFR_BYTE1;
                S_WR_SFR_BYTE1: state_next = S_DISCARD;

                default       : state_next = state;
            endcase
        end
    end

    always_ff @ (posedge clk) begin
        if (spi_rx_first && spi_rx_valid) begin
            mode_r <= spi_rx_byte[7:4];
        end
    end

    always_ff @ (posedge clk) begin
        if (spi_rx_first && spi_rx_valid) begin
            addr_r0 <= spi_rx_byte[3:0];
        end
        if (spi_rx_valid && state == S_WR_SFR_ADDR) begin
            addr_r1 <= spi_rx_byte;
        end
    end

    always_ff @ (posedge clk) begin
        if (spi_rx_valid && (state == S_WR_SFR_BYTE0)) begin
            data_temp0 <= spi_rx_byte;
        end
        if (spi_rx_valid && (state == S_WR_AXI_BYTE0)) begin
            data_temp0 <= spi_rx_byte;
        end
        if (spi_rx_valid && (state == S_WR_AXI_BYTE1)) begin
            data_temp1 <= spi_rx_byte;
        end
        if (spi_rx_valid && (state == S_WR_AXI_BYTE2)) begin
            data_temp2 <= spi_rx_byte;
        end
    end

    assign sfr_addr = mode_r[0] ? {addr_r0, addr_r1} : {addr_r0, spi_rx_byte};
    assign sfr_din  = {data_temp0, spi_rx_byte};
    assign sfr_wren = spi_rx_valid && (state == S_WR_SFR_BYTE1);
    assign sfr_rden = spi_rx_valid && state == S_RD_SFR_ADDR;


    assign axi_wr_addr = {addr_r0, spi_rx_byte};
    assign axi_wr_data = {data_temp0, spi_rx_byte};
    assign axi_wr_en   = spi_rx_valid && (state == S_RD_AXI_BYTE3);

    assign axi_rd_addr = {addr_r0, spi_rx_byte};
    assign axi_rd_en   = spi_rx_valid && state == S_RD_AXI_ADDR;


    always_comb begin
        spi_tx_data = (state == S_RD_SFR_BYTE0) ? sfr_dout[15:8] :
                      (state == S_RD_SFR_BYTE1) ? sfr_dout[ 7:0] :
                      (state == S_RD_AXI_BYTE0) ? sfr_dout[15:8] :
                      (state == S_RD_AXI_BYTE0) ? sfr_dout[15:8] :
                      (state == S_RD_AXI_BYTE0) ? sfr_dout[15:8] :
                      (state == S_RD_AXI_BYTE0) ? sfr_dout[15:8] :
                      8'h00;
    end

endmodule

`default_nettype wire
