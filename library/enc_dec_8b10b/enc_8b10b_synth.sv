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
// Filename: enc_8b10b_synth.sv
//
// Purpose: 8b/10b encoder synthesis file. It's not very useful, just used to
//   analysis the logic level and timing of enc_8b10b module.
//
//=============================================================================

`timescale 1 ns / 1 ps
`default_nettype none

module enc_8b10b_synth (
    input  wire       clk    ,
    input  wire       rst    ,
    input  wire       cen    ,
    //
    input  wire [7:0] din    ,
    input  wire       charisk,
    input  wire       dispin ,
    //
    output wire [9:0] dout   ,
    output wire       kerr   ,
    output wire       dispout,
    output wire       valid
);

    reg rst_r, cen_r, charisk_r, dispin_r;
    reg [7:0] din_r;

    always_ff @(posedge clk) begin
        rst_r     <= rst;
        cen_r     <= cen;
        din_r     <= din;
        charisk_r <= charisk;
        dispin_r  <= dispin;
    end

    enc_8b10b i_enc_8b10b (
        .clk    (clk      ),
        .rst    (rst_r    ),
        .cen    (cen_r    ),
        //
        .din    (din_r    ),
        .charisk(charisk_r),
        .dispin (dispin_r ),
        //
        .dout   (dout     ),
        .kerr   (kerr     ),
        .dispout(dispout  ),
        .valid  (valid    )
    );

endmodule

`default_nettype wire
