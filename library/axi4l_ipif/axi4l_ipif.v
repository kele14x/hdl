/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

// Note: AxPROT not supported (not connected)

module axi4l_ipif #(
    parameter C_ADDR_WIDTH = 12,
    parameter C_DATA_WIDTH = 32
) (
    // AXI4-Lite Slave
    //=================
    input  wire                      aclk         ,
    input  wire                      aresetn      ,
    //
    input  wire [              31:0] s_axi_awaddr ,
    input  wire [               2:0] s_axi_awprot ,
    input  wire                      s_axi_awvalid,
    output reg                       s_axi_awready,
    //
    input  wire [  C_DATA_WIDTH-1:0] s_axi_wdata  ,
    input  wire [C_DATA_WIDTH/8-1:0] s_axi_wstrb  ,
    input  wire                      s_axi_wvalid ,
    output reg                       s_axi_wready ,
    //
    output reg  [               1:0] s_axi_bresp  ,
    output reg                       s_axi_bvalid ,
    input  wire                      s_axi_bready ,
    //
    input  wire [              31:0] s_axi_araddr ,
    input  wire [               2:0] s_axi_arprot ,
    input  wire                      s_axi_arvalid,
    output reg                       s_axi_arready,
    //
    output reg  [  C_DATA_WIDTH-1:0] s_axi_rdata  ,
    output reg  [               1:0] s_axi_rresp  ,
    output reg                       s_axi_rvalid ,
    input  wire                      s_axi_rready ,
    // Write i/f
    //-----------
    output reg  [  C_ADDR_WIDTH-3:0] wr_addr      ,
    output reg                       wr_req       ,
    output reg  [               3:0] wr_be        ,
    output reg  [  C_DATA_WIDTH-1:0] wr_data      ,
    input  wire                      wr_ack       ,
    // Read i/f
    //----------
    output reg  [  C_ADDR_WIDTH-3:0] rd_addr      ,
    output reg                       rd_req       ,
    input  wire [  C_DATA_WIDTH-1:0] rd_data      ,
    input  wire                      rd_ack
);

    initial begin
        if (!(C_DATA_WIDTH == 32 || C_DATA_WIDTH == 64))
            $error();
    end

    // RRESP/BRESP
    localparam C_RESP_OKAY   = 2'b00; // OKAY, normal access success
    localparam C_RESP_EXOKAY = 2'b01; // EXOKAY, exclusive access success
    localparam C_RESP_SLVERR = 2'b10; // SLVERR, slave error
    localparam C_RESP_DECERR = 2'b11; // DECERR, decoder error


    wire wr_valid, wr_addr_valid, wr_data_valid;

    wire rd_valid;

    // Write State Machine
    //=====================

    localparam S_WRRST  = 3'd0; // in reset
    localparam S_WRIDLE = 3'd1; // idle, waiting for both write address and write data
    localparam S_WRADDR = 3'd2; // write data is provided, waiting for write address
    localparam S_WRDATA = 3'd3; // write address is provided, waiting for write data
    localparam S_WRWAIT = 3'd4; // both write data and address is provided, wait `wr_ack`
    localparam S_WRRESP = 3'd5; // `wr_ack` is assert, response to axi master

    reg [2:0] wr_state, wr_state_next;

    always @ (posedge aclk) begin
        if (!aresetn) begin
            wr_state <= S_WRRST;
        end else begin
            wr_state <= wr_state_next;
        end
    end

    always @ (*) begin
        case (wr_state)
            S_WRRST  : wr_state_next = S_WRIDLE;
            S_WRIDLE : wr_state_next = (s_axi_awvalid && s_axi_wvalid) ? S_WRWAIT :
                                        s_axi_awvalid ? S_WRADDR :
                                        s_axi_wvalid  ? S_WRDATA :
                                        S_WRIDLE;
            S_WRADDR : wr_state_next = !s_axi_wvalid  ? S_WRADDR : S_WRWAIT;
            S_WRDATA : wr_state_next = !s_axi_awvalid ? S_WRDATA : S_WRWAIT;
            S_WRWAIT : wr_state_next = !wr_ack        ? S_WRWAIT : S_WRRESP;
            S_WRRESP : wr_state_next = !s_axi_bready  ? S_WRRESP : S_WRIDLE;
            default  : wr_state_next = S_WRRST;
        endcase
    end

    assign wr_valid = ((wr_state == S_WRIDLE) && s_axi_awvalid && s_axi_wvalid) ||
        ((wr_state == S_WRADDR) && s_axi_wvalid) ||
        ((wr_state == S_WRDATA) && s_axi_awvalid);

    assign wr_addr_valid = ((wr_state == S_WRIDLE) && s_axi_awvalid) ||
        ((wr_state == S_WRDATA) && s_axi_awvalid);

    assign wr_data_valid = ((wr_state == S_WRIDLE) && s_axi_wvalid) ||
        ((wr_state == S_WRADDR) && s_axi_wvalid);


    // Write Address Channel
    //-----------------------

    // We are waiting for both write address and write data, but only write
    // address is provided. Register it for later use.
    always @ (posedge aclk) begin
        if (!aresetn) begin
            wr_addr <= 'd0;
        end else if (wr_addr_valid) begin
            wr_addr <= s_axi_awaddr[C_ADDR_WIDTH-1:2];
        end
    end

    // Slave can accept write address if idle, or if only write data is
    // provided.
    always @ (posedge aclk) begin
        if (!aresetn) begin
            s_axi_awready <= 1'b0;
        end else begin
            s_axi_awready <= (wr_state_next == S_WRIDLE || wr_state_next == S_WRDATA);
        end
    end


    // Write Data Channel
    //--------------------

    // We are waiting for both write address and write data, but only write
    // data is provided. Register it for later use.
    always @ (posedge aclk) begin
        if (!aresetn) begin
            wr_data <= 'd0;
            wr_be   <= 'd0;
        end if (wr_data_valid) begin
            wr_data <= s_axi_wdata;
            wr_be   <= s_axi_wstrb;
        end
    end

    // Slave can accpet write data if idle, or if only write address is
    // provided.
    always @ (posedge aclk) begin
        if (!aresetn) begin
            s_axi_wready <= 1'b0;
        end else begin
            s_axi_wready <= (wr_state_next == S_WRIDLE || wr_state_next == S_WRADDR);
        end
    end


    // Write response channel
    //------------------------

    always @ (posedge aclk) begin
        if (!aresetn) begin
            wr_req <= 1'b0;
        end else begin
            wr_req <= (wr_state_next == S_WRWAIT);
        end
    end

    always @ (posedge aclk) begin
        if (!aresetn) begin
            s_axi_bvalid <= 1'b0;
        end else begin
            s_axi_bvalid <= (wr_state_next == S_WRRESP);
        end
    end

    always @ (posedge aclk) begin
        if (!aresetn) begin
            s_axi_bresp <= 0;
        end else if (wr_state == S_WRWAIT && wr_ack) begin
            s_axi_bresp <= C_RESP_OKAY; // TODO: This is logic seems problem
        end
    end


    // Read State Machine
    //====================

    // Read Iteration Interval = 2 (back-to-back read transaction)
    // Read Latency = 2 (from AWADDR transaction to RDATA transaction)

    localparam S_RDRST  = 2'd0;
    localparam S_RDIDLE = 2'd1;
    localparam S_RDWAIT = 2'd2;
    localparam S_RDRESP = 2'd3;

    reg [1:0] rd_state, rd_state_next;

    always @ (posedge aclk) begin
        if (!aresetn) begin
            rd_state <= S_RDRST;
        end else begin
            rd_state <= rd_state_next;
        end
    end

    always @ (*) begin
        case(rd_state)
            S_RDRST  : rd_state_next = S_RDIDLE;
            S_RDIDLE : rd_state_next = !s_axi_arvalid ? S_RDIDLE : S_RDWAIT;
            S_RDWAIT : rd_state_next = !rd_ack        ? S_RDWAIT : S_RDRESP;
            S_RDRESP : rd_state_next = !s_axi_rready  ? S_RDRESP : S_RDIDLE;
            default  : rd_state_next = S_RDRST;
        endcase
    end

    assign rd_valid = (rd_state == S_RDIDLE) && s_axi_arvalid;


    // Read Address Channel
    //----------------------

    always @ (posedge aclk) begin
        if (!aresetn) begin
            rd_addr <= 'd0;
        end else if (rd_valid) begin
            rd_addr <= s_axi_araddr[C_ADDR_WIDTH-1:3];
        end
    end

    always @ (posedge aclk) begin
        if (!aresetn) begin
            s_axi_arready <= 1'b0;
        end else begin
            s_axi_arready <= (rd_state_next == S_RDIDLE);
        end
    end

    always @ (posedge aclk) begin
        if (!aresetn) begin
            rd_req <= 1'b0;
        end else begin
            rd_req <= (rd_state_next == S_RDWAIT);
        end
    end


    // Read Data Channel
    //-------------------

    always @ (posedge aclk) begin
        if (!aresetn) begin
            s_axi_rvalid <= 1'b0;
        end else begin
            s_axi_rvalid <= (rd_state_next == S_RDRESP);
        end
    end

    always @ (posedge aclk) begin
        if (!aresetn) begin
            s_axi_rdata <= 0;
        end else if (rd_state == S_RDWAIT && rd_ack) begin
            s_axi_rdata <= rd_data;
        end
    end

    always @ (posedge aclk) begin
        if (!aresetn) begin
            s_axi_rresp <= 0;
        end else if (rd_state == S_RDWAIT && rd_ack) begin
            s_axi_rresp <= C_RESP_OKAY;
        end
    end

endmodule

`default_nettype wire
