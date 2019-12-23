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
// Filename: tb_dec_8b10b.sv
//
// Purpose: Test bench for 8b/10b decider.
//
// Note: The golden encoder table "dec.mif" was obtained from Xilinx's 8b/10b
//   encoder IP core.
//   https://www.xilinx.com/support/documentation/ip_documentation/decode_8b10b.pdf
//
//=============================================================================

`timescale 1 ns / 1 ps
`default_nettype none

module tb_dec_8b10b;

    reg clk;
    reg rst;
    reg cen;
    //
    reg [9:0] din   ;
    reg       dispin;
    //
    wire [7:0] dout      ;
    wire       charisk   ;
    wire       dispout   ;
    wire       disperr   ;
    wire       notintable;
    wire       valid     ;

    reg [7:0] dout_gold      ;
    reg       charisk_gold   ;
    reg       notintable_gold;
    reg       disperr_gold   ;
    reg       dispout_gold   ;

    // Address [ 9:0]: {din}
    // Data    [13:0]: {sym_disp, code_err, charisk, dout}
    reg [13:0] dec_table [0:1023];

    initial begin
        $readmemb("dec.mif", dec_table, 0, 1023);
    end

    // Stimulation

    always begin
        clk = 0;
        #5;
        clk = 1;
        #5;
    end

    initial begin
        rst = 1;
        #100;
        rst = 0;
    end

    initial begin
        $display("Simulation starts.");
        wait(!rst);
        for (int i = 0; i < 1024; i = i + 1) begin
            @(posedge clk);
            cen <= 1;
            din <= i;
            dispin <= 0;
        end
        for (int i = 0; i < 1024; i = i + 1) begin
            @(posedge clk);
            cen <= 1;
            din <= i;
            dispin <= 1;
        end

        @(posedge clk);
        din <= 0;
        cen <= 0;
        #100;
        $finish();
    end

    final begin
        $display("Simulation ends.");
    end

    dec_8b10b DUT (.*);

    always_ff @ (posedge clk) begin
        if (rst) begin
            dout_gold       <= 'd0;
            charisk_gold    <= 1'b0;
            notintable_gold <= 1'b0;
            dispout_gold    <= 1'b0;
            disperr_gold    <= 1'b0;
        end else if (cen) begin
            dout_gold       <= dec_table[din][7:0];
            charisk_gold    <= dec_table[din][8];
            notintable_gold <= dec_table[din][9];
            dispout_gold    <= dec_table[din][dispin*2+10];
            disperr_gold    <= dec_table[din][dispin*2+11];
        end
    end

    // When reset is assert, outputs should be into default value

    assert property (@(posedge clk) rst |=> dout == 8'd0);

    assert property (@(posedge clk) rst |=> charisk == 1'd0);

    assert property (@(posedge clk) rst |=> dispout == 1'd0);

    assert property (@(posedge clk) rst |=> disperr == 1'd0);

    assert property (@(posedge clk) rst |=> notintable == 1'd0);

    assert property (@(posedge clk) rst |=> valid == 1'd0);

    // When cen is not assert, outputs should remain stable

    assert property (@(posedge clk) ~rst && !cen |=> $stable(dout));

    assert property (@(posedge clk) ~rst && !cen |=> $stable(charisk));

    assert property (@(posedge clk) ~rst && !cen |=> $stable(dispout));

    assert property (@(posedge clk) ~rst && !cen |=> $stable(disperr));

    assert property (@(posedge clk) ~rst && !cen |=> $stable(notintable));

    // Check output with gold result, note that when notintable assert, it
    // indicates input is a not in table symbol (there are 244 not in table
    // symbol). So core can have a undefined behavior. Outputs when notintalbe
    // is assert is not important and can be ignored.

    assert property (@(posedge clk) cen |=> notintable == notintable_gold);

    assert property (@(posedge clk) cen ##1 !notintable |-> dout == dout_gold);

    assert property (@(posedge clk) cen ##1 !notintable |-> dispout == dispout_gold);

    assert property (@(posedge clk) cen ##1 !notintable |-> disperr == disperr_gold);

    assert property (@(posedge clk) cen ##1 !notintable |-> charisk == charisk_gold);

endmodule

`default_nettype wire
