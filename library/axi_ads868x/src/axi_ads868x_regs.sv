/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module axi_ads868x_regs #(parameter [31:0] C_VERSION = "20191230") (
    // User Ports
    //------------
    input  var logic        up_clk          ,
    input  var logic        up_rstn         ,
    //
    input  var logic [ 9:0] up_wr_addr      ,
    input  var logic        up_wr_req       ,
    input  var logic [ 3:0] up_wr_be        ,
    input  var logic [31:0] up_wr_data      ,
    output var logic        up_wr_ack       ,
    //
    input  var logic [ 9:0] up_rd_addr      ,
    input  var logic        up_rd_req       ,
    output var logic [31:0] up_rd_data      ,
    output var logic        up_rd_ack       ,
    // Core Ports
    //------------
    input  var logic        clk             ,
    input  var logic        rst             ,
    //
    output var logic        ctrl_soft_reset ,
    //
    output var logic [ 3:0] ctrl_ext_mux_en ,
    output var logic        ctrl_rst_pd_n   ,
    //
    output var logic [31:0] ctrl_spi_txdata ,
    output var logic [ 1:0] ctrl_spi_txbyte ,
    output var logic        ctrl_spi_txvalid,
    //
    input  var logic [31:0] ctrl_spi_rxdata
);

    // Write
    //=======

    var logic ctrl_soft_reset_int;

    var logic ctrl_spi_txvalid_int;

    // ctrl_soft_reset_int on reg[0] on address = 0
    always_ff @ (posedge up_clk) begin
        if (!up_rstn) begin
            ctrl_soft_reset_int <= 'd0;
        end else if (up_wr_req && up_wr_addr == 'd1 && up_wr_be[0]) begin
            ctrl_soft_reset_int <= up_wr_data[0];
        end
    end

    always_ff @ (posedge up_clk) begin
        if (!up_rstn) begin
            ctrl_ext_mux_en <= 'd0;
        end else if (up_wr_req && up_wr_addr == 'd2 && up_wr_be[0]) begin
            ctrl_ext_mux_en <= up_wr_data[3:0];
        end
    end

    always_ff @ (posedge up_clk) begin
        if (!up_rstn) begin
            ctrl_rst_pd_n <= 1'b1;
        end else if (up_wr_req && up_wr_addr == 'd3 && up_wr_be[0]) begin
            ctrl_rst_pd_n <= up_wr_data[0];
        end
    end

    always_ff @ (posedge up_clk) begin
        if (!up_rstn) begin
            ctrl_spi_txbyte <= 2'b11;
        end else if (up_wr_req && up_wr_addr == 'd4 && up_wr_be[0]) begin
            ctrl_spi_txbyte <= up_wr_data[0];
        end
    end

    always_ff @ (posedge up_clk) begin
        if (!up_rstn) begin
            ctrl_spi_txdata <= 32'd0;
        end else begin
            if (up_wr_req && up_wr_addr == 'd5 && up_wr_be[0]) begin
                ctrl_spi_txdata[7:0] <= up_wr_data[7:0];
            end
            if (up_wr_req && up_wr_addr == 'd5 && up_wr_be[1]) begin
                ctrl_spi_txdata[15:8] <= up_wr_data[15:8];
            end
            if (up_wr_req && up_wr_addr == 'd5 && up_wr_be[2]) begin
                ctrl_spi_txdata[23:16] <= up_wr_data[23:16];
            end
            if (up_wr_req && up_wr_addr == 'd5 && up_wr_be[3]) begin
                ctrl_spi_txdata[31:24] <= up_wr_data[31:24];
            end
        end
    end

    always_ff @ (posedge up_clk) begin
        if (!up_rstn) begin
            ctrl_spi_txvalid_int <= 1'b0;
        end else begin
            ctrl_spi_txvalid_int <= (up_wr_req && up_wr_addr == 'd5);
        end
    end

    // CDC
    //-----
    xpm_cdc_array_single #(
        .DEST_SYNC_FF  (2),
        .INIT_SYNC_FF  (1),
        .SIM_ASSERT_CHK(1),
        .SRC_INPUT_REG (0),
        .WIDTH         (1)
    ) i_cdc_soft_reset (
        .src_clk (1'b0               ),
        .src_in  (ctrl_soft_reset_int),
        .dest_clk(clk                ),
        .dest_out(ctrl_soft_reset    )
    );

    xpm_cdc_pulse #(
        .DEST_SYNC_FF  (2),
        .INIT_SYNC_FF  (1),
        .REG_OUTPUT    (1),
        .RST_USED      (0),
        .SIM_ASSERT_CHK(1)
    ) i_cdc_ctrl_spi_txvalid (
        .dest_pulse(ctrl_spi_txvalid    ),
        .dest_clk  (clk                 ),
        .dest_rst  (1'b0                ),
        .src_clk   (up_clk              ),
        .src_pulse (ctrl_spi_txvalid_int),
        .src_rst   (1'b0                )
    );

    // Read
    //======

    // Read decode
    always_ff @ (posedge up_clk) begin
        if (!up_rstn) begin
            up_rd_data <= 32'd0;
        end else if (up_rd_req) begin
            // Address decode
            case (up_rd_addr)
                'd0    : up_rd_data <= C_VERSION;
                'd1    : up_rd_data <= {32'd0, ctrl_soft_reset_int};
                'd2    : up_rd_data <= {28'd0, ctrl_ext_mux_en};
                'd3    : up_rd_data <= {31'd0, ctrl_rst_pd_n};
                'd4    : up_rd_data <= {30'd0, ctrl_spi_txbyte};
                'd5    : up_rd_data <= ctrl_spi_txdata;
                'd6    : up_rd_data <= ctrl_spi_rxdata;
                default: up_rd_data <= 32'hDEADBEEF;
            endcase
        end
    end

    always_ff @ (posedge up_clk) begin
        if (!up_rstn) begin
            up_rd_ack  <= 1'b0;
        end else begin
            up_rd_ack <= up_rd_req;
        end
    end

endmodule

`default_nettype wire
