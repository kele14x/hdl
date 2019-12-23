
`timescale 1 ns / 1 ps
`default_nettype none

// RRESP/BRESP
// 0b00 - OKAY, normal access success
// 0b01 - EXOKAY, exclusive access success
// 0b10 - SLVERR, slave error
// 0b11 - DECERR, decoder error

// AxPROT
// [0] - 0/1: Unprivileged access/Privileged access
// [1] - 0/1: Secure access/Non-secure access
// [2] - 0/1: Data access/Instruction access

module axi4_lite_slave #(parameter C_DATA_WIDTH = 32) (
    // AXI4-Lite
    //==========
    // Global
    input  wire                      ACLK   ,
    input  wire                      ARESETn,
    // Write address channel
    input  wire [  C_DATA_WIDTH-1:0] AWADDR ,
    input  wire [               2:0] AWPROT ,
    input  wire                      AWVALID,
    output wire                      AWREADY,
    // Write data channel
    input  wire [  C_DATA_WIDTH-1:0] WDATA  ,
    input  wire [C_DATA_WIDTH/8-1:0] WSTRB  ,
    input  wire                      WVALID ,
    output wire                      WREADY ,
    // Write response channel
    output reg  [               1:0] BRESP  ,
    output reg                       BVALID ,
    input  wire                      BREADY ,
    // Read address channel
    input  wire [  C_DATA_WIDTH-1:0] ARADDR ,
    input  wire [               2:0] ARPROT ,
    input  wire                      ARVALID,
    output wire                      ARREADY,
    // Read data channel
    output reg  [  C_DATA_WIDTH-1:0] RDATA  ,
    output reg  [               1:0] RRESP  ,
    output wire                      RVALID ,
    input  wire                      RREADY
);

    // Write State Machine
    //=====================

    typedef enum {WRRST, WRIDLE, WRADDR, WRDATA, WRRESP} WRSTATE_T;

    WRSTATE_T wr_state, wr_state_next;

    always_ff @ (posedge ACLK) begin
        if (!ARESETn) begin
            wr_state <= WRRST;
        end else begin
            wr_state <= wr_state_next;
        end
    end

    always_comb begin
        case (wr_state)
            WRRST  : wr_state_next = WRIDLE;
            WRIDLE : wr_state_next = (AWVALID && WVALID) ? WRRESP :
                                      AWVALID ? WRADDR :
                                      WVALID  ? WRDATA :
                                      WRIDLE;
            WRADDR : wr_state_next = !WVALID  ? WRADDR : WRRESP;
            WRDATA : wr_state_next = !AWVALID ? WRDATA : WRRESP;
            WRRESP : wr_state_next = !BREADY  ? WRRESP : WRIDLE;
        endcase
    end

    // Write address channel
    //======================

    assign AWREADY = (wr_state == WRIDLE || wr_state == WRDATA);

    // Write data channel
    //===================

    assign WREADY = (wr_state == WRIDLE || wr_state == WRADDR);

    // Write response channel
    //=======================

    assign BVALID = (wr_state == WRRESP);

    always_ff @ (posedge ACLK) begin
        if (!ARESETn) begin
            BRESP <= 0;
        end else if (
            ((wr_state == WRIDLE) && AWVALID && WVALID) ||
            ((wr_state == WRADDR) && WVALID) ||
            ((wr_state == WRDATA) && AWVALID)) begin
            BRESP <= 0;
        end
    end


    // Read State Machine
    //====================

    // Read Iteration Interval = 2 (back-to-back read transaction)
    // Read Latency = 2 (from AWADDR transaction to RDATA transaction)

    typedef enum {RDRST, RDIDLE, RDDATA} RDSTATE_T;

    RDSTATE_T rd_state, rd_state_next;

    always_ff @ (posedge ACLK) begin
        if (!ARESETn) begin
            rd_state <= RDRST;
        end else begin
            rd_state <= rd_state_next;
        end
    end

    always_comb begin
        case(rd_state)
            RDRST  : rd_state_next = RDIDLE;
            RDIDLE : rd_state_next = !ARVALID ? RDIDLE : RDDATA;
            RDDATA : rd_state_next = !RREADY  ? RDDATA : RDIDLE;
            default: rd_state_next = RDRST;
        endcase
    end

    // Read address channel
    //======================

    assign ARREADY = (rd_state == RDIDLE);

    // Read data channel
    //==================

    assign RVALID = (rd_state == RDDATA);

    always_ff @ (posedge ACLK) begin
        if (!ARESETn) begin
            RDATA <= 0;
        end else begin
            if ((rd_state == RDIDLE) && ARVALID) begin
                RDATA <= ARADDR;
            end
        end
    end

    always_ff @ (posedge ACLK) begin
        if (!ARESETn) begin
            RRESP <= 0;
        end else begin
            if ((rd_state == RDIDLE) && ARVALID) begin
                RRESP <= 2'b00;
            end
        end
    end

endmodule

`default_nettype wire
