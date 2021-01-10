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

// File: cfr_ipif_mux.sv
// Brief: IPIF MUX for CFR

`timescale 1ns / 1ps `default_nettype none

module cfr_ipif_mux #(
    parameter int IPIF_ADDR_WIDTH = 14,
    parameter int IPIF_DATA_WIDTH = 32,
    //
    parameter int NUM_BRANCH      = 16
) (
    // IPIF Interface
    //---------------
    input  var                       clk                     ,
    input  var                       rst                     ,
    //
    input  var [IPIF_ADDR_WIDTH-1:0] wr_addr                 ,
    input  var                       wr_req                  ,
    input  var [IPIF_DATA_WIDTH-1:0] wr_data                 ,
    output var                       wr_ack                  ,
    //
    input  var [IPIF_ADDR_WIDTH-1:0] rd_addr                 ,
    input  var                       rd_req                  ,
    output var [IPIF_DATA_WIDTH-1:0] rd_data                 ,
    output var                       rd_ack                  ,
    // Registers
    //---------------
    output var [IPIF_ADDR_WIDTH-1:0] ipif_wr_addr[NUM_BRANCH],
    output var                       ipif_wr_req [NUM_BRANCH],
    output var [IPIF_DATA_WIDTH-1:0] ipif_wr_data[NUM_BRANCH],
    input  var                       ipif_wr_ack [NUM_BRANCH],
    //
    output var [IPIF_ADDR_WIDTH-1:0] ipif_rd_addr[NUM_BRANCH],
    output var                       ipif_rd_req [NUM_BRANCH],
    input  var [IPIF_DATA_WIDTH-1:0] ipif_rd_data[NUM_BRANCH],
    input  var                       ipif_rd_ack [NUM_BRANCH]
);

    localparam int ADDR_WIDTH_PER_BRANCH = IPIF_ADDR_WIDTH - $clog2(NUM_BRANCH-1);
    localparam int ADDR_SPACE_PER_BRANCH = 2**ADDR_WIDTH_PER_BRANCH;

    // WR

    generate
        for (genvar i = 0; i < NUM_BRANCH; i++) begin

            // wr_addr, wr_data
            always_ff @ (posedge clk) begin
                ipif_wr_addr[i] <= wr_addr;
                ipif_wr_data[i] <= wr_data;
            end

            // wr_req
            always_ff @ (posedge clk) begin
                ipif_wr_req[i] <= (i*ADDR_SPACE_PER_BRANCH <= wr_addr) && (wr_addr < (i+1)*ADDR_SPACE_PER_BRANCH) && wr_req;
            end

        end
    endgenerate

    always_ff @ (posedge clk) begin
        wr_ack <= ipif_wr_ack[wr_addr/ADDR_SPACE_PER_BRANCH];
    end

    // RD

    generate
        for (genvar i = 0; i < NUM_BRANCH; i++) begin

            // rd_addr
            always_ff @ (posedge clk) begin
                ipif_rd_addr[i] <= rd_addr;
            end

            // rd_req
            always_ff @ (posedge clk) begin
                ipif_rd_req[i] <= (i*ADDR_SPACE_PER_BRANCH <= rd_addr) && (rd_addr < (i+1)*ADDR_SPACE_PER_BRANCH) && rd_req;
            end

        end
    endgenerate

    // rd_data, rd_ack
    always_ff @ (posedge clk) begin
        rd_data <= ipif_rd_data[rd_addr/ADDR_SPACE_PER_BRANCH];
        rd_ack  <= ipif_rd_ack [rd_addr/ADDR_SPACE_PER_BRANCH];
    end

endmodule

`default_nettype wire
