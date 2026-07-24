/**
 * Shift RAM
 *
 * This module implements a shift register using a RAM-based structure.
 *
 * Parameters:
 * - WIDTH: Width of input and output data (default: 8 bits)
 * - DEPTH: Number of delay stages (default: 8)
 *
 * Ports:
 * - clk: Clock input
 * - rst: Reset input
 * - cen: Clock enable input
 * - din: Input data
 * - dout: Output data (delayed)
 *
 * Operation:
 * 1. The module uses a RAM-based structure to implement the shift register
 * 2. The input data is written to the RAM on each clock cycle when cen is high
 * 3. The output data is read from the RAM on each clock cycle
 * 4. The output data is delayed by DEPTH clock cycles
 *
 * Latency: DEPTH clock cycles
 */

`timescale 1 ns / 1 ps
//
`default_nettype none

module shift_ram #(
    parameter integer WIDTH     = 8,
    parameter integer DEPTH     = 8,
    parameter reg     INPUT_REG = 1'b0
) (
    input  wire             clk,
    input  wire             rst,
    input  wire             cen,
    //
    input  wire [WIDTH-1:0] din,
    output reg  [WIDTH-1:0] dout
);

  // Local parameters

  // Memory write and read address has minimal gap of 1 to avoid collision,
  // which means maximum delay taps 2 ** (AddrWidth) - 1. Additional
  // RAM is configured to have latency of 3, result maximum depth is
  // 2 ** (AddrWidth) + 2.
  localparam integer AddrWidth = $clog2(DEPTH - 2 - (INPUT_REG ? 1 : 0));

  localparam integer MinDepth = INPUT_REG ? 5 : 4;

  // Check parameters

  // verilog_format: off
  initial begin
    // Check DEPTH
    if (DEPTH < MinDepth || 16384 < DEPTH) begin
      $display("Delay depth (DEPTH) must be within the range %0d to 16384, got %0d. [%m]", MinDepth, DEPTH);
      #1 $finish();
    end
  end
  // verilog_format: on

  // Signals

  reg  [AddrWidth-1:0] addra = 'd0;
  reg  [AddrWidth-1:0] addrb;

  reg  [    WIDTH-1:0] dina;

  wire [    WIDTH-1:0] doutb;

  // Write & read address

  always @(posedge clk) begin
    if (rst) begin
      addra <= 0;
    end else if (cen) begin
      addra <= addra + 1'd1;
    end
  end

  generate
    if (INPUT_REG) begin : g_ireg
      always @(posedge clk) begin
        if (cen) begin
          dina <= din;
        end
      end
    end else begin : g_no_ireg
      always @(*) begin
        dina = din;
      end
    end
  endgenerate

  // At minimal depth=4, read address is reset to -1, which is bottom of RAM.
  always @(posedge clk) begin
    if (rst) begin
      addrb <= -DEPTH + 3 + (INPUT_REG ? 1 : 0);
    end else if (cen) begin
      addrb <= addra - DEPTH + 4 + (INPUT_REG ? 1 : 0);
    end
  end

  ram_sdp #(
      .ADDR_WIDTH  (AddrWidth),
      .DATA_WIDTH  (WIDTH),
      .READ_LATENCY(2),
      .INIT_WORD   ({WIDTH{1'b0}}),
      .INIT_FILE   ("")
  ) i_ram_sdp (
      // Port A, write port
      .clka (clk),
      .ena  (cen),
      .wea  (cen),
      .addra(addra),
      .dina (dina),
      // Port B, read port
      .clkb (clk),
      .rstb ({2{rst}}),
      .enb  ({2{cen}}),
      .addrb(addrb),
      .doutb(doutb)
  );

  always @(posedge clk) begin
    if (rst) begin
      dout <= 0;
    end else if (cen) begin
      dout <= doutb;
    end
  end

endmodule

`default_nettype wire
