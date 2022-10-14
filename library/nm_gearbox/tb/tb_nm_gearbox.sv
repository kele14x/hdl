`timescale 1 ns / 1 ps
//
`default_nettype none

module tb_nm_gearbox;

  bit        clk;
  bit        rst;
  //
  bit [15:0] din;
  bit        din_valid;
  bit        din_ready;
  //
  bit [63:0] dout;
  bit        dout_valid;
  //
  bit [ 5:0] dout_bits = 2;


  initial begin
    clk = 0;
    forever begin
      #5 clk = ~clk;
    end
  end

  initial begin
    rst = 1;
    #100 rst = 0;
  end

  initial begin
    wait (rst == 0);
    @(posedge clk);
    // Send n ticks input
    for (int i = 0; i < 10; i++) begin
      din <= i;
      din_valid <= 1;
      forever begin
        @(posedge clk);
        if (din_ready) break;
      end
    end
    // Reset
    din <= 0;
    din_valid <= 0;
  end

  nm_gearbox UUT (.*);

endmodule : tb_nm_gearbox

`default_nettype wire
