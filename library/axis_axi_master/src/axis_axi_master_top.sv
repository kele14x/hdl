/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module axis_axi_master_top (
    // Clock & Reset
    //==============
    input  wire        aclk             ,
    input  wire        aresetn          ,
    // AXI4-Stream
    //============
    input  wire [ 7:0] s_axis_tdata     ,
    input  wire        s_axis_tvalid    ,
    output reg         s_axis_tready    ,
    //
    output reg  [ 7:0] m_axis_tdata     ,
    output reg         m_axis_tvalid    ,
    input  wire        m_axis_tready    ,
    // AXI4-Lite
    //==========
    output reg  [31:0] m_axi_awaddr     ,
    output wire [ 2:0] m_axi_awprot     ,
    output reg         m_axi_awvalid    ,
    input  wire        m_axi_awready    ,
    //
    output reg  [31:0] m_axi_wdata      ,
    output wire [ 3:0] m_axi_wstrb      ,
    output reg         m_axi_wvalid     ,
    input  wire        m_axi_wready     ,
    //
    input  wire [ 1:0] m_axi_bresp      ,
    input  wire        m_axi_bvalid     ,
    output reg         m_axi_bready     ,
    //
    output reg  [31:0] m_axi_araddr     ,
    output wire [ 2:0] m_axi_arprot     ,
    output reg         m_axi_arvalid    ,
    input  wire        m_axi_arready    ,
    //
    input  wire [31:0] m_axi_rdata      ,
    input  wire [ 1:0] m_axi_rresp      ,
    input  wire        m_axi_rvalid     ,
    output reg         m_axi_rready     ,
    // Status
    //========
    output reg         err_saxis_timeout,
    //
    output reg         err_maxis_timeout,
    output reg         err_maxis_overrun,
    //
    output reg         err_axi_awoverrun,
    output reg         err_axi_woverrun ,
    output reg         err_axi_bresperr ,
    output reg         err_axi_aroverrun,
    output reg         err_axi_rresperr
);


    localparam C_OP_RD = 1'b0;
    localparam C_OP_WR = 1'b1;

    localparam C_AXI_RESP_OKAY   = 2'b00;
    localparam C_AXI_RESP_EXOKAY = 2'b01;
    localparam C_AXI_RESP_SLVERR = 2'b10;
    localparam C_AXI_RESP_DECERR = 2'b11;

    // Slave AXIS State Machine
    // This state machine tracks what is inputed to the S_AXIS_* interface.
    // The data bytes should be like:
    //      |      Byte 0     |  Byte 1 |   Byte 2  |   Byte 3  |  Byte 4  |  Byte 5 |
    //      | WR/N | A14 ~ A8 | A7 ~ A0 | D31 ~ D24 | D23 ~ D16 | D15 ~ D8 | D7 ~ D0 |
    //

    typedef enum {
        S_SAXIS_RST,    // Under reset/fault recovery
        S_SAXIS_WRN_A0, // Waiting for WR/N and Address 0
        S_SAXIS_A1,     // Waiting for address 1
        S_SAXIS_DUMMY,  // This byte is ignored 
        S_SAXIS_D0,     // Waiting for data 0
        S_SAXIS_D1,     // Waiting for data 1
        S_SAXIS_D2,     // Waiting for data 2
        S_SAXIS_D3      // Waiting for data 3
    } SAXIS_STATE_T;

    SAXIS_STATE_T saxis_state, saxis_state_next;

    reg [9:0] saxis_state_timeout;

    wire saxis_state_busy;

    // Master AXIS state Machine
    // This state machine tries to output 4 bytes read data to M_AXIS_* interface.

    typedef enum {
        S_MAXIS_RST,   // Under reset/fault recovery
        S_MAXIS_IDLE,  // Idle, nothing to output
        S_MAXIS_BYTE0, // Output byte 0
        S_MAXIS_BYTE1, // Output byte 1
        S_MAXIS_BYTE2, // Output byte 2
        S_MAXIS_BYTE3  // Output byte 3
    } MAXIS_STATE_T;

    MAXIS_STATE_T maxis_state, maxis_state_next;

    reg [8:0] maxis_state_timeout;

    wire maxis_state_busy;

    //

    reg        axi_wrn;
    reg [14:0] axi_addr;

    reg [31:0] axi_wr_data;
    reg        axi_wr_en;

    reg [31:0] axi_rd_data;
    reg        axi_rd_en;
    reg        axi_rd_ack;


    // SAXIS State Machine
    //====================

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            saxis_state <= S_SAXIS_RST;
        end else begin
            saxis_state <= saxis_state_next;
        end
    end

    always_comb begin
        case (saxis_state)
            S_SAXIS_RST    : saxis_state_next = S_SAXIS_WRN_A0;
            //
            S_SAXIS_WRN_A0 : saxis_state_next = s_axis_tvalid ? S_SAXIS_A1     : S_SAXIS_WRN_A0;
            S_SAXIS_A1     : saxis_state_next = s_axis_tvalid ? S_SAXIS_DUMMY  :
                                       saxis_state_timeout[9] ? S_SAXIS_WRN_A0 : S_SAXIS_A1;
            //
            S_SAXIS_DUMMY  : saxis_state_next = s_axis_tvalid ? S_SAXIS_D0 :
                                       saxis_state_timeout[9] ? S_SAXIS_WRN_A0 : S_SAXIS_DUMMY;
            //
            S_SAXIS_D0     : saxis_state_next = s_axis_tvalid ? S_SAXIS_D1     :
                                       saxis_state_timeout[9] ? S_SAXIS_WRN_A0 : S_SAXIS_D0;
            S_SAXIS_D1     : saxis_state_next = s_axis_tvalid ? S_SAXIS_D2     :
                                       saxis_state_timeout[9] ? S_SAXIS_WRN_A0 : S_SAXIS_D1;
            S_SAXIS_D2     : saxis_state_next = s_axis_tvalid ? S_SAXIS_D3     :
                                       saxis_state_timeout[9] ? S_SAXIS_WRN_A0 : S_SAXIS_D2;
            S_SAXIS_D3     : saxis_state_next = s_axis_tvalid ? S_SAXIS_WRN_A0 :
                                       saxis_state_timeout[9] ? S_SAXIS_WRN_A0 : S_SAXIS_D3;
            //
            default   : saxis_state_next = S_SAXIS_RST;
        endcase
    end

    assign saxis_state_busy = saxis_state_next == S_SAXIS_A1 ||
        saxis_state_next == S_SAXIS_DUMMY || 
        saxis_state_next == S_SAXIS_D0 || saxis_state_next == S_SAXIS_D1 ||
        saxis_state_next == S_SAXIS_D2 || saxis_state_next == S_SAXIS_D3;

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            saxis_state_timeout <= 'd0;
        end else if (s_axis_tvalid) begin
            saxis_state_timeout <= 'd0;
        end else if (saxis_state_busy) begin
            saxis_state_timeout <= saxis_state_timeout == 10'h200 ? 10'h200 : saxis_state_timeout + 1;
        end else begin // Other states
            saxis_state_timeout <= 'd0;
        end
    end


    // Slave AXIS
    //------------

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            s_axis_tready <= 1'b0;
        end else begin
            s_axis_tready <= ((saxis_state_next == S_SAXIS_WRN_A0) || saxis_state_busy);
        end
    end

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            err_saxis_timeout <= 1'b0;
        end else begin
            err_saxis_timeout <= (saxis_state_timeout[9] && !s_axis_tvalid);
        end
    end

    // Master AXIS State Machine
    //==========================

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            maxis_state <= S_MAXIS_RST;
        end else begin
            maxis_state <= maxis_state_next;
        end
    end

    always_comb begin
        case (maxis_state)
            S_MAXIS_RST   : maxis_state_next = S_MAXIS_IDLE;
            S_MAXIS_IDLE  : maxis_state_next = axi_rd_ack    ? S_MAXIS_BYTE0 : S_MAXIS_IDLE;
            S_MAXIS_BYTE0 : maxis_state_next = m_axis_tready ? S_MAXIS_BYTE1 : 
                                      maxis_state_timeout[8] ? S_MAXIS_IDLE  : S_MAXIS_BYTE0;
            S_MAXIS_BYTE1 : maxis_state_next = m_axis_tready ? S_MAXIS_BYTE2 : 
                                      maxis_state_timeout[8] ? S_MAXIS_IDLE  : S_MAXIS_BYTE1;
            S_MAXIS_BYTE2 : maxis_state_next = m_axis_tready ? S_MAXIS_BYTE3 : 
                                      maxis_state_timeout[8] ? S_MAXIS_IDLE  : S_MAXIS_BYTE2;
            S_MAXIS_BYTE3 : maxis_state_next = m_axis_tready ? S_MAXIS_IDLE  : 
                                      maxis_state_timeout[8] ? S_MAXIS_IDLE  : S_MAXIS_BYTE3;
            default : maxis_state_next = S_MAXIS_RST;
        endcase
    end

    assign maxis_state_busy = (maxis_state_next == S_MAXIS_BYTE0 || maxis_state_next == S_MAXIS_BYTE1 ||
        maxis_state_next == S_MAXIS_BYTE2 || maxis_state_next == S_MAXIS_BYTE3);

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            err_maxis_overrun <= 1'b0;
        end else begin
            err_maxis_overrun <= (axi_rd_ack && (maxis_state != S_MAXIS_IDLE));
        end
    end

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            maxis_state_timeout <= 'd0;
        end else if (m_axis_tready) begin
            maxis_state_timeout <= 'd0;
        end else if (maxis_state_busy) begin
            maxis_state_timeout <= maxis_state_timeout == 9'h100 ? 9'h100 : maxis_state_timeout + 1;
        end else begin // Other state
            maxis_state_timeout <= 'd0;
        end
    end

    // Master AXIS
    //------------

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            m_axis_tdata <= 'd0;
        end else if (maxis_state_next == S_MAXIS_BYTE0) begin
            m_axis_tdata <= axi_rd_data[31:24];
        end else if (maxis_state_next == S_MAXIS_BYTE1) begin
            m_axis_tdata <= axi_rd_data[23:16];
        end else if (maxis_state_next == S_MAXIS_BYTE2) begin
            m_axis_tdata <= axi_rd_data[15:8];
        end else if (maxis_state_next == S_MAXIS_BYTE3) begin
            m_axis_tdata <= axi_rd_data[7:0];
        end else begin
            m_axis_tdata <= 'd0;
        end
    end

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            m_axis_tvalid <= 1'b0;
        end else if (maxis_state_busy) begin
            m_axis_tvalid <= 1'b1;
        end else begin
            m_axis_tvalid <= 1'b0;
        end
    end

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            err_maxis_timeout <= 1'b0;
        end else begin
            err_maxis_timeout <= (maxis_state_timeout[8] && !m_axis_tready);
        end
    end 


    // axi_* registers
    //================

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            axi_wrn <= 1'b0;
        end else if (saxis_state == S_SAXIS_WRN_A0 && s_axis_tvalid) begin
            axi_wrn <= s_axis_tdata[7];
        end
    end

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            axi_addr <= 'd0;
        end else begin
            if (saxis_state == S_SAXIS_WRN_A0 && s_axis_tvalid) begin
                axi_addr[14:8] <= s_axis_tdata[6:0];
            end
            if (saxis_state == S_SAXIS_A1 && s_axis_tvalid) begin
                axi_addr[7:0] <= s_axis_tdata;
            end
        end
    end

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            axi_rd_en <= 1'b0;
        end else begin
            axi_rd_en <= (saxis_state == S_SAXIS_A1 && s_axis_tvalid && (axi_wrn == C_OP_RD));
        end
    end

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            axi_wr_en <= 1'b0;
        end else begin
            axi_wr_en <= (saxis_state == S_SAXIS_D3 && s_axis_tvalid && (axi_wrn == C_OP_WR));
        end
    end

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            axi_wr_data <= 'd0;
        end else begin
            if (saxis_state == S_SAXIS_D0 && s_axis_tvalid && (axi_wrn == C_OP_WR)) begin
                axi_wr_data[31:24] <= s_axis_tdata;
            end
            if (saxis_state == S_SAXIS_D1 && s_axis_tvalid && (axi_wrn == C_OP_WR)) begin
                axi_wr_data[23:16] <= s_axis_tdata;
            end
            if (saxis_state == S_SAXIS_D2 && s_axis_tvalid && (axi_wrn == C_OP_WR)) begin
                axi_wr_data[15:8] <= s_axis_tdata;
            end
            if (saxis_state == S_SAXIS_D3 && s_axis_tvalid && (axi_wrn == C_OP_WR)) begin
                axi_wr_data[7:0] <= s_axis_tdata;
            end
        end
    end


    // AXI Master
    //===========

    // Write Address Channel
    //----------------------

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            m_axi_awaddr <= 32'h00000000;
        end else if (axi_wr_en && !(m_axi_awvalid && !m_axi_awready)) begin
            m_axi_awaddr <= {15'd0, axi_addr, 2'd0};
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
            err_axi_awoverrun <= 1'b0;
        end else begin
            err_axi_awoverrun <= axi_wr_en && (m_axi_awvalid && !m_axi_awready);
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
            err_axi_woverrun <= 1'b0;
        end else begin
            err_axi_woverrun <= axi_wr_en && (m_axi_awvalid && !m_axi_awready);
        end
    end

    // Write Response Channel
    //------------------------

    // Always be ready
    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            m_axi_bready <= 1'b0;
        end else begin
            m_axi_bready <= 1'b1;
        end
    end

    // Indicate previous write transaction is not successful
    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            err_axi_bresperr <= 1'b0;
        end else begin
            err_axi_bresperr <= m_axi_bvalid &&
                (m_axi_bresp == C_AXI_RESP_SLVERR ||
                 m_axi_bresp == C_AXI_RESP_DECERR);
        end
    end

    // Read Address Channel
    //---------------------

    // m_axi_araddr
    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            m_axi_araddr <= 32'd0;
        end else if (axi_rd_en && !(m_axi_arvalid && !m_axi_arready)) begin
            m_axi_araddr <= {15'd0, axi_addr, 2'd0};
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
            err_axi_aroverrun <= 1'b0;
        end else begin
            err_axi_aroverrun <= axi_rd_en && (m_axi_arvalid && !m_axi_arready);
        end
    end

    // Read Data Channel
    //------------------

    // Always be ready
    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            m_axi_rready <= 1'b0;
        end else begin
            m_axi_rready <= 1'b1;
        end
    end

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            axi_rd_data <= 32'hDEADBEEF;
        end else if (m_axi_rvalid) begin
            axi_rd_data <= (m_axi_rresp == C_AXI_RESP_OKAY ||
                m_axi_rresp == C_AXI_RESP_EXOKAY) ? m_axi_rdata : 32'hDEADBEEF;
        end
    end

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            axi_rd_ack <= 1'b0;
        end else begin
            axi_rd_ack <= m_axi_rvalid;
        end
    end

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            err_axi_rresperr <= 1'b0;
        end else begin
            err_axi_rresperr <= m_axi_rvalid &&
                (m_axi_rresp == C_AXI_RESP_SLVERR ||
                 m_axi_rresp == C_AXI_RESP_DECERR);
        end
    end

endmodule

`default_nettype wire
