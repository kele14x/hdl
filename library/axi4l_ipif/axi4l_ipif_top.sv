//******************************************************************************
// Copyright (C) 2020  kele14x
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
//******************************************************************************

`timescale 1 ns / 1 ps
`default_nettype none

// Note: AxPROT not supported (not connected)

module axi4l_ipif_top #(
    parameter C_ADDR_WIDTH = 12,
    parameter C_DATA_WIDTH = 32
) (
    // AXI4-Lite Slave
    //=================
    input  var logic                      aclk         ,
    input  var logic                      aresetn      ,
    //
    input  var logic [  C_ADDR_WIDTH-1:0] s_axi_awaddr ,
    input  var logic [               2:0] s_axi_awprot ,
    input  var logic                      s_axi_awvalid,
    output var logic                      s_axi_awready,
    //
    input  var logic [  C_DATA_WIDTH-1:0] s_axi_wdata  ,
    input  var logic [C_DATA_WIDTH/8-1:0] s_axi_wstrb  ,
    input  var logic                      s_axi_wvalid ,
    output var logic                      s_axi_wready ,
    //
    output var logic [               1:0] s_axi_bresp  ,
    output var logic                      s_axi_bvalid ,
    input  var logic                      s_axi_bready ,
    //
    input  var logic [  C_ADDR_WIDTH-1:0] s_axi_araddr ,
    input  var logic [               2:0] s_axi_arprot ,
    input  var logic                      s_axi_arvalid,
    output var logic                      s_axi_arready,
    //
    output var logic [  C_DATA_WIDTH-1:0] s_axi_rdata  ,
    output var logic [               1:0] s_axi_rresp  ,
    output var logic                      s_axi_rvalid ,
    input  var logic                      s_axi_rready ,
    // Write i/f
    //-----------
    output var logic [  C_ADDR_WIDTH-3:0] wr_addr      ,
    output var logic                      wr_req       ,
    output var logic [C_DATA_WIDTH/8-1:0] wr_be        ,
    output var logic [  C_DATA_WIDTH-1:0] wr_data      ,
    input  var logic                      wr_ack       ,
    // Read i/f
    //----------
    output var logic [  C_ADDR_WIDTH-3:0] rd_addr      ,
    output var logic                      rd_req       ,
    input  var logic [  C_DATA_WIDTH-1:0] rd_data      ,
    input  var logic                      rd_ack
);

    // synthesis translate_off
    initial begin
        assert ((C_DATA_WIDTH == 32) || (C_DATA_WIDTH == 64)) else
            $error("AXI-4 Lite interface only support C_DATA_WIDTH=32 or 64");
    end
    // synthesis translate_on
  
    // RRESP/BRESP
    localparam C_RESP_OKAY   = 2'b00; // OKAY, normal access success
    localparam C_RESP_EXOKAY = 2'b01; // EXOKAY, exclusive access success
    localparam C_RESP_SLVERR = 2'b10; // SLVERR, slave error
    localparam C_RESP_DECERR = 2'b11; // DECERR, decoder error


    // Write State Machine
    //=====================

    enum {
        S_WRRST , // in reset
        S_WRIDLE, // idle, waiting for both write address and write data
        S_WRADDR, // write data is provided, waiting for write address
        S_WRDATA, // write address is provided, waiting for write data
        S_WRWAIT, // both write data and address is provided, wait `wr_ack`
        S_WRRESP  // `wr_ack` is assert, response to axi master
    } wr_state, wr_state_next;

    var logic wr_valid, wr_addr_valid, wr_data_valid;
    var logic [4:0] wr_cnt;

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
            S_WRWAIT : wr_state_next = !(wr_ack || wr_cnt[4]) ? S_WRWAIT : S_WRRESP;
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
            wr_req <= wr_valid;
        end
    end

    // Time out counter of waiting for `wr_ack`
    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            wr_cnt <= 5'h1F;
        end else if (wr_state_next == S_WRWAIT) begin
            wr_cnt <= wr_cnt + 1;
        end else begin
            wr_cnt <= 5'h1F;
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
            s_axi_bresp <= C_RESP_OKAY;
        end else if (wr_state == S_WRWAIT && wr_cnt[4]) begin
            s_axi_bresp <= C_RESP_SLVERR; // Time out, response a error
        end
    end


    // Read State Machine
    //====================

    // Read Iteration Interval = 2 (back-to-back read transaction)
    // Read Latency = 2 (from AWADDR transaction to RDATA transaction)

    enum {
        S_RDRST ,
        S_RDIDLE,
        S_RDWAIT,
        S_RDRESP
    } rd_state, rd_state_next;

    var logic rd_valid;
    var logic [4:0] rd_cnt;

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
            S_RDWAIT : rd_state_next = !(rd_ack || rd_cnt[4]) ? S_RDWAIT : S_RDRESP;
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
            rd_addr <= s_axi_araddr[C_ADDR_WIDTH-1:2];
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
            rd_req <= rd_valid;
        end
    end


    // Read Data/Response Channel
    //-------------------

    always @ (posedge aclk) begin
        if (!aresetn) begin
            s_axi_rvalid <= 1'b0;
        end else begin
            s_axi_rvalid <= (rd_state_next == S_RDRESP);
        end
    end

    // Time out counter of waiting for `rd_ack`
    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            rd_cnt <= 5'h1F;
        end else if (rd_state_next == S_RDWAIT) begin
            rd_cnt <= rd_cnt + 1;
        end else begin
            rd_cnt <= 5'h1F;
        end
    end

    always @ (posedge aclk) begin
        if (!aresetn) begin
            s_axi_rdata <= 0;
        end else if (rd_state == S_RDWAIT && rd_ack) begin
            s_axi_rdata <= rd_data;
        end else if (rd_state == S_RDWAIT && rd_cnt[4]) begin
            s_axi_rdata <= 'd0; // Read time out, give master default value
        end
    end

    always @ (posedge aclk) begin
        if (!aresetn) begin
            s_axi_rresp <= 0;
        end else if (rd_state == S_RDWAIT && rd_ack) begin
            s_axi_rresp <= C_RESP_OKAY;
        end else if (rd_state == S_RDWAIT && rd_cnt[4]) begin
            s_axi_rresp <= C_RESP_SLVERR; // Read time out, response a error
        end
    end

endmodule

`default_nettype wire
