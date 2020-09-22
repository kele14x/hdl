/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

// AXI Trigger Subsystem
module axi_ts_core (
    input  var logic        clk                     ,
    input  var logic        rst                     ,
    // Other module
    //-------------
    // RTC
    input  var logic [31:0] rtc_sec                 ,
    input  var logic [31:0] rtc_nsec                ,
    // External trigger
    input  var logic [ 7:0] ext_trigger             ,
    // Device action
    output var logic        measure_start           ,
    input  var logic        measure_ready           ,
    input  var logic        measure_idle            ,
    input  var logic        measure_done            ,
    // Control
    //--------
    // Overall
    input  var logic        ctrl_abort              ,
    // Idle & Init state control
    input  var logic        ctrl_init_immediate     ,
    input  var logic        ctrl_init_continuous    ,
    // Arm state control
    input  var logic        ctrl_arm_immediate      ,
    input  var logic [31:0] ctrl_arm_source         ,
    input  var logic [31:0] ctrl_arm_count          ,
    // Trigger state control
    input  var logic        ctrl_trigger_immediate  ,
    input  var logic [31:0] ctrl_trigger_source     ,
    input  var logic [31:0] ctrl_trigger_count      ,
    // State
    //------
    // Measure state control
    output var logic        stat_operation_complete ,
    output var logic        stat_sweeping           ,
    output var logic        stat_waiting_for_arm    ,
    output var logic        stat_waiting_for_trigger,
    output var logic        stat_measuring
);


    typedef enum {
        S_RST           , // Under rest, fault recovery
        S_IDLE          , // Idle, waiting for init
        S_INITIATED_DOWN, // Initiated, going downward
        S_INITIATED_UP  , // Initiated, going upward
        S_ARM_DOWN      , // Waiting for arm
        S_ARM_UP        , // Check arm count
        S_TRIGGER_DOWN  , // Waiting for trigger
        S_TRIGGER_UP    , // Check trigger count
        S_MEASURE_START , // Start measuring, wait action ready
        S_MEASURE_WAIT    // Measuring, wait action done
    } AT_STATE_T;

    AT_STATE_T state, state_next;


    logic [31:0] arm_count, trigger_count;
    logic        arm_wire, trigger_wire;

    always_ff @ (posedge clk) begin
        if (rst) begin
            state <= S_RST;
        end else begin
            state <= state_next;
        end
    end

    always_comb begin
        if (ctrl_abort) begin
            state_next = S_IDLE;
        end else begin
            case (state)
                S_RST            : state_next = S_IDLE;
                //
                S_IDLE           : state_next = (ctrl_init_immediate || ctrl_init_continuous) ? S_INITIATED_DOWN : S_IDLE;
                //
                S_INITIATED_DOWN : state_next = S_ARM_DOWN;
                S_INITIATED_UP   : state_next = ctrl_init_continuous ? S_ARM_DOWN : S_IDLE;
                //
                S_ARM_DOWN       : state_next = arm_wire ? S_TRIGGER_DOWN : S_ARM_DOWN;
                S_ARM_UP         : state_next = (arm_count >= ctrl_arm_count) ? S_INITIATED_DOWN : S_ARM_DOWN;
                //
                S_TRIGGER_DOWN   : state_next = trigger_wire ? S_MEASURE_START : S_TRIGGER_DOWN;
                S_TRIGGER_UP     : state_next = (trigger_count >= ctrl_trigger_count) ? S_ARM_UP : S_TRIGGER_DOWN;
                //
                S_MEASURE_START  : state_next = measure_ready ? S_MEASURE_WAIT : S_MEASURE_START;
                S_MEASURE_WAIT   : state_next = measure_done ? S_TRIGGER_UP : S_MEASURE_WAIT;
                //
                default          : state_next = S_RST;
            endcase // state
        end
    end


    // Measure start

    always_ff @ (posedge clk) begin
        if (rst) begin
            measure_start <= 1'b0;
        end else begin
            measure_start <= (state_next == S_MEASURE_START);
        end
    end


    // Arm and trigger wire

    always_ff @ (posedge clk) begin
        if (rst) begin
            arm_wire <= 1'b0;
        end else begin
            arm_wire <= (ctrl_arm_immediate);
        end
    end

    always_ff @ (posedge clk) begin
        if (rst) begin
            trigger_wire <= 1'b0;
        end else begin
            trigger_wire <= (ctrl_trigger_immediate);
        end
    end


    //

    always_ff @ (posedge clk) begin
        if (rst) begin
            arm_count <= 'd0;
        end else if (
            (state_next == S_ARM_DOWN     ) ||
            (state_next == S_TRIGGER_DOWN ) ||
            (state_next == S_TRIGGER_UP   ) ||
            (state_next == S_MEASURE_START) ||
            (state_next == S_MEASURE_WAIT )
        ) begin
            arm_count <= arm_count;
        end else if (state_next == S_ARM_UP) begin
            arm_count <= arm_count + 1;
        end else begin
            arm_count <= 'd0;
        end
    end


    always_ff @ (posedge clk) begin
        if (rst) begin
            trigger_count <= 'd0;
        end else if (
            (state_next == S_TRIGGER_DOWN ) ||
            (state_next == S_MEASURE_START) ||
            (state_next == S_MEASURE_WAIT )
        ) begin
            trigger_count <= trigger_count;
        end else if (state_next == S_TRIGGER_UP) begin
            trigger_count <= trigger_count + 1;
        end else begin
            trigger_count <= 'd0;
        end
    end

    // Status output

    always_ff @ (posedge clk) begin
        if (rst) begin
            stat_operation_complete <= 1'b0;
        end else begin
            stat_operation_complete <= (state_next == S_IDLE);
        end
    end

    always_ff @ (posedge clk) begin
        if (rst) begin
            stat_sweeping <= 1'b0;
        end else begin
            stat_sweeping <= (
                (state_next == S_ARM_DOWN     ) ||
                (state_next == S_ARM_UP       ) ||
                (state_next == S_TRIGGER_DOWN ) ||
                (state_next == S_TRIGGER_UP   ) ||
                (state_next == S_MEASURE_START) ||
                (state_next == S_MEASURE_WAIT ));
        end
    end


    always_ff @ (posedge clk) begin
        if (rst) begin
            stat_waiting_for_arm <= 1'b0;
        end else begin
            stat_waiting_for_arm <= (
                (state_next == S_ARM_DOWN     ) ||
                (state_next == S_TRIGGER_DOWN ) ||
                (state_next == S_TRIGGER_UP   ) ||
                (state_next == S_MEASURE_START) ||
                (state_next == S_MEASURE_WAIT ));
        end
    end


    always_ff @ (posedge clk) begin
        if (rst) begin
            stat_waiting_for_trigger <= 1'b0;
        end else begin
            stat_waiting_for_trigger <= (state_next == S_TRIGGER_DOWN);
        end
    end

    always_ff @ (posedge clk) begin
        if (rst) begin
            stat_measuring <= 1'b0;
        end else begin
            stat_measuring <= (
                (state_next == S_MEASURE_START) ||
                (state_next == S_MEASURE_WAIT ));
        end
    end

endmodule

`default_nettype wire
