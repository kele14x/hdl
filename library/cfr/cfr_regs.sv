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
    parameter int ID         = 0 ,
    //
    parameter int ADDR_WIDTH = 10,
    parameter int DATA_WIDTH = 32
) (
    // IPIF Interface
    //---------------
    input  var                  clk                           ,
    input  var                  rst                           ,
    //
    input  var [ADDR_WIDTH-1:0] wr_addr                       ,
    input  var                  wr_req                        ,
    input  var [DATA_WIDTH-1:0] wr_data                       ,
    output var                  wr_ack                        ,
    //
    input  var [ADDR_WIDTH-1:0] rd_addr                       ,
    input  var                  rd_req                        ,
    output var [DATA_WIDTH-1:0] rd_data                       ,
    output var                  rd_ack                        ,
    // Registers
    //---------------
    output var                  ctrl_pc_cfr_enable            ,
    output var [          16:0] ctrl_pc_cfr_detect_threshold  ,
    output var [          16:0] ctrl_pc_cfr_clipping_threshold,
    //
    output var                  ctrl_pc_cfr_cpw_wr_en         ,
    output var [           7:0] ctrl_pc_cfr_cpw_wr_addr       ,
    output var [          15:0] ctrl_pc_cfr_cpw_wr_data_i     ,
    output var [          15:0] ctrl_pc_cfr_cpw_wr_data_q     ,
    //
    output var                  ctrl_hc_enable                ,
    output var [          16:0] ctrl_hc_threshold
);

    // WR

    always_ff @ (posedge clk) begin
        if (rst) begin
            ctrl_pc_cfr_enable<=1'b0;
        end if (wr_addr == 8 && wr_req) begin
            ctrl_pc_cfr_enable <= wr_data[0];
        end
    end

    always_ff @ (posedge clk) begin
        if (rst) begin
            ctrl_pc_cfr_detect_threshold <= '1;
        end if (wr_addr == 9 && wr_req) begin
            ctrl_pc_cfr_detect_threshold <= wr_data[16:0];
        end
    end

    always_ff @ (posedge clk) begin
        if (rst) begin
            ctrl_pc_cfr_clipping_threshold <= '1;
        end if (wr_addr == 10 && wr_req) begin
            ctrl_pc_cfr_clipping_threshold <= wr_data[16:0];
        end
    end

    always_ff @ (posedge clk) begin
        if (rst) begin
            ctrl_hc_enable <= 1'b0;
        end if (wr_addr == 11 && wr_req) begin
            ctrl_hc_enable <= wr_data[0];
        end
    end

    always_ff @ (posedge clk) begin
        if (rst) begin
            ctrl_hc_threshold <= '1;
        end if (wr_addr == 12 && wr_req) begin
            ctrl_hc_threshold <= wr_data[16:0];
        end
    end

    always_ff @ (posedge clk) begin
        if (rst) begin
            ctrl_pc_cfr_cpw_wr_en <= '0;
            ctrl_pc_cfr_cpw_wr_addr <= '0;
            ctrl_pc_cfr_cpw_wr_data_i <= '0;
            ctrl_pc_cfr_cpw_wr_data_q <= '0;
        end if (wr_addr >= 512 && wr_addr < 768 && wr_req) begin
            ctrl_pc_cfr_cpw_wr_en     <= 1'b1;
            ctrl_pc_cfr_cpw_wr_addr   <= wr_addr % 256;
            ctrl_pc_cfr_cpw_wr_data_i <= wr_data[15:0];
        end else if (wr_addr >= 768 && wr_addr < 1024 && wr_req) begin
            ctrl_pc_cfr_cpw_wr_en     <= 1'b1;
            ctrl_pc_cfr_cpw_wr_addr   <= wr_addr % 256;
            ctrl_pc_cfr_cpw_wr_data_q <= wr_data[15:0];
        end else begin
            ctrl_pc_cfr_cpw_wr_en <= 1'b0;
        end
    end

    // RD

    always_ff @ (posedge clk) begin
        if (rst) begin
            rd_data <= '0;
        end else if (rd_req) begin
            case (rd_addr)
                0       : rd_data <= ID;
                8       : rd_data <= {32'b0, ctrl_pc_cfr_enable};
                9       : rd_data <= {15'b0, ctrl_pc_cfr_detect_threshold};
                10      : rd_data <= {15'b0, ctrl_pc_cfr_clipping_threshold};
                11      : rd_data <= {31'b0, ctrl_hc_enable};
                12      : rd_data <= {15'b0, ctrl_hc_threshold};
                default : rd_data <= 32'hDEADBEEF;
            endcase
        end
    end

    // ACK

    always_ff @ (posedge clk) begin
        if (rst) begin
            wr_ack <= 1'b0;
        end else begin
            wr_ack <= wr_req;
        end
    end

    always_ff @ (posedge clk) begin
        if (rst) begin
            rd_ack <= 1'b0;
        end else begin
            rd_ack <= rd_req;
        end
    end

endmodule

`default_nettype wire
