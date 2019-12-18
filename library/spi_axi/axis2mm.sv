/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module axis2mm (
    input  wire        aclk         ,
    input  wire        aresetn      ,
    // RX
    input  wire [ 7:0] s_axis_tdata ,
    input  wire        s_axis_tvalid,
    output wire        s_axis_tready,
    // TX
    output wire [ 7:0] m_axis_tdata ,
    output wire        m_axis_tvalid,
    input  wire        m_axis_tready,
    /* AXI */
    output wire [31:0] m_axi_awaddr ,
    output wire [ 2:0] m_axi_awprot ,
    output wire        m_axi_awvalid,
    input  wire        m_axi_awready,
    //
    output wire [31:0] m_axi_wdata  ,
    output wire [ 3:0] m_axi_wstrb  ,
    output wire        m_axi_wvalid ,
    input  wire        m_axi_wready ,
    //
    input  wire [ 1:0] m_axi_bresp  ,
    input  wire        m_axi_bvalid ,
    output wire        m_axi_bready ,
    //
    output wire [31:0] m_axi_araddr ,
    output wire [ 2:0] m_axi_arprot ,
    output wire        m_axi_arvalid,
    input  wire        m_axi_arready,
    //
    input  wire [31:0] m_axi_rdata  ,
    input  wire [ 1:0] m_axi_rresp  ,
    input  wire        m_axi_rvalid ,
    output wire        m_axi_rready
);

    // AXIS Slave
    //============

    logic s_tready;

    // RX AXIS is always ready
    always_ff @ (posedge aclk)
        if (~aresetn)
            s_tready <= 1'b0;
        else
            s_tready <= 1'b1;

    assign s_axis_tready = s_tready;

    // State Machine
    //===============

    wire rx_trans;

    assign rx_trans = s_tready && s_axis_tvalid;

    typedef enum {IDLE, RADDR0, RADDR1, RDATA0, RDATA1, RDATA2, RDATA3,
       WADDR0, WADDR1, WDATA0, WDATA1, WDATA2, WDATA3} STATE_T;

    localparam [7:0] CMD_NOP   = 8'h00;
    localparam [7:0] CMD_READ  = 8'h01;
    localparam [7:0] CMD_WRITE = 8'h02;

    STATE_T state, next_state;

    always_ff @ (posedge aclk)
        if (~aresetn)
            state <= IDLE;
        else
            state <= next_state;

    always_comb
        case(state)
            IDLE: next_state = ~rx_trans                 ? IDLE   :
                               s_axis_tdata == CMD_NOP   ? IDLE   :
                               s_axis_tdata == CMD_READ  ? RADDR0 :
                               s_axis_tdata == CMD_WRITE ? WADDR0 : IDLE;
            RADDR0: next_state = ~rx_trans ? RADDR0 : RADDR1;
            RADDR1: next_state = ~rx_trans ? RADDR1 : RDATA0;
            RDATA0: next_state = ~rx_trans ? RDATA0 : RDATA1;
            RDATA1: next_state = ~rx_trans ? RDATA1 : RDATA2;
            RDATA2: next_state = ~rx_trans ? RDATA2 : RDATA3;
            RDATA3: next_state = ~rx_trans ? RDATA3 : IDLE;
            WADDR0: next_state = ~rx_trans ? WADDR0 : WADDR1;
            WADDR1: next_state = ~rx_trans ? WADDR1 : WDATA0;
            WDATA0: next_state = ~rx_trans ? WDATA0 : WDATA1;
            WDATA1: next_state = ~rx_trans ? WDATA1 : WDATA2;
            WDATA2: next_state = ~rx_trans ? WDATA2 : WDATA3;
            WDATA3: next_state = ~rx_trans ? WDATA3 : IDLE;
            default: next_state = IDLE;
        endcase

    logic [15:0] read_address;
    logic [31:0] read_data;
    logic        read_data_valid;

    logic [15:0] write_address;
    logic [31:0] write_data;

    always_ff @ (posedge aclk) begin
        if (state == WADDR0 && s_axis_tvalid) write_address[7:0]  <= s_axis_tdata;
        if (state == WADDR1 && s_axis_tvalid) write_address[15:8] <= s_axis_tdata;
        if (state == WDATA0 && s_axis_tvalid) write_data[7:0]     <= s_axis_tdata;
        if (state == WDATA1 && s_axis_tvalid) write_data[15:8]    <= s_axis_tdata;
        if (state == WDATA2 && s_axis_tvalid) write_data[23:16]   <= s_axis_tdata;
        if (state == WDATA3 && s_axis_tvalid) write_data[31:24]   <= s_axis_tdata;

        if (state == RADDR0 && s_axis_tvalid) read_address[7:0]  <= s_axis_tdata;
        if (state == RADDR1 && s_axis_tvalid) read_address[15:8] <= s_axis_tdata;
    end

    logic start_axi_write, start_axi_read;

    always_ff @ (posedge aclk)
        start_axi_write <= ((state == WDATA3) && s_axis_tvalid);

    always_ff @ (posedge aclk)
        start_axi_read <= ((state == RADDR1) && s_axis_tvalid);


    // AXI4 Lite
    //===========
    
    // s_axis_tdata  -> write_address    -> awaddr
    // s_axis_tvalid -> write_data       -> awvalid
    // s_axis_tready -> start_axi_write  -> wdata
    //                                   -> wstrb
    //                                   -> wvalid
    //                                   -> bready

    // Write Address Channel
    //----------------------

    logic [31:0] awaddr;
    logic        awvalid;

    always_ff @ (posedge aclk)
        if (~aresetn) begin
            awaddr <= 'b0;
            awvalid <= 'b0;
        end else if (start_axi_write) begin
            awaddr <= {16'b0, write_address};
            awvalid <= 'b1;
        end else if (awvalid && m_axi_awready) begin
            awaddr <= 'b0;
            awvalid <= 'b0;
        end

    assign m_axi_awaddr = awaddr;
    assign m_axi_awprot = 3'b000; // Access permission not supported
    assign m_axi_awvalid = awvalid;

    // Write Data Channel
    //-------------------

    logic [31:0] wdata;
    logic [ 3:0] wstrb;
    logic        wvalid;

    always_ff @ (posedge aclk)
        if (~aresetn) begin
            wdata <= 'b0;
            wstrb <= 'b0;
            wvalid <= 'b0;
        end else if (start_axi_write) begin
            wdata <= write_data;
            wstrb <= 4'b1111;
            wvalid <= 'b1;
        end else if (wvalid && m_axi_wready) begin
            wdata <= 'b0;
            wstrb <= 'b0;
            wvalid <= 'b0;
        end


    assign m_axi_wdata = wdata;
    assign m_axi_wstrb = wstrb; // Always write full 32-bit data
    assign m_axi_wvalid = wvalid;

    // Write Response Channel
    //------------------------

    logic bready;

    always_ff @ (posedge aclk) begin
        if (~aresetn) begin
            bready <= 1'b0;
        end else if (start_axi_write) begin
            bready <= 1'b1;
        end else if (bready && m_axi_bvalid) begin
            bready <= 'b0;
        end
    end

    assign m_axi_bready = bready;


    // s_axis_tdata  -> read_address    -> araddr
    // s_axis_tvalid -> read_data       -> arvalid
    // s_axis_tready -> start_axi_read  -> rready

    // Read Address Channel
    //---------------------

    logic [31:0] araddr;
    logic        arvalid;

    always_ff @ (posedge aclk) begin
        if (~aresetn) begin
            araddr <= 'd0;
            arvalid <= 'd0;
        end else if (start_axi_read) begin
            araddr <={16'b0, read_address};
            arvalid <= 'b1;
        end else if (arvalid && m_axi_arready) begin
            araddr <= 'd0;
            arvalid <= 'd0;
        end
    end

    assign m_axi_araddr = araddr;
    assign m_axi_arprot = 3'b000; // Access permission not supported
    assign m_axi_arvalid = arvalid;

    // Read Data Channel
    //------------------

    logic rready;

    always_ff @ (posedge aclk) begin
        if (~aresetn) begin
            rready <= 'd0;
        end else if (start_axi_read) begin
            rready <= 'b1;
        end else if (rready && m_axi_rvalid) begin
            rready <= 'd0;
        end
    end

    assign m_axi_rready = rready;

    always_ff @ (posedge aclk)
        if (rready && m_axi_rvalid)
            read_data <=  m_axi_rdata;

    always_ff @ (posedge aclk)
        read_data_valid <= (rready && m_axi_rvalid);

    // TX AXIS
    //===========
    
    logic [2:0] tx_cnt_r;
    logic [7:0] tx_data_r;
    logic       tx_valid_r;
    
    always_ff @ (posedge aclk)
        if (~aresetn) begin
            tx_cnt_r <= 'hF;
            tx_data_r <= 'b0;
            tx_valid_r <= 1'b0;
        end else if (read_data_valid) begin
            tx_cnt_r <= 0;
            tx_data_r <= read_data[7:0];
            tx_valid_r <= 1'b1;
        end else if (tx_valid_r && m_axis_tready) begin
            tx_cnt_r <= (tx_cnt_r < 3) ? tx_cnt_r + 1 : 'hF;
            if (tx_cnt_r == 0)
                tx_data_r <= read_data[15:8];
            else if (tx_cnt_r == 1)
                tx_data_r <= read_data[23:16];
            else if (tx_cnt_r == 2)
                tx_data_r <= read_data[31:24];
            else
                tx_data_r <= 'b0;
            tx_valid_r <= (tx_cnt_r < 3) ? 1'b1 : 1'b0;
        end
    
    assign m_axis_tdata = tx_data_r;
    assign m_axis_tvalid = tx_valid_r;

endmodule
