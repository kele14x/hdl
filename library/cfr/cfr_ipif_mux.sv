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
    parameter int IPIF_ADDR_WIDTH = 10,
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

endmodule

`default_nettype wire
