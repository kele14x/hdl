/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 100 ps
`default_nettype none

module axi_ad7124_trigger (
    input  var logic clk       ,
    input  var logic rst       ,
    //
    input  var logic spi_sdi   ,
    input  var logic spi_active,
    input  var logic spi_cs    ,
    //
    output var logic trigger
);

    (* async_reg="true" *)
    reg sdi_d1, sdi_d2;

    always_ff @ (posedge clk) begin
        sdi_d1 <= spi_sdi;
        sdi_d2 <= sdi_d1;
    end

    always_ff @ (posedge clk) begin
        if (rst) begin
            trigger <= 1'b0;
        end else begin
            trigger <= ((spi_cs == 1'b0) && (spi_active == 1'b0) &&
                (sdi_d1 == 1'b0) && (sdi_d2 == 1'b1));
        end
    end

endmodule

`default_nettype wire
