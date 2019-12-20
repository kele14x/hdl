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
    input  wire [ 7:0] spi_rx_byte ,
    input  wire        spi_rx_first,
    input  wire        spi_rx_valid,
    //
    output reg  [ 7:0] spi_tx_data ,
    input  reg         spi_tx_load ,
    // SFR
    //======
    output wire [11:0] sfr_addr   ,
    output wire [15:0] sfr_din    ,
    output wire        sfr_wren   ,
    output wire        sfr_rden   ,
    input  wire [15:0] sfr_dout   ,
    // AXI
    //=====
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

    reg [3:0] mode_r;
    reg [3:0] addr_r0;
    reg [7:0] addr_r1;
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
            // Do not move to next state when rx is not valid
            state_next = state;
        end else if (spi_rx_first) begin
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
