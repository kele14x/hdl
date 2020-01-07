/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module spi_axi_ctrl (
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
    // SPI
    //=====
    input  wire        spi_rx_ss         ,
    input  wire [15:0] spi_rx_data       ,
    input  wire [ 3:0] spi_rx_bitcnt     ,
    input  wire        spi_rx_valid      ,
    //
    output wire [15:0] spi_tx_data       ,
    input  wire        spi_tx_load       ,
    // Status
    //========
    output reg         stat_axi_awoverrun,
    output reg         stat_axi_woverrun ,
    output reg         stat_axi_bresperr ,
    output reg         stat_axi_aroverrun,
    output reg         stat_axi_rresperr
);

    localparam C_OP_RD = 1'b0;
    localparam C_OP_WR = 1'b1;

    reg [3:0] mode_r;
    reg [3:0] addr_r0;
    reg [7:0] addr_r1;
    reg [7:0] data_temp0, data_temp1, data_temp2;

    typedef enum {
        S_RST, S_IDLE, S_RD_WAIT, S_RD_HIGH, S_RD_LOW, S_WR_HIGH, S_WR_LOW
    } STATE_T;

    STATE_T state, state_next;

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            state <= S_RST;
        end else begin
            state <= state_next;
        end
    end

    always_comb begin
        case (state)
            S_RST     : state_next = S_IDLE;
            S_IDLE    : state_next = spi_rx_ss ? S_IDLE :
                (spi_rx_valid && spi_rx_bitcnt == 13 && spi_rx_data[13] == C_OP_RD) ? S_RD_WAIT :
                (spi_rx_valid && spi_rx_bitcnt == 15) ? S_WR_HIGH : S_IDLE;
            S_RD_WAIT : state_next = spi_rx_ss ? S_IDLE :
                (spi_rx_valid && spi_rx_bitcnt == 15) ? S_RD_HIGH : S_RD_WAIT;
            S_RD_HIGH : state_next = spi_rx_ss ? S_IDLE :
                (spi_rx_valid && spi_rx_bitcnt == 15) ? S_RD_LOW : S_RD_HIGH;
            S_RD_LOW  : state_next = spi_rx_ss ? S_IDLE :
                (spi_rx_valid && spi_rx_bitcnt == 15) ? S_IDLE : S_RD_LOW;
            S_WR_HIGH : state_next = spi_rx_ss ? S_IDLE :
                (spi_rx_valid && spi_rx_bitcnt == 15) ? S_WR_LOW : S_WR_HIGH;
            S_WR_LOW  : state_next = spi_rx_ss ? S_IDLE :
                (spi_rx_valid && spi_rx_bitcnt == 15) ? S_IDLE : S_WR_LOW;
            default   : state_next = S_RST;
        endcase
    end

    wire        axi_wr_en;
    wire [14:0] axi_wr_addr;
    wire [31:0] axi_wr_data;

    wire        axi_rd_en;
    wire [12:0] axi_rd_addr;
    reg  [31:0] axi_rd_data;

    reg [15:0] temp0, temp1;

    always_ff @ (posedge aclk) begin
        if (state == S_IDLE && spi_rx_valid && spi_rx_bitcnt == 15) begin
            temp0 <= spi_rx_data;
        end
    end

    always_ff @ (posedge aclk) begin
        if (state == S_WR_HIGH && spi_rx_valid && spi_rx_bitcnt == 15) begin
            temp1 <= spi_rx_data;
        end
    end

    assign spi_tx_data = state == S_RD_LOW ? axi_rd_data[31:16] : axi_rd_data[15:0];

    assign axi_wr_en = state == S_WR_LOW && !spi_rx_ss && spi_rx_valid && spi_rx_bitcnt == 15;
    assign axi_wr_addr = temp0;
    assign axi_wr_data = {temp1, spi_rx_data};

    assign axi_rd_en = state == S_IDLE && !spi_rx_ss && spi_rx_valid && spi_rx_bitcnt == 13 && spi_rx_data[13] == C_OP_RD;
    assign axi_rd_addr = spi_rx_data[12:0];

    // AXI
    //============

    localparam C_AXI_RESP_OKAY   = 2'b00;
    localparam C_AXI_RESP_EXOKAY = 2'b01;
    localparam C_AXI_RESP_SLVERR = 2'b10;
    localparam C_AXI_RESP_DECERR = 2'b11;


    // Write Address Channel
    //----------------------

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            m_axi_awaddr <= 32'h00000000;
        end else if (axi_wr_en && !(m_axi_awvalid && !m_axi_awready)) begin
            m_axi_awaddr <= {17'd0, axi_wr_addr};
        end
    end

    assign m_axi_awprot  = 3'b0; // Not supported

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            m_axi_awvalid <= 1'b0;
        end else if (axi_wr_en) begin
            m_axi_awvalid <= 1'b1;
        end else if (m_axi_awready) begin
            m_axi_awvalid <= 1'b0;
        end
    end

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            stat_axi_awoverrun <= 1'b0;
        end else begin
            stat_axi_awoverrun <= axi_wr_en && (m_axi_awvalid && !m_axi_awready);
        end
    end

    // Write Data Channel
    //-------------------

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            m_axi_wdata <= 32'h00000000;
        end else if (axi_wr_en && !(m_axi_wvalid && !m_axi_wready)) begin
            m_axi_wdata <= axi_wr_data;
        end
    end

    assign m_axi_wstrb  = 4'b1111; // Always write all 4-byte

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            m_axi_wvalid <= 1'b0;
        end else if (axi_wr_en) begin
            m_axi_wvalid <= 1'b1;
        end else if (m_axi_wready) begin
            m_axi_wvalid <= 1'b0;
        end
    end

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            stat_axi_woverrun <= 1'b0;
        end else begin
            stat_axi_woverrun <= axi_wr_en && (m_axi_awvalid && !m_axi_awready);
        end
    end

    // Write Response Channel
    //------------------------

    // Indicate previous write transaction is not successful
    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            stat_axi_bresperr <= 1'b0;
        end else begin
            stat_axi_bresperr <= m_axi_bvalid &&
                (m_axi_bresp == C_AXI_RESP_SLVERR ||
                 m_axi_bresp == C_AXI_RESP_DECERR);
        end
    end

    assign m_axi_bready = 1'b1; // Always be ready

    // Read Address Channel
    //---------------------

    // m_axi_araddr
    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            m_axi_araddr <= 32'd0;
        end else if (axi_rd_en && !(m_axi_arvalid && !m_axi_arready)) begin
            m_axi_araddr <= {17'd0, axi_rd_addr, 2'd0};
        end
    end

    // m_axi_arprot
    assign m_axi_arprot = 3'd0; // Not supported

    // m_axi_arvalid
    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            m_axi_arvalid <= 1'b0;
        end else if (axi_rd_en) begin
            m_axi_arvalid <= 1'b1;
        end else if (m_axi_arready) begin
            m_axi_arvalid <= 1'b0;
        end
    end

    // Indicates SPI side want to issue a AXI read transaction, but previous
    // read transaction still struck at AXI read address channel
    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            stat_axi_aroverrun <= 1'b0;
        end else begin
            stat_axi_aroverrun <= axi_rd_en && (m_axi_arvalid && !m_axi_arready);
        end
    end

    // Read Data Channel
    //------------------

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            axi_rd_data <= 32'hDEADBEEF;
        end else if (m_axi_rvalid) begin
            axi_rd_data <= (m_axi_rresp == C_AXI_RESP_OKAY ||
                m_axi_rresp == C_AXI_RESP_EXOKAY) ? m_axi_rdata : 32'hDEADBEEF;
        end
    end

    assign m_axi_rready = 1'b1; // always be ready

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            stat_axi_rresperr <= 1'b0;
        end else begin
            stat_axi_rresperr <= m_axi_rvalid &&
                (m_axi_rresp == C_AXI_RESP_SLVERR ||
                 m_axi_rresp == C_AXI_RESP_DECERR);
        end
    end

endmodule

`default_nettype wire
