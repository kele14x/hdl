/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module tb_spi_axi ();

    logic        SCK_I         = 0;
    logic        SCK_O         = 0;
    logic        SCK_T         = 0;
    logic        SS_I          = 1;
    logic        SS_O          = 0;
    logic        SS_T          = 0;
    logic        IO0_I         = 0; // SI
    logic        IO0_O         = 0;
    logic        IO0_T         = 0;
    logic        IO1_I         = 0; // SO
    logic        IO1_O         = 0;
    logic        IO1_T         = 0;
    // AXI4 Lite Master
    //=================
    logic        aclk          = 0;
    logic        aresetn       = 0;
    //
    logic [31:0] m_axi_awaddr ;
    logic [ 2:0] m_axi_awprot ;
    logic        m_axi_awvalid;
    logic        m_axi_awready;
    //
    logic [31:0] m_axi_wdata  ;
    logic [ 3:0] m_axi_wstrb  ;
    logic        m_axi_wvalid ;
    logic        m_axi_wready ;
    //
    logic [ 1:0] m_axi_bresp  ;
    logic        m_axi_bvalid ;
    logic        m_axi_bready ;
    //
    logic [31:0] m_axi_araddr ;
    logic [ 2:0] m_axi_arprot ;
    logic        m_axi_arvalid;
    logic        m_axi_arready;
    //
    logic [31:0] m_axi_rdata  ;
    logic [ 1:0] m_axi_rresp  ;
    logic        m_axi_rvalid ;
    logic        m_axi_rready ;

    localparam SPI_PERIOD = 100;

    logic [47:0] spi_sod;

    task spi_send(input [47:0] sid, output [47:0] sod);
        SS_I = 0;
        #(SPI_PERIOD/2);
        for (int i = 47; i > 0; i--) begin
            SCK_I = 1;
            IO0_I = sid[i];
            #(SPI_PERIOD/2);
            SCK_I = 0;
            sod[i] = IO1_O;
            #(SPI_PERIOD/2);
        end
        IO0_I = 0;
        SS_I = 1;
        #(SPI_PERIOD/2);
    endtask

    always begin
        #5 aclk = ~aclk;
    end
    
    initial begin
        #1000 aresetn = 1;
    end
    
    initial begin
        $display("Simulation starts");
        wait(aresetn);
        repeat(10) begin
            spi_send(48'h5A5A01020304, spi_sod);
            #1000;
        end
        #100000;
        $finish();
    end

    final begin
        $display("Simulation ends");
    end

    spi_axi_v1_0 DUT ( .* );

endmodule

`default_nettype wire
