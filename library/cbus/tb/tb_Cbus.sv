/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module tb_Cbus ();

    parameter SYS_W  = 1 ;
    parameter PERIDO = 8;

    // Upper Pins
    logic             UPPER_RX_CLK_P;
    logic             UPPER_RX_CLK_N;
    logic [SYS_W-1:0] UPPER_RX_DIN_P;
    logic [SYS_W-1:0] UPPER_RX_DIN_N;
    //
    logic             UPPER_TX_CLK_P ;
    logic             UPPER_TX_CLK_N ;
    logic [SYS_W-1:0] UPPER_TX_DOUT_P;
    logic [SYS_W-1:0] UPPER_TX_DOUT_N;
    // Lower Pins
    logic             LOWER_RX_CLK_P;
    logic             LOWER_RX_CLK_N;
    logic [SYS_W-1:0] LOWER_RX_DIN_P;
    logic [SYS_W-1:0] LOWER_RX_DIN_N;
    //
    logic             LOWER_TX_CLK_P ;
    logic             LOWER_TX_CLK_N ;
    logic [SYS_W-1:0] LOWER_TX_DOUT_P;
    logic [SYS_W-1:0] LOWER_TX_DOUT_N;

    // Fabric Port
    logic tx_core_clk; // 125 MHz
    logic rx_core_clk;
    //
    logic tx_reset;
    logic rx_reset;

    logic [7:0]       s_axis_tdata ;
    logic             s_axis_tvalid;
    logic             s_axis_tlast ;
    logic             s_axis_tready;
    //
    logic [7:0]       m_axis_tdata ;
    logic             m_axis_tvalid;
    logic             m_axis_tlast ;
    logic             m_axis_tready;

    assign UPPER_RX_CLK_P = UPPER_TX_CLK_P;
    assign UPPER_RX_CLK_N = UPPER_TX_CLK_N;
    assign UPPER_RX_DIN_P = UPPER_TX_DOUT_P;
    assign UPPER_RX_DIN_N = UPPER_TX_DOUT_N;

    assign LOWER_RX_CLK_P = LOWER_TX_CLK_P;
    assign LOWER_RX_CLK_N = LOWER_TX_CLK_N;
    assign LOWER_RX_DIN_P = LOWER_TX_DOUT_P;
    assign LOWER_RX_DIN_N = LOWER_TX_DOUT_N;

    reg [7:0] buffer [0:1023];

    task axis_send(input [7:0] buffer[], input integer len);
        // Sync to clock
        @(posedge tx_core_clk);
        for (integer i = 0; i < len; i = i + 1) begin
            $display("send %d th buff", i);
            // Send i-th byte
            s_axis_tdata  <= buffer[i];
            s_axis_tvalid <= 1'b1;
            s_axis_tlast  <= (i==len);
            // wait i-th byte is received
            forever begin
                @(posedge tx_core_clk);
                if (s_axis_tvalid && s_axis_tready) break;
            end            
        end 
        // Reset bus
        s_axis_tdata  <= 0;
        s_axis_tvalid <= 0;
        s_axis_tlast  <= 0;
    endtask


    always begin
        tx_core_clk = 0;
        rx_core_clk = 0;
        #(PERIDO/2);
        tx_core_clk = 1;
        rx_core_clk = 1;
        #(PERIDO/2);
    end

    initial begin

        tx_reset = 1;
        rx_reset = 1;
        
        s_axis_tdata = 0;
        s_axis_tvalid = 0;
        s_axis_tlast = 0;
        
        #(1000);
        tx_reset = 0;
        rx_reset = 0;
        
        $display("%t: Reset done.", $time);
        
        #(1000);
        // Init buffer
        for (integer i = 0; i < 100; i = i + 1) buffer[i] = 100+i;
        // Send 100 data
        axis_send(buffer, 100);
        // Send byte 0 to 99
        
    end

    Cbus UUT ( .* );

endmodule
