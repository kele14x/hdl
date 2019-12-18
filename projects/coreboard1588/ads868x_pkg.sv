/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

package ads868x_pkg;

    /* Group: Command Register */

    parameter [15:0] ADS868X_CMD_NO_OP    = 16'h0000;
    parameter [15:0] ADS868X_CMD_STDBY    = 16'h8200;
    parameter [15:0] ADS868X_CMD_PWR_DN   = 16'h8300;
    parameter [15:0] ADS868X_CMD_RST      = 16'h8500;
    parameter [15:0] ADS868X_CMD_AUTO_RST = 16'hA000;

    parameter [15:0] ADS868X_CMD_MAN_CH0 = 16'hC000;
    parameter [15:0] ADS868X_CMD_MAN_CH1 = 16'hC400;
    parameter [15:0] ADS868X_CMD_MAN_CH2 = 16'hC800;
    parameter [15:0] ADS868X_CMD_MAN_CH3 = 16'hCC00;

    // ADS8688 only
    parameter [15:0] ADS868X_CMD_MAN_CH4 = 16'hD000;
    parameter [15:0] ADS868X_CMD_MAN_CH5 = 16'hD400;
    parameter [15:0] ADS868X_CMD_MAN_CH6 = 16'hD800;
    parameter [15:0] ADS868X_CMD_MAN_CH7 = 16'hDC00;

    parameter [15:0] ADS868X_CMD_MAN_AUX = 16'hE000;

    /* Group: Program Register */

    // AUTO SCAN SEQUENCING CONTROL
    parameter [6:0] ADS868X_REG_AUTO_SEQ_EN = 7'h01;
    parameter [6:0] ADS868X_REG_CH_PWR_DN   = 7'h02;

    // DEVICE FEATURES SELECTION CONTROL
    parameter [6:0] ADS868X_REG_FEA_SEL   = 7'h03;

    // RANGE SELECT REGISTERS
    parameter [6:0] ADS868X_REG_CH0_RNG = 7'h05;
    parameter [6:0] ADS868X_REG_CH1_RNG = 7'h06;
    parameter [6:0] ADS868X_REG_CH2_RNG = 7'h07;
    parameter [6:0] ADS868X_REG_CH3_RNG = 7'h08;
    //
    parameter [6:0] ADS868X_REG_CH4_RNG = 7'h09;
    parameter [6:0] ADS868X_REG_CH5_RNG = 7'h0A;
    parameter [6:0] ADS868X_REG_CH6_RNG = 7'h0B;
    parameter [6:0] ADS868X_REG_CH7_RNG = 7'h0C;

    // COMMAND READ BACK
    parameter [6:0] ADS868X_REG_CMD_RB = 7'h3F;

    /* Group: Program Register OP */

    parameter ADS868X_REG_READ = 1'b0;
    parameter ADS868X_REG_WRITE = 1'b1;

    function [31:0] ads868x_cmd_op(input [15:0] cmd);
        return {cmd, 16'b0};
    endfunction

    function [23:0] ads868x_reg_op(input [6:0] addr, input wr_rd_n, input [7:0] data);
        return {addr, wr_rd_n, data, 8'b0};
    endfunction

    function [23:0] ads868x_reg_read(input [6:0] addr, input [7:0] data);
        return ads868x_reg_op(addr, ADS868X_REG_READ, data);
    endfunction

    function [23:0] ads868x_reg_write(input [6:0] addr, input [7:0] data);
        return ads868x_reg_op(addr, ADS868X_REG_WRITE, data);
    endfunction

endpackage
