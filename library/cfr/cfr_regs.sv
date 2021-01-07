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

// File: cfr_regs.sv
// Brief: Register interface for CFR

`timescale 1ns / 1ps `default_nettype none

module cfr_regs #(
    parameter int IPIF_ADDR_WIDTH = 10,
    parameter int IPIF_DATA_WIDTH = 32
) (
    // IPIF Interface
    //---------------
    input  var                         ipif_clk                      ,
    input  var                         ipif_rst                      ,
    //
    input  var [  IPIF_ADDR_WIDTH-1:0] ipif_wr_addr                  ,
    input  var                         ipif_wr_req                   ,
    input  var [  IPIF_DATA_WIDTH-1:0] ipif_wr_data                  ,
    output var                         ipif_wr_ack                   ,
    //
    input  var [  IPIF_ADDR_WIDTH-1:0] ipif_rd_addr                  ,
    input  var                         ipif_rd_req                   ,
    output var [  IPIF_DATA_WIDTH-1:0] ipif_rd_data                  ,
    output var                         ipif_rd_ack                   ,
    // Registers
    //---------------
    output var                         ctrl_pc_cfr_enable            ,
    output var [                 16:0] ctrl_pc_cfr_clipping_threshold,
    output var [                 16:0] ctrl_pc_cfr_detect_threshold  ,
    //
    output var                         ctrl_pc_cfr_cpw_wr_en         ,
    output var [                  7:0] ctrl_pc_cfr_cpw_wr_addr       ,
    output var [                 15:0] ctrl_pc_cfr_cpw_wr_data_i     ,
    output var [                 15:0] ctrl_pc_cfr_cpw_wr_data_q     ,
    //
    output var                         ctrl_hc_enable                ,
    output var [                 16:0] ctrl_hc_threshold
);

endmodule

`default_nettype wire
