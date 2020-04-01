/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

`timescale 1 ns / 1 ps
`default_nettype none

//------------------------------------------------------------------------------
// Single DFF LFSR circuit for PRBS generator
//
//            PRBS output
//                ^
//         .----. |   k-bit delay     l-bit delay
//     +->|  D  |-+---------------->+-------+
//     |  .____.                    |       |
//     |                            |       |
//     +---------------------------xor------+
//
//   N = 1 + k + l
//   For RPBS7 (1 + x^6 + x^7), k = 5, l = 1
//
// Some example for PRBSx:
//
//     N         TAP
//   ----------------
//     7          6
//    15         14
//    23         18
//    31         28
// Note:
//   `rst` over `ce`
//------------------------------------------------------------------------------

(* keep_hierarchy="yes" *)
module Cbus_tx_pma_prbs_gen #(
    parameter N   = 31,
    // 1 + x^6 + x^7
    parameter TAP = 28
) (
    input  wire clk   ,
    input  wire rst   ,
    input  wire ce    ,
    input  wire din   , // inject error
    output reg  dout
);

    localparam [1:N] RESET_VALUE = {1'b1, {(N-1){1'b0}}};

    reg [1:N] lfsr = RESET_VALUE;

    // Only first bit of LFSR is reset-able
    always_ff @ (posedge clk) begin : p_lfsr1
        if (rst) begin
            lfsr[1] <= 1'b1;
        end else if (ce) begin
            lfsr[1] <= lfsr[TAP] ^ lfsr[N];
        end
    end

    // All other taps are delay chain, usually implemented by SRLx-DFF pair
    always_ff @ (posedge clk) begin : p_lfsr2N
        if (ce) begin
            lfsr[2:N] <= lfsr[1:N-1];
        end
    end

    always_ff @ (posedge clk) begin :p_dout
        if (rst) begin
            dout <= 0;
        end else begin
            dout = lfsr[N] ^ din;
        end
    end

endmodule
