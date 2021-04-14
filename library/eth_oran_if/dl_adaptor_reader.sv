// File: dl_adaptor_reader.sv
// Brief: Downlink PDxCH (DL U-Plane data) adaptor reader. One reader will try
//        to read 4 branches' data and put them into dl_symbol_* interface.
//        One of this module is designed to handle one CC.
//        The output should have aligned with 10 ms DL radio start, and each
//        symbol start. The control of symbol start is done by external module.
`timescale 1 ns / 1 ps `default_nettype none

module dl_adaptor_reader #(
    parameter int NUM_DL_LAYER = 16,
    parameter int NUM_CC = 2
) (
    // Interface with DFE
    //===================
    input var         clk,
    input var         rst,
    //
    input var         dl_radio_start_10ms,
    input var         dl_sym_update      [NUM_CC],
    // Read
    output var [11:0] rd_addr            [NUM_DL_LAYER][NUM_CC],
    output var        rd_en              [NUM_DL_LAYER][NUM_CC],
    input var  [63:0] rd_data            [NUM_DL_LAYER][NUM_CC],
    //
    output var        dl_sof             [NUM_DL_LAYER][NUM_CC],
    output var        dl_sos             [NUM_DL_LAYER][NUM_CC],
    output var [31:0] dl_data            [NUM_DL_LAYER][NUM_CC],
    output var        dl_valid           [NUM_DL_LAYER][NUM_CC],
    output var [11:0] dl_num             [NUM_DL_LAYER][NUM_CC]
);


endmodule

`default_nettype wire
