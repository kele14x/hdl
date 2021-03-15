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

// File: cfr.sv
// Brief: CFR Top module

`timescale 1ns / 1ps `default_nettype none

module cfr #(
    parameter int AXI_ADDR_WIDTH = 17,
    parameter int AXI_DATA_WIDTH = 32,
    //
    parameter int DATA_WIDTH     = 16,
    //
    parameter int CPW_ADDR_WIDTH = 8 ,
    parameter int CPW_DATA_WIDTH = 16,
    //
    parameter int NUM_BRANCH     = 16
) (
    // Data Interface
    //---------------
    input  var                      clk                                        ,
    input  var                      rst                                        ,
    // Data input
    input  var [    DATA_WIDTH-1:0] data_i_in                      [NUM_BRANCH],
    input  var [    DATA_WIDTH-1:0] data_q_in                      [NUM_BRANCH],
    // Data output
    output var [    DATA_WIDTH-1:0] data_i_out                     [NUM_BRANCH],
    output var [    DATA_WIDTH-1:0] data_q_out                     [NUM_BRANCH],
    // Control Interface
    //------------------
    input  var                      ctrl_clk                                   ,
    input  var                      ctrl_rst                                   ,
    //
    input  var                      ctrl_pc_cfr_enable             [NUM_BRANCH],
    input  var [      DATA_WIDTH:0] ctrl_pc_cfr_clipping_threshold [NUM_BRANCH],
    input  var [      DATA_WIDTH:0] ctrl_pc_cfr_detect_threshold   [NUM_BRANCH],
    //
    input  var [CPW_ADDR_WIDTH-1:0] ctrl_pc_cfr_cpw_addr           [NUM_BRANCH],
    input  var                      ctrl_pc_cfr_cpw_en             [NUM_BRANCH],
    input  var                      ctrl_pc_cfr_cpw_we             [NUM_BRANCH],
    output var [CPW_DATA_WIDTH-1:0] ctrl_pc_cfr_cpw_rd_data_i      [NUM_BRANCH],
    output var [CPW_DATA_WIDTH-1:0] ctrl_pc_cfr_cpw_rd_data_q      [NUM_BRANCH],
    input  var [CPW_DATA_WIDTH-1:0] ctrl_pc_cfr_cpw_wr_data_i      [NUM_BRANCH],
    input  var [CPW_DATA_WIDTH-1:0] ctrl_pc_cfr_cpw_wr_data_q      [NUM_BRANCH],
    //
    input  var                      ctrl_hc_enable                 [NUM_BRANCH],
    input  var [      DATA_WIDTH:0] ctrl_hc_threshold              [NUM_BRANCH]
);


    generate
        for (genvar i = 0; i < NUM_BRANCH; i++) begin : g_branch

            cfr_branch #(
                .ID             (i               ),
                //
                .IPIF_ADDR_WIDTH(AXI_ADDR_WIDTH-7),
                .IPIF_DATA_WIDTH(AXI_DATA_WIDTH  ),
                //
                .DATA_WIDTH     (DATA_WIDTH      ),
                //
                .CPW_ADDR_WIDTH (CPW_ADDR_WIDTH  ),
                .CPW_DATA_WIDTH (CPW_DATA_WIDTH  )
            ) i_cfr_branch (
                .clk                           (clk                              ),
                .rst                           (rst                              ),
                //
                .data_i_in                     (data_i_in                     [i]),
                .data_q_in                     (data_q_in                     [i]),
                //
                .data_i_out                    (data_i_out                    [i]),
                .data_q_out                    (data_q_out                    [i]),
                //
                .ctrl_clk                      (ctrl_clk                         ),
                .ctrl_rst                      (ctrl_rst                         ),
                //
                .ctrl_pc_cfr_enable            (ctrl_pc_cfr_enable            [i]),
                .ctrl_pc_cfr_clipping_threshold(ctrl_pc_cfr_clipping_threshold[i]),
                .ctrl_pc_cfr_detect_threshold  (ctrl_pc_cfr_detect_threshold  [i]),
                //
                .ctrl_pc_cfr_cpw_addr          (ctrl_pc_cfr_cpw_addr          [i]),
                .ctrl_pc_cfr_cpw_en            (ctrl_pc_cfr_cpw_en            [i]),
                .ctrl_pc_cfr_cpw_we            (ctrl_pc_cfr_cpw_we            [i]),
                .ctrl_pc_cfr_cpw_rd_data_i     (ctrl_pc_cfr_cpw_rd_data_i     [i]),
                .ctrl_pc_cfr_cpw_rd_data_q     (ctrl_pc_cfr_cpw_rd_data_q     [i]),
                .ctrl_pc_cfr_cpw_wr_data_i     (ctrl_pc_cfr_cpw_wr_data_i     [i]),
                .ctrl_pc_cfr_cpw_wr_data_q     (ctrl_pc_cfr_cpw_wr_data_q     [i]),
                //
                .ctrl_hc_enable                (ctrl_hc_enable                [i]),
                .ctrl_hc_threshold             (ctrl_hc_threshold             [i])
            );

        end
    endgenerate
endmodule

`default_nettype wire
