/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module axi_ads124x_regs #(
    parameter C_ADDR_WIDTH = 10,
    parameter C_DATA_WIDTH = 32
) (
    input  var logic                    clk             ,
    input  var logic                    rst             ,
    //
    input  var logic [C_ADDR_WIDTH-1:0] up_wr_addr      ,
    input  var logic                    up_wr_req       ,
    input  var logic [C_DATA_WIDTH-1:0] up_wr_din       ,
    output var logic                    up_wr_ack       ,
    //
    input  var logic [C_ADDR_WIDTH-1:0] up_rd_addr      ,
    input  var logic                    up_rd_req       ,
    output var logic [C_DATA_WIDTH-1:0] up_rd_dout      ,
    output var logic                    up_rd_ack       ,
    //
    output var logic                    ctrl_soft_reset ,
    //
    output var logic                    ctrl_op_mode    ,
    //
    output var logic                    ctrl_ad_start   ,
    output var logic                    ctrl_ad_reset   ,
    input  var logic                    stat_ad_drdy    ,
    //
    output var logic [             1:0] ctrl_spi_txbytes,
    output var logic [            31:0] ctrl_spi_txdata ,
    output var logic                    ctrl_spi_txvalid,
    //
    input  var logic [            31:0] stat_spi_rxdata ,
    input  var logic                    stat_spi_rxvalid
);


    // Write

    // ctrl_soft_reset at address = 0, bit[0]
    always_ff @ (posedge clk) begin
        if (rst) begin
            ctrl_soft_reset <= 1'b0;
        end else if (up_wr_req && up_wr_addr == 'd0) begin
            ctrl_soft_reset <= up_wr_din[0];
        end
    end

    // ctrl_op_mode at address = 1, bit[0]
    always_ff @ (posedge clk) begin
        if (rst) begin
            ctrl_op_mode <= 1'b0;
        end else if (up_wr_req && up_wr_addr == 'd1) begin
            ctrl_op_mode <= up_wr_din[0];
        end
    end

    // ctrl_ad_start at address = 2, bit[0]
    always_ff @ (posedge clk) begin
        if (rst) begin
            ctrl_ad_start <= 1'b0;
        end else if (up_wr_req && up_wr_addr == 'd2) begin
            ctrl_ad_start <= up_wr_din[0];
        end
    end

    // ctrl_ad_reset at address = 3, bit[0]
    always_ff @ (posedge clk) begin
        if (rst) begin
            ctrl_ad_reset <= 1'b1;
        end else if (up_wr_req && up_wr_addr == 'd3) begin
            ctrl_ad_reset <= up_wr_din[0];
        end
    end

    // ctrl_spi_txbytes at address = 5, bit[0]
    always_ff @ (posedge clk) begin
        if (rst) begin
            ctrl_spi_txbytes <= 1'b0;
        end else if (up_wr_req && up_wr_addr == 'd5) begin
            ctrl_spi_txbytes <= up_wr_din[1:0];
        end
    end

    // ctrl_spi_txdata at address = 6, bit[0]
    always_ff @ (posedge clk) begin
        if (rst) begin
            ctrl_spi_txdata <= 1'b0;
            ctrl_spi_txvalid <= 1'b0;
        end else if (up_wr_req && up_wr_addr == 'd6) begin
            ctrl_spi_txdata <= up_wr_din[31:0];
            ctrl_spi_txvalid <= 1'b1;
        end else begin
            ctrl_spi_txvalid <= 1'b0;
        end
    end

    // It take 1 clock to write response
    always_ff @ (posedge clk) begin
        if (rst) begin
            up_wr_ack <= 1'b0;
        end else begin
            up_wr_ack <= up_wr_req;
        end
    end

    // Read

    always_ff @ (posedge clk) begin
        if (rst) begin
            up_rd_dout <= 'd0;
        end else if (up_rd_req) begin
            case (up_rd_addr)
                'd0    : up_rd_dout <= {31'd0, ctrl_soft_reset};
                'd1    : up_rd_dout <= {31'd0, ctrl_op_mode};
                'd2    : up_rd_dout <= {31'd0, ctrl_ad_start};
                'd3    : up_rd_dout <= {31'd0, ctrl_ad_reset};
                'd4    : up_rd_dout <= {31'd0, stat_ad_drdy};
                'd5    : up_rd_dout <= {30'd0, ctrl_spi_txbytes};
                'd6    : up_rd_dout <= ctrl_spi_txdata;
                'd7    : up_rd_dout <= stat_spi_rxdata;
                'd8    : up_rd_dout <= {31'd0, stat_spi_rxvalid};
                default: up_rd_dout <= 32'hDEADBEEF;
            endcase
        end
    end

    // It takes 1 clock for read response
    always_ff @ (posedge clk) begin
        if (rst) begin
            up_rd_ack <= 1'b0;
        end else begin
            up_rd_ack <= up_rd_req;
        end
    end

endmodule

`default_nettype wire
