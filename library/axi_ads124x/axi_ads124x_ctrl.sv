/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module axi_ads124x_ctrl #(parameter C_CLK_FREQ = 125000) (
    input  wire        aclk             ,
    input  wire        aresetn          ,
    // SPI send
    output reg  [ 7:0] spitx_axis_tdata ,
    output reg         spitx_axis_tvalid,
    input  wire        spitx_axis_tready,
    // SPI receive
    input  wire [ 7:0] spirx_axis_tdata ,
    input  wire        spirx_axis_tvalid,
    output wire        spirx_axis_tready,
    //
    output reg  [31:0] adc_axis_tdata   ,
    output reg         adc_axis_tvalid  ,
    input  wire        adc_axis_tready  ,
    //
    input  wire        pps              ,
    //
    output wire        RESET            ,
    output wire        START            , // At least 732 ns width
    input  wire        DRDY             ,
    // O&M Interface
    //---------------
    input  wire        up_clk           ,
    input  wire        up_rst           ,
    //
    input  wire        up_op_mode       , // 0 = ctrl i/f control, 1 = auto control
    //
    input  wire        up_ad_start      ,
    input  wire        up_ad_reset      ,
    output wire        up_ad_drdy       ,
    //
    input  wire [31:0] up_spi_send      ,
    input  wire [ 1:0] up_spi_nbytes    ,
    input  wire        up_spi_valid     ,
    output reg  [31:0] up_spi_recv
);

    import axi_ads124x_pkg::*;

    localparam C_CNT_WIDTH = $clog2(C_CLK_FREQ-1);

    reg [C_CNT_WIDTH-1:0] counter;
    reg sample_tick;

    always_ff @ (posedge aclk) begin
        counter <= (!aresetn || pps || counter == C_CLK_FREQ - 1) ? 0 : counter + 1;
    end

    always_ff @ (posedge aclk) begin
        sample_tick = (counter == 100);
    end

    typedef enum {S_RST, S_IDLE,
        S_AUTO_WAIT, S_AUTO_NOP2, S_AUTO_NOP1, S_AUTO_NOP0,
        S_CTRL_CMD3, S_CTRL_CMD2, S_CTRL_CMD1, S_CTRL_CMD0} STATE_T;

    STATE_T state, state_next;

    wire up_op_mode_cdc;

    reg [6:0] auto_start_cnt;
    reg auto_start;

    wire drdy_cdc, drdy_negedge;
    reg drdy_cdc_d;

    // up_clk to aclk CDC
    //====================

    // up_op_mode = 0 : External control mode, AD124x is controlled by up_*
    //                  ports from external source.
    // up_op_mode = 1 : Auto control mode, logic will automatically issue
    //                  START and read back data.
    cdc_bits i_cdc_up_op_mode (
        .din    (up_op_mode    ),
        .out_clk(aclk          ),
        .dout   (up_op_mode_cdc)
    );

    wire up_spi_valid_cdc;

    xpm_cdc_pulse #(
        .DEST_SYNC_FF  (2),
        .INIT_SYNC_FF  (1),
        .REG_OUTPUT    (1),
        .RST_USED      (0),
        .SIM_ASSERT_CHK(1)
    ) xpm_cdc_pulse_inst (
        .dest_pulse(up_spi_valid_cdc),
        .dest_clk  (aclk            ),
        .dest_rst  (1'b0            ),
        .src_clk   (up_clk          ),
        .src_pulse (up_spi_valid    ),
        .src_rst   (1'b0            )
    );

    always_ff @ (posedge aclk) begin
        if (!aresetn) begin
            state <= S_RST;
        end else begin
            state <= state_next;
        end
    end

    always_comb begin
        case (state)
            S_RST       : state_next = S_IDLE;
            S_IDLE      : state_next =
                // Enter auto control loop
                (up_op_mode_cdc && sample_tick)   ? S_AUTO_WAIT :
                // Send SPI command from external source
                (!up_op_mode_cdc && up_spi_valid_cdc) ? (up_spi_nbytes == 2'b11 ? S_CTRL_CMD3 :
                                                         up_spi_nbytes == 2'b10 ? S_CTRL_CMD2 :
                                                         up_spi_nbytes == 2'b01 ? S_CTRL_CMD1 :
                                                         S_CTRL_CMD0) :  S_IDLE; // TODO:
            // Automatically send
            S_AUTO_WAIT : state_next = drdy_negedge        ? S_AUTO_NOP2 : S_AUTO_WAIT;
            S_AUTO_NOP2 : state_next = (spitx_axis_tready) ? S_AUTO_NOP1 : S_AUTO_NOP1;
            S_AUTO_NOP1 : state_next = (spitx_axis_tready) ? S_AUTO_NOP0 : S_AUTO_NOP1;
            S_AUTO_NOP0 : state_next = (spitx_axis_tready) ? S_IDLE      : S_AUTO_NOP0;
            //
            S_CTRL_CMD3 : state_next = (spitx_axis_tready) ? S_CTRL_CMD2 : S_CTRL_CMD3;
            S_CTRL_CMD2 : state_next = (spitx_axis_tready) ? S_CTRL_CMD1 : S_CTRL_CMD2;
            S_CTRL_CMD1 : state_next = (spitx_axis_tready) ? S_CTRL_CMD0 : S_CTRL_CMD1;
            S_CTRL_CMD0 : state_next = (spitx_axis_tready) ? S_IDLE      : S_CTRL_CMD0;
            default     : state_next = S_RST;
        endcase
    end

    always_ff @ (posedge aclk) begin
        if (state_next == S_AUTO_NOP0) begin
            spitx_axis_tdata <= SPI_CMD_NOP;
        end else if (state_next == S_AUTO_NOP1) begin
            spitx_axis_tdata <= SPI_CMD_NOP;
        end else if (state_next == S_AUTO_NOP2) begin
            spitx_axis_tdata <= SPI_CMD_NOP;
        end else if (state_next == S_CTRL_CMD3) begin
            spitx_axis_tdata <= up_spi_send[31:24];
        end else if (state_next == S_CTRL_CMD2) begin
            spitx_axis_tdata <= up_spi_send[23:16];
        end else if (state_next == S_CTRL_CMD2) begin
            spitx_axis_tdata <= up_spi_send[15: 8];
        end else if (state_next == S_CTRL_CMD2) begin
            spitx_axis_tdata <= up_spi_send[ 7: 0];
        end
    end

    always_ff @ (posedge aclk) begin
        spitx_axis_tvalid <= (state_next == S_AUTO_NOP0 ||
            state_next == S_AUTO_NOP1 || state_next == S_AUTO_NOP2);
    end

    assign spirx_axis_tready = 1'b1;

    always_ff @ (posedge aclk) begin
        if (state == S_AUTO_NOP0 && spirx_axis_tvalid) begin
            adc_axis_tdata[23:16] <= spirx_axis_tdata;
        end
        if (state == S_AUTO_NOP1 && spirx_axis_tvalid) begin
            adc_axis_tdata[15: 8] <= spirx_axis_tdata;
        end
        if (state == S_AUTO_NOP2 && spirx_axis_tvalid) begin
            adc_axis_tdata[ 7: 0] <= spirx_axis_tdata;
        end
    end


    // Extend the START pulse for at least 732 ns, this is required by AD124x
    // datasheet (#7.6, page 11, tSTART requirement). We do 128 clocks.

    always_ff @ (posedge aclk) begin
        if (sample_tick) begin
            auto_start_cnt <= 1;
        end else if (|auto_start_cnt) begin
            auto_start_cnt <= auto_start_cnt + 1;
        end
    end

    always_ff @ (posedge aclk) begin
        auto_start <= |auto_start_cnt;
    end


    // DRDY pin input CDC
    cdc_bits i_cdc_drdy (
        .din    (DRDY    ),
        .out_clk(aclk    ),
        .dout   (drdy_cdc)
    );

    always_ff @ (posedge aclk) begin
        drdy_cdc_d <= drdy_cdc;
    end

    // Falling edge of /DRDY pin
    assign drdy_negedge = !drdy_cdc && drdy_cdc_d;


    // GPIO pins (START/RESET/DRDY) for exteranl control mode:

    // If in external control mode, start pin to AD124x is controlled by
    // external source. This allows external source controls AD124x freely.
    // External can use issue command (read/write/sleep/wakeup/etc.) to
    // control AD124x chip.
    assign START = up_op_mode ? up_ad_start : auto_start;

    // If in external control mode, reset pin to AD124x is controlled by
    // external. Else set it high (not reset).
    assign RESET = up_op_mode ? up_ad_reset : 1'b1;

    cdc_bits i_cdc_drdy2 (
        .din    (DRDY      ),
        .out_clk(up_clk    ),
        .dout   (up_ad_drdy)
    );

endmodule

`default_nettype wire
