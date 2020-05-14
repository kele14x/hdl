/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

module tb_coreboard1588 ();

    // FPGA Misc

    logic [1:0] FPGA_LED ;
    logic [3:0] FPGA_TEST;

    // MCU <-> FPGA

    logic FPGA_RST     = 0; // !Active low
    logic FPGA_RUN        ;
    logic FPGA_MCU_RST    ;
    logic FPGA_DAT_FIN    ;
    logic FPGA_MCU_INTR   ;

    wire FPGA_MCU_SPI_CLK ;
    wire FPGA_MCU_SPI_CS  ;
    wire FPGA_MCU_SPI_MOSI;
    wire FPGA_MCU_SPI_MISO;

    logic [11:0] FMC_A    ;
    logic        FMC_CLK  ;
    logic        FMC_NE   ;
    logic [ 1:0] FMC_NBL  ;
    logic        FMC_NWAIT;
    logic        FMC_NL   ;
    logic        FMC_NOE  ;
    logic        FMC_NWE  ;
    wire  [15:0] FMC_D    ;

    // FPGA GCLK

    logic A7_GCLK = 0;

    // Trigger
    
    logic FPGA_EXT_TRIGGER;
    logic FPGA_TRIGGER_EN ;

    // PHY

    logic PTP_CLK_OUT  = 0;
    logic PTP_TRG_FPGA = 0;

    // FPGA <-> QSPI

    wire       A7_CONFIG_FCS_B;
    wire [3:0] A7_CONFIG_DQ   ;

    // ADS868x

    wire FPGA_SPI1_CLK ;
    wire FPGA_SPI1_CS  ;
    wire FPGA_SPI1_MOSI;
    wire FPGA_SPI1_MISO;

    logic AD1_RST;

    logic [2:0] CH_SEL_A;

    logic EN_TCH_A;
    logic EN_PCH_A;
    logic EN_TCH_B;
    logic EN_PCH_B;

    wire FPGA_SPI2_CLK ;
    wire FPGA_SPI2_CS  ;
    wire FPGA_SPI2_MOSI;
    wire FPGA_SPI2_MISO;
    //
    logic AD2_DRDY ;
    logic AD2_RST  ;
    logic AD2_START;

    // UUT
    //===========

    coreboard1588 DUT (.*);

    sim_clk_gen #(
        .CLK_FREQ_HZ (25000000),
        .RST_POLARITY(1       ),
        .RST_CYCLES  (10      )
    ) i_A7_GCLK_GEN (
        .clk(A7_GCLK),
        .rst(       )
    );

    sim_clk_gen #(
        .CLK_FREQ_HZ (25000000),
        .RST_POLARITY(1       ),
        .RST_CYCLES  (10      )
    ) i_PTP_CLK_GEN (
        .clk(PTP_CLK_OUT),
        .rst(           )
    );

    // Helper functions
    //=================

    task FPGA_Reset();
        FPGA_RST = 0;
        #1000 FPGA_RST = 1;
        // Wait internal logic lock
        #10000;
    endtask

    // 
    parameter SPI_SCK_PERIOD = 25;

    reg sck = 1'b0, ss = 1'b1, mosi = 1'bz, miso = 1'bz;

    assign FPGA_MCU_SPI_CLK  = sck;
    assign FPGA_MCU_SPI_CS   = ss;
    assign FPGA_MCU_SPI_MOSI = mosi;
    assign FPGA_MCU_SPI_MISO = miso;

    task FPGA_MCU_SPI_TransRecv(input wrn, input [31:0] addr, input [31:0] txd, output [31:0] rxd);
        reg [7:0] buffer [0:6];
        reg [31:0] rxd_temp;
        // Set buffer
        buffer[0] = wrn ? (addr[17:10] | 8'h80) : (addr[17:10] & 8'h7F);
        buffer[1] = addr[ 9: 2];
        buffer[2] = 0; // Dummy byte
        buffer[3] = txd[31:24];
        buffer[4] = txd[23:16];
        buffer[5] = txd[15: 8];
        buffer[6] = txd[ 7: 0];

        // SPI Pre
        sck = 0;
        ss = 0;
        mosi = 0;
        #(SPI_SCK_PERIOD/2);

        // SPI Data
        for (int ibyte = 0; ibyte < 7; ibyte++) begin
            for (int ibit = 7; ibit >= 0; ibit--) begin
                sck = 1;
                mosi = buffer[ibyte][ibit];
                #(SPI_SCK_PERIOD/2);
                sck = 0;
                // Sample on negedge
                if (ibyte >= 3) begin
                    rxd_temp[0] = miso;
                    rxd_temp <<= 1;
                end
                #(SPI_SCK_PERIOD/2);
            end
        end
        
        rxd = rxd_temp;
        
        // SPI Post
        sck = 1'b0;
        ss = 1'b1;
        mosi = 1'bz;
        #(SPI_SCK_PERIOD/2);

    endtask;

    task FPGA_WriteReg(input [31:0] addr, input [31:0] data);
        reg [31:0] dummy;
        FPGA_MCU_SPI_TransRecv(1'b1, addr, data, dummy);
    endtask

    task FPGA_ReadReg(input [31:0] addr, output [31:0] data);
        FPGA_MCU_SPI_TransRecv(1'b0, addr, 32'h0, data);
    endtask

    // Simulation Caes
    //================

    initial begin
        $display("%t: Simulation starts.", $time);
        
        // Soft reset FPGA
        FPGA_Reset();
        
        // Enable ADS868x AUTOSPI
        FPGA_WriteReg(32'hC08, 32'h1);
  
        // Set trigger mode to RTC
        FPGA_WriteReg(32'h84, 32'h3);
        // Set RTC trigger time
        FPGA_WriteReg(32'h88, 32'h0);
        FPGA_WriteReg(32'h8C, 32'd1000000);
        // Enable trigger
        FPGA_WriteReg(32'h80, 32'h1);
        
        #100000000;
        $finish;
    end

    final begin
        $display("%t: Simulation ends.", $time);
    end

endmodule

`default_nettype wire
