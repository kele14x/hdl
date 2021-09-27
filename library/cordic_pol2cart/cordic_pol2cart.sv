// File: cordic_pol2cart.sv
// Brief: CORDIC-based approximation of polar-to-Cartesian conversion

`timescale 1ns / 1ps `default_nettype none

module cordic_pol2cart #(
    parameter int DATA_WIDTH           = 16,
    parameter int CTRL_WIDTH           = 1,
    parameter int ITERATIONS           = 7,
    parameter int COMPENSATION_SCALING = 1
) (
    input var  logic                  clk,
    input var  logic                  rst,
    //
    input var  logic [DATA_WIDTH-1:0] r,
    input var  logic [  ITERATIONS:0] theta,
    input var  logic [CTRL_WIDTH-1:0] ctrl_in,
    //
    output var logic [DATA_WIDTH+1:0] xout,
    output var logic [DATA_WIDTH+1:0] yout,
    output var logic [CTRL_WIDTH-1:0] ctrl_out
);

  cordic_rotate #(
      .DATA_WIDTH          (DATA_WIDTH),
      .CTRL_WIDTH          (CTRL_WIDTH),
      .ITERATIONS          (ITERATIONS),
      .COMPENSATION_SCALING(COMPENSATION_SCALING)
  ) i_cordic_rotate (
      .clk     (clk),
      .rst     (rst),
      //
      .xin     (r),
      .yin     ({DATA_WIDTH{1'b0}}),
      .theta   (theta),
      .ctrl_in (ctrl_in),
      //
      .xout    (xout),
      .yout    (yout),
      .ctrl_out(ctrl_out)
  );

endmodule

`default_nettype wire
