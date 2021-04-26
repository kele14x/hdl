// File: dl_adaptor.sv
// Brief: Downlink PDxCH (DL U-Plane data) adaptor. Input is 4 branch (4 dl
//        layer) stream from XORIF ip core, each stream contains all CCs' data.
//        However, output has different share structure. Each stream contains 4
//        layer interleaved data. Also each CC has separated port, resulting
//        8 streams for 4 branches/layers and 2 CCs.
`timescale 1 ns / 1 ps `default_nettype none

module dl_adaptor_sim #(
    parameter int NUM_CC = 2,
    parameter int NUM_DL_LAYER = 16
) (
    // Interface with XORIF
    //=====================
    input var         clk_400m,
    input var         rst_400m,
    // Timing ports
    // Note, s_dl_update is expected to be few ticks after `dl_radio_start_10ms`
    input var         s_dl_update          [      NUM_CC],
    // 4 branch/layer stream, CC shared
    input var  [63:0] s_defm_data_tdata    [NUM_DL_LAYER],
    input var  [ 7:0] s_defm_data_tkeep    [NUM_DL_LAYER],
    input var         s_defm_data_tvalid   [NUM_DL_LAYER],
    input var         s_defm_data_tlast    [NUM_DL_LAYER],
    output var        s_defm_data_tready   [NUM_DL_LAYER],
    input var  [30:0] s_defm_data_tuser    [NUM_DL_LAYER],
    // Interface with DFE
    //===================
    input var         clk_491m52,
    input var         rst_491m52,
    // DL symbol timing
    input var         dl_radio_start_10ms,
    // 2 CC port, each will have interleaved 4 layer data
    output var        dl_sof               [      NUM_CC],
    output var        dl_sos               [      NUM_CC],
    output var [15:0] dl_data_i            [      NUM_CC][NUM_DL_LAYER],
    output var [15:0] dl_data_q            [      NUM_CC][NUM_DL_LAYER],
    output var        dl_valid             [      NUM_CC],
    // Control Interface
    //==================
    input var  [ 3:0] ctrl_bandwidth       [      NUM_CC],
    input var  [ 1:0] ctrl_numerology      [      NUM_CC],
    input var  [ 1:0] ctrl_compression_mode[      NUM_CC]
);

endmodule

`default_nettype wire
