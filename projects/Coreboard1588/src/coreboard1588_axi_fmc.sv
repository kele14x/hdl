/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

//****************************************************************************
// s00_axis_tdata[31:0]:
//  [31:24] Not used
//  [23:16] Channel ID
//  [15: 0] ADC data
//
// s01_axis_tdata[31:0]
//   [31:24] Channel ID
//   [23: 0] ADC data
//****************************************************************************

module coreboard1588_axi_fmc (
    // AXIS
    //-----
    input  wire        aclk                   ,
    input  wire        aresetn                ,
    //
    input  wire        FPGA_EXT_TRIGGER       ,
    input  wire        FPGA_TRIGGER_EN        ,
    //
    // ADS868x S_AXIS
    //----------
    input  wire [31:0] s00_axis_tdata         ,
    input  wire        s00_axis_tvalid        ,
    output reg         s00_axis_tready        ,
    //
    // ADS124x S_AXIS
    //---------------
    input  wire [31:0] s01_axis_tdata         ,
    input  wire        s01_axis_tvalid        ,
    output reg         s01_axis_tready        ,
    // RTC
    //=====
    input  wire [31:0] rtc_second             ,
    input  wire [31:0] rtc_nanosecond         ,
    // BRAM interface
    //---------------
    output wire        bram_clk               ,
    output wire        bram_rst               ,
    //
    output reg  [11:0] bram_addr              ,
    output reg         bram_en                ,
    input  wire [15:0] bram_dout              ,
    output reg  [15:0] bram_din               ,
    output reg  [ 1:0] bram_we                ,
    //
    output reg         ts_irq                 ,
    // Control
    //========
    input  wire        ctrl_trigger_enable    ,
    input  wire [ 1:0] ctrl_trigger_source    , // 00 = MCU, 01 = external, 11 = RTC
    input  wire [31:0] ctrl_trigger_second    ,
    input  wire [31:0] ctrl_trigger_nanosecond
);


    // Data Buffer
    //-------------
    // total 41 half word (82 byte)

    reg [31:0] ts_s_reg ; // Sample time second value
    reg [31:0] ts_ns_reg; // Sample time nanosecond value

    reg [15:0] pch_data[0:15]; // PCH data from ADS868x
    reg [15:0] tch_data[0:15]; // TCH data from ADS868x

    reg [23:0] pt100[0:2]; // PT100 value from ADS124x

    reg [15:0] triggered;

    reg [31:0] trg_s_reg;   // Triggered time second value
    reg [31:0] trg_ns_reg;  // Triggered time nanosecond value

    // Move second & nano second counter to temp register
    always @ (posedge aclk) begin
        if (s00_axis_tvalid && s00_axis_tdata[23:16] == 8'h00) begin
            ts_s_reg  <= rtc_second;
            ts_ns_reg <= rtc_nanosecond;
        end
    end

    // Save PCH/TCH value to temp register
    // s00_axis_tdata[23:16] is MUX value, where:
    // [1:0] is ADS868x internal MUX (4 to 1)
    // [4:2] is external MUX (8 to 1)
    // Mapping is need due to PCB rounting
    // ID    0        1        2        3
    //     TCH8     PCH8     TCH0     PCH0
    // ID    4        5        6        7
    //     TCH9     PCH9     TCH1     PCH1
    // ...
    // ID   28       29       30       31
    //     TCH15    PCH15    TCH7     PCH7

    always @ (posedge aclk) begin: p_tpch
        integer i;
        integer pid, tid;
        for (i = 0; i < 16; i = i + 1) begin
            // pid is PCH MUX value, see PCB for detail
            pid = (i < 8) ? (i * 4 + 3) : ((i - 8) * 4 + 1);
            if (s00_axis_tvalid && s00_axis_tdata[23:16] == pid) begin
                pch_data[i] <= s00_axis_tdata[15:0];
            end
            // tid is TCH MUX value, see PCB for detail
            tid = (i < 8) ? (i * 4 + 2) : ((i - 8) * 4 + 0);
            if (s00_axis_tvalid && s00_axis_tdata[23:16] == tid) begin
                tch_data[i] <= s00_axis_tdata[15:0];
            end
        end
    end

    // Save PT100 value to buffer
    // ID = 0: Channel 0
    // ID = 1: Channel 1
    // ID = 2: Channel 2

    always @ (posedge aclk) begin: p_pt100
        if (s01_axis_tvalid && s01_axis_tdata[31:24] == 8'd0) begin
            pt100[0] <= s01_axis_tdata[23:0];
        end
        if (s01_axis_tvalid && s01_axis_tdata[31:24] == 8'd1) begin
            pt100[1] <= s01_axis_tdata[23:0];
        end
        if (s01_axis_tvalid && s01_axis_tdata[31:24] == 8'd2) begin
            pt100[2] <= s01_axis_tdata[23:0];
        end
    end


    always @ (posedge aclk) begin
        if (!aresetn) begin
            s00_axis_tready <= 1'b0;
        end else begin
            s00_axis_tready <= 1'b1;
        end
    end

    always @ (posedge aclk) begin
        if (!aresetn) begin
            s01_axis_tready <= 1'b0;
        end else begin
            s01_axis_tready <= 1'b1;
        end
    end

    // Trigger
    //========

    // Trigger state machine
    typedef enum {S_TRG_RESET, S_TRG_IDLE, S_TRG_ARMED, S_TRG_TRIGGERED} T_STATE;

    T_STATE state, state_next;


    var logic trigger_wire;

    var logic rtc_trigger;
    var logic mcu_trigger;
    var logic ext_trigger;

    ext_trg i_ext_trg1 (
        .clk            (aclk            ),
        .ext_trg_in     (FPGA_EXT_TRIGGER),
        .ext_trg_negedge(ext_trigger     )
    );

    ext_trg i_ext_trg2 (
        .clk            (aclk           ),
        .ext_trg_in     (FPGA_TRIGGER_EN),
        .ext_trg_negedge(mcu_trigger    )
    );

    assign rtc_trigger = (ctrl_trigger_second == rtc_second) &&
        (ctrl_trigger_nanosecond == rtc_nanosecond);

    assign trigger_wire = (ctrl_trigger_source == 2'b00) ? mcu_trigger :
        (ctrl_trigger_source == 2'b01) ? ext_trigger :
        (ctrl_trigger_source == 2'b11) ? rtc_trigger : 1'b0;

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            state <= S_TRG_RESET;
        end else begin
            state <= state_next;
        end
    end

    always_comb begin
        case (state)
            S_TRG_RESET     : state_next = S_TRG_IDLE;
            S_TRG_IDLE      : state_next = !ctrl_trigger_enable ? S_TRG_IDLE      : S_TRG_ARMED;
            S_TRG_ARMED     : state_next = !ctrl_trigger_enable ? S_TRG_IDLE      :
                                           !trigger_wire        ? S_TRG_ARMED     : S_TRG_TRIGGERED;
            S_TRG_TRIGGERED : state_next = !ctrl_trigger_enable ? S_TRG_IDLE      :
                                           !(s00_axis_tvalid && s00_axis_tdata[23:16] == 8'd0)
                                                                ? S_TRG_TRIGGERED : S_TRG_IDLE;
            default : state_next = S_TRG_RESET;
        endcase
    end

    // Triggered flag
    always_ff @ (posedge aclk) begin
        if (s00_axis_tvalid && s00_axis_tdata[23:16] == 8'd0) begin
            triggered <= (state == S_TRG_TRIGGERED) ? 16'd1 : 16'd0;
        end
    end

    // Triggered time
    always_ff @ (posedge aclk) begin
        if (s00_axis_tvalid && s00_axis_tdata[23:16] == 8'd0 &&
            state == S_TRG_TRIGGERED) begin
            trg_s_reg  <= rtc_second;
            trg_ns_reg <= rtc_nanosecond;
        end
    end

    // Write 94 byte to BRAM
    //----------------------

    reg [7:0] bram_wr_state;

    always @ (posedge aclk) begin
        if (!aresetn) begin
            bram_wr_state <= {8{1'b1}}; // Reset state
        end else if (s00_axis_tvalid && s00_axis_tdata[23:16] == 8'd31) begin
            // last P/TCH data is writed into buffer
            bram_wr_state <= 0;
        end else if (bram_wr_state <= 44) begin
            bram_wr_state <= bram_wr_state + 1;
        end else begin
            bram_wr_state <= {8{1'b1}};
        end
    end

    // BRAM clock
    assign bram_clk = aclk;

    // BRAM reset
    assign bram_rst = !aresetn;

    // BRAM dout
    always @ (posedge aclk) begin
        if (!aresetn) begin
            bram_din <= 'd0;
        end else begin
            if (bram_wr_state == 0) begin
                // {halfword [0], halfword [1]}: Second
                bram_din <= ts_s_reg[31:16];
            end else if (bram_wr_state == 1) begin
                bram_din <= ts_s_reg[15: 0];
            end else if (bram_wr_state == 2) begin
                // {halfword [2], halfword [3]}: Nanosecond
                bram_din <= ts_ns_reg[31:16];
            end else if (bram_wr_state == 3) begin
                bram_din <= ts_ns_reg[15: 0];
            end else if (bram_wr_state <= 19) begin
                // {halfword [4] ~ halfword [19]}: PCH[0] ~ PCH[15]
                bram_din <= pch_data[bram_wr_state-4];
            end else if (bram_wr_state <= 35) begin
                // {halfword [20] ~ halfword [35]}: TCH[0] ~ TCH[15]
                bram_din <= tch_data[bram_wr_state-20];
            end else if (bram_wr_state == 36) begin
                // {halfword [36], halfword [37]}: PT100[0]
                bram_din <= {8'b0, pt100[0][23:16]};
            end else if (bram_wr_state == 37) begin
                bram_din <= pt100[0][15:0];
            end else if (bram_wr_state == 38) begin
                // {halfword [38], halfword [39]}: PT100[1]
                bram_din <= {8'b0, pt100[1][23:16]};
            end else if (bram_wr_state == 39) begin
                bram_din <= pt100[1][15:0];
            end else if (bram_wr_state == 40) begin
                // {halfword [40], halfword [41]}: PT100[2]
                bram_din <= {8'b0, pt100[2][23:16]};
            end else if (bram_wr_state == 41) begin
                bram_din <= pt100[2][15:0];
            end else if (bram_wr_state == 42) begin
                // {halfword [40]}: triggered
                bram_din <= triggered;
            end else if (bram_wr_state == 43) begin
                bram_din <= trg_s_reg[31:16];
            end else if (bram_wr_state == 44) begin
                bram_din <= trg_s_reg[15:0];
            end else if (bram_wr_state == 45) begin
                bram_din <= trg_ns_reg[31:16];
            end else if (bram_wr_state == 46) begin
                bram_din <= trg_ns_reg[15:0];
            end else begin
                bram_din <= 'd0;
            end
        end
    end

    // BRAM enable
    always @ (posedge aclk) begin
        if (!aresetn) begin
            bram_en <= 1'b0;
        end else begin
            bram_en <= (bram_wr_state >=0 && bram_wr_state <= 46);
        end
    end

    // BRAM write enable
    always @ (posedge aclk) begin
        if (!aresetn) begin
            bram_we <= 2'b00;
        end else begin
            bram_we <= (bram_wr_state >=0 && bram_wr_state <= 46) ? 2'b11 : 2'b00;
        end
    end

    // BRAM address enable
    always @ (posedge aclk) begin
        if (!aresetn) begin
            bram_addr <= 'd0;
        end else begin
            bram_addr <= (bram_wr_state >=0 && bram_wr_state <= 46) ? bram_wr_state : 'd0;
        end
    end

    // IRQ signal pulse width extern
    reg [8:0] ts_irq_ext;

    always @ (posedge aclk) begin
        if (!aresetn) begin
            ts_irq_ext <= 'd0;
        end else begin
            if (bram_wr_state == 46) begin
                ts_irq_ext <= 'd1;
            end else if (|ts_irq_ext) begin
                ts_irq_ext <= ts_irq_ext + 1;
            end
        end
    end

    // IRQ signal
    always @ (posedge aclk) begin
        if (!aresetn) begin
            ts_irq <= 1'b0;
        end else begin
            ts_irq <= |ts_irq_ext;
        end
    end


endmodule

`default_nettype wire
