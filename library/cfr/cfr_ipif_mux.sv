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

`timescale 1 ns / 1 ps `default_nettype none

module cfr_ipif_mux #(
    parameter int IPIF_ADDR_WIDTH = 15,
    parameter int IPIF_DATA_WIDTH = 32,
    //
    parameter int NUM_BRANCH      = 32
) (
    // IPIF Interface
    //---------------
    input  var                                          clk                     ,
    input  var                                          rst                     ,
    //
    input  var [                   IPIF_ADDR_WIDTH-1:0] wr_addr                 ,
    input  var                                          wr_req                  ,
    input  var [                   IPIF_DATA_WIDTH-1:0] wr_data                 ,
    output var                                          wr_ack                  ,
    //
    input  var [                   IPIF_ADDR_WIDTH-1:0] rd_addr                 ,
    input  var                                          rd_req                  ,
    output var [                   IPIF_DATA_WIDTH-1:0] rd_data                 ,
    output var                                          rd_ack                  ,
    // Registers
    //---------------
    output var [IPIF_ADDR_WIDTH-$clog2(NUM_BRANCH)-1:0] ipif_wr_addr[NUM_BRANCH],
    output var                                          ipif_wr_req [NUM_BRANCH],
    output var [                   IPIF_DATA_WIDTH-1:0] ipif_wr_data[NUM_BRANCH],
    input  var                                          ipif_wr_ack [NUM_BRANCH],
    //
    output var [IPIF_ADDR_WIDTH-$clog2(NUM_BRANCH)-1:0] ipif_rd_addr[NUM_BRANCH],
    output var                                          ipif_rd_req [NUM_BRANCH],
    input  var [                   IPIF_DATA_WIDTH-1:0] ipif_rd_data[NUM_BRANCH],
    input  var                                          ipif_rd_ack [NUM_BRANCH]
);

    localparam int ADDR_WIDTH_PER_BRANCH = IPIF_ADDR_WIDTH - $clog2(NUM_BRANCH-1);

    // WR

    generate
        for (genvar i = 0; i < NUM_BRANCH; i++) begin

            // wr_addr, wr_data
            always_ff @ (posedge clk) begin
                if (rst) begin
                    ipif_wr_addr[i] <= '0;
                    ipif_wr_data[i] <= '0;
                end else if ((wr_addr[IPIF_ADDR_WIDTH-1:ADDR_WIDTH_PER_BRANCH] == i) && wr_req) begin
                    ipif_wr_addr[i] <= wr_addr[ADDR_WIDTH_PER_BRANCH-1:0];
                    ipif_wr_data[i] <= wr_data;
                end
            end

            // wr_req
            always_ff @ (posedge clk) begin
                if (rst) begin
                    ipif_wr_req[i] <= 1'b0;
                end else begin
                    ipif_wr_req[i] <= (wr_addr[IPIF_ADDR_WIDTH-1:ADDR_WIDTH_PER_BRANCH] == i) && wr_req;
                end
            end

        end
    endgenerate

    always_ff @ (posedge clk) begin
        if (rst)begin
            wr_ack <= 1'b0;
        end else begin
            wr_ack <= ipif_wr_ack[wr_addr[IPIF_ADDR_WIDTH-1:ADDR_WIDTH_PER_BRANCH]];
        end
    end

    // RD

    generate
        for (genvar i = 0; i < NUM_BRANCH; i++) begin

            // rd_addr
            always_ff @ (posedge clk) begin
                if (rst) begin
                    ipif_rd_addr[i] <= '0;
                end else if ((rd_addr[IPIF_ADDR_WIDTH-1:ADDR_WIDTH_PER_BRANCH] == i) && rd_req) begin
                    ipif_rd_addr[i] <= rd_addr[ADDR_WIDTH_PER_BRANCH-1:0];
                end
            end

            // rd_req
            always_ff @ (posedge clk) begin
                if (rst) begin
                    ipif_rd_req[i] <= 1'b0;
                end else begin
                    ipif_rd_req[i] <= (rd_addr[IPIF_ADDR_WIDTH-1:ADDR_WIDTH_PER_BRANCH] == i) && rd_req;
                end
            end

        end
    endgenerate

    // rd_data, rd_ack
    always_ff @ (posedge clk) begin
        if (rst) begin
            rd_data <= '0;
            rd_ack  <= 1'b0;
        end else begin
            rd_data <= ipif_rd_data[rd_addr[IPIF_ADDR_WIDTH-1:ADDR_WIDTH_PER_BRANCH]];
            rd_ack  <= ipif_rd_ack [rd_addr[IPIF_ADDR_WIDTH-1:ADDR_WIDTH_PER_BRANCH]];
        end
    end

endmodule

`default_nettype wire
