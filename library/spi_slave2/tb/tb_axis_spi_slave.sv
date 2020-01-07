//=============================================================================
//
// Copyright (C) 2019 Kele
//
// This program is free software: you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by the Free
// Software Foundation, either version 3 of the License, or (at your option)
// any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
// FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
// more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
//
//=============================================================================

`timescale 1 ns / 1 ps
`default_nettype none

module tb_axis_spi_slave;

    parameter SPI_PERIOD = 60;

    logic SCK   ;
    logic SS_N  ;
    logic MOSI  ;
    logic MISO_Z;

    logic aclk   ;
    logic aresetn;

    logic [7:0] m_axis_tdata ;
    logic       m_axis_tvalid;
    logic       m_axis_tready;

    logic [7:0] s_axis_tdata ;
    logic       s_axis_tvalid;
    logic       s_axis_tready;

    logic stat_rx_overflow;
    logic stat_tx_underflow;

    reg [7:0] tx_buffer [0:100];

    task axis_send (input [7:0] tdata);
        @(posedge aclk);
        // Send byte
        s_axis_tdata  <= tdata;
        s_axis_tvalid <= 1'b1;
        // wait byte is received
        forever begin
            @(posedge aclk);
            if (s_axis_tvalid && s_axis_tready) break;
        end
        // Reset bus
        s_axis_tdata  <= 0;
        s_axis_tvalid <= 0;
    endtask

    // Send n byte on SPI bus
    task spi_send(input int nbyte, input [7:0] txd[]);
        // Active slave select pin
        SS_N = 0;
        #(SPI_PERIOD/2);
        // Loop byte
        for (int i = 0; i < nbyte; i++) begin
            // Loop bit
            for (int j = 0; j < 8; j++) begin
                // Data is pushed at rising edge of SCK
                SCK = 1;
                MOSI = txd[i][7-j];
                #(SPI_PERIOD/2);
                // Slave should sample data at this time
                SCK = 0;
                #(SPI_PERIOD/2);
            end
            $display("%t, SPI Master send: 0x%x", $time, txd[i]);
        end
        // Deactive slave select
        SS_N = 1;
        MOSI = 1'bZ;
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

    always @(negedge SCK, posedge SS_N) begin
        if (SS_N) begin
            rx_cnt = 0;
        end else begin
            rx_data[7-rx_cnt] = MISO_Z;
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
        s_axis_tdata = 0;
        s_axis_tvalid = 0;
        m_axis_tready = 1;
        wait(aresetn);

        axis_send(8'hAA);
        axis_send(8'h55);
    end

    initial begin
        SCK = 0;
        SS_N = 1;
        MOSI = 1'bZ;
        wait(aresetn);
        #200;
        for (int i = 0; i < 100; i++) begin
            tx_buffer[i] = i + 100;
        end
        spi_send(4, tx_buffer);
        spi_send(4, tx_buffer);
    end

    always @ (posedge aclk) begin
        if (m_axis_tvalid && m_axis_tready) begin
            $display("%t, RX AXIS got: 0x%x", $time, m_axis_tdata);
        end
    end

    always @ (posedge aclk) begin
        if (s_axis_tvalid && s_axis_tready) begin
            $display("%t, TX AXIS send: 0x%x", $time, s_axis_tdata);
        end
    end

    final begin
        $display("Simulation ends");
    end

`define SIMULATION
    axis_spi_slave DUT ( .* );

endmodule
