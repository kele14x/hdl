/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module up_bram_top #(
    parameter C_ADDR_WIDTH = 10,
    parameter C_DATA_WIDTH = 32
) (
    input  var logic                      clk       ,
    input  var logic                      rst       ,
    //
    input  var logic [  C_ADDR_WIDTH-1:0] up_wr_addr,
    input  var logic [C_DATA_WIDTH/8-1:0] up_wr_be  ,
    input  var logic                      up_wr_req ,
    input  var logic [  C_DATA_WIDTH-1:0] up_wr_din ,
    output var logic                      up_wr_ack ,
    //
    input  var logic [  C_ADDR_WIDTH-1:0] up_rd_addr,
    input  var logic                      up_rd_req ,
    output var logic [  C_DATA_WIDTH-1:0] up_rd_dout,
    output var logic                      up_rd_ack
);

    var logic [C_DATA_WIDTH-1:0] mem [0:(2**C_ADDR_WIDTH)-1];
    var logic rd_req_d;
    var logic [C_DATA_WIDTH-1:0] rd_temp;

    // Initialize memory to all zeros
    initial begin
        for (int i = 0; i < 2**C_ADDR_WIDTH; i++) begin
            mem[i] = 'd0;
        end
    end

    // Write to memory

    always_ff @ (posedge clk) begin
        if (up_wr_req) begin
            for (int i = 0; i < C_DATA_WIDTH/8; i++) begin
                if (up_wr_be[i]) begin
                    mem[up_wr_addr][i*8+7-:8] <= up_wr_din[i*8+7-:8];
                end
            end
        end
    end

    // Write ACK

    always_ff @ (posedge clk) begin
        if (rst) begin
            up_wr_ack <= 1'b0;
        end else begin
            up_wr_ack <= up_wr_req;
        end
    end

    // Read from memory

    always_ff @ (posedge clk) begin
        rd_req_d  <= up_rd_req;
    end

    always_ff @ (posedge clk) begin
        if (up_rd_req) begin
            rd_temp <= mem[up_rd_addr];
        end
    end

    always_ff @ (posedge clk) begin
        if (rst) begin
            up_rd_dout <= 'd0;
        end else if (rd_req_d) begin
            up_rd_dout <= rd_temp;
        end
    end

    // Read ACK

    always_ff @ (posedge clk) begin
        if (rst) begin
            up_rd_ack <= 1'b0;
        end else begin
            up_rd_ack <= rd_req_d;
        end
    end

endmodule
