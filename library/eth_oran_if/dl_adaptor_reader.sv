// File: dl_adaptor_reader.sv
// Brief: Downlink PDxCH (DL U-Plane data) adaptor reader. One reader will try
//        to read 4 branches' data and put them into dl_symbol_* interface.
//        One of this module is designed to handle one CC.
//        The output should have aligned with 10 ms DL radio start, and each
//        symbol start. The control of symbol start is done by external module.
`timescale 1 ns / 1 ps `default_nettype none

module dl_adaptor_reader #(
    parameter int NUM_BRANCH = 4
) (
    // Interface with DFE
    //===================
    input var         clk,
    input var         rst,
    //
    input var         dl_radio_start_10ms,
    input var         dl_symbol_start,
    // Read
    output var [11:0] rd_addr            [NUM_BRANCH],
    output var        rd_en              [NUM_BRANCH],
    input var  [63:0] rd_data            [NUM_BRANCH],
    //
    output var        dl_sof             [NUM_BRANCH],
    output var        dl_sos             [NUM_BRANCH],
    output var [31:0] dl_data            [NUM_BRANCH],
    output var        dl_valid           [NUM_BRANCH],
    output var [11:0] dl_num             [NUM_BRANCH]
);


endmodule

`default_nettype wire
