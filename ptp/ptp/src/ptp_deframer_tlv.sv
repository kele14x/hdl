// File: ptp_deframer_tlv.sv
// Brief: Not implemented
`timescale 1 ns / 1 ps
//
`default_nettype none

module ptp_deframer_tlv(
    input var         clk,
    input var         rst,
    //
    input var  [63:0] s_axis_tdata,
    input var  [ 7:0] s_axis_tkeep,
    input var         s_axis_tvalid,
    input var         s_axis_tlast,
    input var  [79:0] s_axis_tuser
);

endmodule

`default_nettype wire
