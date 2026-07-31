`timescale 1 ns / 1 ps

`default_nettype none

package fh_pkg;

  localparam [15:0] EtherTypeVlan = 16'h8100;
  localparam [15:0] EtherTypePtp = 16'h88F7;
  localparam [15:0] EtherTypeEcpri = 16'hAEFE;

  function automatic [63:0] byte_reverse64(input logic [63:0] data);
    integer i;
    begin
      for (i = 0; i < 8; i = i + 1) begin
        byte_reverse64[i*8+7-:8] = data[63-i*8-:8];
      end
    end
  endfunction

endpackage

`default_nettype wire
