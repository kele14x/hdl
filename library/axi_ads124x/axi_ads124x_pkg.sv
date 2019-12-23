/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

package axi_ads124x_pkg;

    parameter SPI_CMD_WAKEUP   = 8'h00;
    parameter SPI_CMD_SLEEP    = 8'h02;
    parameter SPI_CMD_SYNC0    = 8'h04;
    parameter SPI_CMD_SYNC1    = 8'h04;
    parameter SPI_CMD_RESET    = 8'h06;
    parameter SPI_CMD_NOP      = 8'hFF;
    parameter SPI_CMD_RDATA    = 8'h12;
    parameter SPI_CMD_RDATAC   = 8'h14;
    parameter SPI_CMD_SDATAC   = 8'h16;
    parameter SPI_CMD_RREG0    = 8'h20;
    parameter SPI_CMD_RREG1    = 8'h00;
    parameter SPI_CMD_WREG0    = 8'h40;
    parameter SPI_CMD_WREG1    = 8'h00;
    parameter SPI_CMD_SYSOCAL  = 8'h60;
    parameter SPI_CMD_SYSGCAL  = 8'h61;
    parameter SPI_CMD_SELFOCAL = 8'h62;

endpackage
