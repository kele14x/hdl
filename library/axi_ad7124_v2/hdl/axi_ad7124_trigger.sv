/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 100 ps
`default_nettype none

module axi_ad7124_trigger (
    input  wire spi_clk   ,
    input  wire spi_resetn,
    input  wire spi_sdi   ,
    input  wire spi_active,
    input  wire spi_cs    ,
    output reg  trigger
);

    (* async_reg="true" *)
    reg sdi_d1, sdi_d2;

    always_ff @ (posedge spi_clk) begin
        sdi_d1 <= spi_sdi;
        sdi_d2 <= sdi_d1;
    end

    always_ff @ (posedge spi_clk) begin
        if (~spi_resetn)
            trigger <= 1'b0;
        else
            trigger <= ((spi_cs == 1'b0) && (spi_active == 1'b0) &&
                (sdi_d1 == 1'b0) && (sdi_d2 == 1'b1));
    end

endmodule

`default_nettype wire
