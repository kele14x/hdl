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

module tb_spi_master ();

    parameter CLK_RATIO   = 16;

    logic SCK_I = 0;
    logic SCK_O = 0;
    logic SCK_T = 0;
    logic SS_I  = 0;
    logic SS_O  = 0;
    logic SS_T  = 0;
    logic IO0_I = 0;
    logic IO0_O = 0; // MO
    logic IO0_T = 0;
    logic IO1_I;     // MI
    logic IO1_O = 0;
    logic IO1_T = 0;

    logic clk = 0;
    logic rst = 1;

    logic [7:0] spi_tx_data  = 0;
    logic       spi_tx_valid = 0;
    logic       spi_tx_ready = 0;

    logic [7:0] spi_rx_data  = 0;
    logic       spi_rx_valid = 0;

    task axis_send (input [7:0] tdata);
        @(posedge clk);
        // Send byte
        spi_tx_data  <= tdata;
        spi_tx_valid <= 1'b1;
        // wait byte is received
        forever begin
            @(posedge clk);
            if (spi_tx_ready) break;
        end
        // Reset bus
        spi_tx_data  <= 0;
        spi_tx_valid <= 0;
    endtask

    always #4 clk = !clk;

    initial #100 rst = 0;

    // Loopback test
    assign IO1_I = IO0_O;

    initial begin
        $display("Simulation starts");
        wait (rst == 0);
        #100;
        // Send one frame
        axis_send(8'h55);

        #2000;
        axis_send(8'hA3);
        axis_send(8'hAA);

        #10000;
        $finish;
    end

    final begin
        $display("Simulation ends");
    end

    spi_master #(
        .CLK_RATIO  (CLK_RATIO  )
    ) UUT ( .* );

endmodule
