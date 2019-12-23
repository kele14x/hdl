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

    parameter CLK_RATIO   = 2;

    logic SCK   ;
    logic SS_N  ;
    logic MOSI_Z;
    logic MISO  ;

    logic aclk   ;
    logic aresetn;

    logic [7:0] s_axis_tdata ;
    logic                  s_axis_tvalid;
    logic                   s_axis_tready;

    logic [7:0] m_axis_tdata ;
    logic                   m_axis_tvalid;
    logic                   m_axis_tready;

    logic stat_rx_overflow;

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

    always begin
        aclk = 0;
        #4;
        aclk = 1;
        #4;
    end

    assign MISO = MOSI_Z;

    initial begin
        $display("Simulation starts");
        aresetn = 0;
        s_axis_tdata = 0;
        s_axis_tvalid = 0;
        m_axis_tready = 1;
        #1000;
        aresetn = 1;
        $display("%t: Reset done",$time());

        #1000;
        // Send one frame
        axis_send(8'h55);
        axis_send(8'hA3);
        
        #600;
        axis_send(8'hAA);

        #10000;
        $finish;
    end

    always @ (posedge aclk) begin
        if (s_axis_tvalid && s_axis_tready) begin
            $display("%t, TX AXIS I/F send: 0x%X", $time, s_axis_tdata);
        end
        if (m_axis_tvalid && m_axis_tready) begin
            $display("%t, RX AXIS I/F got: 0x%X",  $time, m_axis_tdata);
        end
    end

    final begin
        $display("Simulation ends");
    end

`define SIMULATION
    axis_spi_master #(
        .CLK_RATIO  (CLK_RATIO  )
    ) UUT ( .* );

endmodule
