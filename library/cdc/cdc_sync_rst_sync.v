// File: cdc_sync_rst_sync.sv
// Brief: Asynchronous reset signal synchronizer. This module is used to
//        synchronize an asynchronous reset signal into specified clock domain.
//        The reset output will assert and release (leave reset) synchronously
//        with `clk`.

`timescale 1 ns / 1 ps `default_nettype none

module cdc_sync_rst_sync #(
    parameter int SYNC_FF = 4
) (
    input var  clk,
    input var  arst_in,
    output var rst_out
);

  initial begin
    assert (SYNC_FF >= 2)
    else $error("SYNC_FF must be equal or lager than 2.");
  end

  (* async_reg="true" *)
  logic [SYNC_FF-1:0] async_reg;

  always_ff @(posedge clk) begin
    async_reg <= {async_reg[SYNC_FF-2:0], arst_in};
  end

  assign rst_out = async_reg[SYNC_FF-1];

endmodule

`default_nettype wire
