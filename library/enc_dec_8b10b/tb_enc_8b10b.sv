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
// Filename: tb_enc_8b10b.sv
//
// Purpose: Test bench for 8b/10b encoder.
//
// Note: The golden encoder table "enc.mif" was obtained from Xilinx's 8b/10b
//   encoder IP core.
//   https://www.xilinx.com/support/documentation/ip_documentation/encode_8b10b.pdf
//
//=============================================================================

`timescale 1 ns / 1 ps
`default_nettype none

module tb_enc_8b10b;

    parameter C_RST_CODE = 10'b0101010101;

    reg       clk       ;
    reg       rst       ;
    reg       cen       ;
    //
    reg [7:0] din    ;
    reg       charisk;
    reg       dispin ;
    //
    wire [9:0] dout   ;
    wire       kerr   ;
    wire       dispout;
    wire       valid  ;

    reg [9:0] dout_gold   ;
    reg       kerr_gold   ;
    reg       dispout_gold;

    // Address [ 9:0]: {charisk,  dispin,  din }
    // Data    [11:0]: {kerr, dispout, dout}
    reg [11:0] enc_table [0:1023];

    initial begin
        $readmemb("enc.mif", enc_table, 0, 1023);
    end

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
        {cen, charisk, dispin, din} <= 0;
        wait(!rst);
        for (int i = 0; i < 1024; i = i + 1) begin
            @(posedge clk);
            cen <= 1;
            {charisk, dispin, din} <= i;
        end
        @(posedge clk);
        {cen, charisk, dispin, din} <= 0;
        #100;
        $finish();
    end

    final begin
        $display("Simulation ends.");
    end

    enc_8b10b #(.C_RST_CODE(C_RST_CODE)) DUT (.*);

    always_ff @ (posedge clk) begin
        if (rst) begin
            dout_gold <= C_RST_CODE;
            kerr_gold <= 0;
            dispout_gold <= 0;
        end else begin
            {kerr_gold, dispout_gold, dout_gold} <= enc_table[{charisk, dispin, din}];
        end
    end

    // When reset is assert, outputs should be into default value

    assert property (@(posedge clk) rst |=> dout == 10'b0101010101);

    assert property (@(posedge clk) rst |=> !valid);

    assert property (@(posedge clk) rst |=> !dispout);

    assert property (@(posedge clk) rst |=> !kerr);

    // When cen is not assert, outputs should remain stable

    assert property (@(posedge clk) ~rst && !cen |=> $stable(dout));

    assert property (@(posedge clk) ~rst && !cen |=> $stable(dispout));

    assert property (@(posedge clk) ~rst && !cen |=> $stable(kerr));

    assert property (@(posedge clk) ~rst |=> valid == $past(cen));

    // Check our output with gold result, note that when kerr is assert, it
    // indicates input is a undefined K char (there are only 12 valid K char).
    // So core can have a undefined behavior. dout value then kerr is assert
    // is not important and can be ignored.

    assert property (@(posedge clk)
        ~rst && cen |=> kerr == kerr_gold);

    assert property (@(posedge clk)
        ~rst && cen |=> dispout == dispout_gold);

    assert property (@(posedge clk)
        ~rst && cen ##1 !kerr |-> dout == dout_gold);

endmodule

`default_nettype wire
