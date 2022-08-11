// File: ch_fir_coe.sv
// Brief: Channel filter
`timescale 1 ns / 1 ps
//
`default_nettype none

module ch_fir_coe #(
    parameter int COE_ADDR_WIDTH = 6,
    parameter int COE_DATA_WIDTH = 16
) (
    input var                              clk,
    input var                              rst,
    output var signed [COE_DATA_WIDTH-1:0] coe_out          [2**COE_ADDR_WIDTH],
    // Control signals
    //----------------
    input var                              ctrl_clk,
    input var                              ctrl_rst,
    // Coefficient memory
    input var                              ctrl_coe_en,
    input var                              ctrl_coe_we,
    input var         [COE_ADDR_WIDTH-1:0] ctrl_coe_addr,
    input var         [COE_DATA_WIDTH-1:0] ctrl_coe_data_in,
    output var        [COE_DATA_WIDTH-1:0] ctrl_coe_data_out
);

  // Coefficients are stored in a register array
  (* ram_style="register" *)
  logic signed [COE_DATA_WIDTH-1:0] coe_mem[2**COE_ADDR_WIDTH];

  // Coefficients Store

  always_ff @(posedge ctrl_clk) begin
    if (ctrl_coe_we && ctrl_coe_we) begin
      coe_mem[ctrl_coe_addr] <= $signed(ctrl_coe_data_in);
    end
  end

  always_ff @(posedge ctrl_clk) begin
    if (ctrl_coe_en) begin
      ctrl_coe_data_out <= $unsigned(coe_mem[ctrl_coe_addr]);
    end
  end

  assign coe_out = coe_mem;

endmodule

`default_nettype wire
