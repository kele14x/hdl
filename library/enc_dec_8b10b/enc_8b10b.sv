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
// Filename: enc_8b10b.sv
//
// Purpose: A 8b/10b encoder. 8b/10b encoder was developed by IBM in 1983 as a
//   transmit line code. It's still used in many high speed applications such
//   as JESD204B and PCI-E(1.x & 2.x). Generally, it maps a 8-bit word into a
//   10-bit symbol to achieve DC-balance and bounded disparity, and yet provide
//   enough state changes to allow reasonable clock recovery. There are many
//   free 8b/10b design cores on Internet:
//
//     * Xilinx's 8b/10b encoder: https://www.xilinx.com/support/documentation/ip_documentation/encode_8b10b.pdf
//     * https://opencores.org/projects/8b10b_encdec
//
//   This is just my “reinvent-the-wheels" project to have a better
//   understanding of 8b/10b process.
//
// Note: rst has high priority over cen
//
// Reference: * A DC-Balanced, Partitioned-Block, 8B/10B Transmission Code, IBM, 1983
//              https://ieeexplore.ieee.org/document/5390392
//            * https://en.wikipedia.org/wiki/8b/10b_encoding
//            * https://www.xilinx.com/support/documentation/application_notes/xapp1122.pdf
//            * https://www.xilinx.com/support/documentation/ip_documentation/encode_8b10b.pdf
//
//=============================================================================

`timescale 1 ns / 1 ps
`default_nettype none

module enc_8b10b #(parameter C_RST_CODE = 10'b0101010101) (
    input  wire       clk    ,
    input  wire       rst    ,
    input  wire       cen    ,
    //
    input  wire [7:0] din    ,
    input  wire       charisk,
    input  wire       dispin ,
    //
    output reg  [9:0] dout   ,
    output reg        kerr   ,
    output reg        dispout,
    output reg        valid
);

    wire [2:0] b3;
    wire [4:0] b5;

    reg [3:0] b4;
    reg [5:0] b6;

    reg alt, disp_6b, disp_4b;;
    wire k28, kok;

    function [9:0] bit_reverse(input [9:0] bin);
        for (int i = 0; i < 10; i = i + 1)
            bit_reverse[i] = bin[9-i];
    endfunction

    //

    assign b3 = din[7:5];
    assign b5 = din[4:0];

    // 5b/6b encoding (EDCBA -> abcdei)
    //===============================
    // disp_in, charisk, b5 => disp_6b, b6

    always_comb begin : c_b6
        case (b5) // K/D.x.y
            5'b00000: b6 = ~dispin ? 6'b100111 : 6'b011000; // D.00.y
            5'b00001: b6 = ~dispin ? 6'b011101 : 6'b100010; // D.01.y
            5'b00010: b6 = ~dispin ? 6'b101101 : 6'b010010; // D.02.y
            5'b00011: b6 =           6'b110001;             // D.03.y
            5'b00100: b6 = ~dispin ? 6'b110101 : 6'b001010; // D.04.y
            5'b00101: b6 =           6'b101001;             // D.05.y
            5'b00110: b6 =           6'b011001;             // D.06.y
            5'b00111: b6 = ~dispin ? 6'b111000 : 6'b000111; // D.07.y
            5'b01000: b6 = ~dispin ? 6'b111001 : 6'b000110; // D.08.y
            5'b01001: b6 =           6'b100101;             // D.09.y
            5'b01010: b6 =           6'b010101;             // D.10.y
            5'b01011: b6 =           6'b110100;             // D.11.y
            5'b01100: b6 =           6'b001101;             // D.12.y
            5'b01101: b6 =           6'b101100;             // D.13.y
            5'b01110: b6 =           6'b011100;             // D.14.y
            5'b01111: b6 = ~dispin ? 6'b010111 : 6'b101000; // D.15.y
            5'b10000: b6 = ~dispin ? 6'b011011 : 6'b100100; // D.16.y
            5'b10001: b6 =           6'b100011;             // D.17.y
            5'b10010: b6 =           6'b010011;             // D.18.y
            5'b10011: b6 =           6'b110010;             // D.19.y
            5'b10100: b6 =           6'b001011;             // D.20.y
            5'b10101: b6 =           6'b101010;             // D.21.y
            5'b10110: b6 =           6'b011010;             // D.22.y
            5'b10111: b6 = ~dispin ? 6'b111010 : 6'b000101; // K/D.23.y
            5'b11000: b6 = ~dispin ? 6'b110011 : 6'b001100; // D.24.y
            5'b11001: b6 =           6'b100110;             // D.25.y
            5'b11010: b6 =           6'b010110;             // D.26.y
            5'b11011: b6 = ~dispin ? 6'b110110 : 6'b001001; // K/D.27.y
            5'b11100: b6 =  charisk ? (~dispin ? 6'b001111 : 6'b110000) // K.28.y
                                               : 6'b001110; // D.28.y
            5'b11101: b6 = ~dispin ? 6'b101110 : 6'b010001; // K/D.29.y
            5'b11110: b6 = ~dispin ? 6'b011110 : 6'b100001; // K/D.30.y
            default : b6 = ~dispin ? 6'b101011 : 6'b010100; // D.31.y
        endcase
    end

    // Running disparity after 5b/6b encoding
    always_comb begin : p_disp_6b
        case (b5) // K/D.x.y
            5'b00000: disp_6b = ~dispin; // D.00.y
            5'b00001: disp_6b = ~dispin; // D.01.y
            5'b00010: disp_6b = ~dispin; // D.02.y
            5'b00011: disp_6b =  dispin; // D.03.y
            5'b00100: disp_6b = ~dispin; // D.04.y
            5'b00101: disp_6b =  dispin; // D.05.y
            5'b00110: disp_6b =  dispin; // D.06.y
            5'b00111: disp_6b =  dispin; // D.07.y
            5'b01000: disp_6b = ~dispin; // D.08.y
            5'b01001: disp_6b =  dispin; // D.09.y
            5'b01010: disp_6b =  dispin; // D.10.y
            5'b01011: disp_6b =  dispin; // D.11.y
            5'b01100: disp_6b =  dispin; // D.12.y
            5'b01101: disp_6b =  dispin; // D.13.y
            5'b01110: disp_6b =  dispin; // D.14.y
            5'b01111: disp_6b = ~dispin; // D.15.y
            5'b10000: disp_6b = ~dispin; // D.16.y
            5'b10001: disp_6b =  dispin; // D.17.y
            5'b10010: disp_6b =  dispin; // D.18.y
            5'b10011: disp_6b =  dispin; // D.19.y
            5'b10100: disp_6b =  dispin; // D.20.y
            5'b10101: disp_6b =  dispin; // D.21.y
            5'b10110: disp_6b =  dispin; // D.22.y
            5'b10111: disp_6b = ~dispin; // K/D.23.y
            5'b11000: disp_6b = ~dispin; // D.24.y
            5'b11001: disp_6b =  dispin; // D.25.y
            5'b11010: disp_6b =  dispin; // D.26.y
            5'b11011: disp_6b = ~dispin; // K/D.27.y
            5'b11100: disp_6b =  charisk ? ~dispin // K.28.y
                               : dispin; // D.28.y
            5'b11101: disp_6b = ~dispin; // K/D.29.y
            5'b11110: disp_6b = ~dispin; // K/D.30.y
            default : disp_6b = ~dispin; // D.31.y
        endcase
    end

    // 3b/4b encoding (HGF -> fghj)
    //=============================
    // alt, k28, disp_6b, charisk, d3 => d4, disp_4b

    // For D.x.7, either the Primary (D.x.P7), or the Alternate (D.x.A7) is used
    // D.x.A7 is used for some of combination, other wise use D.x.P7
    always_comb begin : c_alt
        alt = ((b5 == 17 || b5 == 18 || b5 == 20) && (!dispin)) ||
              ((b5 == 11 || b5 == 13 || b5 == 14) && (dispin));
    end

    // Check if din is K.28.y
    assign k28 = (b5 == 5'b11100) && charisk;

    // Check if din MAYBE a valid K char
    assign kok = (b5 == 28 || // K.28.y
                 (b5 == 23 && b3 == 7) || // K.23.7
                 (b5 == 27 && b3 == 7) || // K.27.7
                 (b5 == 29 && b3 == 7) || // K.29.7
                 (b5 == 30 && b3 == 7));

    // 3b/4b mapping table, note that none valid K char will use normal encoding,
    // so none valid K will produce a in table symbol, decoder won't detect it
    always_comb begin : c_b4
        case (b3)
            3'b000  : b4 = ~disp_6b          ? 4'b1011 : 4'b0100; // K/D.x.0
            3'b001  : b4 = (~disp_6b && k28) ? 4'b0110 : 4'b1001; // K/D.x.1
            3'b010  : b4 = (~disp_6b && k28) ? 4'b1010 : 4'b0101; // K/D.x.2
            3'b011  : b4 = ~disp_6b          ? 4'b1100 : 4'b0011; // K/D.x.3
            3'b100  : b4 = ~disp_6b          ? 4'b1101 : 4'b0010; // K/D.x.4
            3'b101  : b4 = (~disp_6b && k28) ? 4'b0101 : 4'b1010; // K/D.x.5
            3'b110  : b4 = (~disp_6b && k28) ? 4'b1001 : 4'b0110; // K/D.x.6
            default : b4 = ~(alt || (charisk && kok)) ? (~disp_6b ? 4'b1110 : 4'b0001)  // D.x.P7 / K.err.P7
                                                      : (~disp_6b ? 4'b0111 : 4'b1000); // D.x.A7 / K.23.7 / K.27.7 / K.28.7 / K.29.7 / K.30.7 / K.err.A7
        endcase
    end

    // Running disparity after 3b/4b encoding
    always_comb begin : p_disp_4b
        case (b3)
            3'b000  : disp_4b = ~disp_6b; // K/D.x.0
            3'b001  : disp_4b =  disp_6b; // K/D.x.1
            3'b010  : disp_4b =  disp_6b; // K/D.x.2
            3'b011  : disp_4b =  disp_6b; // K/D.x.3
            3'b100  : disp_4b = ~disp_6b; // K/D.x.4
            3'b101  : disp_4b =  disp_6b; // K/D.x.5
            3'b110  : disp_4b =  disp_6b; // K/D.x.6
            default : disp_4b = ~disp_6b; // K/D.x.7
        endcase
    end

    // Final running disparity is disparity after 3b/4b encoding
    always_ff @ (posedge clk) begin : p_disp_run
        if (rst) begin
            dispout <= 1'b0;
        end else if (cen) begin
            dispout <= disp_4b;
        end
    end

    // Final dout is bit reversed of abcdeifghj
    always_ff @ (posedge clk) begin : p_dout
        if (rst) begin
            dout <= C_RST_CODE;
        end else if (cen) begin
            dout <= bit_reverse({b6, b4});
        end
    end

    // Only 12 K is valid
    always_ff @ (posedge clk) begin : p_kerr
        if (rst) begin
            kerr <= 1'b0;
        end else if (cen) begin
            kerr <= (charisk && ~kok);
        end
    end

    // Indicate new data output is valid
    always_ff @ (posedge clk) begin : p_en
        if (rst) begin
            valid <= 1'b0;
        end else begin
            valid <= cen;
        end
    end

endmodule

`default_nettype wire
