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

// File: cfr.sv
// Brief: CFR Top module

`timescale 1ns / 1ps `default_nettype none

module cfr #(
    parameter int AXI_ADDR_WIDTH = 16,
    parameter int AXI_DATA_WIDTH = 32,
    //
    parameter int DATA_WIDTH     = 16,
    //
    parameter int CPW_ADDR_WIDTH = 8 ,
    parameter int CPW_DATA_WIDTH = 16,
    //
    parameter int NUM_BRANCH     = 16
) (
    // AXI4-Lite Slave I/F
    //--------------------
    input  var                      aclk                   ,
    input  var                      aresetn                ,
    //
    input  var [AXI_ADDR_WIDTH-1:0] s_axi_awaddr           ,
    input  var [               2:0] s_axi_awprot           ,
    input  var                      s_axi_awvalid          ,
    output var                      s_axi_awready          ,
    //
    input  var [AXI_DATA_WIDTH-1:0] s_axi_wdata            ,
    input  var [               3:0] s_axi_wstrb            ,
    input  var                      s_axi_wvalid           ,
    output var                      s_axi_wready           ,
    //
    output var [               1:0] s_axi_bresp            ,
    output var                      s_axi_bvalid           ,
    input  var                      s_axi_bready           ,
    //
    input  var [AXI_ADDR_WIDTH-1:0] s_axi_araddr           ,
    input  var [               2:0] s_axi_arprot           ,
    input  var                      s_axi_arvalid          ,
    output var                      s_axi_arready          ,
    //
    output var [AXI_DATA_WIDTH-1:0] s_axi_rdata            ,
    output var [               1:0] s_axi_rresp            ,
    output var                      s_axi_rvalid           ,
    input  var                      s_axi_rready           ,
    // Data Interface
    //---------------
    input  var                      clk                    ,
    input  var                      rst                    ,
    // Data input
    input  var [    DATA_WIDTH-1:0] data_i_in  [NUM_BRANCH],
    input  var [    DATA_WIDTH-1:0] data_q_in  [NUM_BRANCH],
    // Data output
    output var [    DATA_WIDTH-1:0] data_i_out [NUM_BRANCH],
    output var [    DATA_WIDTH-1:0] data_q_out [NUM_BRANCH]
);

    logic [AXI_ADDR_WIDTH-3:0] wr_addr;
    logic                      wr_req ;
    logic [AXI_DATA_WIDTH-1:0] wr_data;
    logic                      wr_ack ;

    logic [AXI_ADDR_WIDTH-3:0] rd_addr;
    logic                      rd_req ;
    logic [AXI_DATA_WIDTH-1:0] rd_data;
    logic                      rd_ack ;

    logic [AXI_ADDR_WIDTH-7:0] ipif_wr_addr[NUM_BRANCH];
    logic                      ipif_wr_req [NUM_BRANCH];
    logic [AXI_DATA_WIDTH-1:0] ipif_wr_data[NUM_BRANCH];
    logic                      ipif_wr_ack [NUM_BRANCH];

    logic [AXI_ADDR_WIDTH-7:0] ipif_rd_addr[NUM_BRANCH];
    logic                      ipif_rd_req [NUM_BRANCH];
    logic [AXI_DATA_WIDTH-1:0] ipif_rd_data[NUM_BRANCH];
    logic                      ipif_rd_ack [NUM_BRANCH];

    // Address width 16 -> 14
    axi4l_ipif_top #(
        .C_ADDR_WIDTH(AXI_ADDR_WIDTH),
        .C_DATA_WIDTH(AXI_DATA_WIDTH)
    ) i_axi4l_ipif_top (
        .aclk         (aclk          ),
        .aresetn      (aresetn       ),
        //
        .s_axi_awaddr (s_axi_awaddr  ),
        .s_axi_awprot (s_axi_awprot  ),
        .s_axi_awvalid(s_axi_awvalid ),
        .s_axi_awready(s_axi_awready ),
        //
        .s_axi_wdata  (s_axi_wdata   ),
        .s_axi_wstrb  (s_axi_wstrb   ),
        .s_axi_wvalid (s_axi_wvalid  ),
        .s_axi_wready (s_axi_wready  ),
        //
        .s_axi_bresp  (s_axi_bresp   ),
        .s_axi_bvalid (s_axi_bvalid  ),
        .s_axi_bready (s_axi_bready  ),
        //
        .s_axi_araddr (s_axi_araddr  ),
        .s_axi_arprot (s_axi_arprot  ),
        .s_axi_arvalid(s_axi_arvalid ),
        .s_axi_arready(s_axi_arready ),
        //
        .s_axi_rdata  (s_axi_rdata   ),
        .s_axi_rresp  (s_axi_rresp   ),
        .s_axi_rvalid (s_axi_rvalid  ),
        .s_axi_rready (s_axi_rready  ),
        //
        .wr_addr      (wr_addr       ),
        .wr_req       (wr_req        ),
        .wr_be        (/* Not used */),
        .wr_data      (wr_data       ),
        .wr_ack       (wr_ack        ),
        //
        .rd_addr      (rd_addr       ),
        .rd_req       (rd_req        ),
        .rd_data      (rd_data       ),
        .rd_ack       (rd_ack        )
    );


    // Address width 14 -> 10
    cfr_ipif_mux #(
        .IPIF_ADDR_WIDTH(AXI_ADDR_WIDTH-2),
        .IPIF_DATA_WIDTH(AXI_DATA_WIDTH  ),
        .NUM_BRANCH     (NUM_BRANCH      )
    ) i_cfr_ipif_mux (
        .clk         (aclk        ),
        .rst         (~aresetn    ),
        //
        .wr_addr     (wr_addr     ),
        .wr_req      (wr_req      ),
        .wr_data     (wr_data     ),
        .wr_ack      (wr_ack      ),
        //
        .rd_addr     (rd_addr     ),
        .rd_req      (rd_req      ),
        .rd_data     (rd_data     ),
        .rd_ack      (rd_ack      ),
        //
        .ipif_wr_addr(ipif_wr_addr),
        .ipif_wr_req (ipif_wr_req ),
        .ipif_wr_data(ipif_wr_data),
        .ipif_wr_ack (ipif_wr_ack ),
        //
        .ipif_rd_addr(ipif_rd_addr),
        .ipif_rd_req (ipif_rd_req ),
        .ipif_rd_data(ipif_rd_data),
        .ipif_rd_ack (ipif_rd_ack )
    );


    generate
        for (genvar i = 0; i < NUM_BRANCH; i++) begin : g_branch

            // Address width: 10
            cfr_branch #(
                .IPIF_ADDR_WIDTH(AXI_ADDR_WIDTH-6),
                .IPIF_DATA_WIDTH(AXI_DATA_WIDTH  ),
                //
                .DATA_WIDTH     (DATA_WIDTH      ),
                //
                .CPW_ADDR_WIDTH (CPW_ADDR_WIDTH  ),
                .CPW_DATA_WIDTH (CPW_DATA_WIDTH  )
            ) i_cfr_branch (
                .ipif_clk    (aclk           ),
                .ipif_rst    (~aresetn       ),
                //
                .ipif_wr_addr(ipif_wr_addr[i]),
                .ipif_wr_req (ipif_wr_req [i]),
                .ipif_wr_data(ipif_wr_data[i]),
                .ipif_wr_ack (ipif_wr_ack [i]),
                //
                .ipif_rd_addr(ipif_rd_addr[i]),
                .ipif_rd_req (ipif_rd_req [i]),
                .ipif_rd_data(ipif_rd_data[i]),
                .ipif_rd_ack (ipif_rd_ack [i]),
                //
                .clk         (clk            ),
                .rst         (rst            ),
                //
                .data_i_in   (data_i_in   [i]),
                .data_q_in   (data_q_in   [i]),
                .data_i_out  (data_i_out  [i]),
                .data_q_out  (data_q_out  [i])
            );
        end
    endgenerate
endmodule

`default_nettype wire
