`timescale 1 ns / 1 ps
//
`default_nettype none

module prach_resync (
    input var         clk,
    input var         rst_n,
    //
    input var  [15:0] din_dr_cc0,
    input var  [15:0] din_dr_cc1,
    input var  [15:0] din_dr_cc2,
    input var  [15:0] din_di_cc0,
    input var  [15:0] din_di_cc1,
    input var  [15:0] din_di_cc2,
    input var  [ 2:0] din_chn,
    input var         sync_in,
    //
    output var [15:0] dout_dr   [3],
    output var [15:0] dout_di   [3],
    output var [ 7:0] dout_chn,
    output var        sync_out
);

  // Input is 61.44 Msps, 8 clock ticks / sample

  logic sync_req;

  always_ff @(posedge clk) begin
    dout_dr[0] <= din_dr_cc0;
    dout_dr[1] <= din_dr_cc1;
    dout_dr[2] <= din_dr_cc2;
    //
    dout_di[0] <= din_di_cc0;
    dout_di[1] <= din_di_cc1;
    dout_di[2] <= din_di_cc2;
  end

  // Ensure sync_out is aligned with dout_chn == 0

  always_ff @(posedge clk) begin
    if (sync_in && din_chn != 0) begin
      sync_req <= 1'b1;
    end else if (din_chn == 0) begin
      sync_req <= 1'b0;
    end
  end

  always_ff @(posedge clk) begin
    if ((sync_in || sync_req) && din_chn == 0) begin
      dout_chn <= '0;
    end else begin
      dout_chn <= dout_chn + 1;
    end
  end

  always_ff @(posedge clk) begin
    if ((sync_in || sync_req) && din_chn == 0) begin
      sync_out <= 1'b1;
    end else begin
      sync_out <= 1'b0;
    end
  end

endmodule

`default_nettype wire
