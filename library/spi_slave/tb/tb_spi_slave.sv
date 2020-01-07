/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module tb_spi_axi ();

    parameter WIDTH = 8;

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

    logic        clk  = 0;
    logic        rst  = 1;
    
    logic                       rx_ss    ;
    logic [          WIDTH-1:0] rx_data  ;
    logic [$clog2(WIDTH-1)-1:0] rx_bitcnt;
    logic                       rx_valid ;
    // Tx i/f, beat at each word
    logic [          WIDTH-1:0] tx_data  = 0;
    logic                       tx_load   = 0;


    // Basic SPI Operations
    //=====================

    localparam SPI_PERIOD = 100;

    logic [7:0] txbuffer [0:100], rxbuffer[0:100];

    task spi_send(input int nbytes);
        SS_I = 1;
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

    task spi_read_sfr(input [11:0] addr, output [15:0] data);
        txbuffer[0] = {4'b0000, addr[11:8]};
        txbuffer[1] = addr[7:0];
        txbuffer[2] = 8'd0;
        txbuffer[3] = 8'd0;
        spi_send(4);
    endtask

    task spi_write_sfr(input [11:0] addr, input [15:0] data);
        txbuffer[0] = {4'b0001, addr[11:8]};
        txbuffer[1] = addr[7:0];
        txbuffer[2] = data[15:8];
        txbuffer[3] = data[7:0];
        spi_send(4);
    endtask


    //=========================================================================

    always #5 clk = !clk;

    initial #1000 rst = 0;

    initial begin        
        $display("Simulation starts");
        wait(!rst);

        #100;
        txbuffer[0] = 8'hAA;
        txbuffer[1] = 8'h55;
        txbuffer[2] = 8'hAA;
        txbuffer[3] = 8'h55;
        spi_send(4);
        
        #1000;
        $finish();
    end

    final $display("Simulation ends");

    spi_slave #(.WIDTH(WIDTH)) DUT ( .* );

endmodule

`default_nettype wire
