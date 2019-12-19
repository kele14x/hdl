/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module spi_axi_ctrl (
    input  wire        clk         ,
    input  wire        rst         ,
    //
    input  wire [ 7:0] spi_rx_data ,
    input  wire        spi_rx_first,
    input  wire        spi_rx_valid,
    //
    output reg  [ 7:0] spi_tx_data ,
    output reg         spi_tx_load ,
    // SFR
    //======
    output wire [11:0] sfr_wr_addr ,
    output wire [15:0] sfr_wr_data ,
    output wire        sfr_wr_en   ,
    // Read
    output wire [11:0] sfr_rd_addr ,
    output wire        sfr_rd_en   ,
    input  wire [15:0] sfr_rd_data ,
    //
    output wire [11:0] axi_wr_addr ,
    output wire [31:0] axi_wr_data ,
    output wire        axi_wr_en   ,
    // Read
    output wire [11:0] axi_rd_addr ,
    output wire        axi_rd_en   ,
    input  wire [31:0] axi_rd_data
);

    localparam C_OP_RDSFR = 4'b0000;
    localparam C_OP_WRSFR = 4'b0001;
    localparam C_OP_RDAXI = 4'b0010;
    localparam C_OP_WRAXI = 4'b0011;

    reg [3:0] addr_temp;
    reg [7:0] data_temp0, data_temp1, data_temp2;

    typedef enum {
        S_RD_SFR_ADDR, S_RD_SFR_BYTE0, S_RD_SFR_BYTE1,
        S_WR_SFR_ADDR, S_WR_SFR_BYTE0, S_WR_SFR_BYTE1,
        S_RD_AXI_ADDR, S_RD_AXI_BYTE0, S_RD_AXI_BYTE1, S_RD_AXI_BYTE2, S_RD_AXI_BYTE3,
        S_WR_AXI_ADDR, S_WR_AXI_BYTE0, S_WR_AXI_BYTE1, S_WR_AXI_BYTE2, S_WR_AXI_BYTE3,
        S_DISCARD
    } STATE_T;

    STATE_T state, state_next;

    always_ff @ (posedge clk) begin
        if (rst) begin
            state <= S_DISCARD;
        end else begin
            state <= state_next;
        end
    end

    always_comb begin
        if (!spi_rx_valid) begin
            state_next = state;
        end else if (spi_rx_first) begin
             state_next = spi_rx_data[7:4] == C_OP_RDSFR ? S_RD_SFR_ADDR :
                                              spi_rx_data[7:4] == C_OP_WRSFR ? S_WR_SFR_ADDR :
                                              spi_rx_data[7:4] == C_OP_RDAXI ? S_RD_AXI_ADDR :
                                              spi_rx_data[7:4] == C_OP_RDSFR ? S_RD_SFR_ADDR :
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
            addr_temp <= spi_rx_data[3:0];
        end
    end

    always_ff @ (posedge clk) begin
        if (spi_rx_valid && (state == S_WR_SFR_BYTE0)) begin
            data_temp0 <= spi_rx_data;
        end
        if (spi_rx_valid && (state == S_WR_AXI_BYTE0)) begin
            data_temp0 <= spi_rx_data;
        end
        if (spi_rx_valid && (state == S_WR_AXI_BYTE1)) begin
            data_temp1 <= spi_rx_data;
        end
        if (spi_rx_valid && (state == S_WR_AXI_BYTE2)) begin
            data_temp2 <= spi_rx_data;
        end
    end

    assign sfr_wr_addr = {addr_temp, spi_rx_data};
    assign sfr_wr_data = {data_temp0, spi_rx_data};
    assign sfr_wr_en   = spi_rx_valid && (state == S_RD_SFR_BYTE1);

    assign sfr_rd_addr = {addr_temp, spi_rx_data};
    assign sfr_rd_en   = spi_rx_valid && state == S_RD_SFR_ADDR;

    assign axi_wr_addr = {addr_temp, spi_rx_data};
    assign axi_wr_data = {data_temp0, spi_rx_data};
    assign axi_wr_en   = spi_rx_valid && (state == S_RD_AXI_BYTE3);

    assign axi_rd_addr = {addr_temp, spi_rx_data};
    assign axi_rd_en   = spi_rx_valid && state == S_RD_AXI_ADDR;

endmodule

`default_nettype wire
