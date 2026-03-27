localparam reg [15:0] EtherTypeVlan = 16'h8100;
localparam reg [15:0] EtherTypePtp = 16'h88F7;
localparam reg [15:0] EtherTypeEcpri = 16'hAEFE;

function [63:0] byte_reverse64(input [63:0] data);
  integer i;
  begin
    for (i = 0; i < 8; i = i + 1) begin
      byte_reverse64[i*8+7-:8] = data[63-i*8-:8];
    end
  end
endfunction
