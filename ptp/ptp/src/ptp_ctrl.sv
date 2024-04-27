// File: ptp_master.sv
// Brief: PTP Master implemented by FPGA.
`timescale 1 ns / 1 ps
//
`default_nettype none

module ptp_ctrl (
    input var  clk,
    input var  rst,
    //
    output var s_send_sync,
    output var s_send_announce,
    output var s_send_delay_req,
    output var s_send_delay_resp
);


endmodule

`default_nettype wire
