/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module spi_axi_axiff (
    // CTRL
    //=====
    input  wire [11:0] axi_wr_addr       ,
    input  wire [31:0] axi_wr_data       ,
    input  wire        axi_wr_en         ,
    // Read
    input  wire [11:0] axi_rd_addr       ,
    input  wire        axi_rd_en         ,
    output wire [31:0] axi_rd_data       ,
    // AXI
    //======
    input  wire        aclk              ,
    input  wire        aresetn           ,
    //
    output reg  [31:0] m_axi_awaddr      ,
    output wire [ 2:0] m_axi_awprot      ,
    output reg         m_axi_awvalid     ,
    input  wire        m_axi_awready     ,
    //
    output reg  [31:0] m_axi_wdata       ,
    output wire [ 3:0] m_axi_wstrb       ,
    output reg         m_axi_wvalid      ,
    input  wire        m_axi_wready      ,
    //
    input  wire [ 1:0] m_axi_bresp       ,
    input  wire        m_axi_bvalid      ,
    output wire        m_axi_bready      ,
    //
    output reg  [31:0] m_axi_araddr      ,
    output wire [ 2:0] m_axi_arprot      ,
    output reg         m_axi_arvalid     ,
    input  wire        m_axi_arready     ,
    //
    input  wire [31:0] m_axi_rdata       ,
    input  wire [ 1:0] m_axi_rresp       ,
    input  wire        m_axi_rvalid      ,
    output wire        m_axi_rready      ,
    // Status
    //========
    output reg         stat_axi_awoverrun,
    output reg         stat_axi_woverrun ,
    output reg         stat_axi_wrerror  ,
    output reg         stat_axi_aroverrun
);

    localparam C_AXI_RESP_OKAY   = 2'b00;
    localparam C_AXI_RESP_EXOKAY = 2'b01;
    localparam C_AXI_RESP_SLVERR = 2'b10;
    localparam C_AXI_RESP_DECERR = 2'b11;


    // AXI
    //============

    reg [17:0] high_addr = 18'd0;

    // Write Address Channel
    //----------------------

    wire axi_wr;

    assign axi_wr = (capture_edge && (rx_bitcnt == 4'd13) &&
         (rx_wordcnt == 4'd0) && (rx_word[13:12] == 2'b11));

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            m_axi_awaddr <= 32'h00000000;
        end else if (axi_wr && !(m_axi_awvalid && !m_axi_awready)) begin
            m_axi_awaddr <= {high_addr, rx_word[11:0], 2'b00};
        end
    end

    assign m_axi_awprot  = 3'b0; // Not supported

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            m_axi_awvalid <= 1'b0;
        end else if (axi_wr) begin
            m_axi_awvalid <= 1'b1;
        end else if (m_axi_awready) begin
            m_axi_awvalid <= 1'b0;
        end
    end

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            stat_axi_awoverrun <= 1'b0;
        end else begin
            stat_axi_awoverrun <= axi_wr && (m_axi_awvalid && !m_axi_awready);
        end
    end

    // Write Data Channel
    //-------------------

    reg [15:0] axi_wr_temp;
    wire axi_wr_dh, axi_wr_dl;

    assign axi_wr_dh = (capture_edge && (rx_bitcnt == 4'd15) &&
        (rx_wordcnt == 4'd1));
    assign axi_wr_dl = (capture_edge && (rx_bitcnt == 4'd15) &&
        (rx_wordcnt == 4'd2));

    always_ff @ (posedge aclk) begin
        if (axi_wr_dh && !(m_axi_wvalid && !m_axi_wready)) begin
            axi_wr_temp <= rx_word;
        end
    end

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            m_axi_wdata <= 32'h00000000;
        end else if (axi_wr_dl && !(m_axi_wvalid && !m_axi_wready)) begin
            m_axi_wdata <= {axi_wr_temp, rx_word};
        end
    end

    assign m_axi_wstrb  = 4'b1; // Always write all 4-byte

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            m_axi_wvalid <= 1'b0;
        end else if (axi_wr_dl) begin
            m_axi_wvalid <= 1'b1;
        end else if (m_axi_wready) begin
            m_axi_wvalid <= 1'b0;
        end
    end

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            stat_axi_woverrun <= 1'b0;
        end else begin
            stat_axi_woverrun <= axi_wr_dl && (m_axi_awvalid && !m_axi_awready);
        end
    end

    // Write Response Channel
    //------------------------

    // Indicate previous write tansaction is not successful
    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            stat_axi_wrerror <= 1'b0;
        end else begin
            stat_axi_wrerror <= m_axi_bvalid &&
                (m_axi_bresp == C_AXI_RESP_SLVERR ||
                 m_axi_bresp == C_AXI_RESP_DECERR);
        end
    end

    assign m_axi_bready = 1'b1; // Always be ready

    // Read Address Channel
    //---------------------

    wire axi_rd;

    assign axi_rd = (capture_edge && (rx_bitcnt == 4'd13) &&
        (rx_wordcnt == 4'd0) && (rx_word[13:12] == 2'b10));

    // m_axi_araddr
    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            m_axi_araddr <= 32'd0;
        end else if (axi_rd && !(m_axi_arvalid && !m_axi_arready)) begin
            m_axi_araddr <= {high_addr, rx_word[11:0], 2'b00};
        end
    end

    // m_axi_arprot
    assign m_axi_arprot = 3'd0; // Not supported

    // m_axi_arvalid
    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            m_axi_arvalid <= 1'b0;
        end else if (axi_rd) begin
            m_axi_arvalid <= 1'b1;
        end else if (m_axi_arready) begin
            m_axi_arvalid <= 1'b0;
        end
    end

    // Indicates SPI side want to issue a AXI read transaction, but previous
    // read transaction still stucks at AXI read address channel
    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            stat_axi_aroverrun <= 1'b0;
        end else begin
            stat_axi_aroverrun <= axi_rd && (m_axi_arvalid && !m_axi_arready);
        end
    end

    // Read Data Channel
    //------------------

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            axi_rdata_r <= 32'hDEADBEEF;
        end else if (m_axi_rvalid) begin
            axi_rdata_r <= (m_axi_rresp == C_AXI_RESP_OKAY ||
                m_axi_rresp == C_AXI_RESP_EXOKAY) ? m_axi_rdata : 32'hDEADBEEF;
        end
    end

    assign m_axi_rready = 1'b1; // always be ready

endmodule
