/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module axi_ads868x_regs #(
    parameter        C_ADDR_WIDTH = 8         ,
    parameter [31:0] C_VERSION    = "20191230"
) (
    // User Ports
    //------------
    input  var logic                    clk             ,
    input  var logic                    rst             ,
    //
    input  var logic [C_ADDR_WIDTH-1:0] up_wr_addr      ,
    input  var logic                    up_wr_req       ,
    input  var logic [             3:0] up_wr_be        ,
    input  var logic [            31:0] up_wr_data      ,
    output var logic                    up_wr_ack       ,
    //
    input  var logic [C_ADDR_WIDTH-1:0] up_rd_addr      ,
    input  var logic                    up_rd_req       ,
    output var logic [            31:0] up_rd_data      ,
    output var logic                    up_rd_ack       ,
    // Core Ports
    //------------
    output var logic                    ctrl_soft_reset ,
    output var logic                    ctrl_power_down ,
    output var logic                    ctrl_auto_spi   ,
    //
    output var logic [             2:0] ctrl_ext_mux_sel,
    output var logic [             3:0] ctrl_ext_mux_en ,
    //
    output var logic [             1:0] ctrl_spi_txbyte ,
    output var logic [            31:0] ctrl_spi_txdata ,
    output var logic                    ctrl_spi_txvalid,
    //
    input  var logic [            31:0] stat_spi_rxdata ,
    input  var logic                    stat_spi_rxvalid
);

    // Write
    //=======

    // ctrl_soft_reset on reg[0] on address = 0
    always_ff @ (posedge clk) begin
        if (rst) begin
            ctrl_soft_reset <= 'd0;
        end else if (up_wr_req && up_wr_addr == 'd0 && up_wr_be[0]) begin
            ctrl_soft_reset <= up_wr_data[0];
        end
    end

    // ctrl_power_down on reg[0] on address = 1
    always_ff @ (posedge clk) begin
        if (rst) begin
            ctrl_power_down <= 'd0;
        end else if (up_wr_req && up_wr_addr == 'd1 && up_wr_be[0]) begin
            ctrl_power_down <= up_wr_data[0];
        end
    end

    // ctrl_auto_spi on reg[0] on address = 2
    always_ff @ (posedge clk) begin
        if (rst) begin
            ctrl_auto_spi <= 'd0;
        end else if (up_wr_req && up_wr_addr == 'd2 && up_wr_be[0]) begin
            ctrl_auto_spi <= up_wr_data[0];
        end
    end

    // ctrl_ext_mux_sel on reg[2:0]  on address = 3
    always_ff @ (posedge clk) begin
        if (rst) begin
            ctrl_ext_mux_sel <= 'd0;
        end else if (up_wr_req && up_wr_addr == 'd3 && up_wr_be[0]) begin
            ctrl_ext_mux_sel <= up_wr_data[2:0];
        end
    end

    // ctrl_ext_mux_en on reg[3:0] on address = 4
    always_ff @ (posedge clk) begin
        if (rst) begin
            ctrl_ext_mux_en <= 'd0;
        end else if (up_wr_req && up_wr_addr == 'd4 && up_wr_be[0]) begin
            ctrl_ext_mux_en <= up_wr_data[3:0];
        end
    end

    // ctrl_spi_txbyte on reg[1:0] on address = 5
    always_ff @ (posedge clk) begin
        if (rst) begin
            ctrl_spi_txbyte <= 2'b11;
        end else if (up_wr_req && up_wr_addr == 'd5 && up_wr_be[0]) begin
            ctrl_spi_txbyte <= up_wr_data[1:0];
        end
    end

    // ctrl_spi_txdata on reg[31:0] on address = 6
    always_ff @ (posedge clk) begin
        if (rst) begin
            ctrl_spi_txdata <= 32'd0;
        end else begin
            for (int i = 0; i < 4; i++) begin
                if (up_wr_req && up_wr_addr == 'd6 && up_wr_be[i]) begin
                    ctrl_spi_txdata[i*8+7-:8] <= up_wr_data[i*8+7-:8];
                end
            end
        end
    end

    // ctrl_spi_txvalid when write to address = 6
    always_ff @ (posedge clk) begin
        if (rst) begin
            ctrl_spi_txvalid <= 1'b0;
        end else begin
            ctrl_spi_txvalid <= (up_wr_req && up_wr_addr == 'd6);
        end
    end

    always_ff @ (posedge clk) begin
        if (rst) begin
            up_wr_ack  <= 1'b0;
        end else begin
            up_wr_ack <= up_wr_req;
        end
    end

    // Read
    //======

    // Read decode
    always_ff @ (posedge clk) begin
        if (rst) begin
            up_rd_data <= 32'd0;
        end else if (up_rd_req) begin
            // Address decode
            case (up_rd_addr)
                'd0    : up_rd_data <= {31'b0, ctrl_soft_reset};
                'd1    : up_rd_data <= {31'd0, ctrl_power_down};
                'd2    : up_rd_data <= {31'd0, ctrl_auto_spi};
                'd3    : up_rd_data <= {29'd0, ctrl_ext_mux_sel};
                'd4    : up_rd_data <= {28'd0, ctrl_ext_mux_en};
                'd5    : up_rd_data <= {30'd0, ctrl_spi_txbyte};
                'd6    : up_rd_data <= ctrl_spi_txdata;
                'd7    : up_rd_data <= stat_spi_rxdata;
                'd8    : up_rd_data <= stat_spi_rxvalid;
                default: up_rd_data <= 32'hDEADBEEF;
            endcase
        end
    end

    always_ff @ (posedge clk) begin
        if (rst) begin
            up_rd_ack  <= 1'b0;
        end else begin
            up_rd_ack <= up_rd_req;
        end
    end

endmodule

`default_nettype wire
