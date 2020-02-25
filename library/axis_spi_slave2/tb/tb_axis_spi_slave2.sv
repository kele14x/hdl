/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module tb_axis_spi_slave2;

    parameter SPI_PERIOD = 60;
    
    parameter C_DATA_WIDTH     = 8; // 8, 16, 24, 32

    logic SS_I  = 0;
    logic SS_O  = 0;
    logic SS_T  = 0;
    logic SCK_I = 0;
    logic SCK_O = 0;
    logic SCK_T = 0;
    logic IO0_I = 0; // SI
    logic IO0_O = 0;
    logic IO0_T = 0;
    logic IO1_I = 0; // SO
    logic IO1_O = 0;
    logic IO1_T = 0;

    logic aclk    = 0;
    logic aresetn = 0;

    logic [7:0] axis_rx_tdata  = 0;
    logic       axis_rx_tvalid = 0;
    logic       axis_rx_tready = 0;

    logic [7:0] axis_tx_tdata  = 0;
    logic       axis_tx_tvalid = 0;
    logic       axis_tx_tready = 0;


    reg [7:0] tx_buffer [0:100];

    task axis_send (input [7:0] tdata);
        @(posedge aclk);
        // Send byte
        axis_tx_tdata  <= tdata;
        axis_tx_tvalid <= 1'b1;
        // wait byte is received
        forever begin
            @(posedge aclk);
            if (axis_tx_tvalid && axis_tx_tready) break;
        end
        // Reset bus
        axis_tx_tdata  <= 0;
        axis_tx_tvalid <= 0;
    endtask

    // Send n byte on SPI bus
    task spi_send(input int nbyte, input [7:0] txd[]);
        // Active slave select pin
        SS_I = 0;
        #(SPI_PERIOD/2);
        // Loop byte
        for (int i = 0; i < nbyte; i++) begin
            // Loop bit
            for (int j = 0; j < 8; j++) begin
                // Data is pushed at rising edge of SCK
                SCK_I = 1;
                IO0_I = txd[i][7-j];
                #(SPI_PERIOD/2);
                // Slave should sample data at this time
                SCK_I = 0;
                #(SPI_PERIOD/2);
            end
            $display("%t, SPI Master send: 0x%x", $time, txd[i]);
        end
        // Deactive slave select
        SS_I = 1;
        IO0_I = 1'bZ;
        // Guard time between words
        #(SPI_PERIOD/2);
    endtask

    /* Simulation */
    //==============

    always begin
        aclk = 0;
        #5;
        aclk = 1;
        #5;
    end

    reg [2:0] rx_cnt = 0;
    reg [7:0] rx_data = 0;

    always @(negedge SCK_I, posedge SS_I) begin
        if (SS_I) begin
            rx_cnt = 0;
        end else begin
            rx_data[7-rx_cnt] = IO1_O;
            if (rx_cnt == 7) begin
                $display("%t, SPI Master got: 0x%x", $time, rx_data);
            end
            rx_cnt++;
        end
    end

    initial begin
        $display("%t: Simulation starts.", $time);
        aresetn = 0;
        #1000;
        aresetn = 1;
        $display("%t: Reset done", $time);
        #100000;
        $finish;
    end

    initial begin
        axis_tx_tdata = 0;
        axis_tx_tvalid = 0;
        axis_rx_tready = 1;
        wait(aresetn);

        axis_send(8'hAA);
        axis_send(8'h55);
    end

    initial begin
        SCK_I = 0;
        SS_I = 1;
        IO0_I = 1'bZ;
        wait(aresetn);
        #200;
        for (int i = 0; i < 100; i++) begin
            tx_buffer[i] = i + 100;
        end
        spi_send(4, tx_buffer);
        spi_send(4, tx_buffer);
    end

    always @ (posedge aclk) begin
        if (axis_rx_tvalid && axis_rx_tready) begin
            $display("%t, RX AXIS got: 0x%x", $time, axis_rx_tdata);
        end
    end

    always @ (posedge aclk) begin
        if (axis_tx_tvalid && axis_tx_tready) begin
            $display("%t, TX AXIS send: 0x%x", $time, axis_tx_tdata);
        end
    end

    final begin
        $display("Simulation ends");
    end

    axis_spi_slave2 #(
        .C_DATA_WIDTH(C_DATA_WIDTH)
    ) DUT ( .* );

endmodule
