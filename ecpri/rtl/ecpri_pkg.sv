`timescale 1 ns / 1 ps

`default_nettype none

package ecpri_pkg;

  localparam [15:0] ECPRI_ETHERTYPE_VLAN  = 16'h8100;
  localparam [15:0] ECPRI_ETHERTYPE_PTP   = 16'h88F7;
  localparam [15:0] ECPRI_ETHERTYPE_ECPRI = 16'hAEFE;

  // Get the TKEEP size based on the pattern.
  function automatic [1:0] tkeep_size(input reg [3:0] tkeep);
    begin
      if (tkeep[3]) tkeep_size = 2'b11;
      else if (tkeep[2]) tkeep_size = 2'b10;
      else if (tkeep[1]) tkeep_size = 2'b01;
      else if (tkeep[0]) tkeep_size = 2'b00;
      else tkeep_size = 2'b00;
    end
  endfunction

  // Get the TKEEP pattern based on the byte ending position.
  function automatic [3:0] get_tkeep(input reg [1:0] size);
    begin
      case (size)
        2'b00:   get_tkeep = 4'b0001;
        2'b01:   get_tkeep = 4'b0011;
        2'b10:   get_tkeep = 4'b0111;
        2'b11:   get_tkeep = 4'b1111;
        default: get_tkeep = 4'b0000;
      endcase
    end
  endfunction

  // Byte reverse for word.
  function automatic [31:0] byte_reverse(input reg [31:0] data);
    integer i;
    begin
      for (i = 0; i < 4; i = i + 1) begin
        byte_reverse[31-i*8-:8] = data[i*8+7-:8];
      end
    end
  endfunction

endpackage

`default_nettype wire
