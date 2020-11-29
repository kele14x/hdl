`timescale 1ns / 1ps

module tb_cordiccart2pol();

    parameter ITERATIONS = 7;
    parameter DATA_WIDTH = 16;

    logic                         clk  ;
    logic                         rst  ;
    //
    logic signed [DATA_WIDTH-1:0] xin  ;
    logic signed [DATA_WIDTH-1:0] yin  ;
    //
    logic        [  ITERATIONS:0] theta;
    logic        [  DATA_WIDTH:0] r    ;

    always begin
        clk = 0;
        #5;
        clk = 1;
        #5;
    end

    initial begin
        rst = 1;
        #100;
        rst = 0;
    end

    initial begin
        wait (rst == 0);
        @(posedge clk);
        xin <= 10000;
        yin <= 0;
        @(posedge clk);
        xin <= 0;
        yin <= 0;
    end

    cordiccart2pol #(
        .ITERATIONS(ITERATIONS),
        .DATA_WIDTH(DATA_WIDTH)
    ) i_cordiccart2pol (
        .clk  (clk  ),
        .rst  (rst  ),
        .xin  (xin  ),
        .yin  (yin  ),
        .theta(theta),
        .r    (r    )
    );

endmodule
