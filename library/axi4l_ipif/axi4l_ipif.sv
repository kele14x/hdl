/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

// Note: AxPROT not supported (not connected)

module axi4l_ipif #(
    parameter C_DATA_WIDTH = 32,
    parameter [31:0] C_REG_ADDR_LIST [0:1] = {
        32'h0000_0000,
        32'h0000_0004
    }
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
    input  wire                      s_axi_rready
);

    // RRESP/BRESP
    localparam C_RESP_OKAY   = 2'b00; // OKAY, normal access success
    localparam C_RESP_EXOKAY = 2'b01; // EXOKAY, exclusive access success
    localparam C_RESP_SLVERR = 2'b10; // SLVERR, slave error
    localparam C_RESP_DECERR = 2'b11; // DECERR, decoder error

    localparam C_NUM_REGS = $size(C_REG_ADDR_LIST);

    reg [C_DATA_WIDTH-1:0] reg_array [0:C_NUM_REGS-1];


    function addr_in_range(input [31:0] addr);
        for (int i = 0; i < C_NUM_REGS; i++)
            if (addr == C_REG_ADDR_LIST[i]) return 1'b1;
        return 1'b0;
    endfunction

    function [31:0] output_mux (input [31:0] addr);
        for (int i = 0; i < C_NUM_REGS; i++)
            if (addr == C_REG_ADDR_LIST[i]) return reg_array[i];
         return 32'h00000000;
    endfunction


    // Write State Machine
    //=====================

    typedef enum {
        S_WRRST , // in reset
        S_WRIDLE, // idle, waiting for both write address and write data
        S_WRADDR, // write data is provided, waiting for write address
        S_WRDATA, // write address is provided, waiting for write data
        S_WRRESP  // both write data and address is provided
    } WRSTATE_T;

    WRSTATE_T wr_state, wr_state_next;

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            wr_state <= S_WRRST;
        end else begin
            wr_state <= wr_state_next;
        end
    end

    always_comb begin
        case (wr_state)
            S_WRRST  : wr_state_next = S_WRIDLE;
            S_WRIDLE : wr_state_next = (s_axi_awvalid && s_axi_wvalid) ? S_WRRESP :
                                        s_axi_awvalid ? S_WRADDR :
                                        s_axi_wvalid  ? S_WRDATA :
                                        S_WRIDLE;
            S_WRADDR : wr_state_next = !s_axi_wvalid  ? S_WRADDR : S_WRRESP;
            S_WRDATA : wr_state_next = !s_axi_awvalid ? S_WRDATA : S_WRRESP;
            S_WRRESP : wr_state_next = !s_axi_bready  ? S_WRRESP : S_WRIDLE;
            default  : wr_state_next = S_WRRST;
        endcase
    end

    wire wr_valid;

    assign wr_valid = ((wr_state == S_WRIDLE) && s_axi_awvalid && s_axi_wvalid) ||
        ((wr_state == S_WRADDR) && s_axi_wvalid) ||
        ((wr_state ==S_WRDATA) && s_axi_arvalid);

    // Write Address Channel
    //-----------------------

    reg  [31:0] awaddr;
    wire [31:0] awaddr_s;

    // We are waiting for both write address and write data, but only write
    // address is provided. Register it for later use.
    always_ff @ (posedge aclk) begin
        if (wr_state == S_WRIDLE && s_axi_awvalid && !s_axi_wvalid) begin
            awaddr <= s_axi_awaddr;
        end
    end

    // Slave can accept write address if idle, or if only write data is
    // provided.
    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            s_axi_awready <= 1'b0;
        end else begin
            s_axi_awready <= (wr_state_next == S_WRIDLE || wr_state_next == S_WRDATA);
        end
    end

    // In state WRADDR, we had registered write address, use it instead of
    // `s_axi_awaddr` on bus (it may already changed by master).
    assign awaddr_s = (wr_state == S_WRADDR) ? awaddr : s_axi_awaddr;


    // Write Data Channel
    //--------------------

    reg  [31:0] wdata;
    wire [31:0] wdata_s;
    reg  [ 3:0] wstrb;
    wire [ 3:0] wstrb_s;


    // We are waiting for both write address and write data, but only write
    // data is provided. Register it for later use.
    always_ff @ (posedge aclk) begin
        if (wr_state == S_WRIDLE && !s_axi_awvalid && s_axi_wvalid) begin
            wdata <= s_axi_wdata;
            wstrb <= s_axi_wstrb;
        end
    end

    // Slave can accpet write data if idle, or if only write address is
    // provided.
    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            s_axi_wready <= 1'b0;
        end else begin
            s_axi_wready <= (wr_state_next == S_WRIDLE || wr_state_next == S_WRADDR);
        end
    end

    // In state WRDATA, we had registered write data, use it instead of
    // `s_axi_wdata` on bus (it may already changed by master).
    assign wdata_s = (wr_state == S_WRDATA) ? wdata : s_axi_wdata;
    assign wstrb_s = (wr_state == S_WRDATA) ? wstrb : s_axi_wstrb;

    // Write Decoding
    //================

    generate
        for (genvar i = 0; i < C_NUM_REGS; i++) begin
            for (genvar j = 0; j < C_DATA_WIDTH/8; j++) begin

                always_ff @ (posedge aclk) begin
                    if (!aresetn) begin
                        reg_array[i][j*8+7-:8] <= 'd0;
                    end else if (wr_valid && awaddr_s == C_REG_ADDR_LIST[i] && wstrb_s[j]) begin
                        reg_array[i][j*8+7-:8] <= wdata_s[j*8+7-:8];
                    end
                end

            end
        end
    endgenerate

    // Write response channel
    //------------------------

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            s_axi_bvalid <= 1'b0;
        end else begin
            s_axi_bvalid <= (wr_state_next == S_WRRESP);
        end
    end

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            s_axi_bresp <= 0;
        end else if (wr_valid) begin
            s_axi_bresp <= addr_in_range(awaddr_s) ? C_RESP_OKAY : C_RESP_DECERR;
        end
    end


    // Read State Machine
    //====================

    // Read Iteration Interval = 2 (back-to-back read transaction)
    // Read Latency = 2 (from AWADDR transaction to RDATA transaction)

    typedef enum {S_RDRST, S_RDIDLE, S_RDDATA} RDSTATE_T;

    RDSTATE_T rd_state, rd_state_next;

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            rd_state <= S_RDRST;
        end else begin
            rd_state <= rd_state_next;
        end
    end

    always_comb begin
        case(rd_state)
            S_RDRST  : rd_state_next = S_RDIDLE;
            S_RDIDLE : rd_state_next = !s_axi_arvalid ? S_RDIDLE : S_RDDATA;
            S_RDDATA : rd_state_next = !s_axi_rready  ? S_RDDATA : S_RDIDLE;
            default  : rd_state_next = S_RDRST;
        endcase
    end

    wire rd_valid;

    assign rd_valid = (rd_state == S_RDIDLE) && s_axi_arvalid;

    // Read Address Channel
    //----------------------

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            s_axi_arready <= 1'b0;
        end else begin
            s_axi_arready <= (rd_state_next == S_RDIDLE);
        end
    end

    // Read Data Channel
    //-------------------

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            s_axi_rvalid <= 1'b0;
        end else begin
            s_axi_rvalid <= (rd_state_next == S_RDDATA);
        end
    end

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            s_axi_rdata <= 0;
        end else if (rd_valid) begin
            s_axi_rdata <= output_mux(s_axi_araddr);
        end
    end

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            s_axi_rresp <= 0;
        end else if (rd_valid) begin
            s_axi_rresp <= addr_in_range(s_axi_araddr);
        end
    end

endmodule

`default_nettype wire
