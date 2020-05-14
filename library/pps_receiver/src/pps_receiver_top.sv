/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module pps_receiver_top #(parameter C_CLOCK_FREQUENCY = 25000000) (
    // Core clock domain
    //----------------------
    // Clock & Reset
    input  var logic ptp_clk,
    // External 1PPS in
    input  var logic pps_in ,
    // 1PPS to Fabric
    output var logic pps_out,
    // 1kHz to Fabric
    output var logic ts_out
);

    // Clock Buffer
    //=============

    wire clk;

    BUFR #(
        .BUFR_DIVIDE("BYPASS" ),
        .SIM_DEVICE ("7SERIES")
    ) BUFR_inst (
        .I  (ptp_clk),
        .CE (1'b1   ),
        .CLR(1'b0   ),
        .O  (clk    )
    );

    // PPS input CDC
    //==============
    // Standard 2-async FF structure to capture PPS input from external input

    (* ASYNC_REG="true" *)
    var logic pps_cdc_reg1, pps_cdc_reg2;

    var logic pps_d      ;
    var logic pps_posedge;

    always_ff @ (posedge clk) begin
        pps_cdc_reg1 <= pps_in;
        pps_cdc_reg2 <= pps_cdc_reg1;
    end

    always_ff @ (posedge clk) begin
        pps_d <= pps_cdc_reg2;
    end

    assign pps_posedge = {pps_cdc_reg2, pps_d} == 2'b10;


    // ADV/LATE adjust
    //================
    // There will be 1 clock uncertainty when capture async input. That is
    // if we see posedge at this clock, the accurate posedge can be at range
    // (-1, +1) clock. We won't adjust the internal PPS if we see the posege
    // within this range. However, to determine which clock is the best
    // estimation within these 3 ticks, we count on which tick we see the
    // posedge more frequently.

    var logic [$clog2(C_CLOCK_FREQUENCY-1)-1:0] pps_counter    ;
    var logic [$clog2(C_CLOCK_FREQUENCY-1)-1:0] last_pha    = 0;

    var logic match, late_by1, adv_by1;

    var logic [3:0] adv_cnt, late_cnt;

    // `pps_counter` is a free running counter that count for 1s at current
    // clock frequency.
    always_ff @ (posedge clk) begin
        pps_counter <= (pps_counter >= C_CLOCK_FREQUENCY - 1) ? 'd0 :
            pps_counter + 1;
    end

    // We capture the PPS's posedge at same tick of last capture
    assign match = (pps_counter == last_pha);

    // We capture the PPS's posedge one tick advance than last capture
    assign adv_by1 = (last_pha - pps_counter == 1) ||
        (pps_counter - last_pha == C_CLOCK_FREQUENCY - 1);

    // We capture the PPS's posedge one tick later than last capture
    assign late_by1 = (pps_counter - last_pha == 1) ||
        (last_pha - pps_counter == C_CLOCK_FREQUENCY - 1);

    // To determine which tick (1 clock advanced tick, current tick, 1 clock
    // late tick) is the best estimation of PPS time. We counter for if we see
    // PPS's posedge on advanced tick or late tick more time. If any counter
    // reach 15, we adjust the internal PPS. If we see PPS out of the (-1, +1)
    // range, adjust the internall PPS immediately.
    always_ff @ (posedge clk) begin
        // Default
        adv_cnt  <= adv_cnt;
        late_cnt <= late_cnt;
        last_pha <= last_pha;
        //
        if (pps_posedge) begin
            if (match) begin
                // Current count is equal to last count
                if (adv_cnt > 0) adv_cnt  <= adv_cnt - 1;
                if (late_cnt > 0) late_cnt <= late_cnt - 1;
            end else if (adv_by1) begin
                // Current count is 1 less than last count
                if (late_cnt > 0) late_cnt <= late_cnt - 1;
                adv_cnt <= adv_cnt + 1;
                if (&adv_cnt) last_pha <= pps_counter;
            end else if (late_by1) begin
                // Current count is 1 more than last count
                if (adv_cnt > 0) adv_cnt  <= adv_cnt - 1;
                late_cnt <= late_cnt + 1;
                if (&late_cnt) last_pha <= pps_counter;
            end else begin
                // Current count is 1 more different than last count
                adv_cnt  <= 0;
                late_cnt <= 0;
                last_pha <= pps_counter;
            end
        end
    end

    always_ff @ (posedge clk) begin
        pps_out <= match;
    end

    // TS generation
    //==============
    // We need this since the period of PPS is long (1s). If we are using
    // another async clock to capture this PPS, due to clock frequency error,
    // it will be a large integrating error during 1s. Say 50 ppm, it will be
    // 50us after 1s. Reduce the period will reduce this error.
    // 1 kHZ pulse is chosen.

    var logic [$clog2(C_CLOCK_FREQUENCY/1000-1)-1:0] ts_counter    ;

    always_ff @ (posedge clk) begin
        if (match) begin
            ts_counter <= 0;
        end  else begin
            ts_counter <= (ts_counter >= C_CLOCK_FREQUENCY/1000 - 1) ? 0 :
                ts_counter + 1;
        end
    end

    always_ff @ (posedge clk) begin
        if (match) begin
            ts_out <= 1'b1;
        end else begin
            ts_out <= (ts_counter >= C_CLOCK_FREQUENCY/1000 - 1);
        end
    end

endmodule

`default_nettype wire
