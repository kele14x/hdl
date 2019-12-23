/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module pps_receiver #(parameter C_CLOCK_FREQUENCY = 125000000) (
    // Core clock domain
    //----------------------
    // Clock & Reset
    input  wire        clk            ,
    input  wire        rst            ,
    // External 1PPS in
    input  wire        pps_in         ,
    // 1PPS to Fabric
    output reg         pps_out        ,
    // Monitor Clock domain (Maybe asynchronous with core clock)
    //----------------------------------------------------------
    input  wire        aclk           ,
    input  wire        aresetn        ,
    // Status
    output reg  [31:0] stat_pps_phase ,
    output wire        stat_pps_status,
    // IQR
    output reg         iqr_pps_posedge
);

    initial begin
        if ($clog2(C_CLOCK_FREQUENCY-1) > 32)
            $warning("Core clock frequency too slow, which makes the 1 PPS counter exist 32-bit width");
    end

    // CDC
    //=====

    (* ASYNC_REG="true" *)
        reg pps_cdc_reg1, pps_cdc_reg2;
    reg  pps_d      ;
    wire pps_posedge;

    always_ff @ (posedge clk) begin
        pps_cdc_reg1 <= pps_in;
        pps_cdc_reg2 <= pps_cdc_reg1;
    end

    always_ff @ (posedge clk) begin
        pps_d <= pps_cdc_reg2;
    end

    assign pps_posedge = {pps_cdc_reg2, pps_d} == 2'b10;


    // ADC/LATE adjust
    //================

    reg [$clog2(C_CLOCK_FREQUENCY-1)-1:0] free_counter    ;
    reg [$clog2(C_CLOCK_FREQUENCY-1)-1:0] last_pha     = 0;

    wire match, late_by1, adv_by1;

    reg [3:0] adv_cnt, late_cnt;

    // `free_counter` is a free running counter that count for 1s at current
    // clock frequency.
    always_ff @ (posedge clk) begin
        free_counter <= (rst || free_counter == C_CLOCK_FREQUENCY-1) ? 'd0 :
            free_counter + 1;
    end

    assign match = (free_counter == last_pha);

    assign adv_by1 = (last_pha - free_counter == 1) ||
        (free_counter - last_pha == C_CLOCK_FREQUENCY - 1);

    assign late_by1 = (free_counter - last_pha == 1) ||
        (last_pha - free_counter == C_CLOCK_FREQUENCY - 1);

    always_ff @ (posedge clk) begin
        if (rst) begin
            adv_cnt  <= 'd0;
            late_cnt <= 'd0;
            last_pha <= 'd0;
        end else begin
            if (pps_posedge) begin
                if (match) begin
                    // Current count is equal to last count
                    adv_cnt  <= adv_cnt == 0 ? adv_cnt : adv_cnt + 1;
                    late_cnt <= late_cnt == 0 ? late_cnt : late_cnt + 1;
                end else if (adv_by1) begin
                    // Current count is 1 less than last count
                    late_cnt <= late_cnt == 0 ? late_cnt : late_cnt + 1;
                    adv_cnt  <= adv_cnt + 1;
                    if (adv_cnt == 15) last_pha <= free_counter;
                end else if (late_by1) begin
                    // Current count is 1 more than last count
                    adv_cnt  <= adv_cnt == 0 ? adv_cnt : adv_cnt + 1;
                    late_cnt <= late_cnt + 1;
                    if (late_cnt == 15) last_pha <= free_counter;
                end else begin
                    // Current count is 1 more different than last count
                    adv_cnt  <= 0;
                    late_cnt <= 0;
                    last_pha <= free_counter;
                end
            end
        end
    end

    always_ff @ (posedge clk) begin
        pps_out <= match;
    end

    // PPS Status track
    //=================

    reg pps_posedge_d, pps_posedge_dd;

    reg pps_status;

    always_ff @ (posedge clk) begin
        pps_posedge_d  <= pps_posedge;
        pps_posedge_dd <= pps_posedge_d;
    end

    always_ff @ (posedge clk) begin
        if (rst) begin
            pps_status <= 1'b0;
        end else if (pps_posedge) begin
            pps_status <= (match || adv_by1 || late_by1);
        end else if (late_by1) begin
            pps_status <= (pps_posedge || pps_posedge_d || pps_posedge_dd);
        end
    end


    // Status CDC
    //===========

    reg [2:0] pps_out_ext;
    reg       pps_out_pre;

    wire pps_out_cdc        ;
    reg  pps_out_cdc_d      ;
    wire pps_out_cdc_posedge;

    always_ff @ (posedge clk) begin
        pps_out_ext <= {pps_out_ext[1:0], late_by1};
        pps_out_pre <= |pps_out_ext;
    end

    cdc_bits i_pps_posedge_cdc (
        .din    (pps_out_pre),
        .out_clk(aclk       ),
        .dout   (pps_out_cdc)
    );

    always_ff @ (posedge aclk) begin
        pps_out_cdc_d <= pps_out_cdc;
    end

    assign pps_out_cdc_posedge = ({pps_out_cdc, pps_out_cdc_d} == 2'b10);

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            stat_pps_phase <= 32'd0;
        end else if (pps_out_cdc_posedge) begin
            stat_pps_phase <= last_pha;
        end
    end

    cdc_bits i_pps_status_cdc (
        .din    (pps_status     ),
        .out_clk(aclk           ),
        .dout   (stat_pps_status)
    );

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            iqr_pps_posedge <= 1'b0;
        end else begin
            iqr_pps_posedge <= pps_out_cdc_posedge;
        end
    end


endmodule
