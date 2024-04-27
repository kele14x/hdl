// File: qmc.sv
// Brief: Quadrature Modulator Correction module
`timescale 1 ns / 1 ps
//
`default_nettype none

module qmc #(
    parameter integer DATA_WIDTH = 16,
    parameter integer GAIN_WIDTH = 16,
    parameter integer SRA_BITS   = 14
) (
    input var                          clk,
    input var                          rst,
    //
    input var  signed [DATA_WIDTH-1:0] data_i_in,
    input var  signed [DATA_WIDTH-1:0] data_q_in,
    output var signed [DATA_WIDTH-1:0] data_i_out,
    output var signed [DATA_WIDTH-1:0] data_q_out,
    //
    input var  signed [GAIN_WIDTH-1:0] gain_i_in,
    input var  signed [GAIN_WIDTH-1:0] gain_q_in,
    input var  signed [GAIN_WIDTH-1:0] gain_qi_in,
    input var  signed [DATA_WIDTH-1:0] offset_i_in,
    input var  signed [DATA_WIDTH-1:0] offset_q_in
);


  // Local parameters

  localparam integer Latency = 4;
  localparam integer AdderWidth = DATA_WIDTH + GAIN_WIDTH;


  // Signals

  logic signed [AdderWidth-1:0] data_i_s0;
  logic signed [AdderWidth-1:0] data_i_s1;

  logic signed [AdderWidth-1:0] data_q_s0;

  logic signed [AdderWidth-1:0] offset_i_shift;
  logic signed [AdderWidth-1:0] offset_q_shift;


  // I data path includes gain, offset and phase correction from Q path
  // Q data path includes gain, offset

  assign offset_i_shift = ((offset_i_in <<< SRA_BITS) + (1 <<< (SRA_BITS - 1)));
  assign offset_q_shift = ((offset_q_in <<< SRA_BITS) + (1 <<< (SRA_BITS - 1)));

  mac #(
      // Port width
      .A_WIDTH  (DATA_WIDTH),
      .B_WIDTH  (GAIN_WIDTH),
      .C_WIDTH  (AdderWidth),
      .P_WIDTH  (AdderWidth),
      // Pipeline depth
      .A_REG    (1),
      .AD_REG   (0),
      .B_REG    (1),
      .C_REG    (1),
      .D_REG    (0),
      .M_REG    (1),
      .P_REG    (1),
      // Feature control
      .USE_DPORT(0)
  ) i_mac_i0 (
      .clk(clk),
      .a  (data_i_in),
      .b  (gain_i_in),
      .c  (offset_i_shift),
      .d  ('0),
      .p  (data_i_s0)
  );

  mac #(
      // Port width
      .A_WIDTH  (DATA_WIDTH),
      .B_WIDTH  (GAIN_WIDTH),
      .C_WIDTH  (AdderWidth),
      .P_WIDTH  (AdderWidth),
      // Pipeline depth
      .A_REG    (2),
      .AD_REG   (0),
      .B_REG    (2),
      .C_REG    (0),
      .D_REG    (0),
      .M_REG    (1),
      .P_REG    (1),
      // Feature control
      .USE_DPORT(0)
  ) i_mac_i1 (
      .clk(clk),
      .a  (data_q_in),
      .b  (gain_qi_in),
      .c  (data_i_s0),
      .d  ('0),
      .p  (data_i_s1)
  );

  mac #(
      // Port width
      .A_WIDTH  (DATA_WIDTH),
      .B_WIDTH  (GAIN_WIDTH),
      .C_WIDTH  (AdderWidth),
      .P_WIDTH  (AdderWidth),
      // Pipeline depth
      .A_REG    (2),
      .AD_REG   (0),
      .B_REG    (2),
      .C_REG    (1),
      .D_REG    (0),
      .M_REG    (1),
      .P_REG    (1),
      // Feature control
      .USE_DPORT(0)
  ) i_mac_q0 (
      .clk(clk),
      .a  (data_q_in),
      .b  (gain_q_in),
      .c  (offset_q_shift),
      .d  ('0),
      .p  (data_q_s0)
  );


  // Output

  always_ff @(posedge clk) begin
    data_i_out <= data_i_s1 >>> SRA_BITS;
  end

  always_ff @(posedge clk) begin
    data_q_out <= data_q_s0 >>> SRA_BITS;
  end

endmodule

`default_nettype wire
