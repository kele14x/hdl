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
    input  var logic                      ext_trigger             ,
    // Device action
    output var logic                      measure_start           ,
    input  var logic                      measure_ready           ,
    input  var logic                      measure_done            
);


    logic                      up_wreq ;
    logic [AXI_ADDR_WIDTH-3:0] up_waddr;
    logic [              31:0] up_wdata;
    logic                      up_wack ;
    //
    logic                      up_rreq ;
    logic [AXI_ADDR_WIDTH-3:0] up_raddr;
    logic [              31:0] up_rdata;
    logic                      up_rack ;


    logic ctrl_abort;

    // Idle & Init state control
    logic ctrl_init_immediate ;
    logic ctrl_init_continuous;

    // Arm state control
    logic        ctrl_arm_immediate;
    logic [31:0] ctrl_arm_source   ;
    logic [31:0] ctrl_arm_count    ;

    // Trigger state control
    logic        ctrl_trigger_immediate;
    logic [31:0] ctrl_trigger_source   ;
    logic [31:0] ctrl_trigger_count    ;

    // Measure state control
    logic stat_operation_complete ;
    logic stat_sweeping           ;
    logic stat_waiting_for_arm    ;
    logic stat_waiting_for_trigger;
    logic stat_measuring          ;


    (* keep_hierarchy="yes" *)
    up_axi #(.AXI_ADDRESS_WIDTH(AXI_ADDR_WIDTH)) i_up_axi (
        .up_clk        (aclk         ),
        .up_rstn       (aresetn      ),
        //
        .up_axi_awvalid(s_axi_awvalid),
        .up_axi_awaddr (s_axi_awaddr ),
        .up_axi_awready(s_axi_awready),
        //
        .up_axi_wvalid (s_axi_wvalid ),
        .up_axi_wdata  (s_axi_wdata  ),
        .up_axi_wstrb  (s_axi_wstrb  ),
        .up_axi_wready (s_axi_wready ),
        //
        .up_axi_bvalid (s_axi_bvalid ),
        .up_axi_bresp  (s_axi_bresp  ),
        .up_axi_bready (s_axi_bready ),
        //
        .up_axi_arvalid(s_axi_arvalid),
        .up_axi_araddr (s_axi_araddr ),
        .up_axi_arready(s_axi_arready),
        //
        .up_axi_rvalid (s_axi_rvalid ),
        .up_axi_rresp  (s_axi_rresp  ),
        .up_axi_rdata  (s_axi_rdata  ),
        .up_axi_rready (s_axi_rready ),
        //
        .up_wreq       (up_wreq      ),
        .up_waddr      (up_waddr     ),
        .up_wdata      (up_wdata     ),
        .up_wack       (up_wack      ),
        //
        .up_rreq       (up_rreq      ),
        .up_raddr      (up_raddr     ),
        .up_rdata      (up_rdata     ),
        .up_rack       (up_rack      )
    );


    (* keep_hierarchy="yes" *)
    axi_ts_regs #(.ADDR_WIDTH(AXI_ADDR_WIDTH-2)) i_axi_ts_regs (
        .up_clk                  (aclk                    ),
        .up_rstn                 (aresetn                 ),
        //
        .up_wreq                 (up_wreq                 ),
        .up_waddr                (up_waddr                ),
        .up_wdata                (up_wdata                ),
        .up_wack                 (up_wack                 ),
        //
        .up_rreq                 (up_rreq                 ),
        .up_raddr                (up_raddr                ),
        .up_rdata                (up_rdata                ),
        .up_rack                 (up_rack                 ),
        //
        .ctrl_abort              (ctrl_abort              ),
        .ctrl_init_immediate     (ctrl_init_immediate     ),
        .ctrl_init_continuous    (ctrl_init_continuous    ),
        .ctrl_arm_immediate      (ctrl_arm_immediate      ),
        .ctrl_arm_source         (ctrl_arm_source         ),
        .ctrl_arm_count          (ctrl_arm_count          ),
        .ctrl_trigger_immediate  (ctrl_trigger_immediate  ),
        .ctrl_trigger_source     (ctrl_trigger_source     ),
        .ctrl_trigger_count      (ctrl_trigger_count      ),
        //
        .stat_operation_complete (stat_operation_complete ),
        .stat_sweeping           (stat_sweeping           ),
        .stat_waiting_for_arm    (stat_waiting_for_arm    ),
        .stat_waiting_for_trigger(stat_waiting_for_trigger),
        .stat_measuring          (stat_measuring          )
    );


    axi_ts_core i_axi_ts_core (
        .clk                     (aclk                    ),
        .rst                     (~aresetn                ),
        //
        .rtc_sec                 (rtc_sec                 ),
        .rtc_nsec                (rtc_nsec                ),
        //
        .ext_trigger             (ext_trigger             ),
        //
        .measure_start           (measure_start           ),
        .measure_ready           (measure_ready           ),
        .measure_done            (measure_done            ),
        //
        .ctrl_abort              (ctrl_abort              ),
        .ctrl_init_immediate     (ctrl_init_immediate     ),
        .ctrl_init_continuous    (ctrl_init_continuous    ),
        .ctrl_arm_immediate      (ctrl_arm_immediate      ),
        .ctrl_arm_source         (ctrl_arm_source         ),
        .ctrl_arm_count          (ctrl_arm_count          ),
        .ctrl_trigger_immediate  (ctrl_trigger_immediate  ),
        .ctrl_trigger_source     (ctrl_trigger_source     ),
        .ctrl_trigger_count      (ctrl_trigger_count      ),
        .stat_operation_complete (stat_operation_complete ),
        .stat_sweeping           (stat_sweeping           ),
        .stat_waiting_for_arm    (stat_waiting_for_arm    ),
        .stat_waiting_for_trigger(stat_waiting_for_trigger),
        .stat_measuring          (stat_measuring          )
    );

endmodule

`default_nettype wire
