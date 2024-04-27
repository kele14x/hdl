// File: ptp_pkg.sv
// Brief: Package holds useful constants and functions for O-RAN
package ptp_pkg;

  localparam logic [15:0] EtherTypeVlan = 16'h8100;
  localparam logic [15:0] EtherTypePtp = 16'h88F7;

  localparam logic [7:0] PtpMessageTypeSync       = 4'h0;
  localparam logic [7:0] PtpMessageTypeDelayReq   = 4'h1;
  localparam logic [7:0] PtpMessageTypeFollowUp   = 4'h8;
  localparam logic [7:0] PtpMessageTypeDelayResp  = 4'h9;
  localparam logic [7:0] PtpMessageTypeAnnounce   = 4'hB;

  function automatic logic [3:0] tkeep_size(input logic [7:0] tkeep);
    tkeep_size = 0;
    for (int i = 0; i < 8; i++) begin
      if (tkeep_size[i]) tkeep_size = i + 1;
    end
  endfunction

  function automatic logic [63:0] byte_reverse(input logic [63:0] data);
    for (int i = 0; i < 8; i++) begin
      byte_reverse[63-i*8-:8] = data[i*8+7-:8];
    end
  endfunction

endpackage
