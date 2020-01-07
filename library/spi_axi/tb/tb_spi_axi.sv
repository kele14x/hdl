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
    logic        m_axi_awready = 1;
    //
    logic [31:0] m_axi_wdata  ;
    logic [ 3:0] m_axi_wstrb  ;
    logic        m_axi_wvalid ;
    logic        m_axi_wready  = 1;
    //
    logic [ 1:0] m_axi_bresp   = 0;
    logic        m_axi_bvalid  = 0;
    logic        m_axi_bready ;
    //
    logic [31:0] m_axi_araddr ;
    logic [ 2:0] m_axi_arprot ;
    logic        m_axi_arvalid;
    logic        m_axi_arready = 1;
    //
    logic [31:0] m_axi_rdata   = 0;
    logic [ 1:0] m_axi_rresp   = 0;
    logic        m_axi_rvalid  = 0;
    logic        m_axi_rready ;


    // Basic SPI Operations
    //=====================

    localparam SPI_PERIOD = 100;

    logic [7:0] txbuffer [0:100], rxbuffer[0:100];

    task spi_send(input int nbytes);
        SS_I = 0;
        #(SPI_PERIOD/2);
        for (int nb = 0; nb < nbytes; nb++) begin
            for (int i = 7; i >= 0; i--) begin
                SCK_I = 1;
                IO0_I = txbuffer[nb][i];
                #(SPI_PERIOD/2);
                SCK_I = 0;
                rxbuffer[nb][i] = IO1_O;
                #(SPI_PERIOD/2);
            end
        end
        IO0_I = 0;
        SS_I = 1;
        #(SPI_PERIOD/2);
        $write("%t, SPI Tx:", $time);
        for (int i = 0; i < nbytes; i++)
            $write("%x, ", txbuffer[i]);
        $write("\n");
        $write("%t, SPI Rx:", $time);
        for (int i = 0; i < nbytes; i++)
            $write("%x, ", rxbuffer[i]);
        $write("\n");
    endtask

    task spi_read(input [14:0] addr);
        txbuffer[0] = {1'b0, addr[14:8]};
        txbuffer[1] = addr[7:0];
        txbuffer[2] = 8'd0;
        txbuffer[3] = 8'd0;
        txbuffer[4] = 8'd0;
        txbuffer[5] = 8'd0;
        spi_send(6);
    endtask

    task spi_write(input [14:0] addr, input [31:0] data);
        txbuffer[0] = {1'b1, addr[14:8]};
        txbuffer[1] = addr[7:0];
        txbuffer[2] = data[31:24];
        txbuffer[3] = data[23:16];
        txbuffer[4] = data[15: 8];
        txbuffer[5] = data[ 7: 0];
        spi_send(6);
    endtask


    //=========================================================================

    always #5 aclk = ~aclk;
    
    initial #1000 aresetn = 1;
    
    initial begin
        $display("Simulation starts");
        wait(aresetn);
        
        #100;
        spi_write(15'h0A,32'h55AA55AA);
        #1000;
        spi_read(15'h0A);
        #1000;
        $finish();
    end

    final $display("Simulation ends");

    spi_axi DUT ( .* );

endmodule

`default_nettype wire
