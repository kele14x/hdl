// File: dpd.sv
// Brief: DPD top module.
`timescale 1 ns / 1 ps
//
`default_nettype none

module dpd #(
    parameter int DATA_WIDTH   = 16,
    parameter int NUM_CHANNELS = 2
) (
    input var                  clk,
    input var                  rst,
    //
    input var [DATA_WIDTH-1:0] data_i_in [NUM_CHANNELS],
    input var [DATA_WIDTH-1:0] data_q_in [NUM_CHANNELS],
    //
    input var [DATA_WIDTH-1:0] data_i_out[NUM_CHANNELS],
    input var [DATA_WIDTH-1:0] data_q_out[NUM_CHANNELS]
);


  generate
    for (genvar i = 0; i < NUM_CHANNELS; i++) begin : g_ch
      dpd_channel #(
          .DATA_WIDTH(DATA_WIDTH)
      ) i_channel (
          .clk       (clk),
          .rst       (rst),
          //
          .data_i_in (data_i_in[i]),
          .data_q_in (data_q_in[i]),
          //
          .data_i_out(data_i_out[i]),
          .data_q_out(data_q_out[i])
      );
    end
  endgenerate

endmodule

`default_nettype wire
