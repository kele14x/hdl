// File: cdc_async_rst_sync.sv
// Brief: Asynchronous reset signal synchronizer. This simple module is the so
//        called best practice do to synchronize an asynchronous reset signal
//        into specified clock domain. The reset output is put into reset
//        asynchronously, but will release (leave reset) synchronously with
//        `clk`.

`timescale 1 ns / 1 ps `default_nettype none

module cdc_async_rst_sync #(
    parameter int SYNC_FF = 4,
    parameter logic RST_ACTIVE_HIGH = 0
) (
    input var  clk,
    input var  async_rst,
    output var sync_rst
);

  (* async_reg="true" *)
  logic [SYNC_FF-1:0] async_reg;
  logic async_clr;

  assign async_clr = async_rst ^ (RST_ACTIVE_HIGH ? 1'b0 : 1'b1);

  always_ff @(posedge clk, posedge async_clr) begin
    if (async_clr) begin
      async_reg <= {SYNC_FF{(RST_ACTIVE_HIGH ? 1'b1 : 1'b0)}};
    end else begin
      async_reg <= {async_reg[SYNC_FF-2:0], (RST_ACTIVE_HIGH ? 1'b0 : 1'b1)};
    end
  end

  assign sync_rst = async_reg[SYNC_FF-1];

endmodule

`default_nettype wire
