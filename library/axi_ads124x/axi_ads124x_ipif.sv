/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module axi_ads124x_ipif (
    // AXI4-Lite Slave
    //=================
    input  wire        aclk         ,
    input  wire        aresetn      ,
    //
    input  wire [31:0] s_axi_awaddr ,
    input  wire [ 2:0] s_axi_awprot ,
    input  wire        s_axi_awvalid,
    output reg         s_axi_awready,
    //
    input  wire [31:0] s_axi_wdata  ,
    input  wire [ 3:0] s_axi_wstrb  ,
    input  wire        s_axi_wvalid ,
    output reg         s_axi_wready ,
    //
    output wire [ 1:0] s_axi_bresp  ,
    output wire        s_axi_bvalid ,
    input  wire        s_axi_bready ,
    //
    input  wire [31:0] s_axi_araddr ,
    input  wire [ 2:0] s_axi_arprot ,
    input  wire        s_axi_arvalid,
    output wire        s_axi_arready,
    //
    output wire [31:0] s_axi_rdata  ,
    output wire [ 1:0] s_axi_rresp  ,
    output wire        s_axi_rvalid ,
    input  wire        s_axi_rready ,
    // IP interface
    //==============
    // Register VER
    input  wire [31:0] ver_version,
    // Register CTRL
    output wire        ctrl_opmode ,
    output wire        ctrl_start  ,
    output wire        ctrl_reset  ,
    // Register STAT
    input  wire        stat_drdy   ,
    // Register SPIWR
    output wire [31:0] spisd_data  ,
    // Register SPIWC
    output wire [ 1:0] spisc_nbytes,
    // Register SPIRD
    input  wire [31:0] spird_strb
);


    // Write State Machine
    //---------------------

    typedef enum { 
        WRRST,  // in reset
        WRIDLE, // idle, waiting for both write address and write data
        WRDATA, // write data is provided, waiting for write address
        WRADDR  // write address is provided, waiting for write data
    } WRSTATE_T;

    WRSTATE_T wr_state, wr_state_next;

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            wr_state <= WRRST;
        end else begin
            wr_state <= wr_state_next;
        end
    end 

    always_comb begin
        case(wr_state) 
            WRRST  : wr_state_next = WRIDLE;
            WRIDLE : wr_state_next = (s_axi_awvalid && !s_axi_wvalid) ? WRADDR :
                                     (!s_axi_awvalid && s_axi_wvalid) ? WRDATA : WRIDLE;
            WRADDR : wr_state_next = s_axi_wvalid  ? WRIDLE : WRADDR;
            WRDATA : wr_state_next = s_axi_awvalid ? WRIDLE : WRDATA;
            default: wr_state_next = WRRST;
        endcase
    end

    // Write Address Channel
    //-----------------------

    reg  [31:0] awaddr;
    wire [31:0] awaddr_s;

    // We are waiting for both write address and write data, but only write 
    // address is provided. Register it for later use.
    always_ff @ (posedge aclk) begin
        if (wr_state == WRIDLE && s_axi_awvalid && !s_axi_wvalid) begin
            awaddr <= s_axi_awaddr;
        end
    end

    // Slave can accept write address if idle, or if only write data is 
    // provided.
    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            s_axi_awready <= 1'b0;
        end else if (wr_state_next == WRIDLE || wr_state_next == WRDATA) begin
            s_axi_awready <= 1'b1;
        end 
    end

    // In state WRADDR, we had registered write address, use it instead of
    // `s_axi_awaddr` on bus (it may already changed by master).
    assign awaddr_s = (wr_state == WRADDR) ? awaddr : s_axi_awaddr;

    // Write Data Channel
    //--------------------

    reg  [31:0] wdata;
    wire [31:0] wdata_s;
    reg  [ 3:0] wstrb;

    // We are waiting for both write address and write data, but only write
    // data is provided. Register it for later use.
    always_ff @ (posedge aclk) begin
        if (wr_state == WRIDLE && !s_axi_awvalid && s_axi_wvalid) begin
            wdata <= s_axi_wdata;
            wstrb <= s_axi_wstrb;
        end
    end

    // Slave can accpet write data if idle, or if only write address is 
    // provided.
    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            s_axi_wready <= 1'b0;
        end else if (wr_state_next == WRIDLE || wr_state_next == WRADDR) begin
            s_axi_wready <= 1'b1;
        end
    end

    // In state WRDATA, we had registered write data, use it instead of
    // `s_axi_wdata` on bus (it may already changed by master).
    assign wdata_s = (wr_state == WRDATA) ? wdata : s_axi_wdata;

    // Write Decoding
    //----------------


endmodule : axi_ads124x_ipif

`default_nettype wire
