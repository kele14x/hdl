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
// Filename: dec_8b10b_synth.sv
//
// Purpose: 8b/10b decoder synthesis file. It's not very useful, just used to
//   analysis the logic level and timing of dec_8b10b module.
//
//=============================================================================

`timescale 1 ns / 1 ps
`default_nettype none

module dec_8b10b_synth (
    input  wire       clk       ,
    input  wire       rst       ,
    input  wire       cen       ,
    //
    input  wire [9:0] din       ,
    input  wire       dispin    ,
    //
    output wire [7:0] dout      ,
    output wire       charisk   ,
    output wire       dispout   ,
    output wire       disperr   ,
    output wire       notintable,
    output wire       valid
);

    reg rst_r, cen_r, dispin_r;
    reg [9:0] din_r;

    always_ff @(posedge clk) begin
        rst_r     <= rst;
        cen_r     <= cen;
        din_r     <= din;
        dispin_r  <= dispin;
    end

    dec_8b10b i_dec_8b10b (
        .clk       (clk       ),
        .rst       (rst_r     ),
        .cen       (cen_r     ),
        //
        .din       (din_r     ),
        .dispin    (dispin_r  ),
        //
        .dout      (dout      ),
        .charisk   (charisk   ),
        .dispout   (dispout   ),
        .notintable(notintable),
        .disperr   (disperr   ),
        .valid     (valid     )
    );

endmodule

`default_nettype wire
