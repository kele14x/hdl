`timescale 1 ns / 1 ps

`default_nettype none

package ptp_pkg;

  // PTP message types.
  localparam [3:0] PTP_MESSAGE_TYPE_SYNC            = 4'h0;
  localparam [3:0] PTP_MESSAGE_TYPE_DELAY_REQ       = 4'h1;
  localparam [3:0] PTP_MESSAGE_TYPE_PDELAY_REQ      = 4'h2;
  localparam [3:0] PTP_MESSAGE_TYPE_PDELAY_RESP     = 4'h3;
  localparam [3:0] PTP_MESSAGE_TYPE_FOLLOW_UP       = 4'h8;
  localparam [3:0] PTP_MESSAGE_TYPE_DELAY_RESP      = 4'h9;
  localparam [3:0] PTP_MESSAGE_TYPE_PDELAY_RESP_FUP = 4'hA;
  localparam [3:0] PTP_MESSAGE_TYPE_ANNOUNCE        = 4'hB;
  localparam [3:0] PTP_MESSAGE_TYPE_SIGNALING       = 4'hC;
  localparam [3:0] PTP_MESSAGE_TYPE_MANAGEMENT      = 4'hD;

  // PTP multicast MAC addresses.
  localparam [47:0] PTP_MULTICAST_MAC        = 48'h01_1B_19_00_00_00;
  localparam [47:0] PTP_MULTICAST_MAC_PDELAY = 48'h01_80_C2_00_00_0E;

  // PTP Ethertype.
  localparam [15:0] PTP_ETHERTYPE = 16'h88_F7;

  // PTP control fields.
  localparam [7:0] PTP_CONTROL_FIELD_SYNC       = 8'h00;
  localparam [7:0] PTP_CONTROL_FIELD_DELAY_REQ  = 8'h01;
  localparam [7:0] PTP_CONTROL_FIELD_FOLLOW_UP  = 8'h02;
  localparam [7:0] PTP_CONTROL_FIELD_DELAY_RESP = 8'h03;
  localparam [7:0] PTP_CONTROL_FIELD_MANAGEMENT = 8'h04;
  localparam [7:0] PTP_CONTROL_FIELD_OTHERS     = 8'h05;

  function automatic [31:0] byte_reverse(input reg [31:0] in);
    integer i;
    begin
      for (i = 0; i < 4; i = i + 1) begin
        byte_reverse[i*8+7-:8] = in[31-i*8-:8];
      end
    end
  endfunction

endpackage

`default_nettype wire
