// File: oran_pkg.sv
// Brief: Package holds useful constants and functions for O-RAN
package oran_pkg;

  localparam logic [15:0] EtherTypeVlan  = 16'h8100;
  localparam logic [15:0] EtherTypeEcpri = 16'hAEFE;

  localparam logic [ 7:0] EcpriMessageTypeIq  = 8'd0; // IQ Data
  localparam logic [ 7:0] EcpriMessageTypeRtc = 8'd2; // Real-Time Control Data
  localparam logic [ 7:0] EcpriMessageTypeOdm = 8'd5; // One-way delay measurement

  function automatic logic [3:0] tkeep_size(input logic [7:0] tkeep);
    tkeep_size = 0;
    for (int i = 0; i < 8; i++) begin
      if (tkeep[i]) tkeep_size = i + 1;
    end
  endfunction

  function automatic logic [63:0] byte_reverse(input logic [63:0] data);
    for (int i = 0; i < 8; i++) begin
      byte_reverse[63-i*8-:8] = data[i*8+7-:8];
    end
  endfunction

endpackage
