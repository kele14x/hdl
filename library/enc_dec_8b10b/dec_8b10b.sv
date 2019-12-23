//=============================================================================
//
// Copyright (C) 2019 Kele
//
// This program is free software: you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by the Free
// Software Foundation, either version 3 of the License, or (at your option)
// any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
// FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
// more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
//
//=============================================================================
//
// Filename: dec_8b10b.sv
//
// Purpose: A 8b/10b decoder. Please refer to enc_8b10b.sv for more information
//   about 8b/10b encoding. To decode the 10b symbol, it can be simply done a
//   a bit look-up-table. The table will list all the property of symbol: mapped
//   code, if it's a K char, and the disparity of symbol. Be not that for it's
//   not required to check the disparity if we only want to decode the symbol.
//
// Note: rst has high priority over cen
//
// Reference: * A DC-Balanced, Partitioned-Block, 8B/10B Transmission Code, IBM, 1983
//              https://ieeexplore.ieee.org/document/5390392
//            * https://en.wikipedia.org/wiki/8b/10b_encoding
//            * https://www.xilinx.com/support/documentation/application_notes/xapp1112.pdf
//            * https://www.xilinx.com/support/documentation/ip_documentation/decode_8b10b.pdf
//
//=============================================================================

`timescale 1 ns / 1 ps
`default_nettype none

module dec_8b10b (
    input  wire       clk       ,
    input  wire       rst       ,
    input  wire       cen       ,
    //
    input  wire [9:0] din       ,
    input  wire       dispin    ,
    //
    output reg  [7:0] dout      ,
    output reg        charisk   ,
    output reg        dispout   ,
    output reg        disperr   ,
    output reg        notintable,
    output reg        valid
);

    wire a, b, c, d, e, i, f, g, h, j;

    wire [5:0] b6; // abcdei
    wire [3:0] b4; // fghj

    reg [4:0] b5; // EDCBA
    reg [2:0] b3; // HGF

    reg b6_notintable, b4_notintable;

    wire k28;

    // disp_t:
    // |         | Input disparity | Output disparity |
    // | neg     |        +        |        -         |
    // | pos     |        -        |        +         |
    // | zero    |        x        |        x         |
    // | specneg |        -        |        -         |
    // | specpos |        +        |        +         |
    typedef enum {neg, pos, zero, specneg, specpos} disp_t;

    disp_t b6_disp, b4_disp;

    wire disp_temp, b6b4_disp_mismatch, alt_rule1, alt_rule2, alt_rule3, alt_rule4;


    // Assume input symbol is bit reversed, that is LSB(a) is received first
    assign {j, h, g, f, i, e, d, c, b, a} = din;

    assign b6 = {a, b, c, d ,e, i};

    assign b4 = {f, g, h, j};

    // b6/b5 decoding
    always_comb begin
        case(b6)
            6'b100111 : begin b5 = 5'b00000; b6_notintable = 1'b0; end // D.0.y-
            6'b011000 : begin b5 = 5'b00000; b6_notintable = 1'b0; end // D.0.y+
            6'b011101 : begin b5 = 5'b00001; b6_notintable = 1'b0; end // D.1.y-
            6'b100010 : begin b5 = 5'b00001; b6_notintable = 1'b0; end // D.1.y+
            6'b101101 : begin b5 = 5'b00010; b6_notintable = 1'b0; end // D.2.y-
            6'b010010 : begin b5 = 5'b00010; b6_notintable = 1'b0; end // D.2.y+
            6'b110001 : begin b5 = 5'b00011; b6_notintable = 1'b0; end // D.3.y
            6'b110101 : begin b5 = 5'b00100; b6_notintable = 1'b0; end // D.4.y-
            6'b001010 : begin b5 = 5'b00100; b6_notintable = 1'b0; end // D.4.y+
            6'b101001 : begin b5 = 5'b00101; b6_notintable = 1'b0; end // D.5.y
            6'b011001 : begin b5 = 5'b00110; b6_notintable = 1'b0; end // D.6.y
            6'b111000 : begin b5 = 5'b00111; b6_notintable = 1'b0; end // D.7.y-
            6'b000111 : begin b5 = 5'b00111; b6_notintable = 1'b0; end // D.7.y+
            6'b111001 : begin b5 = 5'b01000; b6_notintable = 1'b0; end // D.8.y-
            6'b000110 : begin b5 = 5'b01000; b6_notintable = 1'b0; end // D.8.y+
            6'b100101 : begin b5 = 5'b01001; b6_notintable = 1'b0; end // D.9.y
            6'b010101 : begin b5 = 5'b01010; b6_notintable = 1'b0; end // D.10.y-
            6'b110100 : begin b5 = 5'b01011; b6_notintable = 1'b0; end // D.11.y-
            6'b001101 : begin b5 = 5'b01100; b6_notintable = 1'b0; end // D.12.y-
            6'b101100 : begin b5 = 5'b01101; b6_notintable = 1'b0; end // D.13.y-
            6'b011100 : begin b5 = 5'b01110; b6_notintable = 1'b0; end // D.14.y-
            6'b101000 : begin b5 = 5'b01111; b6_notintable = 1'b0; end // D.15.y-
            6'b010111 : begin b5 = 5'b01111; b6_notintable = 1'b0; end // D.15.y-

            6'b011011 : begin b5 = 5'b10000; b6_notintable = 1'b0; end // D.16.y+
            6'b100100 : begin b5 = 5'b10000; b6_notintable = 1'b0; end // D.16.y-
            6'b100011 : begin b5 = 5'b10001; b6_notintable = 1'b0; end // D.17.y-
            6'b010011 : begin b5 = 5'b10010; b6_notintable = 1'b0; end // D.18.y+
            6'b110010 : begin b5 = 5'b10011; b6_notintable = 1'b0; end // D.19.y-
            6'b001011 : begin b5 = 5'b10100; b6_notintable = 1'b0; end // D.20.y-
            6'b101010 : begin b5 = 5'b10101; b6_notintable = 1'b0; end // D.21.y-
            6'b011010 : begin b5 = 5'b10110; b6_notintable = 1'b0; end // D.22.y-
            6'b111010 : begin b5 = 5'b10111; b6_notintable = 1'b0; end // D/K.23.y+
            6'b000101 : begin b5 = 5'b10111; b6_notintable = 1'b0; end // D/K.23.y-
            6'b001100 : begin b5 = 5'b11000; b6_notintable = 1'b0; end // D.24.y+
            6'b110011 : begin b5 = 5'b11000; b6_notintable = 1'b0; end // D.24.y-
            6'b100110 : begin b5 = 5'b11001; b6_notintable = 1'b0; end // D.25.y-
            6'b010110 : begin b5 = 5'b11010; b6_notintable = 1'b0; end // D.26.y-
            6'b110110 : begin b5 = 5'b11011; b6_notintable = 1'b0; end // D/K.27.y+
            6'b001001 : begin b5 = 5'b11011; b6_notintable = 1'b0; end // D/K.27.y-
            6'b001110 : begin b5 = 5'b11100; b6_notintable = 1'b0; end // D.28.y-
            6'b001111 : begin b5 = 5'b11100; b6_notintable = 1'b0; end // K.28.y+
            6'b110000 : begin b5 = 5'b11100; b6_notintable = 1'b0; end // K.28.y-
            6'b101110 : begin b5 = 5'b11101; b6_notintable = 1'b0; end // D/K.29.y+
            6'b010001 : begin b5 = 5'b11101; b6_notintable = 1'b0; end // D/K.29.y-
            6'b011110 : begin b5 = 5'b11110; b6_notintable = 1'b0; end // D.30.y+
            6'b100001 : begin b5 = 5'b11110; b6_notintable = 1'b0; end // D.30.y-
            6'b101011 : begin b5 = 5'b11111; b6_notintable = 1'b0; end // D.31.y+
            6'b010100 : begin b5 = 5'b11111; b6_notintable = 1'b0; end // D.31.y-
            default   : begin b5 = 5'b11111; b6_notintable = 1'b1; end // Symbol not in table
        endcase
    end

    // This signal indicate one of (K.28.1, K.28.2, K.28.5, K.28.6), they
    // require special 4b/3b decoding
    assign k28 = ({c,d,e,i} == 4'b0000) && (h ^ j);

    // 4b/3b decoding
    always_comb begin
        case(b4)
            4'b1011 : begin b3 = 3'b000; b4_notintable = 1'b0; end // D/K.x.0-
            4'b0100 : begin b3 = 3'b000; b4_notintable = 1'b0; end // D/K.x.0+
            4'b1001 : begin b3 = ~k28 ? 3'b001 : // D/K.x.1+
                                        3'b110; b4_notintable = 1'b0; end // K.x.6-
            4'b0110 : begin b3 =  k28 ? 3'b001 : // K.x.1-
                                        3'b110; b4_notintable = 1'b0; end // D/K.x.6+
            4'b0101 : begin b3 = ~k28 ? 3'b010 : // D/K.x.2+
                                        3'b101; b4_notintable = 1'b0; end // K.x.5-
            4'b1010 : begin b3 =  k28 ? 3'b010 : // K.x.2-
                                        3'b101; b4_notintable = 1'b0; end // D/K.x.5
            4'b1100 : begin b3 = 3'b011; b4_notintable = 1'b0; end // D/K.x.3
            4'b0011 : begin b3 = 3'b011; b4_notintable = 1'b0; end // D/K.x.3
            4'b0010 : begin b3 = 3'b100; b4_notintable = 1'b0; end // D/K.x.4
            4'b1101 : begin b3 = 3'b100; b4_notintable = 1'b0; end // D/K.x.4
            4'b1110 : begin b3 = 3'b111; b4_notintable = 1'b0; end // D.x.7
            4'b0001 : begin b3 = 3'b111; b4_notintable = 1'b0; end // D.x.7
            4'b0111 : begin b3 = 3'b111; b4_notintable = 1'b0; end // D/K.x.7
            4'b1000 : begin b3 = 3'b111; b4_notintable = 1'b0; end // D/K.x.7
            default : begin b3 = 3'b111; b4_notintable = 1'b1; end // Symbol not in table
        endcase
    end

    // Rules: 1. More ones, disparity is pos (+)
    //        2. More zeros, disprity is neg (-)
    //        3. Same ones with zeros:
    //        3.1 6'b000111, disparity is specneg
    //        3.2 6'b111000, disparity is specpos
    //        3.3 disparity is zero (0)

    // Disparity of 6b symbol
    always_comb begin
        case (b6)
            6'b000000 : b6_disp = neg ;    // invalid ;
            6'b100000 : b6_disp = neg ;    // invalid ;
            6'b010000 : b6_disp = neg ;    // invalid ;
            6'b110000 : b6_disp = neg ;    // K.28
            6'b001000 : b6_disp = neg ;    // invalid ;
            6'b101000 : b6_disp = neg ;    // D.15
            6'b011000 : b6_disp = neg ;    // D.0
            6'b111000 : b6_disp = specneg; // D.7
            6'b000100 : b6_disp = neg ;    // invalid ;
            6'b100100 : b6_disp = neg ;    // D.16
            6'b010100 : b6_disp = neg ;    // D.31
            6'b110100 : b6_disp = zero ;   // D.11
            6'b001100 : b6_disp = neg ;    // D.24
            6'b101100 : b6_disp = zero ;   // D.13
            6'b011100 : b6_disp = zero ;   // D.14
            6'b111100 : b6_disp = pos ;    // invalid ;

            6'b000010 : b6_disp = neg ;    // invalid ;
            6'b100010 : b6_disp = neg ;    // D.1
            6'b010010 : b6_disp = neg ;    // D.2
            6'b110010 : b6_disp = zero ;   // D.19
            6'b001010 : b6_disp = neg ;    // D.4
            6'b101010 : b6_disp = zero ;   // D.21
            6'b011010 : b6_disp = zero ;   // D.22
            6'b111010 : b6_disp = pos ;    // D.23
            6'b000110 : b6_disp = neg ;    // D.8
            6'b100110 : b6_disp = zero ;   // D.25
            6'b010110 : b6_disp = zero ;   // D.26
            6'b110110 : b6_disp = pos ;    // D.27
            6'b001110 : b6_disp = zero ;   // D.28
            6'b101110 : b6_disp = pos ;    // D.29
            6'b011110 : b6_disp = pos ;    // D.30
            6'b111110 : b6_disp = pos ;    // invalid ;

            6'b000001 : b6_disp = neg ;    // invalid ;
            6'b100001 : b6_disp = neg ;    // D.30 ;
            6'b010001 : b6_disp = neg ;    // D.29 ;
            6'b110001 : b6_disp = zero ;   // D.3
            6'b001001 : b6_disp = neg ;    // D.27
            6'b101001 : b6_disp = zero ;   // D.5
            6'b011001 : b6_disp = zero ;   // D.6
            6'b111001 : b6_disp = pos ;    // D.8
            6'b000101 : b6_disp = neg ;    // D.23
            6'b100101 : b6_disp = zero ;   // D.9
            6'b010101 : b6_disp = zero ;   // D.10
            6'b110101 : b6_disp = pos ;    // D.4
            6'b001101 : b6_disp = zero ;   // D.12
            6'b101101 : b6_disp = pos ;    // D.2
            6'b011101 : b6_disp = pos ;    // D.1
            6'b111101 : b6_disp = pos ;    // invalid ;

            6'b000011 : b6_disp = neg ;    // invalid ;
            6'b100011 : b6_disp = zero ;   // D.17
            6'b010011 : b6_disp = zero ;   // D.18
            6'b110011 : b6_disp = pos ;    // D.24
            6'b001011 : b6_disp = zero ;   // D.20
            6'b101011 : b6_disp = pos ;    // D.31
            6'b011011 : b6_disp = pos ;    // D.16
            6'b111011 : b6_disp = pos ;    // invalid ;
            6'b000111 : b6_disp = specpos; // D.7
            6'b100111 : b6_disp = pos ;    // D.0
            6'b010111 : b6_disp = pos ;    // D.15
            6'b110111 : b6_disp = pos ;    // invalid ;
            6'b001111 : b6_disp = pos ;    // K.28
            6'b101111 : b6_disp = pos ;    // invalid ;
            6'b011111 : b6_disp = pos ;    // invalid ;
            6'b111111 : b6_disp = pos ;    // invalid ;

            default : b6_disp = zero ;
        endcase // b6
    end

    // Disparity of 4b symbol
    always_comb begin
        case (b4)
            4'b0000: b4_disp = neg ;
            4'b1000: b4_disp = neg ;
            4'b0100: b4_disp = neg ;
            4'b1100: b4_disp = specneg;
            4'b0010: b4_disp = neg ;
            4'b1010: b4_disp = zero ;
            4'b0110: b4_disp = zero ;
            4'b1110: b4_disp = pos ;
            4'b0001: b4_disp = neg ;
            4'b1001: b4_disp = zero ;
            4'b0101: b4_disp = zero ;
            4'b1101: b4_disp = pos ;
            4'b0011: b4_disp = specpos;
            4'b1011: b4_disp = pos ;
            4'b0111: b4_disp = pos ;
            4'b1111: b4_disp = pos ;
            default: b4_disp = zero ;
        endcase
    end

    // Check if b6 symbol and b4 symbol's disparity violate the encoding rule
    // of 8b/10b.
    assign b6b4_disp_mismatch =
        (b6_disp == pos && b4_disp == pos) ||
        (b6_disp == pos && b4_disp == specneg) ||
        (b6_disp == specpos && b4_disp == pos) ||
        (b6_disp == specpos && b4_disp == specneg) ||
        (b6_disp == neg && b4_disp == neg) ||
        (b6_disp == neg && b4_disp == specpos) ||
        (b6_disp == specneg && b4_disp == neg) ||
        (b6_disp == specneg && b4_disp == specpos);

    // Rule violation
    // (D.11.y, D.13.y, D.14.y, K.28.y-) with D/K.x.P7+ (should use with
    // D/K.x.A7+ or others)
    assign alt_rule1 = (
        b6 == 6'b110100 || b6 == 6'b101100 || b6 == 6'b011100 ||
        b6 == 6'b001111) && b4 == 4'b0001;

    // Rule violation
    // Symbols other than (D.11.y, D.13.7, D14.y, D/K.23.y-, D/K.27.y-,
    // D/K.29.y-, D/K.30.y-, K.28.y-) use with D/K.x.A7+
    assign alt_rule2 = !(
        b6 == 6'b110100 || b6 == 6'b101100 || b6 == 6'b011100 ||
        b6 == 6'b111010 || b6 == 6'b110110 || b6 == 6'b101110 ||
        b6 == 6'b011110 || b6 == 6'b001111) && b4 == 4'b1000;

    // Rule violation
    // (D.17.y, D.18.y, D.20.y, K.28.y+) with D/K.x.P7- (should use with
    // D/K.x.A7- or others)
    assign alt_rule3 = (
        b6 == 6'b100011 || b6 == 6'b010011 || b6 == 6'b001011 ||
        b6 == 6'b110000) && b4 == 4'b1110;

    // Rule violation
    // Symbols other than (D.17.y, D.18.y, D.20.y, D/K.23.y+, D/K.27.y+,
    // D/K.29.y+, D/K.30.y+, K.28.y+) use with D/K.x.A7-
    assign alt_rule4 = !(
        b6 == 6'b100011 || b6 == 6'b010011 || b6 == 6'b001011 ||
        b6 == 6'b000101 || b6 == 6'b001001 || b6 == 6'b010001 ||
        b6 == 6'b100001 || b6 == 6'b110000) && b4 == 4'b0111;

    // Output ports
    //==============

    always_ff @ (posedge clk) begin
        if (rst) begin
            dout <= 8'd0;
        end else if (cen) begin
            dout <= {b3, b5};
        end
    end

    // K chars has two group, K.28.y (y=0~7) and K.x.7 (x=23,27,29,30)
    // The first group can be recognized by c == d == e == i, since in data we
    // never have this.
    // The second group can be recognized by eifghj == 101000 or 010111
    always_ff @ (posedge clk) begin
        if (rst) begin
            charisk <= 1'b0;
        end else if (cen) begin
            charisk <= {c,d,e,i} == 4'b0000 || {c,d,e,i} == 4'b1111 ||
                {e,i,f,g,h,j} == 6'b101000 || {e,i,f,g,h,j} == 6'b010111;
        end
    end

    // Check if the symbol violate the 8b/10b encoding rule. There are 4 rules:
    // * b6 should be in b6/b5 decoding table
    // * b4 should be in b4/b3 decoding table
    // * Symbol disparity should match between b6 & b4 (for example, pos symbol
    //   followed by pos symbol violate the rule)
    // * Special rules for D/K.x.A7 alternative symbol
    always_ff @ (posedge clk) begin
        if (rst) begin
            notintable <= 1'b0;
        end else if (cen) begin
            notintable <= b6_notintable || b4_notintable || b6b4_disp_mismatch
            || alt_rule1 || alt_rule2 || alt_rule3 || alt_rule4;
        end
    end

    assign disp_temp = b6_disp == neg ? 1'b0 :
                       b6_disp == pos ? 1'b1 :
                       b6_disp == specneg ? 1'b0 :
                       b6_disp == specpos ? 1'b1 :
                       dispin;

    always_ff @ (posedge clk) begin
        if (rst) begin
            dispout <= 1'b0;
        end else if (cen) begin
            dispout <= b4_disp == neg ? 1'b0 :
                       b4_disp == pos ? 1'b1 :
                       b4_disp == specneg ? 1'b0 :
                       b4_disp == specpos ? 1'b1 :
                       disp_temp;
        end
    end

    always_ff @ (posedge clk) begin
        if (rst) begin
            disperr <= 1'b0;
        end else if (cen) begin
            disperr <= b6b4_disp_mismatch || (b6_disp == pos && dispin) ||
                (b6_disp == specneg && dispin) || (b6_disp == neg && !dispin) ||
                (b6_disp == specpos && !dispin) || (b4_disp == pos && disp_temp) ||
                (b4_disp == specneg && disp_temp) || (b4_disp == neg && !disp_temp) ||
                (b4_disp == specpos && !disp_temp);
        end
    end

    always_ff @ (posedge clk) begin
        if (rst) begin
            valid <= 1'b0;
        end else begin
            valid <= cen;
        end
    end

endmodule

`default_nettype wire
