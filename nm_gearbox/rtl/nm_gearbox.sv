// File: nm_gearbox
// Brief: A N-bit to M-bit gearbox module.
// Todo: - Add backward pressure support
//       - Write test
//       - Add configuration parameter for N
`timescale 1 ns / 1 ps
//
`default_nettype none

module nm_gearbox (
    input var         clk,
    input var         rst,
    //
    input var  [15:0] din,
    input var         din_valid,
    output var        din_ready,
    //
    output var [63:0] dout,
    output var        dout_valid,
    //
    input var  [ 5:0] dout_bits
);

  // Signals

  logic signed [ 6:0] shift_bits;
  logic signed [ 6:0] shift_bits_next;

  logic               din_ready_next;

  logic        [63:0] en_shifter_out;
  logic        [63:0] data_shifter_out;

  // Functions

  function [63:0] shift(input logic [15:0] din, input logic signed [6:0] shift);
    logic [63:0] dout;
    dout = {48'b0, din};
    if (shift >= 0) begin
      dout = dout << shift;
    end else begin
      dout = dout >> -shift;
    end
    return dout;
  endfunction


  // Main

  always_ff @(posedge clk) begin
    if (rst) begin
      shift_bits <= '0;
    end else begin
      shift_bits <= shift_bits_next;
    end
  end

  always_comb begin
    // State at current counter by default
    shift_bits_next = shift_bits;
    if (dout_bits == 16) begin
      // Required output bit is equal to input
      shift_bits_next = 0;
    end if (dout_bits > 16) begin
      // Required output bits is larger than input
      if ((shift_bits >= 0 && din_valid) || shift_bits < 0) begin
        // Required input is valid, or does not require input
        if (shift_bits + 16 == $signed({1'b0, dout_bits})) begin
          shift_bits_next = 0;
        end if (shift_bits + 16 > $signed({1'b0, dout_bits})) begin
          shift_bits_next = shift_bits - dout_bits;
        end else begin
          shift_bits_next = shift_bits + 16;
        end
      end
    end else begin // dout_bits < 16
      // Required output bits less than input
      if ((shift_bits >= 0 && din_valid) || shift_bits < 0) begin
        // Required input is valid, or does not require input
        if (shift_bits - $signed({1'b0, dout_bits}) == -16) begin
          shift_bits_next = 0;
        end else if (shift_bits - $signed({1'b0, dout_bits}) > -16) begin
          shift_bits_next = shift_bits - dout_bits;
        end else begin // shift_bits - $signed({1'b0, dout_bits}) < -16
          shift_bits_next = shift_bits + 16;
        end
      end
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      din_ready <= '0;
    end else begin
      din_ready <= din_ready_next;
    end
  end

  always_comb begin
    if (dout_bits == 16) begin
      //
      din_ready_next = '1;
    end if (dout_bits > 16) begin
      //
      if (shift_bits_next < 0) begin
        din_ready_next = '0;
      end else begin
        din_ready_next = '1;
      end
    end else begin // dout_bits < 16
      //
      if (shift_bits_next < 0) begin
        din_ready_next = '0;
      end else begin
        din_ready_next = '1;
      end
    end
  end

  // EN & DATA

  always_comb begin
    en_shifter_out = shift({16{1'b1}}, shift_bits);
  end

  always_comb begin
    data_shifter_out = shift(din, shift_bits);
  end

  always_ff @(posedge clk) begin
    for (int i = 0; i < 64; i++) begin
      if (en_shifter_out[i]) begin
        dout[i] <= data_shifter_out[i];
      end
    end
  end

  always_ff @(posedge clk) begin
    dout_valid <= ((shift_bits >= 0 && din_valid) || shift_bits < 0);
  end

endmodule : nm_gearbox

`default_nettype wire
