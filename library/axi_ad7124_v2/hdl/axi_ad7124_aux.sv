/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 100 ps
`default_nettype none

module axi_ad7124_aux #(parameter NUM_OF_BOARD = 6) (
    // UP I/F
    //=======
    input  var logic                    up_clk                 ,
    input  var logic                    up_rstn                ,
    //
    input  var logic                    up_wreq                ,
    input  var logic [            13:0] up_waddr               ,
    input  var logic [            31:0] up_wdata               ,
    output var logic                    up_wack                ,
    //
    input  var logic                    up_rreq                ,
    input  var logic [            13:0] up_raddr               ,
    output var logic [            31:0] up_rdata               ,
    output var logic                    up_rack                ,
    // Control
    //========
    output var logic [NUM_OF_BOARD-1:0] ctrl_power_en          , // 1 = Power on, 0 = Power off
    output var logic [NUM_OF_BOARD-1:0] ctrl_relay_ctrl        , // 1 = Calibration, 0 = Normal op
    //
    output var logic                    ctrl_reset             ,
    output var logic [             5:0] ctrl_board_mask        ,
    //
    output var logic                    ctrl_measure_immediate ,
    output var logic                    ctrl_measure_continuous,
    output var logic [            31:0] ctrl_measure_count     ,
    input  var logic [             2:0] stat_measure_state     ,
    //
    output var logic                    ctrl_fifo_read         ,
    input  var logic [            31:0] stat_fifo_data         ,
    input  var logic                    stat_fifo_empty
);


    localparam [31:0] PCORE_VERSION = 32'h20200926;
    localparam [31:0] ID            = 0           ;


    logic [31:0] up_scratch = 'h0;


    //--------------------------------------------------------------------------
    // Write

    // up_scratch at 2
    always @(posedge up_clk) begin
        if (~up_rstn) begin
            up_scratch <= 'h00;
        end else if (up_wreq && up_waddr == 'd02) begin
            up_scratch <= up_wdata;
        end
    end

    generate 
        for (genvar i = 0; i < 6; i++) begin
            // ctrl_power_en at 16 + i
            always @(posedge up_clk) begin
                if (~up_rstn) begin
                    ctrl_power_en[i] <= 'b0;
                end else if (up_wreq && up_waddr == ('d16 + i)) begin
                    ctrl_power_en[i] <= up_wdata[0];
                end
            end
        end
    endgenerate

    generate 
        for (genvar i = 0; i < 6; i++) begin
            // ctrl_relay_ctrl at 24 + i
            always @(posedge up_clk) begin
                if (~up_rstn) begin
                    ctrl_relay_ctrl[i] <= 'b0;
                end else if (up_wreq && up_waddr == ('d24 + i)) begin
                    ctrl_relay_ctrl[i] <= up_wdata[0];
                end
            end
        end
    endgenerate

    // ctrl_reset at 32
    always @(posedge up_clk) begin
        if (~up_rstn) begin
            ctrl_reset <= 'b0;
        end else if (up_wreq && up_waddr == 'd32) begin
            ctrl_reset <= up_wdata[0];
        end
    end

    // ctrl_board_mask at 33
    always @(posedge up_clk) begin
        if (~up_rstn) begin
            ctrl_board_mask <= 'b0;
        end else if (up_wreq && up_waddr == 'd33) begin
            ctrl_board_mask <= up_wdata[5:0];
        end
    end

    // ctrl_measure_immediate at 40
    always @(posedge up_clk) begin
        if (~up_rstn) begin
            ctrl_measure_immediate <= 'b0;
        end else if (up_wreq && up_waddr == 'd40) begin
            ctrl_measure_immediate <= up_wdata[0];
        end else begin
            ctrl_measure_immediate <= 'b0;
        end
    end

    // ctrl_measure_continuous at 41
    always @(posedge up_clk) begin
        if (~up_rstn) begin
            ctrl_measure_continuous <= 'b0;
        end else if (up_wreq && up_waddr == 'd41) begin
            ctrl_measure_continuous <= up_wdata[0];
        end
    end

    // ctrl_measure_count at 42
    always @(posedge up_clk) begin
        if (~up_rstn) begin
            ctrl_measure_count <= 'b0;
        end else if (up_wreq && up_waddr == 'd42) begin
            ctrl_measure_count <= up_wdata;
        end
    end

    //--------------------------------------------------------------------------
    // Read out

    always @(posedge up_clk) begin
        if (~up_rstn) begin
            up_rdata <= 'b0;
        end else if (up_rreq) begin
            case (up_raddr)
                'd0     : up_rdata <= PCORE_VERSION;
                'd1     : up_rdata <= ID;
                'd2     : up_rdata <= up_scratch;
                'd16    : up_rdata <= {31'b0, ctrl_power_en[0]};
                'd17    : up_rdata <= {31'b0, ctrl_power_en[1]};
                'd18    : up_rdata <= {31'b0, ctrl_power_en[2]};
                'd19    : up_rdata <= {31'b0, ctrl_power_en[3]};
                'd20    : up_rdata <= {31'b0, ctrl_power_en[4]};
                'd21    : up_rdata <= {31'b0, ctrl_power_en[5]};
                'd24    : up_rdata <= {26'b0, ctrl_relay_ctrl[0]};
                'd25    : up_rdata <= {26'b0, ctrl_relay_ctrl[1]};
                'd26    : up_rdata <= {26'b0, ctrl_relay_ctrl[2]};
                'd27    : up_rdata <= {26'b0, ctrl_relay_ctrl[3]};
                'd28    : up_rdata <= {26'b0, ctrl_relay_ctrl[4]};
                'd29    : up_rdata <= {26'b0, ctrl_relay_ctrl[5]};
                'd32    : up_rdata <= {31'b0, ctrl_reset};
                'd33    : up_rdata <= {26'd0, ctrl_board_mask};
                'd41    : up_rdata <= {31'b0, ctrl_measure_continuous};
                'd42    : up_rdata <= ctrl_measure_count;
                'd43    : up_rdata <= {29'b0, stat_measure_state};
                'd48    : up_rdata <= {31'b0, stat_fifo_empty};
                'd49    : up_rdata <= stat_fifo_data;
                default : up_rdata <= 32'h00000000;
            endcase
        end
    end

    // ctrl_fifo_read at 49
    always @(posedge up_clk) begin
        if (~up_rstn) begin
            ctrl_fifo_read <= 1'b0;
        end else if (up_rreq && up_raddr == 'd49) begin
            ctrl_fifo_read <= 1'b1;
        end else begin
            ctrl_fifo_read <= 1'b0;
        end
    end

    //--------------------------------------------------------------------------
    // ACK

    always @(posedge up_clk) begin
        if (~up_rstn) begin
            up_wack <= 1'b0;
        end else begin
            up_wack <= up_wreq;
        end
    end

    always @(posedge up_clk) begin
        if (~up_rstn) begin
            up_rack <= 1'b0;
        end else begin
            up_rack <= up_rreq;
        end
    end

endmodule

`default_nettype wire
