/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

package Cbus_pkg;

    parameter [8:0] ORDERED_SETS_SCP1 = KChar(28, 2);
    parameter [8:0] ORDERED_SETS_SCP2 = KChar(27, 7);

    parameter [8:0] ORDERED_SETS_ECP1 = KChar(29, 7);
    parameter [8:0] ORDERED_SETS_ECP2 = KChar(30, 7);

    parameter [8:0] ORDERED_SETS_P = KChar(28, 4);

    parameter [8:0] ORDERED_SETS_K = KChar(28, 5);
    parameter [8:0] ORDERED_SETS_R = KChar(28, 0);
    parameter [8:0] ORDERED_SETS_A = KChar(28, 3);

    parameter [8:0] ORDERED_SETS_CC = KChar(23, 7);

    parameter [8:0] ORDERED_SETS_SNF = KChar(28, 6);

    parameter [8:0] ORDERED_SETS_COMMA2 = KChar(28, 1);
    parameter [8:0] ORDERED_SETS_COMMA3 = KChar(28, 7);

    function [8:0] KChar(input [4:0] b5, input [2:0] b3);
        begin
            return {1'b1, b3, b5};
        end
    endfunction

    function [8:0] DChar(input [4:0] b5, input [2:0] b3);
        begin
            return {1'b0, b3, b5};
        end
    endfunction

endpackage
