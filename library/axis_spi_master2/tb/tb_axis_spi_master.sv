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

module tb_axis_spi_master ();

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

    logic aclk = 0;
    logic aresetn = 0;

    logic [7:0] s_axis_tdata  = 0;
    logic       s_axis_tvalid = 0;
    logic       s_axis_tready;

    logic [7:0] m_axis_tdata     ;
    logic       m_axis_tvalid    ;
    logic       m_axis_tready = 1;

    task axis_send (input [7:0] tdata);
        @(posedge aclk);
        // Send byte
        s_axis_tdata  <= tdata;
        s_axis_tvalid <= 1'b1;
        // wait byte is received
        forever begin
            @(posedge aclk);
            if (s_axis_tready) break;
        end
        // Reset bus
        s_axis_tdata  <= 0;
        s_axis_tvalid <= 0;
    endtask

    always #4 aclk = !aclk;

    initial #100 aresetn = 1;

    // Loop-back test
    assign IO1_I = IO0_O;

    initial begin
        $display("Simulation starts");
        wait (aresetn == 0);
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

    axis_spi_master #(
        .CLK_RATIO  (CLK_RATIO  )
    ) UUT ( .* );

endmodule
