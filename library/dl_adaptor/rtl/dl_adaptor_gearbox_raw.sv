// File: dl_adaptor_gearbox.sv
// Brief: Downlink PDxCH (DL U-Plane data) adaptor gearbox.
`timescale 1 ns / 1 ps `default_nettype none

module dl_adaptor_gearbox_raw #(
    parameter int NUM_CC
) (
    // Interface with DFE
    //===================
    input var         clk,
    input var         rst,
    //
    input var  [63:0] s_axis_tdata,
    input var  [ 7:0] s_axis_tkeep,
    input var         s_axis_tvalid,
    input var         s_axis_tlast,
    output var        s_axis_tready,
    input var  [30:0] s_axis_tuser,
    // Shared by CC0 and CC1
    output var [63:0] gb_data      [NUM_CC],
    output var        gb_valid     [NUM_CC],
    output var [11:0] gb_re        [NUM_CC]
);


  logic [2:0] tuser_component_carrier;
  logic       tuser_start_of_section;  // Used to indicate the start of a symbol of RB sections.
  logic       tuser_every_other_rb;  // Not used
  logic [3:0] tuser_bit_width;  // Not used
  logic [3:0] tuser_compression_type;  // Not used
  logic [7:0] tuser_num_rb;  // Not used
  logic [9:0] tuser_start_rb;

  // Xilinx PG370, Page 57, Chapter 3, Section x Downlink U-Plane Data Ports
  assign {
    tuser_component_carrier,
    tuser_start_of_section,
    tuser_every_other_rb,
    tuser_bit_width,
    tuser_compression_type,
    tuser_num_rb,
    tuser_start_rb
  } = s_axis_tuser;

  assign s_axis_tready = 1;

  generate
    for (genvar i = 0; i < NUM_CC; i++) begin

      always_ff @(posedge clk) begin
        if (s_axis_tvalid && (tuser_component_carrier == i)) begin
          gb_data[i] <= s_axis_tdata;
        end
      end

      always_ff @(posedge clk) begin
        gb_valid[i] <= s_axis_tvalid && (tuser_component_carrier == i);
      end

      always_ff @(posedge clk) begin
        if (s_axis_tvalid && (tuser_component_carrier == i)) begin
          if (tuser_start_of_section) begin
            gb_re[i] <= tuser_start_rb * 12;
          end else begin
            gb_re[i] <= gb_re[i] + 2;
          end
        end
      end

    end
  endgenerate



endmodule

`default_nettype wire
