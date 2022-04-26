// File: fir_macc_mac.sv
// Brief: MAC unit for FIR filter
`timescale 1 ns / 1 ps
//
`default_nettype none

module fir_macc_mac #(
    parameter int A_WIDTH = 24,
    parameter int B_WIDTH = 16,
    parameter int P_WIDTH = 48
) (
    input var                clk,
    //
    input var  [A_WIDTH-1:0] ain,
    input var  [B_WIDTH-1:0] bin,
    input var                op_in,  // 1 = multiply, 0 = MACC
    output var [P_WIDTH-1:0] pout
);

  localparam int M_WIDTH = A_WIDTH + B_WIDTH;

  logic signed [A_WIDTH-1:0] a_reg;
  logic signed [B_WIDTH-1:0] b_reg;

  logic signed [M_WIDTH-1:0] m_reg;
  logic signed [P_WIDTH-1:0] p_reg;

  logic op_in_d, op_in_dd;

  // delay `op_in` for two ticks to match the DSP latency
  always_ff @(posedge clk) begin
    op_in_d  <= op_in;
    op_in_dd <= op_in_d;
  end

  always_ff @(posedge clk) begin
    a_reg <= $signed(ain);
    b_reg <= $signed(bin);
    m_reg <= a_reg * b_reg;
    if (op_in_dd == 1) begin
      p_reg <= m_reg;
    end else begin
      p_reg <= m_reg + p_reg;
    end
  end

  assign pout = p_reg;

endmodule

`default_nettype wire
