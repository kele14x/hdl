/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

// AXI Trigger Subsystem
module axi_ts_top #(parameter int AXI_ADDR_WIDTH = 12) (
    input  var logic                      aclk                    ,
    input  var logic                      aresetn                 ,
    //
    input  var logic [AXI_ADDR_WIDTH-1:0] s_axi_awaddr            ,
    input  var logic [               2:0] s_axi_awprot            ,
    input  var logic                      s_axi_awvalid           ,
    output var logic                      s_axi_awready           ,
    //
    input  var logic [              31:0] s_axi_wdata             ,
    input  var logic [               3:0] s_axi_wstrb             ,
    input  var logic                      s_axi_wvalid            ,
    output var logic                      s_axi_wready            ,
    //
    output var logic [               1:0] s_axi_bresp             ,
    output var logic                      s_axi_bvalid            ,
    input  var logic                      s_axi_bready            ,
    //
    input  var logic [AXI_ADDR_WIDTH-1:0] s_axi_araddr            ,
    input  var logic [               2:0] s_axi_arprot            ,
    input  var logic                      s_axi_arvalid           ,
    output var logic                      s_axi_arready           ,
    //
    output var logic [              31:0] s_axi_rdata             ,
    output var logic [               1:0] s_axi_rresp             ,
    output var logic                      s_axi_rvalid            ,
    input  var logic                      s_axi_rready            ,
    // Other module
    //-------------
    // RTC
    input  var logic [              31:0] rtc_sec                 ,
    input  var logic [              31:0] rtc_nsec                ,
    // External trigger
    input  var logic [               7:0] ext_trigger             ,
    // Device action
    output var logic                      measure_start           ,
    input  var logic                      measure_ready           ,
    input  var logic                      measure_idle            ,
    input  var logic                      measure_done            ,
    // Control
    //--------
    // Overall
    input  var logic                      ctrl_abort              ,
    // Idle & Init state control
    input  var logic                      ctrl_init_immediate     ,
    input  var logic                      ctrl_init_continuous    ,
    // Arm state control
    input  var logic                      ctrl_arm_immediate      ,
    input  var logic                      ctrl_arm_source         ,
    input  var logic [              31:0] ctrl_arm_count          ,
    // Trigger state control
    input  var logic                      ctrl_trigger_immediate  ,
    input  var logic                      ctrl_trigger_source     ,
    input  var logic [              31:0] ctrl_trigger_count      ,
    // State
    //------
    // Measure state control
    output var logic                      stat_operation_complete ,
    output var logic                      stat_sweeping           ,
    output var logic                      stat_waiting_for_arm    ,
    output var logic                      stat_waiting_for_trigger,
    output var logic                      stat_measuring
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
        S_MEASURING       // Measuring, wait action done
    } AT_STATE_T;

    AT_STATE_T state, state_next;


    logic [31:0] arm_count, trigger_count;
    logic arm_wire, trigger_wire;

    always_ff @ (posedge aclk) begin
        if (~aresetn) begin
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
                S_TRIGGER_DOWN   : state_next = trigger_wire ? S_MEASURING : S_TRIGGER_DOWN;
                S_TRIGGER_UP     : state_next = (trigger_count >= ctrl_trigger_count) ? S_ARM_UP : S_TRIGGER_DOWN;
                //
                S_MEASURING      : state_next = measure_done ? S_TRIGGER_UP : S_MEASURING;
                //
                default          : state_next = S_RST;
            endcase // state
        end
    end

    always_ff @ (posedge aclk) begin
        if (~aresetn) begin
            stat_operation_complete <= 1'b0;
        end else begin
            stat_operation_complete <= (state_next == S_IDLE);
        end
    end

    always_ff @ (posedge aclk) begin
        if (~aresetn) begin
            stat_sweeping <= 1'b0;
        end else begin
            stat_sweeping <= ((state_next == S_ARM_DOWN) ||
                (state_next == S_ARM_UP) || (state_next == S_TRIGGER_DOWN) ||
                (state_next == S_TRIGGER_UP) || (state_next == S_MEASURING));
        end
    end

endmodule

`default_nettype wire
